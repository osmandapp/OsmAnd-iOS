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
    EOAImportDataTypeOsmNotes,
    EOAImportDataTypeOsmEdits
};

@interface OAImportCompleteViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportCompleteViewController
{
    NSArray<OASettingsItem *> * _settingsItems;
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

- (instancetype) initWithSettingsItems:(NSArray<OASettingsItem *> *)settingsItems fileName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        _settingsItems = settingsItems;
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
    NSInteger profilesCount = 0;
    NSInteger actionsCount = 0;
    NSInteger filtersCount = 0;
    NSInteger tileSourcesCount = 0;
    NSInteger renderFilesCount = 0;
    NSInteger routingFilesCount = 0;
    NSInteger gpxFilesCount = 0;
    NSInteger avoidRoadsCount = 0;
    NSInteger mapsCount = 0;
    NSInteger osmNotesCount = 0;
    NSInteger osmEditsCount = 0;
    
    for (id item in _settingsItems)
    {
        if ([item isKindOfClass:OAProfileSettingsItem.class])
            profilesCount += 1;
        else if ([item isKindOfClass:OAQuickAction.class])
            actionsCount += 1;
        else if ([item isKindOfClass:OAPOIUIFilter.class])
            filtersCount += 1;
        else if ([item isKindOfClass:OAMapSourcesSettingsItem.class])
        {
            OAMapSourcesSettingsItem *mapSourcesItem = (OAMapSourcesSettingsItem *) item;
            tileSourcesCount = mapSourcesItem.items.count;
        }
        else if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            EOASettingsItemFileSubtype subType = ((OAFileSettingsItem *)item).subtype;
            if (subType == EOASettingsItemFileSubtypeRenderingStyle)
                renderFilesCount += 1;
            else if (subType == EOASettingsItemFileSubtypeRoutingConfig)
                routingFilesCount += 1;
            else if (subType == EOASettingsItemFileSubtypeGpx)
                gpxFilesCount += 1;
            else if ([OAFileSettingsItemFileSubtype isMap:subType])
                mapsCount += 1;
        }
        else if ([item isKindOfClass:OAAvoidRoadInfo.class])
            avoidRoadsCount += 1;
        else if ([item isKindOfClass:OAOsmNotesSettingsItem.class])
            osmNotesCount += ((OAOsmNotesSettingsItem *)item).items.count;
        else if ([item isKindOfClass:OAOsmEditsSettingsItem.class])
            osmEditsCount += ((OAOsmEditsSettingsItem *)item).items.count;
    }
    
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
            @"count": [NSString stringWithFormat:@"%ld", profilesCount],
            @"category" : @(EOAImportDataTypeQuickActions)
            }
         ];
    }
    if (filtersCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"search_activity"),
            @"iconName": @"ic_custom_search",
            @"count": [NSString stringWithFormat:@"%ld", profilesCount],
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
            @"count": [NSString stringWithFormat:@"%ld", profilesCount],
            @"category" : @(EOAImportDataTypeGpxTrips)
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
    [cell.overflowButton setImage:[[UIImage imageNamed:item[@"iconName"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateDisabled];
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
        // TODO: change this while implementing Avoid roads import!
        [self loadCurrentRoutingMode];
        OARouteAvoidSettingsViewController *avoidController = [[OARouteAvoidSettingsViewController alloc] init];
        [rootController.navigationController pushViewController:avoidController animated:YES];
    }
    else if (dataType == EOAImportDataTypeMaps)
    {
        UIViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
        [rootController.navigationController pushViewController:resourcesViewController animated:YES];
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
            [OAPluginPopupViewController showOsmEditingDisabled];
        }
    }
}

@end
