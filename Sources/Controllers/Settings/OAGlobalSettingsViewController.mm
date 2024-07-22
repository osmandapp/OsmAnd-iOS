//
//  OAGlobalSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsViewController.h"
#import "OAUninstallSpeedCamerasViewController.h"
#import "OAHistorySettingsViewController.h"
#import "OAExportItemsViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAAppSettings.h"
#import "OATargetPointsHelper.h"
#import "OAHistoryHelper.h"
#import "OAExportSettingsType.h"
#import "OAColors.h"
#import "OASizes.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAGlobalSettingsViewController () <OAUninstallSpeedCamerasDelegate>

@end

@implementation OAGlobalSettingsViewController
{
    OAAppSettings *_settings;
    EOAGlobalSettingsScreen _settingsType;
    OATableDataModel *_data;
    NSArray<OAApplicationMode *> * _profileList;
    BOOL _isCarPlayDefaultProfile;
    BOOL _isUsingLastAppMode;
    OAApplicationMode *_selectedProfile;
    OAApplicationMode *_selectedCarPlayProfile;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(EOAGlobalSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    NSMutableArray<OAApplicationMode *> *profileList = [NSMutableArray arrayWithArray:[OAApplicationMode values]];
    if (_settingsType == EOACarplayProfile)
        [profileList removeObject:OAApplicationMode.DEFAULT];
    _profileList = profileList;
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
    if (_settingsType == EOAGlobalSettingsMain)
        return OALocalizedString(@"osmand_settings");
    else if (_settingsType == EOADefaultProfile)
        return OALocalizedString(@"settings_preset");
    else if (_settingsType == EOADialogsAndNotifications)
        return OALocalizedString(@"dialogs_and_notifications_title");
    else if (_settingsType == EOAHistory)
        return OALocalizedString(@"shared_string_history");
    else
        return OALocalizedString(@"carplay_profile");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    switch (_settingsType)
    {
        case EOAGlobalSettingsMain:
        {
            _selectedProfile = [_settings.defaultApplicationMode get];
            _selectedCarPlayProfile = [_settings.carPlayMode get];
            _isUsingLastAppMode = [_settings.useLastApplicationModeByDefault get];
            _isCarPlayDefaultProfile = [_settings.isCarPlayModeDefault get];

            OATableSectionData *defaultProfileSection = [_data createNewSection];
            [defaultProfileSection setFooterText:OALocalizedString(@"default_profile_descr")];
            [defaultProfileSection addRowFromDictionary:@{
                kCellKeyKey : @"settings_preset",
                kCellTitleKey : OALocalizedString(@"settings_preset"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
                @"value" : _isUsingLastAppMode ? OALocalizedString(@"shared_string_last_used") : [[_settings.defaultApplicationMode get] toHumanString]
            }];

            OATableSectionData *carPlayProfileSection = [_data createNewSection];
            [carPlayProfileSection setFooterText:OALocalizedString(@"carplay_profile_descr")];
            [carPlayProfileSection addRowFromDictionary:@{
                kCellKeyKey : @"carplay_profile",
                kCellTitleKey : OALocalizedString(@"carplay_profile"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
                @"value" : _isCarPlayDefaultProfile ? OALocalizedString(@"settings_preset") : [[_settings.carPlayMode get] toHumanString]
            }];

            OATableSectionData *privacyDataSection = [_data createNewSection];
            [privacyDataSection setHeaderText:OALocalizedString(@"privacy_and_security")];
            [privacyDataSection setFooterText:OALocalizedString(@"send_anonymous_data_desc")];
            [privacyDataSection addRowFromDictionary:@{
                kCellKeyKey : @"do_not_send_anonymous_data",
                kCellTitleKey : OALocalizedString(@"send_anonymous_data"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.sendAnonymousAppUsageData get])
            }];
            [privacyDataSection addRowFromDictionary:@{
                kCellKeyKey : @"history_settings",
                kCellTitleKey : OALocalizedString(@"shared_string_history"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
                @"value" : [_settings.searchHistory get] || [_settings.navigationHistory get] || [_settings.mapMarkersHistory get] ? @"" : OALocalizedString(@"shared_string_off"),
            }];

            OATableSectionData *dialogsSection = [_data createNewSection];
            [dialogsSection setHeaderText:OALocalizedString(@"other_location")];
            [dialogsSection setFooterText:OALocalizedString(@"dialogs_and_notifications_descr")];
            [dialogsSection addRowFromDictionary:@{
                kCellKeyKey : @"dialogs_and_notif",
                kCellTitleKey : OALocalizedString(@"dialogs_and_notifications_title"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
                @"value" : [self getDialogsAndNotificationsValue]
            }];

            if (![_settings.speedCamerasUninstalled get])
            {
                OATableSectionData *speedCameraSection = [_data createNewSection];
                [speedCameraSection setHeaderText:OALocalizedString(@"shared_string_legal")];
                [speedCameraSection addRowFromDictionary:@{
                    kCellKeyKey : @"uninstall_speed_cameras",
                    kCellTitleKey : OALocalizedString(@"uninstall_speed_cameras"),
                    kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                }];
            }

            break;
        }
        case EOADefaultProfile:
        {
            _isUsingLastAppMode = [_settings.useLastApplicationModeByDefault get];

            OATableSectionData *lastUsedSection = [_data createNewSection];
            [lastUsedSection addRowFromDictionary:@{
                kCellKeyKey : @"last_used",
                kCellTitleKey : OALocalizedString(@"shared_string_last_used"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @(_isUsingLastAppMode),
            }];

            if (!_isUsingLastAppMode)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    [lastUsedSection addRowFromDictionary:@{
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        kCellAccessoryType : @([_settings.defaultApplicationMode get] == mode ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                        @"mode" : mode
                    }];
                }
            }
            break;
        }
        case EOACarplayProfile:
        {
            _isCarPlayDefaultProfile = [_settings.isCarPlayModeDefault get];

            OATableSectionData *defaultSection = [_data createNewSection];
            [defaultSection addRowFromDictionary:@{
                kCellKeyKey : @"carplay_mode_is_default_string",
                kCellTitleKey : OALocalizedString(@"settings_preset"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @(_isCarPlayDefaultProfile),
            }];

            if (!_isCarPlayDefaultProfile)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    [defaultSection addRowFromDictionary:@{
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        kCellAccessoryType : @([_settings.carPlayMode get] == mode ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone),
                        @"mode" : mode
                    }];
                }
            }
            break;
        }
        case EOAHistory:
        {
            OAHistoryHelper *historyHelper = [OAHistoryHelper sharedInstance];
            OATableSectionData *historySection = [_data createNewSection];
            [historySection setFooterText:OALocalizedString(@"history_preferences_descr")];
            BOOL searchHistory = [_settings.searchHistory get];
            BOOL navigationHistory = [_settings.navigationHistory get];
            BOOL mapMarkersHistory = [_settings.mapMarkersHistory get];

            [historySection addRowFromDictionary:@{
                kCellKeyKey : @"search_history",
                kCellTitleKey : OALocalizedString(@"shared_string_search_history"),
                kCellIconNameKey : @"ic_custom_search",
                kCellIconTint : (searchHistory ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDefault]),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                @"value" : searchHistory
                ? [NSString stringWithFormat:@"%lu", [historyHelper getPointsCountHavingTypes:historyHelper.searchTypes]]
                : OALocalizedString(@"shared_string_off"),
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
            }];
            [historySection addRowFromDictionary:@{
                kCellKeyKey : @"navigation_history",
                kCellTitleKey : OALocalizedString(@"navigation_history"),
                kCellIconNameKey : @"ic_custom_navigation",
                kCellIconTint : (navigationHistory ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDefault]),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
                @"value" : navigationHistory
                    ? [NSString stringWithFormat:@"%ld", [self calculateNavigationItemsCount]]
                    : OALocalizedString(@"shared_string_off"),
            }];
            [historySection addRowFromDictionary:@{
                kCellKeyKey : @"map_markers_history",
                kCellTitleKey : OALocalizedString(@"map_markers_history"),
                kCellIconNameKey : @"ic_custom_marker",
                kCellIconTint : (mapMarkersHistory ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDefault]),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                @"value" : mapMarkersHistory
                    ? [NSString stringWithFormat:@"%lu", [historyHelper getPointsCountHavingTypes:historyHelper.destinationTypes]]
                : OALocalizedString(@"shared_string_off"),
                kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator)
            }];

            OATableSectionData *actionsSection = [_data createNewSection];
            [actionsSection setHeaderText:OALocalizedString(@"actions")];
            [actionsSection setFooterText:OALocalizedString(@"history_actions_footer_text")];

            [actionsSection addRowFromDictionary:@{
                kCellKeyKey : @"export_history",
                kCellTitleKey : OALocalizedString(@"shared_string_export"),
                kCellIconNameKey : @"ic_custom_export",
                kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
                @"value" : @(_settings.sendAnonymousAppUsageData.get),
            }];
            [actionsSection addRowFromDictionary:@{
                kCellKeyKey : @"clear_history",
                kCellTitleKey : OALocalizedString(@"history_clear_alert_title"),
                kCellIconNameKey : @"ic_custom_remove_outlined",
                kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
                @"value" : [self getDialogsAndNotificationsValue],
            }];
            break;
        }
        case EOADialogsAndNotifications:
        {
            OATableSectionData *promotionsSection = [_data createNewSection];
            [promotionsSection setFooterText:OALocalizedString(@"do_not_show_discount_desc")];
            [promotionsSection addRowFromDictionary:@{
                kCellKeyKey : @"do_not_show_discount",
                kCellTitleKey : OALocalizedString(@"do_not_show_discount"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.settingDoNotShowPromotions get])
            }];

            OATableSectionData *downloadMapSection = [_data createNewSection];
            [downloadMapSection addRowFromDictionary:@{
                kCellKeyKey : @"download_map_dialog",
                kCellTitleKey : OALocalizedString(@"download_map_dialog"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.showDownloadMapDialog get])
            }];
        }
        default:
            break;
    }
}

