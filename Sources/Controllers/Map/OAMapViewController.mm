//
//  OAMapViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapViewController.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"

#import <UIActionSheet+Blocks.h>

#import "OAAppData.h"
#import "OAMapRendererView.h"

#import "OAAutoObserverProxy.h"
#import "OAAddFavoriteViewController.h"
#import "OANavigationController.h"
#import "OAResourcesBaseViewController.h"
#import "OAFavoriteItemViewController.h"

#include <OpenGLES/ES2/gl.h>

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
#if defined(OSMAND_IOS_DEV)
#   include <OsmAndCore/Map/ObfMapObjectsMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapPrimitivesMetricsLayerProvider.h>
#   include <OsmAndCore/Map/MapRasterMetricsLayerProvider.h>
#endif // defined(OSMAND_IOS_DEV)

#import "OANativeUtilities.h"
#import "OALog.h"
#include "Localization.h"

#define kElevationGestureMaxThreshold 50.0f
#define kElevationMinAngle 30.0f
#define kElevationGesturePointsPerDegree 3.0f
#define kRotationGestureThresholdDegrees 5.0f
#define kZoomDeceleration 40.0f
#define kZoomVelocityAbsLimit 10.0f
#define kTargetMoveDeceleration 4800.0f
#define kRotateDeceleration 500.0f
#define kRotateVelocityAbsLimitInDegrees 400.0f
#define kMapModePositionTrackingDefaultZoom 15.0f
#define kMapModePositionTrackingDefaultElevationAngle 90.0f
#define kMapModeFollowDefaultZoom 18.0f
#define kMapModeFollowDefaultElevationAngle kElevationMinAngle
#define kQuickAnimationTime 0.4f
#define kOneSecondAnimatonTime 1.0f
#define kUserInteractionAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(1)
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

#define _(name) OAMapRendererViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OAMapViewController ()
@end

@implementation OAMapViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _lastMapSourceChangeObserver;

    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    
    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;

    // "My location" marker, "My course" marker and collection
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKey;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKey;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKey;

    // Context pin marker
    std::shared_ptr<OsmAnd::MapMarkersCollection> _contextPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _contextPinMarker;

    // Favorites presenter
    std::shared_ptr<OsmAnd::FavoriteLocationsPresenter> _favoritesPresenter;

    OAAutoObserverProxy* _appModeObserver;
    OAAppMode _lastAppMode;

    OAAutoObserverProxy* _mapModeObserver;
    OAMapMode _lastMapMode;
    OAAutoObserverProxy* _dayNightModeObserver;

    OAAutoObserverProxy* _locationServicesStatusObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    
    OAAutoObserverProxy* _stateObserver;
    OAAutoObserverProxy* _settingsObserver;
    OAAutoObserverProxy* _framePreparedObserver;

    OAAutoObserverProxy* _layersConfigurationObserver;
    
    UIPinchGestureRecognizer* _grZoom;
    CGFloat _initialZoomLevelDuringGesture;

    UIPanGestureRecognizer* _grMove;
    
    UIRotationGestureRecognizer* _grRotate;
    CGFloat _accumulatedRotationAngle;
    
    UITapGestureRecognizer* _grZoomIn;
    
    UITapGestureRecognizer* _grZoomOut;
    
    UIPanGestureRecognizer* _grElevation;

    UILongPressGestureRecognizer* _grPointContextMenu;

    bool _lastPositionTrackStateCaptured;
    float _lastAzimuthInPositionTrack;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _rendererSync = [[NSObject alloc] init];

    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];
    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     QList< QString > merged;
                                                                     merged << added << removed << updated;
                                                                     [self onLocalResourcesChanged:merged];
                                                                 });

    
    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];
    _lastAppMode = _app.appMode;

    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];
    _lastMapMode = _app.mapMode;

    _dayNightModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onDayNightModeChanged)
                                                  andObserve:_app.dayNightModeObservable];

    _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesStatusChanged)
                                                                 andObserve:_app.locationServices.statusObservable];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];

    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _azimuthObservable = [[OAObservable alloc] init];
    _zoomObservable = [[OAObservable alloc] init];
    _mapObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];
    _stateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                               withHandler:@selector(onMapRendererStateChanged:withKey:)];
    _settingsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onMapRendererSettingsChanged:withKey:)];
    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged)
                                                              andObserve:_app.data.mapLayersConfiguration.changeObservable];
    
    
    _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onMapRendererFramePrepared)];

    // Subscribe to application notifications to correctly suspend and resume rendering
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    // Subscribe to settings change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLanguageSettingsChange)
                                                 name:kNotificationSettingsLanguageChange
                                               object:nil];

    // Create gesture recognizers:
    
    // - Zoom gesture
    _grZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(zoomGestureDetected:)];
    _grZoom.delegate = self;
    
    // - Move gesture
    _grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(moveGestureDetected:)];
    _grMove.delegate = self;
    
    // - Rotation gesture
    _grRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(rotateGestureDetected:)];
    _grRotate.delegate = self;
    
    // - Zoom-in gesture
    _grZoomIn = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(zoomInGestureDetected:)];
    _grZoomIn.delegate = self;
    _grZoomIn.numberOfTapsRequired = 2;
    _grZoomIn.numberOfTouchesRequired = 1;
    
    // - Zoom-out gesture
    _grZoomOut = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(zoomOutGestureDetected:)];
    _grZoomOut.delegate = self;
    _grZoomOut.numberOfTapsRequired = 2;
    _grZoomOut.numberOfTouchesRequired = 2;
    
    // - Elevation gesture
    _grElevation = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(elevationGestureDetected:)];
    _grElevation.delegate = self;
    _grElevation.minimumNumberOfTouches = 2;
    _grElevation.maximumNumberOfTouches = 2;

    // - Long-press context menu of a point gesture
    _grPointContextMenu = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(pointContextMenuGestureDetected:)];
    _grPointContextMenu.delegate = self;

    _lastPositionTrackStateCaptured = false;

    // Create location and course markers
    _myMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilder;

    locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilder.setIsHidden(true);
    _myLocationMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myLocationMainIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_icon"]);
    _myLocationHeadingIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myLocationHeadingIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon"]);
    _myLocationMarker = locationAndCourseMarkerBuilder.buildAndAddToCollection(_myMarkersCollection);

    locationAndCourseMarkerBuilder.clearOnMapSurfaceIcons();
    _myCourseMainIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilder.addOnMapSurfaceIcon(_myCourseMainIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_course_marker_icon"]);
    _myCourseMarker = locationAndCourseMarkerBuilder.buildAndAddToCollection(_myMarkersCollection);

    // Create context pin marker
    _contextPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    _contextPinMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(std::numeric_limits<int>::max() - 1)
        .setIsHidden(true)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"context_pin_marker_icon"])
        .buildAndAddToCollection(_contextPinMarkersCollection);
    
    // Create favorites presenter
    _favoritesPresenter.reset(new OsmAnd::FavoriteLocationsPresenter(_app.favoritesCollection,
                                                                     [OANativeUtilities skBitmapFromPngResource:@"favorite_location_pin_marker_icon"]));

