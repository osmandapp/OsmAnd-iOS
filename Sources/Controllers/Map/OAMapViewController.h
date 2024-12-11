//
//  OAMapViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACommonTypes.h"

NS_ASSUME_NONNULL_BEGIN

#define kUserInteractionAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(1)
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

static NSString * const kNotificationMapGestureAction = @"kNotificationMapGestureAction";
static NSString * const kNotificationLayersConfigurationChanged = @"kNotificationLayersConfigurationChanged";

static const float kCorrectionMinLeftSpace = 40.0;
static const float kCorrectionMinBottomSpace = 40.0;
static const float kCorrectionMinLeftSpaceBBox = 20.0;
static const float kCorrectionMinBottomSpaceBBox = 20.0;

static const int kMinZoomLevelToAjustCameraTilt = 3;
static const int kMaxZoomLimit = 17;

static const float kDefaultElevationAngle = 90.0f;
static const float kElevationGestureMaxThreshold = 50.0f;
static const float kMapModeFollowDefaultZoom = 18.0f;
static const float kMapModeFollowDefaultElevationAngle = 30.0;
static const float kElevationGesturePointsPerDegree = 3.0f;
static const float kRotationGestureThresholdDegrees = 5.0f;
static const float kZoomDeceleration = 40.0f;
static const float kZoomVelocityAbsLimit = 10.0f;
static const float kTargetMoveVelocityLimit = 3000.0f;
static const float kTargetMoveDeceleration = 10000.0f;
static const float kRotateDeceleration = 500.0f;
static const float kRotateVelocityAbsLimitInDegrees = 400.0f;
static const float kMapModePositionTrackingDefaultZoom = 16.0f;

static const float kMapBottomPosConstant = 1.3f;
static const float kGoToMyLocationZoom = 15.0f;

static const float kQuickAnimationTime = 0.25f;
static const float kFastAnimationTime = 0.5f;
static const float kOneSecondAnimatonTime = 1.0f;
static const float kHalfSecondAnimatonTime = 0.5f;
static const float kScreensToFlyWithAnimation = 400000.0;
static const float kNavAnimatonTime = 1.0f;

static const int CENTER_CONSTANT = 0;
static const int BOTTOM_CONSTANT = 1;

@protocol OAMapRendererViewProtocol;

@class OASWptPt, OASMetadata, OASGpxFile, OASearchWptAPI, OAMapRendererView, OAMapLayers, OAWorldRegion, OAMapRendererEnvironment, OAMapPresentationEnvironment, OAObservable, LineChartView, TrackChartHelper, OASGpxTrackAnalysis, OASTrkSegment;

@interface OAMapViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) OAMapRendererView *mapView;
@property (weak, readonly, nullable) id<OAMapRendererViewProtocol> mapRendererView;
@property (nonatomic, readonly) OAMapLayers *mapLayers;
@property unsigned int referenceTileSizeRasterOrigInPixels;

@property (readonly) OAObservable *stateObservable;
@property (readonly) OAObservable *settingsObservable;

@property (readonly) OAObservable *azimuthObservable;
@property (readonly) OAObservable *zoomObservable;
@property (readonly) OAObservable *elevationAngleObservable;
@property (readonly) OAObservable *mapObservable;
@property (readonly) OAObservable *mapSourceUpdatedObservable;

@property (nonatomic, nullable) OASWptPt *foundWpt;
@property (nonatomic, nullable) NSArray *foundWptGroups;
@property (nonatomic, nullable) NSString *foundWptDocPath;

@property (nonatomic) int mapPosition;
@property (nonatomic) int mapPositionX;

@property(readonly) CGFloat displayDensityFactor;

@property(readonly) OAObservable *framePreparedObservable;

@property(nonatomic, assign) BOOL minimap;

@property(readonly) BOOL zoomingByGesture;
@property(readonly) BOOL zoomingByTapGesture;
@property(readonly) BOOL movingByGesture;
@property(readonly) BOOL rotatingByGesture;

@property(readonly) NSDate *lastRotatingByGestureTime;

@property (atomic, readonly) BOOL mapViewLoaded;

@property (readonly) OAMapRendererEnvironment *mapRendererEnv;
@property (readonly) OAMapPresentationEnvironment *mapPresentationEnv;

@property (nonatomic, assign) BOOL isCarPlayActive;
@property (nonatomic, assign) BOOL isCarPlayDashboardActive;

- (CLLocation *) getMapLocation;
- (float) getMapZoom;
- (float)getMap3DModeElevationAngle;
- (void) refreshMap;

- (BOOL) hasWptAt:(CLLocationCoordinate2D)location;

