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
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASyncBackupTask.h"
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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusNone = -1,
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

@interface OAStatusBackupTableViewController () <OAOnPrepareBackupListener, OAStatusBackupDelegate>

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesType _tableType;
    OATableDataModel *_data;
    NSIndexPath *_lastBackupIndexPath;
    NSInteger _itemsSection;
    
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
}

- (instancetype)initWithTableType:(EOARecentChangesType)type
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _tableType = type;
        _settingsHelper = [OANetworkSettingsHelper sharedInstance];
        _backupHelper = [OABackupHelper sharedInstance];
        [self setupNotificationListeners];
        [_backupHelper addPrepareBackupListener:self];
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
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    [self generateData];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)updateData
{
    [self generateData];
    [self.tableView reloadData];
}

- (NSMutableDictionary<NSString *,NSMutableArray<NSArray *> *> *)sortFilesByType:(NSMutableDictionary<NSString *,NSMutableDictionary *> *)filesByName
{
    NSMutableDictionary<NSString *, NSMutableArray<NSArray *> *> *filesByType = [NSMutableDictionary dictionary];
    [filesByName enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        OALocalFile *l = obj[@"localFile"];
        OARemoteFile *r = obj[@"remoteFile"];
        OASettingsItem *item = l ? l.item : r.item;
        NSString *type = [OASettingsItemType typeName:item.type];
        if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *flItem = (OAFileSettingsItem *)item;
            type = [OAFileSettingsItemFileSubtype getSubtypeName:flItem.subtype];
        }
        if (type)
        {
            NSMutableArray<NSArray *> *arr = filesByType[type];
            if (!arr)
            {
                arr = [NSMutableArray array];
                filesByType[type] = arr;
            }
            [arr addObject:@[key, obj]];
        }
    }];
    for (NSMutableArray<NSArray *> *arr in filesByType.allValues)
    {
        [arr sortUsingComparator:^NSComparisonResult(NSArray * _Nonnull obj1, NSArray * _Nonnull obj2) {
            return [[obj1.firstObject stringValue].lastPathComponent compare:[obj2.firstObject stringValue].lastPathComponent];
        }];
    }
    return filesByType;
}

