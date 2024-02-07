//
//  OARoutingHelperUtils.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <routingConfiguration.h>
#import "OACurrentStreetName.h"
NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

struct RoutingParameter;

@interface OARoutingHelperUtils : NSObject

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards;

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards
                        shields:(NSArray *)shields;

+ (RoutingParameter)getParameterForDerivedProfile:(NSString *)key appMode:(OAApplicationMode *)appMode router:(std::shared_ptr<GeneralRouter>)router;

+ (int) lookAheadFindMinOrthogonalDistance:(CLLocation *)currentLocation routeNodes:(NSArray<CLLocation *> *)routeNodes currentRoute:(int)currentRoute iterations:(int)iterations;

+ (BOOL) checkWrongMovementDirection:(CLLocation *)currentLocation prevRouteLocation:(CLLocation *)prevRouteLocation nextRouteLocation:(CLLocation *)nextRouteLocation;

@end

NS_ASSUME_NONNULL_END
