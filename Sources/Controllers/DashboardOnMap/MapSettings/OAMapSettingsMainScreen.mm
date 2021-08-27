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

    NSInteger _showSection;
    NSInteger _favoritesRow;
    NSInteger _poiRow;
    NSInteger _wikipediaRow;
    NSInteger _mapillaryRow;
    NSInteger _tracksRow;

    NSInteger routesSection;
    NSInteger hikingRoutesRow;
    NSInteger cycleRoutesRow;
    NSInteger travelRoutesRow;

    NSInteger mapTypeSection;

    NSInteger mapStyleSection;
    NSInteger contourLinesRow;

    NSInteger overlayUnderlaySection;

    NSInteger languageSection;
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
        _routesParameters = [_styleSettings getParameters:@"routes"];

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

- (NSString *)getMapLangValueStr
{
    NSString *prefLang;
    NSString *prefLangId = _settings.settingPrefMapLanguage.get;
    if (prefLangId)
        prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        prefLang = OALocalizedString(@"local_names");
    
    NSString* languageValue;
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
    return [NSArray arrayWithArray:res];
}

- (void) setupView
{
    NSMutableArray *data = [NSMutableArray new];

    NSMutableDictionary *sectionAppMode = [NSMutableDictionary dictionary];
    sectionAppMode[@"type"] = [OAAppModeCell getCellIdentifier];
    [data addObject:@{
            @"groupName": @"",
            @"cells": @[sectionAppMode]
    }];
    NSInteger visibleSectionsCount = 1;

    NSDictionary *showSectionFavoritesRow = @{
            @"name": OALocalizedString(@"favorites"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier]
    };

    NSDictionary *showSectionPoiRow = @{
            @"name": OALocalizedString(@"poi_overlay"),
            @"value": [self getPOIDescription],
            @"type": [OASettingsTableViewCell getCellIdentifier]
    };

    NSDictionary *showSectionLabelsRow = @{
            @"name": OALocalizedString(@"layer_amenity_label"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier],
            @"key": @"layer_amenity_label"
    };

    BOOL hasWiki = [_iapHelper.wiki isActive];
    NSDictionary *showSectionWikipediaRow = @{
            @"name": OALocalizedString(@"product_title_wiki"),
            @"value": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"wikipedia_layer"
    };

    BOOL hasOsmEditing = [_iapHelper.osmEditing isActive];
    NSDictionary *showSectionOsmEditsRow = @{
            @"name": OALocalizedString(@"osm_edits_offline_layer"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier],
            @"key": @"osm_edits_offline_layer"
    };
    NSDictionary *showSectionOsmNotesRow = @{
            @"name": OALocalizedString(@"osm_notes_online_layer"),
            @"value": @"",
            @"type": [OASwitchTableViewCell getCellIdentifier],
            @"key": @"osm_notes_online_layer"
    };

    BOOL hasMapillary = [_iapHelper.mapillary isActive];
    NSDictionary *showSectionMapillaryRow = @{
            @"name": OALocalizedString(@"street_level_imagery"),
            @"description": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"mapillary_layer"
    };

    BOOL hasTracks = [[[OAGPXDatabase sharedDb] gpxList] count] > 0 || [[OASavingTrackHelper sharedInstance] hasData];
    NSDictionary *showSectionTracksRow = @{
            @"name": OALocalizedString(@"tracks"),
            @"value": @"",
            @"type": [OASettingsTableViewCell getCellIdentifier]
    };

    _showSection = 1;
    visibleSectionsCount++;
    NSMutableArray *showSectionData = [NSMutableArray array];
    [showSectionData addObject:showSectionFavoritesRow];
    _favoritesRow = showSectionData.count - 1;
    [showSectionData addObject:showSectionPoiRow];
    _poiRow = showSectionData.count - 1;
    [showSectionData addObject:showSectionLabelsRow];

    if (hasWiki)
        [showSectionData addObject:showSectionWikipediaRow];
    _wikipediaRow = hasWiki ? showSectionData.count - 1 : -1;

    if (hasOsmEditing)
    {
        [showSectionData addObject:showSectionOsmEditsRow];
        [showSectionData addObject:showSectionOsmNotesRow];
    }

    if (hasMapillary)
        [showSectionData addObject:showSectionMapillaryRow];
    _mapillaryRow = hasMapillary ? showSectionData.count - 1 : -1;

    if (hasTracks)
        [showSectionData addObject:showSectionTracksRow];
    _tracksRow = hasTracks ? showSectionData.count - 1 : -1;

    [data addObject:@{
            @"groupName": OALocalizedString(@"map_settings_show"),
            @"cells": showSectionData
    }];

    NSMutableArray *routesSectionData = [NSMutableArray array];
    routesSection = _routesParameters.count > 0 ? 2 : -1;
    cycleRoutesRow = -1;
    hikingRoutesRow = -1;
    travelRoutesRow = -1;

    if (_routesParameters.count > 0)
    {
        visibleSectionsCount++;
        for (OAMapStyleParameter *routeParameter in _routesParameters)
        {
            if ([routeParameter.name isEqualToString:CYCLE_NODE_NETWORK_ROUTES_ATTR])
                continue;

            NSMutableDictionary *cellRoutes = [NSMutableDictionary dictionary];
            cellRoutes[@"name"] = routeParameter.title;
            cellRoutes[@"value"] = @"";

            if ([routeParameter.name isEqualToString:SHOW_CYCLE_ROUTES_ATTR])
            {
                cycleRoutesRow = [_routesParameters indexOfObject:routeParameter];
                cellRoutes[@"type"] = [OASettingsTableViewCell getCellIdentifier];
            }
            else if ([routeParameter.name isEqualToString:HIKING_ROUTES_OSMC_ATTR])
            {
                hikingRoutesRow = [_routesParameters indexOfObject:routeParameter];
                cellRoutes[@"type"] = [OASettingsTableViewCell getCellIdentifier];
            }
            else if ([routeParameter.title isEqualToString:OALocalizedString(@"travel_routes")])
            {
                travelRoutesRow = [_routesParameters indexOfObject:routeParameter];
                cellRoutes[@"type"] = [OASettingsTableViewCell getCellIdentifier];
            }
            else
            {
                cellRoutes[@"type"] = [OASwitchTableViewCell getCellIdentifier];
                cellRoutes[@"key"] = [NSString stringWithFormat:@"routes_%@", routeParameter.title];
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

    mapTypeSection = visibleSectionsCount++;
    [data addObject:@{
            @"groupName": OALocalizedString(@"map_settings_type"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"map_settings_type"),
                    @"value": _app.data.lastMapSource.name,
                    @"type": [OASettingsTableViewCell getCellIdentifier]
            }]
    }];

    BOOL hasSrtm = [_iapHelper.srtm isActive];

    if (isOnlineMapSource)
    {
        tableData = data;
        mapStyleSection = -1;
    }
    else
    {
        mapStyleSection = visibleSectionsCount++;

        NSArray *categories = [self getAllCategories];
        _filteredTopLevelParams = [[_styleSettings getParameters:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@)", kContourLinesDensity, kContourLinesWidth, kContourLinesColorScheme]];
        NSMutableArray *categoryRows = [NSMutableArray array];
        NSString *modeStr;
        if ([_settings.appearanceMode get] == APPEARANCE_MODE_DAY)
            modeStr = OALocalizedString(@"map_settings_day");
        else if ([_settings.appearanceMode get] == APPEARANCE_MODE_NIGHT)
            modeStr = OALocalizedString(@"map_settings_night");
        else if ([_settings.appearanceMode get] == APPEARANCE_MODE_AUTO)
            modeStr = OALocalizedString(@"daynight_mode_auto");
        else
            modeStr = OALocalizedString(@"-");

        [categoryRows addObject:@{
                @"name": OALocalizedString(@"map_mode"),
                @"value": modeStr,
                @"type": [OASettingsTableViewCell getCellIdentifier]
        }];

        [categoryRows addObject:@{
                @"name": OALocalizedString(@"map_settings_map_magnifier"),
                @"value": [self getPercentString:[_settings.mapDensity get:_settings.applicationMode.get]],
                @"type": [OASettingsTableViewCell getCellIdentifier]
        }];

        [categoryRows addObject:@{
                @"name": OALocalizedString(@"map_settings_text_size"),
                @"value": [self getPercentString:[_settings.textSize get:_settings.applicationMode.get]],
                @"type": [OASettingsTableViewCell getCellIdentifier]
        }];

        for (NSString *cName in categories)
        {
            NSString *cTitle = [_styleSettings getCategoryTitle:cName];
            if (![[cTitle lowercaseString] isEqualToString:@"ui_hidden"])
            {
                if ([[cTitle lowercaseString] isEqualToString:@"transport"])
                {
                    [categoryRows addObject:@{
                            @"name": cTitle,
                            @"value": @"",
                            @"key": @"transport_layer",
                            @"type": [OASettingSwitchCell getCellIdentifier],
                            @"secondaryImg": @"ic_action_additional_option"
                    }];
                }
                else
                {
                    [categoryRows addObject:@{
                            @"name": cTitle,
                            @"value": @"",
                            @"type": [OASettingsTableViewCell getCellIdentifier]
                    }];
                }
            }
        }

        for (OAMapStyleParameter *parameter in _filteredTopLevelParams)
        {
            [categoryRows addObject:@{
                    @"name": parameter.title,
                    @"value": [parameter getValueTitle],
                    @"type": [OASettingsTableViewCell getCellIdentifier]
            }];
        }

        if (hasSrtm)
            [categoryRows addObject:@{
                    @"name": OALocalizedString(@"product_title_srtm"),
                    @"description": @"",
                    @"secondaryImg": @"ic_action_additional_option",
                    @"type": [OASettingSwitchCell getCellIdentifier],
                    @"key": @"contour_lines_layer"
            }];
        contourLinesRow = hasSrtm ? categoryRows.count - 1 : -1;

        NSArray *mapStylesSectionData = @[@{
                @"groupName": OALocalizedString(@"map_settings_style"),
                @"cells": categoryRows
        }];

        tableData = [data arrayByAddingObjectsFromArray:mapStylesSectionData];
    }

    overlayUnderlaySection = visibleSectionsCount++;
    NSMutableArray *overlayUnderlayRows = [NSMutableArray array];

    if (hasSrtm)
        [overlayUnderlayRows addObject:@{
                @"name": OALocalizedString(@"shared_string_terrain"),
                @"description": @"",
                @"secondaryImg": @"ic_action_additional_option",
                @"type": [OASettingSwitchCell getCellIdentifier],
                @"key": @"terrain_layer"
        }];

    [overlayUnderlayRows addObject:@{
            @"name": OALocalizedString(@"map_settings_over"),
            @"description": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"overlay_layer"
    }];

    [overlayUnderlayRows addObject:@{
            @"name": OALocalizedString(@"map_settings_under"),
            @"description": @"",
            @"secondaryImg": @"ic_action_additional_option",
            @"type": [OASettingSwitchCell getCellIdentifier],
            @"key": @"underlay_layer"
    }];

    NSArray *overlayUnderlaySectionData = @[@{
            @"groupName": OALocalizedString(@"map_settings_overunder"),
            @"cells": overlayUnderlayRows
    }];

    tableData = [tableData arrayByAddingObjectsFromArray:overlayUnderlaySectionData];

    languageSection = visibleSectionsCount++;
    NSString *languageValue = [self getMapLangValueStr];
    NSArray *languageSectionData = @[@{
            @"groupName" : OALocalizedString(@"language"),
            @"cells": @[@{
                    @"name": OALocalizedString(@"sett_lang"),
                    @"value": languageValue,
                    @"type": [OASettingsTableViewCell getCellIdentifier]
            }]
    }];

    tableData = [tableData arrayByAddingObjectsFromArray:languageSectionData];

    [tblView reloadData];
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
    NSDictionary *sectionData = (NSDictionary *) tableData[section];
    NSArray *cells = (NSArray *) sectionData[@"cells"];
    NSDictionary *cellData = (NSDictionary *) cells[0];
    if ([cellData[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
        return 0.01;
    else
        return 34.0;
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [_settings setApplicationModePref:mode];
    
    [self setupView];
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
    NSDictionary *data = (NSDictionary *) ((NSArray *) ((NSDictionary *) tableData[indexPath.section])[@"cells"])[indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([data[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
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
    else if ([data[@"type"] isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *) nib[0];
        }

        if (cell)
        {
            [cell.textView setText:data[@"name"]];
            [cell.descriptionView setText:data[@"value"]];
        }
        outCell = cell;

    }
    else if ([data[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
        }

        if (cell)
        {
            [cell.textView setText:data[@"name"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];

            if (indexPath.section == _showSection && indexPath.row == _favoritesRow)
            {
                [cell.switchView setOn:[_settings.mapSettingShowFavorites get]];
                [cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"layer_amenity_label"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowPoiLabel get]];
                [cell.switchView addTarget:self action:@selector(showPoiLabelChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"osm_edits_offline_layer"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowOfflineEdits get]];
                [cell.switchView addTarget:self action:@selector(showOfflineEditsChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] isEqualToString:@"osm_notes_online_layer"])
            {
                [cell.switchView setOn:[_settings.mapSettingShowOnlineNotes get]];
                [cell.switchView addTarget:self action:@selector(showOnlineNotesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else if ([data[@"key"] hasPrefix:@"routes_"])
            {
                [cell.switchView setOn:[data[@"switch"] isEqualToString:@"true"]];
                [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                cell.switchView.tag = ((NSNumber *) data[@"tag"]).integerValue;
            }
        }
        outCell = cell;
    }
    else if ([data[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
        }

        if (cell)
        {
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if ([data[@"key"] isEqualToString:@"mapillary_layer"])
            {
                [cell.switchView setOn:[OsmAndApp instance].data.mapillary];
                [cell.switchView addTarget:self action:@selector(mapillaryChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"contour_lines_layer"])
            {
                BOOL contourLinesOn = true;
                OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
                if ([parameter.value  isEqual: @"disabled"])
                    contourLinesOn = false;
                [cell.switchView setOn: contourLinesOn];
                [cell.switchView addTarget:self action:@selector(contourLinesChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"overlay_layer"])
            {
                [cell.switchView setOn:_app.data.overlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(overlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"underlay_layer"])
            {
                [cell.switchView setOn:_app.data.underlayMapSource != nil];
                [cell.switchView addTarget:self action:@selector(underlayChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"terrain_layer"])
            {
                [cell.switchView setOn:_app.data.terrainType != EOATerrainTypeDisabled];
                [cell.switchView addTarget:self action:@selector(terrainChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"transport_layer"])
            {
                [cell.switchView setOn: [_styleSettings isCategoryEnabled:@"transport"]];
                [cell.switchView addTarget:self action:@selector(transportChanged:) forControlEvents:UIControlEventValueChanged];
            }
            if ([data[@"key"] isEqualToString:@"wikipedia_layer"])
            {
                [cell.switchView setOn:_app.data.wikipedia];
                [cell.switchView addTarget:self action:@selector(wikipediaChanged:) forControlEvents:UIControlEventValueChanged];
            }
            cell.textView.text = data[@"name"];
            NSString *desc = data[@"description"];
            NSString *secondaryImg = data[@"secondaryImg"];
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
    UISwitch *switchView = (UISwitch*)sender;
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
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        BOOL wikipediaOn = switchView.isOn;
        [[OsmAndApp instance].data setWikipedia:wikipediaOn];
    }
}

- (void) contourLinesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [_styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [_styleSettings save:parameter];
    }
}

- (void) overlayChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
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
    UISwitch *switchView = (UISwitch *)sender;
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
    UISwitch *switchView = (UISwitch*)sender;
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
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setShowFavorites:switchView.isOn];
}

- (void) showPoiLabelChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setShowPoiLabel:switchView.isOn];
}

- (void) showOfflineEditsChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setShowOfflineEdits:switchView.isOn];
}

- (void) showOnlineNotesChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings setShowOnlineNotes:switchView.isOn];
}

- (void) transportChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
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
    OAMapSettingsViewController *mapSettingsViewController;

    if (indexPath.section == _showSection)
    {
        if (indexPath.row == _poiRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPOI];
        else if (indexPath.row == _tracksRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
        else if (indexPath.row == _mapillaryRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapillaryFilter];
        else if (indexPath.row == _wikipediaRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWikipedia];
    }
    else if (indexPath.section == routesSection)
    {
        if (indexPath.row == cycleRoutesRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCycleRoutes];
        else if (indexPath.row == hikingRoutesRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenHikingRoutes];
        else if (indexPath.row == travelRoutesRow)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTravelRoutes];
    }
    else if (indexPath.section == mapTypeSection)
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
        ((OAMapSettingsMapTypeScreen *) mapSettingsViewController.screenObj).delegate = self;
    }
    else if (indexPath.section == mapStyleSection && !isOnlineMapSource)
    {
        NSArray *categories = [self getAllCategories];
        if (indexPath.row == 0)
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
        }
        else if (indexPath.row == 1)
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:mapDensityKey];
        }
        else if (indexPath.row == 2)
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:textSizeKey];
        }
        else if (indexPath.row == contourLinesRow)
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenContourLines];
        }
        else if (indexPath.row <= categories.count + 2)
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - kMapStyleTopSettingsCount]];
        }
        else
        {
            OAMapStyleParameter *parameter = _filteredTopLevelParams[indexPath.row - categories.count - kMapStyleTopSettingsCount];
            if (parameter.dataType != OABoolean)
            {
                OAMapSettingsViewController *parameterViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:parameter.name];
                [parameterViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
            }
        }
    }
    else if (indexPath.section == overlayUnderlaySection)
    {
        BOOL hasSrtm = [_iapHelper.srtm isActive];
        if (hasSrtm && indexPath.row == 0)
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
        else if ((hasSrtm && indexPath.row == 1) || (!hasSrtm && indexPath.row == 0))
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
        else if ((hasSrtm && indexPath.row == 2) || (!hasSrtm && indexPath.row == 1))
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
    }
    else if (indexPath.section == languageSection)
    {
        mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
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

- (void)refreshMenuRoutesParameters
{
    _routesParameters = [[OAMapStyleSettings sharedInstance] getParameters:@"routes"];
    if (routesSection != -1)
        [tblView reloadSections:[[NSIndexSet alloc] initWithIndex:routesSection] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
