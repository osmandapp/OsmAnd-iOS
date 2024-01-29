//
//  OABackupImporter.h
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OASettingsItem, OARemoteFile;

@protocol OANetworkImportProgressListener <NSObject>
        
- (void) itemExportStarted:(NSString *)type fileName:(NSString *)fileName work:(NSInteger)work;
- (void) updateItemProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress;
- (void) itemExportDone:(NSString *)type fileName:(NSString *)fileName;
- (void) updateGeneralProgress:(NSInteger)downloadedItems uploadedKb:(NSInteger)uploadedKb;

@end

@interface OACollectItemsResult : NSObject

@property (nonatomic) NSArray<OASettingsItem *> *items;
@property (nonatomic) NSArray<OARemoteFile *> *remoteFiles;

@end

@interface OABackupImporter : NSObject

- (instancetype) initWithListener:(id<OANetworkImportProgressListener>)listener;

@property (nonatomic, assign) BOOL cancelled;

- (void) importItems:(NSArray<OASettingsItem *> *)items
         remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
       forceReadData:(BOOL)forceReadData
      restoreDeleted:(BOOL)restoreDeleted;

- (OACollectItemsResult *) collectItems:(NSArray<OASettingsItem *> *)settingsItems
                              readItems:(BOOL)readItems
                         restoreDeleted:(BOOL)restoreDeleted;

@end

@interface OAItemFileImportTask : NSOperation

- (instancetype) initWithRemoteFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item importer:(OABackupImporter *)importer forceReadData:(BOOL)forceReadData;

@end
