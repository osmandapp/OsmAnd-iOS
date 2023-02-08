//
//  OAGlobalSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsViewController.h"
#import "OAAppSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OATableViewCustomHeaderView.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAHistorySettingsViewController.h"
#import "OAExportItemsViewController.h"
#import "OAHistoryHelper.h"

#define kCarplayHeaderTopMargin 40
#define kDefaultProfileHeaderTopMargin 40

@interface OAGlobalSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAGlobalSettingsViewController
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
    NSArray<OAApplicationMode *> * _profileList;
    BOOL _isDefaultProfile;
    BOOL _isUsingLastAppMode;
}

- (instancetype) initWithSettingsType:(EOAGlobalSettingsScreen)settingsType
{
    self = [super init];
    if (self) {
        [self commonInit];
        _settings = [OAAppSettings sharedManager];
        _settingsType = settingsType;
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _profileList = [NSArray arrayWithArray:OAApplicationMode.values];
}

- (UIView *) getTopView
{
    return _navbarView;
}

- (void) applyLocalization
{
    if (_settingsType == EOAGlobalSettingsMain)
        self.titleLabel.text = OALocalizedString(@"osmand_settings");
    else if (_settingsType == EOADefaultProfile)
        self.titleLabel.text = OALocalizedString(@"settings_preset");
    else if (_settingsType == EOADialogsAndNotifications)
        self.titleLabel.text = OALocalizedString(@"dialogs_and_notifications");
    else if (_settingsType == EOAHistory)
        self.titleLabel.text = OALocalizedString(@"history_settings");
    else
        self.titleLabel.text = OALocalizedString(@"carplay_profile");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    [self setupView];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
        [self.tableView reloadData];
    } completion:nil];
}

