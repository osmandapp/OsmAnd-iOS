//
//  OADownloadsManager.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"
#import "OADownloadTask.h"

// For iOS [6.0, 7.0)
#import <AFDownloadRequestOperation.h>

// For iOS 7.0+
#import <AFURLSessionManager.h>
#import "OADownloadTask_AFURLSessionManager.h"

@implementation OADownloadsManager
{
    AFURLSessionManager* _sessionManager;

    NSObject* _tasksSync;
    NSMutableDictionary* _tasks;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    // Check what backend should be used
    const BOOL isSupported_NSURLSession =
    (NSClassFromString(@"NSURLSession") != nil) &&
    ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending);
    _sessionManager = isSupported_NSURLSession ? [[AFURLSessionManager alloc] init] : nil;

    _tasksSync = [[NSObject alloc] init];
    _tasks = [[NSMutableDictionary alloc] init];
}

- (void)dtor
{

}

- (NSArray*)downloadTasksWithKey:(NSString*)key
{
    @synchronized(_tasksSync)
    {
        return [NSArray arrayWithArray:[_tasks objectForKey:key]];
    }
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:nil];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:targetPath
                                  andKey:nil];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                       andKey:(NSString*)key
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:nil
                                  andKey:key];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                       andKey:(NSString*)key
{
    id<OADownloadTask> task = nil;

    // Create task itself
    if (_sessionManager != nil)
    {
        task = [[OADownloadTask_AFURLSessionManager alloc] initUsingManager:_sessionManager
                                                                  withOwner:self
                                                                 andRequest:request
                                                              andTargetPath:targetPath
                                                                     andKey:key];
    }
    else
    {
        //TODO: code for iOS 6
    }

    // Add task to collection
    @synchronized(_tasksSync)
    {
        NSMutableArray* list = [_tasks objectForKey:key];
        if (list == nil)
        {
            list = [[NSMutableArray alloc] initWithCapacity:1];
            [_tasks setObject:list forKey:key];
        }

        [list addObject:task];
    }

    return task;
}

- (void)removeTask:(id<OADownloadTask>)task
{
    // Add task to collection
    @synchronized(_tasksSync)
    {
        NSMutableArray* list = [_tasks objectForKey:task.key];
        if (list == nil)
            return;

        [list removeObject:task];
        if ([list count] == 0)
            [_tasks removeObjectForKey:task.key];
    }
}

@end
