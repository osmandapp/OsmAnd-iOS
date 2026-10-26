//
//  OANativeRoutingMemoryGuard.h
//  OsmAnd Maps
//
//  OsmAnd/src/net/osmand/plus/routing/NativeRoutingMemoryGuard.java
//  git revision 1026318c413e7baea7b2c3d7d858d96ef8e59366

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OARouteCalculationParams, OASRouteCalculationProgress;

// Native routing (A* and HH) has no limit on its search graph, only on the road tile cache.
// The guard cancels the calculation (the native loop polls isCancelled) before the process
// reaches its memory limit, so the user gets an error instead of a crash and a restart loop.
@interface OANativeRoutingMemoryGuard : NSObject

+ (instancetype) start:(OARouteCalculationParams *)params;

// A nested route calculation can share the progress with its parent. Keep the stop reason on
// that progress so the parent can reject a partial result even after the nested guard stops.
+ (BOOL)memoryLimitExceededForProgress:(nullable OASRouteCalculationProgress *)progress;
+ (void)clearMemoryLimitExceededForProgress:(nullable OASRouteCalculationProgress *)progress;

- (BOOL) isExceeded;

// Stops watching and waits for the watcher, so the flags do not change after this returns.
// Returns YES if the guard cancelled the calculation.
- (BOOL) stop;

@end

NS_ASSUME_NONNULL_END