- (void)generateData
{
    _itemsSection = -1;
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *statusSection = [OATableSectionData sectionData];
    NSString *backupTime = _backupHelper.isBackupPreparing ?
        OALocalizedString(@"checking_progress")
        : [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")]; [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    if ([_settingsHelper isBackupSyncing])
    {
        OATableRowData *progressCell = [OATableRowData rowData];
        [progressCell setCellType:[OATitleIconProgressbarCell getCellIdentifier]];
        [progressCell setKey:@"backupProgress"];
        [progressCell setTitle:[OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]]];
        [progressCell setIconName:@"ic_custom_cloud_upload"];
        [progressCell setIconTint:color_primary_purple];
        [progressCell setObj:@(0.) forKey:@"progress"];
        [statusSection addRow:progressCell];
    }
    else
    {
        OABackupStatus *status = [OABackupStatus getBackupStatus:_backupHelper.backup];
        [statusSection addRowFromDictionary:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellKeyKey: @"lastBackup",
            kCellTitleKey: status.statusTitle,
            kCellDescrKey: backupTime,
            kCellIconNameKey: status.statusIconName,
            kCellIconTint: @(status.iconColor)
        }];
    }
    [_data addSection:statusSection];
    _lastBackupIndexPath = [NSIndexPath indexPathForRow:statusSection.rowCount - 1 inSection:_data.sectionCount - 1];
    
    OATableSectionData *itemsSection = [OATableSectionData sectionData];
    OABackupInfo *info = _backupHelper.backup.backupInfo;

    if (_tableType == EOARecentChangesLocal || _tableType == EOARecentChangesRemote)
    {
        NSMutableDictionary<NSString *, NSMutableDictionary *> *filesByName =  [NSMutableDictionary dictionary];
        if (_tableType == EOARecentChangesLocal)
        {
            NSArray<OALocalFile *> *localFiles = info.filteredFilesToUpload;
            for (OALocalFile *localFile in localFiles)
            {
                NSString *key = [localFile getTypeFileName];
                filesByName[key] = [NSMutableDictionary dictionary];
                filesByName[key][@"localFile"] = localFile;
            }
            NSArray<OARemoteFile *> *deletedFiles = info.filteredFilesToDelete;
            for (OARemoteFile *deletedFile in deletedFiles)
            {
                NSString *key = [deletedFile getTypeNamePath];
                filesByName[key] = [NSMutableDictionary dictionary];
                filesByName[key][@"deleted"] = @(YES);
                filesByName[key][@"remoteFile"] = deletedFile;
            }
            if (filesByName.count > 0)
            {
                NSDictionary<OARemoteFile *, OASettingsItem *> *downloadItems = [OABackupHelper getItemsMapForRestore:info settingsItems:_backupHelper.backup.settingsItems];
                for (OARemoteFile *remoteFile in downloadItems.allKeys)
                {
                    NSString *key = [remoteFile getTypeNamePath];
                    if ([filesByName.allKeys containsObject:key] && ![filesByName[key].allKeys containsObject:@"remoteFile"])
                        filesByName[key][@"remoteFile"] = remoteFile;
                }
                for (NSString *key in filesByName.allKeys)
                {
                    if (![filesByName[key].allKeys containsObject:@"remoteFile"])
                    {
                        OARemoteFile *remoteFile = _backupHelper.backup.remoteFiles[key];
                        if (remoteFile)
                            filesByName[key][@"remoteFile"] = remoteFile;
                    }
                }
            }
        }
        else if (_tableType == EOARecentChangesRemote)
        {
            NSDictionary<OARemoteFile *, OASettingsItem *> *downloadItems = [OABackupHelper getItemsMapForRestore:info settingsItems:_backupHelper.backup.settingsItems];
            for (OARemoteFile *remoteFile in downloadItems.allKeys)
            {
                NSString *key = [remoteFile getTypeNamePath];
                filesByName[key] = [NSMutableDictionary dictionary];
                filesByName[key][@"remoteFile"] = remoteFile;
            }
            NSArray<OALocalFile *> *deletedFiles = info.localFilesToDelete;
            for (OALocalFile *deletedFile in deletedFiles)
            {
                NSString *key = [deletedFile getTypeFileName];
                filesByName[key] = [NSMutableDictionary dictionary];
                filesByName[key][@"deleted"] = @(YES);
                filesByName[key][@"localFile"] = deletedFile;
            }
            if (filesByName.count > 0)
            {
                NSArray<OALocalFile *> *localFiles = info.filteredFilesToUpload;
                for (OALocalFile *localFile in localFiles)
                {
                    NSString *key = [localFile getTypeFileName];
                    if ([filesByName.allKeys containsObject:key] && ![filesByName[key].allKeys containsObject:@"localFile"])
                        filesByName[key][@"localFile"] = localFile;
                }
                for (NSString *key in filesByName.allKeys)
                {
                    if (![filesByName[key].allKeys containsObject:@"localFile"])
                    {
                        OALocalFile *localFile = _backupHelper.backup.localFiles[key];
                        if (localFile)
                            filesByName[key][@"localFile"] = localFile;
                    }
                }
            }
        }
        NSMutableDictionary<NSString *,NSMutableArray<NSArray *> *> * filesByType = [self sortFilesByType:filesByName];
        [filesByType enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<NSArray *> * _Nonnull obj, BOOL * _Nonnull stop) {
            for (NSArray *it in obj)
            {
                BOOL deleted = [it.lastObject[@"deleted"] boolValue];
                EOABackupSyncOperationType operation = deleted ? EOABackupSyncOperationDelete
                    : _tableType == EOARecentChangesLocal ? EOABackupSyncOperationUpload : EOABackupSyncOperationDownload;
                [itemsSection addRow:[self rowFromKey:it.firstObject
                                             mainTint:deleted ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled]
                                        secondaryTint:deleted ? color_primary_red : color_primary_purple
                                            operation:operation
                                            localFile:it.lastObject[@"localFile"]
                                           remoteFile:it.lastObject[@"remoteFile"]]];
            }
        }];
    }
    else if (_tableType == EOARecentChangesConflicts)
    {
        for (NSArray *items in info.filteredFilesToMerge)
        {
            NSString *key = [((OALocalFile *) items.firstObject) getTypeFileName];
            [itemsSection addRow:[self rowFromConflictItems:key
                                                  localFile:items.firstObject
                                                 remoteFile:items.lastObject]];
        }
    }

    if (itemsSection.rowCount == 0)
    {
        [itemsSection addRowFromDictionary:@{
            kCellTypeKey: [OALargeImageTitleDescrTableViewCell getCellIdentifier],
            kCellKeyKey: @"epmtyState",
            kCellTitleKey: [self getLocalizedEmptyStateHeader],
            kCellDescrKey: OALocalizedString(@"cloud_all_changes_uploaded_descr"),
            kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
        }];
    }

    if (![_backupHelper isBackupPreparing])
    {
        _itemsSection = _data.sectionCount;
        [_data addSection:itemsSection];
    }
    if (_itemsSection != -1 && _tableType == EOARecentChangesConflicts && itemsSection.rowCount > 1)
        [_data sectionDataForIndex:_itemsSection].headerText = OALocalizedString(@"backup_conflicts_descr");
}

