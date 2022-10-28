//
//  OACloudRecentChangesTableViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupTableViewController.h"
#import "OAStatusBackupViewController.h"
#import "OAStatusBackupConflictDetailsViewController.h"
#import "OAColors.h"
#import "OATableViewDataModel.h"
#import "OATableViewSectionData.h"
#import "OATableViewRowData.h"
#import "OAPrepareBackupResult.h"
#import "OABackupStatus.h"
#import "OABackupInfo.h"
#import "OASettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OABackupHelper.h"
#import "OASettingsHelper.h"
#import "OABackupDbHelper.h"
#import "OABackupListeners.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OABackupStatus.h"
#import "OARemoteFile.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OATitleIconProgressbarCell.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OANetworkSettingsHelper.h"
#import "OAImportBackupTask.h"
#import "OAExportBackupTask.h"
#import "OALocalFile.h"
#import "OATableViewCustomHeaderView.h"
#import "OASizes.h"
#import "OAResourcesUIHelper.h"

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

@interface OAStatusBackupTableViewController () <OAOnDeleteFilesListener, OAImportListener, OAOnPrepareBackupListener>

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesTable _tableType;
    OATableViewDataModel *_data;
    __weak id<OAStatusBackupTableDelegate> _delegate;
    NSIndexPath *_lastBackupIndexPath;
    NSInteger _itemsSection;
    
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
}

- (instancetype)initWithTableType:(EOARecentChangesTable)type
{
    self = [super init];
    if (self)
    {
        _tableType = type;
    }
    return self;
}

- (void)setDelegate:(id<OAStatusBackupTableDelegate>)delegate
{
    _delegate = delegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    _settingsHelper = [OANetworkSettingsHelper sharedInstance];
    _backupHelper = [OABackupHelper sharedInstance];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_settingsHelper updateExportListener:self];
    [_settingsHelper updateImportListener:self];
    [_backupHelper.backupListeners addDeleteFilesListener:self];
    [_backupHelper addPrepareBackupListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_settingsHelper updateExportListener:nil];
    [_settingsHelper updateImportListener:nil];
    [_backupHelper.backupListeners removeDeleteFilesListener:self];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)updateData
{
    [self generateData];
    [self.tableView reloadData];
}

- (OAPrepareBackupResult *) getBackup
{
    return _delegate.getBackup;
}

- (OABackupStatus *) getStatus
{
    return _delegate.getStatus;
}

- (void)generateData
{
    _data = [[OATableViewDataModel alloc] init];
    OATableViewSectionData *statusSection = [OATableViewSectionData sectionData];
    NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    if ([_settingsHelper isBackupExporting])
    {
        OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
        float progress = exportTask ? (float) exportTask.generalProgress / exportTask.maxProgress : 0.;
        progress = progress > 1 ? 1 : progress;
        OATableViewRowData *progressCell = [OATableViewRowData rowData];
        [progressCell setCellType:[OATitleIconProgressbarCell getCellIdentifier]];
        [progressCell setKey:@"lastBackup"];
        [progressCell setTitle:[OALocalizedString(@"osm_edit_uploading") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (progress * 100)]]];
        [progressCell setIconName:@"ic_custom_cloud_upload"];
        [progressCell setIconTint:color_primary_purple];
        [progressCell setObj:@(progress) forKey:@"progress"];
        [statusSection addRow:progressCell];
    }
    else
    {
        [statusSection addRowFromDictionary:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellKeyKey: @"lastBackup",
            kCellTitleKey: self.getStatus.statusTitle,
            kCellDescrKey: backupTime,
            kCellIconNameKey: self.getStatus.statusIconName,
            kCellIconTint: @(self.getStatus.iconColor)
        }];
    }
    [_data addSection:statusSection];
    _lastBackupIndexPath = [NSIndexPath indexPathForRow:statusSection.rowCount - 1 inSection:_data.sectionCount - 1];
    
    OATableViewSectionData *itemsSection = [OATableViewSectionData sectionData];
    if (_tableType == EOARecentChangesAll)
    {
        for (OASettingsItem *item in self.getBackup.backupInfo.itemsToUpload)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:NO]];
        }
        for (OASettingsItem *item in self.getBackup.backupInfo.itemsToDelete)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:YES]];
        }
    }
    for (NSArray *items in self.getBackup.backupInfo.filteredFilesToMerge)
    {
        [itemsSection addRow:[self rowFromConflictItems:items]];
    }

    if (itemsSection.rowCount == 0)
    {
        [itemsSection addRowFromDictionary:@{
            kCellTypeKey: [OALargeImageTitleDescrTableViewCell getCellIdentifier],
            kCellKeyKey: @"epmtyState",
            kCellTitleKey: OALocalizedString(_tableType == EOARecentChangesAll ? @"cloud_all_changes_uploaded" : @"cloud_no_conflicts"),
            kCellDescrKey: OALocalizedString(_tableType == EOARecentChangesAll ? @"cloud_all_changes_uploaded_descr" : @"cloud_no_conflicts_descr"),
            kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
        }];
    }

    [_data addSection:itemsSection];
    _itemsSection = _data.sectionCount - 1;
    if (_tableType == EOARecentChangesConflicts && itemsSection.rowCount > 1)
        [_data sectionDataForIndex:_itemsSection].headerText = OALocalizedString(@"backup_conflicts_descr");
}

