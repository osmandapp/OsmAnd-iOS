//
//  OADownloadsManager.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OADownloadTask.h"

@interface OADownloadsManager : NSObject

@property (nonatomic) NSMutableArray *currentTasks;

- (instancetype)init;

//- (NSData*)serializeState;
//- (void*)deserializeStateFrom:(NSData*)state;
//@property(readonly, copy) NSArray* downloadTasks;

- (NSArray*)keysOfDownloadTasks;

- (NSArray*)downloadTasksWithKey:(NSString*)key;

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                       andKey:(NSString*)key;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                       andKey:(NSString*)key;

- (BOOL)saveResumeData:(NSData *)resumeData withFileName:(NSString *)fileName;
- (BOOL)deleteResumeData:(NSString *)fileName;
@end
