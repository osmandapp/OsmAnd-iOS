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
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeCheck @"OASettingsTitleCell"

@interface OAMapOrientationThresholdViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapOrientationThresholdViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_values;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    NSArray<NSNumber *> *speedLimitsKm = @[ @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSArray<NSNumber *> *speedLimitsMiles = @[ @-7.f, @-5.f, @-3.f, @0.f, @3.f, @5.f];
    if ([_settings.metricSystem get:self.appMode] == KILOMETERS_AND_METERS)
    {
        NSUInteger index = [speedLimitsKm indexOfObject:@([_settings.switchMapDirectionToCompass get:self.appMode])];
        for (int i = 0; i < speedLimitsKm.count; i++)
        {
            [dataArr addObject:
             @{
               @"name" : speedLimitsKm[i],
               @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsKm[i].intValue, OALocalizedString(@"units_kmh")],
               @"isSelected" : @(index == i),
               @"type" : kCellTypeCheck }
             ];
        }
    }
    else
    {
        NSUInteger index = [speedLimitsMiles indexOfObject:@([_settings.switchMapDirectionToCompass get:self.appMode])];
        for (int i = 0; i < speedLimitsKm.count; i++)
        {
            [dataArr addObject:
             @{
               @"name" : speedLimitsMiles[i],
               @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsMiles[i].intValue, OALocalizedString(@"units_mph")],
               @"isSelected" : @(index == i),
               @"type" : kCellTypeCheck }
             ];
        }
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"map_orientation_change_in_accordance_with_speed");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
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
    [self selectSwitchMapDirectionToCompass:_data[indexPath.section][indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectSwitchMapDirectionToCompass:(NSDictionary *)item
{
    [_settings.switchMapDirectionToCompass set:((NSNumber *)item[@"name"]).doubleValue mode:self.appMode];
    [self dismissViewController];
}

@end

