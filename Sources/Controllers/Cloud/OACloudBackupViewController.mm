//
//  OACloudBackupViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudBackupViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAFilledButtonCell.h"
#import "OATwoFilledButtonsTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OAIAPHelper.h"
#import "OABackupHelper.h"
#import "OAStatusBackupConflictDetailsViewController.h"
#import "OAButtonTableViewCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OAMainSettingsViewController.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OABackupStatus.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAOsmAndFormatter.h"
#import "OABackupError.h"
#import "OASyncBackupTask.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OASettingsItem.h"
#import "OABackupDbHelper.h"
#import "OAFileSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OASettingsBackupViewController.h"
#import "OAStatusBackupViewController.h"
#import "OAExportSettingsType.h"
#import "OABaseBackupTypesViewController.h"
#import "OAExportBackupTask.h"
#import "OAAppVersion.h"
#import "OATableDataModel.h"
#import "OATableRowData.h"
#import "OATableCollapsableRowData.h"
#import "OATableSectionData.h"
#import "OsmAndApp.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource, OAOnPrepareBackupListener, OAOnDeleteAccountListener, OABackupTypesDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tblView;

@end

@implementation OACloudBackupViewController
{
    OATableDataModel *_data;
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
    
    EOACloudScreenSourceType _sourceType;
    OAPrepareBackupResult *_backup;
    OABackupInfo *_info;
    OABackupStatus *_status;
    NSString *_error;
    
    OATitleIconProgressbarCell *_backupProgressCell;
    NSInteger _itemsSection;
    
    UIBarButtonItem *_settingsButton;
}

- (instancetype) initWithSourceType:(EOACloudScreenSourceType)type
{
    self = [self init];
    if (self) {
        _sourceType = type;
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OACloudBackupViewController" bundle:nil];
    if (self) {
        _sourceType = EOACloudScreenSourceTypeDirect;
    }
    return self;
}

- (void)setupNotificationListeners
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupFinished:) name:kBackupSyncFinishedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupStarted) name:kBackupSyncStartedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressUpdate:) name:kBackupProgressUpdateNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = OALocalizedString(@"osmand_cloud");
    [self setupNotificationListeners];
    [OAIAPHelper.sharedInstance checkBackupPurchase];
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    _backupHelper = OABackupHelper.sharedInstance;
    self.tblView.refreshControl = [[UIRefreshControl alloc] init];
    [_backupHelper addPrepareBackupListener:self];
    [self.tblView.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
        [_backupHelper prepareBackup];
    [self generateData];
    self.tblView.delegate = self;
    self.tblView.dataSource = self;
    self.tblView.estimatedRowHeight = 44.;
    self.tblView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_backupHelper.backupListeners addDeleteAccountListener:self];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    OACloudBackupViewController *navigationController = (OACloudBackupViewController *)self.navigationController.topViewController;
    _settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onSettingsButtonPressed)];
    [navigationController.navigationItem setRightBarButtonItem:_settingsButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_backupHelper.backupListeners removeDeleteAccountListener:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_backupHelper removePrepareBackupListener:self];
}

-(void) addAccessibilityLabels
{
    _settingsButton.accessibilityLabel = OALocalizedString(@"shared_string_settings");
}