- (OATableViewRowData *) rowFromConflictItems:(NSArray *)items
{
    OALocalFile *localFile = (OALocalFile *) items.firstObject;
    OARemoteFile *remoteFile = (OARemoteFile *) items.lastObject;
    OATableViewRowData *rowData = [self rowFromItem:localFile.item toDelete:NO];
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

- (OATableViewRowData *) rowFromItem:(OASettingsItem *)item toDelete:(BOOL)toDelete
{
    OATableViewRowData *rowData = [OATableViewRowData rowData];
    [rowData setCellType:[OARightIconTableViewCell getCellIdentifier]];
    [rowData setObj:item forKey:@"settings_item"];
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

    if (_delegate)
    {
        [rowData setDescr:[_delegate getDescriptionForItemType:item.type
                                                      fileName:fileName
                                                       summary:OALocalizedString(@"cloud_last_backup")]];
        [_delegate setRowIcon:rowData item:item];
    }

    [rowData setSecondaryIconName:toDelete ? @"ic_custom_remove" : @"ic_custom_cloud_info"];
    [rowData setObj:toDelete ? @(color_primary_red) : @(color_tint_gray) forKey:@"secondary_icon_color"];
    [rowData setIconTint:toDelete ? color_primary_purple : color_icon_inactive];
    return rowData;
}

- (NSArray *) rowAndIndexForType:(NSString *)type fileName:(NSString *)fileName
{
    EOASettingsItemType intType = [OASettingsItemType parseType:type];
    OATableViewSectionData *section = [_data sectionDataForIndex:_itemsSection];
    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableViewRowData *row = [section getRow:i];
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
            OATableViewRowData *item = [_data itemForIndexPath:indPath];
            BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
            OARightIconTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indPath];
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
                        [self.tableView reloadRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationNone];
                    });
                }
            }
        }
    });
}
// MARK: UITableViewDataSoure

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
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
    else if ([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showButton:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            [cell.cellImageView setImage:[UIImage imageNamed:item.iconName]];

            if (cell.needsUpdateConstraints)
                [cell updateConstraints];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATitleIconProgressbarCell getCellIdentifier]])
    {
        OATitleIconProgressbarCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconProgressbarCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleIconProgressbarCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
        }
        if (cell)
        {
            cell.textView.text = item.title;
            cell.imageView.image = [UIImage templateImageNamed:item.iconName];
            cell.imageView.tintColor = UIColorFromRGB(item.iconTint);

            [cell.progressBar setProgress:[[item objForKey:@"progress"] floatValue] animated:NO];
        }
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (header && section == _itemsSection && _tableType == EOARecentChangesConflicts)
    {
        customHeader.label.text = header;
        customHeader.label.font = [UIFont systemFontOfSize:13.];
        [customHeader setYOffset:2.];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (section == _itemsSection)
    {
        if (header && _tableType == EOARecentChangesConflicts)
        {
            return [OATableViewCustomHeaderView getHeight:header
                                                    width:tableView.bounds.size.width
                                                  xOffset:kPaddingOnSideOfContent
                                                  yOffset:2.
                                                     font:[UIFont systemFontOfSize:13.]] + 15.;
        }
        return kHeaderHeightDefault;
    }
    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    OARemoteFile *remoteConflictItem = [item objForKey:@"remoteConflictItem"];
    if (remoteConflictItem)
    {
        OAStatusBackupConflictDetailsViewController *conflictDetailsViewController =
        [[OAStatusBackupConflictDetailsViewController alloc] initWithLocalFile:[item objForKey:@"localConflictItem"]
                                                                    remoteFile:[item objForKey:@"remoteConflictItem"]
                                                    backupExportImportListener:self];
        conflictDetailsViewController.delegate = _delegate;
        [self presentViewController:conflictDetailsViewController animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OABackupExportListener

- (void)onBackupExportStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate updateBackupStatus:self.getBackup];
        
        if (_lastBackupIndexPath)
        {
            OATableViewRowData *progressCell = [_data itemForIndexPath:_lastBackupIndexPath];
            if ([progressCell.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
                [progressCell setCellType:[OATitleIconProgressbarCell getCellIdentifier]];
            
            [progressCell setTitle:[OALocalizedString(@"osm_edit_uploading") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]]];
            [progressCell setIconName:@"ic_custom_cloud_upload"];
            [progressCell setIconTint:color_primary_purple];
            [progressCell setObj:@(0.) forKey:@"progress"];
            
            [self.tableView reloadRowsAtIndexPaths:@[_lastBackupIndexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        };
    });
}

- (void)onBackupExportFinished:(nonnull NSString *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil)
        {
            [OAUtilities showToast:nil
                           details:[[OABackupError alloc] initWithError:error].getLocalizedError
                          duration:.4
                            inView:self.view];
        }
        else if (!_settingsHelper.isBackupExporting)
        {
            [_backupHelper prepareBackup];
        }
    });
}

