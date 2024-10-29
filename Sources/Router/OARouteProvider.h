//
//  OARouteProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteProvider.java
//  git revision 0b1f9e53eb0b705f8bb5786dac2f95c221efe96d
//
//  Partially syncronized
//  To sync: GPXRouteParams, GPXRouteParamsBuilder, parseOsmAndGPXRoute()

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OAAppSettings.h"
#import "OAResultMatcher.h"
#import "OALocationSimulation.h"
#import "MissingMapsCalculator.h"

#include <OsmAndCore.h>

@class OASGpxFile, OARouteCalculationResult, OAApplicationMode, OALocationsHolder, OAGpxRouteApproximation;
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

@class OASWptPt, OARouteDirectionInfo, OARouteCalculationParams;

struct RouteSegmentResult;

@interface OAGPXRouteParams : NSObject

@property (nonatomic) NSArray<CLLocation *> *points;
@property (nonatomic) NSArray<OARouteDirectionInfo *> *directions;
@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL calculatedRouteTimeSpeed;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) BOOL connectPointsStraightly;
@property (nonatomic) BOOL reverse;
@property (nonatomic) NSArray<id<OALocationPoint>> *wpt;
@property (nonatomic, readonly) NSArray<CLLocation *> *segmentEndPoints;
@property (nonatomic) std::vector<std::shared_ptr<RouteSegmentResult>> route;
@property (nonatomic, readonly) NSArray<OASWptPt *> *routePoints;
    
@property (nonatomic) BOOL addMissingTurns;
    
@end

@interface OAGPXRouteParamsBuilder : NSObject

@property (nonatomic, readonly) OASGpxFile *file;

@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL reverse;
@property (nonatomic, readonly) BOOL leftSide;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) BOOL connectPointsStraightly;
@property (nonatomic) NSInteger selectedSegment;

- (instancetype)initWithDoc:(OASGpxFile *)document;

- (OAGPXRouteParams *) build:(CLLocation *)start;
- (NSArray<CLLocation *> *) getPoints;
- (NSArray<OASimulatedLocation *> *)getSimulatedLocations;

@end

@interface OARouteProvider : NSObject

+ (CLLocation *) createLocation:(OASWptPt *)pt;
+ (NSArray<CLLocation *> *) locationsFromWpts:(NSArray<OASWptPt *> *)wpts;

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params;
- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params;

- (void) runSyncWithNativeRouting:(void (^)(void))runBlock;

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY;

- (std::shared_ptr<RoutingConfiguration>) initOsmAndRoutingConfig:(std::shared_ptr<RoutingConfigurationBuilder>)config params:(OARouteCalculationParams *)params generalRouter:(std::shared_ptr<GeneralRouter>)generalRouter;

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end;
- (std::vector<std::shared_ptr<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(std::shared_ptr<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder;

- (std::shared_ptr<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
														   gctx:(std::shared_ptr<GpxRouteApproximation>)gctx
														 points:(std::vector<std::shared_ptr<GpxPoint>> &)points
												  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                                 gpxFile:(OASGpxFile *)gpxFile
                                                        segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                                         selectedSegment:(NSInteger)selectedSegment;

- (BOOL)checkIfThereAreMissingMapsStartPoint:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets;
- (MissingMapsCalculator *)missingMapsCalculator;

@end
