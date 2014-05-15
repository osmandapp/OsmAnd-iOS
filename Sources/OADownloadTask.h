//
//  OADownloadTask.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OADownloadTaskState) {
    OADownloadTaskStateRunning = 0,
    OADownloadTaskStatePaused = 1,
    OADownloadTaskStateStopping = 2,
    OADownloadTaskStateCompleted = 3,
};

@protocol OADownloadTask <NSObject>

@property(readonly, copy) NSURLRequest *originalRequest;
@property(readonly, copy) NSURLRequest *currentRequest;
@property(readonly, copy) NSURLResponse *response;

@property(readonly) NSString* targetPath;
@property(readonly) NSString* key;

@property(readonly) OADownloadTaskState state;
- (void)resume;
- (void)pause;
- (void)stop;
- (void)cancel;

@property(readonly) int64_t bytesReceived;
@property(readonly) int64_t contentSizeToReceive;

@property(readonly, copy) NSError *error;

@end
