//
//  OATransportRoutingHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <transportRouteResult.h>
#include <transportRouteResultSegment.h>

#import "OARoutingHelper.h"

@protocol OATransportRouteCalculationProgressCallback <NSObject>

@required

- (void) start;
- (void) updateProgress:(int)progress;
- (void) finish;

@end

@class OARouteCalculationResult;
@class OAApplicationMode;

@interface OATransportRouteResultSegment : NSObject
@property (nonatomic, assign) std::shared_ptr<TransportRouteResultSegment> segment;
- (instancetype) initWithSegment:(std::shared_ptr<TransportRouteResultSegment>)seg;
@end

@interface OATransportRoutingHelper : NSObject

+ (OATransportRoutingHelper *) sharedInstance;

@property (nonatomic) NSMapTable<NSArray<OATransportRouteResultSegment *> *, OARouteCalculationResult *> *walkingRouteSegments;

@property (nonatomic, readonly) CLLocation *startLocation;
@property (nonatomic, readonly) CLLocation *endLocation;
@property (nonatomic) OAApplicationMode *applicationMode;

@property (nonatomic) NSInteger currentRoute;

- (void) setFinalAndCurrentLocation:(CLLocation *) finalLocation currentLocation:(CLLocation *)currentLocation;
- (void) addListener:(id<OARouteInformationListener>)l;
- (BOOL) removeListener:(id<OARouteInformationListener>)lt;

- (void) clearCurrentRoute:(CLLocation *) newFinalLocation;
- (void) recalculateRouteDueToSettingsChange;
- (void) addProgressBar:(id<OATransportRouteCalculationProgressCallback>) progressRoute;

- (std::vector<SHARED_PTR<TransportRouteResult>>) getRoutes;

- (BOOL) isRouteBeingCalculated;
- (OARouteCalculationResult *) getWalkingRouteSegment:(OATransportRouteResultSegment *)s1 s2:(OATransportRouteResultSegment *)s2;
- (NSInteger) getWalkingTime:(vector<SHARED_PTR<TransportRouteResultSegment>>&) segments;
- (NSInteger) getWalkingDistance:(vector<SHARED_PTR<TransportRouteResultSegment>>&) segments;

- (OABBox) getBBox;
- (NSString *) getLastRouteCalcError;

@end

