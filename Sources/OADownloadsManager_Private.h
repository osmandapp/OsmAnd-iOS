//
//  OADownloadsManager_Private.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"

@interface OADownloadsManager (Private)

- (void)notifyTaskActivated:(id<OADownloadTask>)task;
- (void)notifyTaskDeactivated:(id<OADownloadTask>)task;

- (void)removeTask:(id<OADownloadTask>)task;

- (void)saveResumeData:(NSData*)resumeData forTask:(id<OADownloadTask>)task;
- (void)deleteResumeDataForTask:(id<OADownloadTask>)task;

@end
