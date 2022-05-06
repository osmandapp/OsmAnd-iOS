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
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAIconTextDescCell.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAPlugin.h"
#import "OAMonitoringPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAPluginResetBottomSheetViewController.h"
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
#import "OASettingsItem.h"
#import "OARendererRegistry.h"
#import "OAExportItemsViewController.h"
#import "OAIndexConstants.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherSettingsViewController.h"

#define kSidePadding 16.
#define BACKUP_INDEX_DIR @"backup"
#define OSMAND_SETTINGS_FILE_EXT @"osf"

typedef NS_ENUM(NSInteger, EOADashboardScreenType) {
    EOADashboardScreenTypeNone = 0,
    EOADashboardScreenTypeMap,
    EOADashboardScreenTypeScreen
};

@interface OAConfigureProfileViewController () <UITableViewDelegate, UITableViewDataSource, OACopyProfileBottomSheetDelegate, OADeleteProfileBottomSheetDelegate, OAPluginResetBottomSheetDelegate, OASettingsImportExportDelegate>

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
}

- (instancetype) initWithAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey
{
    self = [super init];
    if (self) {
        _appMode = mode;
        _targetScreenKey = targetScreenKey;
//        [self generateData];
    }
    return self;
}

- (void) generateData
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

    NSMutableArray<NSDictionary *> *profileSettings = [NSMutableArray new];
    [profileSettings addObject:@{
        @"type" : [OAIconTextDescCell getCellIdentifier],
        @"title" : OALocalizedString(@"general_settings_2"),
        @"descr" : OALocalizedString(@"general_settings_descr"),
        @"img" : @"left_menu_icon_settings",
        @"key" : @"general_settings"
    }];
    if (_appMode != OAApplicationMode.DEFAULT)
    {
        [profileSettings addObject:@{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : OALocalizedString(@"routing_settings_2"),
            @"descr" : OALocalizedString(@"routing_settings_descr"),
            @"img" : @"left_menu_icon_navigation",
            @"key" : kNavigationSettings
        }];
    }
    [profileSettings addObject:@{
        @"type" : [OAIconTextDescCell getCellIdentifier],
        @"title" : OALocalizedString(@"configure_map"),
        @"descr" : OALocalizedString(@"configure_map_descr"),
        @"img" : @"left_menu_icon_map",
        @"key" : @"configure_map"
    }];
    [profileSettings addObject:@{
        @"type" : [OAIconTextDescCell getCellIdentifier],
        @"title" : OALocalizedString(@"layer_map_appearance"),
        @"descr" : OALocalizedString(@"configure_screen_descr"),
        @"img" : @"left_menu_configure_screen",
        @"key" : @"configure_screen"
    }];
    [profileSettings addObject:@{
        @"type" : [OAIconTextDescCell getCellIdentifier],
        @"title" : OALocalizedString(@"profile_appearance"),
        @"descr" : OALocalizedString(@"profile_appearance_descr"),
        @"img" : _appMode.getIconName,
        @"key" : @"profile_appearance"
    }];
    
        // TODO: add ui customization
