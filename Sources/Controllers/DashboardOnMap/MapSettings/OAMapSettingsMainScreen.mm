//
//  OAMapSettingsMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsMainScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAFirstMapillaryBottomSheetViewController.h"
#import "OABaseSettingsListViewController.h"
#import "OARootViewController.h"
#import "OAChoosePlanHelper.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OACustomSelectionCollapsableCell.h"
#import "OAPromoButtonCell.h"
#import "OAMapStyleSettings.h"
#import "OAGPXDatabase.h"
#import "OAAppModeCell.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAIAPHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIHelper.h"
#import "OAMapSettingsMapTypeScreen.h"
#import "OAColors.h"

#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"

#define kRoadStyleCategory @"roadStyle"
#define kDetailsCategory @"details"
#define kHideCategory @"hide"
#define kTransportCategory @"transport"
#define kRoutesCategory @"routes"

#define kMaxCountRoutesWithoutGroup 5

@interface OAMapSettingsMainScreen () <OAAppModeCellDelegate, OAMapTypeDelegate>

@end

@implementation OAMapSettingsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;

    OAMapStyleSettings *_styleSettings;
    NSArray<OAMapStyleParameter *> *_filteredTopLevelParams;
    NSArray<OAMapStyleParameter *> *_routesParameters;
    NSArray<NSString *> *_routesWithoutGroup;
    NSArray<NSString *> *_routesWithGroup;

    OAAppModeCell *_appModeCell;
}

static BOOL _isRoutesGroupOpen = NO;

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _iapHelper = [OAIAPHelper sharedInstance];
        _styleSettings = [OAMapStyleSettings sharedInstance];

        title = OALocalizedString(@"configure_map");

        settingsScreen = EMapSettingsScreenMain;

        vwController = viewController;
        tblView = tableView;
    }
    return self;
}

- (void)initView
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
}

