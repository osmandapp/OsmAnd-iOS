//
//  OADownloadTask_AFDownloadRequestOperation.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadTask_AFDownloadRequestOperation.h"

#import "OADownloadsManager.h"
#import "OADownloadsManager_Private.h"

@implementation OADownloadTask_AFDownloadRequestOperation
{
    OADownloadsManager* __weak _owner;
}

- (instancetype)initWithOwner:(OADownloadsManager*)owner
                   andRequest:(NSURLRequest*)request
                andTargetPath:(NSString*)targetPath
                       andKey:(NSString*)key
{
    self = [super init];
    if (self) {
        [self ctor];
        _owner = owner;
        _targetPath = [targetPath copy];
        _key = [key copy];
        _operation = [[AFDownloadRequestOperation alloc] initWithRequest:request
                                                              targetPath:_targetPath
                                                            shouldResume:NO];

        OADownloadTask_AFDownloadRequestOperation* __weak weakSelf = self;
        [_operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation,
                                                         NSInteger bytesRead,
                                                         long long totalBytesRead,
                                                         long long totalBytesExpected,
                                                         long long totalBytesReadForFile,
                                                         long long totalBytesExpectedToReadForFile) {
            [weakSelf onDownloadProgress:((double)totalBytesRead)/((double)totalBytesExpected)];
        }];
        [_operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [weakSelf onCompletedWithError:nil];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [weakSelf onCompletedWithError:error];
        }];
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

@synthesize operation = _operation;

- (void)onCompletedWithError:(NSError*)error
{
    _error = error;

    OADownloadsManager* owner = _owner;
    if (owner != nil)
    {
        [owner.completedObservable notifyEventWithKey:self andValue:_targetPath];
        [owner removeTask:self];
    }

    [_completedObservable notifyEventWithKey:self andValue:_targetPath];
}

- (void)onDownloadProgress:(double)fractionCompleted
{
    _progressCompleted = fractionCompleted;

    OADownloadsManager* owner = _owner;
    if (owner != nil)
    {
        [owner.progressCompletedObservable notifyEventWithKey:self
                                                     andValue:[NSNumber numberWithFloat:_progressCompleted]];
    }

    [_progressCompletedObservable notifyEventWithKey:self
                                            andValue:[NSNumber numberWithFloat:_progressCompleted]];

}

- (NSURLRequest*)originalRequest
{
    return _operation.request;
}

- (NSURLRequest*)currentRequest
{
    return _operation.request;
}

- (NSURLResponse*)response
{
    return _operation.response;
}

@synthesize targetPath = _targetPath;
@synthesize key = _key;

- (OADownloadTaskState)state
{
    if (_operation.isExecuting)
        return OADownloadTaskStateRunning;
    else if (_operation.isPaused)
        return OADownloadTaskStatePaused;
    else if (_operation.isFinished || _operation.isCancelled)
        return OADownloadTaskStateFinished;
    return OADownloadTaskStateUnknown;
}

- (void)resume
{
    if (_operation.isPaused)
        [_operation resume];
    else
        [_operation start];
}

- (void)pause
{
    [_operation pause];
}

- (void)stop
{
    //TODO: should produce resume data
    [_operation cancel];
}

- (void)cancel
{
    [_operation cancel];
}

@synthesize progressCompletedObservable = _progressCompletedObservable;
@synthesize progressCompleted = _progressCompleted;

@synthesize completedObservable = _completedObservable;

@synthesize error = _error;

@end