//        @{
//            @"type" : [OAIconTextDescCell getCellIdentifier],
//            @"title" : OALocalizedString(@"ui_customization"),
//            @"descr" : OALocalizedString(@"ui_customization_descr"),
//            @"img" : todo,
//            @"key" : @"ui_customization"
//        }
    [data addObject:profileSettings];
    [sectionHeaderTitles addObject:OALocalizedString(@"profile_settings")];
    [sectionFooterTitles addObject:OALocalizedString(@"profile_sett_descr")];

    // Plugins
    NSMutableArray *plugins = [NSMutableArray new];
    OAPlugin *tripRec = [OAPlugin getEnabledPlugin:OAMonitoringPlugin.class];
    if (tripRec)
    {
        [plugins addObject:@{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : tripRec.getName,
            @"img" : @"ic_custom_trip",
            @"key" : kTrackRecordingSettings
        }];
    }
    
    OAPlugin *osmEdit = [OAPlugin getEnabledPlugin:OAOsmEditingPlugin.class];
    if (osmEdit)
    {
        [plugins addObject:@{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : osmEdit.getName,
            @"img" : @"ic_custom_osm_edits",
            @"key" : kOsmEditsSettings
        }];
    }
    OAPlugin *weather = [OAPlugin getEnabledPlugin:OAWeatherPlugin.class];
    if (weather)
    {
        [plugins addObject:@{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : weather.getName,
            @"img" : @"ic_custom_umbrella",
            @"key" : kWeatherSettings
        }];
    }
    
    if (plugins.count > 0)
    {
        [data addObject:plugins];
        [sectionHeaderTitles addObject:OALocalizedString(@"plugins")];
        [sectionFooterTitles addObject:OALocalizedString(@"plugin_settings_descr")];
    }
    
    // Actions
    NSMutableArray<NSDictionary *> *settingsActions = [NSMutableArray new];
    [settingsActions addObject:@{
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"title" : OALocalizedString(@"export_profile"),
        @"img" : @"ic_custom_export",
        @"key" : @"export_profile"
    }];
    [settingsActions addObject:@{
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"title" : OALocalizedString(@"copy_from_other_profile"),
        @"img" : @"ic_custom_copy",
        @"key" : @"copy_profile"
    }];
    
    if (![_appMode isCustomProfile] || ([_appMode isCustomProfile] && [self getBackupFileForCustomMode:_appMode.stringKey]))
    {
        [settingsActions addObject:@{
            @"type" : [OATitleRightIconCell getCellIdentifier],
            @"title" : OALocalizedString(@"reset_to_default"),
            @"img" : @"ic_custom_reset",
            @"key" : @"reset_to_default"
        }];
    }
    
    if ([_appMode isCustomProfile])
    {
        [settingsActions addObject:@{
           @"type" : [OATitleRightIconCell getCellIdentifier],
            @"title" : OALocalizedString(@"profile_alert_delete_title"),
            @"img" : @"ic_custom_remove_outlined",
            @"key" : @"delete_profile"
        }];
    }
    [data addObject:settingsActions];
    [sectionHeaderTitles addObject:OALocalizedString(@"actions")];
    [sectionFooterTitles addObject:OALocalizedString(@"export_profile_descr")];

    _data = data;
    _sectionHeaderTitles = sectionHeaderTitles;
    _sectionFooterTitles = sectionFooterTitles;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [self setupTableHeaderView];
    [self generateData];
    [self applyLocalization];
    [self.tableView reloadData];
    
    if (_targetScreenKey)
    {
        [self openTargetSettingsScreen:_targetScreenKey];
        _targetScreenKey = nil;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) applyLocalization
{
    self.titleLabel.text = _appMode.toHumanString;
}

- (UIView *) setupTableHeaderView
{
    return self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getTableHeaderTitle font:[UIFont systemFontOfSize:34.0 weight:UIFontWeightBold] tintColor:UIColorFromRGB(_appMode.getIconColor) icon:_appMode.getIconName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appModeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
        
    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

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

- (void) dealloc
{
    [_appModeChangeObserver detach];
}

- (NSString *)getTableHeaderTitle
{
    return _appMode.toHumanString;
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
    [_cpyProfileViewUnderlay setBackgroundColor:UIColor.blackColor];
    [_cpyProfileViewUnderlay setAlpha:0.2];
    
    UITapGestureRecognizer *underlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUnderlayTapped)];
    [_cpyProfileViewUnderlay addGestureRecognizer:underlayTap];
    [self.view addSubview:_cpyProfileViewUnderlay];
}


- (void) onUnderlayTapped
{
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderView];
        [self.tableView reloadData];
    } completion:nil];
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
        [self.navigationController popToViewController:OARootViewController.instance animated:NO];
    }