- (void) onRefresh
{
    if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
    {
        [_backupHelper addPrepareBackupListener:self];
        [_backupHelper prepareBackup];
    }
    else
    {
        [self.tblView.refreshControl endRefreshing];
    }
}

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    
    if (!_status)
        _status = [OABackupStatus getBackupStatus:_backup];
    
    BOOL backupSaved = _backup.remoteFiles.count != 0;
    BOOL showIntroductionItem = _info != nil && ((_sourceType == EOACloudScreenSourceTypeSignUp && !backupSaved)
                    || (_sourceType == EOACloudScreenSourceTypeSignIn && (backupSaved || _backup.localFiles.count > 0)));
    
    if (showIntroductionItem)
    {
        if (_sourceType == EOACloudScreenSourceTypeSignIn)
        {
            // Existing backup case
            OATableSectionData *existingBackupSection = [OATableSectionData sectionData];
            [existingBackupSection addRowFromDictionary:@{
                kCellTypeKey: OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                kCellKeyKey: @"existingOnlineBackup",
                kCellTitleKey: OALocalizedString(@"backup_welcome_back"),
                kCellDescrKey: OALocalizedString(@"osmand_cloud_authorize_descr"),
                kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
            }];
           
            if ([self shouldShowSyncButton])
            {
                [existingBackupSection addRowFromDictionary:@{
                    kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
                    kCellKeyKey: @"onSetUpBackupButtonPressed",
                    kCellTitleKey: OALocalizedString(@"sync_now")
                }];
            }
            existingBackupSection.headerText = OALocalizedString(@"shared_string_status");
            [_data addSection:existingBackupSection];
        }
        else if (_sourceType == EOACloudScreenSourceTypeSignUp)
        {
            // No backup case
            OATableSectionData *noBackupRows = [OATableSectionData sectionData];
            [noBackupRows addRowFromDictionary:@{
                kCellTypeKey: OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                kCellKeyKey: @"noOnlineBackup",
                kCellTitleKey: OALocalizedString(@"cloud_no_online_backup"),
                kCellDescrKey: OALocalizedString(@"cloud_no_online_backup_descr"),
                kCellIconNameKey: @"ic_custom_cloud_neutral_face_colored"
            }];
            
            if ([self shouldShowSyncButton])
            {
                [noBackupRows addRowFromDictionary:@{
                    kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
                    kCellKeyKey: @"onSetUpBackupButtonPressed",
                    kCellTitleKey: OALocalizedString(@"set_up_backup")
                }];
            }
            noBackupRows.headerText = OALocalizedString(@"shared_string_status");
            [_data addSection:noBackupRows];
        }
    }
    else
    {
        OATableSectionData *backupRows = [OATableSectionData sectionData];
        backupRows.headerText = OALocalizedString(@"shared_string_status");
        [_data addSection:backupRows];

        if (_settingsHelper.isBackupSyncing)
        {
            _backupProgressCell = [self getProgressBarCell];
            NSDictionary *backupProgressCell = @{
                kCellTypeKey: OATitleIconProgressbarCell.getCellIdentifier,
                kCellKeyKey: @"backup_progress",
                @"cell": _backupProgressCell
            };
            [backupRows addRowFromDictionary:backupProgressCell];
        }
        else
        {
            NSString *backupStatusDescr = _backup == nil ? OALocalizedString(@"checking_progress")
                : [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
            OATableCollapsableRowData *collapsableRow = [[OATableCollapsableRowData alloc] initWithData:@{
                kCellTypeKey: OAButtonTableViewCell.getCellIdentifier,
                kCellKeyKey: @"lastBackup",
                kCellTitleKey: _status.statusTitle,
                kCellDescrKey: backupStatusDescr,
                kCellIconNameKey: _status.statusIconName,
                kCellIconTint: @(_status.iconColor)
            }];
            OATableRowData *localChangesRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
                kCellKeyKey: @"local_changes",
                kCellTitleKey: OALocalizedString(@"local_changes"),
                kCellIconNameKey: @"ic_custom_device",
                @"value": @(_backup.backupInfo.filteredFilesToUpload.count + _backup.backupInfo.filteredFilesToDelete.count)
            }];
            [collapsableRow addDependentRow:localChangesRow];
            OATableRowData *updatesRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
                kCellKeyKey: @"remote_updates",
                kCellTitleKey: OALocalizedString(@"download_tab_updates"),
                kCellIconNameKey: @"ic_custom_cloud",
                @"value": @([BackupUtils getItemsMapForRestore:_info settingsItems:_backup.settingsItems].count)
            }];
            [collapsableRow addDependentRow:updatesRow];
            OATableRowData *conflictsRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
                kCellKeyKey: @"conflicts",
                kCellTitleKey: OALocalizedString(@"cloud_conflicts"),
                kCellIconNameKey: @"ic_custom_alert",
                @"value": @(_backup.backupInfo.filteredFilesToMerge.count)
            }];
            [collapsableRow addDependentRow:conflictsRow];
            [backupRows addRow:collapsableRow];

            if (_status.warningTitle != nil || _error.length > 0)
            {
                BOOL hasWarningStatus = _status.warningTitle != nil;
                BOOL hasDescr = _error || _status.warningDescription;
                NSString *descr = hasDescr && hasWarningStatus ? _status.warningDescription : [_error stringByAppendingFormat:@"\n%@", OALocalizedString(@"error_contact_support")];
                NSInteger color = _status == OABackupStatus.CONFLICTS || _status == OABackupStatus.ERROR ? _status.iconColor
                : _status == OABackupStatus.MAKE_BACKUP ? profile_icon_color_green_light : -1;
                NSDictionary *makeBackupWarningCell = @{
                    kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                    kCellKeyKey: @"makeBackupWarning",
                    kCellTitleKey: hasWarningStatus ? _status.warningTitle : OALocalizedString(@"osm_failed_uploads"),
                    kCellDescrKey: descr ? descr : @"",
                    kCellIconTint: @(color),
                    kCellIconNameKey: _status.warningIconName
                };
                [backupRows addRowFromDictionary:makeBackupWarningCell];
            }
        }

        if (_backup == nil && !_settingsHelper.isBackupSyncing)
        {
            NSDictionary *checkingCell = @{
                kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
                kCellKeyKey: @"checkingBackup",
                kCellTitleKey: OALocalizedString(@"checking_progress"),
                @"titleTint": [UIColor colorNamed:ACColorNameTextColorActive]
            };
            [backupRows addRowFromDictionary:checkingCell];
        }
        else if (_settingsHelper.isBackupSyncing)
        {
            NSDictionary *cancellCell = @{
                kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                kCellKeyKey: @"cancellBackupPressed",
                kCellTitleKey: OALocalizedString(@"shared_string_cancel"),
                kCellIconNameKey: @"ic_custom_cancel"
            };
            [backupRows addRowFromDictionary:cancellCell];
        }
        else if (_status == OABackupStatus.MAKE_BACKUP || _status == OABackupStatus.CONFLICTS || _status == OABackupStatus.BACKUP_COMPLETE)
        {
            NSDictionary *backupNowCell = @{
                kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                kCellKeyKey: @"onSetUpBackupButtonPressed",
                kCellTitleKey: OALocalizedString(@"sync_now"),
                kCellIconNameKey: @"ic_custom_update"
            };
            [backupRows addRowFromDictionary:backupNowCell];
        }
        else if (_status == OABackupStatus.NO_INTERNET_CONNECTION)
        {
            NSDictionary *retryCell = @{
                kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                kCellKeyKey: @"onRetryPressed",
                kCellTitleKey: _status.actionTitle,
                kCellIconNameKey: @"ic_custom_reset"
            };
            [backupRows addRowFromDictionary:retryCell];
        }
        else if (_status == OABackupStatus.ERROR)
        {
            NSDictionary *retryCell = @{
                kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                kCellKeyKey: @"onSupportPressed",
                kCellTitleKey: _status.actionTitle,
                kCellIconNameKey: @"ic_custom_letter_outlined"
            };
            [backupRows addRowFromDictionary:retryCell];
        }
        else if (_status == OABackupStatus.SUBSCRIPTION_EXPIRED)
        {
            NSDictionary *purchaseCell = @{
                kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
                kCellKeyKey: @"onSubscriptionExpired",
                kCellTitleKey: _status.actionTitle,
                kCellIconNameKey: @"ic_custom_cloud_upload"
            };
            [backupRows addRowFromDictionary:purchaseCell];
        }

        OATableSectionData *storageRows = [OATableSectionData sectionData];
        storageRows.headerText = OALocalizedString(@"help_article_personal_storage_name");
        [_data addSection:storageRows];

        NSDictionary *purchaseCell = @{
            kCellTypeKey: [OAButtonTableViewCell getCellIdentifier],
            kCellKeyKey: @"onTrashPressed",
            kCellTitleKey: OALocalizedString(@"shared_string_trash"),
            kCellIconNameKey: @"ic_custom_remove",
            kCellIconTintColor: [UIColor colorNamed:ACColorNameIconColorSecondary]
        };
        [storageRows addRowFromDictionary:purchaseCell];
    }
}