- (void) setupView
{
    switch (_settingsType)
    {
        case EOAGlobalSettingsMain:
        {
            _data = @[
                @{
                    @"header" : @"",
                    @"footer" : OALocalizedString(@"default_profile_descr"),
                    @"rows": @[@{@"name" : @"settings_preset",
                                 @"title" : OALocalizedString(@"settings_preset"),
                                 @"value" : _settings.useLastApplicationModeByDefault.get ? OALocalizedString(@"last_used") : _settings.defaultApplicationMode.get.toHumanString,
                                 @"img" : @"menu_cell_pointer.png",
                                 @"type" : [OASettingsTableViewCell getCellIdentifier] }]},
                @{
                    @"header" : @"",
                    @"footer" : OALocalizedString(@"carplay_profile_descr"),
                    @"rows": @[@{ @"name" : @"carplay_profile",
                                  @"title" : OALocalizedString(@"carplay_profile"),
                                  @"value" : _settings.isCarPlayModeDefault.get ? OALocalizedString(@"settings_preset") : _settings.carPlayMode.get.toHumanString,
                                  @"img" : @"menu_cell_pointer.png",
                                  @"type" : [OASettingsTableViewCell getCellIdentifier] }]},
                @{
                    @"header" : [OALocalizedString(@"privacy_and_security_header") upperCase],
                    @"footer" : OALocalizedString(@"send_anonymous_data_desc"),
                    @"rows": @[@{  @"name" : @"do_not_send_anonymous_data",
                                   @"title" : OALocalizedString(@"send_anonymous_data"),
                                   @"value" : @(_settings.sendAnonymousAppUsageData.get),
                                   @"type" : [OASwitchTableViewCell getCellIdentifier], },
                               @{
                                   @"name" : @"history_settings",
                                   @"title" : OALocalizedString(@"history_settings"),
                                   @"value" : ![_settings.defaultSearchHistoryLoggingApplicationMode get] && ![_settings.defaultNavigationHistoryLoggingApplicationMode get] && ![_settings.defaultMarkersHistoryLoggingApplicationMode get] ? OALocalizedString(@"shared_string_off") : @"",
                                   @"img" : @"menu_cell_pointer.png",
                                   @"type" : [OASettingsTableViewCell getCellIdentifier] }]},
                @{
                    @"header" : @"",
                    @"footer" : OALocalizedString(@"dialogs_and_notifications_descr"),
                    @"rows": @[@{@"name" : @"dialogs_and_notif",
                                 @"title" : OALocalizedString(@"dialogs_and_notifications"),
                                 @"description" : OALocalizedString(@"dialogs_and_notifications_descr"),
                                 @"value" : [self getDialogsAndNotificationsValue],
                                 @"img" : @"menu_cell_pointer.png",
                                 @"type" : [OASettingsTableViewCell getCellIdentifier]}]
                }];
            break;
        }
        case EOADefaultProfile:
        {
            _isUsingLastAppMode = _settings.useLastApplicationModeByDefault.get;
            NSMutableArray *arr = [NSMutableArray array];
            [arr addObject: @{
                @"name" : @"last_used",
                @"title" : OALocalizedString(@"last_used"),
                @"value" : @(_isUsingLastAppMode),
                @"type" : [OASwitchTableViewCell getCellIdentifier] }];
            
            if (!_isUsingLastAppMode)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    [arr addObject: @{
                        @"name" : mode.toHumanString,
                        @"descr" : mode.stringKey,
                        @"mode" : mode,
                        @"isSelected" : @(_settings.defaultApplicationMode.get == mode),
                        @"type" : [OAMultiIconTextDescCell getCellIdentifier] }];
                }
            }
            _data = [NSArray arrayWithArray:arr];
            break;
        }
        case EOACarplayProfile:
        {
            _isDefaultProfile = _settings.isCarPlayModeDefault.get;
            NSMutableArray *arr = [NSMutableArray array];
            [arr addObject: @{
                @"name" : @"carplay_mode_is_default_string",
                @"title" : OALocalizedString(@"settings_preset"),
                @"value" : @(_isDefaultProfile),
                @"type" : [OASwitchTableViewCell getCellIdentifier] }];
            
            if (!_isDefaultProfile)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    if (mode != OAApplicationMode.DEFAULT)
                    {
                        [arr addObject: @{
                            @"name" : mode.toHumanString,
                            @"descr" : mode.stringKey,
                            @"mode" : mode,
                            @"isSelected" : @(_settings.carPlayMode.get == mode),
                            @"type" : [OAMultiIconTextDescCell getCellIdentifier] }];
                    }
                }
            }
            _data = [NSArray arrayWithArray:arr];
            break;
        }
        case EOAHistory:
        {
            OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
            NSArray *historyItems = [helper getPointsHavingTypes:helper.searchTypes limit:0];
            _data = @[
                @{
                    @"header" : @"",
                    @"footer" : OALocalizedString(@"history_footer_text"),
                    @"rows": @[@{  @"name" : @"search_history",
                                   @"title" : OALocalizedString(@"search_history"),
                                   @"value" : [_settings.defaultSearchHistoryLoggingApplicationMode get] ? [NSString stringWithFormat:@"%ld", historyItems.count] : OALocalizedString(@"shared_string_off"),
                                   @"icon" : @"ic_custom_search",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"navigation_history",
                                   @"title" : OALocalizedString(@"navigation_history"),
                                   @"value" : [_settings.defaultNavigationHistoryLoggingApplicationMode get] ? [NSString stringWithFormat:@"%ld", historyItems.count] : OALocalizedString(@"shared_string_off"),
                                   @"icon" : @"ic_custom_navigation",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"map_markers_history",
                                   @"title" : OALocalizedString(@"map_markers_history"),
                                   @"value" : [_settings.defaultMarkersHistoryLoggingApplicationMode get] ? [NSString stringWithFormat:@"%ld", historyItems.count] : OALocalizedString(@"shared_string_off"),
                                   @"icon" : @"ic_custom_marker",
                                   @"type" : [OAValueTableViewCell getCellIdentifier] }]},
                @{
                    @"header" : [OALocalizedString(@"actions") upperCase],
                    @"footer" : OALocalizedString(@"history_actions_footer_text"),
                    @"rows": @[@{  @"name" : @"export_history",
                                   @"title" : OALocalizedString(@"shared_string_export"),
                                   @"value" : @(_settings.sendAnonymousAppUsageData.get),
                                   @"icon" : @"ic_custom_export",
                                   @"type" : [OARightIconTableViewCell getCellIdentifier] },
                               @{
                                   @"name" : @"clear_history",
                                   @"title" : OALocalizedString(@"clear_history"),
                                   @"value" : [self getDialogsAndNotificationsValue],
                                   @"icon" : @"ic_custom_remove_outlined",
                                   @"type" : [OARightIconTableViewCell getCellIdentifier] }],
                }];
            break;
        }
        case EOADialogsAndNotifications:
        {
            _data = @[
                @{
                    @"name" : @"do_not_show_discount",
                    @"title" : OALocalizedString(@"do_not_show_discount"),
                    @"description" : OALocalizedString(@"do_not_show_discount_desc"),
                    @"value" : @(_settings.settingDoNotShowPromotions.get),
                    @"type" : [OASwitchTableViewCell getCellIdentifier]
                },
                @{
                    @"name" : @"download_map_dialog",
                    @"title" : OALocalizedString(@"download_map_dialog"),
                    @"value" : @(_settings.showDownloadMapDialog.get),
                    @"type" : [OASwitchTableViewCell getCellIdentifier]
                }
            ];
        }
        default:
            break;
    }
}

