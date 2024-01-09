//
//  OAProfileNavigationSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileNavigationSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OAVehicleParametersViewController.h"
#import "OAMapBehaviorViewController.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OARoutingDataObject.h"
#import "OARoutingDataUtils.h"
#import "OARoutingProfilesHolder.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#define kOsmAndNavigation @"osmand_navigation"

@interface OAProfileNavigationSettingsViewController () <OARouteLineAppearanceViewControllerDelegate>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;

    OAAppSettings *_settings;
    OARoutingProfilesHolder *_routingDataObjects;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _routingDataObjects = [OARoutingDataUtils getRoutingProfiles];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"routing_settings_2");
}

#pragma mark - Table data

- (void)generateData
{
    NSString *selectedProfileName = self.appMode.getRoutingProfile;
    NSString *derivedProfile = self.appMode.getDerivedProfile;
    OARoutingDataObject *routingData = [_routingDataObjects get:selectedProfileName derivedProfile:derivedProfile];
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [navigationArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"nav_type_hint"),
        @"value" : routingData ? routingData.name : @"",
        @"icon" : routingData ? routingData.iconName : @"ic_custom_navigation",
        @"key" : @"navigationType",
    }];
    [navigationArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"route_parameters"),
        @"icon" : @"ic_custom_route",
        @"key" : @"routeParams",
    }];
    [navigationArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"voice_announces"),
        @"icon" : @"ic_custom_sound",
        @"key" : @"voicePrompts",
    }];
    [navigationArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"key" : @"screenAlerts",
    }];
    [navigationArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"vehicle_parameters"),
        @"icon" : self.appMode.getIconName,
        @"key" : @"vehicleParams",
    }];
    [navigationArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"customize_route_line"),
        @"icon" : @"ic_custom_appearance",
        @"key" : @"routeLineAppearance",
    }];
    [otherArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_during_navigation"),
        @"key" : @"mapBehavior",
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    [tableData addObject:@[@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"animate_my_location")
    }]];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"routing_settings");
        case 1:
            return OALocalizedString(@"other_location");
        default:
            return @"";
    }
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    switch (section)
    {
        case 1:
            return OALocalizedString(@"change_map_behavior");
        case 2:
            return OALocalizedString(@"animate_my_location_descr");
        default:
            return @"";
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            [cell leftIconVisibility:![item[@"key"] isEqualToString:@"mapBehavior"]];
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = [_settings.animateMyLocation get:self.appMode];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    if ([itemKey isEqualToString:@"routeLineAppearance"])
    {
        if (self.openFromRouteInfo)
        {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate)
                    [self.delegate closeSettingsScreenWithRouteInfo];
            }];
        }
        else
        {
            [self.navigationController popToViewController:OARootViewController.instance animated:YES];
            OARouteLineAppearanceHudViewController *routeLineAppearanceHudViewController =
                [[OARouteLineAppearanceHudViewController alloc] initWithAppMode:self.appMode prevScreen:EOARouteLineAppearancePrevScreenSettings];
            routeLineAppearanceHudViewController.delegate = self;
            [OARootViewController.instance.mapPanel showScrollableHudViewController:routeLineAppearanceHudViewController];
        }
    }
    else
    {
        OABaseSettingsViewController *settingsViewController = nil;
        if ([itemKey isEqualToString:@"navigationType"])
            settingsViewController = [[OANavigationTypeViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"routeParams"])
            settingsViewController = [[OARouteParametersViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"voicePrompts"])
            settingsViewController = [[OAVoicePromptsViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"screenAlerts"])
            settingsViewController = [[OAScreenAlertsViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"vehicleParams"])
            settingsViewController = [[OAVehicleParametersViewController alloc] initWithAppMode:self.appMode];
        else if ([itemKey isEqualToString:@"mapBehavior"])
            settingsViewController = [[OAMapBehaviorViewController alloc] initWithAppMode:self.appMode];
        if (settingsViewController)
        {
            settingsViewController.delegate = self;
            [self showViewController:settingsViewController];
        }
    }
}

#pragma mark - Selectors

- (void)applyParameter:(UISwitch *)sender
{
    [_settings.animateMyLocation set:sender.isOn mode:self.appMode];
}

#pragma mark - OASettingsDataDelegate

- (void)onSettingsChanged
{
    [self generateData];
    [super onSettingsChanged];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

#pragma mark - OARouteLineAppearanceViewControllerDelegate

- (void)onCloseAppearance
{
    if (self.openFromRouteInfo)
    {
        [[OARootViewController instance].mapPanel showRouteInfo];
        [[OARootViewController instance].mapPanel showRoutePreferences];
    }
    else
    {
        OAMainSettingsViewController *settingsVC = [[OAMainSettingsViewController alloc] initWithTargetAppMode:self.appMode
                                                                                               targetScreenKey:kNavigationSettings];
        [OARootViewController.instance.navigationController pushViewController:settingsVC animated:NO];
    }
}

@end
