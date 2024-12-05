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
#import "OAPrepareBackupResult.h"
#import "OANetworkSettingsHelper.h"
#import "Localization.h"
#import "OALog.h"

@interface OABackupTaskType ()

@property (nonatomic) NSArray<OABackupTaskType *> *dependentTasks;

@end

@implementation OABackupTaskType

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
        COLLECT_REMOTE_FILES = [[OABackupTaskType alloc] initWithDependentTasks:@[self.COLLECT_LOCAL_FILES]];
    return COLLECT_REMOTE_FILES;
}

+ (OABackupTaskType *) GENERATE_BACKUP_INFO
{
    if (!GENERATE_BACKUP_INFO)
        GENERATE_BACKUP_INFO = [[OABackupTaskType alloc] initWithDependentTasks:@[self.COLLECT_LOCAL_FILES, self.COLLECT_REMOTE_FILES]];
    return GENERATE_BACKUP_INFO;
}

@end

@interface OAPrepareBackupTask () <OAOnCollectLocalFilesListener, OABackupCollectListener>

@end

@implementation OAPrepareBackupTask
{
    OABackupHelper *_backupHelper;
    
    __weak id<OAOnPrepareBackupListener> _listener;
    
    NSMutableArray<OABackupTaskType *> *_pendingTasks;
    NSMutableArray<OABackupTaskType *> *_finishedTasks;
}

- (instancetype) initWithListener:(id<OAOnPrepareBackupListener>)listener
{
    self = [super init];
    if (self) {
        _backupHelper = OABackupHelper.sharedInstance;
        _listener = listener;
        
        _pendingTasks = [NSMutableArray array];
        _finishedTasks = [NSMutableArray array];
    }
    return self;
}

- (BOOL) prepare
{
    if (_pendingTasks.count > 0)
        return NO;
    if (_listener)
        [_listener onBackupPreparing];
    [self initTasks];
    return [self runTasks];
}

- (void) initTasks
{
    _backup = [[OAPrepareBackupResult alloc] init];
    _pendingTasks = [NSMutableArray arrayWithArray:@[OABackupTaskType.COLLECT_LOCAL_FILES, OABackupTaskType.COLLECT_REMOTE_FILES, OABackupTaskType.GENERATE_BACKUP_INFO]];
    _finishedTasks = [NSMutableArray array];
}

- (BOOL) runTasks
{
    if (_pendingTasks.count == 0)
    {
        return NO;
    }
    else
    {
        NSMutableArray<OABackupTaskType *> *toDelete = [NSMutableArray array];
        for (OABackupTaskType *taskType in _pendingTasks)
        {
            BOOL shouldRun = YES;
            if (taskType.dependentTasks)
            {
                for (OABackupTaskType *dependentTask in taskType.dependentTasks)
                {
                    if (![_finishedTasks containsObject:dependentTask])
                    {
                        shouldRun = NO;
                        break;
                    }
                }
            }
            if (shouldRun)
            {
                [toDelete addObject:taskType];
                [self runTask:taskType];
            }
        }
        [_pendingTasks removeObjectsInArray:toDelete];
        return YES;
    }
}

- (void) runTask:(OABackupTaskType *)taskType
{
    if (taskType == OABackupTaskType.COLLECT_LOCAL_FILES)
        return [self doCollectLocalFiles];
    
    if (taskType == OABackupTaskType.COLLECT_REMOTE_FILES)
        return [self doCollectRemoteFiles];
    
    if (taskType == OABackupTaskType.GENERATE_BACKUP_INFO)
        return [self doGenerateBackupInfo];
}

- (void) onTaskFinished:(OABackupTaskType *)taskType
{
    [_finishedTasks addObject:taskType];
    if (![self runTasks])
        [self onTasksDone];
}

- (void) doCollectLocalFiles
{
    [_backupHelper collectLocalFiles:self];
}

- (void) doCollectRemoteFiles
{
    @try
    {
        [OANetworkSettingsHelper.sharedInstance collectSettings:kPrepareBackupKey readData:NO listener:self];
    }
    @catch (NSException *e)
    {
        NSString *message = e.reason;
        if (message != nil)
        {
            [self onError:message];
        }
        OALog(@"Collect remote files error: %@", e.reason);
    }
}

- (void) doGenerateBackupInfo
{
    if (_backup.localFiles == nil || _backup.remoteFiles == nil)
    {
        [self onTaskFinished:OABackupTaskType.GENERATE_BACKUP_INFO];
        return;
    }
    [_backupHelper generateBackupInfo:_backup.localFiles uniqueRemoteFiles:[_backup getRemoteFiles:EOARemoteFilesTypeUnique] deletedRemoteFiles:[_backup getRemoteFiles:EOARemoteFilesTypeDeleted] onComplete:^(OABackupInfo *backupInfo, NSString *error) {
        if (error.length == 0)
            _backup.backupInfo = backupInfo;
        else
            [self onError:error];
        [self onTaskFinished:OABackupTaskType.GENERATE_BACKUP_INFO];
    }];
}

- (void) onError:(NSString *)message
{
    [_backup setError:message];
    [_pendingTasks removeAllObjects];
    [self onTasksDone];
}

- (void) onTasksDone
{
    _backupHelper.backup = _backup;
    if (_listener)
        [_listener onBackupPrepared:_backup];
}

// MARK: OAOnCollectLocalFilesListener

- (void)onFileCollected:(OALocalFile *)localFile
{
}

- (void)onFilesCollected:(NSArray<OALocalFile *> *)localFiles
{
    [_backup setLocalFilesFromArray:localFiles];
    [self onTaskFinished:OABackupTaskType.COLLECT_LOCAL_FILES];
}

// MARK: OABackupCollectListener

- (void)onBackupCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(nonnull NSArray<OASettingsItem *> *)items remoteFiles:(nonnull NSArray<OARemoteFile *> *)remoteFiles {
    if (succeed)
    {
        _backup.settingsItems = items;
        [_backup setRemoteFilesFromArray:remoteFiles];
    }
    else
    {
        [self onError:OALocalizedString(@"backup_error_failed_to_fetch_remote_items")];
    }
    [self onTaskFinished:OABackupTaskType.COLLECT_REMOTE_FILES];
}

@end
