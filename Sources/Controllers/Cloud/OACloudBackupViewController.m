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
#import "OATitleRightIconCell.h"
#import "OAIAPHelper.h"
#import "OABackupHelper.h"
#import "OAButtonRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTitleValueCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OAValueTableViewCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OAMainSettingsViewController.h"
#import "OARestoreBackupViewController.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OABackupStatus.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAOsmAndFormatter.h"
#import "OABackupError.h"
#import "OASyncBackupTask.h"
#import "OASettingsBackupViewController.h"
#import "OAExportSettingsType.h"
#import "OABaseBackupTypesViewController.h"
#import "OAStatusBackupViewController.h"
#import "OAExportBackupTask.h"
#import "OAAppVersionDependentConstants.h"
#import "OATableDataModel.h"
#import "OATableCollapsableRowData.h"
#import "OATableRowData.h"
#import "OATableSectionData.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource, OABackupExportListener, OAImportListener, OAOnPrepareBackupListener, OABackupTypesDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *navBarTitle;
@property (weak, nonatomic) IBOutlet UIButton *backImgButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
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
    NSIndexPath *_lastBackupIndexPath;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBackupFinished:) name:kBackupSyncFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBackupStarted) name:kBackupSyncStartedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressUpdate:) name:kBackupProgressUpdateNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNotificationListeners];
    [OAIAPHelper.sharedInstance checkBackupPurchase];
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    _backupHelper = OABackupHelper.sharedInstance;
    self.tblView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tblView.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    if (!_settingsHelper.isBackupExporting)
    {
//        [_settingsHelper updateExportListener:self];
//        [_settingsHelper updateImportListener:self];
        [_backupHelper addPrepareBackupListener:self];
        [_backupHelper prepareBackup];
    }

    self.tblView.delegate = self;
    self.tblView.dataSource = self;
    self.tblView.estimatedRowHeight = 44.;
    self.tblView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [_settingsHelper updateExportListener:self];
