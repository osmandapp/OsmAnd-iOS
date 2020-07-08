//
//  OAMapBehaviorViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapBehaviorViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAAutoCenterMapViewController.h"
#import "OAAutoZoomMapViewController.h"
#import "OAMapOrientationThresholdViewController.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAMapBehaviorViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapBehaviorViewController
{
    NSArray<NSArray *> *_data;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
    }
    return self;
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"map_behavior");
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
    NSMutableArray *dataArr = [NSMutableArray arrayWithObjects:@{
                                    @"type" : @"OASettingsCell",
                                    @"title" : OALocalizedString(@"choose_auto_follow_route"),
                                    @"value" : @"25 sec", // has to be changed
                                    @"key" : @"autoCenter"},
                                @{
                                    @"type" : @"OASettingsCell",
                                    @"title" : OALocalizedString(@"auto_zoom_map"),
                                    @"value" : OALocalizedString(@"auto_zoom_none"), // has to be changed
                                    @"key" : @"autoZoom",
                               },
                               @{
                                    @"type" : @"OASettingsCell",
                                    @"title" : OALocalizedString(@"map_orientation_change_in_accordance_with_speed"),
                                    @"value" : @"0 km/h", // has to be changed
                                    @"key" : @"mapOrientation",
                               },
                               @{
                                    @"type" : @"OASettingSwitchCell",
                                    @"title" : OALocalizedString(@"snap_to_road"),
                                    @"isOn" : @NO }, nil];
    _data = [NSArray arrayWithArray:dataArr];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingsCell"])
    {
        static NSString* const identifierCell = @"OASettingsCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
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
            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 18.0 : 9.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"choose_auto_center_map_view_descr");
    else if (section == 1)
        return OALocalizedString(@"auto_zoom_map_descr");
    else if (section == 2)
        return OALocalizedString(@"map_orientation_change_in_accordance_with_speed_descr");
    else if (section == 3)
        return OALocalizedString(@"snap_to_road_descr");
    else
        return @"";
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"autoCenter"])
        settingsViewController = [[OAAutoCenterMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"autoZoom"])
        settingsViewController = [[OAAutoZoomMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"mapOrientation"])
        settingsViewController = [[OAMapOrientationThresholdViewController alloc] initWithAppMode:self.appMode];
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Switch

- (void) applyParameter:(id)sender
{
}

@end
