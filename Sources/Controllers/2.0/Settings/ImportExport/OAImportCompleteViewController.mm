//
//  OAImportComplete.m
//  OsmAnd
//
//  Created by nnngrach on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportCompleteViewController.h"
#import "OARootViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAMapSettingsViewController.h"
#import "OAQuickActionListViewController.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OAMapSettingsViewController.h"
#import "OARoutingHelper.h"
#import "OAMapActions.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAProfileDataObject.h"
#import "OAQuickAction.h"
#import "OASQLiteTileSource.h"
#import "OAPOIUIFilter.h"
#import "OAAvoidRoadInfo.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIndexConstants.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAFavoritesHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "OAAvoidRoadInfo.h"
#import "OAMarkersSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OADestination.h"

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kIconTitleButtonCell @"OAIconTitleButtonCell"

typedef NS_ENUM(NSInteger, EOAImportDataType) {
    EOAImportDataTypeProfiles = 0,
    EOAImportDataTypeQuickActions,
    EOAImportDataTypeTileSources,
    EOAImportDataTypePoiFilters,
    EOAImportDataTypeRenderSettings,
    EOAImportDataTypeRoutingSettings,
    EOAImportDataTypeAvoidRoads,
    EOAImportDataTypeGpxTrips,
    EOAImportDataTypeMaps,
    EOAImportDataTypeFavorites,
    EOAImportDataTypeOsmNotes,
    EOAImportDataTypeOsmEdits,
    EOAImportDataTypeActiveMarkers,
    EOAImportDataTypeSearchHistory,
    EOAImportDataTypeGlobal
};

@interface OAImportCompleteViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportCompleteViewController
{
    NSDictionary<OAExportSettingsType *, NSArray *> *_itemsMap;
    NSArray <NSString *>*_itemsType;
    NSString *_fileName;
    NSMutableArray<NSDictionary *> * _data;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithSettingsItems:(NSDictionary<OAExportSettingsType *, NSArray *> *)settingsItems fileName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        _itemsMap = settingsItems;
        _itemsType = [NSArray arrayWithArray:[settingsItems allKeys]];
        _fileName = fileName;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    __block NSInteger profilesCount = 0;
    __block NSInteger actionsCount = 0;
    __block NSInteger filtersCount = 0;
    __block NSInteger tileSourcesCount = 0;
    __block NSInteger renderFilesCount = 0;
    __block NSInteger routingFilesCount = 0;
    __block NSInteger gpxFilesCount = 0;
    __block NSInteger avoidRoadsCount = 0;
    __block NSInteger mapsCount = 0;
    __block NSInteger favoritesCount = 0;
    __block NSInteger osmNotesCount = 0;
    __block NSInteger osmEditsCount = 0;
    __block NSInteger markersCount = 0;
    __block NSInteger searchHistoryCount = 0;
    __block NSInteger globalCount = 0;

    [_itemsMap enumerateKeysAndObjectsUsingBlock:^(OAExportSettingsType * _Nonnull type, NSArray * _Nonnull settings, BOOL * _Nonnull stop) {
        if (type == OAExportSettingsType.PROFILE)
            profilesCount += settings.count;
        else if (type == OAExportSettingsType.QUICK_ACTIONS)
            actionsCount += settings.count;
        else if (type == OAExportSettingsType.POI_TYPES)
            filtersCount += settings.count;
        else if (type == OAExportSettingsType.MAP_SOURCES)
            tileSourcesCount += settings.count;
        else if (type == OAExportSettingsType.CUSTOM_RENDER_STYLE)
            renderFilesCount += settings.count;
        else if (type == OAExportSettingsType.OFFLINE_MAPS)
            mapsCount += settings.count;
        else if (type == OAExportSettingsType.CUSTOM_ROUTING)
            routingFilesCount += settings.count;
        else if (type == OAExportSettingsType.TRACKS)
            gpxFilesCount += settings.count;
        else if (type == OAExportSettingsType.AVOID_ROADS)
            avoidRoadsCount += settings.count;
        else if (type == OAExportSettingsType.FAVORITES)
            favoritesCount += settings.count;
        else if (type == OAExportSettingsType.OSM_NOTES)
            osmNotesCount += settings.count;
        else if (type == OAExportSettingsType.OSM_EDITS)
            osmEditsCount += settings.count;
        else if (type == OAExportSettingsType.ACTIVE_MARKERS)
            markersCount += settings.count;
        else if (type == OAExportSettingsType.SEARCH_HISTORY)
            searchHistoryCount += settings.count;
        else if (type == OAExportSettingsType.GLOBAL)
            globalCount += settings.count;
    }];
    
