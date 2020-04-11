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
@property std::shared_ptr<TransportRouteResultSegment> segment;
- (instancetype) initWithSegment:(std::shared_ptr<TransportRouteResultSegment>)seg;
@end

@interface OATransportRoutingHelper : NSObject

+ (OATransportRoutingHelper *) sharedInstance;

@property (nonatomic) NSDictionary<NSArray<OATransportRouteResultSegment *> *, OARouteCalculationResult *> *walkingRouteSegments;

@property (nonatomic, readonly) CLLocation *startLocation;
@property (nonatomic, readonly) CLLocation *endLocation;
@property (nonatomic) OAApplicationMode *applicationMode;

@property (nonatomic) NSInteger currentRoute;

- (void) setFinalAndCurrentLocation:(CLLocation *) finalLocation currentLocation:(CLLocation *)currentLocation;
- (void) addListener:(id<OARouteInformationListener>)l;

- (void) clearCurrentRoute:(CLLocation *) newFinalLocation;
- (void) recalculateRouteDueToSettingsChange;

- (std::vector<SHARED_PTR<TransportRouteResult>>) getRoutes;

@end

