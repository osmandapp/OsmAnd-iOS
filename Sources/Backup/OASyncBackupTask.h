//
//  OASyncBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 07.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OANetworkSettingsHelper.h"

NS_ASSUME_NONNULL_BEGIN

#define kBackupSyncFinishedNotification @"OsmandBackupSyncFinishedNotification"
#define kBackupSyncStartedNotification @"OsmandBackupSyncStartedNotification"
#define kBackupProgressUpdateNotification @"OsmandBackupSyncProgressNotification"
#define kBackupItemFinishedNotification @"OsmandBackupSyncItemFinishedNotification"
#define kBackupItemProgressNotification @"OsmandBackupSyncItemProgressNotification"
#define kBackupItemStartedNotification @"OsmandBackupSyncItemStartedNotification"

@class OASettingsItem;

@interface OASyncBackupTask : NSObject

- (instancetype)initWithKey:(NSString *)key operation:(EOABackupSyncOperationType)operation;

- (void) execute;
- (void)uploadLocalItem:(OASettingsItem *)item;

- (void)downloadRemoteVersion:(OASettingsItem *)item
                    filesType:(EOARemoteFilesType)filesType
                shouldReplace:(BOOL)shouldReplace
               restoreDeleted:(BOOL)restoreDeleted;

- (void)deleteItem:(OASettingsItem *)item;
- (void)deleteLocalItem:(OASettingsItem *)item;

- (void) cancel;

@end

NS_ASSUME_NONNULL_END
