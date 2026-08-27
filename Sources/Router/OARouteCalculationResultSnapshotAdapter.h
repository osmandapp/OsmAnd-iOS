//
//  OARouteCalculationResultSnapshotAdapter.h
//  OsmAnd Maps
//

#import <Foundation/Foundation.h>

#include <memory>
#include <vector>

struct RouteSegmentResult;

@class CLLocation;
@class OAAlarmInfo;
@class OARouteDirectionInfo;
@class OASRouteDetailsSnapshot;
@class OASRouteEvent;
@class OASRouteManeuver;

NS_ASSUME_NONNULL_BEGIN

/** Eager iOS copier from legacy route result values to the shared route-details contract. */
@interface OARouteCalculationResultSnapshotAdapter : NSObject

/** Copies one legacy iOS direction into the shared Android-compatible maneuver contract. */
+ (OASRouteManeuver *)copyManeuver:(OARouteDirectionInfo *)direction;

/** Copies one legacy iOS alarm into the shared Android-compatible route-event contract. */
+ (nullable OASRouteEvent *)copyEvent:(OAAlarmInfo *)alarm;

/** Copies one shared route event back to the existing iOS alarm model. */
+ (nullable OAAlarmInfo *)copyAlarmInfo:(OASRouteEvent *)event;

+ (OASRouteDetailsSnapshot *)createWithLocations:(NSArray<CLLocation *> *)locations
                                      directions:(NSArray<OARouteDirectionInfo *> *)directions
                                         segments:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)segments
                                            alarms:(NSArray<OAAlarmInfo *> *)alarms
                                      listDistance:(NSArray<NSNumber *> *)listDistance
                      intermediateDirectionIndexes:(NSArray<NSNumber *> *)intermediateDirectionIndexes
                                         profileId:(nullable NSString *)profileId
                                     routeProvider:(nullable NSNumber *)routeProvider
                                       routingTime:(float)routingTime
                                initialCalculation:(BOOL)initialCalculation
                            currentRoutePointIndex:(int)currentRoutePointIndex
                             currentDirectionIndex:(int)currentDirectionIndex
                             nextIntermediateIndex:(int)nextIntermediateIndex;

/** Converts the point-aligned legacy segment run to the shared inclusive route-point range. */
+ (void)routePointRangeWithNativeStartPointIndex:(int)nativeStartPointIndex
                             nativeEndPointIndex:(int)nativeEndPointIndex
                                        runStart:(int)runStart
                                          runEnd:(int)runEnd
                                 routePointCount:(int)routePointCount
                         routePointStartIndexOut:(int *)routePointStartIndexOut
                           routePointEndIndexOut:(int *)routePointEndIndexOut;

@end

NS_ASSUME_NONNULL_END