- (BOOL) hasItems
{
    switch (_tableType)
    {
        case EOARecentChangesRemote:
            return [OABackupHelper getItemsMapForRestore:_backupHelper.backup.backupInfo settingsItems:_backupHelper.backup.settingsItems].count > 0;
        case EOARecentChangesLocal:
            return _backupHelper.backup.backupInfo.filteredFilesToDelete.count + _backupHelper.backup.backupInfo.filteredFilesToUpload.count > 0;
        default:
            return NO;
    }
    
}

- (NSString *) getLocalizedEmptyStateHeader
{
    switch (_tableType)
    {
        case EOARecentChangesLocal:
            return OALocalizedString(@"cloud_all_changes_uploaded");
        case EOARecentChangesRemote:
            return OALocalizedString(@"cloud_all_changes_downloaded");
        case EOARecentChangesConflicts:
            return OALocalizedString(@"cloud_no_conflicts");
        default:
            return @"";
    }
}

- (OATableRowData *)rowFromConflictItems:(NSString *)key
                               localFile:(OALocalFile *)localFile
                              remoteFile:(OARemoteFile *)remoteFile
{
    OATableRowData *rowData = [self rowFromKey:key
                                      mainTint:[UIColor colorNamed:ACColorNameIconColorDisabled]
                                 secondaryTint:color_tint_gray
                                     operation:EOABackupSyncOperationNone
                                     localFile:localFile
                                    remoteFile:remoteFile];
    NSString *conflictStr = [OALocalizedString(@"cloud_conflict") stringByAppendingString:@". "];
    NSMutableAttributedString *attributedDescr = [[NSMutableAttributedString alloc] initWithString:[conflictStr stringByAppendingString:rowData.descr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:13 weight:UIFontWeightMedium],
                                      NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive] }
                             range:[attributedDescr.string rangeOfString:conflictStr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
                                      NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary] }
                             range:[attributedDescr.string rangeOfString:rowData.descr]];
    [rowData setObj:attributedDescr forKey:@"descrAttr"];
    [rowData setObj:@"ic_custom_alert" forKey:@"secondaryIconConflict"];
    [rowData setObj:@(color_primary_red) forKey:@"secondaryIconColor"];
    [rowData setIconTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    return rowData;
}

- (OATableRowData *)rowFromKey:(NSString *)key
                      mainTint:(UIColor *)mainTint
                 secondaryTint:(NSInteger)secondaryTint
                     operation:(EOABackupSyncOperationType)operation
                     localFile:(OALocalFile *)localFile
                    remoteFile:(OARemoteFile *)remoteFile
{
    OASettingsItem *settingsItem = nil;
    if (_tableType == EOARecentChangesLocal)
    {
        settingsItem = localFile.item;
        if (!settingsItem)
            settingsItem = remoteFile.item;
    }
    else
    {
        settingsItem = remoteFile.item;
        if (!settingsItem)
            settingsItem = localFile.item;
    }

    NSString *name = @"";
    if ([settingsItem isKindOfClass:OAProfileSettingsItem.class])
    {
        name = [((OAProfileSettingsItem *) settingsItem).appMode toHumanString];
    }
    else
    {
        name = [settingsItem getPublicName];
        if ([settingsItem isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *fileItem = (OAFileSettingsItem *) settingsItem;
            if (fileItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
                name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts_title")];
            else if (fileItem.subtype == EOASettingsItemFileSubtypeVoice)
                name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"shared_string_recorded")];
        }
        else if (!name)
        {
            name = OALocalizedString(@"res_unknown");
        }
    }

    long timeMs = 0;
    if (_tableType == EOARecentChangesLocal && operation == EOABackupSyncOperationDelete)
        timeMs = remoteFile.clienttimems;
    else if (_tableType == EOARecentChangesLocal || _tableType == EOARecentChangesConflicts)
        timeMs = localFile.localModifiedTime * 1000;
    else if (operation == EOABackupSyncOperationDelete)
        timeMs = localFile.uploadTime;
    else
        timeMs = remoteFile.updatetimems;

    NSString *description = [self generateTimeString:timeMs
                                             summary:[self localizedSummaryForOperation:operation
                                                                              localFile:localFile
                                                                             remoteFile:remoteFile]];

    NSMutableString *fileName = [NSMutableString string];
    NSArray<NSString *> *pathComponents = key.pathComponents;
    if (pathComponents.count > 2)
    {
        for (int i = 1; i < pathComponents.count; i++)
        {
            [fileName appendString:pathComponents[i]];
            if (i < pathComponents.count - 1)
                [fileName appendString:@"/"];
        }
    }
    else
    {
        [fileName appendString:key.lastPathComponent];
    }
    OATableRowData *rowData = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey: name,
        kCellDescrKey: description,
        kCellIconTintColor: mainTint,
        @"secondaryIconColor": @(secondaryTint),
        @"operation": @(operation),
        @"fileName": fileName,
        @"settingsItem": settingsItem
    }];
    [self setRowIcon:rowData item:settingsItem];

    if (localFile)
        [rowData setObj:localFile forKey:@"localFile"];
    if (remoteFile)
        [rowData setObj:remoteFile forKey:@"remoteFile"];

    return rowData;
}

