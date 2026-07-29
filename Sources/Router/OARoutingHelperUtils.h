//
//  OARoutingHelperUtils.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <routingConfiguration.h>
#import "OACurrentStreetName.h"
#endif
NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode, OARoutingHelper;

struct RoutingParameter;

@interface OARoutingHelperUtils : NSObject

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards;
#ifdef __cplusplus
+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards
                        shields:(nullable NSArray<RoadShield *> *)shields;

+ (RoutingParameter)getParameterForDerivedProfile:(NSString *)key appMode:(OAApplicationMode *)appMode router:(std::shared_ptr<GeneralRouter>)router;
#endif

+ (int) lookAheadFindMinOrthogonalDistance:(CLLocation *)currentLocation routeNodes:(NSArray<CLLocation *> *)routeNodes currentRoute:(int)currentRoute iterations:(int)iterations;

+ (BOOL) checkWrongMovementDirection:(CLLocation *)currentLocation prevRouteLocation:(CLLocation *)prevRouteLocation nextRouteLocation:(CLLocation *)nextRouteLocation;

+ (CLLocation *) approximateBearingIfNeeded:(OARoutingHelper *)helper projection:(CLLocation *)projection location:(CLLocation *)location previousRouteLocation:(CLLocation *)previousRouteLocation currentRouteLocation:(CLLocation *)currentRouteLocation nextRouteLocation:(CLLocation *)nextRouteLocation
    previewNextTurn:(BOOL)previewNextTurn;

+ (void) updateDrivingRegionIfNeeded:(CLLocation *)newStartLocation force:(BOOL)force;

+ (nullable NSString *)routingParamsQueryValueForAppMode:(OAApplicationMode *)mode;
+ (void)applyRoutingParamsQueryValue:(nullable NSString *)params forAppMode:(OAApplicationMode *)mode;

@end

NS_ASSUME_NONNULL_END