#if defined(OSMAND_IOS_DEV)
    _hideStaticSymbols = NO;
    _visualMetricsMode = OAVisualMetricsModeOff;
    _forceDisplayDensityFactor = NO;
    _forcedDisplayDensityFactor = self.displayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)
}

- (void)deinit
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);

    // Unsubscribe from application notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Allow view to tear down OpenGLES context
    if ([self isViewLoaded])
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        [mapView releaseContext];
    }
}

- (void)loadView
{
    OALog(@"Creating Map Renderer view...");

    // Inflate map renderer view
    OAMapRendererView* mapView = [[OAMapRendererView alloc] init];
    self.view = mapView;
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.contentScaleFactor = [[UIScreen mainScreen] scale];
    [_stateObserver observe:mapView.stateObservable];
    [_settingsObserver observe:mapView.settingsObservable];
    [_framePreparedObserver observe:mapView.framePreparedObservable];

    // Add "My location" and "My course" markers
    [mapView addKeyedSymbolsProvider:_myMarkersCollection];

    // Add context pin markers
    [mapView addKeyedSymbolsProvider:_contextPinMarkersCollection];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    mapView.userInteractionEnabled = YES;
    mapView.multipleTouchEnabled = YES;
    [mapView createContext];
    
    // Attach gesture recognizers:
    [mapView addGestureRecognizer:_grZoom];
    [mapView addGestureRecognizer:_grMove];
    [mapView addGestureRecognizer:_grRotate];
    [mapView addGestureRecognizer:_grZoomIn];
    [mapView addGestureRecognizer:_grZoomOut];
    [mapView addGestureRecognizer:_grElevation];
    [mapView addGestureRecognizer:_grPointContextMenu];
    
    // Adjust map-view target, zoom, azimuth and elevation angle to match last viewed
    mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                      _app.data.mapLastViewedState.target31.y);
    mapView.zoom = _app.data.mapLastViewedState.zoom;
    mapView.azimuth = _app.data.mapLastViewedState.azimuth;
    mapView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;

    // Mark that map source is no longer valid
    _mapSourceInvalidated = YES;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Resume rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView resumeRendering];
    
    // Update map source (if needed)
    if (_mapSourceInvalidated)
    {
        [self updateCurrentMapSource];

        _mapSourceInvalidated = NO;
    }
    
    
    // IOS-208
    
    int showMapIterator = [[NSUserDefaults standardUserDefaults] integerForKey:kShowMapIterator];
    [[NSUserDefaults standardUserDefaults] setInteger:++showMapIterator forKey:kShowMapIterator];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BOOL mapDownloadStopReminding = [[NSUserDefaults standardUserDefaults] boolForKey:kMapDownloadStopReminding];
    const auto worldMap = _app.resourcesManager->getLocalResource(kWorldBasemapKey);
    if (!mapDownloadStopReminding && !worldMap && (showMapIterator == 1 || showMapIterator % 6 == 0) ) {
        
        const auto repositoryMap = _app.resourcesManager->getResourceInRepository(kWorldBasemapKey);
        NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:repositoryMap->packageSize
                                                                   countStyle:NSByteCountFormatterCountStyleFile];
        
        NSString* message = nil;
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
            message = OALocalizedString(@"Install detailed map overview to get more information about your locations.\n\nDowloading requires %1$@ over cellular network. This may incur high charges. Proceed?",
                                        stringifiedSize);
        else
            message = OALocalizedString(@"Install detailed map overview to get more information about your locations.\n\nDowloading requires %1$@ over WiFi network. Proceed?",
                                        stringifiedSize);
        
        UIAlertView *mapDownloadAlert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"Download") message:message delegate:self  cancelButtonTitle:OALocalizedString(@"No, thanks") otherButtonTitles:OALocalizedString(@"Download map now"), OALocalizedString(@"Remind me later"), nil];
        mapDownloadAlert.tag = kUIAlertViewMapDownloadTag;
        [mapDownloadAlert show];
        
    }

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self isViewLoaded])
        return;

    // Suspend rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView suspendRendering];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    if (![self isViewLoaded])
        return;

    // Suspend rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView suspendRendering];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    if (![self isViewLoaded])
        return;

    // Resume rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView resumeRendering];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self isViewLoaded])
        return NO;
    
    if (gestureRecognizer == _grElevation)
    {
        // Elevation gesture recognizer requires 2 touch points
        if (gestureRecognizer.numberOfTouches != 2)
            return NO;

        // Calculate vertical distance between touches
        const auto touch1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
        const auto touch2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
        const auto verticalDistance = fabsf(touch1.y - touch2.y);

        // Ignore this touch if vertical distance is too large
        if (verticalDistance >= kElevationGestureMaxThreshold)
        {
            OALog(@"Elevation gesture ignored due to vertical distance %f", verticalDistance);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Elevation gesture recognizer should not be mixed with others
    if (gestureRecognizer == _grElevation || otherGestureRecognizer == _grElevation)
        return NO;
    
    return YES;
}

- (void)zoomGestureDetected:(UIPinchGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // If gesture has just began, just capture current zoom
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        [mapView suspendSymbolsUpdate];

        _initialZoomLevelDuringGesture = mapView.zoom;
        return;
    }
    
    // If gesture has been cancelled or failed, restore previous zoom
    if (recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        mapView.zoom = _initialZoomLevelDuringGesture;
        return;
    }
    
    // Capture current touch center point
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocationBefore;
    [mapView convert:centerPoint toLocation:&centerLocationBefore];
    
    // Change zoom
    mapView.zoom = _initialZoomLevelDuringGesture - (1.0f - recognizer.scale);

    // Adjust current target position to keep touch center the same
    OsmAnd::PointI centerLocationAfter;
    [mapView convert:centerPoint toLocation:&centerLocationAfter];
    const auto centerLocationDelta = centerLocationAfter - centerLocationBefore;
    [mapView setTarget31:mapView.target31 - centerLocationDelta];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Resume symbols update
        [mapView resumeSymbolsUpdate];
    }

    // If this is the end of gesture, get velocity for animation
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        float velocity = qBound(-kZoomVelocityAbsLimit, recognizer.velocity, kZoomVelocityAbsLimit);
        mapView.animator->animateZoomWith(velocity,
                                          kZoomDeceleration,
                                          kUserInteractionAnimationKey);
        mapView.animator->resume();
    }
}

