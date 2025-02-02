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
#import "OAApplicationMode.h"
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
#import "OASizes.h"
#import "OAResourcesUIHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAStatusBackupTableViewController () <OAOnPrepareBackupListener, OAStatusBackupDelegate>

@end

@interface OAStatusBackupItem : NSObject

@property (nonatomic, assign) BOOL deleted;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) OALocalFile *localFile;
@property (nonatomic, strong) OARemoteFile *remoteFile;
- (instancetype)initWithKey:(NSString *)key;
@end

@implementation OAStatusBackupItem
- (instancetype)initWithKey:(NSString *)key
{
    self = [super init];
    self.key = key;
    return self;
}

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesType _tableType;
    OATableDataModel *_data;
    NSIndexPath *_lastBackupIndexPath;
    NSInteger _itemsSection;
    float _syncProgress;
    NSIndexPath *_syncProgressCell;
    
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
    DownloadingCellCloudHelper *_downloadingCellCloudHelper;
}

- (instancetype)initWithTableType:(EOARecentChangesType)type syncProgress:(float)syncProgress
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _tableType = type;
        _syncProgress = syncProgress;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupDownloadingCellHelper];
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    [self generateData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    if (_downloadingCellCloudHelper)
        [_downloadingCellCloudHelper refreshCellSpinners];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_downloadingCellCloudHelper)
        [_downloadingCellCloudHelper cleanCellCache];
}

- (void)markItemAsInstaled:(NSString *)downloadFinishedResourceId
{
    if ([_data sectionCount] <= 1)
        return;

    OATableSectionData *section = [_data sectionDataForIndex:1];

    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableRowData *row = [section getRow:i];
        
        if (![self shouldMarkRowForOperation:row])
            continue;
        
        OASettingsItem *settingsItem = [row objForKey:@"settingsItem"];
        NSString *type = [OASettingsItemType typeName:settingsItem.type];
        NSString *fileName = [row stringForKey:@"fileName"];
        NSString *resourceId = [_downloadingCellCloudHelper getResourceIdWithTypeName:type filename:fileName];
        if ([downloadFinishedResourceId isEqualToString:resourceId])
        {
            [row setIconTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
        }
    }
}

- (BOOL)shouldMarkRowForOperation:(OATableRowData *)row {
    EOABackupSyncOperationType operationType = (EOABackupSyncOperationType)[row integerForKey:@"operation"];
    return (operationType == EOABackupSyncOperationDownload
            || operationType == EOABackupSyncOperationUpload
            || operationType == EOABackupSyncOperationSync);
}

- (void) setupDownloadingCellHelper
{
    __weak __typeof(self) weakSelf = self;
    _downloadingCellCloudHelper = [[DownloadingCellCloudHelper alloc] init];
    [_downloadingCellCloudHelper setHostTableView:weakSelf.tableView];

    _downloadingCellCloudHelper.rightIconStyle = DownloadingCellRightIconTypeShowShevronBeforeDownloading;
    if (_tableType == EOARecentChangesConflicts)
    {
        _downloadingCellCloudHelper.rightIconStyle = DownloadingCellRightIconTypeShowIconAndShevronAlways;
        _downloadingCellCloudHelper.rightIconName = @"ic_custom_alert";
        _downloadingCellCloudHelper.rightIconColor = [UIColor colorNamed:ACColorNameIconColorDisruptive];
    }
    else
    {
        _downloadingCellCloudHelper.rightIconStyle = DownloadingCellRightIconTypeShowShevronBeforeDownloading;
    }
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)updateData
{
    _syncProgress = 0;
    [self generateData];
    [_downloadingCellCloudHelper cleanCellCache];
    [self.tableView reloadData];
}

