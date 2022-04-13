//
//  OAPrepareBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 26.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAPrepareBackupResult;

@protocol OAOnPrepareBackupListener <NSObject>

- (void) onBackupPreparing;

- (void) onBackupPrepared:(OAPrepareBackupResult *)backupResult;

@end

@interface OABackupTaskType : NSObject <OAOnPrepareBackupListener>

+ (OABackupTaskType *) COLLECT_LOCAL_FILES;
+ (OABackupTaskType *) COLLECT_REMOTE_FILES;
+ (OABackupTaskType *) GENERATE_BACKUP_INFO;

@end

@interface OAPrepareBackupTask : NSObject

@property (nonatomic, readonly) OAPrepareBackupResult *backup;

@end

NS_ASSUME_NONNULL_END
