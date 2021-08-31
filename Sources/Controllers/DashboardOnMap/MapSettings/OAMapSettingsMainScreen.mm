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
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAMapStyleSettings.h"
#import "OAGPXDatabase.h"
#import "OAMapSource.h"
#import "OAAppModeCell.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAMapSettingsOverlayUnderlayScreen.h"
#import "Reachability.h"
#import "OAPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAMapSettingsMapTypeScreen.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>

#define kMapStyleTopSettingsCount 3
#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"

@interface OAMapSettingsMainScreen () <OAAppModeCellDelegate, OAMapTypeDelegate>

@end

@implementation OAMapSettingsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;

    OAMapStyleSettings *_styleSettings;
    NSArray *_filteredTopLevelParams;
    NSArray<OAMapStyleParameter *> *_routesParameters;

    OAAppModeCell *_appModeCell;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
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
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    NSMutableArray *data = [NSMutableArray array];

    [data addObject:@{
            @"groupName": @"",
            @"cells": @[@{
                    @"type": [OAAppModeCell getCellIdentifier],
            }]
    }];

    NSMutableArray *showSectionData = [NSMutableArray array];
    [showSectionData addObject:@{
            @"name": OALocalizedString(@"favorites"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier],
            @"key": @"favorites"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"poi_overlay"),
            @"value": [self getPOIDescription],
            @"type": [OASettingsTableViewCell getCellIdentifier],
            @"key": @"poi_layer"
    }];

    [showSectionData addObject:@{
            @"name": OALocalizedString(@"layer_amenity_label"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier],
            @"key": @"layer_amenity_label"
    }];

    if ([_iapHelper.wiki isActive])
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"product_title_wiki"),
                @"value": @"",
                @"secondaryImg": @"ic_action_additional_option",
                @"type": [OASettingSwitchCell getCellIdentifier],
                @"key": @"wikipedia_layer"
        }];

    if ([_iapHelper.osmEditing isActive])
    {
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"osm_edits_offline_layer"),
                @"value": @"",
                @"type": [OASwitchTableViewCell getCellIdentifier],
                @"key": @"osm_edits_offline_layer"
        }];
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"osm_notes_online_layer"),
                @"value": @"",
                @"type": [OASwitchTableViewCell getCellIdentifier],
                @"key": @"osm_notes_online_layer"
        }];
    }

    if ([_iapHelper.mapillary isActive])
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"street_level_imagery"),
                @"description": @"",
                @"secondaryImg": @"ic_action_additional_option",
                @"type": [OASettingSwitchCell getCellIdentifier],
                @"key": @"mapillary_layer"
        }];

    if ([[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData])
        [showSectionData addObject:@{
                @"name": OALocalizedString(@"tracks"),
                @"value": @"",
                @"type": [OASettingsTableViewCell getCellIdentifier],
                @"key": @"tracks"
        }];

    [data addObject:@{
            @"groupName": OALocalizedString(@"map_settings_show"),
            @"cells": showSectionData
    }];

    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(_app.data.lastMapSource.resourceId).remove(QStringLiteral(".sqlitedb")));
    _routesParameters = !([_app.data.lastMapSource.type isEqualToString:@"sqlitedb"] || (resource != nullptr && resource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources)) ? [_styleSettings getParameters:@"routes"] : [NSArray array];
    NSMutableArray *routesSectionData = [NSMutableArray array];
    if (_routesParameters.count > 0)
    {
        NSArray<NSString *> *hasParameters = @[SHOW_CYCLE_ROUTES_ATTR, HIKING_ROUTES_OSMC_ATTR];
        for (OAMapStyleParameter *routeParameter in _routesParameters)
        {
            if ([routeParameter.name isEqualToString:CYCLE_NODE_NETWORK_ROUTES_ATTR])
                continue;

            NSMutableDictionary *cellRoutes = [NSMutableDictionary new];
            cellRoutes[@"name"] = routeParameter.title;
            cellRoutes[@"value"]= @"";
            cellRoutes[@"key"]= [NSString stringWithFormat:@"routes_%@", routeParameter.name];

            if ([hasParameters containsObject:routeParameter.name])
            {
                cellRoutes[@"type"] = [OASettingsTableViewCell getCellIdentifier];
            }
            else
            {
                cellRoutes[@"type"] = [OASwitchTableViewCell getCellIdentifier];
                cellRoutes[@"switch"] = routeParameter.storedValue;
                cellRoutes[@"tag"] = @([_routesParameters indexOfObject:routeParameter]);
            }

            [routesSectionData addObject:cellRoutes];
        }

        [data addObject:@{
                @"groupName": OALocalizedString(@"rendering_category_routes"),
                @"cells": routesSectionData
        }];
    }

    [data addObject:@{
            @"groupName": OALocalizedString(@"map_settings_type"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"map_settings_type"),
                    @"value": _app.data.lastMapSource.name,
                    @"type": [OASettingsTableViewCell getCellIdentifier],
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
                @"type": [OASettingsTableViewCell getCellIdentifier],
                @"key": @"map_mode"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_settings_map_magnifier"),
                @"value": [self getPercentString:[_settings.mapDensity get:_settings.applicationMode.get]],
                @"type": [OASettingsTableViewCell getCellIdentifier],
                @"key": @"map_magnifier"
        }];
        [mapStyleSectionData addObject:@{
                @"name": OALocalizedString(@"map_settings_text_size"),
                @"value": [self getPercentString:[_settings.textSize get:_settings.applicationMode.get]],
                @"type": [OASettingsTableViewCell getCellIdentifier],
                @"key": @"text_size"
        }];

        for (NSString *cName in [self getAllCategories])
        {
            NSString *cTitle = [_styleSettings getCategoryTitle:cName];
            if ([[cName lowercaseString] isEqualToString:@"transport"])
            {
                [mapStyleSectionData addObject:@{
                        @"name": cTitle,
                        @"value": @"",
                        @"type": [OASettingSwitchCell getCellIdentifier],
                        @"secondaryImg": @"ic_action_additional_option",
                        @"key": [NSString stringWithFormat:@"transport_layer"]
                }];
            }
            else
            {
                [mapStyleSectionData addObject:@{
                        @"name": cTitle,
                        @"value": @"",
                        @"type": [OASettingsTableViewCell getCellIdentifier],
                        @"key": [NSString stringWithFormat:@"category_%@", cName]
                }];
            }
        }

        _filteredTopLevelParams = [[_styleSettings getParameters:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@)", kContourLinesDensity, kContourLinesWidth, kContourLinesColorScheme]];
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            [mapStyleSectionData addObject:@{
                    @"name": parameter.title,
                    @"value": [parameter getValueTitle],
                    @"type": [OASettingsTableViewCell getCellIdentifier],
                    @"key": [NSString stringWithFormat:@"filtered_%@", parameter.name]
            }];
        }

        if ([_iapHelper.srtm isActive])
            [mapStyleSectionData addObject:@{
                    @"name": OALocalizedString(@"product_title_srtm"),
                    @"description": @"",
                    @"secondaryImg": @"ic_action_additional_option",
                    @"type": [OASettingSwitchCell getCellIdentifier],
                    @"key": @"contour_lines_layer"
            }];

        [data addObject:@{
                @"groupName": OALocalizedString(@"map_settings_style"),
                @"cells": mapStyleSectionData
        }];
    }

    NSMutableArray *overlayUnderlaySectionData = [NSMutableArray array];

    if ([_iapHelper.srtm isActive])
        [overlayUnderlaySectionData addObject:@{
                @"name": OALocalizedString(@"shared_string_terrain"),
                @"description": @"",
                @"secondaryImg": @"ic_action_additional_option",
                @"type": [OASettingSwitchCell getCellIdentifier],
                @"key": @"terrain_layer"
        }];

    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_over"),
            @"description": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"overlay_layer"
    }];
    [overlayUnderlaySectionData addObject:@{
            @"name": OALocalizedString(@"map_settings_under"),
            @"description": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"underlay_layer"
    }];

    [data addObject:@{
            @"groupName": OALocalizedString(@"map_settings_overunder"),
            @"cells": overlayUnderlaySectionData
    }];

    [data addObject:@{
            @"groupName": OALocalizedString(@"language"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"sett_lang"),
                    @"value": [self getMapLangValueStr],
                    @"type": [OASettingsTableViewCell getCellIdentifier],
                    @"key": @"map_language"
            }]
    }];

    tableData = data;
    [tblView reloadData];
}

