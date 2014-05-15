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
        _task = [manager downloadTaskWithRequest:request
                                        progress:nil
                                     destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                         return [self getDestinationFor:targetPath andResponse:response];
                                     }
                               completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                   [self onCompletedWith:response andStoredAt:filePath withError:error];
                               }];
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

//@property (readonly) int64_t bytesReceived;
//@property (readonly) int64_t contentSizeToReceive;

//@property (readonly, copy) NSError *error;

@end