- (void)deinitView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];
    BOOL hasWiki = [_iapHelper.wiki isPurchased];
    BOOL hasSRTM = [_iapHelper.srtm isPurchased];

    [data addObject:@{
            @"group_name": @"",
            @"cells": @[@{
                    @"type": [OAAppModeCell getCellIdentifier],
            }]
    }];

    NSMutableArray *showSectionData = [NSMutableArray array];
    [showSectionData addObject:@{
            @"name": OALocalizedString(@"favorites"),
            @"image": @"ic_custom_favorites",
            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
            @"key": @"favorites"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"poi_overlay"),
            @"value": [self getPOIDescription],
            @"image": @"ic_custom_info",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"key": @"poi_layer"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"layer_amenity_label"),
            @"image": @"ic_custom_point_labels",
            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
            @"key": @"layer_amenity_label"
    }];

    if (!hasWiki || (!_iapHelper.wiki.disabled))
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"product_title_wiki"),
                @"image": hasWiki ? @"ic_custom_wikipedia" : @"ic_custom_wikipedia_download_colored",
                hasWiki ? @"has_options" : @"desc": hasWiki ? @YES : OALocalizedString(@"explore_wikipedia_offline"),
                @"type": hasWiki ? [OAIconTextDividerSwitchCell getCellIdentifier] : [OAPromoButtonCell getCellIdentifier],
                @"key": @"wikipedia_layer"
        }];

    if ([_iapHelper.osmEditing isActive])
    {
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"osm_edits_offline_layer"),
                @"image": @"ic_action_openstreetmap_logo",
                @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                @"key": @"osm_edits_offline_layer"
        }];
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"osm_notes_online_layer"),
                @"image": @"ic_action_osm_note",
                @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                @"key": @"osm_notes_online_layer"
        }];
    }

    if ([_iapHelper.mapillary isActive])
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"street_level_imagery"),
                @"image": @"ic_custom_mapillary_symbol",
                @"has_options": @YES,
                @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                @"key": @"mapillary_layer"
        }];

    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData])
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"tracks"),
                @"value": @"",
                @"image": @"ic_custom_trip",
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"tracks"
        }];

    [data addObject:@{
            @"group_name": OALocalizedString(@"map_settings_show"),
            @"cells": showSectionData
    }];

    [self generateRoutesData];
    if (_routesParameters.count > 0)
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.groupName = OALocalizedString(_isRoutesGroupOpen ? @"shared_string_collapse" : @"shared_string_show_all");
        group.type = [OACustomSelectionCollapsableCell getCellIdentifier];
        group.isOpen = _isRoutesGroupOpen;

        NSMutableArray<NSDictionary *> *routeCells = [NSMutableArray array];
        NSArray<NSString *> *hasParameters = @[SHOW_CYCLE_ROUTES_ATTR, HIKING_ROUTES_OSMC_ATTR, TRAVEL_ROUTES];
        for (OAMapStyleParameter *routeParameter in _routesParameters)
        {
            NSDictionary *routeData = @{
                    @"name": routeParameter.title,
                    @"image": [self getImageForParameterOrCategory:routeParameter.name],
                    @"key": [NSString stringWithFormat:@"routes_%@", routeParameter.name],
                    @"type": [hasParameters containsObject:routeParameter.name] ? [OAIconTitleValueCell getCellIdentifier] : [OAIconTextDividerSwitchCell getCellIdentifier]
            };

            if ([_routesWithoutGroup containsObject:routeParameter.name])
                [routeCells addObject:routeData];
            else if ([_routesWithGroup containsObject:routeParameter.name])
                [group.groupItems addObject:routeData];
        }
        if ([self hasCollapsableRoutesGroup])
        {
            [routeCells addObject:@{
                    @"group": group,
                    @"type": NSStringFromClass([group class]),
                    @"key": @"collapsed_routes"
            }];
        }

        [data addObject:@{
                @"group_name": OALocalizedString(@"rendering_category_routes"),
                @"cells": routeCells
        }];
    }

    [data addObject:@{
            @"group_name": OALocalizedString(@"map_settings_type"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"map_settings_type"),
                    @"value": _app.data.lastMapSource.name,
                    @"image": @"ic_custom_map_style",
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"map_type"
            }]
    }];

    if (!isOnlineMapSource)
    {
        NSString *modeStr;
        if ([_settings.appearanceMode get] == APPEARANCE_MODE_DAY)
            modeStr = OALocalizedString(@"map_settings_day");
        else if ([_settings.appearanceMode get] == APPEARANCE_MODE_NIGHT)
            modeStr = OALocalizedString(@"map_settings_night");
        else if ([_settings.appearanceMode get] == APPEARANCE_MODE_AUTO)
            modeStr = OALocalizedString(@"daynight_mode_auto");
        else
            modeStr = OALocalizedString(@"-");

        NSMutableArray *mapStyleSectionData = [NSMutableArray array];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_mode"),
                @"value": modeStr,
                @"image": @"ic_custom_sun",
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"map_mode"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_settings_map_magnifier"),
                @"value": [self getPercentString:[_settings.mapDensity get:_settings.applicationMode.get]],
                @"image": @"ic_custom_magnifier",
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"map_magnifier"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_settings_text_size"),
                @"value": [self getPercentString:[_settings.textSize get:_settings.applicationMode.get]],
                @"image": @"ic_custom_text_size",
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"text_size"
        }];

        for (NSString *cName in [self getAllCategories])
        {
            BOOL isTransport = [[cName lowercaseString] isEqualToString:kTransportCategory];
            [mapStyleSectionData addObject:@{
                    @"name": [_styleSettings getCategoryTitle:cName],
                    @"image": [self getImageForParameterOrCategory:cName],
                    @"key": [NSString stringWithFormat:@"category_%@", cName],
                    @"type": isTransport ? [OAIconTextDividerSwitchCell getCellIdentifier] : [OAIconTitleValueCell getCellIdentifier],
                    isTransport ? @"has_options" : @"value": isTransport ? @YES : @""
            }];
        }

        _filteredTopLevelParams = [[_styleSettings getParameters:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@)", kContourLinesDensity, kContourLinesWidth, kContourLinesColorScheme]];
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            [mapStyleSectionData addObject:@{
                    @"name": parameter.title,
                    @"image": [self getImageForParameterOrCategory:parameter.name],
                    @"value": [parameter getValueTitle],
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": [NSString stringWithFormat:@"filtered_%@", parameter.name]
            }];
        }

        if (hasSRTM && (!_iapHelper.srtm.disabled))
            [mapStyleSectionData addObject:@{
                    @"name": OALocalizedString(@"product_title_srtm"),
                    @"image": @"ic_custom_contour_lines",
                    @"has_options": @YES,
                    @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                    @"key": @"contour_lines_layer"
            }];

        [data addObject:@{
                @"group_name": OALocalizedString(@"map_settings_style"),
                @"cells": mapStyleSectionData
        }];
    }

    NSMutableArray *overlayUnderlaySectionData = [NSMutableArray array];
    if (!hasSRTM || (!_iapHelper.srtm.disabled))
        [overlayUnderlaySectionData addObject:@{
                @"name": OALocalizedString(@"shared_string_terrain"),
                @"image": hasSRTM ? @"ic_custom_hillshade" : @"ic_custom_contour_lines_colored",
                hasSRTM ? @"has_options" : @"desc": hasSRTM ? @YES : OALocalizedString(@"contour_lines_hillshades_slope"),
                @"type": hasSRTM ? [OAIconTextDividerSwitchCell getCellIdentifier] : [OAPromoButtonCell getCellIdentifier],
                @"key": @"terrain_layer"
        }];
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_over"),
            @"image": @"ic_custom_overlay_map",
            @"has_options": @YES,
            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
            @"key": @"overlay_layer"
    }];
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_under"),
            @"image": @"ic_custom_underlay_map",
            @"has_options": @YES,
            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
            @"key": @"underlay_layer"
    }];
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_weather"),
            @"image": @"ic_custom_overlay_map",
            @"has_options": @YES,
            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
            @"key": @"weather_layer"
    }];

    [data addObject:@{
            @"group_name": OALocalizedString(@"map_settings_overunder"),
            @"cells": overlayUnderlaySectionData
    }];

    [data addObject:@{
            @"group_name": OALocalizedString(@"language"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"sett_lang"),
                    @"value": [self getMapLangValueStr],
                    @"image": @"ic_custom_map_languge",
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"map_language"
            }]
    }];

    tableData = data;
    [UIView transitionWithView: tblView
                      duration: 0.35f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
                    {
                        [tblView reloadData];
                    }
                    completion: nil];
}

