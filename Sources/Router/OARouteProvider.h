//
//  OARouteProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteProvider.java
//  git revision a814e2120744068570e49689a62d48a8730873df

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OAAppSettings.h"
#import "OAGPXDocumentPrimitives.h"

#include <routeSegmentResult.h>
#include <OsmAndCore.h>

@class OAGPXDocument, OARouteCalculationResult, OAApplicationMode;
struct RoutingConfiguration;
struct RoutingConfigurationBuilder;
struct GeneralRouter;

@interface OARouteService : NSObject

@property (nonatomic, readonly) EOARouteService service;

+ (instancetype)withService:(EOARouteService)service;

+ (NSString *)getName:(EOARouteService)service;
+ (BOOL) isOnline:(EOARouteService)service;
+ (BOOL) isAvailable:(EOARouteService)service;
+ (NSArray<OARouteService *> *) getAvailableRouters;

@end

@class OALocationMark, OARouteDirectionInfo, OARouteCalculationParams;

@interface OAGPXRouteParams : NSObject

@property (nonatomic) NSArray<CLLocation *> *points;
@property (nonatomic) NSArray<OARouteDirectionInfo *> *directions;
@property (nonatomic) std::vector<std::shared_ptr<RouteSegmentResult>> route;
@property (nonatomic) NSArray<OAGpxWpt *> *routePoints;
@property (nonatomic) BOOL reverse;
@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) NSArray<id<OALocationPoint>> *wpt;
    
@property (nonatomic) BOOL addMissingTurns;

- (int) findStartIndexFromRoute:(NSArray<CLLocation *> *)route startLoc:(CLLocation *)startLoc calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts;
    
@end

@interface OAGPXRouteParamsBuilder : NSObject

@property (nonatomic, readonly) OAGPXDocument *file;

@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL reverse;
@property (nonatomic, readonly) BOOL leftSide;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;

- (instancetype)initWithDoc:(OAGPXDocument *)document;

- (OAGPXRouteParams *) build;
- (NSArray<CLLocation *> *) getPoints;

@end

@interface OARouteProvider : NSObject

+ (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am;

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params;
- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params;

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY;

- (std::shared_ptr<RoutingConfiguration>) initOsmAndRoutingConfig:(std::shared_ptr<RoutingConfigurationBuilder>)config params:(OARouteCalculationParams *)params generalRouter:(std::shared_ptr<GeneralRouter>)generalRouter;
- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am;

@end
