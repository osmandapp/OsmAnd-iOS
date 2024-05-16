//
//  OAConfigureProfileViewController.m
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAConfigureProfileViewController.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAPlugin.h"
#import "OAMonitoringPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAOsmandDevelopmentViewController.h"
#import "OASettingsHelper.h"
#import "OAProfileSettingsItem.h"
#import "OAMapStyleSettings.h"
#import "OAPOIFiltersHelper.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OARootViewController.h"
#import "OAProfileAppearanceViewController.h"
#import "OACopyProfileBottomSheetViewControler.h"
#import "OADeleteProfileBottomSheetViewController.h"
#import "OATripRecordingSettingsViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OARendererRegistry.h"
#import "OAExportItemsViewController.h"
#import "OAIndexConstants.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherSettingsViewController.h"
#import "OAWikipediaPlugin.h"
#import "OAWikipediaSettingsViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OACloudIntroductionViewController.h"
#import "OABackupHelper.h"
#import "OAChoosePlanHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#define kSidePadding 16.
#define BACKUP_INDEX_DIR @"backup"
#define OSMAND_SETTINGS_FILE_EXT @"osf"
#define kWasClosedFreeBackupSettingsBannerKey @"wasClosedFreeBackupSettingsBanner"

typedef NS_ENUM(NSInteger, EOADashboardScreenType) {
    EOADashboardScreenTypeNone = 0,
    EOADashboardScreenTypeMap,
    EOADashboardScreenTypeScreen
};

@interface OAConfigureProfileViewController () <OACopyProfileBottomSheetDelegate, OADeleteProfileBottomSheetDelegate, OASettingsImportExportDelegate>

@end

@implementation OAConfigureProfileViewController
{
    OAApplicationMode *_appMode;
    
    NSArray<NSString *> *_sectionHeaderTitles;
    NSArray<NSString *> *_sectionFooterTitles;
    
    NSArray<NSArray *> *_data;
    
    OAAutoObserverProxy* _appModeChangeObserver;
    
    EOADashboardScreenType _screenToOpen;
    UIView *_cpyProfileViewUnderlay;
    NSString *_importedFileName;
    NSString *_targetScreenKey;
    FreeBackupBanner *_freeBackupBanner;
}

#pragma mark - Initialization

- (instancetype) initWithAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey
{
    self = [super init];
    if (self)
    {
        _appMode = mode;
        _targetScreenKey = targetScreenKey;
    }
    return self;
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAvailableAppModesChanged)
                                                 andObserve:[OsmAndApp instance].availableAppModesChangedObservable]];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [self.tableView registerClass:[FreeBackupBannerCell class] forCellReuseIdentifier:[FreeBackupBannerCell getCellIdentifier]];
    
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_targetScreenKey)
    {
        [self openTargetSettingsScreen:_targetScreenKey];
        _targetScreenKey = nil;
    }
}

- (BOOL) refreshOnAppear
{
    return YES;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return [_appMode toHumanString];
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (UIImage *)getRightIconLargeTitle
{
    return [UIImage templateImageNamed:[_appMode getIconName]];
}

- (UIColor *)getRightIconTintColorLargeTitle
{
    return UIColorFromRGB([_appMode getIconColor]);
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSString *> *sectionHeaderTitles = [NSMutableArray array];
    NSMutableArray<NSString *> *sectionFooterTitles = [NSMutableArray array];
    NSMutableArray<NSArray *> *data = [NSMutableArray new];
    if (_appMode != OAApplicationMode.DEFAULT)
    {
        [data addObject:@[
            @{
                @"type" : [OASwitchTableViewCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_enabled")
            }
        ]];
        [sectionHeaderTitles addObject:OALocalizedString(@"configure_profile")];
        [sectionFooterTitles addObject:@""];
    }
    if ([self isAvailablePaymentBanner])
    {
        {
            [data addObject:@[
                @{
                    @"type" : [FreeBackupBannerCell getCellIdentifier]
                }
            ]];
            [sectionHeaderTitles addObject:@""];
            [sectionFooterTitles addObject:@""];
        }
    }

    NSMutableArray<NSDictionary *> *profileSettings = [NSMutableArray new];
    [profileSettings addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"general_settings_2"),
        @"descr" : OALocalizedString(@"general_settings_descr"),
        @"img" : @"left_menu_icon_settings",
        @"key" : @"general_settings"
    }];
    if (_appMode != OAApplicationMode.DEFAULT)
    {
        [profileSettings addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"routing_settings_2"),
            @"descr" : OALocalizedString(@"routing_settings_descr"),
            @"img" : @"left_menu_icon_navigation",
            @"key" : kNavigationSettings
        }];
    }
    [profileSettings addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"configure_map"),
        @"descr" : OALocalizedString(@"map_look_descr"),
        @"img" : @"left_menu_icon_map",
        @"key" : @"configure_map"
    }];
    [profileSettings addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"layer_map_appearance"),
        @"descr" : OALocalizedString(@"edit_profile_screen_options_subtitle"),
        @"img" : @"left_menu_configure_screen",
        @"key" : @"configure_screen"
    }];
    [profileSettings addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"profile_appearance"),
        @"descr" : OALocalizedString(@"profile_appearance_descr"),
        @"img" : _appMode.getIconName,
        @"key" : @"profile_appearance"
    }];
    
        // TODO: add ui customization