- (void)generateRoutesData
{
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(_app.data.lastMapSource.resourceId)
            .remove(QStringLiteral(".sqlitedb")));
    _routesParameters = !([_app.data.lastMapSource.type isEqualToString:@"sqlitedb"]
            || (resource != nullptr && resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources))
            ? [_styleSettings getParameters:kRoutesCategory sorted:NO] : [NSArray array];
    _isRoutesGroupOpen = _isRoutesGroupOpen && _routesParameters.count > kMaxCountRoutesWithoutGroup;
    if (_routesParameters.count > 0)
    {
        NSArray<NSString *> *orderedNames = @[SHOW_CYCLE_ROUTES_ATTR, SHOW_MTB_ROUTES_ATTR, HIKING_ROUTES_OSMC_ATTR,
                ALPINE_HIKING_ATTR, PISTE_ROUTES_ATTR, HORSE_ROUTES_ATTR, WHITE_WATER_SPORTS_ATTR];
        _routesParameters = [_routesParameters sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleParameter *obj1, OAMapStyleParameter *obj2) {
            return [@([orderedNames indexOfObject:obj1.name]) compare:@([orderedNames indexOfObject:obj2.name])];
        }];
        NSMutableArray<OAMapStyleParameter *> *routesParameters = [_routesParameters mutableCopy];
        [routesParameters removeObject:[_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR]];
        _routesParameters = routesParameters;

        NSMutableArray<NSString *> *routesWithoutGroup = [NSMutableArray array];
        NSMutableArray<NSString *> *routesWithGroup = [NSMutableArray array];
        for (NSInteger i = 0; i < _routesParameters.count; i++)
        {
            OAMapStyleParameter *routesParameter = routesParameters[i];
            if (i < kMaxCountRoutesWithoutGroup - 1 || ((i == _routesParameters.count - 1) && (i == routesWithoutGroup.count)))
                [routesWithoutGroup addObject:routesParameter.name];
            else
                [routesWithGroup addObject:routesParameter.name];
        }
        _routesWithoutGroup = routesWithoutGroup;
        _routesWithGroup = routesWithGroup;
    }
}