- (NSMutableArray<OAStatusBackupItem *> *)sortFilesByType:(NSMutableDictionary<NSString *,OAStatusBackupItem *> *)filesByName
{
    NSMutableArray<OAStatusBackupItem *> * res = [NSMutableArray array];
    for (OAStatusBackupItem *it in filesByName.allValues)
    {
        OASettingsItem *item = it.localFile ? it.localFile.item : it.remoteFile.item;
        NSString *type = [OASettingsItemType typeName:item.type];
        if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *flItem = (OAFileSettingsItem *)item;
            type = [OAFileSettingsItemFileSubtype getSubtypeName:flItem.subtype];
        }
        NSString *visibleName = item.name;
        if ([item isKindOfClass:OAProfileSettingsItem.class]) {
            visibleName = [((OAProfileSettingsItem *) item).appMode toHumanString];
        } else {
            visibleName = [item getPublicName];
        }
        it.name = [type stringByAppendingPathComponent:visibleName];
        [res addObject:it];
    };
    
    [res sortUsingComparator:^NSComparisonResult(OAStatusBackupItem * _Nonnull obj1, OAStatusBackupItem * _Nonnull obj2) {
        return [obj1.name compare:obj2.name];
    }];
    
    return res;
}

- (void)generateData
{
    _syncProgressCell = nil;
    _itemsSection = -1;
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *statusSection = [OATableSectionData sectionData];
    NSString *backupTime = _backupHelper.isBackupPreparing ?
        OALocalizedString(@"checking_progress")
        : [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")]; [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    [_data addSection:statusSection];
    if ([_settingsHelper isBackupSyncing])
    {
        OATableRowData *progressCell = [OATableRowData rowData];
        [progressCell setCellType:[OATitleIconProgressbarCell getCellIdentifier]];
        [progressCell setKey:@"backupProgress"];
        [progressCell setIconName:@"ic_custom_cloud_upload"];
        [progressCell setIconTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
        [statusSection addRow:progressCell];
        _syncProgressCell = [NSIndexPath indexPathForRow:[statusSection rowCount] - 1 inSection:[_data sectionCount] - 1];
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
    _lastBackupIndexPath = [NSIndexPath indexPathForRow:statusSection.rowCount - 1 inSection:_data.sectionCount - 1];
    
    OATableSectionData *itemsSection = [OATableSectionData sectionData];
    OABackupInfo *info = _backupHelper.backup.backupInfo;
    NSString *header = @"";

    if (_tableType == EOARecentChangesLocal || _tableType == EOARecentChangesRemote)
    {
        NSMutableDictionary<NSString *, OAStatusBackupItem* > *filesByName =  [NSMutableDictionary dictionary];
        if (_tableType == EOARecentChangesLocal)
        {
            header = OALocalizedString(@"cloud_recent_changes");

            NSArray<OALocalFile *> *localFiles = info.filteredFilesToUpload;
            for (OALocalFile *localFile in localFiles)
            {
                NSString *key = [localFile getTypeFileName];
                filesByName[key] = [[OAStatusBackupItem alloc] initWithKey:key];
                filesByName[key].localFile = localFile;
            }
            NSArray<OARemoteFile *> *deletedFiles = info.filteredFilesToDelete;
            for (OARemoteFile *deletedFile in deletedFiles)
            {
                NSString *key = [deletedFile getTypeNamePath];
                filesByName[key] = [[OAStatusBackupItem alloc] initWithKey:key];
                filesByName[key].deleted = @(YES);
                filesByName[key].remoteFile = deletedFile;
            }
            if (filesByName.count > 0)
            {
                NSDictionary<OARemoteFile *, OASettingsItem *> *downloadItems = [BackupUtils getItemsMapForRestore:info settingsItems:_backupHelper.backup.settingsItems];
                for (OARemoteFile *remoteFile in downloadItems.allKeys)
                {
                    NSString *key = [remoteFile getTypeNamePath];
                    if ([filesByName.allKeys containsObject:key] && !filesByName[key].remoteFile)
                        filesByName[key].remoteFile = remoteFile;
                }
                for (NSString *key in filesByName.allKeys)
                {
                    if (!filesByName[key].remoteFile)
                    {
                        OARemoteFile *remoteFile = _backupHelper.backup.remoteFiles[key];
                        if (remoteFile)
                            filesByName[key].remoteFile = remoteFile;
                    }
                }
            }
        }
        else if (_tableType == EOARecentChangesRemote)
        {
            header = OALocalizedString(@"download_tab_updates");

            NSDictionary<OARemoteFile *, OASettingsItem *> *downloadItems = [BackupUtils getItemsMapForRestore:info settingsItems:_backupHelper.backup.settingsItems];
            for (OARemoteFile *remoteFile in downloadItems.allKeys)
            {
                NSString *key = [remoteFile getTypeNamePath];
                filesByName[key] = [[OAStatusBackupItem alloc] initWithKey:key];
                filesByName[key].remoteFile = remoteFile;
            }
            NSArray<OALocalFile *> *deletedFiles = info.localFilesToDelete;
            for (OALocalFile *deletedFile in deletedFiles)
            {
                NSString *key = [deletedFile getTypeFileName];
                filesByName[key] = [[OAStatusBackupItem alloc] initWithKey:key];
                filesByName[key].deleted = @(YES);
                filesByName[key].localFile = deletedFile;
            }
            if (filesByName.count > 0)
            {
                NSArray<OALocalFile *> *localFiles = info.filteredFilesToUpload;
                for (OALocalFile *localFile in localFiles)
                {
                    NSString *key = [localFile getTypeFileName];
                    if ([filesByName.allKeys containsObject:key] && !filesByName[key].localFile)
                        filesByName[key].localFile = localFile;
                }
                for (NSString *key in filesByName.allKeys)
                {
                    if (!filesByName[key].localFile)
                    {
                        OALocalFile *localFile = _backupHelper.backup.localFiles[key];
                        if (localFile)
                            filesByName[key].localFile = localFile;
                    }
                }
            }
        }

        NSMutableArray<OAStatusBackupItem *> * sortedFiles = [self sortFilesByType:filesByName];
        for (OAStatusBackupItem *it in sortedFiles)
        {
            EOABackupSyncOperationType operation = it.deleted ? EOABackupSyncOperationDelete
            : _tableType == EOARecentChangesLocal ? EOABackupSyncOperationUpload : EOABackupSyncOperationDownload;
            OATableRowData *rowData = [self rowFromKey:it.key
                                              mainTint:it.deleted ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled]
                                    secondaryColorName:it.deleted ? ACColorNameIconColorDisruptive : ACColorNameIconColorActive
                                             operation:operation
                                             localFile:it.localFile
                                            remoteFile:it.remoteFile];
            if (rowData)
                [itemsSection addRow:rowData];
        }
        
    }
    else if (_tableType == EOARecentChangesConflicts)
    {
        header = OALocalizedString(@"download_tab_conflicts");

        for (NSArray *items in info.filteredFilesToMerge)
        {
            NSString *key = [((OALocalFile *) items.firstObject) getTypeFileName];
            OATableRowData *rowData = [self rowFromConflictItems:key
                                                       localFile:items.firstObject
                                                      remoteFile:items.lastObject];
            if (rowData)
                [itemsSection addRow:rowData];
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
    else
    {
        itemsSection.headerText = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"),
                                   header,
                                   @([itemsSection rowCount]).stringValue];
    }

    if (![_backupHelper isBackupPreparing])
    {
        _itemsSection = _data.sectionCount;
        [_data addSection:itemsSection];
    }
    if (_tableType == EOARecentChangesConflicts && itemsSection.rowCount > 1)
        statusSection.footerText = OALocalizedString(@"backup_conflicts_descr");
}

- (BOOL) hasItems
{
    switch (_tableType)
    {
        case EOARecentChangesRemote:
            return [BackupUtils getItemsMapForRestore:_backupHelper.backup.backupInfo settingsItems:_backupHelper.backup.settingsItems].count > 0;
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
                            secondaryColorName:ACColorNameIconColorDefault
                                     operation:EOABackupSyncOperationNone
                                     localFile:localFile
                                    remoteFile:remoteFile];
    if (!rowData)
        return nil;

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
    [rowData setObj:ACColorNameIconColorDisruptive forKey:@"secondaryIconColorName"];
    [rowData setIconTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    return rowData;
}

- (OATableRowData *)rowFromKey:(NSString *)key
                      mainTint:(UIColor *)mainTint
                 secondaryColorName:(NSString *)secondaryColorName
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
    if (!settingsItem)
        return nil;
    
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
    }
    if (!name)
    {
        name = OALocalizedString(@"res_unknown");
    }
    
    long timeMs = 0;
    if (_tableType == EOARecentChangesLocal && operation == EOABackupSyncOperationDelete)
        timeMs = remoteFile.clienttimems;
    else if (_tableType == EOARecentChangesLocal)
        timeMs = localFile.localModifiedTime;
    else if (_tableType == EOARecentChangesConflicts || operation == EOABackupSyncOperationDelete)
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
        @"secondaryIconColorName": secondaryColorName,
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


// MARK: OAStatusBackupDelegate

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setObj:[UIImage templateImageNamed:[mode getIconName]] forKey:@"icon"];
        [rowData setObj:[mode getIconName] forKey:@"iconName"];
    }
    else
    {
        OAExportSettingsType *type = [OAExportSettingsType findBySettingsItem:item];
        if (type != nil)
        {
            [rowData setObj:type.icon forKey:@"icon"];
            [rowData setObj:type.iconName forKey:@"iconName"];
        }
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
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
        OASettingsItem *settingsItem = [item objForKey:@"settingsItem"];
        NSString *type = [OASettingsItemType typeName:settingsItem.type];
        NSString *resourceId = [_downloadingCellCloudHelper getResourceIdWithTypeName:type filename:[item stringForKey:@"fileName"]];
        DownloadingCell *cell = [_downloadingCellCloudHelper getOrCreateCell:resourceId];
        [_downloadingCellCloudHelper saveResourceIconWithIconName:[item objForKey:@"iconName"] resourceId:resourceId];
        
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
            [cell leftIconVisibility:YES];
            cell.leftIconView.image = [[item objForKey:@"icon"] imageFlippedForRightToLeftLayoutDirection];
            cell.leftIconView.tintColor = item.iconTintColor;

            NSString *secondaryIconName = hasConflict ? [item stringForKey:@"secondaryIconConflict"] : item.secondaryIconName;
            if (secondaryIconName.length > 0)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:secondaryIconName];
                cell.rightIconView.tintColor = [UIColor colorNamed:[item stringForKey:@"secondaryIconColorName"]];
                [cell rightIconVisibility:YES];
            }
            else
            {
                cell.rightIconView.image = nil;
                [cell rightIconVisibility:NO];
            }
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
            [cell.progressBar setProgress:_syncProgress animated:NO];
            NSString* percent = [NSString stringWithFormat:@"%d%%", (int)(_syncProgress * 100)];
            cell.textView.text = [NSString stringWithFormat:OALocalizedString(@"cloud_sync_progress"), percent];
            cell.imageView.image = [UIImage templateImageNamed:item.iconName];
            cell.imageView.tintColor = item.iconTintColor;
        }
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    ItemStatusType itemProgressType = ItemStatusTypeIdle;
    if ([item objForKey:@"progressType"])
        itemProgressType = (ItemStatusType)[item integerForKey:@"progressType"];

    if ([item objForKey:@"settingsItem"] && [item objForKey:@"operation"] && itemProgressType == ItemStatusTypeIdle && ![self isSyncing:item])
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

- (void)onBackupProgressItemFinished:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *type = userInfo[@"type"];
    NSString *name = userInfo[@"name"];
    
    if (!type || !name)
        return;
    
    NSString *resourceId = [type stringByAppendingString:name];
    [self markItemAsInstaled:resourceId];
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
        float value = roundf([notification.userInfo[@"progress"] floatValue] * 100) / 100.0;
        if (fabs(_syncProgress - value) >= 0.01)
        {
            _syncProgress = value;
            if (_syncProgressCell)
            {
                OATableRowData *row = [_data itemForIndexPath:_syncProgressCell];
                if (row && [row.key isEqualToString:@"backupProgress"])
                {
                    OATitleIconProgressbarCell *cell = (OATitleIconProgressbarCell *) [self.tableView cellForRowAtIndexPath:_syncProgressCell];
                    if (cell)
                    {
                        [cell.progressBar setProgress:_syncProgress animated:NO];
                        NSString* percent = [NSString stringWithFormat:@"%d%%", (int)(_syncProgress * 100)];
                        cell.textView.text = [NSString stringWithFormat:OALocalizedString(@"cloud_sync_progress"), percent];
                    }
                }
            }
        }
    });
}

@end
