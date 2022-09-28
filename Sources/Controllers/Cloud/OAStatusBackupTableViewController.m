//
//  OACloudRecentChangesTableViewController.m
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
#import "OATableViewCellSimple.h"
#import "OATableViewCellRightIcon.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OANetworkSettingsHelper.h"
#import "OAImportBackupTask.h"
#import "OAExportBackupTask.h"
#import "OALocalFile.h"
#import "OATableViewCustomHeaderView.h"
#import "OASizes.h"

@interface OAStatusBackupTableViewController () <OAOnDeleteFilesListener, OAImportListener, OAOnPrepareBackupListener>

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesTable _tableType;
    OATableViewDataModel *_data;
    id<OAStatusBackupTableDelegate> _delegate;
    NSInteger _itemsSection;
    
    OABackupStatus *_status;
    OAPrepareBackupResult *_backup;
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
}

- (instancetype)initWithTableType:(EOARecentChangesTable)type backup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status
{
    self = [super init];
    if (self)
    {
        _tableType = type;
        _backup = backup;
        _status = status;
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
    [self generateData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (void)generateData
{
    _data = [[OATableViewDataModel alloc] init];
    OATableViewSectionData *statusSection = [OATableViewSectionData sectionData];
    NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    [statusSection addRowFromDictionary:@{
        kCellTypeKey: [OATableViewCellSimple getCellIdentifier],
        kCellKeyKey: @"lastBackup",
        kCellTitleKey: _status.statusTitle,
        kCellDescrKey: backupTime,
        kCellIconNameKey: _status.statusIconName,
        kCellIconTint: @((_status == OABackupStatus.BACKUP_COMPLETE || _status == OABackupStatus.MAKE_BACKUP) ? profile_icon_color_green_light : color_primary_purple)
    }];
    [_data addSection:statusSection];
    
    OATableViewSectionData *itemsSection = [OATableViewSectionData sectionData];
    if (_tableType == EOARecentChangesAll)
    {
        for (OASettingsItem *item in _backup.backupInfo.itemsToUpload)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:NO]];
        }
        for (OASettingsItem *item in _backup.backupInfo.itemsToDelete)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:YES]];
        }
    }
    for (NSArray *items in _backup.backupInfo.filteredFilesToMerge)
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
    return rowData;
}

- (OATableViewRowData *) rowFromItem:(OASettingsItem *)item toDelete:(BOOL)toDelete
{
    OATableViewRowData *rowData = [OATableViewRowData rowData];
    [rowData setCellType:[OATableViewCellRightIcon getCellIdentifier]];
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

    [rowData setSecondaryIconName:toDelete ? @"ic_custom_remove" : @"ic_custom_cloud_alert"];
    return rowData;
}

- (NSArray *) rowAndIndexForType:(NSString *)type fileName:(NSString *)fileName
{
    EOASettingsItemType intType = [OASettingsItemType parseType:type];
    OATableViewSectionData *section = [_data sectionDataForIndex:1];
    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableViewRowData *row = [section getRow:i];
        OASettingsItem *item = [row objForKey:@"settings_item"];
        if (item.type == intType && [[row objForKey:@"file_name"] isEqualToString:fileName])
            return @[@(i), row];
    }
    return nil;
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

- (void)setupProgress:(OATableViewCellRightIcon *)cell item:(OATableViewRowData *)item
{
    OAImportBackupTask *importTask = [_settingsHelper getImportTask:kBackupItemsKey];
    OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
    if (!importTask && !exportTask)
    {
        [cell rightIconVisibility:YES];
        OARemoteFile *remoteConflictItem = [item objForKey:@"remoteConflictItem"];
        if (remoteConflictItem)
        {
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_alert"];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_red);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else
        {
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else
    {
        [cell rightIconVisibility:NO];
        FFCircularProgressView *progressView = nil;
        if (!cell.accessoryView)
        {
            FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];
            progressView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.accessoryView = progressView;
        }
        progressView = (FFCircularProgressView *) cell.accessoryView;
        OAItemProgressInfo *progressInfo = nil;
        OASettingsItem *settingsItem = [item objForKey:@"settings_item"];
        if (exportTask)
        {
            progressInfo = [exportTask getItemProgressInfo:[OASettingsItemType typeName:settingsItem.type] fileName:[item objForKey:@"file_name"]];
        }
        else if (importTask)
        {
            progressInfo = [importTask getItemProgressInfo:[OASettingsItemType typeName:settingsItem.type] fileName:[item objForKey:@"file_name"]];
        }
        if (progressInfo && !progressInfo.finished)
        {
            progressView.progress = progressInfo.value / 100.;
        }
        else
        {
            [cell rightIconVisibility:YES];
            OARemoteFile *remoteConflictItem = [item objForKey:@"remoteConflictItem"];
            if (remoteConflictItem)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_alert"];
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_red);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else
            {
                cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATableViewCellSimple getCellIdentifier]])
    {
        OATableViewCellSimple *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellSimple getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellSimple getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellSimple *) nib[0];
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
    else if ([item.cellType isEqualToString:[OATableViewCellRightIcon getCellIdentifier]])
    {
        OATableViewCellRightIcon *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellRightIcon getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellRightIcon getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellRightIcon *) nib[0];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.selectionStyle = [item objForKey:@"remoteConflictItem"] != nil ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

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
            if ([item objForKey:kCellIconTint])
                cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
            else
                cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);

            [self setupProgress:cell item:item];
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
        [conflictDetailsViewController presentInViewController:self];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OABackupExportListener

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
        if (_delegate)
            [_delegate updateBackupStatus:_backup];
    });
}

- (void)updateCellProgress:(NSString * _Nonnull)fileName type:(NSString * _Nonnull)type {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *arr = [self rowAndIndexForType:type fileName:fileName];
        if (arr)
        {
            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[arr.firstObject integerValue] inSection:1];
            OACustomBasicTableCell *cell = [self.tableView cellForRowAtIndexPath:indPath];
            if (cell)
                [self setupProgress:cell item:arr.lastObject];
            [self.tableView reloadRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    });
}

- (void)onBackupExportItemFinished:(nonnull NSString *)type fileName:(nonnull NSString *)fileName {
    [self updateCellProgress:fileName type:type];
}

- (void)onBackupExportItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName value:(NSInteger)value {
    [self updateCellProgress:fileName type:type];
}

- (void)onBackupExportItemStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    [self updateCellProgress:fileName type:type];
}

- (void)onBackupExportProgressUpdate:(NSInteger)value {
    // TODO: notify main progress
}

- (void)onBackupExportStarted {
    // TODO: notify main progress
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate updateBackupStatus:_backup];
    });
}

// MARK: OAOnDeleteFilesListener

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress {
    [self updateCellProgress:file.name type:file.type];
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *,NSString *> *)errors {
    
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message {
    
}

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files {
    
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    // TODO: implement
//    for (SettingsItem settingsItem : settingsItems) {
//        String fileName = BackupHelper.getItemFileName(settingsItem);
//        Object item = getBackupItem(settingsItem.getType().name(), fileName);
//        if (item != null) {
//            notifyItemChanged(items.indexOf(item));
//        }
//    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate updateBackupStatus:_backup];
    });
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
    [self updateCellProgress:fileName type:type];
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
    [self updateCellProgress:fileName type:type];
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
    [self updateCellProgress:fileName type:type];
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    _backup = backupResult;
    _status = [OABackupStatus getBackupStatus:_backup];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate updateBackupStatus:_backup];
    });
}

- (void)onBackupPreparing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate disableBottomButtons];
    });
}

@end
