//
//  OASyncBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 07.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kBackupSyncFinishedNotification @"OsmandBackupSyncFinishedNotification"
#define kBackupSyncStartedNotification @"OsmandBackupSyncStartedNotification"
#define kBackupProgressUpdateNotification @"OsmandBackupSyncProgressNotification"
#define kBackupItemFinishedNotification @"OsmandBackupSyncItemFinishedNotification"
#define kBackupItemProgressNotification @"OsmandBackupSyncItemProgressNotification"
#define kBackupItemStartedNotification @"OsmandBackupSyncItemStartedNotification"

@class OASettingsItem;

@interface OASyncBackupTask : NSObject

- (instancetype)initWithKey:(NSString *)key;

- (void) execute;
- (void)uploadLocalItem:(OASettingsItem *)item fileName:(NSString *)fileName;
- (void)downloadRemoteVersion:(OASettingsItem *)item fileName:(NSString *)fileName;
- (void)deleteItem:(OASettingsItem *)item fileName:(NSString *)fileName;

- (void) cancel;

@end

NS_ASSUME_NONNULL_END
