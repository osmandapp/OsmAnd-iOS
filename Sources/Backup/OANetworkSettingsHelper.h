//
//  OANetworkSettingsHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

#define kBackupItemsKey @"backup_items_key"
#define kRestoreItemsKey @"restore_items_key"
#define kSyncItemsKey @"sync_items_key"
#define kPrepareBackupKey @"prepare_backup_key"

typedef NS_ENUM(NSInteger, EOABackupSyncOperationType) {
    EOABackupSyncOperationNone = -1,
    EOABackupSyncOperationSync = 0,
    EOABackupSyncOperationUpload,
    EOABackupSyncOperationDownload,
    EOABackupSyncOperationDelete
};

@class OASettingsItem, OARemoteFile, OALocalFile, OAImportBackupTask, OAExportBackupTask, OASyncBackupTask;

@protocol OABackupExportListener <NSObject>

- (void) onBackupExportStarted;
- (void) onBackupExportProgressUpdate:(NSInteger)value;
- (void) onBackupExportFinished:(NSString *)error;
- (void) onBackupExportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work;
- (void) onBackupExportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(NSInteger)value;
- (void) onBackupExportItemFinished:(NSString *)type fileName:(NSString *)fileName;

@end

@protocol OABackupCollectListener <NSObject>
- (void) onBackupCollectFinished:(BOOL)succeed
                           empty:(BOOL)empty
                           items:(NSArray<OASettingsItem *> *)items
                     remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles;
@end

@interface OANetworkSettingsHelper : OASettingsHelper

@property (nonatomic, readonly) NSMutableDictionary<NSString *, OAImportBackupTask *> *importAsyncTasks;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, OAExportBackupTask *> *exportAsyncTasks;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, OASyncBackupTask *> *syncBackupTasks;

+ (OANetworkSettingsHelper *) sharedInstance;

- (OAImportBackupTask *)getImportTask:(NSString *)key;
- (OAExportBackupTask *)getExportTask:(NSString *)key;
- (OASyncBackupTask *)getSyncTask:(NSString *)key;

- (EOAImportType) getImportTaskType:(NSString *)key;

- (void) cancelSync;

- (BOOL) isBackupExporting;
- (BOOL) isBackupImporting;
- (BOOL) isBackupSyncing;


- (void) updateExportListener:(id<OABackupExportListener>)listener;
- (void) updateImportListener:(id<OAImportListener>)listener;

- (void) syncSettingsItems:(NSString *)key operation:(EOABackupSyncOperationType)operation;
- (void) syncSettingsItems:(NSString *)key
                 localFile:(OALocalFile *)localFile
                remoteFile:(OARemoteFile *)remoteFile
                 operation:(EOABackupSyncOperationType)operation
                errorToast:(void (^)(NSString *message, NSString *detail))errorToast;

- (void) finishImport:(id<OAImportListener>)listener success:(BOOL)success items:(NSArray<OASettingsItem *> *)items;


- (void) collectSettings:(NSString *)key readData:(BOOL)readData
                listener:(id<OABackupCollectListener>)listener;

- (void) checkDuplicates:(NSString *)key
                   items:(NSArray<OASettingsItem *> *)items
           selectedItems:(NSArray<OASettingsItem *> *)selectedItems
                listener:(id<OACheckDuplicatesListener>)listener;

- (void) importSettings:(NSString *)key
                  items:(NSArray<OASettingsItem *> *)items
          forceReadData:(BOOL)forceReadData
               listener:(id<OAImportListener>)listener;

- (void) exportSettings:(NSString *)key
                  items:(NSArray<OASettingsItem *> *)items
          itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete
          localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete
               listener:(id<OABackupExportListener>)listener;

@end
