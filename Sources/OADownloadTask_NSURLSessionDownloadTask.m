//
//  OADownloadTask_NSURLSessionDownloadTask.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadTask_NSURLSessionDownloadTask.h"

@implementation OADownloadTask_NSURLSessionDownloadTask
{
    OADownloadsManager* __weak _manager;
    NSURLSessionDownloadTask* _task;
}

- (instancetype)initWithManager:(OADownloadsManager*)manager
                        andTask:(NSURLSessionDownloadTask*)task
{
    self = [super init];
    if (self) {
        [self ctor];
        _manager = manager;
        _task = task;
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
/*
@property(readonly) OADownloadTaskState state;
- (void)resume;
- (void)pause;
- (void)stop;
- (void)cancel;
*/
//@property (readonly) int64_t bytesReceived;
//@property (readonly) int64_t contentSizeToReceive;

//@property (readonly, copy) NSError *error;

@end