- (void)moveGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        [mapView suspendSymbolsUpdate];
    }
    
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation = [recognizer translationInView:self.view];
    translation.x *= mapView.contentScaleFactor;
    translation.y *= mapView.contentScaleFactor;

    // Take into account current azimuth and reproject to map space (points)
    const float angle = qDegreesToRadians(mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;

    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    const uint32_t tileSize31 = (1u << (31 - mapView.zoomLevel));
    const double scale31 = static_cast<double>(tileSize31) / mapView.currentTileSizeOnScreenInPixels;

    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    mapView.target31 = target31;
    
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Resume symbols update
        [mapView resumeSymbolsUpdate];
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        // Obtain velocity from recognizer
        CGPoint screenVelocity = [recognizer velocityInView:self.view];
        screenVelocity.x *= mapView.contentScaleFactor;
        screenVelocity.y *= mapView.contentScaleFactor;
        
        // Take into account current azimuth and reproject to map space (points)
        CGPoint velocityInMapSpace;
        velocityInMapSpace.x = screenVelocity.x * cosAngle - screenVelocity.y * sinAngle;
        velocityInMapSpace.y = screenVelocity.x * sinAngle + screenVelocity.y * cosAngle;
        
        // Rescale speed to 31 coordinates
        OsmAnd::PointD velocity;
        velocity.x = -velocityInMapSpace.x * scale31;
        velocity.y = -velocityInMapSpace.y * scale31;
        
        mapView.animator->animateTargetWith(velocity,
                                            OsmAnd::PointD(kTargetMoveDeceleration * scale31, kTargetMoveDeceleration * scale31),
                                            kUserInteractionAnimationKey);
        mapView.animator->resume();
    }
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)rotateGestureDetected:(UIRotationGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Zeroify accumulated rotation on gesture begin
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        [mapView resumeSymbolsUpdate];

        _accumulatedRotationAngle = 0.0f;
    }
    
    // Check if accumulated rotation is greater than threshold
    if (fabs(_accumulatedRotationAngle) < kRotationGestureThresholdDegrees)
    {
        _accumulatedRotationAngle += qRadiansToDegrees(recognizer.rotation);
        [recognizer setRotation:0];

        return;
    }
    
    // Get center of all touches as centroid
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    
    // Convert point from screen to location
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    
    // Rotate current target around center location
    OsmAnd::PointI target = mapView.target31;
    target -= centerLocation;
    OsmAnd::PointI newTarget;
    const float cosAngle = cosf(-recognizer.rotation);
    const float sinAngle = sinf(-recognizer.rotation);
    newTarget.x = target.x * cosAngle - target.y * sinAngle;
    newTarget.y = target.x * sinAngle + target.y * cosAngle;
    newTarget += centerLocation;
    mapView.target31 = newTarget;
    
    // Set rotation
    mapView.azimuth -= qRadiansToDegrees(recognizer.rotation);

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Resume symbols update
        [mapView resumeSymbolsUpdate];
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        float velocity = qBound(-kRotateVelocityAbsLimitInDegrees, -qRadiansToDegrees(recognizer.velocity), kRotateVelocityAbsLimitInDegrees);
        mapView.animator->animateAzimuthWith(velocity,
                                             kRotateDeceleration,
                                             kUserInteractionAnimationKey);
        mapView.animator->resume();
    }
    [recognizer setRotation:0];
}

