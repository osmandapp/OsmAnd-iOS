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
#import "OALog.h"

@implementation OADownloadTask_AFURLSessionManager
{
    OADownloadsManager* __weak _owner;
}

- (instancetype)initUsingManager:(AFURLSessionManager*)manager
                       withOwner:(OADownloadsManager*)owner
                      andRequest:(NSURLRequest*)request
                   andTargetPath:(NSString*)targetPath
                          andKey:(NSString*)key
                         andName:(NSString*)name
{
    self = [super init];
    if (self) {
        [self commonInit];
        _owner = owner;
        _targetPath = [targetPath copy];
        _key = [key copy];
        _name = [name copy];
        
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

- (instancetype)initUsingManager:(AFURLSessionManager*)manager
                       withOwner:(OADownloadsManager*)owner
                      andRequest:(NSURLRequest*)request
                   andResumeData:(NSData*)resumeData
                   andTargetPath:(NSString*)targetPath
                          andKey:(NSString*)key
                         andName:(NSString*)name
{
    self = [super init];
    if (self) {
        [self commonInit];
        _owner = owner;
        _targetPath = [targetPath copy];
        _key = [key copy];
        _name = [name copy];
        
        NSProgress* progress;
        NSURLSessionDownloadTask* task = [manager downloadTaskWithResumeData:resumeData
                                                                    progress:&progress
                                                                 destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                     return [self getDestinationFor:targetPath andResponse:response];
                                                                 }
                                                           completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                               if (!_task)
                                                                   return;
                                                               [self onCompletedWith:response andStoredAt:filePath withError:error];
                                                           }];

        // Verify URL request
        if (![request.URL isEqual:task.originalRequest.URL])
        {
            OALog(@"Ignored incompatible resume data");

            task = [manager downloadTaskWithRequest:request
                                            progress:&progress
                                         destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                             return [self getDestinationFor:targetPath andResponse:response];
                                         }
                                   completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                       [self onCompletedWith:response andStoredAt:filePath withError:error];
                                   }];
        }

        _task = task;

        [progress addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                      options:NSKeyValueObservingOptionInitial
                      context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _progressCompleted = -1.0f;
    _error = nil;
    _progressCompletedObservable = [[OAObservable alloc] init];
    _completedObservable = [[OAObservable alloc] init];
}

- (void)deinit
{
}

@synthesize task = _task;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:[NSProgress class]])
    {
        NSProgress* progress = (NSProgress*)object;
        _progressCompleted = progress.fractionCompleted;

        OADownloadsManager* owner = _owner;
        if (owner != nil)
        {
            [owner.progressCompletedObservable notifyEventWithKey:self
                                                         andValue:[NSNumber numberWithFloat:_progressCompleted]];
        }

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
    return [NSURL fileURLWithPath:_targetPath];
}

- (void)onCompletedWith:(NSURLResponse*)response
            andStoredAt:(NSURL*)targetPath
              withError:(NSError*)error
{
    [_owner notifyTaskDeactivated:self];

    _targetPath = targetPath.path;
    _error = error;

    OADownloadsManager* owner = _owner;
    if (_task.state == NSURLSessionTaskStateCompleted && owner != nil)
    {
        if (error == nil)
            [owner deleteResumeDataForTask:self];

        [owner.completedObservable notifyEventWithKey:self andValue:_targetPath];
        [owner removeTask:self];
    }

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
@synthesize name = _name;

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
    [_owner notifyTaskActivated:self];
    [_task resume];
}

- (void)pause
{
    [_task suspend];
    [_owner notifyTaskDeactivated:self];
}

- (void)stop
{
    [_task cancelByProducingResumeData:^(NSData *resumeData) {
        [_owner saveResumeData:resumeData forTask:self];
    }];
    [_owner notifyTaskDeactivated:self];
}

- (void)cancel
{
    [_owner deleteResumeDataForTask:self];
    [_task cancel];
    [_owner notifyTaskDeactivated:self];
}

@synthesize progressCompletedObservable = _progressCompletedObservable;
@synthesize progressCompleted = _progressCompleted;

@synthesize completedObservable = _completedObservable;

@synthesize error = _error;

@end
