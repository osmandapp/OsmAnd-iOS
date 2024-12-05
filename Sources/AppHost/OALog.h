//
//  OALog.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, EOALog) {
    EOALogVerbose,
    EOALogDebug,
    EOALogInfo,
    EOALogWarning,
    EOALogError
};


#if __cplusplus
extern "C"
{
#endif
    void OALogWithLevel(EOALog level, NSString *format, ...);
    void OALog(NSString *format, ...) __attribute__((format(__NSString__, 1, 2)));
#if __cplusplus
}
#endif


@interface OALogger : NSObject

+ (void) log:(NSString *)format withArguments:(va_list)arguments;

+ (void) createLogFileIfNeeded;

+ (NSString *) getFormattedTimestamp;
+ (NSString *) getFormattedTimestampByDate:(NSDate *)date;
+ (NSString *) getFormattedThread:(NSThread *)thread;

@end
