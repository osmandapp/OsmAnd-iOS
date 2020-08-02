//
//  OAVehicleParametersViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVehicleParametersViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OASettingsModalPresentationViewController.h"
#import "OAVehicleParametersSettingsViewController.h"
#import "OADefaultSpeedViewController.h"
#import "OANavigationSettingsHeader.h"
#import "OANavigationSettingsFooter.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconText @"OAIconTextCell"

@interface OAVehicleParametersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAVehicleParametersViewController
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
    self.titleLabel.text = OALocalizedString(@"vehicle_parameters");
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
    NSMutableArray *defaultSpeedArr = [NSMutableArray array];
    [parametersArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"routing_attr_weight_name"),
        @"value" : @"3 t", // needs to be changed
        @"icon" : @"ic_custom_weight_limit",
        @"key" : @"weightLimit",
    }];
    [parametersArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"routing_attr_height_name"),
        @"value" : @"None", // needs to be changed
        @"icon" : @"ic_custom_height_limit",
        @"key" : @"heightLimit",
    }];
    [parametersArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"routing_attr_width_name"),
        @"value" : @"3 m", // needs to be changed
        @"icon" : @"ic_custom_width_limit",
        @"key" : @"widthLimit",
    }];
    [parametersArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"routing_attr_length_name"),
        @"value" : @"10 m", // needs to be changed
        @"icon" : @"ic_custom_length_limit",
        @"key" : @"lenghtLimit",
    }];
    
    [defaultSpeedArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"default_speed"),
        @"icon" : @"ic_action_speed",
        @"key" : @"defaultSpeed",
        
    }];
    [tableData addObject:parametersArr];
    [tableData addObject:defaultSpeedArr];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftImageView.image = [UIImage imageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconText])
    {
        static NSString* const identifierCell = kCellTypeIconText;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OASettingsModalPresentationViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"weightLimit"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:[OAApplicationMode CAR] vehicleParameter:item[@"title"]];
    else if ([itemKey isEqualToString:@"heightLimit"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:[OAApplicationMode CAR] vehicleParameter:item[@"title"]];
    else if ([itemKey isEqualToString:@"widthLimit"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:[OAApplicationMode CAR] vehicleParameter:item[@"title"]];
    else if ([itemKey isEqualToString:@"lenghtLimit"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:[OAApplicationMode CAR] vehicleParameter:item[@"title"]];
    else if ([itemKey isEqualToString:@"defaultSpeed"])
        settingsViewController = [[OADefaultSpeedViewController alloc] initWithApplicationMode:[OAApplicationMode CAR]];
    [self presentViewController:settingsViewController animated:YES completion:nil];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"announce");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"touting_specified_vehicle_parameters_descr") : OALocalizedString(@"default_speed_descr");
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat emptyHeaderHeight = section == 0 ? 34 : 17;
    return [[self tableView:tableView titleForHeaderInSection:section]  isEqual: @""] ? emptyHeaderHeight : UITableViewAutomaticDimension;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString* const identifierCell = @"OANavigationSettingsHeader";
    OANavigationSettingsHeader* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OANavigationSettingsHeader *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        cell.textView.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    static NSString* const identifierCell = @"OANavigationSettingsFooter";
    OANavigationSettingsFooter* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OANavigationSettingsFooter *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        cell.textView.text = [self tableView:tableView titleForFooterInSection:section];
    }
    return cell;
}

@end
