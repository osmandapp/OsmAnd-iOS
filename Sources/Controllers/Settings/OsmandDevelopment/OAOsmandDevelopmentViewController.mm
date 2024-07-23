//
//  OAOsmandDevelopmentViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentViewController.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OAAppSettings.h"
#import "Localization.h"
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
#import "OAPluginsHelper.h"
#import "OASwitchTableViewCell.h"
#import "OAObservable.h"

@interface OAOsmandDevelopmentViewController () <OAOsmandDevelopmentSimulateLocationDelegate>

@end

@implementation OAOsmandDevelopmentViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    OAOsmandDevelopmentPlugin *_plugin;
}

NSString *const kCellSwitchIsOnKey = @"kCellSwitchIsOnKey";
NSString *const kUse3dIconsKey = @"kUse3dIconsKey";
NSString *const kSimulateLocationKey = @"kSimulateLocationKey";

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
    [_data addSection:simulationSection];
    
    OATableSectionData *renderingSection = [OATableSectionData sectionData];
    renderingSection.headerText = OALocalizedString(@"shared_string_appearance");
    [renderingSection addRowFromDictionary:@{
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellKeyKey : kUse3dIconsKey,
        kCellTitleKey : OALocalizedString(@"osmand_depelopment_use_3d_icons"),
        @"isOn" : @([[OAAppSettings sharedManager].use3dIconsByDefault get])
    }];
    [_data addSection:renderingSection];
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
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
    
    if ([item.key isEqualToString:kUse3dIconsKey])
    {
        [[OAAppSettings sharedManager].use3dIconsByDefault set:sender.isOn];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }
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
