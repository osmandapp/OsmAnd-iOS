//
//  OACloudRecentChangesTableViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupTableViewController.h"
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
#import "OARemoteFile.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OAMultiIconTextDescCell.h"
#import "OACustomBasicTableCell.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OANetworkSettingsHelper.h"
#import "OAImportBackupTask.h"
#import "OAExportBackupTask.h"

@interface OAStatusBackupTableViewController () <OABackupExportListener, OAOnDeleteFilesListener, OAImportListener>

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesTable _tableType;
    OATableViewDataModel *_data;
    
    OABackupStatus *_status;
    OAPrepareBackupResult *_backup;
    
    OANetworkSettingsHelper *_settingsHelper;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    [self generateData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_settingsHelper updateExportListener:self];
    [_settingsHelper updateImportListener:self];
    [OABackupHelper.sharedInstance.backupListeners addDeleteFilesListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_settingsHelper updateExportListener:nil];
    [_settingsHelper updateImportListener:nil];
    [OABackupHelper.sharedInstance.backupListeners removeDeleteFilesListener:self];
}

- (void)generateData
{
    _data = [[OATableViewDataModel alloc] init];
    OATableViewSectionData *statusSection = [OATableViewSectionData sectionData];
    NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    [statusSection addRowFromDictionary:@{
        kCellTypeKey: OAMultiIconTextDescCell.getCellIdentifier,
        kCellKeyKey: @"lastBackup",
        kCellTitleKey: _status.statusTitle,
        kCellDescrKey: backupTime,
        kCellIconNameKey: _status.statusIconName
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
    [_data addSection:itemsSection];
}

- (OATableViewRowData *) rowFromItem:(OASettingsItem *)item toDelete:(BOOL)toDelete
{
    OATableViewRowData *rowData = [OATableViewRowData rowData];
    [rowData setCellType:OACustomBasicTableCell.getCellIdentifier];
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
    NSString *summary = OALocalizedString(@"cloud_last_backup");
    OAUploadedFileInfo *info = [OABackupDbHelper.sharedDatabase getUploadedFileInfo:[OASettingsItemType typeName:item.type] name:fileName];
    if (info)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(info.uploadTime / 1000) def:OALocalizedString(@"shared_string_never")];
        [rowData setDescr:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time]];
    }
    else
    {
        [rowData setDescr:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")]];
    }
    [self setRowIcon:rowData item:item];
    [rowData setSecondaryIconName:toDelete ? @"ic_custom_remove" : @"ic_custom_cloud_done"];
    return rowData;
}

- (void) setRowIcon:(OATableViewRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setObj:mode.getIcon forKey:@"icon"];
        [rowData setIconTint:mode.getIconColor];
    }
    OAExportSettingsType *type = [OAExportSettingsType getExportSettingsTypeForItem:item];
    if (type != nil)
    {
        [rowData setObj:type.icon forKey:@"icon"];
    }
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

- (void)setupProgress:(OACustomBasicTableCell *)cell item:(OATableViewRowData *)item
{
    OAImportBackupTask *importTask = [_settingsHelper getImportTask:kBackupItemsKey];
    OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
    if (!importTask && !exportTask)
    {
        [cell rightIconVisibility:YES];
        cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
        cell.accessoryView = nil;
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
            progressView.progress = progressInfo.value / progressInfo.work;
        }
        else
        {
            [cell rightIconVisibility:YES];
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
            cell.accessoryView = nil;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:OAMultiIconTextDescCell.getCellIdentifier])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:OAMultiIconTextDescCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(nav_bar_day);
            [cell setOverflowVisibility:YES];
        }
        cell.textView.text = item.title;
        cell.descView.text = item.descr;
        [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        return cell;
    }
    else if ([item.cellType isEqualToString:OACustomBasicTableCell.getCellIdentifier])
    {
        OACustomBasicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomBasicTableCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomBasicTableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomBasicTableCell *) nib[0];
            [cell switchVisibility:NO];
            [cell valueVisibility:NO];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [item objForKey:@"icon"];
            if ([item objForKey:kCellIconTint])
                cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
            else
                cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            
            [self setupProgress:cell item:item];
            
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

// MARK: OABackupExportListener

- (void)onBackupExportFinished:(nonnull NSString *)error {
    
}

- (void)updateCellProgress:(NSString * _Nonnull)fileName type:(NSString * _Nonnull)type {
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSArray *arr = [self rowAndIndexForType:type fileName:fileName];
//        if (arr)
//        {
//            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[arr.firstObject integerValue] inSection:1];
//            OACustomBasicTableCell *cell = [self.tableView cellForRowAtIndexPath:indPath];
//            if (cell)
//                [self setupProgress:cell item:arr.lastObject];
//        }
        [self.tableView reloadData];
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

@end
