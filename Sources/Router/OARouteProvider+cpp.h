//
//  OARouteProvider+cpp.h
//  OsmAnd
//
//  Created by Skalii on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteProvider.h"
#import "OAResultMatcher.h"

#include <generalRouter.h>
#include <precalculatedRouteDirection.h>
#include <routePlannerFrontEnd.h>
#include <routeSegment.h>
#include <routeSegmentResult.h>
#include <routingConfiguration.h>
#include <routingContext.h>

@class OALocationsHolder, OARouteCalculationParams, OAGpxRouteApproximation, OAGPXDocument;

@interface OARoutingEnvironment(cpp)

@property (nonatomic, readonly) SHARED_PTR<RoutePlannerFrontEnd> router;
@property (nonatomic, readonly) SHARED_PTR<RoutingContext> ctx;
@property (nonatomic, readonly) SHARED_PTR<RoutingContext> complexCtx;
@property (nonatomic, readonly) SHARED_PTR<PrecalculatedRouteDirection> precalculated;

- (instancetype)initWithRouter:(SHARED_PTR<RoutePlannerFrontEnd>)router
                       context:(SHARED_PTR<RoutingContext>)ctx
                   complextCtx:(SHARED_PTR<RoutingContext>)complexCtx
                 precalculated:(SHARED_PTR<PrecalculatedRouteDirection>)precalculated;

@end

@interface OAGPXRouteParams(cpp)

@property (nonatomic) std::vector<SHARED_PTR<RouteSegmentResult>> route;

@end

@interface OARouteProvider(cpp)

- (SHARED_PTR<RoutingConfiguration>)initOsmAndRoutingConfig:(SHARED_PTR<RoutingConfigurationBuilder>)config
                                                     params:(OARouteCalculationParams *)params
                                              generalRouter:(SHARED_PTR<GeneralRouter>)generalRouter;

- (std::vector<SHARED_PTR<GpxPoint>>)generateGpxPoints:(OARoutingEnvironment *)env
                                                  gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                       locationsHolder:(OALocationsHolder *)locationsHolder;

- (SHARED_PTR<GpxRouteApproximation>)calculateGpxApproximation:(OARoutingEnvironment *)env
                                                          gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                                        points:(std::vector<SHARED_PTR<GpxPoint>> &)points
                                                 resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

+ (std::vector<SHARED_PTR<RouteSegmentResult>>)parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                           gpxFile:(OAGPXDocument *)gpxFile
                                                  segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                                   selectedSegment:(NSInteger)selectedSegment;

@end
