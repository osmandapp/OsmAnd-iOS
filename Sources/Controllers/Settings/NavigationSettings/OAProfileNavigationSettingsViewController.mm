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
#import "OAMapPanelViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#define kOsmAndNavigation @"osmand_navigation"

static const CGFloat kOpenSettingsRowHeight = 44.0;

@interface OAProfileNavigationSettingsViewController () <OARouteLineAppearanceViewControllerDelegate>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;

    OAAppSettings *_settings;
    OARoutingProfilesHolder *_routingDataObjects;
}

#pragma mark - Initialization

- (void)registerNotifications
{
    [self addNotification:LiveActivityManager.authorizationDidChangeNotification selector:@selector(onLiveActivityAuthorizationChanged)];
}

- (void)registerCells
{
    [self addCell:OASwitchTableViewCell.reuseIdentifier];
}

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
    NSInteger trackGuidanceValue = [_settings.detailedTrackGuidance get:self.appMode];
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    NSMutableArray *detailedTrackArr = [NSMutableArray array];
    [navigationArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"nav_type_hint"),
        @"value" : routingData ? routingData.name : @"",
        @"icon" : routingData ? routingData.iconName : @"ic_custom_navigation",
        @"tintColor" : [UIColor colorNamed:ACColorNameIconColorDefault],
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
        @"footer" : OALocalizedString(@"change_map_behavior"),
    }];
    [detailedTrackArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"detailed_track_guidance"),
        @"value" : OALocalizedString(trackGuidanceValue == EOATrackApproximationManual ? @"ask_every_time" : @"shared_string_always"),
        @"icon" : @"ic_custom_attach_track",
        @"tintColor" : [UIColor colorNamed:ACColorNameIconColorActive],
        @"key" : @"detailedTrackGuidance",
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    [tableData addObject:detailedTrackArr];

    if (@available(iOS 16.2, *))
    {
        BOOL areActivitiesEnabled = LiveActivityManager.shared.areActivitiesEnabled;
        NSMutableArray *liveActivityRows = [NSMutableArray arrayWithObject:@{
            @"key" : @"live_activity",
            @"type" : OASwitchTableViewCell.reuseIdentifier,
            @"title" : OALocalizedString(@"live_activity"),
            @"value" : _settings.navigationLiveActivityEnabled,
            @"enabled" : @(areActivitiesEnabled),
            @"footer" : OALocalizedString(areActivitiesEnabled ? @"navigation_live_activity_description" : @"live_activity_system_disabled")
        }];
        if (!areActivitiesEnabled)
        {
            [liveActivityRows addObject:@{
                @"key" : @"open_live_activity_settings",
                @"type" : OASimpleTableViewCell.reuseIdentifier,
                @"title" : OALocalizedString(@"ant_plus_open_settings"),
                @"titleColor" : [UIColor colorNamed:ACColorNameTextColorActive],
                @"accessoryType" : @(UITableViewCellAccessoryNone),
                @"height" : @(kOpenSettingsRowHeight)
            }];
        }
        [tableData addObject:liveActivityRows];
    }

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
    return _data[section].firstObject[@"footer"] ?: @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSNumber *height = item[@"height"];
    return height ? height.doubleValue : UITableViewAutomaticDimension;
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
            cell.leftIconView.tintColor = item[@"tintColor"];
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
            [cell leftIconVisibility:[item[@"icon"] length] > 0];
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = item[@"titleColor"] ?: [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            cell.accessoryType = item[@"accessoryType"] ? (UITableViewCellAccessoryType) [item[@"accessoryType"] integerValue] : UITableViewCellAccessoryDisclosureIndicator;
            cell.accessibilityTraits = UIAccessibilityTraitButton;
            if (item[@"height"])
            {
                cell.topContentSpaceView.hidden = YES;
                cell.bottomContentSpaceView.hidden = YES;
            }
        }
        return cell;
    }
    else if ([cellType isEqualToString:OASwitchTableViewCell.reuseIdentifier])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:OASwitchTableViewCell.reuseIdentifier];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        BOOL enabled = !item[@"enabled"] || [item[@"enabled"] boolValue];
        cell.titleLabel.text = item[@"title"];
        cell.titleLabel.textColor = [UIColor colorNamed:enabled ? ACColorNameTextColorPrimary : ACColorNameTextColorSecondary];
        cell.userInteractionEnabled = enabled;
        cell.switchView.enabled = enabled;
        cell.switchView.on = [((OACommonBoolean *)item[@"value"]) get:self.appMode];
        cell.switchView.accessibilityLabel = item[@"title"];
        cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        [cell.switchView removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
        [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
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
    if ([itemKey isEqualToString:@"open_live_activity_settings"])
    {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
    else if ([itemKey isEqualToString:@"routeLineAppearance"])
    {
        if (self.openFromRouteInfo)
        {
            [self dismissViewControllerAnimated:YES completion:^{
                if ([self.delegate respondsToSelector:@selector(closeSettingsScreenWithRouteInfo)])
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
        else if ([itemKey isEqualToString:@"detailedTrackGuidance"])
            settingsViewController = [[DetailedTrackGuidanceViewController alloc] initWithAppMode:self.appMode];
        if (settingsViewController)
        {
            settingsViewController.delegate = self;
            [self showViewController:settingsViewController];
        }
    }
}

#pragma mark - OASettingsDataDelegate

- (void)onLiveActivityAuthorizationChanged
{
    [self generateData];
    [self.tableView reloadData];
}

- (void)applyParameter:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OACommonBoolean *value = item[@"value"];
    if (value == _settings.navigationLiveActivityEnabled && !LiveActivityManager.shared.areActivitiesEnabled)
    {
        sender.on = [value get:self.appMode];
        [self onLiveActivityAuthorizationChanged];
        return;
    }
    [value set:sender.on mode:self.appMode];
    [LiveActivityManager.shared refresh];
}

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
