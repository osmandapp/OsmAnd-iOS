//
//  OADownloadTask_NSURLSessionDownloadTask.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadTask_AFURLSessionManager.h"

#import "OADownloadsManager.h"
#import "OADownloadsManager_Private.h"

@implementation OADownloadTask_AFURLSessionManager
{
    OADownloadsManager* __weak _owner;
}

- (instancetype)initUsingManager:(AFURLSessionManager*)manager
                       withOwner:(OADownloadsManager*)owner
                      andRequest:(NSURLRequest*)request
                   andTargetPath:(NSString*)targetPath
                          andKey:(NSString*)key;
{
    self = [super init];
    if (self) {
        [self ctor];
        _owner = owner;
        _targetPath = [targetPath copy];
        _key = [key copy];
        NSProgress* progress;
        _task = [manager downloadTaskWithRequest:request
                                        progress:&progress
                                     destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                         return [self getDestinationFor:targetPath andResponse:response];
                                     }
                               completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                   [self onCompletedWith:response andStoredAt:filePath withError:error];
                               }];
        [progress addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                      options:NSKeyValueObservingOptionInitial
                      context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _progressCompleted = -1.0f;
    _error = nil;
    _progressCompletedObservable = [[OAObservable alloc] init];
    _completedObservable = [[OAObservable alloc] init];
}

- (void)dtor
{
}

@synthesize task = _task;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:[NSProgress class]])
    {
        NSProgress* progress = (NSProgress*)object;
        _progressCompleted = progress.fractionCompleted;

        [_progressCompletedObservable notifyEventWithKey:self
                                                andValue:[NSNumber numberWithFloat:_progressCompleted]];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSURL*)getDestinationFor:(NSURL*)temporaryTargetPath
                andResponse:(NSURLResponse*)response
{
    if (_targetPath != nil)
        return [NSURL fileURLWithPath:_targetPath];

    NSString* filenameTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"download.XXXXXXXX"];
    const char* pcsFilenameTemplate = [filenameTemplate fileSystemRepresentation];
    char* pcsFilename = mktemp(strdup(pcsFilenameTemplate));

    NSString* filename = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pcsFilename length:strlen(pcsFilename)];
    free(pcsFilename);

    return [NSURL fileURLWithPath:filename];
}

- (void)onCompletedWith:(NSURLResponse*)response
            andStoredAt:(NSURL*)targetPath
              withError:(NSError*)error
{
    _targetPath = targetPath.path;
    _error = error;

    OADownloadsManager* owner = _owner;
    if (_task.state == NSURLSessionTaskStateCompleted && owner != nil)
        [owner removeTask:self];

    [_completedObservable notifyEventWithKey:self andValue:_targetPath];
}

- (NSURLRequest*)originalRequest
{
    return _task.originalRequest;
}

- (NSURLRequest*)currentRequest
{
    return _task.currentRequest;
}

- (NSURLResponse*)response
{
    return _task.response;
}

@synthesize targetPath = _targetPath;
@synthesize key = _key;

- (OADownloadTaskState)state
{
    switch (_task.state)
    {
        case NSURLSessionTaskStateRunning:
            return OADownloadTaskStateRunning;
        case NSURLSessionTaskStateSuspended:
            return OADownloadTaskStatePaused;
        case NSURLSessionTaskStateCanceling:
            return OADownloadTaskStateStopping;
        case NSURLSessionTaskStateCompleted:
            return OADownloadTaskStateFinished;

        default:
            return OADownloadTaskStateUnknown;
    }
}

- (void)resume
{
    [_task resume];
}

- (void)pause
{
    [_task suspend];
}

- (void)stop
{
    //TODO: should produce resume data
    [_task cancel];
}

- (void)cancel
{
    [_task cancel];
}

@synthesize progressCompletedObservable = _progressCompletedObservable;
@synthesize progressCompleted = _progressCompleted;

@synthesize completedObservable = _completedObservable;

@synthesize error = _error;

@end
