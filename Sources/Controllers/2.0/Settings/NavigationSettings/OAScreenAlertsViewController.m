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
#import "OAAvoidRoadsViewController.h"
#import "OARecalculateRouteViewController.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAScreenAlertsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAScreenAlertsViewController
{
    NSArray<NSArray *> *_data;
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

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"screen_alerts");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
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
        @"type" : @"OADeviceScreenTableViewCell",
        @"foregroundImage" : @"img_settings_sreen_route_alerts@3x.png",
        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
    }];
    [otherArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"isOn" : @YES,
    }];
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"show_traffic_warnings"),
        @"icon" : @"list_warnings_traffic_calming",
        @"isOn" : @YES,
    }];
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"icon" : @"list_warnings_pedestrian",
        @"isOn" : @YES,
    }];
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"show_cameras"),
        @"icon" : @"list_warnings_speed_camera",
        @"isOn" : @NO,
    }];
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"show_tunnels"),
        @"icon" : @"list_warnings_tunnel",
        @"isOn" : @NO,
    }];
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OADeviceScreenTableViewCell"])
    {
        static NSString* const identifierCell = @"OADeviceScreenTableViewCell";
        OADeviceScreenTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
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
    else if ([cellType isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.imgView.image = [UIImage imageNamed:item[@"icon"]];
            cell.switchView.on = [item[@"isOn"] boolValue];
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
    return _data.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.01 : 19.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OABaseSettingsViewController* settingsViewController = nil;
    if (indexPath.row == 0)
    {
        settingsViewController = [[OARecalculateRouteViewController alloc] init];
    }
    else if (indexPath.row == 1)
    {
        settingsViewController = [[OAAvoidRoadsViewController alloc] init];
    }
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
}

@end

