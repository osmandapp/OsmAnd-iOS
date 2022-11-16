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
#import "OAStatusBackupConflictDetailsViewController.h"
#import "OAButtonRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTitleValueCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OAValueTableViewCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "FFCircularProgressView+isSpinning.h"
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
#import "OAExportSettingsType.h"
#import "OABaseBackupTypesViewController.h"
#import "OAExportBackupTask.h"
#import "OAAppVersionDependentConstants.h"
#import "OATableDataModel.h"
#import "OATableRowData.h"
#import "OATableSectionData.h"
#import "OsmAndApp.h"
#import "OASizes.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource, OAOnPrepareBackupListener, OABackupTypesDelegate, OAStatusBackupDelegate, MFMailComposeViewControllerDelegate>

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
    NSInteger _itemsSection;
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
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressItemFinished:) name:kBackupItemFinishedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemProgress:) name:kBackupItemProgressNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemStarted:) name:kBackupItemStartedNotification object:nil];
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
    if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
    {
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
    [_backupHelper addPrepareBackupListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
                kCellTitleKey: OALocalizedString(@"cloud_welcome_back"),
                kCellDescrKey: OALocalizedString(@"cloud_description"),
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
            
            if ([self shouldShowSyncButton])
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

        if (_settingsHelper.isBackupSyncing)
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
            OATableRowData *collapsableRow = [[OATableRowData alloc] initWithData:@{
                kCellTypeKey: OAMultiIconTextDescCell.getCellIdentifier,
                kCellKeyKey: @"lastBackup",
                kCellTitleKey: _status.statusTitle,
                kCellDescrKey: backupTime,
                kCellIconNameKey: _status.statusIconName,
                kCellIconTint: @(_status.iconColor)
            }];
            [backupRows addRow:collapsableRow];

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
            if (_settingsHelper.isBackupSyncing)
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
    OATableSectionData *itemsSection = [OATableSectionData sectionData];
    for (OALocalFile *file in _info.filteredFilesToUpload)
    {
        [itemsSection addRow:[self rowFromItem:file
                                      iconName:@"ic_custom_cloud_upload_outline"
                                      mainTint:color_icon_inactive
                                 secondaryTint:color_primary_purple operation:EOABackupSyncOperationUpload]];
    }
    for (OARemoteFile *file in _info.filteredFilesToDelete)
    {
        [itemsSection addRow:[self rowFromItem:file iconName:@"ic_custom_remove" mainTint:color_primary_purple secondaryTint:color_primary_red operation:EOABackupSyncOperationDelete]];
    }
    NSArray<NSArray *> *downloadItems = [OABackupHelper getItemsMapForRestore:_info settingsItems:_backup.settingsItems];
    for (NSArray *pair in downloadItems)
    {
        [itemsSection addRow:[self rowFromItem:pair.firstObject
                                      iconName:@"ic_custom_cloud_download_outline"
                                      mainTint:color_icon_inactive
                                 secondaryTint:color_primary_purple
                                     operation:EOABackupSyncOperationDownload]];
    }
    for (NSArray *items in _info.filteredFilesToMerge)
    {
        [itemsSection addRow:[self rowFromConflictItems:items]];
    }
    if (itemsSection.rowCount == 0)
    {
        [itemsSection addRowFromDictionary:@{
            kCellTypeKey: [OALargeImageTitleDescrTableViewCell getCellIdentifier],
            kCellKeyKey: @"epmtyState",
            kCellTitleKey: OALocalizedString(@"cloud_all_changes_uploaded"),
            kCellDescrKey: OALocalizedString(@"cloud_all_changes_uploaded_descr"),
            kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
        }];
    }
    if (!_backupHelper.isBackupPreparing)
    {
        _itemsSection = _data.sectionCount;
        [_data addSection:itemsSection];
    }
}

- (OATableRowData *) rowFromConflictItems:(NSArray *)items
{
    OALocalFile *localFile = (OALocalFile *) items.firstObject;
    OARemoteFile *remoteFile = (OARemoteFile *) items.lastObject;
    OATableRowData *rowData = [self rowFromItem:localFile
                                       iconName:@"ic_custom_cloud_info"
                                       mainTint:color_icon_inactive
                                  secondaryTint:color_tint_gray
                                      operation:EOABackupSyncOperationNone];
    [rowData setObj:localFile forKey:@"localConflictItem"];
    [rowData setObj:remoteFile forKey:@"remoteConflictItem"];
    NSString *conflictStr = [OALocalizedString(@"cloud_conflict") stringByAppendingString:@". "];
    NSMutableAttributedString *attributedDescr = [[NSMutableAttributedString alloc] initWithString:[conflictStr stringByAppendingString:rowData.descr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13 weight:UIFontWeightMedium],
                                      NSForegroundColorAttributeName : UIColorFromRGB(color_primary_red) }
                             range:[attributedDescr.string rangeOfString:conflictStr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13],
                                      NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) }
                             range:[attributedDescr.string rangeOfString:rowData.descr]];
    [rowData setObj:attributedDescr forKey:@"descr_attr"];
    [rowData setObj:@"ic_custom_alert" forKey:@"secondary_icon_conflict"];
    [rowData setObj:@(color_primary_red) forKey:@"secondary_icon_color"];
    [rowData setIconTint:color_primary_purple];
    return rowData;
}

