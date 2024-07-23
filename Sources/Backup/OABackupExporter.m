//
//  OABackupExporter.m
//  OsmAnd Maps
//
//  Created by Paul on 16.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupExporter.h"
#import "OABackupHelper.h"
#import "OASettingsItem.h"
#import "OABackupListeners.h"
#import "OAAbstractWriter.h"
#import "OAAtomicInteger.h"
#import "OANetworkWriter.h"
#import "OAAppSettings.h"
#import "OAPrepareBackupResult.h"
#import "OAExportSettingsType.h"
#import "OAExportBackupTask.h"
#import "OAConcurrentCollections.h"
#import "OARemoteFile.h"
#import "OAOperationLog.h"

#define MAX_LIGHT_ITEM_SIZE 10 * 1024 * 1024

@interface OAItemWriterTask : NSOperation

@property (nonatomic, readonly) NSString *error;

@end

@implementation OAItemWriterTask
{
    OAAbstractWriter *_writer;
    OASettingsItem *_item;
}

- (instancetype) initWithWriter:(OAAbstractWriter *)writer item:(OASettingsItem *)item
{
    self = [super init];
    if (self)
    {
        _writer = writer;
        _item = item;
    }
    return self;
}

- (void)main
{
    @try
    {
        [_writer write:_item];
    }
    @catch (NSException *e)
    {
        _error = e.reason;
    }
}

- (void)cancel
{
    [super cancel];
    [_writer cancel];
}

@end

@interface OABackupExporter () <OAOnUploadItemListener, OAOnDeleteFilesListener>

@end

@implementation OABackupExporter
{
    OABackupHelper *_backupHelper;
    NSMutableArray<OASettingsItem *> *_itemsToDelete;
    NSMutableArray<OASettingsItem *> *_localItemsToDelete;
    NSMutableArray<OASettingsItem *> *_oldItemsToDelete;
    NSOperationQueue *_executor;
    __weak id<OANetworkExportProgressListener> _listener;
    OAConcurrentArray<OARemoteFile *> *_oldFilesToDelete;
    
    OAAtomicInteger *_dataProgress;
    OAConcurrentSet *_itemsProgress;
    OAConcurrentDictionary<NSString *, NSString *> *_errors;
}

- (instancetype) initWithListener:(id<OANetworkExportProgressListener>)listener
{
    self = [super initWithListener:nil];
    if (self) {
        _itemsToDelete = [NSMutableArray array];
        _localItemsToDelete = [NSMutableArray array];
        _oldFilesToDelete = [[OAConcurrentArray alloc] init];
        _backupHelper = OABackupHelper.sharedInstance;
        _listener = listener;
    }
    return self;
}

- (NSArray<OASettingsItem *> *)getItemsToDelete
{
    return _itemsToDelete;
}

- (NSArray<OASettingsItem *> *)getLocalItemsToDelete
{
    return _localItemsToDelete;
}

- (NSArray<OASettingsItem *> *)getOldItemsToDelete
{
    return _oldItemsToDelete;
}

- (void) addItemToDelete:(OASettingsItem *)item
{
    [_itemsToDelete addObject:item];
}

- (void) addLocalItemToDelete:(OASettingsItem *)item
{
    [_localItemsToDelete addObject:item];
}

- (void) addOldItemToDelete:(OASettingsItem *)item
{
    [_oldItemsToDelete addObject:item];
}

- (void) export
{
    [self exportItems];
}

