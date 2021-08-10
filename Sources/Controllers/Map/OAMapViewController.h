//
//  OAMapViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OACommonTypes.h"
#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"
#import <Reachability.h>
#import "OAAppSettings.h"
#import "OAPOIType.h"

#define kNotificationMapGestureAction @"kNotificationMapGestureAction"
#define kNotificationLayersConfigurationChanged @"kNotificationLayersConfigurationChanged"

#define kCorrectionMinLeftSpace 40.0
#define kCorrectionMinBottomSpace 40.0
#define kCorrectionMinLeftSpaceBBox 20.0
#define kCorrectionMinBottomSpaceBBox 20.0

#define kElevationGestureMaxThreshold 50.0f
#define kElevationMinAngle 30.0f
#define kElevationGesturePointsPerDegree 3.0f
#define kRotationGestureThresholdDegrees 5.0f
#define kZoomDeceleration 40.0f
#define kZoomVelocityAbsLimit 10.0f
#define kTargetMoveVelocityLimit 3000.0f
#define kTargetMoveDeceleration 10000.0f
#define kRotateDeceleration 500.0f
#define kRotateVelocityAbsLimitInDegrees 400.0f
#define kMapModePositionTrackingDefaultZoom 16.0f
#define kMapModePositionTrackingDefaultElevationAngle 90.0f
#define kMapBottomPosConstant 1.3f
#define kGoToMyLocationZoom 15.0f
#define kMapModeFollowDefaultZoom 18.0f
#define kMapModeFollowDefaultElevationAngle kElevationMinAngle
#define kQuickAnimationTime 0.1f
#define kFastAnimationTime 0.25f
#define kOneSecondAnimatonTime 0.5f
#define kScreensToFlyWithAnimation 4.0
#define kUserInteractionAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(1)
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

#define CENTER_CONSTANT 0
#define BOTTOM_CONSTANT 1

@class OAGpxWpt;
@class OAGpxMetadata;
@class OAGPXRouteDocument;
@class OAPOIUIFilter;
@class OASearchWptAPI;
@class OAMapRendererView;
@class OAMapLayers;
@class OAWorldRegion;

@interface OAMapViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) OAMapRendererView *mapView;
@property (weak, readonly) id<OAMapRendererViewProtocol> mapRendererView;
@property (nonatomic, readonly) OAMapLayers *mapLayers;
@property unsigned int referenceTileSizeRasterOrigInPixels;

@property (readonly) OAObservable* stateObservable;
@property (readonly) OAObservable* settingsObservable;

@property (readonly) OAObservable* azimuthObservable;
@property (readonly) OAObservable* zoomObservable;
@property (readonly) OAObservable* mapObservable;
@property (readonly) OAObservable* mapSourceUpdatedObservable;

@property (nonatomic) OAGpxWpt *foundWpt;
@property (nonatomic) NSArray *foundWptGroups;
@property (nonatomic) NSString *foundWptDocPath;

@property (nonatomic) int mapPosition;
@property (nonatomic) int mapPositionX;

@property(readonly) CGFloat displayDensityFactor;

@property(readonly) OAObservable* framePreparedObservable;
@property(readonly) OAObservable* frameDisplayedObservable;
@property(readonly) OAObservable* idleObservable;

@property(nonatomic, assign) BOOL minimap;

@property(readonly) BOOL zoomingByGesture;
@property(readonly) BOOL movingByGesture;
@property(readonly) BOOL rotatingByGesture;

@property (atomic, readonly) BOOL mapViewLoaded;

- (CLLocation *) getMapLocation;
- (float) getMapZoom;
- (void) refreshMap;

- (void) setDocFileRoute:(NSString *)fileName;
- (void) setGeoInfoDocsGpxRoute:(OAGPXRouteDocument *)doc;

- (BOOL) hasFavoriteAt:(CLLocationCoordinate2D)location;
- (BOOL) hasWptAt:(CLLocationCoordinate2D)location;

- (BOOL) findWpt:(CLLocationCoordinate2D)location;
- (BOOL) findWpt:(CLLocationCoordinate2D)location currentTrackOnly:(BOOL)currentTrackOnly;
- (BOOL) deleteFoundWpt;
- (BOOL) saveFoundWpt;
- (BOOL) addNewWpt:(OAGpxWpt *)wpt gpxFileName:(NSString *)gpxFileName;
- (NSArray<OAGpxWpt *> *) getLocationMarksOf:(NSString *)gpxFileName;

- (BOOL) canZoomIn;
- (void) animatedZoomIn;
- (BOOL) canZoomOut;
- (void) animatedZoomOut;

- (void) goToPosition:(Point31)position31
            animated:(BOOL)animated;
- (void) goToPosition:(Point31)position31
             andZoom:(CGFloat)zoom
            animated:(BOOL)animated;

- (void) correctPosition:(Point31)targetPosition31
       originalCenter31:(Point31)originalCenter31
              leftInset:(CGFloat)leftInset
            bottomInset:(CGFloat)bottomInset
             centerBBox:(BOOL)centerBBox
               animated:(BOOL)animated;

- (float) calculateMapRuler;

- (BOOL) isMyLocationVisible;
- (BOOL) isLocationVisible:(double)latitude longitude:(double)longitude;
- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading;
- (CGFloat) screensToFly:(Point31)position31;

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated;
- (void) hideContextPinMarker;

- (void) highlightRegion:(OAWorldRegion *)region;
- (void) hideRegionHighlight;

- (BOOL) simulateContextMenuPress:(UIGestureRecognizer*)recognizer;

- (void) showRouteGpxTrack;
- (void) hideRouteGpxTrack;

- (void) showTempGpxTrack:(NSString *)filePath update:(BOOL)update;
- (void) showTempGpxTrack:(NSString *)filePath;
- (void) hideTempGpxTrack:(BOOL)update;
- (void) hideTempGpxTrack;
- (void) keepTempGpxTrackVisible;

- (void) showRecGpxTrack:(BOOL)refreshData;
- (void) hideRecGpxTrack;

- (void) updatePoiLayer;

- (BOOL) deleteWpts:(NSArray *)items docPath:(NSString *)docPath;
- (BOOL) updateWpts:(NSArray *)items docPath:(NSString *)docPath updateMap:(BOOL)updateMap;
- (BOOL) updateMetadata:(OAGpxMetadata *)metadata oldPath:(NSString *)oldPath docPath:(NSString *)docPath;

- (void) setWptData:(OASearchWptAPI *)wptApi;

- (void) runWithRenderSync:(void (^)(void))runnable;
- (void) updateLayer:(NSString *)layerId;

- (UIColor *) getTransportRouteColor:(BOOL)nightMode renderAttrName:(NSString *)renderAttrName;
- (NSDictionary<NSString *, NSNumber *> *) getLineRenderingAttributes:(NSString *)renderAttrName;
- (NSDictionary<NSString *, NSNumber *> *) getGpxColors;
- (NSDictionary<NSString *, NSNumber *> *) getRoadRenderingAttributes:(NSString *)renderAttrName additionalSettings:(NSDictionary<NSString *, NSString*> *) additionalSettings;

- (void) showProgressHUDWithMessage:(NSString *)message;
- (void) hideProgressHUD;

- (void) disableRotationAnd3DView:(BOOL)disabled;
- (void) resetViewAngle;

- (void) onApplicationDestroyed;

@end
