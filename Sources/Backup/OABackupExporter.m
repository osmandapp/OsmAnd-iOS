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
#import "OAAbstractWriter.h"
#import "OAAtomicInteger.h"
#import "OANetworkWriter.h"

#define MAX_LIGHT_ITEM_SIZE 10 * 1024 * 1024

@interface OAItemWriterTask : NSOperation

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
    [_writer write:_item];
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
    NSMutableArray<OASettingsItem *> *_oldItemsToDelete;
    NSOperationQueue *_executor;
    __weak id<OANetworkExportProgressListener> _listener;
    NSMutableArray<OARemoteFile *> *_oldFilesToDelete;
}

- (instancetype) initWithListener:(id<OANetworkExportProgressListener>)listener
{
    self = [super init];
    if (self) {
        _itemsToDelete = [NSMutableArray array];
        _oldFilesToDelete = [NSMutableArray array];
        _oldFilesToDelete = [NSMutableArray array];
        _backupHelper = OABackupHelper.sharedInstance;
        _listener = listener;
    }
    return self;
}

- (NSArray<OASettingsItem *> *)getItemsToDelete
{
    return _itemsToDelete;
}

- (NSArray<OASettingsItem *> *)getOldItemsToDelete
{
    return _oldItemsToDelete;
}

- (void) addItemToDelete:(OASettingsItem *)item
{
    [_itemsToDelete addObject:item];
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
//    OperationLog log = new OperationLog("writeItems", true);
//    log.startOperation();
    
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
        [_executor addOperations:lightTasks waitUntilFinished:YES];
        
//        if (!executor.getExceptions().isEmpty()) {
//            log.finishOperation();
//            Throwable t = executor.getExceptions().values().iterator().next();
//            throw new IOException(t.getMessage(), t);
//        }
    }
    if (heavyTasks.count > 0)
    {
        _executor = [[NSOperationQueue alloc] init];
        _executor.maxConcurrentOperationCount = 1;
        [_executor addOperations:heavyTasks waitUntilFinished:YES];
//        if (!executor.getExceptions().isEmpty()) {
//            log.finishOperation();
//            Throwable t = executor.getExceptions().values().iterator().next();
//            throw new IOException(t.getMessage(), t);
//        }
    }
//    log.finishOperation();
}

- (void) exportItems
{
    OAAtomicInteger *dataProgress = [[OAAtomicInteger alloc] initWithInteger:0];
    NSMutableSet *itemsProgress = [NSMutableSet set];
    NSMutableDictionary<NSString *, NSString *> *errors = [NSMutableDictionary dictionary];

//    OnUploadItemListener uploadItemListener = getOnUploadItemListener(itemsProgress, dataProgress, errors);
//    OnDeleteFilesListener deleteFilesListener = getOnDeleteFilesListener(itemsProgress, dataProgress);
//
//    NetworkWriter networkWriter = new NetworkWriter(backupHelper, uploadItemListener);
//    writeItems(networkWriter);
//    deleteFiles(deleteFilesListener);
//    deleteOldFiles(deleteFilesListener);
//    if (!isCancelled()) {
//        backupHelper.updateBackupUploadTime();
//    }
//    if (listener != null) {
//        listener.networkExportDone(errors);
//    }
}