    if (profilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_settings"),
            @"iconName": @"ic_action_settings",
            @"count": [NSString stringWithFormat:@"%ld", profilesCount],
            @"category" : @(EOAImportDataTypeProfiles)
            }
         ];
    }
    if (actionsCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"configure_screen_quick_action"),
            @"iconName": @"ic_custom_quick_action",
            @"count": [NSString stringWithFormat:@"%ld", actionsCount],
            @"category" : @(EOAImportDataTypeQuickActions)
            }
         ];
    }
    if (filtersCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"search_activity"),
            @"iconName": @"ic_custom_search",
            @"count": [NSString stringWithFormat:@"%ld", filtersCount],
            @"category" : @(EOAImportDataTypePoiFilters)
            }
         ];
    }
    if (tileSourcesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"configure_map"),
            @"iconName": @"ic_custom_overlay_map",
            @"count": [NSString stringWithFormat:@"%ld", tileSourcesCount],
            @"category" : @(EOAImportDataTypeTileSources)
            }
         ];
    }
    if (renderFilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_rendering_style"),
            @"iconName": @"ic_custom_map_style",
            @"count": [NSString stringWithFormat:@"%ld",renderFilesCount],
            @"category" : @(EOAImportDataTypeRenderSettings)
            }
         ];
    }
    if (routingFilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_routing"),
            @"iconName": @"ic_action_route_distance",
            @"count": [NSString stringWithFormat:@"%ld",routingFilesCount],
            @"category" : @(EOAImportDataTypeRoutingSettings)
            }
         ];
    }
    if (gpxFilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"tracks"),
            @"iconName": @"ic_custom_trip",
            @"count": [NSString stringWithFormat:@"%ld", gpxFilesCount],
            @"category" : @(EOAImportDataTypeGpxTrips)
            }
         ];
    }
    if (avoidRoadsCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"avoid_road"),
            @"iconName": @"ic_custom_alert",
            @"count": [NSString stringWithFormat:@"%ld", avoidRoadsCount],
            @"category" : @(EOAImportDataTypeAvoidRoads)
            }
         ];
    }
    if (mapsCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"maps"),
            @"iconName": @"ic_custom_map",
            @"count": [NSString stringWithFormat:@"%ld", mapsCount],
            @"category" : @(EOAImportDataTypeMaps)
            }
         ];
    }
    if (favoritesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"favorites"),
            @"iconName": @"ic_custom_favorites",
            @"count": [NSString stringWithFormat:@"%ld", favoritesCount],
            @"category" : @(EOAImportDataTypeFavorites)
            }
         ];
    }
    if (osmNotesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"osm_notes"),
            @"iconName": @"ic_action_add_osm_note",
            @"count": [NSString stringWithFormat:@"%ld", osmNotesCount],
            @"category" : @(EOAImportDataTypeOsmNotes)
            }
         ];
    }
    if (osmEditsCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"osm_edits_title"),
            @"iconName": @"ic_custom_poi",
            @"count": [NSString stringWithFormat:@"%ld", osmEditsCount],
            @"category" : @(EOAImportDataTypeOsmNotes)
            }
         ];
    }
    if (markersCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"map_markers"),
            @"iconName": @"ic_custom_marker",
            @"count": [NSString stringWithFormat:@"%ld", markersCount],
            @"category" : @(EOAImportDataTypeActiveMarkers)
            }
         ];
    }
    if (searchHistoryCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"search_history"),
            @"iconName": @"ic_custom_history",
            @"count": [NSString stringWithFormat:@"%ld", searchHistoryCount],
            @"category" : @(EOAImportDataTypeSearchHistory)
            }
         ];
    }
    if (globalCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"general_settings_2"),
            @"iconName": @"left_menu_icon_settings",
            @"count": [NSString stringWithFormat:@"%ld", globalCount],
            @"category" : @(EOAImportDataTypeGlobal)
            }
         ];
    }
}
 
- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"shared_string_import_complete");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.backButton.hidden = YES;
    self.backImageButton.hidden = YES;
    
    self.primaryBottomButton.hidden = YES;
    self.secondaryBottomButton.hidden = NO;
    [self.secondaryBottomButton setTitle:OALocalizedString(@"shared_string_finish") forState:UIControlStateNormal];
    
    self.additionalNavBarButton.hidden = YES;
    [super viewDidLoad];
}

