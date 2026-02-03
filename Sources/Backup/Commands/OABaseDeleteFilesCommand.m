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
    NSMutableSet *_itemsProgress;
    NSObject *_itemsProgressLock;
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
        _itemsProgressLock = [NSObject new];
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
        _itemsProgressLock = [NSObject new];
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
        OADeleteRemoteFileTask *task = [[OADeleteRemoteFileTask alloc] initWithRequest:r remoteFile:remoteFile byVersion:_byVersion];
        __weak __typeof(self) weakSelf = self;
        __weak OADeleteRemoteFileTask *weakTask = task;
        task.completionBlock = ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            OADeleteRemoteFileTask *strongTask = weakTask;
            if (!strongSelf || !strongTask)
                return;
            
            [strongSelf publishProgress:strongTask];
        };
        [tasks addObject:task];
    }
    _tasks = [tasks copy];
    _executor = [[NSOperationQueue alloc] init];
    [_executor addOperations:tasks waitUntilFinished:YES];
}

- (void) onPreExecute
{
    __strong id<OAOnDeleteFilesListener> listener = _listener;
    if (listener)
        [_backupHelper.backupListeners addDeleteFilesListener:listener];
}

- (NSArray<id<OAOnDeleteFilesListener>> *)getListeners
{
    return _backupHelper.backupListeners.getDeleteFilesListeners;
}

- (void)publishProgress:(id)task
{
    if (![task isKindOfClass:[OADeleteRemoteFileTask class]])
        return;
    
    OARemoteFile *remoteFile = ((OADeleteRemoteFileTask *)task).remoteFile;
    if (!remoteFile)
        return;

    NSUInteger count = 0;
    @synchronized (_itemsProgressLock) {
        [_itemsProgress addObject:remoteFile];
        count = _itemsProgress.count;
    }

    for (id<OAOnDeleteFilesListener> listener in [self getListeners])
    {
        [listener onFileDeleteProgress:remoteFile progress:count];
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
    __strong id<OAOnDeleteFilesListener> listener = _listener;
    if (listener)
        [_backupHelper.backupListeners removeDeleteFilesListener:listener];
}

@end