- (OATitleIconProgressbarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
    OATitleIconProgressbarCell *resultCell = (OATitleIconProgressbarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    resultCell.textView.text = [OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]];
    resultCell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    resultCell.imgView.image = [UIImage templateImageNamed:@"ic_custom_cloud_upload"];
    resultCell.imgView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    resultCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return resultCell;
}

- (BOOL) shouldShowSyncButton
{
    return _info.filteredFilesToDelete.count > 0 || _info.filteredFilesToDownload.count > 0 || _info.filteredFilesToUpload.count > 0;
}

- (BOOL)isActionButtonDisabled:(OATableRowData *)item
{
    BOOL isSyncButton = [item.key isEqualToString:@"onSetUpBackupButtonPressed"];
    BOOL actionButtonDisabled = isSyncButton;
    if (isSyncButton)
    {
        BOOL hasInfo = _info != nil;
        BOOL noChanges = _status == OABackupStatus.MAKE_BACKUP && (!hasInfo || (_info.filteredFilesToUpload.count == 0 && _info.filteredFilesToDelete.count == 0 && _info.filteredLocalFilesToDelete.count == 0 && [BackupUtils getItemsMapForRestore:_info settingsItems:_backup.settingsItems].count == 0));
        actionButtonDisabled = noChanges || _backupHelper.isBackupPreparing || _settingsHelper.isBackupSyncing;
    }
    return actionButtonDisabled;
}

