//
//  OACrashReportSender.h
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Uploads one zip to https://osmand.net/api/crash-report, as Android does: state.txt built now,
 * memory_log.txt and exit_info.txt written by OAMemoryLog before the death, the MetricKit exit
 * counts, the tail of the newest launch logs (256 KB in total) and the newest MetricKit crash diagnostics.
 */
@interface OACrashReportSender : NSObject

/// Builds the report off the main thread and calls back on the main thread.
+ (void)sendCrashReport:(NSArray<NSURL *> *)crashDiagnosticURLs completion:(void (^)(BOOL sent))completion;

/// Counts and flags only: no file names, no coordinates, no profile names, no account data.
+ (NSString *)buildState;

@end

NS_ASSUME_NONNULL_END