- (void)zoomInGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];

    // When user gesture has began, stop all animations
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    _app.mapMode = OAMapModeFree;

    // Put tap location to center of screen
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    mapView.animator->animateTargetTo(centerLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Linear,
                                      kUserInteractionAnimationKey);
    
    // Increate zoom by 1
    zoomDelta += 1.0f;
    mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    mapView.animator->resume();
}

- (void)zoomOutGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];

    // When user gesture has began, stop all animations
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    _app.mapMode = OAMapModeFree;
    
    // Put tap location to center of screen
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    mapView.animator->animateTargetTo(centerLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Linear,
                                      kUserInteractionAnimationKey);
    
    // Decrease zoom by 1
    zoomDelta -= 1.0f;
    mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    mapView.animator->resume();
}

- (void)elevationGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();

        // Suspend symbols update
        [mapView resumeSymbolsUpdate];
    }
    
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat angleDelta = translation.y / static_cast<CGFloat>(kElevationGesturePointsPerDegree);
    CGFloat angle = mapView.elevationAngle;
    angle -= angleDelta;
    if (angle < kElevationMinAngle)
        angle = kElevationMinAngle;
    mapView.elevationAngle = angle;
    [recognizer setTranslation:CGPointZero inView:self.view];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Resume symbols update
        [mapView resumeSymbolsUpdate];
    }
}

- (void)pointContextMenuGestureDetected:(UILongPressGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Capture only last state
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Get location of the gesture
    CGPoint touchPoint = [recognizer locationOfTouch:0 inView:self.view];
    touchPoint.x *= mapView.contentScaleFactor;
    touchPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [mapView convert:touchPoint toLocation:&touchLocation];

    // Format location
    const double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    const double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    NSString* formattedLocation = [[[OsmAndApp instance] locationFormatter] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];

    // Show context pin marker
    _contextPinMarker->setPosition(touchLocation);
    _contextPinMarker->setIsHidden(false);
    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object: self
                                                      userInfo:@{@"lat": [NSNumber numberWithDouble:lat],
                                                                 @"lon": [NSNumber numberWithDouble:lon],
                                                                 @"touchPoint.x": [NSNumber numberWithFloat:touchPoint.x],
                                                                 @"touchPoint.y": [NSNumber numberWithFloat:touchPoint.y]}];
    return;
    
    // Show corresponding action-sheet
    static NSString* const locationDetailsAction = OALocalizedString(@"What's here?");
    static NSString* const addToFavoritesAction = OALocalizedString(@"Add to favorites");
    static NSString* const shareLocationAction = OALocalizedString(@"Share this location");
    static NSString* const targetpointLocationAction = OALocalizedString(@"Set as target point");
    static NSArray* const actions = @[/*locationDetailsAction,*/
                                      addToFavoritesAction,
                                      targetpointLocationAction,
                                      shareLocationAction];
    [UIActionSheet presentOnView:mapView
                       withTitle:formattedLocation
                    cancelButton:OALocalizedString(@"Cancel")
               destructiveButton:nil
                    otherButtons:actions
                        onCancel:^(UIActionSheet *) {
                            _contextPinMarker->setIsHidden(true);
                        }
                   onDestructive:nil
                 onClickedButton:^(UIActionSheet *, NSUInteger actionIdx) {
                     NSString* action = [actions objectAtIndex:actionIdx];
                     if (action == locationDetailsAction)
                     {
                         OALog(@"whats here");
                     }
                     else if (action == targetpointLocationAction)
                     {
                         OALog(@"set as target point");
                     }
                     else if (action == addToFavoritesAction)
                     {
                         
                         OAFavoriteItemViewController* addFavoriteVC = [[OAFavoriteItemViewController alloc] initWithLocation:CLLocationCoordinate2DMake(lat, lon)
                                                                                                                     andTitle:formattedLocation];

                         if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                         {
                             // For iPhone and iPod, push menu to navigation controller
                             [self.navigationController pushViewController:addFavoriteVC
                                                                  animated:YES];
                         }
                         else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
                         {
                             // For iPad, open menu in a popover with it's own navigation controller
                             UINavigationController* navigationController = [[OANavigationController alloc] initWithRootViewController:addFavoriteVC];
                             UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];

                             [popoverController presentPopoverFromRect:CGRectMake(touchPoint.x, touchPoint.y, 0.0f, 0.0f)
                                                                inView:mapView
                                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                                              animated:YES];
                         }
                     }
                     else if (action == shareLocationAction)
                     {

                         UIImage *image = [mapView getGLScreenshot];
                         NSString *string = [NSString stringWithFormat:@"Look at this location: %@", formattedLocation];
                          
                         UIActivityViewController *activityViewController =
                         [[UIActivityViewController alloc] initWithActivityItems:@[image, string]
                                                           applicationActivities:nil];
                         
                         [self.navigationController presentViewController:activityViewController
                                                            animated:YES
                                                          completion:^{
                                                          }];
                     }

                     _contextPinMarker->setIsHidden(true);
                 }];
}

