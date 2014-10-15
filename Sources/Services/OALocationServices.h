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

#if defined(OSMAND_IOS_DEV)
typedef NS_ENUM(NSUInteger, OALocationServicesForcedAccuracy)
{
    OALocationServicesForcedAccuracyNone = 0,
    OALocationServicesForcedAccuracyBest,
    OALocationServicesForcedAccuracyBestForNavigation
};
#endif // defined(OSMAND_IOS_DEV)

@interface OALocationServices : NSObject

- (instancetype)initWith:(OsmAndAppInstance)app;

@property(readonly) BOOL available;
@property(readonly) BOOL compassPresent;
@property(readonly) BOOL allowed;
@property(readonly) BOOL denied;
@property(readonly) OAObservable* stateObservable;

@property(readonly) OALocationServicesStatus status;
@property(readonly) OAObservable* statusObservable;
- (void)start;
- (void)stop;

@property(readonly) CLLocation* lastKnownLocation;
@property(readonly) CLLocationDirection lastKnownHeading;
@property(readonly) OAObservable* updateObserver;

+ (void)showDeniedAlert;

- (NSString *)stringFromBearingToLocation:(CLLocation *)destinationLocation;
- (CGFloat)radiusFromBearingToLocation:(CLLocation *)destinationLocation;

#if defined(OSMAND_IOS_DEV)
@property(nonatomic) OALocationServicesForcedAccuracy forceAccuracy;
#endif // defined(OSMAND_IOS_DEV)

@end
