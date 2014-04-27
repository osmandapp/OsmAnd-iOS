//
//  OALog.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALog.h"

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

        OsmAnd::Logger::get()->log(OsmAnd::LogSeverityLevel::Info,
                                   "%s",
                                   [formattedString cStringUsingEncoding:NSASCIIStringEncoding]);
    }
#if __cplusplus
}
#endif

@implementation OALogger
@end