- (id<OAMapRendererViewProtocol>)mapRendererView
{
    if (![self isViewLoaded])
        return nil;
    return (OAMapRendererView*)self.view;
}

@synthesize stateObservable = _stateObservable;
@synthesize settingsObservable = _settingsObservable;

@synthesize azimuthObservable = _azimuthObservable;


- (void)onMapRendererStateChanged:(id)observer withKey:(id)key
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    switch ([key unsignedIntegerValue])
    {
        case OAMapRendererViewStateEntryAzimuth:
            [_azimuthObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:mapView.azimuth]];
            _app.data.mapLastViewedState.azimuth = mapView.azimuth;
            break;
        case OAMapRendererViewStateEntryZoom:
            [_zoomObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:mapView.zoom]];
            _app.data.mapLastViewedState.zoom = mapView.zoom;
            break;
        case OAMapRendererViewStateEntryElevationAngle:
            _app.data.mapLastViewedState.elevationAngle = mapView.elevationAngle;
            break;
        case OAMapRendererViewStateEntryTarget:
            OsmAnd::PointI newTarget31 = mapView.target31;
            Point31 newTarget31_converted;
            newTarget31_converted.x = newTarget31.x;
            newTarget31_converted.y = newTarget31.y;
            _app.data.mapLastViewedState.target31 = newTarget31_converted;
            [_mapObservable notifyEventWithKey:nil ];
            break;
    }

    [_stateObservable notifyEventWithKey:key];
}

- (void)onMapRendererSettingsChanged:(id)observer withKey:(id)key
{
    [_stateObservable notifyEventWithKey:key];
}

- (void)onMapRendererFramePrepared
{
    [_framePreparedObservable notifyEvent];
}

- (void)animatedAlignAzimuthToNorth
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // When user gesture has began, stop all animations
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    if (_lastMapMode == OAMapModeFollow)
        _app.mapMode = OAMapModePositionTrack;

    // Animate azimuth change to north
    mapView.animator->animateAzimuthTo(0.0f,
                                       kQuickAnimationTime,
                                       OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                       kUserInteractionAnimationKey);
    mapView.animator->resume();
}

@synthesize zoomObservable = _zoomObservable;

@synthesize mapObservable = _mapObservable;

- (float)currentZoomInDelta
{
    if (![self isViewLoaded])
        return 0.0f;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    const auto currentZoomAnimation = mapView.animator->getCurrentAnimation(kUserInteractionAnimationKey,
                                                                            OsmAnd::MapAnimator::AnimatedValue::Zoom);
    if (currentZoomAnimation)
    {
        currentZoomAnimation->pause();

        bool ok = true;

        float deltaValue;
        ok = ok && currentZoomAnimation->obtainDeltaValueAsFloat(deltaValue);

        float initialValue;
        ok = ok && currentZoomAnimation->obtainInitialValueAsFloat(initialValue);

        float currentValue;
        ok = ok && currentZoomAnimation->obtainCurrentValueAsFloat(currentValue);

        currentZoomAnimation->resume();

        if (ok && deltaValue > 0.0f)
            return (initialValue + deltaValue) - currentValue;
    }

    return 0.0f;
}

- (BOOL)canZoomIn
{
    if (![self isViewLoaded])
        return NO;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    return (mapView.zoom < mapView.maxZoom);
}

- (void)animatedZoomIn
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];
    
    // Animate zoom-in by +1
    zoomDelta += 1.0f;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);

    mapView.animator->resume();

}

-(float)calculateMapRuler {
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    if(self.currentZoomOutDelta != 0 || self.currentZoomInDelta != 0){
        return 0;
    }
    return mapView.currentPixelsToMetersScaleFactor ;
}

- (float)currentZoomOutDelta
{
    if (![self isViewLoaded])
        return 0.0f;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    const auto currentZoomAnimation = mapView.animator->getCurrentAnimation(kUserInteractionAnimationKey,
                                                                            OsmAnd::MapAnimator::AnimatedValue::Zoom);
    if (currentZoomAnimation)
    {
        currentZoomAnimation->pause();

        bool ok = true;

        float deltaValue;
        ok = ok && currentZoomAnimation->obtainDeltaValueAsFloat(deltaValue);

        float initialValue;
        ok = ok && currentZoomAnimation->obtainInitialValueAsFloat(initialValue);

        float currentValue;
        ok = ok && currentZoomAnimation->obtainCurrentValueAsFloat(currentValue);

        currentZoomAnimation->resume();

        if (ok && deltaValue < 0.0f)
            return (initialValue + deltaValue) - currentValue;
    }
    
    return 0.0f;
}

- (BOOL)canZoomOut
{
    if (![self isViewLoaded])
        return NO;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    return (mapView.zoom > mapView.minZoom);
}

- (void)animatedZoomOut
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];

    // Animate zoom-in by -1
    zoomDelta -= 1.0f;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    mapView.animator->resume();
    
}

- (void)onAppModeChanged
{
    if (![self isViewLoaded])
        return;

    switch (_app.appMode)
    {
        case OAAppModeBrowseMap:
            // When switching from any app mode to browse-map mode,
            // just keep previous map-mode

            break;

        case OAAppModeDrive:
        case OAAppModeNavigation:
            // When switching to Drive and Navigation app-modes,
            // automatically change map-mode to Follow
            _app.mapMode = OAMapModeFollow;
            break;

        default:
            return;
    }

    _lastAppMode = _app.appMode;
}

