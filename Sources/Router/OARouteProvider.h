//
//  OARouteProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteProvider.java
//  git revision 355d6bb3096f532d1398eaaebac1fcfbd4421b83
//
//  Partially syncronized
//  To sync: GPXRouteParams, GPXRouteParamsBuilder, parseOsmAndGPXRoute()

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OAAppSettings.h"
#import "OAResultMatcher.h"

#include <OsmAndCore.h>

@class OAGPXDocument, OARouteCalculationResult, OAApplicationMode, OALocationsHolder, OAGpxRouteApproximation;
struct RoutingConfiguration;
struct RoutingConfigurationBuilder;
struct GeneralRouter;
struct RoutePlannerFrontEnd;
struct GpxPoint;
struct GpxRouteApproximation;
struct RoutingContext;
struct PrecalculatedRouteDirection;

@interface OARoutingEnvironment : NSObject

@property (nonatomic, readonly) std::shared_ptr<RoutePlannerFrontEnd> router;
@property (nonatomic, readonly) std::shared_ptr<RoutingContext> ctx;
@property (nonatomic, readonly) std::shared_ptr<RoutingContext> complexCtx;
@property (nonatomic, readonly) std::shared_ptr<PrecalculatedRouteDirection> precalculated;

- (instancetype)initWithRouter:(std::shared_ptr<RoutePlannerFrontEnd>)router context:(std::shared_ptr<RoutingContext>)ctx complextCtx:(std::shared_ptr<RoutingContext>)complexCtx precalculated:(std::shared_ptr<PrecalculatedRouteDirection>)precalculated;

@end

@interface OARouteService : NSObject

@property (nonatomic, readonly) EOARouteService service;

+ (instancetype)withService:(EOARouteService)service;

+ (NSString *)getName:(EOARouteService)service;
+ (BOOL) isOnline:(EOARouteService)service;
+ (BOOL) isAvailable:(EOARouteService)service;
+ (NSArray<OARouteService *> *) getAvailableRouters;

@end

@class OALocationMark, OARouteDirectionInfo, OARouteCalculationParams, OAGpxRtePt;

struct RouteSegmentResult;

@interface OAGPXRouteParams : NSObject

@property (nonatomic) NSArray<CLLocation *> *points;
@property (nonatomic) NSArray<OARouteDirectionInfo *> *directions;
@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) BOOL reverse;
@property (nonatomic) NSArray<id<OALocationPoint>> *wpt;
@property (nonatomic, readonly) NSArray<CLLocation *> *segmentEndPoints;
@property (nonatomic) std::vector<std::shared_ptr<RouteSegmentResult>> route;
@property (nonatomic, readonly) NSArray<OAGpxRtePt *> *routePoints;
    
@property (nonatomic) BOOL addMissingTurns;
    
@end

@interface OAGPXRouteParamsBuilder : NSObject

@property (nonatomic, readonly) OAGPXDocument *file;

@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL reverse;
@property (nonatomic, readonly) BOOL leftSide;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) NSInteger selectedSegment;

- (instancetype)initWithDoc:(OAGPXDocument *)document;

- (OAGPXRouteParams *) build:(CLLocation *)start;
- (NSArray<CLLocation *> *) getPoints;

@end

@interface OARouteProvider : NSObject

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params;
- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params;

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY;

- (std::shared_ptr<RoutingConfiguration>) initOsmAndRoutingConfig:(std::shared_ptr<RoutingConfigurationBuilder>)config params:(OARouteCalculationParams *)params generalRouter:(std::shared_ptr<GeneralRouter>)generalRouter;

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end;
- (std::vector<std::shared_ptr<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(std::shared_ptr<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder;

- (std::shared_ptr<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
														   gctx:(std::shared_ptr<GpxRouteApproximation>)gctx
														 points:(std::vector<std::shared_ptr<GpxPoint>> &)points
												  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

@end
