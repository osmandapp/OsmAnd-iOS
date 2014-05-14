//
//  OADownloadTask_NSURLSessionDownloadTask.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OADownloadTask.h"

@class OADownloadsManager;

@interface OADownloadTask_NSURLSessionDownloadTask : NSObject <OADownloadTask>

- (instancetype)initWithManager:(OADownloadsManager*)manager
                        andTask:(NSURLSessionDownloadTask*)task
                  andTargetPath:(NSString*)targetPath;

@property(readonly, copy) NSURLRequest *originalRequest;
@property(readonly, copy) NSURLRequest *currentRequest;
@property(readonly, copy) NSURLResponse *response;

@property(readonly) OADownloadTaskState state;
- (void)resume;
- (void)pause;
- (void)stop;
- (void)cancel;

@property(readonly) int64_t bytesReceived;
@property(readonly) int64_t contentSizeToReceive;

@property(readonly, copy) NSError *error;

@end