- (void) writeItems:(OAAbstractWriter *)writer
{
    OAOperationLog *log = [[OAOperationLog alloc] initWithOperationName:@"writeItems" debug:BACKUP_DEBUG_LOGS];
    [log startOperation];
    
    __block NSString *subscriptionError = nil;
    [_backupHelper checkSubscriptions:^(NSInteger status, NSString *message, NSString *error) {
        if (error)
            subscriptionError = error;
    }];
    if (subscriptionError.length > 0)
    {
        @throw [NSException exceptionWithName:@"IOException" reason:subscriptionError userInfo:nil];
    }
    
    NSMutableArray<OAItemWriterTask *> *lightTasks = [NSMutableArray array];
    NSMutableArray<OAItemWriterTask *> *heavyTasks = [NSMutableArray array];
    for (OASettingsItem *item in self.getItems)
    {
        if (item.getEstimatedSize > MAX_LIGHT_ITEM_SIZE)
        {
            [heavyTasks addObject:[[OAItemWriterTask alloc] initWithWriter:writer item:item]];
        }
        else
        {
            [lightTasks addObject:[[OAItemWriterTask alloc] initWithWriter:writer item:item]];
        }
    }
    if (lightTasks.count > 0)
    {
        _executor = [[NSOperationQueue alloc] init];
        _executor.maxConcurrentOperationCount = 10;
        [_executor addOperations:lightTasks waitUntilFinished:YES];
        for (OAItemWriterTask *task in lightTasks)
            if (task.error)
            {
                [log finishOperation];
                @throw [NSException exceptionWithName:@"IOException" reason:task.error userInfo:nil];
            }
    }
    if (heavyTasks.count > 0)
    {
        _executor = [[NSOperationQueue alloc] init];
        _executor.maxConcurrentOperationCount = 1;
        [_executor addOperations:heavyTasks waitUntilFinished:YES];
        for (OAItemWriterTask *task in heavyTasks)
            if (task.error)
            {
                [log finishOperation];
                @throw [NSException exceptionWithName:@"IOException" reason:task.error userInfo:nil];
            }
    }
    [log finishOperation];
}

- (void) exportItems
{
    _dataProgress = [[OAAtomicInteger alloc] initWithInteger:0];
    _itemsProgress = [[OAConcurrentSet alloc] init];
    _errors = [[OAConcurrentDictionary alloc] init];

    OANetworkWriter *networkWriter = [[OANetworkWriter alloc] initWithListener:self];
    [self writeItems:networkWriter];
    [self deleteFiles:self];
    [self deleteOldFiles:self];
    [self deleteLocalFiles:_itemsProgress dataProgress:_dataProgress];
    if (!self.isCancelled)
        [_backupHelper updateBackupUploadTime];
    if (_listener != nil)
        [_listener networkExportDone:_errors.asDictionary];
}

- (void) deleteFiles:(id<OAOnDeleteFilesListener>)listener
{
    @try
    {
        NSMutableArray<OARemoteFile *> *remoteFiles = [NSMutableArray array];
        NSDictionary<NSString *, OARemoteFile *> *remoteFilesMap = [_backupHelper.backup getRemoteFiles:EOARemoteFilesTypeUnique];
        if (remoteFilesMap != nil)
        {
            NSArray<OASettingsItem *> *itemsToDelete = _itemsToDelete;
            for (OARemoteFile *remoteFile in remoteFilesMap.allValues)
            {
                for (OASettingsItem *item in itemsToDelete)
                {
                    if ([item isEqual:remoteFile.item])
                    {
                        [remoteFiles addObject:remoteFile];
                    }
                }
            }
            if (remoteFiles.count > 0)
            {
                [_backupHelper deleteFilesSync:remoteFiles byVersion:NO listener:listener];
            }
        }
    }
    @catch (NSException *e)
    {
        @throw [NSException exceptionWithName:@"IOException" reason:e.reason userInfo:nil];
    }
}

- (void) deleteOldFiles:(id<OAOnDeleteFilesListener>)listener
{
    @try {
        if (_oldFilesToDelete.countSync > 0)
        {
            [_backupHelper deleteFilesSync:_oldFilesToDelete.asArray byVersion:YES listener:listener];
        }
    }
    @catch (NSException *e)
    {
        @throw [NSException exceptionWithName:@"IOException" reason:e.reason userInfo:nil];
    }
}

