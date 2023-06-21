//
//  OARouteCalculationResult+cpp.h
//  OsmAnd
//
//  Created by Skalii on 01.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteCalculationResult.h"

#include <routeSegmentResult.h>
#include <turnType.h>

@interface OARouteCalculationResult(cpp)

- (instancetype) initWithSegmentResults:(std::vector<std::shared_ptr<RouteSegmentResult>>&)list start:(CLLocation *)start end:(CLLocation *)end intermediates:(NSArray<CLLocation *> *)intermediates leftSide:(BOOL)leftSide routingTime:(float)routingTime waypoints:(NSArray<id<OALocationPoint>> *)waypoints mode:(OAApplicationMode *)mode calculateFirstAndLastPoint:(BOOL)calculateFirstAndLastPoint initialCalculation:(BOOL)initialCalculation;

- (std::vector<std::shared_ptr<RouteSegmentResult>>)getOriginalRoute;
- (std::vector<std::shared_ptr<RouteSegmentResult>>)getOriginalRoute:(int)startIndex;
- (std::vector<std::shared_ptr<RouteSegmentResult>>)getOriginalRoute:(int)startIndex includeFirstSegment:(BOOL)includeFirstSegment;
- (std::vector<std::shared_ptr<RouteSegmentResult>>)getOriginalRoute:(int)startIndex endIndex:(int)endIndex includeFirstSegment:(BOOL)includeFirstSegment;

+ (NSString *)toString:(std::shared_ptr<TurnType>)type shortName:(BOOL)shortName;

- (std::shared_ptr<RouteSegmentResult>)getCurrentSegmentResult;
- (std::shared_ptr<RouteSegmentResult>)getNextStreetSegmentResult;
- (std::vector<std::shared_ptr<RouteSegmentResult>>)getUpcomingTunnel:(float)distToStart;

@end
