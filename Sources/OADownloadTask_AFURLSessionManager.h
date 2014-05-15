//
//  OADownloadTask_NSURLSessionDownloadTask.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OADownloadTask.h"

#import <AFURLSessionManager.h>

@class OADownloadsManager;

@interface OADownloadTask_AFURLSessionManager : NSObject <OADownloadTask>

- (instancetype)initUsingManager:(AFURLSessionManager*)manager
                       withOwner:(OADownloadsManager*)owner
                      andRequest:(NSURLRequest*)request
                   andTargetPath:(NSString*)targetPath
                          andKey:(NSString*)key;

@property(readonly) NSURLSessionDownloadTask* task;

@end
