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
#import "OAMultiIconTextDescCell.h"
#import "OATableViewCustomHeaderView.h"
#import "Localization.h"
#import "OAColors.h"

#define kCarplayHeaderTopMargin 40

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
                    @"name" : @"settings_preset",
                    @"title" : OALocalizedString(@"settings_preset"),
                    @"value" : _settings.useLastApplicationModeByDefault.get ? OALocalizedString(@"last_used") : _settings.defaultApplicationMode.get.toHumanString,
                    @"description" : OALocalizedString(@"default_profile_descr"),
                    @"img" : @"menu_cell_pointer.png",
                    @"type" : [OASettingsTableViewCell getCellIdentifier] },
                @{
                    @"name" : @"carplay_profile",
                    @"title" : OALocalizedString(@"carplay_profile"),
                    @"value" : _settings.isCarPlayModeDefault.get ? OALocalizedString(@"settings_preset") : _settings.carPlayMode.get.toHumanString,
                    @"description" : OALocalizedString(@"carplay_profile_descr"),
                    @"img" : @"menu_cell_pointer.png",
                    @"type" : [OASettingsTableViewCell getCellIdentifier] },
                @{
                    @"name" : @"dialogs_and_notif",
                    @"title" : OALocalizedString(@"dialogs_and_notifications"),
                    @"description" : OALocalizedString(@"dialogs_and_notifications_descr"),
                    @"value" : [self getDialogsAndNotificationsValue],
                    @"img" : @"menu_cell_pointer.png",
                    @"type" : [OASettingsTableViewCell getCellIdentifier]
                },
                @{
                    @"name" : @"do_not_send_anonymous_data",
                    @"title" : OALocalizedString(@"send_anonymous_data"),
                    @"description" : OALocalizedString(@"send_anonymous_data_desc"),
                    @"value" : @(_settings.settingUseAnalytics.get),
                    @"img" : @"menu_cell_pointer.png",
                    @"type" : [OASwitchTableViewCell getCellIdentifier], }
            ];
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
                @"img" : @"menu_cell_pointer.png",
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
                @"img" : @"menu_cell_pointer.png",
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
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOADialogsAndNotifications)
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
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
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
            default:
                break;
        }
    }
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOADialogsAndNotifications)
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
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOADialogsAndNotifications)
        return _data.count;
    else
        return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == EOACarplayProfile)
        return OALocalizedString(@"carplay_profile_descr");
    else
        return @"";
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == EOAGlobalSettingsMain || _settingsType == EOADialogsAndNotifications)
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
    if (_settingsType == EOACarplayProfile)
    {
        NSString *title = [self tableView:tableView titleForHeaderInSection:section];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + kCarplayHeaderTopMargin;
    }
    else
        return section == 0 ? 18.0 : 16.0;
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
                [_settings.settingUseAnalytics set:isChecked];
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