- (void)onBackupExportItemFinished:(nonnull NSString *)type fileName:(nonnull NSString *)fileName
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusFinishedType value:100];
}

- (void)onBackupExportItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName value:(NSInteger)value
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusInProgressType value:value];
}

- (void)onBackupExportItemStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusStartedType value:0];
}

- (void)onBackupExportProgressUpdate:(NSInteger)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
        if (exportTask)
        {
            if (_lastBackupIndexPath)
            {
                float progress = (float) exportTask.generalProgress / exportTask.maxProgress;
                progress = progress > 1 ? 1 : progress;
                OATableViewRowData *progressCell = [_data itemForIndexPath:_lastBackupIndexPath];
                [progressCell setTitle:[OALocalizedString(@"osm_edit_uploading") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (progress * 100)]]];
                [progressCell setObj:@(progress) forKey:@"progress"];
                [self.tableView reloadRowsAtIndexPaths:@[_lastBackupIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    });
}

// MARK: OAOnDeleteFilesListener

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress
{
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *,NSString *> *)errors
{
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message
{
}

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files
{
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items
{
    // TODO: implement
//    for (SettingsItem settingsItem : settingsItems) {
//        String fileName = BackupHelper.getItemFileName(settingsItem);
//        Object item = getBackupItem(settingsItem.getType().name(), fileName);
//        if (item != null) {
//            notifyItemChanged(items.indexOf(item));
//        }
//    }
    [_backupHelper prepareBackup];
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusFinishedType value:100];
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusInProgressType value:value];
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work
{
    [self updateCellProgress:fileName type:type itemProgressType:EOAItemStatusStartedType value:0];
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate updateBackupStatus:backupResult];
        [self updateData];
    });
}

- (void)onBackupPreparing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate disableBottomButtons];
    });
}

@end
