//
//  OAMemoryLog.h
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Memory samples written to disk while the app runs, so that a crash report sent after the
 * process died carries the numbers from before the death. iOS kills a process that crosses its
 * memory limit without any crash report, so these samples and the exit record are the only
 * trace such a death leaves.
 *
 * Numbers only: memory sizes, counters and flags. No file names, no coordinates.
 */
@interface OAMemoryLog : NSObject

+ (OAMemoryLog *)sharedInstance;

/// Starts sampling and records how the previous process ended. Call once from the main thread.
- (void)start;

/// Called when a route calculation ends, cancelled or not.
- (void)onRouteCalculated;

/// The previous process was killed or crashed while the app was on screen: set by -start.
@property (nonatomic, readonly, nullable) NSString *uncleanExitIdentifier;

@property (nonatomic, readonly) NSURL *memoryLogURL;
@property (nonatomic, readonly) NSURL *exitInfoURL;
@property (nonatomic, readonly) NSURL *exitMetricsURL;

@end

NS_ASSUME_NONNULL_END
