//
//  OADownloadsManager.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"
#import <CocoaSecurity.h>
#import <AFURLSessionManager.h>
#import "OADownloadTask_AFURLSessionManager.h"
#import "OADownloadTask.h"
#import "OAUtilities.h"
#import "OALog.h"
#import "OAObservable.h"
#import "OAAnalyticsHelper.h"

#define _(name) OADownloadsManager__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@implementation OADownloadsManager
{
    AFURLSessionManager* _sessionManager;

    NSObject* _tasksSync;
    NSMutableDictionary* _tasks;
    NSMutableArray* _tasksKeysArray;

    NSObject* _activeTasksSync;
    NSMutableDictionary* _activeTasks;

    UIBackgroundTaskIdentifier _backgroundDownloadTask;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":OADownloadsManager"]];
    sessionConfiguration.sessionSendsLaunchEvents = YES;
    sessionConfiguration.allowsCellularAccess = YES;
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
    
    _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];

    _tasksSync = [[NSObject alloc] init];
    _tasks = [[NSMutableDictionary alloc] init];
    _tasksKeysArray = [[NSMutableArray alloc] init];

    _activeTasksSync = [[NSObject alloc] init];
    _activeTasks = [[NSMutableDictionary alloc] init];

    _tasksCollectionChangedObservable = [[OAObservable alloc] init];
    _activeTasksCollectionChangedObservable = [[OAObservable alloc] init];
    _progressCompletedObservable = [[OAObservable alloc] init];
    _completedObservable = [[OAObservable alloc] init];
    _backgroundDownloadCanceledObservable = [[OAObservable alloc] init];

    _backgroundDownloadTask = UIBackgroundTaskInvalid;
}

- (void)deinit
{
}

- (BOOL)backgroundDownloadTaskActive
{
    return _backgroundDownloadTask != UIBackgroundTaskInvalid;
}

- (NSArray*)keysOfDownloadTasks
{
    @synchronized(_tasksSync)
    {
        return [[NSArray alloc] initWithArray:_tasksKeysArray];
    }
}

- (NSArray*)keysOfActiveDownloadTasks
{
    @synchronized(_activeTasksSync)
    {
        return [[NSArray alloc] initWithArray:[_activeTasks allKeys]];
    }
}

- (BOOL)hasDownloadTasks
{
    @synchronized(_tasksSync)
    {
        return ([_tasks count] > 0);
    }
}

- (BOOL)hasActiveDownloadTasks
{
    @synchronized(_activeTasksSync)
    {
        return ([_activeTasks count] > 0);
    }
}

- (id<OADownloadTask>)firstDownloadTasksWithKey:(NSString*)key
{
    @synchronized(_tasksSync)
    {
        return [[_tasks objectForKey:key] firstObject];
    }
}

- (id<OADownloadTask>)firstDownloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_tasksSync)
    {
        __block id<OADownloadTask> result = nil;

        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix])
                return;

            result = [tasks firstObject];
            *stop = (result != nil);
        }];
        
        return result;
    }
}

- (void)cancelDownloadTasks
{
    NSLog(@"Cancel all download tasks");
    @synchronized(_tasksSync)
    {
        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSArray* tasks = (NSArray*)obj_;
            for (id<OADownloadTask> task in tasks)
                [task cancel];
        }];
    }
}

- (void)pauseDownloadTasks
{
    NSLog(@"Suspend all download tasks");
    @synchronized(_tasksSync)
    {
        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSArray* tasks = (NSArray*)obj_;
            for (id<OADownloadTask> task in tasks)
                [task pause];
        }];
    }
}

- (id<OADownloadTask>)firstActiveDownloadTask
{
    @synchronized(_activeTasksSync)
    {
        __block id<OADownloadTask> result = nil;

        [_activeTasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSArray* tasks = (NSArray*)obj_;
            result = [tasks firstObject];
            *stop = (result != nil);
        }];

        return result;
    }
}

- (id<OADownloadTask>)firstActiveDownloadTasksWithKey:(NSString*)key
{
    @synchronized(_activeTasksSync)
    {
        return [[_activeTasks objectForKey:key] firstObject];
    }
}

- (id<OADownloadTask>)firstActiveDownloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_activeTasksSync)
    {
        __block id<OADownloadTask> result = nil;

        [_activeTasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix])
                return;

            result = [tasks firstObject];
            *stop = (result != nil);
        }];

        return result;
    }
}

- (NSArray*)downloadTasksWithKey:(NSString*)key
{
    @synchronized(_tasksSync)
    {
        return [NSArray arrayWithArray:[_tasks objectForKey:key]];
    }
}

- (NSArray*)downloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_tasksSync)
    {
        NSMutableArray* result = [NSMutableArray array];

        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix])
                return;

            [result addObjectsFromArray:tasks];
        }];

        return result;
    }
}

- (NSArray*)downloadTasksWithKeySuffix:(NSString*)suffix
{
    @synchronized(_tasksSync)
    {
        NSMutableArray* result = [NSMutableArray array];

        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasSuffix:suffix])
                return;

            [result addObjectsFromArray:tasks];
        }];

        return result;
    }
}

