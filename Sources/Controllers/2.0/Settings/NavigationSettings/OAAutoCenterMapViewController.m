//
//  OAAutoCenterMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAutoCenterMapViewController.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAAutoCenterMapViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAutoCenterMapViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_screenPowerSaveValues;
    NSArray<NSString *> *_screenPowerSaveNames;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _screenPowerSaveValues = @[ @0, @5, @10, @15, @20, @30, @45, @60 ];
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *val in _screenPowerSaveValues)
    {
        if (val.intValue == 0)
            [array addObject:OALocalizedString(@"shared_string_never")];
        else
            [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"int_seconds")]];
    }
    _screenPowerSaveNames = [NSArray arrayWithArray:array];
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"choose_auto_follow_route");
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
    NSMutableArray *dataArr = [NSMutableArray array];
    for (int i = 0; i < _screenPowerSaveValues.count; i++)
    {
        [dataArr addObject: @{
           @"type" : @"OASettingsTitleCell",
           @"name" : _screenPowerSaveValues[i],
           @"title" : _screenPowerSaveNames[i],
           @"isSelected" : @NO }
         ];
    }
    _data = [NSArray arrayWithObject:dataArr];
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
