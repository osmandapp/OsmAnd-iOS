//
//  OADownloadsManager.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"

#import <CocoaSecurity.h>

// For iOS [6.0, 7.0)
#import "OADownloadTask_AFDownloadRequestOperation.h"

// For iOS 7.0+
#import <AFURLSessionManager.h>
#import "OADownloadTask_AFURLSessionManager.h"

#import "OADownloadTask.h"
#import "OALog.h"

#define _(name) OADownloadsManager__##name
#define ctor _(ctor)
#define dtor _(dtor)

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
    if (!isSupported_NSURLSession)
        _sessionManager = nil;
    else
    {
        NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:
                                                           [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":OADownloadsManager"]];
        sessionConfiguration.allowsCellularAccess = YES;

        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    }

    _tasksSync = [[NSObject alloc] init];
    _tasks = [[NSMutableDictionary alloc] init];

    _progressCompletedObservable = [[OAObservable alloc] init];
    _completedObservable = [[OAObservable alloc] init];
}

- (void)dtor
{
}

- (NSArray*)keysOfDownloadTasks
{
    @synchronized(_tasksSync)
    {
        return [[NSArray alloc] initWithArray:[_tasks allKeys]
                                    copyItems:YES];
    }
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

    // Create task itself
    if (_sessionManager != nil)
    {
        NSData* resumeData = [self findResumeDataForRequest:request];

        if (resumeData != nil)
        {
            task = [[OADownloadTask_AFURLSessionManager alloc] initUsingManager:_sessionManager
                                                                      withOwner:self
                                                                     andRequest:request
                                                                  andResumeData:resumeData
                                                                  andTargetPath:targetPath
                                                                         andKey:key];
        }
        else
        {
            task = [[OADownloadTask_AFURLSessionManager alloc] initUsingManager:_sessionManager
                                                                      withOwner:self
                                                                     andRequest:request
                                                                  andTargetPath:targetPath
                                                                         andKey:key];
        }
    }
    else
    {
        task = [[OADownloadTask_AFDownloadRequestOperation alloc] initWithOwner:self
                                                                     andRequest:request
                                                                  andTargetPath:targetPath
                                                                         andKey:key];
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

@synthesize progressCompletedObservable = _progressCompletedObservable;
@synthesize completedObservable = _completedObservable;

@end
