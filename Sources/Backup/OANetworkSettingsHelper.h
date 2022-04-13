//
//  OANetworkSettingsHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

NS_ASSUME_NONNULL_BEGIN

#define kBackupItemsKey @"backup_items_key"
#define kRestoreItemsKey @"restore_items_key"
#define kPrepareBackupKey @"prepare_backup_key"

@class OASettingsItem, OARemoteFile;

@protocol OABackupExportListener <NSObject>

- (void) onBackupExportStarted;
- (void) onBackupExportProgressUpdate:(int)value;
- (void) onBackupExportFinished:(NSString *)error;
- (void) onBackupExportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work;
- (void) onBackupExportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value;
- (void) onBackupExportItemFinished:(NSString *)type fileName:(NSString *)fileName;

@end

@protocol OABackupCollectListener <NSObject>
- (void) onBackupCollectFinished:(BOOL)succeed
                           empty:(BOOL)empty
                           items:(NSArray<OASettingsItem *> *)items
                     remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles;
@end

@interface OANetworkSettingsHelper : OASettingsHelper

+ (OANetworkSettingsHelper *) sharedInstance;

@end

NS_ASSUME_NONNULL_END
