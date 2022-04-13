//
//  OABackupImporter.h
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem, OARemoteFile;

@protocol OANetworkImportProgressListener <NSObject>
        
- (void) itemExportStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work;
- (void) updateItemProgress:(NSString *)type fileName:(NSString *)fileName progress:(int)progress;
- (void) itemExportDone:(NSString *)type fileName:(NSString *)fileName;

@end

@interface OACollectItemsResult : NSObject

@property (nonatomic) NSArray<OASettingsItem *> *items;
@property (nonatomic) NSArray<OARemoteFile *> *remoteFiles;

@end

@interface OABackupImporter : NSObject

@end

@interface OAItemFileImportTask : NSOperation

- (instancetype) initWithRemoteFile:(OARemoteFile *)remoteFile item:(OASettingsItem *)item importer:(OABackupImporter *)importer forceReadData:(BOOL)forceReadData;

@end

NS_ASSUME_NONNULL_END
