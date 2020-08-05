//
//  OAMainSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OAMainSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTextDescSwitchCell.h"
#import "OATitleRightIconCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"

#import "OACreateProfileViewController.h"
#import "OARearrangeProfilesViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAConfigureProfileViewController.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeCheck @"OAMultiIconTextDescCell"
#define kCellTypeProfileSwitch @"OAIconTextDescSwitchCell"
#define kCellTypeAction @"OATitleRightIconCell"
#define kFooterId @"TableViewSectionFooter"

@implementation OAMainSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    
    OAAutoObserverProxy* _appModeChangeObserver;
    
    OAApplicationMode *_targetAppMode;
}

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode
{
    self = [super init];
    if (self) {
        _targetAppMode = mode;
    }
    return self;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.settingsTableView.rowHeight = UITableViewAutomaticDimension;
    self.settingsTableView.estimatedRowHeight = kEstimatedRowHeight;
    
    _appModeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
    
    _settings = OAAppSettings.sharedManager;
    
    if (_targetAppMode)
    {
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:_targetAppMode];
        [self.navigationController pushViewController:profileConf animated:YES];
        _targetAppMode = nil;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void)dealloc
{
    [_appModeChangeObserver detach];
}

- (void) setupView
{
    if ([self.backButton isDirectionRTL])
        self.backButton.transform = CGAffineTransformMakeRotation(M_PI);
    OAAppSettings* settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = settings.applicationMode;
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
        @"name" : @"global_settings",
        @"title" : OALocalizedString(@"global_settings"),
        @"description" : OALocalizedString(@"global_settings_descr"),
        @"img" : @"left_menu_icon_settings",
        @"type" : kCellTypeIconTitleValue }
    ]];
    
    [data addObject:@[
        @{
            @"name" : @"current_profile",
            @"app_mode" : appMode,
            @"type" : kCellTypeCheck
        }
    ]];
    
    NSMutableArray *profilesSection = [NSMutableArray new];
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        [profilesSection addObject:@{
            @"name" : @"profile_val",
            @"app_mode" : am,
            @"type" : kCellTypeProfileSwitch
        }];
    }
    
    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"new_profile"),
        @"img" : @"ic_custom_add",
        @"type" : kCellTypeAction,
        @"name" : @"add_profile"
    }];
    
    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"edit_profile_list"),
        @"img" : @"ic_custom_edit",
        @"type" : kCellTypeAction,
        @"name" : @"edit_profiles"
    }];
    
    [data addObject:profilesSection];
    
    _data = [NSArray arrayWithArray:data];
    
    [self.settingsTableView setDataSource: self];
    [self.settingsTableView setDelegate:self];
    self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.settingsTableView reloadData];
    [self.settingsTableView reloadInputViews];
    [self.settingsTableView setSeparatorInset:UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0)];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"custom_profile") : OALocalizedString(@"osmand_profile");
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    if (sender.tag < OAApplicationMode.allPossibleValues.count)
    {
        OAApplicationMode *am = OAApplicationMode.allPossibleValues[sender.tag];
        [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
    }
}

- (void) onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftImageView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftImageView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = kCellTypeCheck;
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMultiIconTextDescCell" owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            [cell setOverflowVisibility:YES];
        }
        OAApplicationMode *am = item[@"app_mode"];
        UIImage *img = am.getIcon;
        cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
        cell.textView.text = am.toHumanString;
        cell.descView.text = [self getProfileDescription:am];
        cell.contentView.backgroundColor = [UIColorFromRGB(am.getIconColor) colorWithAlphaComponent:0.1];
        return cell;
    }
    else if ([type isEqualToString:kCellTypeProfileSwitch])
    {
        static NSString* const identifierCell = kCellTypeProfileSwitch;
        OAIconTextDescSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeProfileSwitch owner:self options:nil];
            cell = (OAIconTextDescSwitchCell *)[nib objectAtIndex:0];
        }
        OAApplicationMode *am = item[@"app_mode"];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? 62.0 : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.leftIconView.tintColor = UIColorFromRGB(am.getIconColor);
        cell.titleLabel.text = am.toHumanString;
        cell.descLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.switchView setOn:[OAApplicationMode.values containsObject:am]];
        return cell;
    }
    else if ([type isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return OALocalizedString(@"selected_profile");
    else if (section == 2)
        return OALocalizedString(@"app_profiles");
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"global_settings_descr");
    else if (section == 2)
        return OALocalizedString(@"export_profile_descr");
    return nil;
}

#pragma mark - UITableViewDelegate

- (nullable NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL nonClickable = item[@"nonclickable"] != nil;
    return nonClickable ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    [self selectSettingMain:item];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectSettingMain:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    if ([name isEqualToString:@"global_settings"])
    {
        OAGlobalSettingsViewController* globalSettingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAGlobalSettingsMain];
        [self.navigationController pushViewController:globalSettingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"profile_val"] || [name isEqualToString:@"current_profile"])
    {
        OAApplicationMode *mode = item[@"app_mode"];
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:mode];
        [self.navigationController pushViewController:profileConf animated:YES];
    }
    else if ([name isEqualToString:@"add_profile"])
    {
        OACreateProfileViewController* createProfileViewController = [[OACreateProfileViewController alloc] init];
        [self.navigationController pushViewController:createProfileViewController animated:YES];
    }
    else if ([name isEqualToString:@"edit_profiles"])
    {
        OARearrangeProfilesViewController* rearrangeProfilesViewController = [[OARearrangeProfilesViewController alloc] init];
        [self.navigationController pushViewController:rearrangeProfilesViewController animated:YES];
    }
//    else if ([name isEqualToString:@"general_settings"])
//    {
//        OAProfileGeneralSettingsViewController* settingsViewController = [[OAProfileGeneralSettingsViewController alloc] initWithAppMode:OAApplicationMode.CAR];
//        [self.navigationController pushViewController:settingsViewController animated:YES];
//    }
//    else if ([name isEqualToString:@"routing_settings"])
//    {
//        // TODO: pass selected mode after refactoring
//        OAProfileNavigationSettingsViewController* settingsViewController = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:OAApplicationMode.CAR];
//        [self.navigationController pushViewController:settingsViewController animated:YES];
//    }
//
//
}

@end
