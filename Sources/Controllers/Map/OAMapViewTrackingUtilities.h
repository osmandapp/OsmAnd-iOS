//
//  OAMapViewTrackingUtilities.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAMapViewController;

@interface OAMapViewTrackingUtilities : NSObject

@property (nonatomic, readonly) BOOL showViewAngle;
@property (nonatomic, readonly) BOOL movingToMyLocation;

+ (OAMapViewTrackingUtilities *)instance;

+ (BOOL) isSmallSpeedForCompass:(CLLocation *)location;
+ (BOOL) isSmallSpeedForAnimation:(CLLocation *)location;

- (BOOL) is3DMode;
- (void) switchMap3dMode;

- (BOOL) isMapLinkedToLocation;
- (void) setMapLinkedToLocation:(BOOL)isMapLinkedToLocation;
- (void) backToLocationImpl;
- (void) backToLocationImpl:(int)zoom forceZoom:(BOOL)forceZoom;

- (void) setMapViewController:(OAMapViewController *)mapViewController;
- (void) switchToRoutePlanningMode;
- (void) resetDrivingRegionUpdate;
- (void) detectDrivingRegion:(CLLocation *)location;
- (void) switchRotateMapMode;
- (void) refreshLocation;
- (void) updateSettings;
- (void) animatedAlignAzimuthToNorth;

- (void) setRotationNoneToManual;

- (CLLocation *) getDefaultLocation;
- (CLLocation *) getMapLocation;

- (CGPoint) projectRatioToVisibleMapRect:(CGPoint)ratio;
- (void) setZoomTime:(NSTimeInterval)time;

- (void)startTilting:(float)elevationAngle timePeriod:(float)timePeriod;

@end
