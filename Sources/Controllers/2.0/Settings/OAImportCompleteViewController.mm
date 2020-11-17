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

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kIconTitleButtonCell @"OAIconTitleButtonCell"
#define kProfiles @"kProfiles"
#define kQuickActioins @"kQuickActioins"
#define kTileSources @"kTileSources"
#define kPoiFilters @"kPoiFilters"
#define kRenderSettings @"kRenderSettings"
#define kRoutingSettings @"kRoutingSettings"
#define kAvoidRoads @"kAvoidRoads"

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
    NSInteger avoidRoads = 0;
    
    for (id item in _settingsItems)
    {
        if ([item isKindOfClass:OAProfileSettingsItem.class])
            profilesCount += 1;
        else if ([item isKindOfClass:OAQuickActionsSettingsItem.class])
            actionsCount += ((OAQuickActionsSettingsItem *)item).items.count;
        else if ([item isKindOfClass:OAPOIUIFilter.class])
            filtersCount += 1;
        else if ([item isKindOfClass:OAMapSourcesSettingsItem.class])
        {
            OAMapSourcesSettingsItem *mapSourcesItem = (OAMapSourcesSettingsItem *) item;
            tileSourcesCount = mapSourcesItem.items.count;
        }
        else if ([item isKindOfClass:NSString.class])
        {
            NSString *filePath = (NSString *)item;
            if ([filePath containsString:RENDERERS_DIR])
                renderFilesCount += 1;
            if ([filePath containsString:ROUTING_PROFILES_DIR])
                routingFilesCount += 1;
        }
        else if ([item isKindOfClass:OAAvoidRoadInfo.class])
            avoidRoads += 1;
    }
    
    if (profilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_settings"),
            @"iconName": @"ic_action_settings",
            @"count": [NSString stringWithFormat:@"%ld",(long)profilesCount],
            @"category" : kProfiles
            }
         ];
    }
    if (actionsCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"configure_screen_quick_action"),
            @"iconName": @"ic_custom_quick_action",
            @"count": [NSString stringWithFormat:@"%ld",(long)actionsCount],
            @"category" : kQuickActioins
            }
         ];
    }
    if (filtersCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"search_activity"),
            @"iconName": @"ic_custom_search",
            @"count": [NSString stringWithFormat:@"%ld",(long)profilesCount],
            @"category" : kPoiFilters
            }
         ];
    }
    if (tileSourcesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"configure_map"),
            @"iconName": @"ic_custom_overlay_map",
            @"count": [NSString stringWithFormat:@"%ld", (long)tileSourcesCount],
            @"category" : kTileSources
            }
         ];
    }
    if (renderFilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_rendering_style"),
            @"iconName": @"ic_custom_map_style",
            @"count": [NSString stringWithFormat:@"%ld",(long)profilesCount],
            @"category" : kRenderSettings
            }
         ];
    }
    if (routingFilesCount > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"shared_string_routing"),
            @"iconName": @"ic_action_route_distance",
            @"count": [NSString stringWithFormat:@"%ld",(long)profilesCount],
            @"category" : kRoutingSettings
            }
         ];
    }
    if (avoidRoads > 0)
    {
        [_data addObject: @{
            @"label": OALocalizedString(@"avoid_road"),
            @"iconName": @"ic_custom_alert",
            @"count": [NSString stringWithFormat:@"%ld",(long)profilesCount],
            @"category" : kAvoidRoads
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
    NSString *category = (NSString *) item[@"category"];
    [self.navigationController popToRootViewControllerAnimated:NO];
    OARootViewController *rootController = [OARootViewController instance];
    if ([category isEqualToString:kProfiles] || [category isEqualToString:kRoutingSettings])
    {
        OAMainSettingsViewController *profileSettings = [[OAMainSettingsViewController alloc] init];
        [rootController.navigationController pushViewController:profileSettings animated:YES];
    }
    else if ([category isEqualToString:kQuickActioins])
    {
        OAQuickActionListViewController *actionsList = [[OAQuickActionListViewController alloc] init];
        [rootController.navigationController pushViewController:actionsList animated:YES];
    }
    else if ([category isEqualToString:kPoiFilters])
    {
        [rootController.mapPanel openSearch];
    }
    else if ([category isEqualToString:kTileSources])
    {
        [rootController.mapPanel mapSettingsButtonClick:nil];
    }
    else if ([category isEqualToString:kRenderSettings])
    {
        [rootController.mapPanel showMapStylesScreen];
    }
    else if ([category isEqualToString:kAvoidRoads])
    {
        // TODO: change this while implementing Avoid roads import!
        [self loadCurrentRoutingMode];
        OARouteAvoidSettingsViewController *avoidController = [[OARouteAvoidSettingsViewController alloc] init];
        [rootController.navigationController pushViewController:avoidController animated:YES];
    }
}


@end