- (void)onMapModeChanged
{
    if (![self isViewLoaded])
        return;
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            // Do nothing
            break;
            
        case OAMapModePositionTrack:
        {
            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation != nil)
            {
                // Fly to last-known position without changing anything but target
                
                mapView.animator->pause();
                mapView.animator->cancelAllAnimations();

                OsmAnd::PointI newTarget31(
                    OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                    OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

                // In case previous mode was Follow, restore last azimuth, elevation angle and zoom
                // used in PositionTrack mode
                if (_lastMapMode == OAMapModeFollow && _lastPositionTrackStateCaptured)
                {
                    mapView.animator->animateTargetTo(newTarget31,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                      kLocationServicesAnimationKey);
                    mapView.animator->animateAzimuthTo(_lastAzimuthInPositionTrack,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                       kLocationServicesAnimationKey);
                    mapView.animator->animateElevationAngleTo(kMapModePositionTrackingDefaultElevationAngle,
                                                              kOneSecondAnimatonTime,
                                                              OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                              kLocationServicesAnimationKey);
                    mapView.animator->animateZoomTo(kMapModePositionTrackingDefaultZoom,
                                                    kOneSecondAnimatonTime,
                                                    OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                    kLocationServicesAnimationKey);
                    _lastPositionTrackStateCaptured = false;
                }
                else
                {
                    mapView.animator->parabolicAnimateTargetTo(newTarget31,
                                                               kOneSecondAnimatonTime,
                                                               OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                               OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                               kLocationServicesAnimationKey);
                }

                mapView.animator->resume();
            }
            break;
        }
            
        case OAMapModeFollow:
        {
            // In case previous mode was PositionTrack, remember azimuth, elevation angle and zoom
            if (_lastMapMode == OAMapModePositionTrack)
            {
                _lastAzimuthInPositionTrack = mapView.azimuth;
                _lastPositionTrackStateCaptured = true;
            }

            mapView.animator->pause();
            mapView.animator->cancelAllAnimations();

            mapView.animator->animateZoomTo(kMapModeFollowDefaultZoom,
                                            kOneSecondAnimatonTime,
                                            OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                            kLocationServicesAnimationKey);

            mapView.animator->animateElevationAngleTo(kMapModeFollowDefaultElevationAngle,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                      kLocationServicesAnimationKey);

            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation != nil)
            {
                OsmAnd::PointI newTarget31(
                    OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                    OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
                mapView.animator->animateTargetTo(newTarget31,
                                                  kOneSecondAnimatonTime,
                                                  OsmAnd::MapAnimator::TimingFunction::Linear,
                                                  kLocationServicesAnimationKey);

                const auto direction = (_lastAppMode == OAAppModeBrowseMap)
                    ? _app.locationServices.lastKnownHeading
                    : newLocation.course;
                if (!isnan(direction) && direction >= 0)
                {
                    mapView.animator->animateAzimuthTo(direction,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::Linear,
                                                       kLocationServicesAnimationKey);
                }
            }

            mapView.animator->resume();
            break;
        }

        default:
            return;
    }

    _lastMapMode = _app.mapMode;
}

- (void)onDayNightModeChanged
{
    if (![self isViewLoaded])
        return;

    _mapSourceInvalidated = YES;
}

- (void)onLocationServicesStatusChanged
{
    if (_app.locationServices.status == OALocationServicesStatusInactive)
    {
        // If location services are stopped for any reason,
        // set map-mode to free, since location data no longer available
        _app.mapMode = OAMapModeFree;
    }
}

- (void)onLocationServicesUpdate
{
    if (![self isViewLoaded])
        return;
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;

    // In case there's no known location, do nothing and hide all markers
    if (newLocation == nil)
    {
        _myLocationMarker->setIsHidden(true);
        _myCourseMarker->setIsHidden(true);
        return;
    }

    const OsmAnd::PointI newTarget31(
                                     OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                     OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

    // Update "My" markers
    if (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0)
    {
        _myLocationMarker->setIsHidden(true);

        _myCourseMarker->setIsHidden(false);
        _myCourseMarker->setPosition(newTarget31);
        _myCourseMarker->setIsAccuracyCircleVisible(true);
        _myCourseMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
        _myCourseMarker->setOnMapSurfaceIconDirection(_myCourseMainIconKey,
                                                      OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
    }
    else
    {
        _myCourseMarker->setIsHidden(true);

        _myLocationMarker->setIsHidden(false);
        _myLocationMarker->setPosition(newTarget31);
        _myLocationMarker->setIsAccuracyCircleVisible(true);
        _myLocationMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
        _myLocationMarker->setOnMapSurfaceIconDirection(_myLocationHeadingIconKey,
                                                        OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
    }

    // If map mode is position-track or follow, move to that position
    if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
    {
        mapView.animator->pause();

        const auto azimuthAnimation = mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                            OsmAnd::MapAnimator::AnimatedValue::Azimuth);
        const auto targetAnimation = mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                           OsmAnd::MapAnimator::AnimatedValue::Target);

        mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                 OsmAnd::MapAnimator::AnimatedValue::Azimuth);
        mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                 OsmAnd::MapAnimator::AnimatedValue::Target);

        // For "follow-me" mode azimuth is also controlled
        if (_app.mapMode == OAMapModeFollow)
        {
            // Update azimuth if there's one
            const auto direction = (_lastAppMode == OAAppModeBrowseMap)
                ? newHeading
                : newLocation.course;
            if (!isnan(direction) && direction >= 0)
            {
                if (azimuthAnimation)
                {
                    mapView.animator->cancelAnimation(azimuthAnimation);

                    mapView.animator->animateAzimuthTo(direction,
                                                       azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(),
                                                       OsmAnd::MapAnimator::TimingFunction::Linear,
                                                       kLocationServicesAnimationKey);
                }
                else
                {
                    mapView.animator->animateAzimuthTo(direction,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::Linear,
                                                       kLocationServicesAnimationKey);
                }
            }
        }

        // And also update target
        if (targetAnimation)
        {
            mapView.animator->cancelAnimation(targetAnimation);

            mapView.animator->animateTargetTo(newTarget31,
                                              targetAnimation->getDuration() - targetAnimation->getTimePassed(),
                                              OsmAnd::MapAnimator::TimingFunction::Linear,
                                              kLocationServicesAnimationKey);
        }
        else
        {
            if (_app.mapMode == OAMapModeFollow)
            {
                mapView.animator->animateTargetTo(newTarget31,
                                                  kOneSecondAnimatonTime,
                                                  OsmAnd::MapAnimator::TimingFunction::Linear,
                                                  kLocationServicesAnimationKey);
            }
            else //if (_app.mapMode == OAMapModePositionTrack)
            {
                mapView.animator->parabolicAnimateTargetTo(newTarget31,
                                                           kOneSecondAnimatonTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                           kLocationServicesAnimationKey);
            }
        }

        mapView.animator->resume();
    }
}

- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}

-(void)onLanguageSettingsChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        [self updateCurrentMapSource];
    });
}

- (void)onLocalResourcesChanged:(const QList< QString >&)ids
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == kUIAlertViewMapDownloadTag) {
        if (buttonIndex == 1) {
            // Download map
            const auto repositoryMap = _app.resourcesManager->getResourceInRepository(kWorldBasemapKey);
            [OAResourcesBaseViewController startBackgroundDownloadOf:repositoryMap];
            
        } else if (buttonIndex == alertView.cancelButtonIndex) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMapDownloadStopReminding];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
}


- (void)updateCurrentMapSource
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    @synchronized(_rendererSync)
    {
        const auto screenTileSize = 256 * self.displayDensityFactor;
        const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
        OALog(@"Screen tile size %fpx, raster tile size %dpx", screenTileSize, rasterTileSize);

        // Set reference tile size on the screen
        mapView.referenceTileSizeOnScreenInPixels = screenTileSize;

        // Release previously-used resources (if any)
        _rasterMapProvider.reset();
        _obfMapObjectsProvider.reset();
        _mapPrimitivesProvider.reset();
        _mapPresentationEnvironment.reset();
        _mapPrimitiviser.reset();
        if (_mapObjectsSymbolsProvider)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProvider];
        _mapObjectsSymbolsProvider.reset();
        
        // Determine what type of map-source is being activated
        typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
        OAMapSource* lastMapSource = _app.data.lastMapSource;
        const auto resourceId = QString::fromNSString(lastMapSource.resourceId);
        const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
        if (!mapSourceResource)
        {
            // Missing resource, shift to default
            _app.data.lastMapSource = [OAAppData defaults].lastMapSource;
            return;
        }
        if (mapSourceResource->type == OsmAndResourceType::MapStyle)
        {
            const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
            const auto& resolvedMapStyle = _app.resourcesManager->mapStylesCollection->getResolvedStyleByName(unresolvedMapStyle->name);
            OALog(@"Using '%@' style from '%@' resource", unresolvedMapStyle->name.toNSString(), mapSourceResource->id.toNSString());

            _obfMapObjectsProvider.reset(new OsmAnd::ObfMapObjectsProvider(_app.resourcesManager->obfsCollection));

            NSLog(@"%@", [[NSLocale preferredLanguages] firstObject]);
            
            OsmAnd::MapPresentationEnvironment::LanguagePreference langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
            
            switch ([[OAAppSettings sharedManager] settingMapLanguage]) {
                case 0:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
                case 1:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeAndLocalized;
                    break;
                case 2:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedAndNative;
                    break;
                default:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
            }
            
            
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     QString::fromNSString([[NSLocale preferredLanguages] firstObject]),
                                                                                     langPreferences));
            
            
            _mapPrimitiviser.reset(new OsmAnd::MapPrimitiviser(_mapPresentationEnvironment));
            _mapPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_obfMapObjectsProvider,
                                                                           _mapPrimitiviser,
                                                                           rasterTileSize));

            // Configure with preset if such is set
            if (lastMapSource.variant != nil)
            {
                OALog(@"Using '%@' variant of style", lastMapSource.variant);
                const auto preset = _app.resourcesManager->mapStylesPresetsCollection->getPreset(unresolvedMapStyle->name, QString::fromNSString(lastMapSource.variant));
                if (preset) {
                    QHash< QString, QString > newSettings(preset->attributes);
                    if([[OAAppSettings sharedManager] settingAppMode] == APPEARANCE_MODE_NIGHT) {
                        newSettings[QString::fromLatin1("nightMode")] = "true";
                    }
                    
                    _mapPresentationEnvironment->setSettings(newSettings);
                }
            }
            