- (NSString *) getDialogsAndNotificationsValue
{
    BOOL showPromotions = _settings.settingDoNotShowPromotions.get;
    BOOL showDownloadMap = _settings.showDownloadMapDialog.get;
    if (showPromotions && showDownloadMap)
        return OALocalizedString(@"shared_string_all");
    else if (!showPromotions && !showDownloadMap)
        return OALocalizedString(@"shared_string_none");
    return @"1/2";
}

- (IBAction) backButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOAHistory)
    {
        NSDictionary *section = _data[indexPath.section];
        NSArray *row = section[@"rows"];
        return row[indexPath.row];
    }
    else if (_settingsType == EOADialogsAndNotifications)
        return _data[indexPath.section];
    else
        return _data[indexPath.row];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.descriptionView.numberOfLines = 1;
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
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            [cell.overflowButton setImage:[UIImage templateImageNamed:@"ic_checkmark_default"] forState:UIControlStateNormal];
            cell.overflowButton.tintColor = UIColorFromRGB(color_primary_purple);
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        OAApplicationMode *am = item[@"mode"];
        UIImage *img = am.getIcon;
        cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
        cell.textView.text = am.toHumanString;
        cell.descView.text = am.getProfileDescription;
        [cell setOverflowVisibility:![item[@"isSelected"] boolValue]];
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            NSString *iconName = item[@"icon"];
            cell.leftIconView.image = [UIImage templateImageNamed:iconName];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            if ([item[@"title"] isEqualToString:@"Clear all history"])
                cell.titleLabel.textColor = UIColorFromRGB(color_primary_red);
            else
                cell.titleLabel.textColor = UIColorFromRGB(color_primary_purple);
            
            cell.rightIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            if ([item[@"icon"] isEqualToString:@"ic_custom_remove_outlined"])
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_red);
            else
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
            
        }
        return cell;
    }
    return nil;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *name = item[@"name"];
    if (name)
    {
        switch (self.settingsType)
        {
            case EOAGlobalSettingsMain:
            {
                OAGlobalSettingsViewController* settingsViewController = nil;
                if ([name isEqualToString:@"settings_preset"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADefaultProfile];
                else if ([name isEqualToString:@"carplay_profile"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOACarplayProfile];
                else if ([name isEqualToString:@"history_settings"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAHistory];
                else if ([name isEqualToString:@"dialogs_and_notif"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADialogsAndNotifications];
                [self.navigationController pushViewController:settingsViewController animated:YES];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            case EOADefaultProfile:
            {
                NSDictionary *item = [self getItem:indexPath];
                OAApplicationMode *am = item[@"mode"];
                [_settings.defaultApplicationMode set:am];
                [_settings setApplicationModePref:am];
                [self backButtonClicked:nil];
                break;
            }
            case EOACarplayProfile:
            {
                NSDictionary *item = [self getItem:indexPath];
                OAApplicationMode *am = item[@"mode"];
                [_settings.carPlayMode set:am];
                [self backButtonClicked:nil];
                break;
            }
            case EOAHistory:
            {
                OAHistorySettingsViewController* historyViewController = nil;
                if ([name isEqualToString:@"search_history"])
                {
                    historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOASearchHistoryProfile];
                }
                else if ([name isEqualToString:@"navigation_history"])
                {
                    historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOANavigationHistoryProfile];
                }
                else if ([name isEqualToString:@"map_markers_history"])
                {
                    historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAMarkersHistoryProfile];
                }
                else if ([name isEqualToString:@"export_history"])
                {
                    OAExportItemsViewController *exportController = [[OAExportItemsViewController alloc] init];
                    [self.navigationController pushViewController:exportController animated:YES];
                }
                else if ([name isEqualToString:@"clear_history"])
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"history_clear_alert_title")
                                                                                   message:OALocalizedString(@"history_clear_alert_message")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:nil
                    ];
                    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:OALocalizedString(@"history_clear")
                                                                          style:UIAlertActionStyleDestructive
                                                                        handler:^(UIAlertAction * _Nonnull action) {
                        NSArray *historyItems;
                        OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
                        historyItems = [helper getPointsHavingTypes:helper.searchTypes limit:0];
                        [helper removePoints:historyItems];
                        [self setupView];
                        [self.tableView reloadData];
                    }];
                    
                    [alert addAction:cancelAction];
                    [alert addAction:clearAction];
                    alert.preferredAction = clearAction;
                    [self presentViewController:alert animated:YES completion:nil];
                }
                [self.navigationController pushViewController:historyViewController animated:YES];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            default:
                break;
        }
    }
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOAHistory)
    {
        NSDictionary *sections = _data[section];
        NSArray *row = sections[@"rows"];
        return row.count;
    }
    else if (_settingsType == EOADialogsAndNotifications)
        return 1;
    else if (_settingsType == EOADefaultProfile)
        return _isUsingLastAppMode ? 1 : _data.count;
    else if (_settingsType == EOACarplayProfile)
        return _isDefaultProfile ? 1 : _data.count;
    else
        return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOADialogsAndNotifications || _settingsType == EOAHistory)
        return _data.count;
    else
        return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOAHistory)
    {
        NSDictionary *sections = _data[section];
        return sections[@"header"];
    }
    else if (_settingsType == EOACarplayProfile)
        return OALocalizedString(@"carplay_profile_descr");
    else if (_settingsType == EOADefaultProfile)
        return OALocalizedString(@"default_profile_descr");
    else
        return @"";
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOAHistory)
    {
        NSDictionary *sections = _data[section];
        return sections[@"footer"];
    }
    else if (_settingsType == EOADialogsAndNotifications)
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.text = title;
    vw.label.textColor = UIColorFromRGB(color_text_footer);
    return vw;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain && section == 2)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
    }
    else if (_settingsType == EOACarplayProfile)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + kCarplayHeaderTopMargin;
    }
    else if (_settingsType == EOADefaultProfile)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + kDefaultProfileHeaderTopMargin;
    }
    else if (_settingsType == EOAHistory && section == 1)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
    }
    else
        return section == 0 ? 18.0 : 16.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_settingsType == EOAGlobalSettingsMain)
        return 46.0;
    return UITableViewAutomaticDimension;
}

#pragma mark - Switch

- (void) updateTableView
{
    if (_settingsType == EOADefaultProfile)
    {
        if (!_isUsingLastAppMode)
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i <= _profileList.count; i++)
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i <= _profileList.count; i++)
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
    else if (_settingsType == EOACarplayProfile)
    {
        if (!_isDefaultProfile)
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i < _profileList.count; i++)
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView beginUpdates];
            for (NSInteger i = 1; i < _profileList.count; i++)
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item[@"name"];
        if (name)
        {
            if ([name isEqualToString:@"do_not_show_discount"])
                [_settings.settingDoNotShowPromotions set:isChecked];
            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
                [_settings.sendAnonymousAppUsageData set:isChecked];
            else if ([name isEqualToString:@"download_map_dialog"])
                [_settings.showDownloadMapDialog set:isChecked];
            else if ([name isEqualToString:@"last_used"])
            {
                [_settings.useLastApplicationModeByDefault set:isChecked];
                [self setupView];
                [self updateTableView];
            }
            else if ([name isEqualToString:@"carplay_mode_is_default_string"])
            {
                [_settings.isCarPlayModeDefault set:isChecked];
                [self setupView];
                [self updateTableView];
            }
        }
    }
}

@end
