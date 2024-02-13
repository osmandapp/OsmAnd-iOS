//
//  OAMapViewTrackingUtilities.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAMapViewController, OAObservable;

@interface OAMapViewTrackingUtilities : NSObject

@property (nonatomic, readonly) CLLocation *myLocation;
@property (nonatomic, readonly) CLLocationDirection heading;
@property (nonatomic, readonly) BOOL showViewAngle;
@property (nonatomic, readonly) BOOL movingToMyLocation;

+ (OAMapViewTrackingUtilities *)instance;

+ (BOOL) isSmallSpeedForCompass:(CLLocation *)location;
+ (BOOL) isSmallSpeedForAnimation:(CLLocation *)location;

- (BOOL) isIn3dMode;
- (void) switchMap3dMode;

- (BOOL) isMapLinkedToLocation;
- (void) setMapLinkedToLocation:(BOOL)isMapLinkedToLocation;
- (void) backToLocationImpl;
- (void) backToLocationImpl:(int)zoom forceZoom:(BOOL)forceZoom;

- (void) setMapViewController:(OAMapViewController *)mapViewController;
- (void) switchToRoutePlanningMode;
- (void) resetDrivingRegionUpdate;
- (void) switchRotateMapMode;
- (void) refreshLocation;
- (void) updateSettings;

- (void) setRotationNoneToManual;

- (CLLocation *) getDefaultLocation;

@end
