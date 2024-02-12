//
//  OABaseDeleteFilesCommand.m
//  OsmAnd Maps
//
//  Created by Paul on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseDeleteFilesCommand.h"
#import "OANetworkUtilities.h"
#import "OABackupDbHelper.h"
#import "OABackupHelper.h"
#import "OARemoteFile.h"
#import "OABackupError.h"
#import "OAOperationLog.h"

static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";

@interface OADeleteRemoteFileTask : NSOperation

@property (nonatomic, readonly) OARemoteFile *remoteFile;
@property (nonatomic, readonly) NSData *response;
@property (nonatomic, readonly) NSString *error;

- (instancetype) initWithRequest:(OANetworkRequest *)request
                      remoteFile:(OARemoteFile *)remoteFile
                       byVersion:(BOOL)byVersion;

@end

@implementation OADeleteRemoteFileTask
{
    OANetworkRequest *_request;
    BOOL _byVersion;
}

- (instancetype) initWithRequest:(OANetworkRequest *)request
                      remoteFile:(OARemoteFile *)remoteFile
                       byVersion:(BOOL)byVersion
{
    self = [super init];
    if (self)
    {
        _request = request;
        _remoteFile = remoteFile;
        _byVersion = byVersion;
    }
    return self;
}

- (void)main
{
    OAOperationLog *operationLog = [[OAOperationLog alloc] initWithOperationName:@"deleteFile" debug:BACKUP_DEBUG_LOGS];
    [OANetworkUtilities sendRequest:_request async:NO onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
        if (statusCode == 200 && !error && !_byVersion)
        {
            if (data)
                _response = data;
            [OABackupDbHelper.sharedDatabase removeUploadedFileInfo:[[OAUploadedFileInfo alloc] initWithType:_remoteFile.type name:_remoteFile.name]];
        }
        else if (statusCode != 200)
        {
            if (data)
                _error = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            else
                _error = [NSString stringWithFormat:@"Delete file request error code: %ld", ((NSHTTPURLResponse *)response).statusCode];
        }
    }];
    [operationLog finishOperation:_remoteFile.name];
}

@end

@implementation OABaseDeleteFilesCommand
{
    BOOL _byVersion;
    __weak id<OAOnDeleteFilesListener> _listener;
    NSArray<OADeleteRemoteFileTask *> *_tasks;
    NSArray<OADeleteRemoteFileTask *> *_allTasks;
    NSMutableSet *_itemsProgress;
    OABackupHelper *_backupHelper;
    NSOperationQueue *_executor;
    NSArray *_filesToDelete;
}

- (instancetype)initWithVersion:(BOOL)byVersion
{
    self = [super init];
    if (self) {
        _byVersion = byVersion;
        _backupHelper = OABackupHelper.sharedInstance;
        _tasks = @[];
        _itemsProgress = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener
{
    self = [super init];
    if (self)
    {
        _byVersion = byVersion;
        _listener = listener;
        _backupHelper = OABackupHelper.sharedInstance;
        _itemsProgress = [NSMutableSet set];
    }
    return self;
}

- (void)doInBackground
{
    // override
}

- (void)main
{
    [self onPreExecute];
    [self doInBackground];
    if (_filesToDelete && _filesToDelete.count > 0)
        [self deleteFiles:_filesToDelete];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onPostExecute];
    });
}

- (void)setFilesToDelete:(NSArray *)files
{
    _filesToDelete = files;
}

- (void) deleteFiles:(NSArray<OARemoteFile *> *)remoteFiles
{
    NSMutableDictionary<NSString *, NSString *> *commonParameters = [NSMutableDictionary dictionary];
    commonParameters[@"deviceid"] = _backupHelper.getDeviceId;
    commonParameters[@"accessToken"] = _backupHelper.getAccessToken;
    
    NSMutableArray<OADeleteRemoteFileTask *> *tasks = [NSMutableArray array];
    for (OARemoteFile *remoteFile in remoteFiles)
    {
        NSMutableDictionary<NSString *, NSString *> *parameters = [NSMutableDictionary dictionaryWithDictionary:commonParameters];
        parameters[@"name"] = remoteFile.name;
        parameters[@"type"] = remoteFile.type;
        if (_byVersion)
            parameters[@"updatetime"] = [NSString stringWithFormat:@"%ld", remoteFile.updatetimems];
        OANetworkRequest *r = [[OANetworkRequest alloc] init];
        r.url = _byVersion ? OABackupHelper.DELETE_FILE_VERSION_URL : OABackupHelper.DELETE_FILE_URL;
        r.params = parameters;
        r.post = YES;
        OADeleteRemoteFileTask *t = [[OADeleteRemoteFileTask alloc] initWithRequest:r remoteFile:remoteFile byVersion:_byVersion];
        [t addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
        [tasks addObject:t];
    }
    _allTasks = tasks;
    _executor = [[NSOperationQueue alloc] init];
    [_executor addObserver:self forKeyPath:@"operations" options:0 context:&kQueueOperationsChanged];
    [_executor addOperations:tasks waitUntilFinished:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == _executor && [keyPath isEqualToString:@"operations"] && context == &kQueueOperationsChanged) {
        if ([_executor.operations count] == 0)
        {
            _tasks = _allTasks;
        }
    }
    else if ([keyPath isEqualToString:@"isFinished"])
    {
        [self publishProgress:object];
    }
}

- (void) onPreExecute
{
    if (_listener)
        [_backupHelper.backupListeners addDeleteFilesListener:_listener];
}

- (NSArray<id<OAOnDeleteFilesListener>> *)getListeners
{
    return _backupHelper.backupListeners.getDeleteFilesListeners;
}

- (void) publishProgress:(id)object
{
    for (id<OAOnDeleteFilesListener> listener in [self getListeners]) {
        if ([object isKindOfClass:OADeleteRemoteFileTask.class])
        {
            OARemoteFile *remoteFile = ((OADeleteRemoteFileTask *) object).remoteFile;
            [_itemsProgress addObject:remoteFile];
            [listener onFileDeleteProgress:remoteFile progress:_itemsProgress.count];
        }
    }
}

- (void) onPostExecute
{
    NSArray<id<OAOnDeleteFilesListener>> *listeners = [self getListeners];
    if (listeners.count > 0)
    {
        NSMutableDictionary<OARemoteFile *, NSString *> *errors = [NSMutableDictionary dictionary];
        for (OADeleteRemoteFileTask *task in _tasks)
        {
            BOOL success;
            NSString *message = nil;
            NSString *errorStr = task.error;
            if (errorStr)
            {
                if (errorStr.length > 0)
                {
                    message = [[OABackupError alloc] initWithError:errorStr].toString;
                    success = NO;
                }
                else
                {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:task.response options:NSJSONReadingAllowFragments error:nil];
                    if (json[@"status"] && [json[@"status"] isEqualToString:@"ok"])
                    {
                        success = YES;
                    }
                    else
                    {
                        message = @"Unknown error";
                        success = NO;
                    }
                }
                if (!success)
                    errors[task.remoteFile] = message;
            }
        }
        for (id<OAOnDeleteFilesListener> listener in listeners) {
            [listener onFilesDeleteDone:errors];
        }
    }
    if (_listener != nil)
        [_backupHelper.backupListeners removeDeleteFilesListener:_listener];
}

@end
