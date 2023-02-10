//
//  OAAutoCenterMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAutoCenterMapViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAAutoCenterMapViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (NSString *)getTitle
{
    return OALocalizedString(@"choose_auto_follow_route");
}

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
           @"type" : [OASettingsTitleTableViewCell getCellIdentifier]
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
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
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
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
    [self selectAutoFollowRoute:_data[indexPath.section][indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectAutoFollowRoute:(NSDictionary *)item
{
    [_settings.autoFollowRoute set:((NSNumber *)item[@"name"]).intValue mode:self.appMode];
    [self dismissViewController];
}

@end