- (void) refreshContent
{
    [self generateData];
    [self.tblView reloadData];
}

- (IBAction)onSettingsButtonPressed
{
    OASettingsBackupViewController *settingsBackupViewController = [[OASettingsBackupViewController alloc] init];
    settingsBackupViewController.backupTypesDelegate = self;
    [self.navigationController pushViewController:settingsBackupViewController animated:YES];
}

- (void) onCollapseButtonPressed
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    OATableCollapsableRowData *collapsableRow = (OATableCollapsableRowData *)[_data itemForIndexPath:indexPath];
    collapsableRow.collapsed = !collapsableRow.collapsed;
    NSMutableArray<NSIndexPath *> *rowIndexes = [NSMutableArray array];
    for (NSInteger i = 1; i <= collapsableRow.dependentRowsCount; i++)
        [rowIndexes addObject:[NSIndexPath indexPathForRow:(indexPath.row + i) inSection:indexPath.section]];
    
    [self.tblView performBatchUpdates:^{
        [self.tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (collapsableRow.collapsed)
            [self.tblView deleteRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
        else
            [self.tblView insertRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
    } completion:nil];
}

- (void)onSetUpBackupButtonPressed
{
    if (!_settingsHelper.isBackupSyncing)
        [_settingsHelper syncSettingsItems:kSyncItemsKey operation:EOABackupSyncOperationSync];
}

- (void)onRetryPressed
{
    if (!_backupHelper.isBackupPreparing)
        [_backupHelper prepareBackup];
}

- (void)onSupportPressed
{
    [self sendEmail];
}

- (void) cancellBackupPressed
{
    [_settingsHelper cancelSync];
}

- (void) onSubscriptionExpired
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellId = item.cellType;
    if ([cellId isEqualToString:OALargeImageTitleDescrTableViewCell.getCellIdentifier])
    {
        OALargeImageTitleDescrTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OALargeImageTitleDescrTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
            [cell showButton:NO];
        }
        cell.titleLabel.text = item.title;
        cell.descriptionLabel.text = item.descr;
        [cell.cellImageView setImage:[UIImage imageNamed:item.iconName]];

        if (cell.needsUpdateConstraints)
            [cell updateConstraints];

        return cell;
    }
    else if ([cellId isEqualToString:OAValueTableViewCell.getCellIdentifier])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OAValueTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.titleLabel.text = item.title;
        cell.valueLabel.text = [item stringForKey:@"value"];
        cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
        cell.leftIconView.tintColor = [item integerForKey:@"value"] > 0 ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        cell.separatorInset = UIEdgeInsetsMake(0., ([item.key isEqualToString:@"conflicts"] ? 0. : 65.), 0., 0.);
        return cell;
    }
    else if ([cellId isEqualToString:OAFilledButtonCell.getCellIdentifier])
    {
        OAFilledButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:OAFilledButtonCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
            cell.button.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
            [cell.button setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorPrimary] forState:UIControlStateNormal];
            cell.button.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 9.;
            cell.bottomMarginConstraint.constant = 20.;
            cell.heightConstraint.constant = 42.;
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.button setTitle:item.title forState:UIControlStateNormal];
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:NSSelectorFromString(item.key) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OATwoFilledButtonsTableViewCell.getCellIdentifier])
    {
        OATwoFilledButtonsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATwoFilledButtonsTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATwoFilledButtonsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATwoFilledButtonsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.topButton setTitle:[item objForKey:@"topTitle"] forState:UIControlStateNormal];
        [cell.topButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.topButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton setTitle:[item objForKey:@"bottomTitle"] forState:UIControlStateNormal];
        [cell.bottomButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OAButtonTableViewCell.getCellIdentifier])
    {
        OAButtonTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OAButtonTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *)[nib objectAtIndex:0];
            [cell.button setTitle:nil forState:UIControlStateNormal];
            cell.button.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            [cell descriptionVisibility:item.descr && item.descr.length > 0];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([item.key isEqualToString:@"lastBackup"])
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.button.configuration = nil;
                BOOL collapsed = item.rowType == EOATableRowTypeCollapsable && ((OATableCollapsableRowData *) item).collapsed;
                [cell.button setImage:[UIImage templateImageNamed:collapsed ? @"ic_custom_arrow_right" : @"ic_custom_arrow_down"].imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];
                [cell.button addTarget:self action:@selector(onCollapseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([item.key isEqualToString:@"onTrashPressed"])
            {
                if ([OAIAPHelper isOsmAndProAvailable])
                {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.button.configuration = nil;
                    [cell.button setImage:nil forState:UIControlStateNormal];
                }
                else
                {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                    conf.contentInsets = NSDirectionalEdgeInsetsMake(0., 0, 0, 0.);
                    cell.button.configuration = conf;
                    [cell.button setImage:[UIImage imageNamed:@"ic_payment_label_pro"] forState:UIControlStateNormal];
                    [cell.button addTarget:self action:@selector(onSubscriptionExpired) forControlEvents:UIControlEventTouchUpInside];
                }
            }

            UIColor *leftIconTintColor;
            if (item.iconTintColor)
                leftIconTintColor = item.iconTintColor;
            else if (item.iconTint != -1)
                leftIconTintColor = UIColorFromRGB(item.iconTint);
            else
                leftIconTintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.leftIconView.tintColor = leftIconTintColor;
        }
        return cell;
    }
    else if ([cellId isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;

            BOOL isWarningCell = [item.key isEqualToString:@"makeBackupWarning"];
            [cell descriptionVisibility:isWarningCell];
            cell.selectionStyle = isWarningCell ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            if (isWarningCell)
            {
                cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                NSInteger color = item.iconTint;
                if (color != -1)
                {
                    cell.rightIconView.tintColor = UIColorFromRGB(color);
                    cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
                }
                else
                {
                    cell.rightIconView.image = [UIImage imageNamed:item.iconName];
                }
            }
            else
            {
                BOOL actionButtonDisabled = [self isActionButtonDisabled:item];
                cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.rightIconView.tintColor = actionButtonDisabled ? [UIColor colorNamed:ACColorNameIconColorDisabled] : [UIColor colorNamed:ACColorNameIconColorActive];
                cell.titleLabel.textColor = actionButtonDisabled ? [UIColor colorNamed:ACColorNameTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorActive];
            }
        }
        return cell;
    }
    else if ([cellId isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            BOOL isCheckingBackup = [item.key isEqualToString:@"checkingBackup"];
            cell.selectionStyle = isCheckingBackup ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            if (isCheckingBackup)
            {
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                cell.accessoryView = activityIndicator;
                [activityIndicator startAnimating];
            }
            else
            {
                cell.accessoryView = nil;
            }

            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = [item objForKey:@"titleTint"];
        }
        return cell;
    }
    else if ([cellId isEqualToString:OATitleIconProgressbarCell.getCellIdentifier])
    {
        return [item objForKey:@"cell"];
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OAStatusBackupViewController *statusBackupViewController = nil;
    if ([item.key isEqualToString:@"local_changes"] || [item.key isEqualToString:@"backup_progress"] || item.rowType == EOATableRowTypeCollapsable)
    {
        statusBackupViewController = [[OAStatusBackupViewController alloc] initWithType:EOARecentChangesLocal];
    }
    else if ([item.key isEqualToString:@"remote_updates"])
    {
        statusBackupViewController = [[OAStatusBackupViewController alloc] initWithType:EOARecentChangesRemote];
    }
    else if ([item.key isEqualToString:@"conflicts"])
    {
        statusBackupViewController = [[OAStatusBackupViewController alloc] initWithType:EOARecentChangesConflicts];
    }
    else if ([item.key isEqualToString:@"onTrashPressed"])
    {
        if ([OAIAPHelper isOsmAndProAvailable])
            [self showViewController:[[OACloudTrashViewController alloc] init]];
        else
            [self onSubscriptionExpired];
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        if (![self isActionButtonDisabled:item] && [self respondsToSelector:NSSelectorFromString(item.key)])
            [self performSelector:NSSelectorFromString(item.key) withObject:nil afterDelay:0.];
    }
    if (statusBackupViewController)
        [self showViewController:statusBackupViewController];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _backup = backupResult;
        _info = backupResult.backupInfo;
        _status = [OABackupStatus getBackupStatus:_backup];
        _error = _backup.error;
        [self refreshContent];
        [self.tblView.refreshControl endRefreshing];
    });
}

