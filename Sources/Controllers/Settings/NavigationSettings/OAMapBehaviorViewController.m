//
//  OAMapBehaviorViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapBehaviorViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAutoCenterMapViewController.h"
#import "OAAutoZoomMapViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAMapBehaviorViewController
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"map_during_navigation");
}

#pragma mark - Table data

- (void)generateData
{
    NSString *autoCenterValue = nil;
    NSUInteger autoCenter = [_settings.autoFollowRoute get:self.appMode];
    if (autoCenter == 0)
        autoCenterValue = OALocalizedString(@"shared_string_never");
    else
        autoCenterValue = [NSString stringWithFormat:@"%lu %@", (unsigned long)autoCenter, OALocalizedString(@"int_seconds")];
    
    NSString *autoZoomValue = nil;
    if (![_settings.autoZoomMap get:self.appMode])
    {
        autoZoomValue = OALocalizedString(@"auto_zoom_none");
    }
    else
    {
        EOAAutoZoomMap autoZoomMap = [_settings.autoZoomMapScale get:self.appMode];
        autoZoomValue = [OAAutoZoomMap getName:autoZoomMap];
    }

    NSMutableArray *dataArr = [NSMutableArray arrayWithObjects:@{
                                    @"type" : [OASettingsTableViewCell getCellIdentifier],
                                    @"title" : OALocalizedString(@"choose_auto_follow_route"),
                                    @"value" : autoCenterValue,
                                    @"key" : @"autoCenter"},
                                @{
                                    @"type" : [OASettingsTableViewCell getCellIdentifier],
                                    @"title" : OALocalizedString(@"auto_zoom_map"),
                                    @"value" : autoZoomValue,
                                    @"key" : @"autoZoom",
                               },
                               @{
                                    @"type" : [OASwitchTableViewCell getCellIdentifier],
                                    @"title" : OALocalizedString(@"snap_to_road"),
                                    @"value" : _settings.snapToRoad
                               }, nil];
    _data = [NSArray arrayWithArray:dataArr];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"choose_auto_center_map_view_descr");
    else if (section == 1)
        return OALocalizedString(@"auto_zoom_map_descr");
    else if (section == 2)
        return OALocalizedString(@"snap_to_road_descr");
    else
        return @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            id v = item[@"value"];
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OACommonBoolean class]])
            {
                OACommonBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
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
    return section == 0 ? 18.0 : 9.0;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"autoCenter"])
        settingsViewController = [[OAAutoCenterMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"autoZoom"])
        settingsViewController = [[OAAutoZoomMapViewController alloc] initWithAppMode:self.appMode];
    [self showViewController:settingsViewController];
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary *item = _data[indexPath.section];

    BOOL isChecked = ((UISwitch *) sender).on;
    id v = item[@"value"];
    if ([v isKindOfClass:[OACommonBoolean class]])
    {
        OACommonBoolean *value = v;
        [value set:isChecked mode:self.appMode];
    }
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
