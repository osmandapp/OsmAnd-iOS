//
//  OASpeedLimitToleranceViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASpeedLimitToleranceViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@implementation OASpeedLimitToleranceViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    UIView *_tableHeaderView;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self setupTableHeaderViewWithText:OALocalizedString(@"speed_limit_tolerance_descr")];
}

- (NSString *)getTitle
{
    return OALocalizedString(@"speed_limit_exceed");
}

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    NSArray<NSNumber *> *speedLimitsKm = @[ @-10.f, @-7.f, @-5.f, @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSArray<NSNumber *> *speedLimitsMiles = @[ @-7.f, @-5.f, @-3.f, @0.f, @3.f, @5.f, @7.f, @10.f, @15.f ];
    NSUInteger index = [speedLimitsKm indexOfObject:@([_settings.speedLimitExceedKmh get:self.appMode])];
    if ([_settings.metricSystem get:self.appMode] == KILOMETERS_AND_METERS)
    {
        for (int i = 0; i < speedLimitsKm.count; i++)
        {
            [dataArr addObject:
             @{
               @"name" : speedLimitsKm[i],
               @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsKm[i].intValue, OALocalizedString(@"km_h")],
               @"isSelected" : @(index == i),
               @"type" : [OASettingsTitleTableViewCell getCellIdentifier]
             }];
        }
    }
    else
    {
        for (int i = 0; i < speedLimitsKm.count; i++)
        {
            [dataArr addObject:
             @{
               @"name" : speedLimitsKm[i],
               @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsMiles[i].intValue, OALocalizedString(@"mile_per_hour")],
               @"isSelected" : @(index == i),
               @"type" : [OASettingsTitleTableViewCell getCellIdentifier]
             }];
        }
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (void)onRotation
{
    [self setupTableHeaderViewWithText:OALocalizedString(@"speed_limit_tolerance_descr")];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"isSelected"] boolValue];
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectSpeedLimitExceed:_data[indexPath.section][indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectSpeedLimitExceed:(NSDictionary *)item
{
    [_settings.speedLimitExceedKmh set:((NSNumber *)item[@"name"]).doubleValue mode:self.appMode];
    if (self.delegate)
        [self.delegate onSettingsChanged];
    [self dismissViewController];
}

@end