- (NSString *)localizedSummaryForOperation:(EOABackupSyncOperationType)operation
                                 localFile:(OALocalFile *)localFile
                                remoteFile:(OARemoteFile *)remoteFile
{
    switch (operation)
    {
        case EOABackupSyncOperationDownload:
            return OALocalizedString(localFile ? @"shared_string_modified" : @"shared_string_added");
        case EOABackupSyncOperationUpload:
            return OALocalizedString(remoteFile ? @"shared_string_modified" : @"shared_string_added");
        case EOABackupSyncOperationDelete:
            return OALocalizedString(@"poi_remove_success");
        default:
            return OALocalizedString(@"shared_string_modified");
    }
}

- (NSArray *) rowAndIndexForType:(NSString *)type fileName:(NSString *)fileName
{
    if (_itemsSection == -1)
        return nil;
    EOASettingsItemType intType = [OASettingsItemType parseType:type];
    OATableSectionData *section = [_data sectionDataForIndex:_itemsSection];
    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableRowData *row = [section getRow:i];
        OASettingsItem *item = [row objForKey:@"settingsItem"];
        if (item.type == intType && [[row objForKey:@"fileName"] isEqualToString:fileName])
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
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[rowIndex.lastObject integerValue] inSection:_itemsSection];
            OATableRowData *item = [_data itemForIndexPath:indexPath];
            [item setObj:@(itemProgressType) forKey:@"progressType"];
            [item setObj:@(value) forKey:@"progressValue"];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath])
            {
                OARightIconTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell)
                {
                    if (itemProgressType == EOAItemStatusInProgressType)
                    	[self updateProgressCell:cell indexPath:indexPath item:item];
                    else
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
        }
    });
}

- (void) updateProgressCell:(OARightIconTableViewCell *)cell indexPath:(NSIndexPath *)indexPath item:(OATableRowData *)item
{
    if (![item objForKey:@"progressType"])
    {
        cell.accessoryView = nil;
        return;
    }

    EOAItemStatusType itemProgressType = (EOAItemStatusType)[item integerForKey:@"progressType"];
    NSInteger value = [item integerForKey:@"progressValue"];

    BOOL hasConflict = (EOABackupSyncOperationType) [item integerForKey:@"operation"] == EOABackupSyncOperationNone;
    [cell rightIconVisibility:hasConflict];
    FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
    if (!progressView && itemProgressType != EOAItemStatusFinishedType)
    {
        progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
        progressView.iconView = [[UIView alloc] init];
        progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.accessoryView = progressView;
    }

    if (itemProgressType == EOAItemStatusStartedType)
    {
        progressView.iconPath = [UIBezierPath bezierPath];
        progressView.progress = 0.;
        if (!progressView.isSpinning)
            [progressView startSpinProgressBackgroundLayer];
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
        if (progressView)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            progressView.progress = 0.;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
        [cell rightIconVisibility:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [item setIconTint:color_primary_purple];
        [item setObj:hasConflict ? @(color_primary_red) : @(color_primary_purple) forKey:@"secondaryIconColor"];
        cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
        cell.accessoryView = nil;
    }
}

// MARK: OAStatusBackupDelegate

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
        OAExportSettingsType *type = [OAExportSettingsType findBySettingsItem:item];
        if (type != nil)
            [rowData setObj:type.icon forKey:@"icon"];
    }
}

- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary
{
    if (timeMs != -1)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(timeMs / 1000)
                                                               def:OALocalizedString(@"shared_string_never")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), summary, time];
    }
    else
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), summary, OALocalizedString(@"shared_string_never")];
    }
}

- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary
{
    OAUploadedFileInfo *info = [[OABackupDbHelper sharedDatabase] getUploadedFileInfo:[OASettingsItemType typeName:type] name:fileName];
    return [self generateTimeString:info.uploadTime summary:summary];
}

- (void (^_Nonnull)(NSString * _Nonnull message, NSString * _Nonnull details))showErrorToast
{
    return ^(NSString *message, NSString *details) {
        [OAUtilities showToast:message details:details duration:4 inView:self.view];
    };
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
    OATableRowData *item = [_data itemForIndexPath:indexPath];
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
            BOOL hasConflict = (EOABackupSyncOperationType) [item integerForKey:@"operation"] == EOABackupSyncOperationNone;
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            NSString *description = item.descr;
            NSAttributedString *descriptionAttributed = [item objForKey:@"descrAttr"];
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
            cell.leftIconView.image = [[item objForKey:@"icon"] imageFlippedForRightToLeftLayoutDirection];
            cell.leftIconView.tintColor = item.iconTintColor;

            NSString *secondaryIconName = hasConflict ? [item stringForKey:@"secondaryIconConflict"] : item.secondaryIconName;
            if (secondaryIconName.length > 0)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:secondaryIconName];
                cell.rightIconView.tintColor = UIColorFromRGB([item integerForKey:@"secondaryIconColor"]);
                [cell rightIconVisibility:YES];
            }
            else
            {
                cell.rightIconView.image = nil;
                [cell rightIconVisibility:NO];
            }

            [self updateProgressCell:cell indexPath:indexPath item:item];
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
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:item.descr];
            NSRange range = NSMakeRange(0, str.length);
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 4;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            [str addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
            [str addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:range];
            [str addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:range];
            cell.descriptionLabel.attributedText = str;
            [cell.cellImageView setImage:[UIImage rtlImageNamed:item.iconName]];

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
            [cell.progressBar setProgressTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
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
        customHeader.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
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
                                                     font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]] + 15.;
        }
        return kHeaderHeightDefault;
    }
    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    EOAItemStatusType itemProgressType = EOAItemStatusNone;
    if ([item objForKey:@"progressType"])
        itemProgressType = (EOAItemStatusType)[item integerForKey:@"progressType"];

    if ([item objForKey:@"settingsItem"] && [item objForKey:@"operation"] && itemProgressType == EOAItemStatusNone && ![self isSyncing:item])
    {
        OAStatusBackupConflictDetailsViewController *statusDetailsViewController =
        [[OAStatusBackupConflictDetailsViewController alloc] initWithLocalFile:[item objForKey:@"localFile"]
                                                                    remoteFile:[item objForKey:@"remoteFile"]
                                                                     operation:(EOABackupSyncOperationType) [item integerForKey:@"operation"]
                                                             recentChangesType:_tableType];
        statusDetailsViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:statusDetailsViewController];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL) isSyncing:(OATableRowData *)item
{
    NSString *fileName = [item stringForKey:@"fileName"];
    if (!fileName)
        return NO;

    OASyncBackupTask *syncTask = [_settingsHelper getSyncTask:fileName];
    if (!syncTask)
        syncTask = [_settingsHelper getSyncTask:kSyncItemsKey];

    return syncTask != nil;
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
    });
}

- (void)onBackupPreparing
{
}

// MARK: Sync callbacks

- (void)onBackupFinished:(NSNotification *)notification
{
}

- (void)onBackupStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
    });
}

- (void)onBackupProgressUpdate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float value = [notification.userInfo[@"progress"] floatValue];
        NSIndexPath *progressIdxPath = [NSIndexPath indexPathForRow:0 inSection:0];
        OATableRowData *row = [_data itemForIndexPath:progressIdxPath];
        if (row && [row.key isEqualToString:@"backupProgress"])
        {
            [row setObj:@(value) forKey:@"progress"];
            [row setTitle:[OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (value * 100)]]];
            OATitleIconProgressbarCell *cell = (OATitleIconProgressbarCell *) [self.tableView cellForRowAtIndexPath:progressIdxPath];
            if (cell)
            {
                cell.progressBar.progress = value;
                cell.textView.text = row.title;
            }
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
