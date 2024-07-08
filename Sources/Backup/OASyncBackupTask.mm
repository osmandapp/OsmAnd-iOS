//
//  OASyncBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 07.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASyncBackupTask.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"
#import "OAExportBackupTask.h"
#import "OAImportBackupTask.h"
#import "OAExportSettingsType.h"
#import "OABackupHelper.h"
#import "OASettingsItem.h"
#import "OABackupInfo.h"
#import "OARemoteFile.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

#include <OsmAndCore/ResourcesManager.h>

@interface OASyncBackupTask () <OAOnPrepareBackupListener, OAImportListener, OABackupExportListener>

@end

@implementation OASyncBackupTask
{
    NSString *_key;
    OABackupHelper *_backupHelper;
    NSArray<OASettingsItem *> *_settingsItems;
    NSInteger _maxProgress;
    NSInteger _importProgress;
    NSInteger _exportProgress;
    NSInteger _lastProgress;
    
    EOABackupSyncOperationType _operation;
    BOOL _cancelled;
    BOOL _singleOperation;
}

- (instancetype)initWithKey:(NSString *)key operation:(EOABackupSyncOperationType)operation
{
    self = [super init];
    if (self) {
        _key = key;
        _operation = operation;
        _singleOperation = operation != EOABackupSyncOperationSync;
        _backupHelper = OABackupHelper.sharedInstance;
        if (!_singleOperation)
        	[_backupHelper addPrepareBackupListener:self];

        _importProgress = 0;
        _exportProgress = 0;
        _maxProgress = 0;
        _cancelled = NO;
    }
    return self;
}

- (void)dealloc
{
    [_backupHelper removePrepareBackupListener:self];
}

- (NSInteger) getGeneralProgress
{
    return _importProgress + _exportProgress;
}

- (void)startSync
{
    OAPrepareBackupResult *backup = _backupHelper.backup;
    OABackupInfo *info = backup.backupInfo;
    
    _settingsItems = [OABackupHelper getItemsForRestore:info settingsItems:backup.settingsItems];
    if (_operation != EOABackupSyncOperationDownload)
        _maxProgress += ([self calculateExportMaxProgress] / 1024);
    if (_operation != EOABackupSyncOperationUpload)
        _maxProgress += [OAImportBackupTask calculateMaxProgress];
    
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncStartedNotification object:nil];
    if (_settingsItems.count > 0 && _operation != EOABackupSyncOperationUpload)
    {
        [OANetworkSettingsHelper.sharedInstance importSettings:kRestoreItemsKey items:_settingsItems filesType:EOARemoteFilesTypeUnique forceReadData:YES listener:self];
    }
    else if (_operation != EOABackupSyncOperationDownload)
    {
        [self uploadNewItems];
    }
    else
    {
        [self onSyncFinished:nil];
    }
}

- (void)execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (!_backupHelper.isBackupPreparing)
            [self startSync];
    });
}

- (void)uploadLocalItem:(OASettingsItem *)item
{
    [OANetworkSettingsHelper.sharedInstance exportSettings:[OABackupHelper getItemFileName:item] items:@[item] itemsToDelete:@[] localItemsToDelete:@[] listener:self];
}

- (void)downloadRemoteVersion:(OASettingsItem *)item
                    filesType:(EOARemoteFilesType)filesType
                shouldReplace:(BOOL)shouldReplace
               restoreDeleted:(BOOL)restoreDeleted
{
    [item setShouldReplace:shouldReplace];
    [OANetworkSettingsHelper.sharedInstance importSettings:[OABackupHelper getItemFileName:item] items:@[item] filesType:filesType forceReadData:YES shouldReplace:shouldReplace restoreDeleted:restoreDeleted listener:self];
}

- (void) deleteItem:(OASettingsItem *)item
{
    [OANetworkSettingsHelper.sharedInstance exportSettings:[OABackupHelper getItemFileName:item] items:@[] itemsToDelete:@[item] localItemsToDelete:@[] listener:self];
}

- (void) deleteLocalItem:(OASettingsItem *)item
{
    [OANetworkSettingsHelper.sharedInstance exportSettings:[OABackupHelper getItemFileName:item] items:@[] itemsToDelete:@[] localItemsToDelete:@[item] listener:self];
}

- (void)cancel
{
    _cancelled = YES;
    [self onSyncFinished:nil];
}

