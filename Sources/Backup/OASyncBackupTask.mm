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
#import "OABackupInfo.h"
#import "OARemoteFile.h"
#import "OsmAndApp.h"

#include <OsmAndCore/ResourcesManager.h>

@interface OASyncBackupTask () <OABackupCollectListener, OAOnPrepareBackupListener, OACheckDuplicatesListener, OAImportListener, OABackupExportListener>

@end

@implementation OASyncBackupTask
{
    OABackupHelper *_backupHelper;
    NSArray<OASettingsItem *> *_settingsItems;
    NSInteger _maxProgress;
    NSInteger _lastProgress;
    NSInteger _currentProgress;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backupHelper = OABackupHelper.sharedInstance;
        [_backupHelper addPrepareBackupListener:self];
        _currentProgress = 0;
        _lastProgress = 0;
        _maxProgress = 0;
    }
    return self;
}

- (void)dealloc
{
    [_backupHelper removePrepareBackupListener:self];
}

- (void)execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        OANetworkSettingsHelper.sharedInstance.syncBackupTask = self;
        if (!_backupHelper.isBackupPreparing)
            [self collectAndReadSettings];
        
        [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncStartedNotification object:nil];
    });
}

- (void) collectAndReadSettings
{
    @try
    {
        [OANetworkSettingsHelper.sharedInstance collectSettings:kRestoreItemsKey readData:YES listener:self];
    }
    @catch (NSException *e)
    {
        NSLog(@"Restore backup error: %@", e.reason);
    }
}

- (void) uploadNewItems
{
    @try
    {
        OABackupInfo *info = _backupHelper.backup.backupInfo;
        NSArray<OASettingsItem *> *items = info.itemsToUpload;
        if (items.count > 0 || info.filteredFilesToDelete.count > 0)
        {
            [OANetworkSettingsHelper.sharedInstance exportSettings:kBackupItemsKey items:items itemsToDelete:info.itemsToDelete listener:self];
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"Backup generation error: %@", e.reason);
    }
}

// MARK: OABackupCollectListener

- (void)onBackupCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
{
    if (succeed)
    {
        OAPrepareBackupResult *backup = _backupHelper.backup;
        OABackupInfo *info = backup.backupInfo;
        NSMutableSet<OASettingsItem *> *itemsForRestore = [NSMutableSet set];
        if (info != nil)
        {
            for (OARemoteFile *remoteFile in info.filesToDownload)
            {
                OASettingsItem *restoreItem = [self getRestoreItem:items remoteFile:remoteFile];
                if (restoreItem != nil)
                    [itemsForRestore addObject:restoreItem];
            }
        }
        _settingsItems = itemsForRestore.allObjects;
        _maxProgress += [OAImportBackupTask calculateMaxProgress];
        _maxProgress += ([self calculateExportMaxProgress] / 1024);
        
        if (_settingsItems.count > 0)
        {
            [OANetworkSettingsHelper.sharedInstance checkDuplicates:kRestoreItemsKey items:_settingsItems selectedItems:_settingsItems listener:self];
        }
        else
        {
            [self uploadNewItems];
        }
    }
    else
    {
        [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncFinishedNotification object:nil userInfo:nil];
    }
}

- (NSInteger) calculateExportMaxProgress
{
    OABackupInfo *info = _backupHelper.backup.backupInfo;
    NSMutableArray<OASettingsItem *> *oldItemsToDelete = [NSMutableArray array];
    for (OASettingsItem *item in info.itemsToUpload)
    {
        OAExportSettingsType *exportType = [OAExportSettingsType getExportSettingsTypeForItem:item];
        if (exportType && [_backupHelper getVersionHistoryTypePref:exportType].get)
        {
            [oldItemsToDelete addObject:item];
        }
    }
    return [OAExportBackupTask getEstimatedItemsSize:info.itemsToUpload itemsToDelete:info.itemsToDelete oldItemsToDelete:oldItemsToDelete];;
    
}

- (OASettingsItem *) getRestoreItem:(NSArray<OASettingsItem *> *)items remoteFile:(OARemoteFile *)remoteFile
{
    for (OASettingsItem *item in items)
    {
        if ([OABackupHelper applyItem:item type:remoteFile.type name:remoteFile.name])
            return item;
    }
    return nil;
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    [self collectAndReadSettings];
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncStartedNotification object:nil];
}

- (void)onBackupPreparing {
    
}

// MARK: OACheckDuplicatesListener

- (void)onDuplicatesChecked:(NSArray *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    NSMutableArray<OASettingsItem *> *filteredItems = [NSMutableArray arrayWithArray:items];
    [filteredItems removeObjectsInArray:duplicates];
    @try {
        [OANetworkSettingsHelper.sharedInstance importSettings:kRestoreItemsKey items:filteredItems forceReadData:NO listener:self];
    } @catch (NSException *e) {
        NSLog(@"Restore backup import error: %@", e.reason);
    }
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items
{
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
    _currentProgress = uploadedKb;
    float progress = (float) _currentProgress / _maxProgress;
    progress = progress > 1 ? 1 : progress;
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupProgressUpdateNotification object:nil userInfo:@{@"progress": @(progress)}];
}

// MARK: OABackupExportListener

- (void)onBackupExportFinished:(NSString *)error
{
    NSDictionary *info = nil;
    if (error)
        info = @{@"error": error};
    OANetworkSettingsHelper.sharedInstance.syncBackupTask = nil;
    [NSNotificationCenter.defaultCenter postNotificationName:kBackupSyncFinishedNotification object:nil userInfo:info];
}

- (void)onBackupExportProgressUpdate:(NSInteger)value
{
    OAExportBackupTask *exportTask = [OANetworkSettingsHelper.sharedInstance getExportTask:kBackupItemsKey];
    _currentProgress += exportTask.generalProgress - _lastProgress;
    float progress = (float) _currentProgress / _maxProgress;
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
