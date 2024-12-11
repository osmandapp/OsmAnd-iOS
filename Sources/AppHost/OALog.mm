//
//  OALog.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALog.h"

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Logging.h>

#include <pthread.h>

/// set YES for printing logs without timestamp and thread name
static const BOOL useShortFormat = NO;

/// overwrite to YES to write log file in debug device. (while device is diconnected from XCode).
/// warning: set to YES only for diconnected device debugging time. if you connect device back to XCode, in this mode all logs printed in file will not appear in XCode console (because that's how freopen() works)
static BOOL shouldWriteToLogFileInDubug = NO;

/// overwrite to YES to stop deleting old log files in debug device.
static BOOL shouldSaveOldLogFiles = NO;

static int maxLogFilesCount = 3;


#if __cplusplus
extern "C"
{
#endif
    void OALog(NSString *format, ...)
    {
        va_list args;
        va_start(args, format);
        NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSCAssert((formattedString != nil), @"Log formatting failed");
        OALogWithLevel(EOALogInfo, formattedString);
    }

    void OALogWithLevel(EOALog level, NSString *format, ...)
    {
        va_list args;
        va_start(args, format);
        NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSCAssert((formattedString != nil), @"Log formatting failed");
        
        if (!useShortFormat)
        {
            NSString *timestamp = [OALogger getFormattedTimestamp];
            NSString *threadInfo = [OALogger getFormattedThread:[NSThread currentThread]];
            formattedString = [NSString stringWithFormat:@"%@  %@  %@",
                               timestamp,
                               threadInfo,
                               formattedString];
        }

        const char* pcsFormattedString = [formattedString cStringUsingEncoding:NSASCIIStringEncoding];
        OsmAnd::LogSeverityLevel cppLogLevel;
        if (level == EOALogVerbose)
            cppLogLevel = OsmAnd::LogSeverityLevel::Verbose;
        else if (level == EOALogDebug)
            cppLogLevel = OsmAnd::LogSeverityLevel::Debug;
        else if (level == EOALogInfo)
            cppLogLevel = OsmAnd::LogSeverityLevel::Info;
        else if (level == EOALogWarning)
            cppLogLevel = OsmAnd::LogSeverityLevel::Warning;
        else if (level == EOALogError)
            cppLogLevel = OsmAnd::LogSeverityLevel::Error;
        
        if (pcsFormattedString != nullptr)
            OsmAnd::Logger::get()->log(cppLogLevel, "%s", pcsFormattedString);
        else
            OsmAnd::Logger::get()->log(cppLogLevel, "%s", qPrintable(QString::fromNSString(formattedString)));
    }
#if __cplusplus
}
#endif


@implementation OALogger

static NSDateFormatter *_dateFormatter;

// wrapper for using OALog() from swift
+ (void) log:(NSString *)format withArguments:(va_list)args;
{
    NSString *logString = [[NSString alloc] initWithFormat:format arguments:args];
    OALog(@"%@", logString);
}

+ (void) createLogFileIfNeeded
{
    BOOL shouldCreateLogFile = NO;
    #if DEBUG
    shouldCreateLogFile = shouldWriteToLogFileInDubug;
    #else
        shouldCreateLogFile = YES;
    #endif
    
    if (shouldCreateLogFile)
        [self createLogFile];
}

+ (void) createLogFile
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logsPath = [documentsPath stringByAppendingPathComponent:@"Logs"];
    if (![manager fileExistsAtPath:logsPath])
        [manager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:logsPath error:nil];
    
    files = [[[files sortedArrayUsingComparator:^NSComparisonResult(NSString *filename1, NSString *filename2) {
        return [filename1 compare:filename2];
    }] reverseObjectEnumerator] allObjects];
    
    if (!shouldSaveOldLogFiles)
    {
        for (NSInteger i = 0; i < files.count; i++)
        {
            if (i > maxLogFilesCount)
                [manager removeItemAtPath:[logsPath stringByAppendingPathComponent:files[i]] error:nil];
        }
    }
    
    [[self dateFormatter] setDateFormat:@"MMM dd, yyyy HH:mm:ss"];
    NSString *destPath = [[logsPath stringByAppendingPathComponent:[[self dateFormatter] stringFromDate:NSDate.date]] stringByAppendingPathExtension:@"log"];
    
    freopen([destPath fileSystemRepresentation], "a+", stdout);
    freopen([destPath fileSystemRepresentation], "a+", stderr);
}

+ (NSString *) getFormattedTimestamp
{
    return [self getFormattedTimestampByDate:[NSDate now]];
}

+ (NSString *) getFormattedTimestampByDate:(NSDate *)date
{
    [[self dateFormatter] setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS"];
    return [[self dateFormatter] stringFromDate:date];
}

+ (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter)
        _dateFormatter = [[NSDateFormatter alloc] init];
    return _dateFormatter;
}

+ (NSString *) getFormattedThread:(NSThread *)thread
{
    BOOL isMain = [thread isMainThread];
    NSString *name = thread.name;
    name = (name && name.length > 0) ? [NSString stringWithFormat:@" \"%@\"", thread.name] : @"";
    NSString *quality = [self formattedQualityOfServise:thread.qualityOfService];
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());
    
    return [NSString stringWithFormat:@"[%@ %d%@%@]",
            isMain ? @"MainThread" : @"Thread",
            machTID,
            name,
            quality];
}

+ (NSString *) formattedQualityOfServise:(NSQualityOfService)quality
{
    switch (quality) {
        case NSQualityOfServiceUserInteractive:
            return @"";
        case NSQualityOfServiceUserInitiated:
            return @"  Initiated";
        case NSQualityOfServiceUtility:
            return @"  Utility";
        case NSQualityOfServiceBackground:
            return @"  Background";
        default:
            return @"  Default";
    }
}

@end
