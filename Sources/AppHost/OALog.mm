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

// set true for printing logs without timestamp and thread ingo
static const BOOL useShortFormat = NO;

#if __cplusplus
extern "C"
{
#endif
    void OALog(NSString *format, ...)
    {
        va_list args;
        va_start(args, format);
        NSString* formattedString = [[NSString alloc] initWithFormat:format
                                                       arguments:args];
        
        
        
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
        if (pcsFormattedString != nullptr)
            OsmAnd::Logger::get()->log(OsmAnd::LogSeverityLevel::Info, "%s", pcsFormattedString);
        else
            OsmAnd::Logger::get()->log(OsmAnd::LogSeverityLevel::Info, "%s", qPrintable(QString::fromNSString(formattedString)));
    }
#if __cplusplus
}
#endif

@implementation OALogger

// for using OALog() from swift
+ (void) log:(NSString *)format withArguments:(va_list)args;
{
    NSString *logString = [[NSString alloc] initWithFormat:format arguments:args];
    OALog(@"%@", logString);
}

+ (NSString *) getFormattedTimestamp
{
    return [self getFormattedTimestampByDate:[NSDate now]];
}

+ (NSString *) getFormattedTimestampByDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) getFormattedThread:(NSThread *)thread
{
    BOOL isMain = [thread isMainThread];
    NSString *name = thread.name;
    name = (name && name.length > 0) ? [NSString stringWithFormat:@" \"%@\"", thread.name] : @"";
    NSString *quality = [self formattedQualityOfServise:thread.qualityOfService];
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());
    
    return [NSString stringWithFormat:@"[%@ %d%@%@]",
            isMain ? @"MainTread" : @"Tread",
            machTID,
            name,
            quality];
}

+ (NSString *) formattedQualityOfServise:(NSQualityOfService)quality
{
    switch (quality) {
        case NSQualityOfServiceUserInteractive:
            return @"";
            //most common format. don't write
            //return @"Interactive";
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