- (NSString *)getMapLangValueStr
{
    NSString *prefLangId = _settings.settingPrefMapLanguage.get;
    NSString *prefLang = prefLangId.length > 0 ? [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]] : OALocalizedString(@"local_names");
    switch (_settings.settingMapLanguage.get)
    {
        case 0: // NativeOnly
            return OALocalizedString(@"sett_lang_local");
        case 4: // LocalizedAndNative
            return [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 1: // LocalizedOrNative
            return [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_or"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 5: // LocalizedOrTransliteratedAndNative
            return [NSString stringWithFormat:@"%@ (%@) %@ %@", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]], OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        case 6: // LocalizedOrTransliterated
            return [NSString stringWithFormat:@"%@ (%@)", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]]];
        default:
            return @"";
    }
}

- (NSArray *)getAllCategories
{
    NSMutableArray *res = [NSMutableArray array];
    for (NSString *cName in [_styleSettings getAllCategories])
    {
        if (![[cName lowercaseString] isEqualToString:@"ui_hidden"] && ![[cName lowercaseString] isEqualToString:kRoutesCategory])
            [res addObject:cName];
    }
    return res;
}

- (NSString *)getPercentString:(double)value
{
    return [NSString stringWithFormat:@"%d %%", (int) (value * 100.0)];
}

- (NSString *)getPOIDescription
{
    NSMutableString *descr = [[NSMutableString alloc] init];
    OAPOIFiltersHelper *filtersHelper = [OAPOIFiltersHelper sharedInstance];
    NSArray<OAPOIUIFilter *> *selectedFilters = [[filtersHelper getSelectedPoiFilters:@[[filtersHelper getTopWikiPoiFilter]]] allObjects];
    NSUInteger size = [selectedFilters count];
    if (size > 0)
    {
        [descr appendString:selectedFilters[0].name];
        if (size > 1)
            [descr appendString:@" ..."];
    }
    return descr;
}

- (NSString *)getImageForParameterOrCategory:(NSString *)paramName
{
    if ([paramName isEqualToString:SHOW_CYCLE_ROUTES_ATTR] || [paramName isEqualToString:SHOW_MTB_ROUTES_ATTR])
        return @"ic_action_bicycle_dark";
    else if([paramName isEqualToString:WHITE_WATER_SPORTS_ATTR])
        return @"ic_action_kayak";
    else if([paramName isEqualToString:HORSE_ROUTES_ATTR])
        return @"ic_action_horse";
    else if([paramName isEqualToString:HIKING_ROUTES_OSMC_ATTR] || [paramName isEqualToString:ALPINE_HIKING_ATTR])
        return @"ic_action_trekking_dark";
    else if([paramName isEqualToString:PISTE_ROUTES_ATTR])
        return @"ic_action_skiing";
    else if([paramName isEqualToString:TRAVEL_ROUTES])
        return @"mm_routes";
    else if([paramName isEqualToString:kRoadStyleCategory])
        return @"ic_custom_road_style";
    else if([paramName isEqualToString:kDetailsCategory])
        return @"ic_custom_overlay_map";
    else if([paramName isEqualToString:kHideCategory])
        return @"ic_custom_hide";
    else if([paramName isEqualToString:kTransportCategory])
        return @"ic_custom_transport_bus";

    return @"";
}

