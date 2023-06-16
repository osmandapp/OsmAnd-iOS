//
//  OARoutingHelper+cpp.h
//  OsmAnd
//
//  Created by Skalii on 12.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingHelper.h"
#import "OAResultMatcher.h"

#include <routeSegmentResult.h>
#include <routePlannerFrontEnd.h>
#include <routeSegment.h>

@class OARoutingEnvironment, OALocationsHolder, OAGpxRouteApproximation;

@interface OARoutingHelper(cpp)

- (std::vector<SHARED_PTR<RouteSegmentResult>>)getUpcomingTunnel:(float)distToStart;

- (SHARED_PTR<RouteSegmentResult>)getCurrentSegmentResult;
- (SHARED_PTR<RouteSegmentResult>)getNextStreetSegmentResult;

- (std::vector<SHARED_PTR<GpxPoint>>)generateGpxPoints:(OARoutingEnvironment *)env
                                                  gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                       locationsHolder:(OALocationsHolder *)locationsHolder;

- (SHARED_PTR<GpxRouteApproximation>)calculateGpxApproximation:(OARoutingEnvironment *)env
                                                          gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                                        points:(std::vector<SHARED_PTR<GpxPoint>> &)points
                                                 resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

@end
