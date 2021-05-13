//
//  OAScreenAlertsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAScreenAlertsViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAAvoidPreferParametersViewController.h"
#import "OARecalculateRouteViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAScreenAlertsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAScreenAlertsViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    BOOL _showAlerts;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _showAlerts = [_settings.showScreenAlerts get:self.appMode];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"screen_alerts");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
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
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"value" : _settings.showScreenAlerts,
        @"key" : @"screenAlerts",
    }];
    [parametersArr addObject:@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_traffic_warnings"),
        @"icon" : @"list_warnings_traffic_calming",
        @"value" : _settings.showTrafficWarnings,
    }];
    [parametersArr addObject:@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"icon" : @"list_warnings_pedestrian",
        @"value" : _settings.showPedestrian,
    }];
    [parametersArr addObject:@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_cameras"),
        @"icon" : @"list_warnings_speed_camera",
        @"value" : _settings.showCameras,
    }];
    [parametersArr addObject:@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"title" : OALocalizedString(@"show_tunnels"),
        @"icon" : @"list_warnings_tunnel",
        @"value" : _settings.showTunnels,
    }];
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OADeviceScreenTableViewCell getCellIdentifier]])
    {
        OADeviceScreenTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADeviceScreenTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeviceScreenTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADeviceScreenTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundImageView.image = [UIImage imageNamed:item[@"backgroundImage"]];
            cell.foregroundImageView.image = [UIImage imageNamed:item[@"foregroundImage"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            if ([item[@"key"] isEqualToString:@"screenAlerts"])
            {
                cell.imgView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imgView.tintColor = _showAlerts ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
            }
            else
            {
                cell.imgView.image = [UIImage imageNamed:item[@"icon"]];
            }
            id v = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
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

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _showAlerts ? _data.count : 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.01 : 19.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - Switch

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
    if ([v isKindOfClass:[OAProfileBoolean class]])
    {
        OAProfileBoolean *value = v;
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

@end