- (NSString *)getDialogsAndNotificationsValue
{
    NSInteger valuesEnabled = 0;
    NSInteger allValues = 0;

    if ([_settings.settingDoNotShowPromotions get])
        valuesEnabled++;
    allValues++;

    if ([_settings.showDownloadMapDialog get])
        valuesEnabled++;
    allValues++;

    if (allValues == valuesEnabled)
        return OALocalizedString(@"shared_string_all");
    else if (valuesEnabled == 0)
        return OALocalizedString(@"shared_string_none");

    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_slash"), @(valuesEnabled).stringValue, @(allValues).stringValue];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
        }
        if (cell)
        {
            cell.accessoryType = item.accessoryType;
            OAApplicationMode *appMode = [item objForKey:@"mode"];
            if (appMode)
            {
                cell.titleLabel.text = [appMode toHumanString];
                cell.descriptionLabel.text = [appMode getProfileDescription];
                [cell descriptionVisibility:YES];

                cell.leftIconView.image = [[appMode getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                cell.leftIconView.tintColor = [appMode getProfileColor];
                [cell leftIconVisibility:YES];
            }
            else
            {
                [cell leftIconVisibility:NO];
                [cell descriptionVisibility:NO];
                cell.titleLabel.text = item.title;
            }
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL isClearHistory = [item.key isEqualToString:@"clear_history"];
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = isClearHistory ? [UIColor colorNamed:ACColorNameButtonBgColorDisruptive] : [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.rightIconView.tintColor = isClearHistory ? [UIColor colorNamed:ACColorNameButtonBgColorDisruptive] : [UIColor colorNamed:ACColorNameIconColorActive];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;

            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [item boolForKey:@"value"];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.accessoryType = item.accessoryType;
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];

            BOOL hasLeftIcon = item.iconName && item.iconName.length > 0;
            [cell leftIconVisibility:hasLeftIcon];
            cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:item.iconName] : nil;
            BOOL hasTintColor = item.iconName && item.iconName.length > 0;
            cell.leftIconView.tintColor = hasTintColor ? [item objForKey:kCellIconTint] : [UIColor colorNamed:ACColorNameIconColorActive];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    switch (_settingsType)
    {
        case EOAGlobalSettingsMain:
        {
            if ([item.key isEqualToString:@"uninstall_speed_cameras"])
            {
                OAUninstallSpeedCamerasViewController *uninstallSpeedCamerasViewController = [[OAUninstallSpeedCamerasViewController alloc] init];
                uninstallSpeedCamerasViewController.delegate = self;
                [self showModalViewController:uninstallSpeedCamerasViewController];
            }
            else
            {
                UIViewController *settingsViewController = nil;
                if ([item.key isEqualToString:@"settings_preset"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADefaultProfile];
                else if ([item.key isEqualToString:@"carplay_profile"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOACarplayProfile];
                else if ([item.key isEqualToString:@"history_settings"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAHistory];
                else if ([item.key isEqualToString:@"dialogs_and_notif"])
                    settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADialogsAndNotifications];
                
                if (settingsViewController)
                {
                    [self.navigationController pushViewController:settingsViewController animated:YES];
                }
            }
            break;
        }
        case EOADefaultProfile:
        {
            OAApplicationMode *appMode = [item objForKey:@"mode"];
            [_settings.defaultApplicationMode set:appMode];
            [_settings setApplicationModePref:appMode];
            [self dismissViewController];
            break;
        }
        case EOACarplayProfile:
        {
            OAApplicationMode *appMode = [item objForKey:@"mode"];
            [_settings.carPlayMode set:appMode];
            [self dismissViewController];
            break;
        }
        case EOAHistory:
        {
            if ([item.key isEqualToString:@"clear_history"])
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"history_clear_alert_title")
                                                                                message:OALocalizedString(@"history_clear_alert_message")
                                                                        preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                        style:UIAlertActionStyleDefault
                                                                        handler:nil
                            ];
                UIAlertAction *clearAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_clear")
                                                                        style:UIAlertActionStyleDestructive
                                                                    handler:^(UIAlertAction * _Nonnull action) {
                    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
                    [helper removePoints:[helper getAllPoints:YES]];
                    [self generateData];
                    [self.tableView reloadData];
                }];

                [alert addAction:cancelAction];
                [alert addAction:clearAction];
                alert.preferredAction = clearAction;
                [self presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                if ([item.key isEqualToString:@"export_history"])
                {
                    OAHistoryHelper *historyHelper = [OAHistoryHelper sharedInstance];
                    NSDictionary<OAExportSettingsType *, NSArray<id> *> *typesItems = @{
                        OAExportSettingsType.HISTORY_MARKERS : [historyHelper getPointsHavingTypes:historyHelper.destinationTypes limit:0],
                        OAExportSettingsType.SEARCH_HISTORY : [historyHelper getPointsHavingTypes:historyHelper.searchTypes limit:0],
                        OAExportSettingsType.NAVIGATION_HISTORY : [historyHelper getPointsFromNavigation:0]
                    };
                    [self.navigationController pushViewController:[[OAExportItemsViewController alloc] initWithTypes:typesItems] animated:YES];
                }
                else
                {
                    OAHistorySettingsViewController *historyViewController;
                    if ([item.key isEqualToString:@"search_history"])
                        historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
                    else if ([item.key isEqualToString:@"navigation_history"])
                        historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAHistorySettingsTypeNavigation editing:NO];
                    else if ([item.key isEqualToString:@"map_markers_history"])
                        historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAHistorySettingsTypeMapMarkers editing:NO];
                    if (historyViewController)
                        [self.navigationController pushViewController:historyViewController animated:YES];
                }
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - Selectors

- (void)updateTableView
{
    BOOL isDefault = _settingsType == EOADefaultProfile;
    BOOL isCarPlay = _settingsType == EOACarplayProfile;
    if (isDefault || isCarPlay)
    {
        NSMutableArray<NSIndexPath *> *rows = [NSMutableArray array];
        for (NSInteger i = 1; i <= _profileList.count; i++)
        {
            [rows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }

        [self.tableView beginUpdates];
        if ((isDefault && !_isUsingLastAppMode) || (isCarPlay && !_isCarPlayDefaultProfile))
            [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
        else if ((isDefault && _isUsingLastAppMode) || (isCarPlay && _isCarPlayDefaultProfile))
            [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)onSwitchPressed:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        BOOL isChecked = ((UISwitch *) sender).on;

        if ([item.key isEqualToString:@"do_not_show_discount"])
        {
            [_settings.settingDoNotShowPromotions set:isChecked];
        }
        else if ([item.key isEqualToString:@"do_not_send_anonymous_data"])
        {
            [_settings.sendAnonymousAppUsageData set:isChecked];
        }
        else if ([item.key isEqualToString:@"download_map_dialog"])
        {
            [_settings.showDownloadMapDialog set:isChecked];
        }
        else if ([item.key isEqualToString:@"last_used"])
        {
            [_settings.useLastApplicationModeByDefault set:isChecked];
            [self generateData];
            [self updateTableView];
        }
        else if ([item.key isEqualToString:@"carplay_mode_is_default_string"])
        {
            [_settings.isCarPlayModeDefault set:isChecked];
            [self generateData];
            [self updateTableView];
        }
    }
}

#pragma mark - Additions

- (NSInteger)calculateNavigationItemsCount
{
    NSInteger count = [[OAHistoryHelper sharedInstance] getPointsCountFromNavigation];
    if ([[OATargetPointsHelper sharedInstance] isBackupPointsAvailable])
    {
        // Take "Previous Route" item into account during calculations
        count++;
    }
    return count;
}

#pragma mark - OAUninstallSpeedCamerasDelegate

- (void)onUninstallSpeedCameras
{
    [self generateData];
    [self.tableView reloadData];
}

@end