- (NSArray*)activeDownloadTasksWithKey:(NSString*)key
{
    @synchronized(_activeTasksSync)
    {
        return [NSArray arrayWithArray:[_activeTasks objectForKey:key]];
    }
}

- (NSArray*)activeDownloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_activeTasksSync)
    {
        NSMutableArray* result = [NSMutableArray array];

        [_activeTasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix])
                return;

            [result addObjectsFromArray:tasks];
        }];
        
        return result;
    }
}

- (NSArray*)activeDownloadTasksWithKeySuffix:(NSString*)suffix
{
    @synchronized(_activeTasksSync)
    {
        NSMutableArray* result = [NSMutableArray array];

        [_activeTasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasSuffix:suffix])
                return;

            [result addObjectsFromArray:tasks];
        }];

        return result;
    }
}

- (NSUInteger)numberOfDownloadTasksWithKey:(NSString*)key
{
    @synchronized(_tasksSync)
    {
        NSArray* tasks = [_tasks objectForKey:key];
        if (!tasks)
            return 0;

        return [tasks count];
    }
}

- (NSUInteger)numberOfDownloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_tasksSync)
    {
        __block NSUInteger result = 0;

        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix] || tasks == nil)
                return;

            result += [tasks count];
        }];
        
        return result;
    }
}

- (NSUInteger)numberOfDownloadTasksWithKeySuffix:(NSString*)suffix
{
    @synchronized(_tasksSync)
    {
        __block NSUInteger result = 0;

        [_tasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasSuffix:suffix] || tasks == nil)
                return;

            result += [tasks count];
        }];

        return result;
    }
}

- (NSUInteger)numberOfActiveDownloadTasksWithKey:(NSString*)key
{
    @synchronized(_activeTasksSync)
    {
        NSArray* tasks = [_activeTasks objectForKey:key];
        if (!tasks)
            return 0;

        return [tasks count];
    }
}

- (NSUInteger)numberOfActiveDownloadTasksWithKeyPrefix:(NSString*)prefix
{
    @synchronized(_activeTasksSync)
    {
        __block NSUInteger result = 0;

        [_activeTasks enumerateKeysAndObjectsUsingBlock:^(id key_, id obj_, BOOL *stop) {
            NSString* key = (NSString*)key_;
            NSArray* tasks = (NSArray*)obj_;

            if (![key hasPrefix:prefix] || tasks == nil)
                return;

            result += [tasks count];
        }];

        return result;
    }
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:nil
                                 andName:@""
                               andHidden:NO];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:targetPath
                                  andKey:nil
                                 andName:name
                               andHidden:hidden];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                       andKey:(NSString*)key
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden
{
    return [self downloadTaskWithRequest:request
                           andTargetPath:nil
                                  andKey:key
                                 andName:name
                               andHidden:hidden];
}

- (id<OADownloadTask>)downloadTaskWithRequest:(NSURLRequest*)request
                                andTargetPath:(NSString*)targetPath
                                       andKey:(NSString*)key
                                      andName:(NSString*)name
                                    andHidden:(BOOL)hidden
{
    [OAAnalyticsHelper logEvent:@"map_download_start"];

    id<OADownloadTask> task = nil;

    // Generate target path if needed
    if (targetPath == nil)
    {
        NSString* filenameTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"download.XXXXXXXX"];
        const char* pcsFilenameTemplate = [filenameTemplate fileSystemRepresentation];
        char* pcsFilename = mktemp(strdup(pcsFilenameTemplate));

        targetPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pcsFilename
                                                                                 length:strlen(pcsFilename)];
        free(pcsFilename);
    }

    NSData* resumeData = [self findResumeDataForRequest:request];
    
    if (resumeData != nil)
    {
        task = [[OADownloadTask_AFURLSessionManager alloc] initUsingManager:_sessionManager
                                                                  withOwner:self
                                                                 andRequest:request
                                                              andResumeData:resumeData
                                                              andTargetPath:targetPath
                                                                     andKey:key
                                                                    andName:name
    															  andHidden:hidden];
    }
    else
    {
        task = [[OADownloadTask_AFURLSessionManager alloc] initUsingManager:_sessionManager
                                                                  withOwner:self
                                                                 andRequest:request
                                                              andTargetPath:targetPath
                                                                     andKey:key
                                                                    andName:name
															      andHidden:hidden];
    }
    
    // Add task to collection
    @synchronized(_tasksSync)
    {
        NSMutableArray* list = [_tasks objectForKey:key];
        if (list == nil)
        {
            list = [[NSMutableArray alloc] initWithCapacity:1];
            [_tasks setObject:list forKey:key];
            [_tasksKeysArray addObject:key];
        }

        [list addObject:task];

        [_tasksCollectionChangedObservable notifyEventWithKey:self];

        // Start background task if not started yet
        if (_backgroundDownloadTask == UIBackgroundTaskInvalid)
        {
            NSLog(@"Begin background download task");
            _backgroundDownloadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"DownloadManagerBackgroundTask" expirationHandler:^{
                NSLog(@"Background download expired");
                [self pauseDownloadTasks];
                if (_backgroundDownloadTask != UIBackgroundTaskInvalid)
                {
                    NSLog(@"End background download task (time expired)");
                    [[UIApplication sharedApplication] endBackgroundTask:_backgroundDownloadTask];
                    _backgroundDownloadTask = UIBackgroundTaskInvalid;

                    [_backgroundDownloadCanceledObservable notifyEvent];
                }
            }];
        }
    }

    return task;
}

