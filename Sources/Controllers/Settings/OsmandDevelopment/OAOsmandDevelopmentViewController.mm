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
#import "OASwitchTableViewCell.h"
#import "OAPluginsHelper.h"

#define kCellSwitchIsOnKey @"kCellSwitchIsOnKey"

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
NSString *const kUseOldRouting = @"kUseOldRouting";
NSString *const kUseV1AutoZoom = @"kUseV1AutoZoom";

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _plugin = (OAOsmandDevelopmentPlugin *) [OAPluginsHelper getPlugin:OAOsmandDevelopmentPlugin.class];
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
    [simulationSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellKeyKey : kUseOldRouting,
        kCellTitleKey : OALocalizedString(@"osmand_depelopment_use_old_routing"),
        @"isOn" : @([[OAAppSettings sharedManager].useOldRouting get])
    }];
    [_data addSection:simulationSection];
    
    OATableSectionData *navigationSection = [OATableSectionData sectionData];
    navigationSection.headerText = OALocalizedString(@"shared_string_navigation");
    [navigationSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellKeyKey : kUseV1AutoZoom,
        kCellTitleKey : OALocalizedString(@"osmand_depelopment_use_discrete_autozoom"),
        @"isOn" : @([[OAAppSettings sharedManager].useV1AutoZoom get])
    }];
    [_data addSection:navigationSection];
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
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.switchView.on = [item boolForKey:@"isOn"];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];            
        }
        return cell;
    }
    return nil;
}

- (void)onSwitchPressed:(UISwitch *)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    if ([item.key isEqualToString:kUseOldRouting])
        [[OAAppSettings sharedManager].useOldRouting set:sender.isOn];
    else if ([item.key isEqualToString:kUseV1AutoZoom])
        [[OAAppSettings sharedManager].useV1AutoZoom set:sender.isOn];
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

#pragma mark - OAOsmandDevelopmentSimulateLocationDelegate

- (void)onSimulateLocationInformationUpdated
{
    [self generateData];
    [self.tableView reloadData];
}

@end
