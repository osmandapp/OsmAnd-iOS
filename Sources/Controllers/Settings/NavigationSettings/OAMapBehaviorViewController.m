//
//  OAMapBehaviorViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapBehaviorViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAAutoCenterMapViewController.h"
#import "OAAutoZoomMapViewController.h"
#import "OAMapOrientationThresholdViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAMapBehaviorViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapBehaviorViewController
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"map_during_navigation");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
}

- (void) setupView
{
    NSString *autoCenterValue = nil;
    NSUInteger autoCenter = [_settings.autoFollowRoute get:self.appMode];
    if (autoCenter == 0)
        autoCenterValue = OALocalizedString(@"shared_string_never");
    else
        autoCenterValue = [NSString stringWithFormat:@"%lu %@", (unsigned long)autoCenter, OALocalizedString(@"units_seconds")];
    
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
    NSString *mapOrientationValue = nil;
    NSInteger mapOrientation = [_settings.switchMapDirectionToCompass get:self.appMode];
    if ([_settings.metricSystem get:self.appMode] == KILOMETERS_AND_METERS)
        mapOrientationValue = [NSString stringWithFormat:@"%d %@", (int)mapOrientation, OALocalizedString(@"units_km_h")];
    else
        mapOrientationValue = [NSString stringWithFormat:@"%d %@", (int)mapOrientation, OALocalizedString(@"units_mph")];

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
                                    @"type" : [OASettingsTableViewCell getCellIdentifier],
                                    @"title" : OALocalizedString(@"map_orientation_change_in_accordance_with_speed"),
                                    @"value" : mapOrientationValue,
                                    @"key" : @"mapOrientation",
                               },
                               @{
                                    @"type" : [OASettingSwitchCell getCellIdentifier],
                                    @"title" : OALocalizedString(@"snap_to_road"),
                                    @"value" : _settings.snapToRoad
                               }, nil];
    _data = [NSArray arrayWithArray:dataArr];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
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
    else if ([cellType isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
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

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 18.0 : 9.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"choose_auto_center_map_view_descr");
    else if (section == 1)
        return OALocalizedString(@"auto_zoom_map_descr");
    else if (section == 2)
        return OALocalizedString(@"map_orientation_change_in_accordance_with_speed_descr");
    else if (section == 3)
        return OALocalizedString(@"snap_to_road_descr");
    else
        return @"";
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"autoCenter"])
        settingsViewController = [[OAAutoCenterMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"autoZoom"])
        settingsViewController = [[OAAutoZoomMapViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"mapOrientation"])
        settingsViewController = [[OAMapOrientationThresholdViewController alloc] initWithAppMode:self.appMode];
    [self showViewController:settingsViewController];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Switch

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
