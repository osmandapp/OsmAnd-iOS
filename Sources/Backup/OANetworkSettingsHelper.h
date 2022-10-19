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
#define kPrepareBackupKey @"prepare_backup_key"

@class OASettingsItem, OARemoteFile, OAImportBackupTask, OAExportBackupTask;

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

+ (OANetworkSettingsHelper *) sharedInstance;

- (OAImportBackupTask *)getImportTask:(NSString *)key;
- (OAExportBackupTask *)getExportTask:(NSString *)key;

- (EOAImportType) getImportTaskType:(NSString *)key;

- (BOOL) cancelExport;
- (BOOL) cancelImport;

- (BOOL) isBackupExporting;
- (BOOL) isBackupImporting;

- (void) updateExportListener:(id<OABackupExportListener>)listener;
- (void) updateImportListener:(id<OAImportListener>)listener;


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
               listener:(id<OABackupExportListener>)listener;

@end
