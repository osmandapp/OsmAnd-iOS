//
//  OARoutingHelper+cpp.h
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingHelper.h"
#import "OAResultMatcher.h"

#include <vector>
#include <routeSegment.h>
#include <routeSegmentResult.h>

@class OAGpxRouteApproximation, OALocationsHolder;

@interface OARoutingHelper(cpp)

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getUpcomingTunnel:(float)distToStart;
- (std::vector<std::shared_ptr<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(std::shared_ptr<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder;
- (std::shared_ptr<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
                                                           gctx:(std::shared_ptr<GpxRouteApproximation>)gctx
                                                         points:(std::vector<std::shared_ptr<GpxPoint>> &)points
                                                  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

- (std::shared_ptr<RouteSegmentResult>) getCurrentSegmentResult;
- (std::shared_ptr<RouteSegmentResult>) getNextStreetSegmentResult;

@end
