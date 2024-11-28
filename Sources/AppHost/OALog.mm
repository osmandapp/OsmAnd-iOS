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

@end
