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
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OAVehicleParametersViewController.h"
#import "OAMapBehaviorViewController.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAProfileDataObject.h"
#import "OsmAndApp.h"
#import "OAProfileDataUtils.h"
#import "OASettingsHelper.h"

#import "Localization.h"
#import "OAColors.h"

#define kOsmAndNavigation @"osmand_navigation"

@interface OAProfileNavigationSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;
    
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    NSDictionary<NSString *, OARoutingProfileDataObject *> *_routingProfileDataObjects;
    BOOL _showAppModeDialog; // to delete
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = OAAppSettings.sharedManager;
        _app = [OsmAndApp instance];
        [self generateData];
        _showAppModeDialog = NO;
    }
    return self;
}

- (void) updateNavBar
{
    self.subtitleLabel.text = self.appMode.toHumanString;
}

- (void) generateData
{
    NSString *selectedProfileName = self.appMode.getRoutingProfile;
    _routingProfileDataObjects = [OAProfileDataUtils getRoutingProfiles];
    NSArray *profiles = [_routingProfileDataObjects allValues];
    OARoutingProfileDataObject *routingData;
    for (OARoutingProfileDataObject *profile in profiles)
    {
        if([profile.stringKey isEqual:selectedProfileName])
            routingData = profile;
    }
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    if (self.appMode != OAApplicationMode.CARPLAY)
    {
        [navigationArr addObject:@{
            @"type" : [OAIconTitleValueCell getCellIdentifier],
            @"title" : OALocalizedString(@"nav_type_title"),
            @"value" : routingData ? routingData.name : @"",
            @"icon" : routingData ? routingData.iconName : @"ic_custom_navigation",
            @"key" : @"navigationType",
        }];
    }
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"route_parameters"),
        @"icon" : @"ic_custom_route",
        @"key" : @"routeParams",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"voice_announces"),
        @"icon" : @"ic_custom_sound",
        @"key" : @"voicePrompts",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"key" : @"screenAlerts",
    }];
    [navigationArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"vehicle_parameters"),
        @"icon" : self.appMode.getIconName,
        @"key" : @"vehicleParams",
    }];
    [otherArr addObject:@{
        @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"map_during_navigation"),
        @"key" : @"mapBehavior",
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
    [self updateNavBar];
    [self.tableView reloadData];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"routing_settings_2");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftImageView.tintColor = UIColorFromRGB(color_icon_inactive);
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftImageView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"navigationType"])
        settingsViewController = [[OANavigationTypeViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"routeParams"])
        settingsViewController = [[OARouteParametersViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"voicePrompts"])
        settingsViewController = [[OAVoicePromptsViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"screenAlerts"])
        settingsViewController = [[OAScreenAlertsViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"vehicleParams"])
        settingsViewController = [[OAVehicleParametersViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"mapBehavior"])
        settingsViewController = [[OAMapBehaviorViewController alloc] initWithAppMode:self.appMode];
    settingsViewController.delegate = self;
    [self showViewController:settingsViewController];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"routing_settings") : OALocalizedString(@"help_other_header");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"change_map_behavior");
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

#pragma mark - OASettingsDataDelegate

- (void)onSettingsChanged
{
    [self generateData];
    [super onSettingsChanged];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