- (OATableRowData *) rowFromItem:(id)file iconName:(NSString *)iconName mainTint:(NSInteger)mainTint secondaryTint:(NSInteger)secondaryTint operation:(EOABackupSyncOperationType)operation
{
    OASettingsItem *item = nil;
    if ([file isKindOfClass:OALocalFile.class])
        item = ((OALocalFile *) file).item;
    else if ([file isKindOfClass:OARemoteFile.class])
        item = ((OARemoteFile *) file).item;
    OATableRowData *rowData = [OATableRowData rowData];
    [rowData setCellType:[OARightIconTableViewCell getCellIdentifier]];
    [rowData setObj:file forKey:@"file"];
    [rowData setObj:item forKey:@"settings_item"];
    [rowData setObj:@(operation) forKey:@"operation"];
    NSString *name = item.getPublicName;
    if ([item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *flItem = (OAFileSettingsItem *)item;
        if (flItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts")];
        else if (flItem.subtype == EOASettingsItemFileSubtypeVoice)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"recorded_voice")];
    }
    [rowData setTitle:name];
    NSString *fileName = [OABackupHelper getItemFileName:item];
    [rowData setObj:fileName forKey:@"file_name"];

    
    [rowData setDescr:[self getDescriptionForItemType:item.type
                                             fileName:fileName
                                              summary:OALocalizedString(@"cloud_last_backup")]];
    [self setRowIcon:rowData item:item];

    [rowData setSecondaryIconName:iconName];
    [rowData setObj:@(secondaryTint) forKey:@"secondary_icon_color"];
    [rowData setIconTint:mainTint];
    return rowData;
}

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setObj:[UIImage templateImageNamed:[mode getIconName]] forKey:@"icon"];
    }
    else
    {
        OAExportSettingsType *type = [OAExportSettingsType getExportSettingsTypeForItem:item];
        if (type != nil)
            [rowData setObj:type.icon forKey:@"icon"];
    }
}

- (NSArray *) rowAndIndexForType:(NSString *)type fileName:(NSString *)fileName
{
    EOASettingsItemType intType = [OASettingsItemType parseType:type];
    OATableSectionData *section = [_data sectionDataForIndex:_itemsSection];
    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableRowData *row = [section getRow:i];
        OASettingsItem *item = [row objForKey:@"settings_item"];
        if (item.type == intType && [[row objForKey:@"file_name"] isEqualToString:fileName])
            return @[row, @(i)];
    }
    return nil;
}

- (void)updateCellProgress:(NSString * _Nonnull)fileName
                      type:(NSString * _Nonnull)type
          itemProgressType:(EOAItemStatusType)itemProgressType
                     value:(NSInteger)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *rowIndex = [self rowAndIndexForType:type fileName:fileName];
        if (rowIndex)
        {
            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[rowIndex.lastObject integerValue] inSection:_itemsSection];
            OATableRowData *item = [_data itemForIndexPath:indPath];
            BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
            OARightIconTableViewCell *cell = [self.tblView cellForRowAtIndexPath:indPath];
            if (cell)
            {
                [cell rightIconVisibility:hasConflict];
                FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
                if (!progressView)
                {
                    progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
                    progressView.iconView = [[UIView alloc] init];
                    progressView.tintColor = UIColorFromRGB(color_primary_purple);
                    cell.accessoryView = progressView;
                }

                if (itemProgressType == EOAItemStatusStartedType)
                {
                    progressView.iconPath = [UIBezierPath bezierPath];
                    progressView.progress = 0.;
                    if (!progressView.isSpinning)
                        [progressView startSpinProgressBackgroundLayer];
                    [progressView setNeedsDisplay];
                }
                else if (itemProgressType == EOAItemStatusInProgressType)
                {
                    progressView.iconPath = nil;
                    if (progressView.isSpinning)
                        [progressView stopSpinProgressBackgroundLayer];
                    progressView.progress = value / 100. - 0.001;
                }
                else if (itemProgressType == EOAItemStatusFinishedType)
                {
                    progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                    progressView.progress = 0.;
                    if (!progressView.isSpinning)
                        [progressView startSpinProgressBackgroundLayer];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [cell rightIconVisibility:YES];
                        BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
                        [item setIconTint:color_primary_purple];
                        [item setObj:hasConflict ? @(color_primary_red) : @(color_primary_purple) forKey:@"secondary_icon_color"];
                        [self.tblView reloadRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationNone];
                    });
                }
            }
        }
    });
}

- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary
{
    if (timeMs != -1)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(timeMs / 1000)
                                                               def:OALocalizedString(@"shared_string_never")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time];
    }
    else
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")];
    }
}

- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary
{
    OAUploadedFileInfo *info = [[OABackupDbHelper sharedDatabase] getUploadedFileInfo:[OASettingsItemType typeName:type] name:fileName];
    return [self generateTimeString:info.uploadTime summary:summary];
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

- (BOOL) shouldShowSyncButton
{
    return _backup.localFiles.count > 0 || _backup.remoteFiles.count > 0;
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
    [_settingsHelper syncSettingsItems:kSyncItemsKey];
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
    [_settingsHelper cancelImport];
    [_settingsHelper cancelExport];
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
    else if ([cellId isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
        }
        if (cell)
        {
            BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.selectionStyle = hasConflict ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.accessoryType = hasConflict ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

            NSString *description = item.descr;
            NSAttributedString *descriptionAttributed = [item objForKey:@"descr_attr"];
            [cell descriptionVisibility:description != nil || descriptionAttributed != nil];
            if (descriptionAttributed)
            {
                cell.descriptionLabel.text = nil;
                cell.descriptionLabel.attributedText = descriptionAttributed;
            }
            else
            {
                cell.descriptionLabel.attributedText = nil;
                cell.descriptionLabel.text = description;
            }

            cell.titleLabel.text = item.title;
            cell.leftIconView.image = [item objForKey:@"icon"];
            cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);

            NSString *secondaryIconName = hasConflict ? [item stringForKey:@"secondary_icon_conflict"] : item.secondaryIconName;
            cell.rightIconView.image = secondaryIconName ? [UIImage templateImageNamed:secondaryIconName] : nil;
            cell.rightIconView.tintColor = UIColorFromRGB([item integerForKey:@"secondary_icon_color"]);
        }
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
        [cell.topButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
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
    OARemoteFile *remoteConflictItem = [item objForKey:@"remoteConflictItem"];
    if (remoteConflictItem)
    {
        OAStatusBackupConflictDetailsViewController *conflictDetailsViewController =
        [[OAStatusBackupConflictDetailsViewController alloc] initWithLocalFile:[item objForKey:@"localConflictItem"]
                                                                    remoteFile:[item objForKey:@"remoteConflictItem"]
                                                    backupExportImportListener:self];
        conflictDetailsViewController.delegate = self;
        [self presentViewController:conflictDetailsViewController animated:YES completion:nil];
    }
    else if ([item objForKey:@"settings_item"] && [item objForKey:@"operation"] && !_settingsHelper.isBackupSyncing)
    {
        EOABackupSyncOperationType operation = (EOABackupSyncOperationType) [item integerForKey:@"operation"];
        id file = [item objForKey:@"file"];
        if ([file isKindOfClass:OALocalFile.class] && operation == EOABackupSyncOperationUpload)
        {
            OALocalFile *fl = (OALocalFile *) file;
            NSString *fileName = [OABackupHelper getItemFileName:fl.item];
            if (!_settingsHelper.syncBackupTasks[fileName])
                [_settingsHelper syncSettingsItems:fileName localFile:fl remoteFile:nil operation:operation];
        }
        else if ([file isKindOfClass:OARemoteFile.class])
        {
            OARemoteFile *fl = (OARemoteFile *) file;
            NSString *fileName = [OABackupHelper getItemFileName:fl.item];
            if (!_settingsHelper.syncBackupTasks[fileName])
                [_settingsHelper syncSettingsItems:fileName localFile:nil remoteFile:fl operation:operation];
        }
    }
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
        self.settingsButton.userInteractionEnabled = YES;
        self.settingsButton.tintColor = UIColor.whiteColor;
        [self.tblView.refreshControl endRefreshing];
    });
}

- (void)onBackupPreparing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Show progress bar
        [self.tblView.refreshControl layoutIfNeeded];
        [self.tblView.refreshControl beginRefreshing];
        CGPoint contentOffset = CGPointMake(0, -self.tblView.refreshControl.frame.size.height);
        [self.tblView setContentOffset:contentOffset animated:YES];
        self.settingsButton.userInteractionEnabled = NO;
        self.settingsButton.tintColor = UIColorFromRGB(color_tint_gray);
    });
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
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:.4 inView:self.view];
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

- (void)onBackupProgressItemFinished:(NSNotification *)notification
{
    [self updateCellProgress:notification.userInfo[@"name"] type:notification.userInfo[@"type"] itemProgressType:EOAItemStatusFinishedType value:100];
}

- (void)onBackupItemProgress:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self updateCellProgress:info[@"name"] type:info[@"type"] itemProgressType:EOAItemStatusInProgressType value:[info[@"value"] integerValue]];
}

- (void)onBackupItemStarted:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self updateCellProgress:info[@"name"] type:info[@"type"] itemProgressType:EOAItemStatusStartedType value:0];
}

@end