//        @{
//            @"type" : [OASimpleTableViewCell getCellIdentifier],
//            @"title" : OALocalizedString(@"ui_customization"),
//            @"descr" : OALocalizedString(@"ui_customization_short_descr"),
//            @"img" : todo,
//            @"key" : @"ui_customization"
//        }
    [data addObject:profileSettings];
    [sectionHeaderTitles addObject:OALocalizedString(@"profile_settings")];
    [sectionFooterTitles addObject:OALocalizedString(@"profile_sett_descr")];

    // Plugins
    NSMutableArray *plugins = [NSMutableArray new];
    OAPlugin *tripRec = [OAPluginsHelper getEnabledPlugin:OAMonitoringPlugin.class];
    if (tripRec)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : tripRec.getName,
            @"img" : @"ic_custom_trip",
            @"key" : kTrackRecordingSettings
        }];
    }
    
    OAPlugin *osmEdit = [OAPluginsHelper getEnabledPlugin:OAOsmEditingPlugin.class];
    if (osmEdit)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : osmEdit.getName,
            @"img" : @"ic_custom_osm_edits",
            @"key" : kOsmEditsSettings
        }];
    }
    
    OAPlugin *developmentPlugin = [OAPluginsHelper getEnabledPlugin:OAOsmandDevelopmentPlugin.class];
    if (developmentPlugin)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : developmentPlugin.getName,
            @"img" : @"ic_custom_laptop",
            @"key" : kOsmandDevelopmentSettings
        }];
    }
    
    OAPlugin *weather = [OAPluginsHelper getEnabledPlugin:OAWeatherPlugin.class];
    if (weather)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : weather.getName,
            @"img" : @"ic_custom_umbrella",
            @"key" : kWeatherSettings
        }];
    }
    
    OAPlugin *wikipedia = [OAPluginsHelper getEnabledPlugin:OAWikipediaPlugin.class];
    if (wikipedia)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : wikipedia.getName,
            @"img" : @"ic_custom_wikipedia",
            @"key" : kWikipediaSettings
        }];
    }
    OAPlugin *externalSensors = [OAPluginsHelper getEnabledPlugin:OAExternalSensorsPlugin.class];
    if (externalSensors)
    {
        [plugins addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : externalSensors.getName,
            @"img" : @"ic_custom_sensor",
            @"key" : kExternalSensors
        }];
    }
    
    if (plugins.count > 0)
    {
        [data addObject:plugins];
        [sectionHeaderTitles addObject:OALocalizedString(@"plugins_menu_group")];
        [sectionFooterTitles addObject:OALocalizedString(@"plugin_settings_descr")];
    }
    
    // Actions
    NSMutableArray<NSDictionary *> *settingsActions = [NSMutableArray new];
    [settingsActions addObject:@{
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"export_profile"),
        @"img" : @"ic_custom_export",
        @"key" : @"export_profile"
    }];
    [settingsActions addObject:@{
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"copy_from_other_profile"),
        @"img" : @"ic_custom_copy",
        @"key" : @"copy_profile"
    }];
    
    if (![_appMode isCustomProfile] || ([_appMode isCustomProfile] && [self getBackupFileForCustomMode:_appMode.stringKey]))
    {
        [settingsActions addObject:@{
            @"type" : [OARightIconTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"reset_to_default"),
            @"img" : @"ic_custom_reset",
            @"key" : @"reset_to_default"
        }];
    }
    
    if ([_appMode isCustomProfile])
    {
        [settingsActions addObject:@{
           @"type" : [OARightIconTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"profile_alert_delete_title"),
            @"img" : @"ic_custom_remove_outlined",
            @"key" : @"delete_profile"
        }];
    }
    [data addObject:settingsActions];
    [sectionHeaderTitles addObject:OALocalizedString(@"shared_string_actions")];
    [sectionFooterTitles addObject:OALocalizedString(@"export_profile_descr")];

    _data = data;
    _sectionHeaderTitles = sectionHeaderTitles;
    _sectionFooterTitles = sectionFooterTitles;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSString *title = _sectionHeaderTitles[section];
    return title.length > 0 ? title : nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    NSString *title = _sectionFooterTitles[section];
    return title.length > 0 ? title : nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
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
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [OAApplicationMode.values containsObject:_appMode];
            [cell.switchView addTarget:self action:@selector(onModeSwitchPressed:) forControlEvents:UIControlEventValueChanged];

            cell.titleLabel.text = [OAApplicationMode.values containsObject:_appMode] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell;
        cell = (OASimpleTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell.leftIconView setTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
        }
        if (cell)
        {
            [cell.titleLabel setText:item[@"title"]];
            [cell.leftIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = (OARightIconTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
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
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[FreeBackupBannerCell getCellIdentifier]])
    {
        FreeBackupBannerCell *cell = (FreeBackupBannerCell *)[self.tableView dequeueReusableCellWithIdentifier:[FreeBackupBannerCell getCellIdentifier]];
        if (!_freeBackupBanner) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FreeBackupBanner" owner:self options:nil];
            _freeBackupBanner = (FreeBackupBanner *)nib[0];
            __weak OAConfigureProfileViewController *weakSelf = self;
            _freeBackupBanner.didOsmAndCloudButtonAction = ^{
                [weakSelf.navigationController pushViewController:[OACloudIntroductionViewController new] animated:YES];
            };
            _freeBackupBanner.didCloseButtonAction = ^{
                [weakSelf closeFreeBackupBanner];
            };
            [_freeBackupBanner configureWithBannerType:BannerTypeSettings];
            
            _freeBackupBanner.translatesAutoresizingMaskIntoConstraints = NO;
            [cell.contentView addSubview:_freeBackupBanner];
            [NSLayoutConstraint activateConstraints:@[
                [_freeBackupBanner.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
                [_freeBackupBanner.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
                [_freeBackupBanner.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
                [_freeBackupBanner.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
            ]];
        }
        return cell;
        
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[FreeBackupBannerCell getCellIdentifier]])
    {
        CGFloat titleHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.titleLabel.text width:tableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
                
        CGFloat descriptionHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.descriptionLabel.text width:tableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
        return _freeBackupBanner.defaultFrameHeight + titleHeight + descriptionHeight;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

- (BOOL)isAvailablePaymentBanner
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kWasClosedFreeBackupSettingsBannerKey]
    && ![OAIAPHelper isOsmAndProAvailable]
    && !OABackupHelper.sharedInstance.isRegistered;
}

- (void)closeFreeBackupBanner
{
    _freeBackupBanner = nil;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWasClosedFreeBackupSettingsBannerKey];
    [self generateData];
    [self.tableView reloadData];
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    if (section == 0 && _appMode != OAApplicationMode.DEFAULT)
    {
        OATableViewCustomHeaderView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        vw.label.text = nil;
        vw.label.attributedText = nil;

        NSString *title = _sectionHeaderTitles[section];
        [vw setYOffset:6.];
        UIFont *labelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        vw.label.attributedText = [[NSAttributedString alloc] initWithString:title attributes:@{NSParagraphStyleAttributeName : style, NSFontAttributeName : labelFont, NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary]}];
        [vw sizeToFit];
        return vw;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    [self openTargetSettingsScreen:key];
}

#pragma mark - Selectors

- (void)openDashboardScreen:(EOADashboardScreenType)type
{
    if (type == EOADashboardScreenTypeMap)
        [OARootViewController.instance.mapPanel mapSettingsButtonClick:nil mode:_appMode];
    else if (type == EOADashboardScreenTypeScreen)
        [OARootViewController.instance.mapPanel showConfigureScreen:_appMode];
}

- (void) onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self openDashboardScreen:_screenToOpen];
        _screenToOpen = EOADashboardScreenTypeNone;
    });
}

