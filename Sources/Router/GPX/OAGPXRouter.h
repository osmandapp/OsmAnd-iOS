//
//  OAGPXRouter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObservable.h"

typedef NS_ENUM(NSInteger, OAGPXRouteVariantType)
{
    OAGPXRouteVariantPedestrianSlow = 0,
    OAGPXRouteVariantPedestrian,
    OAGPXRouteVariantBicycle,
    OAGPXRouteVariantCar,
};

@class OAGPXRouteDocument;
@class OAGPX;

@interface OAGPXRouter : NSObject

@property (nonatomic, readonly) OAGPX *gpx;
@property (nonatomic, readonly) OAGPXRouteDocument *routeDoc;

@property (readonly) OAObservable* locationUpdatedObservable;
@property (readonly) OAObservable* routeDefinedObservable;
@property (readonly) OAObservable* routeCanceledObservable;
@property (readonly) OAObservable* routeChangedObservable;
@property (readonly) OAObservable* routePointDeactivatedObservable;
@property (readonly) OAObservable* routePointActivatedObservable;

@property (nonatomic, assign) OAGPXRouteVariantType routeVariantType;

+ (OAGPXRouter *)sharedInstance;

- (BOOL)hasActiveRoute;

- (void)setRouteWithGpx:(OAGPX *)gpx;
- (void)cancelRoute;
- (void)saveRoute;
- (void)saveRouteIfModified;

- (void)refreshRoute;
- (void)refreshRoute:(BOOL)rebuildPointsOrder;

- (NSTimeInterval)getRouteDuration;
- (NSTimeInterval)getRouteDuration:(OAGPXRouteVariantType)routeVariantType;

- (void)updateDistanceAndDirection:(BOOL)forceUpdate;
- (void)refreshDestinations;
- (void)refreshDestinations:(BOOL)rebuildPointsOrder;

- (CGFloat)getMovementSpeed;
- (CGFloat)getMovementSpeed:(OAGPXRouteVariantType)routeVariantType;

- (void)sortRoute;

@end