- (NSString *)getMapLangValueStr
{
    NSString *prefLang;
    NSString *prefLangId = _settings.settingPrefMapLanguage.get;
    if (prefLangId)
        prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        prefLang = OALocalizedString(@"local_names");

    NSString *languageValue;
    switch (_settings.settingMapLanguage.get)
    {
        case 0: // NativeOnly
            languageValue = OALocalizedString(@"sett_lang_local");
            break;
        case 4: // LocalizedAndNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 1: // LocalizedOrNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_or"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 5: // LocalizedOrTransliteratedAndNative
            languageValue = [NSString stringWithFormat:@"%@ (%@) %@ %@", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]], OALocalizedString(@"shared_string_and"), [OALocalizedString(@"sett_lang_local") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;
        case 6: // LocalizedOrTransliterated
            languageValue = [NSString stringWithFormat:@"%@ (%@)", prefLang, [OALocalizedString(@"sett_lang_trans") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            break;

        default:
            break;
    }

    return languageValue;
}

- (NSArray *) getAllCategories
{
    NSMutableArray *res = [NSMutableArray array];
    NSMutableArray *categories = [NSMutableArray arrayWithArray:[_styleSettings getAllCategories]];
    for (NSString *cName in categories)
    {
        if (![[cName lowercaseString] isEqualToString:@"ui_hidden"] && ![[cName lowercaseString] isEqualToString:@"routes"])
            [res addObject:cName];
    }
    return res;
}

- (NSString *) getPercentString:(double)value
{
    return [NSString stringWithFormat:@"%d %%", (int) (value * 100.0)];
}

- (NSString *) getPOIDescription
{
    NSMutableString *descr = [[NSMutableString alloc] init];
    NSMutableArray<OAPOIUIFilter *> *selectedFilters = [[[[OAPOIFiltersHelper sharedInstance] getSelectedPoiFilters] allObjects] mutableCopy];
    [selectedFilters removeObject:[[OAPOIFiltersHelper sharedInstance] getTopWikiPoiFilter]];
    NSUInteger size = [selectedFilters count];
    if (size > 0)
    {
        [descr appendString:selectedFilters[0].name];
        if (size > 1)
            [descr appendString:@" ..."];
    }
    return descr;
}

- (CGFloat) heightForHeader:(NSInteger)section
{
    NSDictionary *sectionData = tableData[section];
    NSArray *cells = sectionData[@"cells"];
    if (cells.count > 0)
    {
        NSDictionary *cellData = cells[0];
        if ([cellData[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
            return 0.01;
        else
            return 34.0;
        
    }
    return 0.01;
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [_settings setApplicationModePref:mode];
    
    [self setupView];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return (NSDictionary *) ((NSArray *) ((NSDictionary *) tableData[indexPath.section])[@"cells"])[indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [tableData count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ((NSDictionary *) tableData[section])[@"groupName"];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((NSArray*) ((NSDictionary *) tableData[section])[@"cells"]) count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
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
    else if ([item[@"type"] isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *) nib[0];
        }

        if (cell)
        {
            [cell.textView setText:item[@"name"]];
            [cell.descriptionView setText:item[@"value"]];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
        }

        if (cell)
        {
            [cell.textView setText:item[@"name"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];

            if ([item[@"key"] isEqualToString:@"favorites"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowFavorites get]];
                [cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([item[@"key"] isEqualToString:@"layer_amenity_label"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowPoiLabel get]];
                [cell.switchView addTarget:self action:@selector(showPoiLabelChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([item[@"key"] isEqualToString:@"osm_edits_offline_layer"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowOfflineEdits get]];
                [cell.switchView addTarget:self action:@selector(showOfflineEditsChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([item[@"key"] isEqualToString:@"osm_notes_online_layer"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowOnlineNotes get]];
                [cell.switchView addTarget:self action:@selector(showOnlineNotesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([item[@"key"] hasPrefix:@"routes_"])
            {
                [cell.switchView setOn:[item[@"switch"] isEqualToString:@"true"]];
                [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                cell.switchView.tag = ((NSNumber *) item[@"tag"]).integerValue;
            }
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
        }

        if (cell)
        {
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if ([item[@"key"] isEqualToString:@"mapillary_layer"])
            {
                [cell.switchView setOn:[OsmAndApp instance].data.mapillary];
                [cell.switchView addTarget:self action:@selector(mapillaryChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
            {
                BOOL contourLinesOn = true;
                OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
                if ([parameter.value isEqual:@"disabled"])
                    contourLinesOn = false;
                [cell.switchView setOn:contourLinesOn];
                [cell.switchView addTarget:self action:@selector(contourLinesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"overlay_layer"])
            {
                [cell.switchView setOn:_app.data.overlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(overlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"underlay_layer"])
            {
                [cell.switchView setOn:_app.data.underlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(underlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"terrain_layer"])
            {
                [cell.switchView setOn:_app.data.terrainType != EOATerrainTypeDisabled];
                [cell.switchView addTarget:self action:@selector(terrainChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"transport_layer"])
            {
                [cell.switchView setOn:[_styleSettings isCategoryEnabled:@"transport"]];
                [cell.switchView addTarget:self action:@selector(transportChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
            {
                [cell.switchView setOn:_app.data.wikipedia];
                [cell.switchView addTarget:self action:@selector(wikipediaChanged:) forControlEvents:UIControlEventValueChanged];
            }
            cell.textView.text = item[@"name"];
            NSString *desc = item[@"description"];
            NSString *secondaryImg = item[@"secondaryImg"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            [cell setSecondaryImage:secondaryImg.length > 0 ? [UIImage imageNamed:secondaryImg] : nil];
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        outCell = cell;
    }
    return outCell;
}

- (void) mapillaryChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        BOOL mapillaryOn = switchView.isOn;
        [[OsmAndApp instance].data setMapillary:mapillaryOn];
        if (mapillaryOn && !_settings.mapillaryFirstDialogShown.get)
        {
            [_settings.mapillaryFirstDialogShown set:YES];
            OAFirstMapillaryBottomSheetViewController *screen = [[OAFirstMapillaryBottomSheetViewController alloc] init];
            [screen show];
        }
    }
}

- (void)wikipediaChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        BOOL wikipediaOn = switchView.isOn;
        [_app.data setWikipedia:wikipediaOn];
    }
}

- (void) contourLinesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [_styleSettings save:parameter];
    }
}

- (void) overlayChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        if (switchView.isOn)
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
            _app.data.overlayMapSource = nil;
    }
}

- (void)mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        OAMapStyleParameter *p = _routesParameters[switchView.tag];
        if (p)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                p.value = switchView.isOn ? @"true" : @"false";
                [_styleSettings save:p];
            });
        }
    }
}

- (void) installMapLayerFor:(id)param
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

- (void) underlayChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        OAMapStyleParameter *hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];
        if (switchView.isOn)
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
}

- (void) terrainChanged:(id)sender
{
    if ([sender isKindOfClass:UISwitch.class])
    {
        UISwitch *switchView = (UISwitch *) sender;
        if (switchView.isOn)
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
}

- (void) showFavoriteChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
        [_settings setShowFavorites:switchView.isOn];
}

- (void) showPoiLabelChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
        [_settings setShowPoiLabel:switchView.isOn];
}

- (void) showOfflineEditsChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
        [_settings setShowOfflineEdits:switchView.isOn];
}

- (void) showOnlineNotesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
        [_settings setShowOnlineNotes:switchView.isOn];
}

- (void) transportChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        [_styleSettings setCategoryEnabled:switchView.isOn categoryName:@"transport"];
        if (switchView.isOn && ![_styleSettings isCategoryEnabled:@"transport"])
        {
            OAMapSettingsViewController *transportSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:@"transport"];
            [transportSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        }
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OAMapSettingsViewController *mapSettingsViewController;

    if ([item[@"key"] isEqualToString:@"poi_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPOI];
    }
    else if ([item[@"key"] isEqualToString:@"tracks"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
    }
    else if ([item[@"key"] isEqualToString:@"mapillary_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapillaryFilter];
    }
    else if ([item[@"key"] isEqualToString:@"wikipedia_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWikipedia];
    }
    else if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"routes_%@", SHOW_CYCLE_ROUTES_ATTR]])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCycleRoutes];
    }
    else if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"routes_%@", HIKING_ROUTES_OSMC_ATTR]])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenHikingRoutes];
    }
    /*else if ([item[@"key"] isEqualToString:@"routes_travel"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTravelRoutes];
    }*/
    else if ([item[@"key"] isEqualToString:@"map_type"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
        ((OAMapSettingsMapTypeScreen *) mapSettingsViewController.screenObj).delegate = self;
    }
    if ([item[@"key"] isEqualToString:@"map_mode"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
    }
    else if ([item[@"key"] isEqualToString:@"map_magnifier"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:mapDensityKey];
    }
    else if ([item[@"key"] isEqualToString:@"text_size"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:textSizeKey];
    }
    else if ([item[@"key"] isEqualToString:@"contour_lines_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenContourLines];
    }
    else if ([item[@"key"] isEqualToString:@"terrain_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
    }
    else if ([item[@"key"] isEqualToString:@"overlay_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
    }
    else if ([item[@"key"] isEqualToString:@"underlay_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
    }
    else if ([item[@"key"] isEqualToString:@"map_language"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
    }
    else if ([item[@"key"] isEqualToString:@"transport_layer"])
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:@"transport"];
    }
    else if ([item[@"key"] hasPrefix:@"filtered_"])
    {
        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"filtered_%@", parameter.name]])
            {
                if (parameter.dataType != OABoolean)
                {
                    OAMapSettingsViewController *parameterViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:parameter.name];
                    [parameterViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
                }
            }
        }
    }
    else if ([item[@"key"] hasPrefix:@"category_"])
    {
        for (NSString *cName in [self getAllCategories])
        {
            if ([item[@"key"] isEqualToString:[NSString stringWithFormat:@"category_%@", cName]])
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:cName];
        }
    }


    if (mapSettingsViewController)
            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - OAMapTypeDelegate

- (void)updateSkimapRoutesParameter:(OAMapSource *)source
{
    if (![source.resourceId hasPrefix:@"skimap"])
    {
        OAMapStyleParameter *ski = [_styleSettings getParameter:PISTE_ROUTES_ATTR];
        ski.value = @"false";
        [_styleSettings save:ski];
    }
}

- (void)refreshMenu
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    [self setupView];
}

@end