- (void) onModeSwitchPressed:(UISwitch *)sender
{
    [OAApplicationMode changeProfileAvailability:_appMode isSelected:sender.isOn];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void) setCurrentModeActive:(EOADashboardScreenType)type
{
    [OAAppSettings.sharedManager setApplicationModePref:_appMode];
    if (![OAApplicationMode.values containsObject:_appMode])
    {
        _screenToOpen = type;
        [OAApplicationMode changeProfileAvailability:_appMode isSelected:YES];
    }
    else
    {
        [self openDashboardScreen:type];
    }
}

- (void) addUnderlay
{
    _cpyProfileViewUnderlay = [[UIView alloc] initWithFrame:CGRectMake(0., 0., self.view.frame.size.width, self.view.frame.size.height)];
    [_cpyProfileViewUnderlay setBackgroundColor:[UIColor colorNamed:ACColorNameViewBg]];
    [_cpyProfileViewUnderlay setAlpha:0.2];
    
    UITapGestureRecognizer *underlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUnderlayTapped)];
    [_cpyProfileViewUnderlay addGestureRecognizer:underlayTap];
    [self.view addSubview:_cpyProfileViewUnderlay];
}


- (void) onUnderlayTapped
{
    
}

- (void)openTargetSettingsScreen:(NSString *)targetScreenKey
{
    if ([targetScreenKey isEqualToString:@"configure_map"])
    {
        [self setCurrentModeActive:EOADashboardScreenTypeMap];
        [self.navigationController popToViewController:OARootViewController.instance animated:NO];
    }
    else if ([targetScreenKey isEqualToString:@"configure_screen"])
    {
        [self setCurrentModeActive:EOADashboardScreenTypeScreen];
    }
    else if ([targetScreenKey isEqualToString:@"copy_profile"])
    {
        OACopyProfileBottomSheetViewControler *bottomSheet = [[OACopyProfileBottomSheetViewControler alloc] initWithMode:_appMode];
        bottomSheet.delegate = self;
        [bottomSheet presentInViewController:self];
    }
    else if ([targetScreenKey isEqualToString:@"reset_to_default"])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"reset_to_default")
                                                                       message:OALocalizedString                  (@"reset_profile_action_descr")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil
        ];
        UIAlertAction *resetAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_reset")
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
            [self resetAppModePrefs:_appMode];
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:resetAction];
        alert.preferredAction = resetAction;
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([targetScreenKey isEqualToString:@"delete_profile"])
    {
        OADeleteProfileBottomSheetViewController *bottomSheet = [[OADeleteProfileBottomSheetViewController alloc] initWithMode:_appMode];
        bottomSheet.delegate = self;
        [self addUnderlay];
        [bottomSheet show];
    }
    else
    {
        UIViewController *settingsScreen = nil;
        if ([targetScreenKey isEqualToString:kGeneralSettings])
            settingsScreen = [[OAProfileGeneralSettingsViewController alloc] initWithAppMode:_appMode];
        else if ([targetScreenKey isEqualToString:kNavigationSettings])
            settingsScreen = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:_appMode];
        else if ([targetScreenKey isEqualToString:kProfileAppearanceSettings])
            settingsScreen = [[OAProfileAppearanceViewController alloc] initWithProfile:_appMode];
        else if ([targetScreenKey isEqualToString:kExportProfileSettings])
            settingsScreen = [[OAExportItemsViewController alloc] initWithAppMode:_appMode hostVC:self];
        else if ([targetScreenKey isEqualToString:kTrackRecordingSettings])
            settingsScreen = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenGeneral applicationMode:_appMode];
        else if ([targetScreenKey isEqualToString:kOsmEditsSettings])
            settingsScreen = [[OAOsmEditingSettingsViewController alloc] init];
        else if ([targetScreenKey isEqualToString:kWeatherSettings])
            settingsScreen = [[OAWeatherSettingsViewController alloc] init];
        else if ([targetScreenKey isEqualToString:kOsmandDevelopmentSettings])
            settingsScreen = [[OAOsmandDevelopmentViewController alloc] init];
        else if ([targetScreenKey isEqualToString:kWikipediaSettings])
            settingsScreen = [[OAWikipediaSettingsViewController alloc] initWithAppMode:_appMode];
        else if ([targetScreenKey isEqualToString:kExternalSensors])
            settingsScreen = [[UIStoryboard storyboardWithName:@"BLEExternalSensors" bundle:nil] instantiateViewControllerWithIdentifier:@"BLEExternalSensors"];
        if (settingsScreen)
            [self.navigationController pushViewController:settingsScreen animated:YES];
    }
}

