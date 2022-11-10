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

@interface OASyncBackupTask : NSObject

- (void)execute;

@end

NS_ASSUME_NONNULL_END
