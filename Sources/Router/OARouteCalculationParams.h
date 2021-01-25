//
//  OARouteCalculationParams.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OARouteCalculationResult.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"

#include <OsmAndCore.h>
#include <routeCalculationProgress.h>

@class OARouteCalculationResult;
@class OAWalkingRouteSegment;

@protocol OARouteCalculationResultListener <NSObject>

@required

- (void) onRouteCalculated:(OARouteCalculationResult *) route segment:(OAWalkingRouteSegment *)segment;

@end

@interface OARouteCalculationParams : NSObject

@property (nonatomic) CLLocation *start;
@property (nonatomic) CLLocation *end;
@property (nonatomic) NSArray<CLLocation *> *intermediates;

@property (nonatomic) OAApplicationMode *mode;
@property (nonatomic) OAGPXRouteParams *gpxRoute;
@property (nonatomic) OARouteCalculationResult *previousToRecalculate;
@property (nonatomic) BOOL onlyStartPointChanged;
@property (nonatomic) BOOL fast;
@property (nonatomic) BOOL leftSide;
@property (nonatomic) BOOL inSnapToRoadMode;
@property (nonatomic) BOOL inPublicTransportMode;
@property (nonatomic) BOOL startTransportStop;
@property (nonatomic) BOOL targetTransportStop;
@property (nonatomic, assign) std::shared_ptr<RouteCalculationProgress> calculationProgress;
@property (nonatomic) id<OARouteCalculationProgressCallback> calculationProgressCallback;
@property (nonatomic) id<OARouteCalculationResultListener> resultListener;

@property (nonatomic) OAWalkingRouteSegment *walkingRouteSegment;

@end