- (void) uploadNewItems
{
    if (_cancelled)
        return;
    @try
    {
        OABackupInfo *info = _backupHelper.backup.backupInfo;
        NSArray<OASettingsItem *> *itemsToUpload = info.itemsToUpload;
        NSArray<OASettingsItem *> *itemsToDelete = info.itemsToDelete;
        NSArray<OASettingsItem *> *localItemsToDelete = info.localItemsToDelete;
        if (itemsToUpload.count > 0 || itemsToDelete.count > 0 || localItemsToDelete.count > 0)
        {
            [OANetworkSettingsHelper.sharedInstance exportSettings:kBackupItemsKey items:itemsToUpload itemsToDelete:itemsToDelete localItemsToDelete:localItemsToDelete listener:self];
        }
        else
        {
            [self onSyncFinished:nil];
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"Backup generation error: %@", e.reason);
    }
}

- (NSInteger) calculateExportMaxProgress
{
    OABackupInfo *info = _backupHelper.backup.backupInfo;
    if (info)
    {
        NSMutableArray<OASettingsItem *> *oldItemsToDelete = [NSMutableArray array];
        for (OASettingsItem *item in info.itemsToUpload)
        {
            OAExportSettingsType *exportType = [OAExportSettingsType findBySettingsItem:item];
            if (exportType && [_backupHelper getVersionHistoryTypePref:exportType].get)
            {
                [oldItemsToDelete addObject:item];
            }
        }
        return [OAExportBackupTask getEstimatedItemsSize:info.itemsToUpload itemsToDelete:info.itemsToDelete localItemsToDelete:info.localItemsToDelete oldItemsToDelete:oldItemsToDelete];
    }
    return 0;
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    [self startSync];
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncStartedNotification object:nil];
}

- (void)onBackupPreparing {
    
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items
{
    if (_cancelled)
        return;
    if (succeed)
    {
        OsmAndAppInstance app = OsmAndApp.instance;
        app.resourcesManager->rescanUnmanagedStoragePaths();
        [app.localResourcesChangedObservable notifyEvent];
        [app loadRoutingFiles];
//        reloadIndexes(items);
//        AudioVideoNotesPlugin plugin = OsmandPlugin.getPlugin(AudioVideoNotesPlugin.class);
//        if (plugin != null) {
//            plugin.indexingFiles(true, true);
//        }
    }
    if (_singleOperation)
        return [self onSyncFinished:nil];
    [self uploadNewItems];
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName
{
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupItemFinishedNotification object:nil userInfo:@{@"type": type, @"name": fileName}];
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value
{
    [NSNotificationCenter.defaultCenter  postNotificationName:kBackupItemProgressNotification object:nil userInfo:@{@"type": type, @"name": fileName, @"value": @(value)}];
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work
{
    [NSNotificationCenter.defaultCenter  postNotificationName:kBackupItemStartedNotification object:nil userInfo:@{@"type": type, @"name": fileName, @"work": @(work)}];
}

- (void)onImportProgressUpdate:(NSInteger)value uploadedKb:(NSInteger)uploadedKb
{
    _importProgress = uploadedKb;
    float progress = (float) self.getGeneralProgress / _maxProgress;
    progress = progress > 1 ? 1 : progress;
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupProgressUpdateNotification object:nil userInfo:@{@"progress": @(progress)}];
}

- (void)onSyncFinished:(NSDictionary *)info
{
    [OANetworkSettingsHelper.sharedInstance.syncBackupTasks removeObjectForKey:_key];
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncFinishedNotification object:nil userInfo:info];
}

// MARK: OABackupExportListener

- (void)onBackupExportFinished:(NSString *)error
{
    NSDictionary *info = nil;
    if (error)
        info = @{@"error": error};
    [self onSyncFinished:info];
}

- (void)onBackupExportProgressUpdate:(NSInteger)value
{
    OAExportBackupTask *exportTask = [OANetworkSettingsHelper.sharedInstance getExportTask:kBackupItemsKey];
    _exportProgress += exportTask.generalProgress - _lastProgress;
    float progress = (float) self.getGeneralProgress / _maxProgress;
    progress = progress > 1 ? 1 : progress;
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupProgressUpdateNotification object:nil userInfo:@{@"progress": @(progress)}];
    _lastProgress = exportTask.generalProgress;
}

- (void)onBackupExportItemFinished:(NSString *)type fileName:(NSString *)fileName
{
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupItemFinishedNotification object:nil userInfo:@{@"type": type, @"name": fileName}];
}

- (void)onBackupExportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(NSInteger)value
{
    [NSNotificationCenter.defaultCenter  postNotificationName:kBackupItemProgressNotification object:nil userInfo:@{@"type": type, @"name": fileName, @"value": @(value)}];
}

- (void)onBackupExportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work
{
    [NSNotificationCenter.defaultCenter  postNotificationName:kBackupItemStartedNotification object:nil userInfo:@{@"type": type, @"name": fileName, @"work": @(work)}];
}

- (void)onBackupExportStarted {
}

@end
