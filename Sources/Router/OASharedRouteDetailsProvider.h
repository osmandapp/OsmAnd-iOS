//
//  OASharedRouteDetailsProvider.h
//  OsmAnd Maps
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class OARouteCalculationResult;
@class OARouteDirectionInfo;
@class OASRouteDetailsSnapshot;
@class OASRouteSummary;

NS_ASSUME_NONNULL_BEGIN

/** iOS compatibility entry point for the shared Android-compatible route-details backend. */
@interface OASharedRouteDetailsProvider : NSObject

+ (OASRouteDetailsSnapshot *)getSnapshot:(OARouteCalculationResult *)route;
+ (OASRouteSummary *)getSummary:(OARouteCalculationResult *)route;

+ (NSArray<NSNumber *> *)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations;

+ (void)updateDirectionDistancesAndTimes:(NSArray<OARouteDirectionInfo *> *)directions
                  distanceToFinishMeters:(NSArray<NSNumber *> *)distanceToFinishMeters;

+ (nullable CLLocation *)getRouteLocationByDistance:(NSArray<CLLocation *> *)locations
                             currentRoutePointIndex:(int)currentRoutePointIndex
                                    distanceMeters:(int)distanceMeters;

@end

NS_ASSUME_NONNULL_END
