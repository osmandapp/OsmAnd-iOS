//
//  OAScreenAlertsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAScreenAlertsViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAvoidPreferParametersViewController.h"
#import "OARecalculateRouteViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAScreenAlertsViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    BOOL _showAlerts;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    _showAlerts = [_settings.showScreenAlerts get:self.appMode];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"screen_alerts");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    
    [otherArr addObject:@{
        @"type" : [OADeviceScreenTableViewCell getCellIdentifier],
        @"foregroundImage" : @"img_settings_sreen_route_alerts@3x.png",
        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
    }];
    [otherArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"value" : _settings.showScreenAlerts,
        @"key" : @"screenAlerts",
    }];
    [parametersArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"traffic_warning_speed_limit"),
        @"icon" : [self getSpeedLimitIcon],
        @"value" : _settings.showSpeedLimitWarnings,
    }];
    [parametersArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_traffic_warnings"),
        @"icon" : @"list_warnings_traffic_calming",
        @"value" : _settings.showTrafficWarnings,
    }];
    [parametersArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"icon" : @"list_warnings_pedestrian",
        @"value" : _settings.showPedestrian,
    }];

    if (![_settings.speedCamerasUninstalled get])
    {
        [parametersArr addObject:@{
            @"type" : [OASwitchTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"show_cameras"),
            @"icon" : @"list_warnings_speed_camera",
            @"value" : _settings.showCameras,
        }];
    }

    [parametersArr addObject:@{
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_tunnels"),
        @"icon" : @"list_warnings_tunnel",
        @"value" : _settings.showTunnels,
    }];
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OADeviceScreenTableViewCell getCellIdentifier]])
    {
        OADeviceScreenTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OADeviceScreenTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeviceScreenTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADeviceScreenTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundImageView.image = [UIImage imageNamed:item[@"backgroundImage"]].imageFlippedForRightToLeftLayoutDirection;
            cell.foregroundImageView.image = [UIImage imageNamed:item[@"foregroundImage"]].imageFlippedForRightToLeftLayoutDirection;
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
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            if ([item[@"key"] isEqualToString:@"screenAlerts"])
            {
                cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
                cell.leftIconView.tintColor = _showAlerts ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
            }
            else
            {
                cell.leftIconView.image = [UIImage rtlImageNamed:item[@"icon"]];
            }
            id v = item[@"value"];
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OACommonBoolean class]])
            {
                OACommonBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _showAlerts ? _data.count : 1;
}

#pragma mark - Selectors

- (void) updateTableView
{
    if (_showAlerts)
    {
        [self.tableView beginUpdates];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    BOOL isChecked = ((UISwitch *) sender).on;
    id v = item[@"value"];
    if ([v isKindOfClass:[OACommonBoolean class]])
    {
        OACommonBoolean *value = v;
        [value set:isChecked mode:self.appMode];
        if ([[v key] isEqualToString:@"showScreenAlerts"])
        {
            _showAlerts = isChecked;
            [self updateTableView];
        }
    }
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

#pragma mark - Additions

- (NSString *)getSpeedLimitIcon
{
    OAApplicationMode *mode = [_settings.applicationMode get];
    if ([_settings.drivingRegion get:mode] == DR_US)
        return @"list_warnings_speed_limit_us";
    else if ([_settings.drivingRegion get:mode] == DR_CANADA)
        return @"list_warnings_speed_limit_ca";
    return @"list_warnings_limit";
}

@end