-(void) loadCurrentRoutingMode
{
    OAMapActions *mapActions = [[OAMapActions alloc] init];
    OAApplicationMode *currentRoutingMode = [mapActions getRouteMode];
    [OARoutingHelper.sharedInstance setAppMode:currentRoutingMode];
}

#pragma mark - Actions

- (IBAction)secondaryButtonPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
      
    OAMultiIconTextDescCell *cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAMultiIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMultiIconTextDescCell" owner:self options:nil];
        cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
    }
    [cell.textView setText:item[@"label"]];
    NSString *countString = [NSString stringWithFormat:OALocalizedString(@"added_items"), item[@"count"]];
    [cell.descView setText:countString];
    cell.iconView.hidden = YES;
    cell.overflowButton.enabled = NO;
    [cell.overflowButton setImage:[UIImage templateImageNamed:item[@"iconName"]] forState:UIControlStateDisabled];
    [cell.overflowButton setTintColor:UIColorFromRGB(color_primary_purple)];
    [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
    cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:(NSString *)OALocalizedString(@"import_complete_description") boldFragment:_fileName forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:OALocalizedString(@"import_complete_description") boldFragment:_fileName inSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    [self.navigationController popToRootViewControllerAnimated:NO];
    OARootViewController *rootController = [OARootViewController instance];
    EOAImportDataType dataType = (EOAImportDataType) [item[@"category"] integerValue];
    if (dataType == EOAImportDataTypeProfiles || dataType == EOAImportDataTypeRoutingSettings)
    {
        OAMainSettingsViewController *profileSettings = [[OAMainSettingsViewController alloc] init];
        [rootController.navigationController pushViewController:profileSettings animated:YES];
    }
    else if (dataType == EOAImportDataTypeQuickActions)
    {
        OAQuickActionListViewController *actionsList = [[OAQuickActionListViewController alloc] init];
        [rootController.navigationController pushViewController:actionsList animated:YES];
    }
    else if (dataType == EOAImportDataTypePoiFilters)
    {
        [rootController.mapPanel openSearch];
    }
    else if (dataType == EOAImportDataTypeTileSources)
    {
        [rootController.mapPanel mapSettingsButtonClick:nil];
    }
    else if (dataType == EOAImportDataTypeRenderSettings)
    {
        [rootController.mapPanel showMapStylesScreen];
    }
    else if (dataType == EOAImportDataTypeGpxTrips)
    {
        UITabBarController* myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [myPlacesViewController setSelectedIndex:1];
        [rootController.navigationController pushViewController:myPlacesViewController animated:YES];
    }
    else if (dataType == EOAImportDataTypeAvoidRoads)
    {
        OARouteAvoidSettingsViewController *avoidController = [[OARouteAvoidSettingsViewController alloc] init];
        [self presentViewController:avoidController animated:YES completion:nil];
    }
    else if (dataType == EOAImportDataTypeMaps)
    {
        UIViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
        [rootController.navigationController pushViewController:resourcesViewController animated:YES];
    }
    else if (dataType == EOAImportDataTypeFavorites)
    {
        UIViewController* favoritesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [rootController.navigationController pushViewController:favoritesViewController animated:YES];
    }
    else if (dataType == EOAImportDataTypeOsmNotes || dataType == EOAImportDataTypeOsmEdits)
    {
        BOOL isOsmEditingEnabled = [[OAIAPHelper sharedInstance].osmEditing isActive];
        if (isOsmEditingEnabled)
        {
            UITabBarController* myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
            [myPlacesViewController setSelectedIndex:2];
            [rootController.navigationController pushViewController:myPlacesViewController animated:YES];
        }
        else
        {
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_OsmEditing];
        }
    }
    else if (dataType == EOAImportDataTypeActiveMarkers)
    {
        [rootController.mapPanel showCards];
    }
    else if (dataType == EOAImportDataTypeSearchHistory)
    {
        [rootController.mapPanel openSearch];
    }
    else if (dataType == EOAImportDataTypeGlobal)
    {
        OAMainSettingsViewController *settingsVC = [[OAMainSettingsViewController alloc] init];
        [rootController.navigationController pushViewController:settingsVC animated:NO];
    }
}

@end
