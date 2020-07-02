//
//  OAMapOrientationViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapOrientationViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"
#import "OAAppSettings.h"
#import "OAFileNameTranslationHelper.h"
#import "OrderedDictionary.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeCheck @"OAIconTextCell"

@interface OAMapOrientationViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapOrientationViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
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

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"rotate_map_to_bearing");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _settings = [OAAppSettings sharedManager];
    [self setupView];
}

- (void) setupView
{
    int rotateMap = [_settings.rotateMap get];
    NSMutableArray *dataArr = [NSMutableArray array];
    [dataArr addObject:@{
        @"name" : @"none",
        @"title" : OALocalizedString(@"rotate_map_none_opt"),
        @"selected" : @(rotateMap == ROTATE_MAP_NONE),
        @"icon" : @"ic_custom_direction_north",
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"bearing",
        @"title" : OALocalizedString(@"rotate_map_bearing_opt"),
        @"selected" : @(rotateMap == ROTATE_MAP_BEARING),
        @"icon" : @"ic_custom_direction_movement",
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
       @"name" : @"compass",
       @"title" : OALocalizedString(@"rotate_map_compass_opt"),
       @"selected" : @(rotateMap == ROTATE_MAP_COMPASS),
       @"icon" : @"ic_custom_direction_compass",
       @"type" : kCellTypeCheck,
    }];
    _data = [NSArray arrayWithObject:dataArr];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = kCellTypeCheck;
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
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.hidden = ![item[@"selected"] boolValue];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *name = item[@"name"];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"bearing"])
        [settings.rotateMap set:ROTATE_MAP_BEARING];
    else if ([name isEqualToString:@"compass"])
        [settings.rotateMap set:ROTATE_MAP_COMPASS];
    else
        [settings.rotateMap set:ROTATE_MAP_NONE];
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