//    [_settingsHelper updateImportListener:self];
    [_backupHelper addPrepareBackupListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [_settingsHelper updateExportListener:nil];
//    [_settingsHelper updateImportListener:nil];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applyLocalization
{
    self.navBarTitle.text = OALocalizedString(@"backup_and_restore");
}

- (void) onRefresh
{
    if (!_settingsHelper.isBackupExporting)
    {
        [_settingsHelper updateExportListener:self];
        [_settingsHelper updateImportListener:self];
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
                kCellTitleKey: OALocalizedString(@"cloud_welcome_back"),
                kCellDescrKey: OALocalizedString(@"cloud_description"),
                kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
            }];
            BOOL showBothButtons = [self shouldShowBackupButton] && [self shouldShowRestoreButton];
            if (showBothButtons)
            {
                [existingBackupSection addRowFromDictionary:@{
                    kCellTypeKey: OATwoFilledButtonsTableViewCell.getCellIdentifier,
                    kCellKeyKey: @"backupAndRestore",
                    @"topTitle": OALocalizedString(@"cloud_restore_now"),
                    @"bottomTitle": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            if ([self shouldShowRestoreButton] && !showBothButtons)
            {
                [existingBackupSection addRowFromDictionary:@{
                    kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
                    kCellKeyKey: @"onRestoreButtonPressed",
                    kCellTitleKey: OALocalizedString(@"cloud_restore_now")
                }];
            }
            if ([self shouldShowBackupButton] && !showBothButtons)
            {
                [existingBackupSection addRowFromDictionary:@{
                    kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
                    kCellKeyKey: @"onSetUpBackupButtonPressed",
                    kCellTitleKey: OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            existingBackupSection.headerText = OALocalizedString(@"cloud_backup");
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
            
            if ([self shouldShowBackupButton])
            {
                [noBackupRows addRowFromDictionary:@{
                    kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
                    kCellKeyKey: @"onSetUpBackupButtonPressed",
                    kCellTitleKey: OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            noBackupRows.headerText = OALocalizedString(@"cloud_backup");
            [_data addSection:noBackupRows];
        }
    }
    else
    {
        OATableSectionData *backupRows = [OATableSectionData sectionData];
        backupRows.headerText = OALocalizedString(@"cloud_backup");
        [_data addSection:backupRows];

        OASyncBackupTask *syncTask = _settingsHelper.syncBackupTask;
        if (syncTask)
        {
            _backupProgressCell = [self getProgressBarCell];
            NSDictionary *backupProgressCell = @{
                kCellTypeKey: OATitleIconProgressbarCell.getCellIdentifier,
                @"cell": _backupProgressCell
            };
            [backupRows addRowFromDictionary:backupProgressCell];
        }
        else
        {
            NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
            OATableCollapsableRowData *collapsableRow = [[OATableCollapsableRowData alloc] initWithData:@{
                kCellTypeKey: OAMultiIconTextDescCell.getCellIdentifier,
                kCellKeyKey: @"lastBackup",
                kCellTitleKey: _status.statusTitle,
                kCellDescrKey: backupTime,
                kCellIconNameKey: _status.statusIconName,
                kCellIconTint: @(_status.iconColor)
            }];
            OATableRowData *localChangesRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
                kCellKeyKey: @"local_changes",
                kCellTitleKey: OALocalizedString(@"local_changes"),
                kCellIconNameKey: @"ic_custom_device",
                @"value": @(_backup.backupInfo.filteredFilesToUpload.count)
            }];
            [collapsableRow addDependentRow:localChangesRow];
            OATableRowData *updatesRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
                kCellKeyKey: @"remote_updates",
                kCellTitleKey: OALocalizedString(@"res_updates"),
                kCellIconNameKey: @"ic_custom_cloud",
                @"value": @(_backup.backupInfo.filesToDownload.count)
            }];
            [collapsableRow addDependentRow:updatesRow];
            [backupRows addRow:collapsableRow];
            _lastBackupIndexPath = [NSIndexPath indexPathForRow:backupRows.rowCount - 1 inSection:_data.sectionCount - 1];

            if (_status.warningTitle != nil || _error.length > 0)
            {
                BOOL hasWarningStatus = _status.warningTitle != nil;
                BOOL hasDescr = _error || _status.warningDescription;
                NSString *descr = hasDescr && hasWarningStatus ? _status.warningDescription : [_error stringByAppendingFormat:@"\n%@", OALocalizedString(@"error_contact_support")];
                NSInteger color = _status == OABackupStatus.CONFLICTS || _status == OABackupStatus.ERROR ? _status.iconColor
                        : _status == OABackupStatus.MAKE_BACKUP ? profile_icon_color_green_light : -1;
                NSDictionary *makeBackupWarningCell = @{
                    kCellTypeKey: OATitleDescrRightIconTableViewCell.getCellIdentifier,
                    kCellKeyKey: @"makeBackupWarning",
                    kCellTitleKey: hasWarningStatus ? _status.warningTitle : OALocalizedString(@"osm_failed_uploads"),
                    kCellDescrKey: descr ? descr : @"",
                    kCellIconTint: @(color),
                    kCellIconNameKey: _status.warningIconName
                };
                [backupRows addRowFromDictionary:makeBackupWarningCell];
            }
        }
        BOOL hasInfo = _info != nil;
        BOOL noConflicts = _status == OABackupStatus.CONFLICTS && (!hasInfo || _info.filteredFilesToMerge.count == 0);
        BOOL noChanges = _status == OABackupStatus.MAKE_BACKUP && (!hasInfo || (_info.filteredFilesToUpload.count == 0 && _info.filteredFilesToDelete.count == 0));
        BOOL actionButtonHidden = _status == OABackupStatus.BACKUP_COMPLETE || noConflicts || noChanges;
        if (!actionButtonHidden)
        {
            if (_settingsHelper.isBackupExporting)
            {
                NSDictionary *cancellCell = @{
                    kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
                    kCellKeyKey: @"cancellBackupPressed",
                    kCellTitleKey: OALocalizedString(@"shared_string_cancel"),
                    kCellIconNameKey: @"ic_custom_cancel"
                };
                [backupRows addRowFromDictionary:cancellCell];
            }
            else if (_status == OABackupStatus.MAKE_BACKUP || _status == OABackupStatus.CONFLICTS)
            {
                NSDictionary *backupNowCell = @{
                    kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
                    kCellKeyKey: @"onSetUpBackupButtonPressed",
                    kCellTitleKey: OALocalizedString(@"sync_now"),
                    kCellIconNameKey: @"ic_custom_update"
                };
                [backupRows addRowFromDictionary:backupNowCell];
            }
//            else if (_status == OABackupStatus.CONFLICTS)
//            {
//                NSDictionary *conflictsCell = @{
//                    kCellTypeKey: OAValueTableViewCell.getCellIdentifier,
//                    kCellKeyKey: @"viewConflictsCell",
//                    kCellTitleKey: OALocalizedString(@"cloud_view_conflicts"),
//                    @"value": @(_info.filteredFilesToMerge.count)
//                };
//                [backupRows addRowFromDictionary:conflictsCell];
//            }
            else if (_status == OABackupStatus.NO_INTERNET_CONNECTION)
            {
                NSDictionary *retryCell = @{
                    kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
                    kCellKeyKey: @"onRetryPressed",
                    kCellTitleKey: _status.actionTitle,
                    kCellIconNameKey: @"ic_custom_reset"
                };
                [backupRows addRowFromDictionary:retryCell];
            }
            else if (_status == OABackupStatus.ERROR)
            {
                NSDictionary *retryCell = @{
                    kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
                    kCellKeyKey: @"onSupportPressed",
                    kCellTitleKey: _status.actionTitle,
                    kCellIconNameKey: @"ic_custom_letter_outlined"
                };
                [backupRows addRowFromDictionary:retryCell];
            }
            else if (_status == OABackupStatus.SUBSCRIPTION_EXPIRED)
            {
                NSDictionary *purchaseCell = @{
                    kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
                    kCellKeyKey: @"onSubscriptionExpired",
                    kCellTitleKey: _status.actionTitle,
                    kCellIconNameKey: @"ic_custom_osmand_pro_logo_colored"
                };
                [backupRows addRowFromDictionary:purchaseCell];
            }
        }
    }
    OATableSectionData *restoreSection = [OATableSectionData sectionData];
    restoreSection.headerText = OALocalizedString(@"restore");
    restoreSection.footerText = OALocalizedString(@"restore_backup_descr");
    [restoreSection addRowFromDictionary:@{
        kCellTypeKey: OAButtonRightIconCell.getCellIdentifier,
        kCellKeyKey: @"onRestoreButtonPressed",
        kCellTitleKey: OALocalizedString(@"restore_data"),
        kCellIconNameKey: @"ic_custom_restore"
    }];
    [_data addSection:restoreSection];

    [_data addSection:[self getLocalBackupSectionDataObj]];
}

- (OATitleIconProgressbarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
    OATitleIconProgressbarCell *resultCell = (OATitleIconProgressbarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
    resultCell.textView.text = [OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]];
    resultCell.imgView.image = [UIImage templateImageNamed:@"ic_custom_cloud_upload"];
    resultCell.imgView.tintColor = UIColorFromRGB(color_primary_purple);
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    resultCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return resultCell;
}

- (BOOL) shouldShowBackupButton
{
    return _backup.localFiles.count > 0;
}

- (BOOL) shouldShowRestoreButton
{
    return _backup.remoteFiles.count > 0;
}

- (void) refreshContent
{
    [self generateData];
    [self.tblView reloadData];
}

- (IBAction)onBackButtonPressed
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OAMainSettingsViewController class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }

    [self dismissViewController];
}

- (IBAction)onSettingsButtonPressed
{
    OASettingsBackupViewController *settingsBackupViewController = [[OASettingsBackupViewController alloc] init];
    settingsBackupViewController.backupTypesDelegate = self;
    [self.navigationController pushViewController:settingsBackupViewController animated:YES];
}

- (void)onSetUpBackupButtonPressed
{
    OASyncBackupTask *syncTask = [[OASyncBackupTask alloc] init];
    [syncTask execute];
}

- (void) onViewConflictsPressed
{
    OAStatusBackupViewController *statusBackupViewController = [[OAStatusBackupViewController alloc] initWithBackup:_backup status:_status openConflicts:YES];
    statusBackupViewController.delegate = self;
    [self.navigationController pushViewController:statusBackupViewController animated:YES];
}

- (void)onRetryPressed
{
    [_backupHelper prepareBackup];
}

- (void)onSupportPressed
{
    [self sendEmail];
}

- (void) cancellBackupPressed
{
    [_settingsHelper cancelImport];
    [_settingsHelper cancelExport];
}

- (void) onSubscriptionExpired
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
}