//protected void deleteFiles(OnDeleteFilesListener listener) throws IOException {
//    try {
//        List<RemoteFile> remoteFiles = new ArrayList<>();
//        Map<String, RemoteFile> remoteFilesMap = backupHelper.getBackup().getRemoteFiles(RemoteFilesType.UNIQUE);
//        if (remoteFilesMap != null) {
//            List<SettingsItem> itemsToDelete = this.itemsToDelete;
//            for (RemoteFile remoteFile : remoteFilesMap.values()) {
//                for (SettingsItem item : itemsToDelete) {
//                    if (item.equals(remoteFile.item)) {
//                        remoteFiles.add(remoteFile);
//                    }
//                }
//            }
//            if (!Algorithms.isEmpty(remoteFiles)) {
//                backupHelper.deleteFilesSync(remoteFiles, false, AsyncTask.THREAD_POOL_EXECUTOR, listener);
//            }
//        }
//    } catch (UserNotRegisteredException e) {
//        throw new IOException(e.getMessage(), e);
//    }
//}
//
//protected void deleteOldFiles(OnDeleteFilesListener listener) throws IOException {
//    try {
//        if (!Algorithms.isEmpty(oldFilesToDelete)) {
//            backupHelper.deleteFilesSync(oldFilesToDelete, true, AsyncTask.THREAD_POOL_EXECUTOR, listener);
//        }
//    } catch (UserNotRegisteredException e) {
//        throw new IOException(e.getMessage(), e);
//    }
//}
//
//@Override
//public void cancel() {
//    super.cancel();
//    if (executor != null) {
//        executor.cancel();
//    }
//}
//
//private OnUploadItemListener getOnUploadItemListener(Set<Object> itemsProgress, AtomicInteger dataProgress, Map<String, String> errors) {
//    return new OnUploadItemListener() {
//        
//        @Override
//        public void onItemUploadStarted(@NonNull SettingsItem item, @NonNull String fileName, int work) {
//            if (listener != null) {
//                listener.itemExportStarted(item.getType().name(), fileName, work);
//            }
//        }
//        
//        @Override
//        public void onItemUploadProgress(@NonNull SettingsItem item, @NonNull String fileName, int progress, int deltaWork) {
//            int p = dataProgress.addAndGet(deltaWork);
//            if (listener != null) {
//                listener.updateItemProgress(item.getType().name(), fileName, progress);
//                listener.updateGeneralProgress(itemsProgress.size(), p);
//            }
//        }
//        
//        @Override
//        public void onItemFileUploadDone(@NonNull SettingsItem item, @NonNull String fileName, long uploadTime, @Nullable String error) {
//            String type = item.getType().name();
//            if (!Algorithms.isEmpty(error)) {
//                errors.put(type + "/" + fileName, error);
//            } else {
//                markOldFileForDeletion(item, fileName);
//            }
//            int p = dataProgress.addAndGet(APPROXIMATE_FILE_SIZE_BYTES / 1024);
//            if (listener != null) {
//                listener.updateGeneralProgress(itemsProgress.size(), p);
//            }
//        }
//        
//        @Override
//        public void onItemUploadDone(@NonNull SettingsItem item, @NonNull String fileName, long uploadTime, @Nullable String error) {
//            String type = item.getType().name();
//            if (!Algorithms.isEmpty(error)) {
//                errors.put(type + "/" + fileName, error);
//            }
//            itemsProgress.add(item);
//            if (listener != null) {
//                listener.itemExportDone(item.getType().name(), fileName);
//                listener.updateGeneralProgress(itemsProgress.size(), dataProgress.get());
//            }
//        }
//    };
//}
//
//private OnDeleteFilesListener getOnDeleteFilesListener(Set<Object> itemsProgress, AtomicInteger dataProgress) {
//    return new OnDeleteFilesListener() {
//        
//        @Override
//        public void onFilesDeleteStarted(@NonNull List<RemoteFile> files) {
//            
//        }
//        
//        @Override
//        public void onFileDeleteProgress(@NonNull RemoteFile file, int progress) {
//            int p = dataProgress.addAndGet(APPROXIMATE_FILE_SIZE_BYTES / 1024);
//            itemsProgress.add(file);
//            if (listener != null) {
//                listener.itemExportDone(file.getType(), file.getName());
//                listener.updateGeneralProgress(itemsProgress.size(), p);
//            }
//        }
//        
//        @Override
//        public void onFilesDeleteDone(@NonNull Map<RemoteFile, String> errors) {
//            
//        }
//        
//        @Override
//        public void onFilesDeleteError(int status, @NonNull String message) {
//            
//        }
//    };
//}
//
//private void markOldFileForDeletion(@NonNull SettingsItem item, @NonNull String fileName) {
//    String type = item.getType().name();
//    ExportSettingsType exportType = ExportSettingsType.getExportSettingsTypeForItem(item);
//    if (exportType != null && !backupHelper.getVersionHistoryTypePref(exportType).get()) {
//        RemoteFile remoteFile = backupHelper.getBackup().getRemoteFile(type, fileName);
//        if (remoteFile != null) {
//            oldFilesToDelete.add(remoteFile);
//        }
//    }
//}
//

// MARK: OAOnUploadItemListener

- (void)onItemFileUploadDone:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName uploadTime:(long)uploadTime error:(nonnull NSString *)error {
    
}

- (void)onItemUploadDone:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName uploadTime:(long)uploadTime error:(nonnull NSString *)error {
    
}

- (void)onItemUploadProgress:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork {
    
}

- (void)onItemUploadStarted:(nonnull OASettingsItem *)item fileName:(nonnull NSString *)fileName work:(NSInteger)work {
    
}


// MARK: OAOnDeleteFilesListener

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress {
    
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *,NSString *> *)errors {
    
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message {
    
}

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files {
    
}

@end
