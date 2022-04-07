//
//  OAPrepareBackupTask.m
//  OsmAnd Maps
//
//  Created by Paul on 26.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAPrepareBackupTask.h"
#import "OABackupHelper.h"
#import "OABackupListeners.h"

@implementation OABackupTaskType
{
    NSArray<OABackupTaskType *> *_dependentTasks;
}

static OABackupTaskType *COLLECT_LOCAL_FILES;
static OABackupTaskType *COLLECT_REMOTE_FILES;
static OABackupTaskType *GENERATE_BACKUP_INFO;

- (instancetype) initWithDependentTasks:(NSArray<OABackupTaskType *> *)dependentTasks
{
    self = [super init];
    if (self) {
        _dependentTasks = dependentTasks;
    }
    return self;
}

+ (OABackupTaskType *) COLLECT_LOCAL_FILES
{
    if (!COLLECT_LOCAL_FILES)
        COLLECT_LOCAL_FILES = [[OABackupTaskType alloc] initWithDependentTasks:nil];
    return COLLECT_LOCAL_FILES;
}

+ (OABackupTaskType *) COLLECT_REMOTE_FILES
{
    if (!COLLECT_REMOTE_FILES)
        COLLECT_REMOTE_FILES = [[OABackupTaskType alloc] initWithDependentTasks:nil];
    return COLLECT_REMOTE_FILES;
}

+ (OABackupTaskType *) GENERATE_BACKUP_INFO
{
    if (!GENERATE_BACKUP_INFO)
        GENERATE_BACKUP_INFO = [[OABackupTaskType alloc] initWithDependentTasks:@[self.COLLECT_LOCAL_FILES, self.COLLECT_REMOTE_FILES]];
    return GENERATE_BACKUP_INFO;
}

@end

@implementation OAPrepareBackupTask
{
    OABackupHelper *_backupHelper;
    
    id<OAOnPrepareBackupListener> _listener;
    
    NSMutableArray<OABackupTaskType *> *_pendingTasks;
    NSMutableArray<OABackupTaskType *> *_finishedTasks;
}

- (instancetype) initWithListener:(id<OAOnPrepareBackupListener>)listener
{
    self = [super init];
    if (self) {
        _listener = listener;
        
        _pendingTasks = [NSMutableArray array];
        _finishedTasks = [NSMutableArray array];
    }
    return self;
}



@end