//    else if ([key isEqualToString:@"ui_customization"])
//    {
//
//    }
    else if ([targetScreenKey isEqualToString:@"copy_profile"])
    {
        OACopyProfileBottomSheetViewControler *bottomSheet = [[OACopyProfileBottomSheetViewControler alloc] initWithMode:_appMode];
        bottomSheet.delegate = self;
        [bottomSheet presentInViewController:self];
    }
    else if ([targetScreenKey isEqualToString:@"reset_to_default"])
    {
        OAPluginResetBottomSheetViewController *screen = [[OAPluginResetBottomSheetViewController alloc] initWithParam:_appMode];
        screen.delegate = self;
        [screen show];
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
            settingsScreen = [[OAExportItemsViewController alloc] initWithAppMode:_appMode];
        else if ([targetScreenKey isEqualToString:kTrackRecordingSettings])
            settingsScreen = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenGeneral applicationMode:_appMode];
        else if ([targetScreenKey isEqualToString:kOsmEditsSettings])
            settingsScreen = [[OAOsmEditingSettingsViewController alloc] init];
        else if ([targetScreenKey isEqualToString:kWeatherSettings])
            settingsScreen = [[OAWeatherSettingsViewController alloc] init];

        if (settingsScreen)
            [self.navigationController pushViewController:settingsScreen animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.text = nil;
    vw.label.attributedText = nil;
    
    NSString *title = _sectionHeaderTitles[section];
    
    if (section == 0 && _appMode != OAApplicationMode.DEFAULT)
    {
        [vw setYOffset:6.];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        vw.label.attributedText = [[NSAttributedString alloc] initWithString:title attributes:@{NSParagraphStyleAttributeName : style, NSFontAttributeName : labelFont, NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
    }
    else
    {
        [vw setYOffset:17.];
        vw.label.text = [title upperCase];
        vw.label.textColor = UIColorFromRGB(color_text_footer);
    }
    [vw sizeToFit];
    return vw;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleRightIconCell getCellIdentifier]])
        return 45.;
    else
        return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    if (section == 0 && _appMode != OAApplicationMode.DEFAULT)
        return [OATableViewCustomHeaderView getHeight:_sectionHeaderTitles[section] width:textWidth yOffset:6. font:[UIFont systemFontOfSize:15.0]] + 10.;
    
    return [OATableViewCustomHeaderView getHeight:_sectionHeaderTitles[section] width:textWidth];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == 0 && _appMode != OAApplicationMode.DEFAULT ? 0.01 : [OAUtilities calculateTextBounds:_sectionFooterTitles[section] width:DeviceScreenWidth - (16 + OAUtilities.getLeftMargin) * 2 font:[UIFont systemFontOfSize:13.]].height + 16.;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = _sectionFooterTitles[section];
    return title.length > 0 ? title : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [OAApplicationMode.values containsObject:_appMode];
            [cell.switchView addTarget:self action:@selector(onModeSwitchPressed:) forControlEvents:UIControlEventValueChanged];
            cell.textView.text = [OAApplicationMode.values containsObject:_appMode] ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDescCell getCellIdentifier]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
            cell.arrowIconView.image = [cell.arrowIconView.image imageFlippedForRightToLeftLayoutDirection];
            [cell.iconView setTintColor:UIColorFromRGB(color_icon_inactive)];
            cell.descView.font = [UIFont systemFontOfSize:15.];
            cell.separatorInset = UIEdgeInsetsMake(0., 64., 0., 0.);
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            cell.descView.hidden = YES;
                
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell *cell = (OATitleRightIconCell *)[tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    [self openTargetSettingsScreen:key];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OACopyProfileBottomSheetDelegate

- (void) onCopyProfileCompleted
{
    [self setupTableHeaderView];
    [self generateData];
    [self applyLocalization];
    [self.tableView reloadData];
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

#pragma mark - OAPluginResetBottomSheetDelegate

- (void) onPluginSettingsReset
{
    [self resetAppModePrefs:_appMode];
}

- (void) resetAppModePrefs:(OAApplicationMode *)appMode
{
    if (appMode)
    {
        if (appMode.isCustomProfile)
        {
            [OAAppSettings.sharedManager resetPreferencesForProfile:appMode];
            NSString *fileName = [self getBackupFileForCustomMode:appMode.stringKey];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
                [self restoreCustomModeFromFile:fileName];
        }
        else
        {
            [OAAppSettings.sharedManager resetPreferencesForProfile:appMode];
            [self showAlertMessage:OALocalizedString(OALocalizedString(@"profile_prefs_reset_successful"))];
            [self updateCopiedOrResetPrefs];
        }
        [self resetMapStylesForProfile:appMode];
    }
}

- (void) restoreCustomModeFromFile:(NSString *)filePath
{
    _importedFileName = filePath;
    [OASettingsHelper.sharedInstance collectSettings:filePath latestChanges:@"" version:1 delegate:self];
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
	[styleSettings resetMapStyleForAppMode:appMode.variantKey];
}


- (void) importBackupSettingsItems:(nonnull NSString *)file items:(nonnull NSArray<OASettingsItem *> *)items
{
    [OASettingsHelper.sharedInstance importSettings:file items:items latestChanges:@"" version:1 delegate:self];
}

- (void) updateCopiedOrResetPrefs
{
    [[OAPOIFiltersHelper sharedInstance] loadSelectedPoiFilters];
    [[OARootViewController instance].mapPanel.mapWidgetRegistry updateVisibleWidgets];
    [OAMapStyleSettings.sharedInstance loadParameters];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    [[[OsmAndApp instance].data applicationModeChangedObservable] notifyEventWithKey:nil];
    [self updateView];
}

- (void) updateView
{
    self.titleLabel.text = _appMode.toHumanString;
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
    [self showAlertMessage:OALocalizedString(OALocalizedString(@"profile_prefs_reset_successful"))];
    [self updateCopiedOrResetPrefs];
}

@end
