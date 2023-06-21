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

@class OAGPXDocument, OARouteCalculationResult, OAApplicationMode, OALocationsHolder, OAGpxRouteApproximation, OASimulatedLocation;

@interface OARoutingEnvironment : NSObject

@end

@interface OARouteService : NSObject

@property (nonatomic, readonly) EOARouteService service;

+ (instancetype)withService:(EOARouteService)service;

+ (NSString *)getName:(EOARouteService)service;
+ (BOOL) isOnline:(EOARouteService)service;
+ (BOOL) isAvailable:(EOARouteService)service;
+ (NSArray<OARouteService *> *) getAvailableRouters;

@end

@class OAWptPt, OARouteDirectionInfo, OARouteCalculationParams;

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
@property (nonatomic, readonly) NSArray<OAWptPt *> *routePoints;
    
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
@property (nonatomic) BOOL connectPointsStraightly;
@property (nonatomic) NSInteger selectedSegment;

- (instancetype)initWithDoc:(OAGPXDocument *)document;

- (OAGPXRouteParams *) build:(CLLocation *)start;
- (NSArray<CLLocation *> *) getPoints;
- (NSArray<OASimulatedLocation *> *)getSimulatedLocations;

@end

@interface OARouteProvider : NSObject

+ (CLLocation *) createLocation:(OAWptPt *)pt;
+ (NSArray<CLLocation *> *) locationsFromWpts:(NSArray<OAWptPt *> *)wpts;

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params;
- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params;

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY;

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end;

@end
