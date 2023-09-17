//
//  OAOsmandDevelopmentViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OALocationSimulation.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableRowData.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OAOsmandDevelopmentSimulateLocationViewController.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAPlugin.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OARootViewController.h"
#import "OAIndexConstants.h"

#define kCellSwitchIsOnKey @"kCellSwitchIsOnKey"
#define kCellSwitchEnabledKey @"kCellSwitchEnabledKey"
#define kCellSwitchUserInteractionEnabledKey @"kCellSwitchUserInteractionEnabledKey"

@interface OAOsmandDevelopmentViewController () <OAOsmandDevelopmentSimulateLocationDelegate>

@end

@implementation OAOsmandDevelopmentViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    OAOsmandDevelopmentPlugin *_plugin;
}

NSString *const kSimulateLocationKey = @"kSimulateLocationKey";
NSString *const kTestHeightmapKey = @"kTestHeightmapKey";
NSString *const kDisableVertexHillshade = @"kDisableVertexHillshade";
NSString *const kGenerateHillshadeKey = @"kGenerateHillshadeKey";
NSString *const kGenerateSlopeKey = @"kGenerateSlopeKey";

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _plugin = (OAOsmandDevelopmentPlugin *) [OAPlugin getPlugin:OAOsmandDevelopmentPlugin.class];
}

- (void)registerNotifications
{
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"debugging_and_development");;
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"osm_editing_settings_descr");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    BOOL isRouteAnimating = [[OsmAndApp instance].locationServices.locationSimulation isRouteAnimating];
    _data = [OATableDataModel model];
    __weak OAOsmandDevelopmentViewController *weakSelf = self;
    OATableSectionData *simulationSection = [OATableSectionData sectionData];
    simulationSection.headerText = OALocalizedString(@"osmand_depelopment_simulate_location_section");
    [simulationSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellKeyKey : kSimulateLocationKey,
        kCellTitleKey : OALocalizedString(@"simulate_your_location"),
        kCellDescrKey : isRouteAnimating ? OALocalizedString(@"simulate_in_progress") : @"",
        @"actionBlock" : (^void(){ [weakSelf openSimulateLocationSettings]; })
    }];
    [_data addSection:simulationSection];
    
    OATableSectionData *heightMapSection = [OATableSectionData sectionData];
    heightMapSection.headerText = OALocalizedString(@"download_heightmap_maps");
    BOOL heightmapEnabled = [_plugin isHeightmapEnabled];
    
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kTestHeightmapKey,
        kCellTitleKey : OALocalizedString(@"test_heightmap"),
        kCellSwitchIsOnKey : @(heightmapEnabled ? [_plugin.enableHeightmap get] : NO),
        kCellSwitchEnabledKey : @([OAIAPHelper isOsmAndProAvailable]),
        kCellSwitchUserInteractionEnabledKey : @(YES),
        @"actionBlock" : (^void(){ [weakSelf openProPlanScreen]; })
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kDisableVertexHillshade,
        kCellTitleKey : OALocalizedString(@"disable_vertex_hillshade_3d"),
        kCellSwitchIsOnKey : @([_plugin.disableVertexHillshade3D get]),
        kCellSwitchEnabledKey : @(YES),
        kCellSwitchUserInteractionEnabledKey : @(heightmapEnabled)
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kGenerateSlopeKey,
        kCellTitleKey : OALocalizedString(@"generate_slope_from_3d_maps"),
        kCellSwitchIsOnKey : @([_plugin.generateSlopeFrom3DMaps get]),
        kCellSwitchEnabledKey : @(YES),
        kCellSwitchUserInteractionEnabledKey : @(heightmapEnabled)
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kGenerateHillshadeKey,
        kCellTitleKey : OALocalizedString(@"generate_hillshade_from_3d_maps"),
        kCellSwitchIsOnKey : @([_plugin.generateHillshadeFrom3DMaps get]),
        kCellSwitchEnabledKey : @(YES),
        kCellSwitchUserInteractionEnabledKey : @(heightmapEnabled)
    }];
    [_data addSection:heightMapSection];
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *type = item.cellType;
    
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = item.descr;
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.switchView.tintColor = UIColorFromRGB(color_bottom_sheet_secondary);
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.userInteractionEnabled = [item boolForKey:kCellSwitchUserInteractionEnabledKey];
            cell.switchView.userInteractionEnabled = [item boolForKey:kCellSwitchEnabledKey];
            
            cell.titleLabel.textColor = [item boolForKey:kCellSwitchUserInteractionEnabledKey] ? UIColor.blackColor : UIColorFromRGB(color_bottom_sheet_secondary);
            cell.titleLabel.text = item.title;
            cell.switchView.onTintColor = [item boolForKey:kCellSwitchUserInteractionEnabledKey] ? UIColorFromRGB(color_uiswitch_on_day) : UIColorFromRGB(color_footer_icon_gray);
            cell.switchView.on = [item boolForKey:kCellSwitchIsOnKey];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}

#pragma mark - Additions

- (void)openSimulateLocationSettings
{
    OAOsmandDevelopmentSimulateLocationViewController *vc = [[OAOsmandDevelopmentSimulateLocationViewController alloc] init];
    vc.simulateLocationDelegate = self;
    [self showViewController:vc];
}

- (void)openProPlanScreen
{
    if (![OAIAPHelper isOsmAndProAvailable])
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:[OAIAPHelper sharedInstance].proMonthly navController:self.navigationController];
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

#pragma mark - Selectors

- (void)applyParameter:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    BOOL isOn = sender.isOn;
    
    if ([item.key isEqualToString:kTestHeightmapKey])
    {
        [_plugin.enableHeightmap set:isOn];
        [self generateData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if ([item.key isEqualToString:kDisableVertexHillshade])
    {
        [_plugin.disableVertexHillshade3D set:isOn];
    }
    else if ([item.key isEqualToString:kGenerateSlopeKey])
    {
        [_plugin.generateSlopeFrom3DMaps set:isOn];
    }
    else if ([item.key isEqualToString:kGenerateHillshadeKey])
    {
        [_plugin.generateHillshadeFrom3DMaps set:isOn];
    }
}

#pragma mark - OAOsmandDevelopmentSimulateLocationDelegate

- (void)onSimulateLocationInformationUpdated
{
    [self generateData];
    [self.tableView reloadData];
}

@end