#pragma mark - OACopyProfileBottomSheetDelegate

- (void) onCopyProfileCompleted
{
    [self updateView];
}

- (void) onCopyProfileDismissed
{
    [_cpyProfileViewUnderlay removeFromSuperview];
}

#pragma mark - OADeleteProfileBottomSheetDelegate

- (void) onDeleteProfileDismissed
{
    [_cpyProfileViewUnderlay removeFromSuperview];
}

- (void) resetAppModePrefs:(OAApplicationMode *)appMode
{
    if (appMode)
    {
        [OAAppSettings.sharedManager.settingPrefMapLanguage resetToDefault];
        [OAAppSettings.sharedManager resetPreferencesForProfile:appMode];
        if (appMode.isCustomProfile)
        {
            NSString *fileName = [self getBackupFileForCustomMode:appMode.stringKey];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
                [self restoreCustomModeFromFile:fileName];
        }
        else
        {
            [self updateCopiedOrResetPrefs];
        }
        [self resetMapStylesForProfile:appMode];
    }
}

- (void) restoreCustomModeFromFile:(NSString *)filePath
{
    _importedFileName = filePath;
    [OASettingsHelper.sharedInstance collectSettings:filePath latestChanges:@"" version:kVersion delegate:self onComplete:nil silent:YES];
}

