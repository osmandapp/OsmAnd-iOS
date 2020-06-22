//
//  OAProfileNavigationSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileNavigationSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAProfileNavigationSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;
}

- (instancetype) init
{
    self = [super init];
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
    _titleLabel.text = OALocalizedString(@"routing_settings_2");
    //[_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
//    _tableView.rowHeight = UITableViewAutomaticDimension;
//    _tableView.estimatedRowHeight = 60.;
    [self setupView];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [navigationArr addObject:@{
        @"type" : @"OAIconTitleValueCell",
        @"title" : OALocalizedString(@"nav_type_title"),
        @"value" : OALocalizedString(@"m_style_car"),
        @"icon" : @"ic_custom_navigation",
    }];
    [navigationArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"route_params"),
        @"icon" : @"ic_custom_route",
    }];
    [navigationArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"voice_anounces"),
        @"icon" : @"ic_custom_sound",
    }];
    [navigationArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
    }];
    [navigationArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"vehicle_parameters"),
        @"icon" : @"ic_profile_car", // has to change according to current profile icon
    }];
    [otherArr addObject:@{
        @"type" : @"OASettingsTitleCell",
        @"title" : OALocalizedString(@"map_behavior"),
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OAIconTitleValueCell"])
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
            cell.leftImageView.tintColor = UIColorFromRGB(color_icon_inactive);
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
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:@"OASettingsTitleCell"])
    {
        static NSString* const identifierCell = @"OASettingsTitleCell";
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"routing_settings") : OALocalizedString(@"help_other_header");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"change_map_behavior");
}

@end