- (void) deleteLocalFiles:(OAConcurrentSet *)itemsProgress dataProgress:(OAAtomicInteger *)dataProgress
{
    NSArray<OASettingsItem *> *localItemsToDelete = _localItemsToDelete;
    for (OASettingsItem *item in localItemsToDelete)
    {
        [item remove];
        [itemsProgress addObjectSync:item];
        if (_listener)
        {
            int p = [dataProgress addAndGet:(APPROXIMATE_FILE_SIZE_BYTES / 1024)];
            NSString *fileName = [OABackupHelper getItemFileName:item];
            [_listener itemExportDone:[OASettingsItemType typeName:item.type] fileName:fileName];
            [_listener updateGeneralProgress:itemsProgress.countSync uploadedKb:(NSInteger)p];
        }
    }
}

- (void)cancel
{
    [super cancel];
    if (_executor)
        [_executor cancelAllOperations];
}

- (void) markOldFileForDeletion:(OASettingsItem *)item fileName:(NSString *)fileName
{
    NSString *type = [OASettingsItemType typeName:item.type];
    OAExportSettingsType *exportType = [OAExportSettingsType findBySettingsItem:item];
    if (exportType != nil && ![_backupHelper getVersionHistoryTypePref:exportType].get)
    {
        OARemoteFile *remoteFile = [_backupHelper.backup getRemoteFile:type fileName:fileName];
        if (remoteFile != nil)
            [_oldFilesToDelete addObjectSync:remoteFile];
    }
}

// MARK: OAOnUploadItemListener

- (void)onItemFileUploadDone:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName uploadTime:(long)uploadTime error:(nonnull NSString *)error {
    NSString *type = [OASettingsItemType typeName:item.type];
    if (error.length > 0)
    {
        [_errors setObjectSync:error forKey:[NSString stringWithFormat:@"%@/%@", type, fileName]];
    }
    else
    {
        [self markOldFileForDeletion:item fileName:fileName];
    }
    int p = [_dataProgress addAndGet:(APPROXIMATE_FILE_SIZE_BYTES / 1024)];
    if (_listener != nil)
    {
        [_listener updateGeneralProgress:_itemsProgress.countSync uploadedKb:(NSInteger)p];
    }
}

- (void)onItemUploadDone:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName error:(nonnull NSString *)error {
    NSString *type = [OASettingsItemType typeName:item.type];
    if (error.length > 0)
    {
        [_errors setObjectSync:error forKey:[NSString stringWithFormat:@"%@/%@", type, fileName]];
    }
    [_itemsProgress addObjectSync:item];
    if (_listener)
    {
        [_listener itemExportDone:type fileName:fileName];
        [_listener updateGeneralProgress:_itemsProgress.countSync uploadedKb:(NSInteger)_dataProgress.get];
    }
}

- (void)onItemUploadProgress:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork {
    NSInteger p = [_dataProgress addAndGet:(int) deltaWork];
    if (_listener)
    {
        [_listener updateItemProgress:[OASettingsItemType typeName:item.type] fileName:fileName progress:progress];
        [_listener updateGeneralProgress:_itemsProgress.countSync uploadedKb:p];
    }
}

- (void)onItemUploadStarted:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    if (_listener)
        [_listener itemExportStarted:[OASettingsItemType typeName:item.type] fileName:fileName work:work];
}


// MARK: OAOnDeleteFilesListener

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress {
    int p = [_dataProgress addAndGet:(APPROXIMATE_FILE_SIZE_BYTES / 1024)];
    [_itemsProgress addObjectSync:file];
    if (_listener != nil)
    {
        [_listener itemExportDone:file.type fileName:file.name];
        [_listener updateGeneralProgress:_itemsProgress.countSync uploadedKb:(NSInteger)p];
    }
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *,NSString *> *)errors {
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message {
}

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files {
}

@end