- (void) resetMapStylesForProfile:(OAApplicationMode *)appMode
{
    NSString *renderer = [OAAppSettings.sharedManager.renderer get:appMode];
    NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:renderer];
	OAMapSource *source = [[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
													 andVariant:appMode.variantKey
														   name:mapStyleInfo[@"title"]];
	[[OsmAndApp instance].data setLastMapSource:source mode:appMode];

	OAMapStyleSettings *styleSettings = [[OAMapStyleSettings alloc] initWithStyleName:mapStyleInfo[@"id"]
																		mapPresetName:appMode.variantKey];
	[styleSettings resetMapStyleForAppMode:appMode.variantKey onComplete:^{
        [self showAlertMessage:OALocalizedString(@"profile_prefs_reset_successful")];
    }];
}

- (void) importBackupSettingsItems:(nonnull NSString *)file items:(nonnull NSArray<OASettingsItem *> *)items
{
    [OASettingsHelper.sharedInstance importSettings:file items:items latestChanges:@"" version:kVersion delegate:self];
}

- (void) updateCopiedOrResetPrefs
{
    [[OAPOIFiltersHelper sharedInstance] loadSelectedPoiFilters];
    [[OARootViewController instance].mapPanel recreateAllControls];
    [OAMapStyleSettings.sharedInstance loadParameters];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    [[[OsmAndApp instance].data applicationModeChangedObservable] notifyEventWithKey:nil];
    [self updateView];
}

- (void) updateView
{
    [self updateNavbar];
    [self applyLocalization];
    [self setupTableHeaderView];
    [self generateData];
    [self.tableView reloadData];
}

- (NSString *) getBackupFileForCustomMode:(NSString *)appModeKey
{
    NSString *fileName = [appModeKey stringByAppendingPathExtension:OSMAND_SETTINGS_FILE_EXT];
    NSString *backupDir = [[OsmAndApp instance].documentsPath stringByAppendingPathComponent:BACKUP_INDEX_DIR];
    [self createDirectoryIfNotExist:backupDir];
    return [backupDir stringByAppendingPathComponent:fileName];
}

- (void) createDirectoryIfNotExist:(NSString *)path
{
    [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void) showAlertMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(nonnull NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        OASettingsItem *itm = nil;
        for (OASettingsItem *item in items)
        {
            if ([item isKindOfClass:OAProfileSettingsItem.class])
            {
                OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *)item;
                if ([profileItem.appMode.stringKey isEqualToString:_appMode.stringKey])
                {
                    itm = item;
                    itm.shouldReplace = YES;
                    break;
                }
            }
        }
        if (itm)
        {
            [self importBackupSettingsItems:_importedFileName items:@[itm]];
        }
    }
}

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    [self updateCopiedOrResetPrefs];
}

@end