- (void)onBackupPreparing
{
}

#pragma mark - OABackupTypesDelegate

- (void)onCompleteTasks
{
    [self onBackupPrepared:_backupHelper.backup];
}

- (void)setProgressTotal:(NSInteger)total
{
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)sendEmail
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:OALocalizedString(@"backup_and_restore")];
        NSString *body = [NSString stringWithFormat:@"%@\n%@", _backup.error, [OAAppVersion getFullVersionWithAppName]];
        [mailCont setToRecipients:[NSArray arrayWithObject:OALocalizedString(@"login_footer_email_part")]];
        [mailCont setMessageBody:body isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

// MARK: OABackupNotifications

- (void)onBackupStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContent];
    });
}

- (void)onBackupFinished:(NSNotification *)notification
{
    NSString *error = notification.userInfo[@"error"];
    if (error != nil)
    {
        [self refreshContent];
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:4. inView:self.view];
    }
    else if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
    {
        [_backupHelper prepareBackup];
    }
}

- (void)onBackupProgressUpdate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float value = [notification.userInfo[@"progress"] floatValue];
        if (_backupProgressCell)
        {
            _backupProgressCell.progressBar.progress = value;
            _backupProgressCell.textView.text = [OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (value * 100)]];
        }
    });
}

#pragma mark - Purchases

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
        {
            [self.tblView.refreshControl beginRefreshing];
            [_backupHelper addPrepareBackupListener:self];
            [_backupHelper prepareBackup];
        }
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
        {
            [self.tblView.refreshControl beginRefreshing];
            [_backupHelper addPrepareBackupListener:self];
            [_backupHelper prepareBackup];
        }
    });
}

#pragma mark - OAOnDeleteAccountListener

- (void)onDeleteAccount:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error)
            [_backupHelper logout];

        NSString *text = error != nil ? [error getLocalizedError] : message;
        if (text && text.length > 0)
            [OAUtilities showToast:text details:nil duration:4 inView:self.view];
        [self dismissViewController];
    });
}

@end
