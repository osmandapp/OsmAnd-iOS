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

- (instancetype)init;

- (NSArray*)keysOfDownloadTasks;
- (NSArray*)keysOfActiveDownloadTasks;

- (BOOL)hasDownloadTasks;
- (BOOL)hasActiveDownloadTasks;

- (id<OADownloadTask>)firstDownloadTasksWithKey:(NSString*)key;
- (id<OADownloadTask>)firstDownloadTasksWithKeyPrefix:(NSString*)prefix;
- (id<OADownloadTask>)firstActiveDownloadTasksWithKey:(NSString*)key;
- (id<OADownloadTask>)firstActiveDownloadTasksWithKeyPrefix:(NSString*)prefix;

- (NSArray*)downloadTasksWithKey:(NSString*)key;
- (NSArray*)downloadTasksWithKeyPrefix:(NSString*)prefix;
- (NSArray*)activeDownloadTasksWithKey:(NSString*)key;
- (NSArray*)activeDownloadTasksWithKeyPrefix:(NSString*)prefix;

- (NSUInteger)numberOfDownloadTasksWithKey:(NSString*)key;
- (NSUInteger)numberOfDownloadTasksWithKeyPrefix:(NSString*)prefix;
- (NSUInteger)numberOfActiveDownloadTasksWithKey:(NSString*)key;
- (NSUInteger)numberOfActiveDownloadTasksWithKeyPrefix:(NSString*)prefix;

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                       andKey:(NSString*)key
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden;
- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                       andKey:(NSString*)key
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden;

@property(readonly) OAObservable* tasksCollectionChangedObservable;
@property(readonly) OAObservable* activeTasksCollectionChangedObservable;
@property(readonly) OAObservable* progressCompletedObservable;
@property(readonly) OAObservable* completedObservable;

@property(readonly) BOOL allowScreenTurnOff;

@end
