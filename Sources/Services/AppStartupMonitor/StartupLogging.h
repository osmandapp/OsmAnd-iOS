//
//  StartupLogging.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 07.07.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#ifndef StartupLogging_h
#define StartupLogging_h

#import "OsmAnd_Maps-Swift.h"
#include <stdio.h>

static const NSInteger OAStartupMaxLogFiles = 3;

static inline void OAPruneStartupLogFiles(NSString *logsPath)
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *error = nil;
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:logsPath error:&error];
    if (error != nil || files.count == 0)
        return;

    NSMutableArray<NSDictionary<NSString *, id> *> *logFiles = [NSMutableArray arrayWithCapacity:files.count];
    for (NSString *file in files)
    {
        if (![file.pathExtension isEqualToString:@"log"])
            continue;

        NSString *path = [logsPath stringByAppendingPathComponent:file];
        NSDictionary<NSFileAttributeKey, id> *attributes = [manager attributesOfItemAtPath:path error:nil];
        NSDate *date = attributes[NSFileCreationDate] ?: [NSDate dateWithTimeIntervalSince1970:0];
        [logFiles addObject:@{ @"path" : path, @"date" : date }];
    }

    if (logFiles.count <= OAStartupMaxLogFiles)
        return;

    [logFiles sortUsingComparator:^NSComparisonResult(NSDictionary<NSString *, id> *file1, NSDictionary<NSString *, id> *file2) {
        return [file2[@"date"] compare:file1[@"date"]];
    }];

    for (NSInteger i = OAStartupMaxLogFiles; i < logFiles.count; i++)
        [manager removeItemAtPath:logFiles[i][@"path"] error:nil];
}

static inline void OAInitializeStartupLogFileIfNeeded(void)
{
#if DEBUG
    return;
#else
    static BOOL initialized = NO;
    if (initialized)
        return;

    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logsPath = [documentsPath stringByAppendingPathComponent:@"Logs"];
    if (![manager fileExistsAtPath:logsPath])
        [manager createDirectoryAtPath:logsPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *fileName = [NSString stringWithFormat:@"%@.log", [formatter stringFromDate:NSDate.date]];
    NSString *destPath = [logsPath stringByAppendingPathComponent:fileName];
    FILE *stdoutFile = freopen([destPath fileSystemRepresentation], "a+", stdout);
    FILE *stderrFile = freopen([destPath fileSystemRepresentation], "a+", stderr);
    if (stdoutFile != NULL && stderrFile != NULL)
    {
        initialized = YES;
        OAPruneStartupLogFiles(logsPath);
    }
#endif
}

// Logs startup event with the current Objective-C self as class/object context.
#define LogStartup(eventName) [[AppStartupMonitor shared] log:(eventName) from:self]

// Logs startup event without class/object context.
#define LogStartupSimple(eventName) [[AppStartupMonitor shared] log:(eventName) from:nil]

// Logs app/device/runtime launch context once.
#define LogStartupContext(launchOptions) [[AppStartupMonitor shared] logLaunchContext:(launchOptions)]

// Marks startup as finished and prints timeline.
#define MarkStartupFinished() [[AppStartupMonitor shared] markStartupFinishedIfNeeded]

#endif /* StartupLogging_h */
