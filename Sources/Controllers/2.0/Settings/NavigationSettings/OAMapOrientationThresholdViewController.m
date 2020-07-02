//
//  OAMapOrientationThresholdViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapOrientationThresholdViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAMapOrientationThresholdViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapOrientationThresholdViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_values;
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
    _values = @[ @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSMutableArray *dataArr = [NSMutableArray array];
    for (int i = 0; i < _values.count; i++)
    {
        [dataArr addObject:
         @{
           @"name" : _values[i],
           @"title" : [NSString stringWithFormat:@"%d %@", _values[i].intValue, OALocalizedString(@"units_kmh")],
           @"isSelected" : @NO,
           @"type" : @"OASettingsTitleCell"
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"map_orientation_change_in_accordance_with_speed");
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
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingsTitleCell"])
    {
        static NSString* const identifierCell = @"OASettingsTitleCell";
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"isSelected"] boolValue];
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

