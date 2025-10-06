//
//  OAAutoCenterMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAutoCenterMapViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAAutoCenterMapViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"choose_auto_follow_route");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    NSArray<NSNumber *> *autoFollowRouteValues = @[ @0, @5, @10, @15, @20, @25, @30, @45, @60, @90 ];
    NSArray<NSString *> *autoFollowRouteEntries;
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *val in autoFollowRouteValues)
    {
        if (val.intValue == 0)
            [array addObject:OALocalizedString(@"shared_string_never")];
        else
            [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"int_seconds")]];
    }
    autoFollowRouteEntries = [NSArray arrayWithArray:array];
    int selectedValue = [_settings.autoFollowRoute get:self.appMode];
    for (int i = 0; i < autoFollowRouteValues.count; i++)
    {
        [dataArr addObject:
         @{
           @"name" : autoFollowRouteValues[i],
           @"title" : autoFollowRouteEntries[i],
           @"isSelected" : @(autoFollowRouteValues[i].intValue == selectedValue),
           @"type" : [OASimpleTableViewCell getCellIdentifier]
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.accessoryType = [item[@"isSelected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self selectAutoFollowRoute:_data[indexPath.section][indexPath.row]];
}

#pragma mark - Selectors

- (void) selectAutoFollowRoute:(NSDictionary *)item
{
    [_settings.autoFollowRoute set:((NSNumber *)item[@"name"]).intValue mode:self.appMode];
    [self.delegate onSettingsChanged];
    [self dismissViewController];
}

@end
