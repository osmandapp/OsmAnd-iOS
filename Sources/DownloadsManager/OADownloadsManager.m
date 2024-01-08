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
    NSURLSessionConfiguration* sessionConfiguration;
    
    /*
    if ([OAUtilities iosVersionIsAtLeast:@"8.0"])
    {
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":OADownloadsManager"]];
    }
    else
    {
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":OADownloadsManager"]];
    }
    */
    sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":OADownloadsManager"]];
//    sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
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
}

- (void)deinit
{
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

- (BOOL)allowScreenTurnOff
{
    //if (_sessionManager != nil)
    //    return YES; // For iOS 7.0+ there's no sense of keeping screen on

    // For iOS pre-7.0 don't turn off screen while downloading something
    return ![self hasActiveDownloadTasks];
}

@end