- (void)onRestoreButtonPressed
{
    OARestoreBackupViewController *restoreVC = [[OARestoreBackupViewController alloc] init];
    [self.navigationController pushViewController:restoreVC animated:YES];
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
    if ([cellId isEqualToString:OATitleRightIconCell.getCellIdentifier])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17.];
        }
        cell.titleView.text = item.title;
        [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        return cell;
    }
    else if ([cellId isEqualToString:OALargeImageTitleDescrTableViewCell.getCellIdentifier])
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
        cell.leftIconView.tintColor = UIColorFromRGB((([item integerForKey:@"value"] > 0) ? color_primary_purple : color_tint_gray));
        cell.separatorInset = UIEdgeInsetsMake(0., ([item.key isEqualToString:@"remote_updates"] ? 0. : 65.), 0., 0.);
        return cell;
    }
    else if ([cellId isEqualToString:OAFilledButtonCell.getCellIdentifier])
    {
        OAFilledButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:OAFilledButtonCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
            cell.button.backgroundColor = UIColorFromRGB(color_primary_purple);
            [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            cell.button.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
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
        [cell.topButton addTarget:self action:@selector(onRestoreButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton setTitle:[item objForKey:@"bottomTitle"] forState:UIControlStateNormal];
        [cell.bottomButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OAMultiIconTextDescCell.getCellIdentifier])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:OAMultiIconTextDescCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            [cell setOverflowVisibility:YES];
        }
        BOOL collapsed = item.rowType == EOATableRowTypeCollapsable && ((OATableCollapsableRowData *) item).collapsed;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:collapsed ? @"ic_custom_arrow_right" : @"ic_custom_arrow_down"]];
        imageView.tintColor = UIColorFromRGB(color_primary_purple);
        cell.accessoryView = imageView;
        cell.textView.text = item.title;
        cell.descView.text = item.descr;
        [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        cell.iconView.tintColor = item.iconTint != -1 ? UIColorFromRGB(item.iconTint) : UIColorFromRGB(color_primary_purple);
        return cell;
    }
    else if ([cellId isEqualToString:OAButtonRightIconCell.getCellIdentifier])
    {
        OAButtonRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OAButtonRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:NSSelectorFromString(item.key) forControlEvents:UIControlEventTouchUpInside];
        [cell.button setTitle:item.title forState:UIControlStateNormal];
        [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        return cell;
    }
    else if ([cellId isEqualToString:OATitleDescrRightIconTableViewCell.getCellIdentifier])
    {
        OATitleDescrRightIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleDescrRightIconTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleLabel.text = item.title;
        cell.descriptionLabel.text = item.descr;
        NSInteger color = item.iconTint;
        if (color != -1)
        {
            cell.iconView.tintColor = UIColorFromRGB(color);
            [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        }
        else
        {
            [cell.iconView setImage:[UIImage imageNamed:item.iconName]];
        }
        
        return cell;
    }
    else if ([cellId isEqualToString:OAIconTitleValueCell.getCellIdentifier])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:OAIconTitleValueCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.descriptionView.font = [UIFont systemFontOfSize:17.];
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
        }
        cell.textView.text = item.title;
        cell.descriptionView.text = [item stringForKey:@"value"];
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
    NSString *itemId = item.key;
    if (indexPath == _lastBackupIndexPath)
    {
        if (item.rowType == EOATableRowTypeCollapsable)
        {
            OATableCollapsableRowData *collapsableRow = (OATableCollapsableRowData *)item;
            collapsableRow.collapsed = !collapsableRow.collapsed;
            NSMutableArray<NSIndexPath *> *rowIndexes = [NSMutableArray array];
            for (NSInteger i = 1; i <= collapsableRow.dependentRowsCount; i++)
                [rowIndexes addObject:[NSIndexPath indexPathForRow:(indexPath.row + i) inSection:indexPath.section]];
            
            [tableView performBatchUpdates:^{
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                if (collapsableRow.collapsed)
                    [tableView deleteRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
                else
                    [tableView insertRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
            } completion:nil];
            
        }
//        OAStatusBackupViewController *statusBackupViewController = [[OAStatusBackupViewController alloc] initWithBackup:_backup status:_status];
//        statusBackupViewController.delegate = self;
//        [self.navigationController pushViewController:statusBackupViewController animated:YES];
    }
    else if ([itemId isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([itemId isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
    else if ([itemId isEqualToString:@"viewConflictsCell"])
    {
        [self onViewConflictsPressed];
    }
    else if ([itemId isEqualToString:@"backupNow"])
    {
        
    }
    else if ([itemId isEqualToString:@"retry"])
    {
        
    }
    else if ([itemId isEqualToString:@"viewConflicts"])
    {
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OABackupExportListener

- (void)onBackupFinished:(NSNotification *)notification
{
    NSString *error = notification.userInfo[@"error"];
    if (error != nil)
    {
        [self refreshContent];
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:.4 inView:self.view];
    }
    else if (!_settingsHelper.isBackupExporting)
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

- (void)onBackupStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContent];
    });
}

- (void)onBackupExportItemFinished:(nonnull NSString *)type fileName:(nonnull NSString *)fileName
{
    
}

- (void)onBackupExportItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName value:(NSInteger)value
{
    
}

- (void)onBackupExportItemStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work
{
    
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
    
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
    
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
    
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    _backup = backupResult;
    _info = _backup.backupInfo;
    _status = [OABackupStatus getBackupStatus:_backup];
    _error = _backup.error;
    [self refreshContent];
    self.settingsButton.userInteractionEnabled = YES;
    self.settingsButton.tintColor = UIColor.whiteColor;
    [self.tblView.refreshControl endRefreshing];
}

- (void)onBackupPreparing
{
    // Show progress bar
    [self.tblView.refreshControl layoutIfNeeded];
    [self.tblView.refreshControl beginRefreshing];
    self.settingsButton.userInteractionEnabled = NO;
    self.settingsButton.tintColor = UIColorFromRGB(color_tint_gray);
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
        NSString *body = [NSString stringWithFormat:@"%@\n%@", _backup.error, [OAAppVersionDependentConstants getAppVersionWithBundle]];
        [mailCont setToRecipients:[NSArray arrayWithObject:OALocalizedString(@"login_footer_email_part")]];
        [mailCont setMessageBody:body isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