- (BOOL)isEnabled:(NSString *)key index:(NSInteger)index
{
    if ([key isEqualToString:@"favorites"])
        return [_settings.mapSettingShowFavorites get];
    if ([key isEqualToString:@"poi_layer"])
        return [[_settings.selectedPoiFilters get] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"std_%@", OSM_WIKI_CATEGORY] withString:@""].length > 0;
    else if ([key isEqualToString:@"layer_amenity_label"])
        return [_settings.mapSettingShowPoiLabel get];
    else if ([key isEqualToString:@"wikipedia_layer"])
        return _app.data.wikipedia;
    else if ([key isEqualToString:@"osm_edits_offline_layer"])
        return [_settings.mapSettingShowOfflineEdits get];
    else if ([key isEqualToString:@"osm_notes_online_layer"])
        return [_settings.mapSettingShowOnlineNotes get];
    else if ([key isEqualToString:@"mapillary_layer"])
        return _app.data.mapillary;
    else if ([key isEqualToString:@"tracks"])
        return _settings.mapSettingVisibleGpx.get.count > 0;
    else if ([key isEqualToString:@"category_transport"])
        return [_styleSettings isCategoryEnabled:kTransportCategory];
    else if ([key isEqualToString:@"contour_lines_layer"])
        return ![[_styleSettings getParameter:@"contourLines"].value isEqualToString:@"disabled"];
    else if ([key isEqualToString:@"terrain_layer"])
        return _app.data.terrainType != EOATerrainTypeDisabled;
    else if ([key isEqualToString:@"overlay_layer"])
        return _app.data.overlayMapSource != nil;
    else if ([key isEqualToString:@"underlay_layer"])
        return _app.data.underlayMapSource != nil;
    else if ([key isEqualToString:@"weather_layer"])
        return _app.data.weather;

    if ([key hasPrefix:@"routes_"])
    {
        NSString *routesValue = _routesParameters[index].value;
        return routesValue.length > 0 ? [key hasSuffix:HIKING_ROUTES_OSMC_ATTR] ? ![routesValue isEqualToString:@"disabled"] : [routesValue isEqualToString:@"true"] : NO;
    }

    return YES;
}

- (BOOL)hasCollapsableRoutesGroup
{
    return _routesParameters.count > kMaxCountRoutesWithoutGroup;
}

- (BOOL)isCollapsableRoutesGroup:(NSString *)groupName
{
    return [groupName isEqualToString:OALocalizedString(@"rendering_category_routes")];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSArray *cells = tableData[indexPath.section][@"cells"];
    if ([self hasCollapsableRoutesGroup] && [self isCollapsableRoutesGroup:tableData[indexPath.section][@"group_name"]])
    {
        if (indexPath.row >= _routesWithoutGroup.count)
        {
            OATableCollapsableGroup *group = cells.lastObject[@"group"];
            if ((_isRoutesGroupOpen && (indexPath.row == (cells.count + group.groupItems.count) - 1))
                || (!_isRoutesGroupOpen && indexPath.row == cells.count - 1))
                return cells.lastObject;

            return group.groupItems[indexPath.row - _routesWithoutGroup.count];
        }
    }

    return cells[indexPath.row];
}

- (CGFloat)heightForHeader:(NSInteger)section
{
    NSArray *cells = tableData[section][@"cells"];
    if (cells.count > 0)
        return [cells[0][@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]] ? 0.01 : 34.;

    return 0.01;
}

- (void)openCloseGroup:(NSIndexPath *)indexPath
{
    if ([self hasCollapsableRoutesGroup] && [self isCollapsableRoutesGroup:tableData[indexPath.section][@"group_name"]])
    {
        OATableCollapsableGroup *group = [self getItem:indexPath][@"group"];
        if (group.groupItems.count > 0)
        {
            _isRoutesGroupOpen = group.isOpen = !group.isOpen;
            group.groupName = OALocalizedString(_isRoutesGroupOpen ? @"shared_string_collapse" : @"shared_string_show_all");

            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            for (NSInteger i = _routesWithoutGroup.count + 1; i <= _routesParameters.count; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            }
            [tblView beginUpdates];
            if (_isRoutesGroupOpen)
            {
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count
                                                                     inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
                [tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            }
            else
            {
                [tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count
                                                                     inSection:indexPath.section]]
                               withRowAnimation:UITableViewRowAnimationNone];
            }
            [tblView endUpdates];
            [UIView setAnimationsEnabled:NO];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_routesWithoutGroup.count - 1
                                                                 inSection:indexPath.section]]
                           withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];

            if (_isRoutesGroupOpen
                    && [tblView indexPathForCell:[tblView visibleCells].lastObject].section <= indexPath.section)
            {
                [tblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_routesWithoutGroup.count
                                                                   inSection:indexPath.section]
                               atScrollPosition:UITableViewScrollPositionMiddle
                                       animated:YES];
            }
        }
    }
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    [self openCloseGroup:indexPath];
}

