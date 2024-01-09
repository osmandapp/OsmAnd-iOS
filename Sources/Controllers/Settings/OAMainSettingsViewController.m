//
//  OAMainSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OAMainSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"
#import "OAPurchasesViewController.h"
#import "OABackupHelper.h"
#import "OASizes.h"
#import "OACreateProfileViewController.h"
#import "OARearrangeProfilesViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAExportItemsViewController.h"
#import "OACloudIntroductionViewController.h"
#import "OACloudBackupViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAMainSettingsViewController () <UIDocumentPickerDelegate>

@end

@implementation OAMainSettingsViewController
{
    OAAppSettings *_settings;

    NSArray<NSArray *> *_data;
    int _globalSettingsSection;
    int _selectedProfileSection;
    int _applicationProfilesSection;
    int _localBackupSection;

    OAApplicationMode *_targetAppMode;
    NSString *_targetScreenKey;
    int _lastSwitchedAppModeRow;
}

#pragma mark - Initialization

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey
{
    self = [super init];
    if (self)
    {
        _targetAppMode = mode;
        _targetScreenKey = targetScreenKey;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _globalSettingsSection = -1;
    _selectedProfileSection = -1;
    _applicationProfilesSection = -1;
    _localBackupSection = -1;
    _lastSwitchedAppModeRow = -1;
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAvailableAppModesChanged)
                                                 andObserve:[OsmAndApp instance].availableAppModesChangedObservable]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAvailableAppModesChanged)
                                                 andObserve:OsmAndApp.instance.data.applicationModeChangedObservable]];
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OACloudBackupViewController class]])
        {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            return;
        }
    }
    [super viewWillDisappear:animated];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_settings");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_targetAppMode)
    {
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:_targetAppMode
                                                                                                  targetScreenKey:_targetScreenKey];
        [self.navigationController pushViewController:profileConf animated:YES];
        _targetAppMode = nil;
        _targetScreenKey = nil;
    }
}

#pragma mark - Table data

- (void)generateData
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"name" : @"osmand_settings",
            @"title" : OALocalizedString(@"osmand_settings"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"left_menu_icon_settings",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        },
        @{
            @"name" : @"backup_restore",
            @"title" : OALocalizedString(@"osmand_cloud"),
            @"value" : @"", // TODO: insert value
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_cloud_upload_colored_day",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        },
        @{
            @"name" : @"purchases",
            @"title" : OALocalizedString(@"purchases"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_shop_bag",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        }
    ]];
    _globalSettingsSection = data.count - 1;

    [data addObject:@[
        @{
            @"name" : @"current_profile",
            @"app_mode" : appMode,
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"isColored" : @YES
        }
    ]];
    _selectedProfileSection = data.count - 1;

    NSMutableArray *profilesSection = [NSMutableArray new];
    for (int i = 0; i < OAApplicationMode.allPossibleValues.count; i++)
    {
        [profilesSection addObject:@{
            @"name" : @"profile_val",
            @"app_mode" : OAApplicationMode.allPossibleValues[i],
            @"type" : i == 0 ? [OASimpleTableViewCell getCellIdentifier] : [OASwitchTableViewCell getCellIdentifier],
            @"isColored" : @NO
        }];
    }

    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"new_profile"),
        @"img" : @"ic_custom_add",
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"name" : @"add_profile"
    }];

    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"reorder_profiles"),
        @"img" : @"ic_custom_edit",
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"name" : @"edit_profiles"
    }];
    
    [data addObject:profilesSection];
    _applicationProfilesSection = data.count - 1;

    [data addObject:[self getLocalBackupSectionData]];
    _localBackupSection = data.count - 1;

    _data = [NSArray arrayWithArray:data];
}