- (void)notifyTaskActivated:(id<OADownloadTask>)task
{
    @synchronized(_activeTasksSync)
    {
        NSMutableArray* list = [_activeTasks objectForKey:task.key];
        if (list == nil)
        {
            list = [[NSMutableArray alloc] initWithCapacity:1];
            [_activeTasks setObject:list forKey:task.key];
        }

        [list addObject:task];

        [_activeTasksCollectionChangedObservable notifyEventWithKey:self];
    }
}

- (void)notifyTaskDeactivated:(id<OADownloadTask>)task
{
    @synchronized(_activeTasksSync)
    {
        NSMutableArray* list = [_activeTasks objectForKey:task.key];
        if (list == nil)
            return;

        [list removeObject:task];
        if ([list count] == 0)
            [_activeTasks removeObjectForKey:task.key];

        //[_activeTasksCollectionChangedObservable notifyEventWithKey:self];
    }
}

- (void)removeTask:(id<OADownloadTask>)task
{
    @synchronized(_tasksSync)
    {
        NSMutableArray* list = [_tasks objectForKey:task.key];
        if (list == nil)
            return;

        [list removeObject:task];
        if ([list count] == 0) {
            [_tasks removeObjectForKey:task.key];
            [_tasksKeysArray removeObject:task.key];
        }

        [_tasksCollectionChangedObservable notifyEventWithKey:self];

        // When the all task are done, end the background task
        if (_tasks.count == 0 && _backgroundDownloadTask != UIBackgroundTaskInvalid)
        {
            NSLog(@"End background download task (all downloads complete");
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundDownloadTask];
            _backgroundDownloadTask = UIBackgroundTaskInvalid;
        }
    }
}

+ (NSString*)resumeDataFileNameForRequest:(NSURLRequest*)request
{
    return [@"resumeData_" stringByAppendingString:[CocoaSecurity md5:request.URL.absoluteString].hexLower];
}

- (NSData*)findResumeDataForRequest:(NSURLRequest*)request
{
    NSString* resumeDataFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[OADownloadsManager resumeDataFileNameForRequest:request]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:resumeDataFileName])
        return nil;

    NSError* error = nil;
    NSData* resumeData = [NSData dataWithContentsOfFile:resumeDataFileName options:NSDataReadingMappedIfSafe
                                    error:&error];
    if (error)
        OALog(@"Failed to read resume data from '%@': %@", resumeDataFileName, error);

    return resumeData;
}

- (void)saveResumeData:(NSData*)resumeData forTask:(id<OADownloadTask>)task_
{
    if ([task_ isKindOfClass:[OADownloadTask_AFURLSessionManager class]])
    {
        OADownloadTask_AFURLSessionManager* task = (OADownloadTask_AFURLSessionManager*)task_;
        [self saveResumeData:resumeData forRequest:task.task.originalRequest];
    }
}

- (void)saveResumeData:(NSData*)resumeData forRequest:(NSURLRequest*)request
{
    NSString* resumeDataFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[OADownloadsManager resumeDataFileNameForRequest:request]];

    NSError* error = nil;
    [resumeData writeToFile:resumeDataFileName
                 options:NSDataWritingAtomic
                      error:&error];

    if (error)
        OALog(@"Failed to save resume data to '%@': %@", resumeDataFileName, error);
}

- (void)deleteResumeDataForTask:(id<OADownloadTask>)task_
{
    if ([task_ isKindOfClass:[OADownloadTask_AFURLSessionManager class]])
    {
        OADownloadTask_AFURLSessionManager* task = (OADownloadTask_AFURLSessionManager*)task_;
        [self deleteResumeDataForRequest:task.task.originalRequest];
    }
}

- (void)deleteResumeDataForRequest:(NSURLRequest*)request
{
    NSString* resumeDataFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[OADownloadsManager resumeDataFileNameForRequest:request]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:resumeDataFileName])
        return;

    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:resumeDataFileName
                                               error:&error];
    if (error)
        OALog(@"Failed to delete resume data in '%@': %@", resumeDataFileName, error);
}

@synthesize tasksCollectionChangedObservable = _tasksCollectionChangedObservable;
@synthesize activeTasksCollectionChangedObservable = _activeTasksCollectionChangedObservable;
@synthesize progressCompletedObservable = _progressCompletedObservable;
@synthesize completedObservable = _completedObservable;
@synthesize backgroundDownloadCanceledObservable = _backgroundDownloadCanceledObservable;

@end