#pragma mark - OAAppModeCellDelegate

- (void)appModeChanged:(OAApplicationMode *)mode
{
    [_settings setApplicationModePref:mode];
    [self setupView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return tableData[section][@"group_name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasCollapsableRoutesGroup] && [self isCollapsableRoutesGroup:tableData[section][@"group_name"]])
        return 1 + (_isRoutesGroupOpen ? _routesParameters.count : _routesWithoutGroup.count);

    return ((NSArray *) tableData[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL isOn = [self isEnabled:item[@"key"] index:indexPath.row];
    BOOL hasOptions = [item[@"has_options"] boolValue];
    BOOL isGroup = [self hasCollapsableRoutesGroup] && [self isCollapsableRoutesGroup:tableData[indexPath.section][@"group_name"]];
    BOOL isLastIndex = indexPath.row == (!isGroup
            ? [self tableView:self.tblView numberOfRowsInSection:indexPath.section] - 1
            : ((_isRoutesGroupOpen ? _routesParameters.count : _routesWithoutGroup.count) - 1));

    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAAppModeCell getCellIdentifier] owner:self options:nil];
            _appModeCell = (OAAppModeCell *) nib[0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode.get;
            _appModeCell.delegate = self;
        }
        outCell = _appModeCell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:YES];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., isLastIndex ? 20.0 : 66.0, 0., 0.);
            cell.textView.text = item[@"name"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.leftIconView.tintColor = isOn ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
        }
        if (cell)
        {
            cell.selectionStyle = hasOptions ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., isLastIndex ? 20.0 : 66.0, 0., 0.);
            cell.switchView.on = isOn;
            cell.dividerView.hidden = !hasOptions;
            cell.textView.text = item[@"name"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.iconView.tintColor = isOn ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAPromoButtonCell getCellIdentifier]])
    {
        OAPromoButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAPromoButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPromoButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAPromoButtonCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 66.0, 0., 0.);
            cell.actionButton.titleLabel.numberOfLines = 1;
            cell.actionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            cell.actionButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
        }
        if (cell)
        {
            cell.textView.text = item[@"name"];
            cell.descView.text = item[@"desc"];
            [cell.actionButton setTitle:OALocalizedString(@"purchase_get") forState:UIControlStateNormal];
            [cell.actionButton setTitleColor:[UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:0.1] forState:UIControlStateHighlighted];
            cell.iconView.image = [UIImage imageNamed:item[@"image"]];

            cell.actionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.actionButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.actionButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if (isGroup)
    {
        OATableCollapsableGroup *group = item[@"group"];
        OACustomSelectionCollapsableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomSelectionCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomSelectionCollapsableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomSelectionCollapsableCell *) nib[0];
            [cell makeSelectable:NO];
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = group.groupName;
            if (indexPath.row > 0)
                cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.image = [UIImage templateImageNamed:
                    (isRoutesGroup && _isRoutesGroupOpen) || (isOSMGroup && _isOSMGroupOpen) ? @"ic_custom_arrow_up" : @"ic_custom_arrow_down"];
            if ((!_isRoutesGroupOpen || !_isOSMGroupOpen) && [cell isDirectionRTL])
                cell.iconView.image = cell.iconView.image.imageFlippedForRightToLeftLayoutDirection;

            cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.openCloseGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];
    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OAMapSettingsViewController *mapSettingsViewController;
    BOOL isPromoButton = [item[@"type"] isEqualToString:[OAPromoButtonCell getCellIdentifier]];

    if ([item[@"key"] hasPrefix:@"collapsed_"])
        [self openCloseGroup:indexPath];
    else if ([item[@"key"] isEqualToString:@"poi_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPOI];
    else if ([item[@"key"] isEqualToString:@"tracks"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
    else if ([item[@"key"] isEqualToString:@"mapillary_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapillaryFilter];
    else if ([item[@"key"] isEqualToString:@"wikipedia_layer"] && !isPromoButton)
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWikipedia];
    else if ([item[@"key"] isEqualToString:@"map_mode"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
    else if ([item[@"key"] isEqualToString:@"map_magnifier"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:mapDensityKey];
    else if ([item[@"key"] isEqualToString:@"text_size"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:textSizeKey];
    else if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenContourLines];
    else if ([item[@"key"] isEqualToString:@"terrain_layer"] && !isPromoButton)
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
    else if ([item[@"key"] isEqualToString:@"overlay_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
    else if ([item[@"key"] isEqualToString:@"underlay_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
    else if ([item[@"key"] isEqualToString:@"map_language"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
    else if ([item[@"key"] isEqualToString:@"weather_layer"])
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWeather];

    if ([item[@"key"] hasPrefix:@"routes_"])
    {
        NSArray<NSString *> *hasParameters = @[SHOW_CYCLE_ROUTES_ATTR, HIKING_ROUTES_OSMC_ATTR, TRAVEL_ROUTES];
        NSString *parameterName = [item[@"key"] substringFromIndex:7];
        if ([hasParameters containsObject:parameterName])
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenRoutes param:parameterName];
    }
    else if ([item[@"key"] isEqualToString:@"map_type"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
        ((OAMapSettingsMapTypeScreen *) mapSettingsViewController.screenObj).delegate = self;
    }
    else if ([item[@"key"] hasPrefix:@"filtered_"])
    {
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            if (parameter.dataType != OABoolean && [item[@"key"] isEqualToString:[NSString stringWithFormat:@"filtered_%@", parameter.name]])
            {
                OAMapSettingsViewController *parameterViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:parameter.name];
                [parameterViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
            }
        }
    }
    else if ([item[@"key"] hasPrefix:@"category_"])
    {
        for (NSString *cName in _allCategories)
        {
            if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"category_%@", cName]])
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:cName];
        }
    }

    if (mapSettingsViewController)
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"favorites"])
        [_settings setShowFavorites:switchView.on];
    else if ([item[@"key"] isEqualToString:@"layer_amenity_label"])
        [_settings setShowPoiLabel:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
        [_app.data setWikipedia:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"osm_edits_offline_layer"])
        [_settings setShowOfflineEdits:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"osm_notes_online_layer"])
        [_settings setShowOnlineNotes:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"mapillary_layer"])
        [self mapillaryChanged:switchView.isOn];
    else if ([item[@"key"] hasPrefix:@"routes_"])
        [self groupItemSwitchChanged:switchView.isOn indexPath:indexPath];
    else if ([item[@"key"] hasPrefix:@"osm_"])
        [self groupItemSwitchChanged:switchView.isOn indexPath:indexPath];
    else if ([item[@"key"] isEqualToString:@"category_transport"])
        [self transportChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
        [self contourLinesChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"terrain_layer"])
        [self terrainChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"overlay_layer"])
        [self overlayChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"underlay_layer"])
        [self underlayChanged:switchView.isOn];
    else if ([item[@"key"] isEqualToString:@"weather_layer"])
        [self weatherChanged:switchView.isOn];

    [tblView beginUpdates];
    [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tblView endUpdates];
}

- (void)mapillaryChanged:(BOOL)isOn
{
    [_app.data setMapillary:isOn];
    if (isOn && !_settings.mapillaryFirstDialogShown.get)
    {
        [_settings.mapillaryFirstDialogShown set:YES];
        OAFirstMapillaryBottomSheetViewController *screen = [[OAFirstMapillaryBottomSheetViewController alloc] init];
        [screen show];
    }
}

- (void)groupItemSwitchChanged:(BOOL)isOn indexPath:(NSIndexPath *)indexPath
{
    BOOL isRoutesGroup = [self isCollapsableRoutesGroup:tableData[indexPath.section][@"group_name"]];
    BOOL isOsmGroup = [self isCollapsableOsmGroup:tableData[indexPath.section][@"cells"]];
    OAMapStyleParameter *parameter = isRoutesGroup ? _routesParameters[indexPath.row]
            : isOsmGroup ? _osmParameters[indexPath.row - 3] : nil;
    if (parameter)
    {
        parameter.value = isOn ? @"true" : @"false";
        [_styleSettings save:parameter];
    }
}

- (void)transportChanged:(BOOL)isOn
{
    [_styleSettings setCategoryEnabled:isOn categoryName:kTransportCategory];
    if (isOn && ![_styleSettings isCategoryEnabled:kTransportCategory])
    {
        OAMapSettingsViewController *transportSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:kTransportCategory];
        [transportSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
}

- (void)contourLinesChanged:(BOOL)isOn
{
    OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
    parameter.value = isOn ? [_settings.contourLinesZoom get] : @"disabled";
    [_styleSettings save:parameter];
}

- (void)terrainChanged:(BOOL)isOn
{
    if (isOn)
    {
        EOATerrainType lastType = _app.data.lastTerrainType;
        _app.data.terrainType = lastType != EOATerrainTypeDisabled ? lastType : EOATerrainTypeHillshade;
    }
    else
    {
        _app.data.lastTerrainType = _app.data.terrainType;
        _app.data.terrainType = EOATerrainTypeDisabled;
    }
}

- (void)overlayChanged:(BOOL)isOn
{
    if (isOn)
    {
        BOOL hasLastMapSource = _app.data.lastOverlayMapSource != nil;
        if (!hasLastMapSource)
            _app.data.lastOverlayMapSource = [OAMapSource getOsmAndOnlineTilesMapSource];

        _app.data.overlayMapSource = _app.data.lastOverlayMapSource;
        if (!hasLastMapSource)
        {
            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        }
    }
    else
    {
        _app.data.overlayMapSource = nil;
    }
}

- (void)underlayChanged:(BOOL)isOn
{
    OAMapStyleParameter *hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];
    if (isOn)
    {
        BOOL hasLastMapSource = _app.data.lastUnderlayMapSource != nil;
        if (!hasLastMapSource)
            _app.data.lastUnderlayMapSource = [OAMapSource getOsmAndOnlineTilesMapSource];

        hidePolygonsParameter.value = @"true";
        [_styleSettings save:hidePolygonsParameter];
        _app.data.underlayMapSource = _app.data.lastUnderlayMapSource;
        if (!hasLastMapSource)
        {
            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        }
    }
    else
    {
        hidePolygonsParameter.value = @"false";
        [_styleSettings save:hidePolygonsParameter];
        _app.data.underlayMapSource = nil;
    }
}

- (void)weatherChanged:(BOOL)isOn
{
    _app.data.weather = isOn;
}

- (void)installMapLayerFor:(id)param
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOnlineSources param:param];
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_upload_no_internet") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self.vwController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - UIButton pressed

- (BOOL)onButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    OAProduct *product;
    if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
        product = _iapHelper.wiki;
    else if ([item[@"key"] isEqualToString:@"terrain_layer"])
        product = _iapHelper.srtm;

    [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:[OARootViewController instance].navigationController];
    return NO;
}

#pragma mark - OAMapTypeDelegate

- (void)updateSkimapRoutesParameter:(OAMapSource *)source
{
    if (![source.resourceId hasPrefix:@"skimap"])
    {
        OAMapStyleParameter *ski = [_styleSettings getParameter:PISTE_ROUTES_ATTR];
        ski.value = @"false";
        [_styleSettings save:ski];

        if ([_routesWithGroup containsObject:PISTE_ROUTES_ATTR])
        {
            NSMutableArray *routesWithGroup = [_routesWithGroup mutableCopy];
            [routesWithGroup removeObject:PISTE_ROUTES_ATTR];
            _routesWithGroup = routesWithGroup;
        }
    }
    else
    {
        _routesWithGroup = [@[PISTE_ROUTES_ATTR] arrayByAddingObjectsFromArray:_routesWithGroup];
    }
}

- (void)refreshMenu
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    [self setupView];
}

#pragma mark - OAIAPProductNotification

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

- (void)productsRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

@end