- (NSArray *)getLocalBackupSectionData
{
    return @[
        @{
            @"type": OARightIconTableViewCell.getCellIdentifier,
            @"name": @"backupIntoFile",
            @"title": OALocalizedString(@"backup_into_file"),
            @"img": @"ic_custom_save_to_file",
            @"regular_text": @(YES)
        },
        @{
            @"type": OARightIconTableViewCell.getCellIdentifier,
            @"name": @"restoreFromFile",
            @"title": OALocalizedString(@"restore_from_file"),
            @"img": @"ic_custom_read_from_file",
            @"regular_text": @(YES)
        }
    ];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"profile_type_custom_string") : OALocalizedString(@"profile_type_base_string");
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == _selectedProfileSection)
        return OALocalizedString(@"selected_profile");
    else if (section == _applicationProfilesSection)
        return OALocalizedString(@"application_profiles");
    else if (section == _localBackupSection)
        return OALocalizedString(@"local_backup");

    return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (section == _globalSettingsSection)
        return OALocalizedString(@"global_settings_descr");
    else if (section == _applicationProfilesSection)
        return OALocalizedString(@"import_profile_descr");
    else if (section == _localBackupSection)
        return OALocalizedString(@"local_backup_descr");

    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.leftIconView.image = [item[@"name"] isEqualToString:@"backup_restore"] ? [UIImage rtlImageNamed:item[@"img"]] : [UIImage templateImageNamed:item[@"img"]];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            cell.titleLabel.numberOfLines = 3;
            cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            OAApplicationMode *am = item[@"app_mode"];
            UIImage *img = am.getIcon;
            cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.leftIconView.tintColor = UIColorFromRGB(am.getIconColor);
            cell.titleLabel.text = am.toHumanString;
            cell.descriptionLabel.text = [self getProfileDescription:am];
            cell.contentView.backgroundColor = UIColor.clearColor;
            if ([item[@"isColored"] boolValue])
                cell.backgroundColor = [UIColor colorNamed:ACColorNameCellBgColorSelected];
            else
                cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        OAApplicationMode *am = item[@"app_mode"];
        BOOL isEnabled = [OAApplicationMode.values containsObject:am];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? kPaddingToLeftOfContentWithIcon : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
        cell.leftIconView.tintColor = isEnabled ? UIColorFromRGB(am.getIconColor) : [UIColor colorNamed:ACColorNameIconColorDisabled];
        cell.titleLabel.text = am.toHumanString;
        cell.descriptionLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        BOOL isDefault = am == OAApplicationMode.DEFAULT;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (!isDefault)
        {
            [cell.switchView setOn:isEnabled];
            [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        [cell switchVisibility:!isDefault];
        [cell dividerVisibility:!isDefault];
        return cell;
    }
    else if ([type isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if ([item[@"regular_text"] boolValue])
        {
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        else
        {
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        cell.titleLabel.text = item[@"title"];
        [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    [self selectSettingMain:item];
}

#pragma mark - Selectors

- (void)onBackupIntoFilePressed
{
    OAExportItemsViewController *exportController = [[OAExportItemsViewController alloc] init];
    [self.navigationController pushViewController:exportController animated:YES];
}

- (void)onRestoreFromFilePressed
{
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"net.osmand.osf"] inMode:UIDocumentPickerModeImport];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

- (void) selectSettingMain:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    if ([name isEqualToString:@"osmand_settings"])
    {
        OAGlobalSettingsViewController* globalSettingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAGlobalSettingsMain];
        [self.navigationController pushViewController:globalSettingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"backup_restore"])
    {
        UIViewController *vc;
        if (OABackupHelper.sharedInstance.isRegistered)
            vc = [[OACloudBackupViewController alloc] init];
        else
            vc = [[OACloudIntroductionViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([name isEqualToString:@"purchases"])
    {
        OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
        [self.navigationController pushViewController:purchasesViewController animated:YES];
    }
    else if ([name isEqualToString:@"profile_val"] || [name isEqualToString:@"current_profile"])
    {
        OAApplicationMode *mode = item[@"app_mode"];
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:mode
                                                                                                  targetScreenKey:nil];
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
    else if ([name isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([name isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    if (sender.tag < OAApplicationMode.allPossibleValues.count)
    {
        _lastSwitchedAppModeRow = (int) sender.tag;
        OAApplicationMode *am = OAApplicationMode.allPossibleValues[sender.tag];
        [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
    }
}

- (void)onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        if (_lastSwitchedAppModeRow != -1)
        {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_lastSwitchedAppModeRow inSection:_applicationProfilesSection]] withRowAnimation:UITableViewRowAnimationFade];
            _lastSwitchedAppModeRow = -1;
        }
        else
        {
            [self.tableView reloadData];
        }
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSString *path = urls[0].path;
    NSString *extension = [[path pathExtension] lowercaseString];
    if ([extension caseInsensitiveCompare:@"osf"] == NSOrderedSame)
        [OASettingsHelper.sharedInstance collectSettings:urls[0].path latestChanges:@"" version:1];
}

@end
