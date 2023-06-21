//
//  OARouteCalculationParams.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteCalculationParams.java
//  git revision 5ac2f6922ac23acbea26a81b5425635e420e62f5

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARouteCalculationResult, OAWalkingRouteSegment, OAApplicationMode, OAGPXRouteParams;

@protocol OARouteCalculationProgressCallback;

@protocol OARouteCalculationResultListener <NSObject>

@required

- (void) onRouteCalculated:(OARouteCalculationResult *) route segment:(OAWalkingRouteSegment *)segment;

@end

@interface OARouteCalculationParams : NSObject

@property (nonatomic) CLLocation *start;
@property (nonatomic) CLLocation *end;
@property (nonatomic) NSArray<CLLocation *> *intermediates;
@property (nonatomic) CLLocation *currentLocation;

@property (nonatomic) OAApplicationMode *mode;
@property (nonatomic) OAGPXRouteParams *gpxRoute;
@property (nonatomic) OARouteCalculationResult *previousToRecalculate;

@property (nonatomic) BOOL onlyStartPointChanged;
@property (nonatomic) BOOL fast;
@property (nonatomic) BOOL leftSide;
@property (nonatomic) BOOL startTransportStop;
@property (nonatomic) BOOL targetTransportStop;
@property (nonatomic) BOOL inPublicTransportMode;
@property (nonatomic) BOOL extraIntermediates;
@property (nonatomic) BOOL initialCalculation;
@property (nonatomic) BOOL inSnapToRoadMode;

@property (nonatomic) id<OARouteCalculationProgressCallback> calculationProgressCallback;
@property (nonatomic) id<OARouteCalculationResultListener> resultListener;

@property (nonatomic) OAWalkingRouteSegment *walkingRouteSegment;

@end
