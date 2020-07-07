//
//  OARouteParametersViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParametersViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAAvoidPreferParametersViewController.h"
#import "OARecalculateRouteViewController.h"
#import "OARoutePreferencesParameters.h"

#import "Localization.h"
#import "OAColors.h"

@interface OARouteParametersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OARouteParametersViewController
{
    NSArray<NSArray *> *_data;
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"route_params");
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
        @"foregroundImage" : @"img_settings_sreen_route_parameters@3x.png",
        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
    }];
    [parametersArr addObject:@{
        @"type" : @"OAIconTitleValueCell",
        @"title" : OALocalizedString(@"recalculate_route"),
        @"value" : @"120 m", // has to be changed
        @"icon" : @"ic_custom_minimal_distance",
        @"key" : @"recalculateRoute",
    }];
    [parametersArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"impassable_road"),
        @"icon" : @"ic_custom_alert",
        @"key" : @"avoidRoads"
    }];
    if ([OAAvoidPreferParametersViewController hasPreferParameters:self.appMode])
    {
        [parametersArr addObject:@{
            @"type" : @"OAIconTextCell",
            @"title" : OALocalizedString(@"prefer_in_routing_title"),
            @"key" : @"preferRoads"
        }];
    }
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"routing_attr_short_way_name"),
        @"icon" : @"ic_custom_fuel",
        @"isOn" : @NO,
    }];
    [parametersArr addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"routing_attr_allow_private_name"),
        @"icon" : @"ic_custom_forbid_private_access",
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
    else if ([cellType isEqualToString:@"OAIconTitleValueCell"])
    {
        static NSString* const identifierCell = @"OAIconTitleValueCell";
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB(color_chart_orange);
        }
        return cell;
    }
    else if ([cellType isEqualToString:@"OAIconTextCell"])
    {
        static NSString* const identifierCell = @"OAIconTextCell";
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if ([item[@"key"] isEqualToString:@"avoidRoads"])
            {
                cell.iconView.tintColor = [OAAvoidRoadsRoutingParameter hasAnyAvoidEnabled:self.appMode] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_footer_icon_gray);
            }
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
            cell.imgView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = UIColorFromRGB(color_icon_inactive);
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
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"recalculateRoute"])
    {
        settingsViewController = [[OARecalculateRouteViewController alloc] init];
    }
    else if ([itemKey isEqualToString:@"avoidRoads"])
    {
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:YES];
        settingsViewController.delegate = self;
    }
    else if ([itemKey isEqualToString:@"preferRoads"])
    {
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:NO];
    }
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Switch

- (void) applyParameter:(id)sender
{
}

@end