#if defined(OSMAND_IOS_DEV)
            switch (_visualMetricsMode)
            {
                case OAVisualMetricsModeBinaryMapData:
                    _rasterMapProvider.reset(new OsmAnd::ObfMapObjectsMetricsLayerProvider(_obfMapObjectsProvider,
                                                                                           256 * mapView.contentScaleFactor,
                                                                                           mapView.contentScaleFactor));
                    break;

                case OAVisualMetricsModeBinaryMapPrimitives:
                    _rasterMapProvider.reset(new OsmAnd::MapPrimitivesMetricsLayerProvider(_mapPrimitivesProvider,
                                                                                           256 * mapView.contentScaleFactor,
                                                                                           mapView.contentScaleFactor));
                    break;

                case OAVisualMetricsModeBinaryMapRasterize:
                {
                    std::shared_ptr<OsmAnd::MapRasterLayerProvider> backendProvider(
                        new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
                    _rasterMapProvider.reset(new OsmAnd::MapRasterMetricsLayerProvider(backendProvider,
                                                                                       256 * mapView.contentScaleFactor,
                                                                                       mapView.contentScaleFactor));
                    break;
                }

                case OAVisualMetricsModeOff:
                default:
                    _rasterMapProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
                    break;
            }
#else
          _rasterMapProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
#endif // defined(OSMAND_IOS_DEV)
            [mapView setProvider:_rasterMapProvider
                        forLayer:0];

#if defined(OSMAND_IOS_DEV)
            if (!_hideStaticSymbols)
            {
                _mapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                       rasterTileSize));
                [mapView addTiledSymbolsProvider:_mapObjectsSymbolsProvider];
            }
#else
            _mapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                   rasterTileSize));
            [mapView addTiledSymbolsProvider:_mapObjectsSymbolsProvider];
#endif
        }
        else if (mapSourceResource->type == OsmAndResourceType::OnlineTileSources)
        {
            const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(mapSourceResource->metadata)->sources;
            OALog(@"Using '%@' online source from '%@' resource", lastMapSource.variant, mapSourceResource->id.toNSString());

            const auto onlineMapTileProvider = onlineTileSources->createProviderFor(QString::fromNSString(lastMapSource.variant));
            if (!onlineMapTileProvider)
            {
                // Missing resource, shift to default
                _app.data.lastMapSource = [OAAppData defaults].lastMapSource;
                return;
            }
            onlineMapTileProvider->setLocalCachePath(_app.cacheDir);
            _rasterMapProvider = onlineMapTileProvider;
            [mapView setProvider:_rasterMapProvider
                        forLayer:0];
        }
    }
}

- (void)onLayersConfigurationChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayers];
    });
}

- (void)updateLayers
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    @synchronized(_rendererSync)
    {
        if ([_app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
            [mapView addKeyedSymbolsProvider:_favoritesPresenter];
        else
            [mapView removeKeyedSymbolsProvider:_favoritesPresenter];
    }
}

- (CGFloat)displayDensityFactor
{
#if defined(OSMAND_IOS_DEV)
    if (_forceDisplayDensityFactor)
        return _forcedDisplayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)

    if (![self isViewLoaded])
        return [UIScreen mainScreen].scale;
    return self.view.contentScaleFactor;
}

- (void)goToPosition:(Point31)position31
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    _app.mapMode = OAMapModeFree;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();

    if (animated)
    {
        mapView.animator->parabolicAnimateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                                   kQuickAnimationTime,
                                                   OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                   OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                                   kUserInteractionAnimationKey);
        mapView.animator->resume();
    }
    else
    {
        [mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
    }
}

- (void)goToPosition:(Point31)position31
             andZoom:(CGFloat)zoom
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    _app.mapMode = OAMapModeFree;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();

    if (animated)
    {
        mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                          kQuickAnimationTime,
                                          OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                          kUserInteractionAnimationKey);
        mapView.animator->animateZoomTo(zoom,
                                        kQuickAnimationTime,
                                        OsmAnd::MapAnimator::TimingFunction::EaseInOutQuadratic,
                                        kUserInteractionAnimationKey);
        mapView.animator->resume();
    }
    else
    {
        [mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
        [mapView setZoom:zoom];
    }
}

@synthesize framePreparedObservable = _framePreparedObservable;

#if defined(OSMAND_IOS_DEV)
@synthesize hideStaticSymbols = _hideStaticSymbols;
- (void)setHideStaticSymbols:(BOOL)hideStaticSymbols
{
    if (_hideStaticSymbols == hideStaticSymbols)
        return;

    _hideStaticSymbols = hideStaticSymbols;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}

@synthesize visualMetricsMode = _visualMetricsMode;
- (void)setVisualMetricsMode:(OAVisualMetricsMode)visualMetricsMode
{
    if (_visualMetricsMode == visualMetricsMode)
        return;

    _visualMetricsMode = visualMetricsMode;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}

@synthesize forceDisplayDensityFactor = _forceDisplayDensityFactor;
- (void)setForceDisplayDensityFactor:(BOOL)forceDisplayDensityFactor
{
    if (_forceDisplayDensityFactor == forceDisplayDensityFactor)
        return;

    _forceDisplayDensityFactor = forceDisplayDensityFactor;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}

@synthesize forcedDisplayDensityFactor = _forcedDisplayDensityFactor;
- (void)setForcedDisplayDensityFactor:(CGFloat)forcedDisplayDensityFactor
{
    _forcedDisplayDensityFactor = forcedDisplayDensityFactor;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        [self updateCurrentMapSource];
    });
}

#endif // defined(OSMAND_IOS_DEV)

@end