- (BOOL) findWpt:(CLLocationCoordinate2D)location;
- (BOOL) findWpt:(CLLocationCoordinate2D)location currentTrackOnly:(BOOL)currentTrackOnly;
- (BOOL) deleteFoundWpt;
- (BOOL) saveFoundWpt;
- (BOOL) addNewWpt:(OASWptPt *)wpt gpxFileName:(nullable NSString *)gpxFileName;
- (NSArray<OASWptPt *> *)getPointsOf:(nullable NSString *)gpxFileName groupName:(NSString *)groupName;

- (BOOL) canZoomIn;
- (void) zoomIn;
- (void) zoomInAndAdjustTiltAngle;
- (BOOL) canZoomOut;
- (void) zoomOut;
- (void) zoomOutAndAdjustTiltAngle;

- (void) animatedPanUp;
- (void) animatedPanDown;
- (void) animatedPanLeft;
- (void) animatedPanRight;

- (void)setViewportScaleX:(double)x y:(double)y;
- (void)setViewportScaleX:(double)x;
- (void)setViewportScaleY:(double)y;
- (void)setViewportForCarPlayScaleX:(double)x y:(double)y;
- (void)setViewportForCarPlayScaleX:(double)x;
- (void)setViewportForCarPlayScaleY:(double)y;

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

- (void) carPlayMoveGestureDetected:(UIGestureRecognizerState)state
                    numberOfTouches:(NSInteger)numberOfTouches
                        translation:(CGPoint)translation
                           velocity:(CGPoint)screenVelocity;

- (float) calculateMapRuler;

- (BOOL) isMyLocationVisible;
- (BOOL) isLocationVisible:(double)latitude longitude:(double)longitude;
- (void) updateLocation:(nullable CLLocation *)newLocation heading:(CLLocationDirection)newHeading;
- (CGFloat) screensToFly:(Point31)position31;

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated;
- (void) hideContextPinMarker;

- (void) highlightRegion:(OAWorldRegion *)region;
- (void) hideRegionHighlight;

- (BOOL) simulateContextMenuPress:(UIGestureRecognizer *)recognizer;

- (void) showTempGpxTrack:(NSString *)filePath update:(BOOL)update;
- (void) showTempGpxTrack:(NSString *)filePath;
- (void) showTempGpxTrackFromGpxFile:(OASGpxFile *)doc;
- (void) hideTempGpxTrack:(BOOL)update;
- (void) hideTempGpxTrack;
- (void) keepTempGpxTrackVisible;

- (void) showRecGpxTrack:(BOOL)refreshData;
- (void) hideRecGpxTrack;

- (void) updatePoiLayer;

- (BOOL) deleteWpts:(NSArray *)items docPath:(NSString *)docPath;
- (BOOL) updateWpts:(NSArray *)items docPath:(NSString *)docPath updateMap:(BOOL)updateMap;
- (BOOL) updateMetadata:(nullable OASMetadata *)metadata oldPath:(NSString *)oldPath docPath:(NSString *)docPath;

- (void) setWptData:(OASearchWptAPI *)wptApi;

- (void) runWithRenderSync:(nullable void (^)(void))runnable;
- (void) updateLayer:(NSString *)layerId;

- (nullable UIColor *) getTransportRouteColor:(BOOL)nightMode renderAttrName:(NSString *)renderAttrName;
- (nullable NSDictionary<NSString *, NSNumber *> *) getLineRenderingAttributes:(NSString *)renderAttrName;
- (NSDictionary<NSString *, NSNumber *> *) getGpxColors;
- (NSDictionary<NSString *, NSArray<NSNumber *> *> *) getGpxWidth;
- (NSDictionary<NSString *, NSNumber *> *) getRoadRenderingAttributes:(NSString *)renderAttrName additionalSettings:(nullable NSDictionary<NSString *, NSString*> *) additionalSettings;

- (void) showProgressHUD;
- (void) showProgressHUDWithMessage:(NSString *)message;
- (void) hideProgressHUD;

- (void) disableRotationAnd3DView:(BOOL)disabled;
- (void) resetViewAngle;

- (void) onApplicationDestroyed;

- (void) recreateHeightmapProvider;
- (void) updateElevationConfiguration;

- (void) updateTapRulerLayer;

- (void)getAltitudeForMapCenter:(void (^)(float height))callback;
- (void)getAltitudeForLatLon:(CLLocationCoordinate2D)latLon callback:(void (^)(float height))callback;

- (void)fitTrackOnMap:(LineChartView *)lineChartView
             startPos:(double)startPos
               endPos:(double)endPos
             location:(CLLocationCoordinate2D)location
             forceFit:(BOOL)forceFit
             analysis:(OASGpxTrackAnalysis *)analysis
              segment:(nullable OASTrkSegment *)segment
     trackChartHelper:(TrackChartHelper *)trackChartHelper;

@end

NS_ASSUME_NONNULL_END
