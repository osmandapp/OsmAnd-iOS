//
//  OAGlobalSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsViewController.h"
#import "OAUninstallSpeedCamerasViewController.h"
#import "OAAppSettings.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"

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
    else
        return OALocalizedString(@"carplay_profile");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (void)addAccessibilityLabels
{
    self.leftNavbarButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
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

            OATableSectionData *defaultProfileSection = [OATableSectionData sectionData];
            [defaultProfileSection setFooterText:OALocalizedString(@"default_profile_descr")];
            [defaultProfileSection addRowFromDictionary:@{
                kCellKeyKey : @"settings_preset",
                kCellTitleKey : OALocalizedString(@"settings_preset"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                @"value" : _isUsingLastAppMode ? OALocalizedString(@"shared_string_last_used") : [[_settings.defaultApplicationMode get] toHumanString]
            }];
            [_data addSection:defaultProfileSection];

            OATableSectionData *carPlayProfileSection = [OATableSectionData sectionData];
            [carPlayProfileSection setFooterText:OALocalizedString(@"carplay_profile_descr")];
            [carPlayProfileSection addRowFromDictionary:@{
                kCellKeyKey : @"carplay_profile",
                kCellTitleKey : OALocalizedString(@"carplay_profile"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                @"value" : _isCarPlayDefaultProfile ? OALocalizedString(@"settings_preset") : [[_settings.carPlayMode get] toHumanString]
            }];
            [_data addSection:carPlayProfileSection];

            OATableSectionData *anonymousDataSection = [OATableSectionData sectionData];
            [anonymousDataSection setHeaderText:OALocalizedString(@"privacy_and_security")];
            [anonymousDataSection setFooterText:OALocalizedString(@"send_anonymous_data_desc")];
            [anonymousDataSection addRowFromDictionary:@{
                kCellKeyKey : @"do_not_send_anonymous_data",
                kCellTitleKey : OALocalizedString(@"send_anonymous_data"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.sendAnonymousAppUsageData get])
            }];
            [_data addSection:anonymousDataSection];

            OATableSectionData *dialogsSection = [OATableSectionData sectionData];
            [dialogsSection setHeaderText:OALocalizedString(@"other_location")];
            [dialogsSection setFooterText:OALocalizedString(@"dialogs_and_notifications_descr")];
            [dialogsSection addRowFromDictionary:@{
                kCellKeyKey : @"dialogs_and_notif",
                kCellTitleKey : OALocalizedString(@"dialogs_and_notifications_title"),
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                @"value" : [self getDialogsAndNotificationsValue]
            }];
            [_data addSection:dialogsSection];

            if (![_settings.speedCamerasUninstalled get])
            {
                OATableSectionData *speedCameraSection = [OATableSectionData sectionData];
                [speedCameraSection setHeaderText:OALocalizedString(@"shared_string_legal")];
                [speedCameraSection addRowFromDictionary:@{
                    kCellKeyKey : @"uninstall_speed_cameras",
                    kCellTitleKey : OALocalizedString(@"uninstall_speed_cameras"),
                    kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                }];
                [_data addSection:speedCameraSection];
            }

            break;
        }
        case EOADefaultProfile:
        {
            _isUsingLastAppMode = [_settings.useLastApplicationModeByDefault get];

            OATableSectionData *lastUsedSection = [OATableSectionData sectionData];
            [lastUsedSection addRowFromDictionary:@{
                kCellKeyKey : @"last_used",
                kCellTitleKey : OALocalizedString(@"shared_string_last_used"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @(_isUsingLastAppMode),
            }];
            [_data addSection:lastUsedSection];

            if (!_isUsingLastAppMode)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    [lastUsedSection addRowFromDictionary:@{
                        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
                        @"mode" : mode,
                        @"isSelected" : @([_settings.defaultApplicationMode get] == mode)
                    }];
                }
            }
            break;
        }
        case EOACarplayProfile:
        {
            _isCarPlayDefaultProfile = [_settings.isCarPlayModeDefault get];

            OATableSectionData *defaultSection = [OATableSectionData sectionData];
            [defaultSection addRowFromDictionary:@{
                kCellKeyKey : @"carplay_mode_is_default_string",
                kCellTitleKey : OALocalizedString(@"settings_preset"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @(_isCarPlayDefaultProfile),
            }];
            [_data addSection:defaultSection];

            if (!_isCarPlayDefaultProfile)
            {
                for (OAApplicationMode *mode in _profileList)
                {
                    [defaultSection addRowFromDictionary:@{
                        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
                        @"mode" : mode,
                        @"isSelected" : @([_settings.carPlayMode get] == mode)
                    }];
                }
            }
            break;
        }
        case EOADialogsAndNotifications:
        {
            OATableSectionData *promotionsSection = [OATableSectionData sectionData];
            [promotionsSection setFooterText:OALocalizedString(@"do_not_show_discount_desc")];
            [promotionsSection addRowFromDictionary:@{
                kCellKeyKey : @"do_not_show_discount",
                kCellTitleKey : OALocalizedString(@"do_not_show_discount"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.settingDoNotShowPromotions get])
            }];
            [_data addSection:promotionsSection];

            OATableSectionData *downloadMapSection = [OATableSectionData sectionData];
            [downloadMapSection addRowFromDictionary:@{
                kCellKeyKey : @"download_map_dialog",
                kCellTitleKey : OALocalizedString(@"download_map_dialog"),
                kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
                @"value" : @([_settings.showDownloadMapDialog get])
            }];
            [_data addSection:downloadMapSection];
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
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
            cell.titleLabel.text = item.title;
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
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            OAApplicationMode *appMode = [item objForKey:@"mode"];

            cell.titleLabel.text = [appMode toHumanString];
            cell.descriptionLabel.text = [appMode getProfileDescription];

            cell.leftIconView.image = [[appMode getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = UIColorFromRGB([appMode getIconColor]);

            [cell rightIconVisibility:[item boolForKey:@"isSelected"]];
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
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
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
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    switch (_settingsType)
    {
        case EOAGlobalSettingsMain:
        {
            UIViewController *settingsViewController = nil;
            if ([item.key isEqualToString:@"settings_preset"])
                settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADefaultProfile];
            else if ([item.key isEqualToString:@"carplay_profile"])
                settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOACarplayProfile];
            else if ([item.key isEqualToString:@"dialogs_and_notif"])
                settingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOADialogsAndNotifications];

            if (settingsViewController)
            {
                [self.navigationController pushViewController:settingsViewController animated:YES];
            }
            else
            {
                if ([item.key isEqualToString:@"uninstall_speed_cameras"])
                {
                    settingsViewController = [[OAUninstallSpeedCamerasViewController alloc] init];
                    ((OAUninstallSpeedCamerasViewController *) settingsViewController).delegate = self;
                }

                if (settingsViewController)
                    [self presentViewController:settingsViewController animated:YES completion:nil];
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
        default:
            break;
    }
}

#pragma mark - Selectors

- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

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

#pragma mark - OAUninstallSpeedCamerasDelegate

- (void)onUninstallSpeedCameras
{
    [self generateData];
    [self.tableView reloadData];
}

@end
