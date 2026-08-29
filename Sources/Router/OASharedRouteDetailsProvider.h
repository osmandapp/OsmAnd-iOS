//
//  OASharedRouteDetailsProvider.h
//  OsmAnd Maps
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class OAAlarmInfo;
@class OALocationPointWrapper;
@class OARouteCalculationResult;
@class OARouteDirectionInfo;
@class OASRouteCumulativeInfo;

NS_ASSUME_NONNULL_BEGIN

/** iOS compatibility entry point for the shared Android-compatible route-details backend. */
@interface OASharedRouteDetailsProvider : NSObject

+ (NSArray<NSNumber *> *)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations;

+ (void)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations
                              result:(NSMutableArray<NSNumber *> *)result;

+ (void)updateDirectionDistancesAndTimes:(NSArray<OARouteDirectionInfo *> *)directions
                  distanceToFinishMeters:(NSArray<NSNumber *> *)distanceToFinishMeters;

+ (NSArray<OASRouteCumulativeInfo *> *)getCumulativeInfoByPosition:(NSArray<OARouteDirectionInfo *> *)directions;

+ (void)calculateIntermediateIndexesForLocations:(NSArray<CLLocation *> *)locations
                                     intermediates:(nullable NSArray<CLLocation *> *)intermediates
                                        directions:(NSMutableArray<OARouteDirectionInfo *> *)directions
                                intermediatePoints:(NSMutableArray<NSNumber *> *)intermediatePoints;

+ (nullable CLLocation *)getRouteLocationByDistance:(NSArray<CLLocation *> *)locations
                             currentRoutePointIndex:(int)currentRoutePointIndex
                                    distanceMeters:(int)distanceMeters;

+ (OAAlarmInfo *)createSpeedLimit:(int)speed
                         latitude:(double)latitude
                        longitude:(double)longitude
             speedMetersPerSecond:(float)speedMetersPerSecond;

+ (nullable OAAlarmInfo *)createAlarmInfoWithTag:(nullable NSString *)tag
                                           value:(nullable NSString *)value
                                   locationIndex:(int)locationIndex
                                        latitude:(double)latitude
                                       longitude:(double)longitude;

+ (NSArray<OALocationPointWrapper *> *)selectAlarmWrappersForRoute:(OARouteCalculationResult *)route
                                             routingAlarmsEnabled:(BOOL)routingAlarmsEnabled
                                                       showCameras:(BOOL)showCameras
                                                speakSpeedCameras:(BOOL)speakSpeedCameras
                                                       showTunnels:(BOOL)showTunnels
                                                      speakTunnels:(BOOL)speakTunnels
                                                    showPedestrian:(BOOL)showPedestrian
                                                   speakPedestrian:(BOOL)speakPedestrian
                                              showTrafficWarnings:(BOOL)showTrafficWarnings
                                             speakTrafficWarnings:(BOOL)speakTrafficWarnings;

@end

NS_ASSUME_NONNULL_END
