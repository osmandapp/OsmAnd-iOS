//
//  OAVoicePromptsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVoicePromptsViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OASettingsTableViewCell.h"
#import "OANavigationLanguageViewController.h"
#import "OASpeedLimitToleranceViewController.h"
#import "OARepeatNavigationInstructionsViewController.h"
#import "OAArrivalAnnouncementViewController.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAVoicePromptsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAVoicePromptsViewController
{
    NSArray<NSArray *> *_data;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OAAppSettingsViewController" bundle:nil];
    if (self) {
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
    self.titleLabel.text = OALocalizedString(@"voice_prompts");
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
    NSMutableArray *firstSection = [NSMutableArray array]; // change
    NSMutableArray *secondSection = [NSMutableArray array];
    NSMutableArray *thirdSection = [NSMutableArray array];
    NSMutableArray *fourthSection = [NSMutableArray array];
    NSMutableArray *fifthSection = [NSMutableArray array];
    [firstSection addObject:@{
        @"type" : @"OASettingSwitchCell",
        @"title" : OALocalizedString(@"voice_provider"),
        @"icon" : @"ic_custom_sound",
        @"isOn" : @YES,
    }];
    [firstSection addObject:@{
        @"type" : @"OAIconTitleValueCell",
        @"title" : OALocalizedString(@"language"),
        @"value" : @"Croatian", // needs to be changed
        @"icon" : @"ic_custom_map_languge",
        @"isOn" : @NO,
    }];
    
    [secondSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_street_names"),
        @"isOn" : @NO,
    }];
    [secondSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"show_traffic_warnings"),
        @"isOn" : @NO,
    }];
    [secondSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"isOn" : @NO,
    }];
    
    [thirdSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_speed_limit"),
        @"isOn" : @NO,
    }];
    [thirdSection addObject:@{
        @"type" : @"OASettingsCell",
        @"title" : OALocalizedString(@"speed_limit_exceed"),
        @"value" : @"0 km/h", // needs to be changed
    }];
    
    [fourthSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_cameras"),
        @"isOn" : @NO,
    }];
    [fourthSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_tunnels"),
        @"isOn" : @NO,
    }];
    [fourthSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"announce_gpx_waypoints"),
        @"isOn" : @NO,
    }];
    [fourthSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_favorites"),
        @"isOn" : @NO,
    }];
    [fourthSection addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"speak_poi"),
        @"isOn" : @NO,
    }];
    
    [fifthSection addObject:@{
        @"type" : @"OASettingsCell",
        @"title" : OALocalizedString(@"keep_informing"),
        @"value" : @"7 min", // needs to be changed
    }];
    [fifthSection addObject:@{
        @"type" : @"OASettingsCell",
        @"title" : OALocalizedString(@"arrival_distance"),
        @"value" : @"Early", // needs to be changed
    }];
    [tableData addObject:firstSection];
    [tableData addObject:secondSection];
    [tableData addObject:thirdSection];
    [tableData addObject:fourthSection];
    [tableData addObject:fifthSection];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingSwitchCell"])
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
    else if ([cellType isEqualToString:@"OAIconTitleValueCell"])
    {
        static NSString* const identifierCell = @"OAIconTitleValueCell";
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.iconView.image = [UIImage imageNamed:item[@"icon"]];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    else if ([cellType isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
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
    else if ([cellType isEqualToString:@"OASettingsCell"])
    {
        static NSString* const identifierCell = @"OASettingsCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? OALocalizedString(@"announce") : @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"speak_descr") : @"";
}

//- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
//}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAAppSettingsViewController* settingsViewController = nil;
    if (indexPath.section == 0 && indexPath.row == 1)
        settingsViewController = [[OANavigationLanguageViewController alloc] init];
    if (indexPath.section == 2 && indexPath.row == 1)
        settingsViewController = [[OASpeedLimitToleranceViewController alloc] init];
    if (indexPath.section == 4 && indexPath.row == 0)
        settingsViewController = [[OARepeatNavigationInstructionsViewController alloc] init];
    if (indexPath.section == 4 && indexPath.row == 1)
        settingsViewController = [[OAArrivalAnnouncementViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) applyParameter:(id)sender
{
   
}

@end
