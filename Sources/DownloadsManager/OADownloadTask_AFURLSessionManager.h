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
                          andKey:(NSString*)key
                         andName:(NSString*)name
                       andHidden:(BOOL)hidden;

- (instancetype)initUsingManager:(AFURLSessionManager*)manager
                       withOwner:(OADownloadsManager*)owner
                      andRequest:(NSURLRequest*)request
                   andResumeData:(NSData*)resumeData
                   andTargetPath:(NSString*)targetPath
                          andKey:(NSString*)key
                         andName:(NSString*)name
                       andHidden:(BOOL)hidden;

@property(readonly) NSURLSessionDownloadTask* task;

@end
