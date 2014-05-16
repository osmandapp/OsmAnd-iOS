//
//  OADownloadTask_NSURLSessionDownloadTask.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadTask_AFURLSessionManager.h"

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
        _progressCompleted = -1.0f;
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

/*
        - (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
    progress:(NSProgress * __autoreleasing *)progress
    destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;*/
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
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
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSURL*)getDestinationFor:(NSURL*)temporaryTargetPath
                andResponse:(NSURLResponse*)response
{
    return _targetPath != nil ? [NSURL fileURLWithPath:_targetPath] : temporaryTargetPath;
}

- (void)onCompletedWith:(NSURLResponse*)response
            andStoredAt:(NSURL*)targetPath
              withError:(NSError*)error
{

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
    return 0;
}

- (void)resume
{
    [_task resume];
}

- (void)pause
{

}

- (void)stop
{

}

- (void)cancel
{

}

@synthesize progressCompleted = _progressCompleted;

//@property (readonly) int64_t bytesReceived;
//@property (readonly) int64_t contentSizeToReceive;

//@property (readonly, copy) NSError *error;

@end
