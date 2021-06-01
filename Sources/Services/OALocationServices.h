//
//  OALocationServices.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "OACommonTypes.h"
#import "OAObservable.h"

typedef NS_ENUM(NSUInteger, OALocationServicesStatus)
{
    OALocationServicesStatusInactive,
    OALocationServicesStatusActive,
    OALocationServicesStatusAuthorizing,
    OALocationServicesStatusSuspended
};

@class OALocationSimulation;

@interface CLLocation (util)

- (double) bearingTo:(CLLocation *)location;

@end

@interface OALocationServices : NSObject

- (instancetype) initWith:(OsmAndAppInstance)app;

@property (readonly) BOOL available;
@property (readonly) BOOL compassPresent;
@property (readonly) BOOL allowed;
@property (readonly) BOOL denied;
@property (readonly) OAObservable* stateObservable;

@property (readonly) OALocationServicesStatus status;
@property (readonly) OAObservable* statusObservable;

- (void) start;
- (void) stop;

@property (readonly) CLLocation* lastKnownLocation;
@property (readonly) CLLocationDirection lastKnownHeading;
@property (readonly) CLLocationDirection lastKnownMagneticHeading;
@property (readonly) CLLocationDegrees lastKnownDeclination;
@property (readonly) OAObservable *updateObserver;
@property (readonly) OAObservable *updateFirstTimeObserver;
@property (readonly) OALocationSimulation *locationSimulation;

+ (void) showDeniedAlert;

- (NSString *) stringFromBearingToLocation:(CLLocation *)destinationLocation;
- (CGFloat) radiusFromBearingToLocation:(CLLocation *)destinationLocation;
- (CGFloat) radiusFromBearingToLocation:(CLLocation *)destinationLocation sourceLocation:(CLLocation*)sourceLocation;
- (CGFloat) radiusFromBearingToLatitude:(double)latitude longitude:(double)longitude;
- (CGFloat) radiusFromBearingToLatitude:(double)latitude longitude:(double)longitude sourceLocation:(CLLocation*)sourceLocation;

+ (void) computeDistanceAndBearing:(double)lat1 lon1:(double)lon1 lat2:(double)lat2 lon2:(double)lon2 distance:(double *)distance initialBearing:(double *)initialBearing /*finalBearing:(double *)finalBearing*/;

+ (BOOL) isPointAccurateForRouting:(CLLocation *)loc;

- (void) setLocationFromSimulation:(CLLocation *)location;

@end
