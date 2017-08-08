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
#import <UIViewController+JASidePanel.h>

#import "OAAppData.h"
#import "OAMapRendererView.h"

#import "OAAutoObserverProxy.h"
#import "OANavigationController.h"
#import "OARootViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAMapStyleSettings.h"
#import "OAPOIHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXRouteDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAGpxWptItem.h"
#import "OAGPXRouter.h"
#import "OAGpxRoutePoint.h"
#import "OADestination.h"
#import "OAPluginPopupViewController.h"
#import "OAIAPHelper.h"
#import "OAMapCreatorHelper.h"
#import "OAPOI.h"
#import "OAPOILocationType.h"
#import "OAPOIMyLocationType.h"
#import "OAPOIUIFilter.h"
#import "OAQuickSearchHelper.h"
#import "OAMapLayers.h"
#import "OADestinationsHelper.h"

#import "OARoutingHelper.h"
#import "OAPointDescription.h"
#import "OARouteCalculationResult.h"
#import "OATargetPointsHelper.h"

#include "OASQLiteTileSourceMapLayerProvider.h"
#include "OAWebClient.h"
#include <OsmAndCore/IWebClient.h>

//#include "OAMapMarkersCollection.h"

#include <OpenGLES/ES2/gl.h>

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
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
#include <OsmAndCore/Map/BillboardVectorMapSymbol.h>
#include <OsmAndCore/Map/RasterMapSymbol.h>
#include <OsmAndCore/Map/OnPathRasterMapSymbol.h>
#include <OsmAndCore/Map/IOnSurfaceMapSymbol.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>

#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>

#include <OsmAndCore/QKeyValueIterator.h>

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
#define kTargetMoveVelocityLimit 3000.0f
#define kTargetMoveDeceleration 10000.0f
#define kRotateDeceleration 500.0f
#define kRotateVelocityAbsLimitInDegrees 400.0f
#define kMapModePositionTrackingDefaultZoom 16.0f
#define kMapModePositionTrackingDefaultElevationAngle 90.0f
#define kGoToMyLocationZoom 15.0f
#define kMapModeFollowDefaultZoom 18.0f
#define kMapModeFollowDefaultElevationAngle kElevationMinAngle
#define kQuickAnimationTime 0.1f
#define kOneSecondAnimatonTime 0.5f
#define kScreensToFlyWithAnimation 4.0
#define kUserInteractionAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(1)
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

#define kGpxLayerIndex 9
#define kGpxRecLayerIndex 12

#define _(name) OAMapRendererViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@implementation OAMapSymbol

-(BOOL)isPlace
{
    if (_isPlace)
    {
        return YES;
    }
    else if (_poiType && _poiType.tag)
    {
        return [_poiType.tag isEqualToString:@"place"];
    }
    return NO;
}

@end


@interface OAMapViewController () <OAMapRendererDelegate, OARouteCalculationProgressCallback, OARouteInformationListener>
@end

@implementation OAMapViewController
{
    // -------------------------------------------------------------------------------------------

    OAAutoObserverProxy* _gpxRouteDefinedObserver;
    OAAutoObserverProxy* _gpxRouteCanceledObserver;
    OAAutoObserverProxy* _gpxRouteChangedObserver;

    OAAutoObserverProxy* _updateGpxTracksObserver;
    OAAutoObserverProxy* _updateRecTrackObserver;
    OAAutoObserverProxy* _updateRouteTrackObserver;

    OAAutoObserverProxy* _trackRecordingObserver;
    
    NSString *_gpxDocFileTemp;
    NSString *_gpxDocFileRoute;
    NSArray *_gpxDocsPaths;

    // Active gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _gpxDocs;
    // Route gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _gpxDocsRoute;
    // Temp gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _gpxDocsTemp;
    // Currently recording gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _gpxDocsRec;

    // Navigation route gpx
    std::shared_ptr<const OsmAnd::GeoInfoDocument> _gpxNaviTrack;

    OAGPXRouter *_gpxRouter;
    
    BOOL _tempTrackShowing;
    BOOL _recTrackShowing;

    // -------------------------------------------------------------------------------------------
    
    OsmAndAppInstance _app;
    
    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    
    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;
    std::shared_ptr<OsmAnd::IWebClient> _webClient;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;

    OAMapLayers *_mapLayers;

    std::shared_ptr<OsmAnd::ObfDataInterface> _obfsDataInterface;

    OAAutoObserverProxy* _appModeObserver;
    OAAppMode _lastAppMode;

    OAAutoObserverProxy* _mapModeObserver;
    OAMapMode _lastMapMode;
    OAMapMode _lastMapModeBeforeDrive;
    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _mapSettingsChangeObserver;
    OAAutoObserverProxy* _mapLayerChangeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;

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

    UITapGestureRecognizer* _grSymbolContextMenu;
    UILongPressGestureRecognizer* _grPointContextMenu;

    bool _lastPositionTrackStateCaptured;
    float _lastAzimuthInPositionTrack;
    float _lastZoom;
    float _lastElevationAngle;
    
    BOOL _rotatingToNorth;
    BOOL _isIn3dMode;
    
    NSDate *_startChangingMapMode;
    
    CLLocationCoordinate2D _centerLocationForMapArrows;
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
    _gpxRouter = [OAGPXRouter sharedInstance];
    
    _webClient = std::make_shared<OAWebClient>();

    _rendererSync = [[NSObject alloc] init];

    _mapLayerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onMapLayerChanged)
                                                              andObserve:_app.data.mapLayerChangeObservable];

    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    _gpxRouteDefinedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onGpxRouteDefined)
                                                              andObserve:_gpxRouter.routeDefinedObservable];
    _gpxRouteCanceledObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onGpxRouteCanceled)
                                                              andObserve:_gpxRouter.routeCanceledObservable];
    _gpxRouteChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onGpxRouteChanged)
                                                           andObserve:_gpxRouter.routeChangedObservable];

    /*
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
    */
    
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

    _mapSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onMapSettingsChanged)
                                                       andObserve:_app.mapSettingsChangeObservable];
    
    _updateGpxTracksObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onUpdateGpxTracks)
                                                            andObserve:_app.updateGpxTracksOnMapObservable];

    _updateRecTrackObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onUpdateRecTrack)
                                                          andObserve:_app.updateRecTrackOnMapObservable];

    _updateRouteTrackObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onUpdateRouteTrack)
                                                         andObserve:_app.updateRouteTrackOnMapObservable];

    _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesStatusChanged)
                                                                 andObserve:_app.locationServices.statusObservable];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];

    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onTrackRecordingChanged)
                                                         andObserve:_app.trackRecordingObservable];

    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _azimuthObservable = [[OAObservable alloc] init];
    _zoomObservable = [[OAObservable alloc] init];
    _mapObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];
    _idleObservable = [[OAObservable alloc] init];
    
    _stateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                               withHandler:@selector(onMapRendererStateChanged:withKey:)];
    _settingsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onMapRendererSettingsChanged:withKey:)];
    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged:withKey:andValue:)
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
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
    _grMove.minimumNumberOfTouches = 1;
    _grMove.maximumNumberOfTouches = 1;
    
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

    // - Single-press context menu of a point gesture
    _grSymbolContextMenu = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(pointContextMenuGestureDetected:)];
    _grSymbolContextMenu.delegate = self;
    _grSymbolContextMenu.numberOfTapsRequired = 1;
    _grSymbolContextMenu.numberOfTouchesRequired = 1;

    // - Long-press context menu of a point gesture
    _grPointContextMenu = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(pointContextMenuGestureDetected:)];
    _grPointContextMenu.delegate = self;

    _lastPositionTrackStateCaptured = false;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack]) {
        OAMapMode mapMode = (OAMapMode)[[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
        if (mapMode == OAMapModeFollow) {
            _lastAzimuthInPositionTrack = 0.0f;
            _lastZoom = kMapModePositionTrackingDefaultZoom;
            _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
            _lastPositionTrackStateCaptured = true;
        }
    }

    // prevents single tap to fire together with double tap
    [_grSymbolContextMenu requireGestureRecognizerToFail:_grZoomIn];
    
    _mapLayers = [[OAMapLayers alloc] initWithMapViewController:self];
    
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

    [_mapLayers destroyLayers];
    
    // Unsubscribe from application notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Allow view to tear down OpenGLES context
    if ([self isViewLoaded])
        [_mapView releaseContext];
}

- (void)loadView
{
    OALog(@"Creating Map Renderer view...");

    // Inflate map renderer view
    _mapView = [[OAMapRendererView alloc] init];
    self.view = _mapView;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapView.contentScaleFactor = [[UIScreen mainScreen] scale];
    [_stateObserver observe:_mapView.stateObservable];
    [_settingsObserver observe:_mapView.settingsObservable];
    [_framePreparedObserver observe:_mapView.framePreparedObservable];
    _mapView.rendererDelegate = self;

    // Create map layers
    [_mapLayers createLayers];    
}

#pragma mark - OAMapRendererDelegate

- (void) frameRendered
{
    if (_mapLayers)
        [_mapLayers onMapFrameRendered];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    _mapView.userInteractionEnabled = YES;
    _mapView.multipleTouchEnabled = YES;
    _mapView.displayDensityFactor = self.displayDensityFactor;
    [_mapView createContext];
    
    // Attach gesture recognizers:
    [_mapView addGestureRecognizer:_grZoom];
    [_mapView addGestureRecognizer:_grMove];
    [_mapView addGestureRecognizer:_grRotate];
    [_mapView addGestureRecognizer:_grZoomIn];
    [_mapView addGestureRecognizer:_grZoomOut];
    [_mapView addGestureRecognizer:_grElevation];
    [_mapView addGestureRecognizer:_grSymbolContextMenu];
    [_mapView addGestureRecognizer:_grPointContextMenu];
    
    // Adjust map-view target, zoom, azimuth and elevation angle to match last viewed
    _mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                      _app.data.mapLastViewedState.target31.y);
    _mapView.zoom = _app.data.mapLastViewedState.zoom;
    _mapView.azimuth = _app.data.mapLastViewedState.azimuth;
    _mapView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;

    // Mark that map source is no longer valid
    _mapSourceInvalidated = YES;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Resume rendering
    [_mapView resumeRendering];
    
    // Update map source (if needed)
    if (_mapSourceInvalidated)
    {
        [self updateCurrentMapSource];

        _mapSourceInvalidated = NO;
    }
    
    
    // IOS-208
    if (_app.resourcesManager->isRepositoryAvailable())
    {
        int showMapIterator = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kShowMapIterator];
        [[NSUserDefaults standardUserDefaults] setInteger:++showMapIterator forKey:kShowMapIterator];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *key = [@"resource:" stringByAppendingString:_app.resourcesManager->getResourceInRepository(kWorldBasemapKey)->id.toNSString()];
        BOOL _isWorldMapDownloading = [_app.downloadsManager.keysOfDownloadTasks containsObject:key];

        BOOL mapDownloadStopReminding = [[NSUserDefaults standardUserDefaults] boolForKey:kMapDownloadStopReminding];
        double mapDownloadReminderDelta = [[NSDate date] timeIntervalSince1970] - [[NSUserDefaults standardUserDefaults] doubleForKey:kMapDownloadReminderStoppedDate];
        const auto worldMap = _app.resourcesManager->getLocalResource(kWorldBasemapKey);
        if (!_isWorldMapDownloading &&
            (!mapDownloadStopReminding || mapDownloadReminderDelta > 60.0 * 60.0 * 24.0 * 8.0) &&
            !worldMap && (showMapIterator == 1 || showMapIterator % 6 == 0))
            
            [OAPluginPopupViewController askForWorldMap];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self isViewLoaded])
        return;

    // Suspend rendering
    [_mapView suspendRendering];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastMapUsedTime];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (![self isViewLoaded])
        return;

    // Suspend rendering
    [_mapView suspendRendering];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    if (![self isViewLoaded])
        return;

    // Resume rendering
    [_mapView resumeRendering];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    NSDate *lastMapUsedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastMapUsedTime];
    if (lastMapUsedDate)
        if ([[NSDate date] timeIntervalSinceDate:lastMapUsedDate] > kInactiveHoursResetLocation * 60.0 * 60.0) {
            if (_app.mapMode == OAMapModeFree)
                _app.mapMode = OAMapModePositionTrack;
        }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastMapUsedTime];
}

- (void)setGeoInfoDocsGpxRoute:(OAGPXRouteDocument *)doc
{
    _gpxDocsRoute.clear();
    _gpxDocsRoute.append([doc getDocument]);
}

- (void)setDocFileRoute:(NSString *)fileName
{
    _gpxDocFileRoute = fileName;
}

- (void)setupMapArrowsLocation
{
    [self setupMapArrowsLocation:_centerLocationForMapArrows];
}

- (void)setupMapArrowsLocation:(CLLocationCoordinate2D)centerLocation
{
    OAAppSettings * settings = [OAAppSettings sharedManager];
    if (settings.settingMapArrows != MAP_ARROWS_MAP_CENTER)
    {
        settings.mapCenter = centerLocation;
        [settings setSettingMapArrows:MAP_ARROWS_MAP_CENTER];
        [_mapObservable notifyEventWithKey:nil];
    }
}

- (void)restoreMapArrowsLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupMapArrowsLocation) object:nil];
    
    [[OAAppSettings sharedManager] setSettingMapArrows:MAP_ARROWS_LOCATION];
    [_mapObservable notifyEventWithKey:nil];
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
        const auto verticalDistance = std::abs(touch1.y - touch2.y);

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
    if (gestureRecognizer == _grElevation &&
        (otherGestureRecognizer == _grMove || otherGestureRecognizer == _grRotate || otherGestureRecognizer == _grZoom))
        return NO;
    if (gestureRecognizer == _grMove && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grRotate && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grZoom && otherGestureRecognizer == _grElevation)
        return NO;
    
    if (gestureRecognizer == _grPointContextMenu && otherGestureRecognizer == _grSymbolContextMenu)
        return NO;
    if (gestureRecognizer == _grSymbolContextMenu && otherGestureRecognizer == _grPointContextMenu)
        return NO;
    if (gestureRecognizer == _grSymbolContextMenu && otherGestureRecognizer == _grZoomIn)
        return NO;
    if (gestureRecognizer == _grZoomIn && otherGestureRecognizer == _grSymbolContextMenu)
        return NO;
    
    return YES;
}

- (void)zoomGestureDetected:(UIPinchGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    // If gesture has just began, just capture current zoom
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self postMapGestureAction];

        // When user gesture has began, stop all animations
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

        _initialZoomLevelDuringGesture = _mapView.zoom;
        return;
    }
    
    // If gesture has been cancelled or failed, restore previous zoom
    if (recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _mapView.zoom = _initialZoomLevelDuringGesture;
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
    centerPoint.x *= _mapView.contentScaleFactor;
    centerPoint.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI centerLocationBefore;
    [_mapView convert:centerPoint toLocation:&centerLocationBefore];
    
    // Change zoom
    _mapView.zoom = _initialZoomLevelDuringGesture - (1.0f - recognizer.scale);

    // Adjust current target position to keep touch center the same
    OsmAnd::PointI centerLocationAfter;
    [_mapView convert:centerPoint toLocation:&centerLocationAfter];
    const auto centerLocationDelta = centerLocationAfter - centerLocationBefore;
    [_mapView setTarget31:_mapView.target31 - centerLocationDelta];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }

    // If this is the end of gesture, get velocity for animation
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        float velocity = qBound(-kZoomVelocityAbsLimit, (float)recognizer.velocity, kZoomVelocityAbsLimit);
        _mapView.animator->animateZoomWith(velocity,
                                          kZoomDeceleration,
                                          kUserInteractionAnimationKey);
        _mapView.animator->resume();
    }
}

- (void)moveGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    self.sidePanelController.recognizesPanGesture = NO;

    if (recognizer.state == UIGestureRecognizerStateBegan && recognizer.numberOfTouches > 0)
    {
        [self postMapGestureAction];

        // Get location of the gesture
        CGPoint touchPoint = [recognizer locationOfTouch:0 inView:self.view];
        touchPoint.x *= _mapView.contentScaleFactor;
        touchPoint.y *= _mapView.contentScaleFactor;
        OsmAnd::PointI touchLocation;
        [_mapView convert:touchPoint toLocation:&touchLocation];
        
        double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
        double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
        _centerLocationForMapArrows = CLLocationCoordinate2DMake(lat, lon);
        [self performSelector:@selector(setupMapArrowsLocation) withObject:nil afterDelay:1.0];

        // When user gesture has began, stop all animations
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);
    }
    
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation = [recognizer translationInView:self.view];
    translation.x *= _mapView.contentScaleFactor;
    translation.y *= _mapView.contentScaleFactor;

    // Take into account current azimuth and reproject to map space (points)
    const float angle = qDegreesToRadians(_mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;

    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    const uint32_t tileSize31 = (1u << (31 - _mapView.zoomLevel));
    const double scale31 = static_cast<double>(tileSize31) / _mapView.currentTileSizeOnScreenInPixels;

    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = _mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    _mapView.target31 = target31;
    
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        // Obtain velocity from recognizer
        CGPoint screenVelocity = [recognizer velocityInView:self.view];

        if (screenVelocity.x > 0)
            screenVelocity.x = MIN(screenVelocity.x, kTargetMoveVelocityLimit);
        else
            screenVelocity.x = MAX(screenVelocity.x, -kTargetMoveVelocityLimit);
        
        if (screenVelocity.y > 0)
            screenVelocity.y = MIN(screenVelocity.y, kTargetMoveVelocityLimit);
        else
            screenVelocity.y = MAX(screenVelocity.y, -kTargetMoveVelocityLimit);
        
        screenVelocity.x *= _mapView.contentScaleFactor;
        screenVelocity.y *= _mapView.contentScaleFactor;

        // Take into account current azimuth and reproject to map space (points)
        CGPoint velocityInMapSpace;
        velocityInMapSpace.x = screenVelocity.x * cosAngle - screenVelocity.y * sinAngle;
        velocityInMapSpace.y = screenVelocity.x * sinAngle + screenVelocity.y * cosAngle;
        
        // Rescale speed to 31 coordinates
        OsmAnd::PointD velocity;
        velocity.x = -velocityInMapSpace.x * scale31;
        velocity.y = -velocityInMapSpace.y * scale31;
        
        _mapView.animator->animateTargetWith(velocity,
                                            OsmAnd::PointD(kTargetMoveDeceleration * scale31, kTargetMoveDeceleration * scale31),
                                            kUserInteractionAnimationKey);
        _mapView.animator->resume();
    }
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)rotateGestureDetected:(UIRotationGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    // Zeroify accumulated rotation on gesture begin
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self postMapGestureAction];

        // When user gesture has began, stop all animations
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

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
    centerPoint.x *= _mapView.contentScaleFactor;
    centerPoint.y *= _mapView.contentScaleFactor;
    
    // Convert point from screen to location
    OsmAnd::PointI centerLocation;
    [_mapView convert:centerPoint toLocation:&centerLocation];
    
    // Rotate current target around center location
    OsmAnd::PointI target = _mapView.target31;
    target -= centerLocation;
    OsmAnd::PointI newTarget;
    const float cosAngle = cosf(-recognizer.rotation);
    const float sinAngle = sinf(-recognizer.rotation);
    newTarget.x = target.x * cosAngle - target.y * sinAngle;
    newTarget.y = target.x * sinAngle + target.y * cosAngle;
    newTarget += centerLocation;
    _mapView.target31 = newTarget;
    
    // Set rotation
    _mapView.azimuth -= qRadiansToDegrees(recognizer.rotation);

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        //float velocity = qBound(-kRotateVelocityAbsLimitInDegrees, -qRadiansToDegrees((float)recognizer.velocity), kRotateVelocityAbsLimitInDegrees);
        //_mapView.animator->animateAzimuthWith(velocity,
        //                                     kRotateDeceleration,
        //                                     kUserInteractionAnimationKey);
        
        _mapView.animator->resume();
    }
    [recognizer setRotation:0];
}

- (void)zoomInGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self postMapGestureAction];
    }
    
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];

    // When user gesture has began, stop all animations
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    _app.mapMode = OAMapModeFree;

    // Put tap location to center of screen
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    centerPoint.x *= _mapView.contentScaleFactor;
    centerPoint.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [_mapView convert:centerPoint toLocation:&centerLocation];

    OsmAnd::PointI destLocation(_mapView.target31.x / 2.0 + centerLocation.x / 2.0, _mapView.target31.y / 2.0 + centerLocation.y / 2.0);
    
    _mapView.animator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomIn,
                                      kUserInteractionAnimationKey);
    
    // Increate zoom by 1
    zoomDelta += 1.0f;
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    _mapView.animator->resume();
}

- (void)zoomOutGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self postMapGestureAction];
    }

    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];

    // When user gesture has began, stop all animations
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
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
    centerPoint.x *= _mapView.contentScaleFactor;
    centerPoint.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [_mapView convert:centerPoint toLocation:&centerLocation];
    
    OsmAnd::PointI destLocation(centerLocation.x - 2 * (centerLocation.x - _mapView.target31.x), centerLocation.y - 2 * (centerLocation.y - _mapView.target31.y));
    
    _mapView.animator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomOut,
                                      kUserInteractionAnimationKey);
    
    // Decrease zoom by 1
    zoomDelta -= 1.0f;
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    _mapView.animator->resume();
}

- (void)elevationGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self postMapGestureAction];

        // When user gesture has began, stop all animations
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);
    }
    
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat angleDelta = translation.y / static_cast<CGFloat>(kElevationGesturePointsPerDegree);
    CGFloat angle = _mapView.elevationAngle;
    angle -= angleDelta;
    if (angle < kElevationMinAngle)
        angle = kElevationMinAngle;
    _mapView.elevationAngle = angle;
    [recognizer setTranslation:CGPointZero inView:self.view];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }
}

-(BOOL)simulateContextMenuPress:(UIGestureRecognizer*)recognizer
{
    return [self pointContextMenuGestureDetected:recognizer];
}

- (void)processSymbolFields:(OAMapSymbol *)symbol decodedValues:(const QList<OsmAnd::Amenity::DecodedValue>)decodedValues
{
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    
    for (const auto& entry : decodedValues)
    {
        if (entry.declaration->tagName.startsWith(QString("content")))
        {
            NSString *key = entry.declaration->tagName.toNSString();
            NSString *loc;
            if (key.length > 8)
                loc = [[key substringFromIndex:8] lowercaseString];
            else
                loc = @"";
            
            [content setObject:entry.value.toNSString() forKey:loc];
        }
        else
        {
            [values setObject:entry.value.toNSString() forKey:entry.declaration->tagName.toNSString()];
        }
    }
    
    symbol.values = values;
    symbol.localizedContent = content;
}

- (void)processAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity symbol:(OAMapSymbol *)symbol
{
    const auto& decodedCategories = amenity->getDecodedCategories();
    if (!decodedCategories.isEmpty())
    {
        const auto& entry = decodedCategories.first();
        if (!symbol.poiType)
            symbol.poiType = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:entry.category.toNSString() name:entry.subcategory.toNSString()];
    }

    symbol.obfId = amenity->id;
    symbol.caption = amenity->nativeName.toNSString();
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSString *nameLocalized = [OAPOIHelper processLocalizedNames:amenity->localizedNames nativeName:amenity->nativeName names:names];
    if (nameLocalized.length > 0)
        symbol.caption = nameLocalized;
    symbol.localizedNames = names;
    
    const auto decodedValues = amenity->getDecodedValues();
    [self processSymbolFields:symbol decodedValues:decodedValues];
    
    if (symbol.poiType)
    {
        if ([symbol.poiType.name isEqualToString:@"wiki_place"])
            symbol.type = OAMapSymbolWiki;
        else
            symbol.type = OAMapSymbolPOI;
    }
}

- (BOOL)pointContextMenuGestureDetected:(UIGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return NO;

    // Get location of the gesture
    CGPoint touchPoint = [recognizer locationOfTouch:0 inView:self.view];
    touchPoint.x *= _mapView.contentScaleFactor;
    touchPoint.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [_mapView convert:touchPoint toLocation:&touchLocation];
    
    // Format location
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self setupMapArrowsLocation:CLLocationCoordinate2DMake(lat, lon)];
    }

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }
    
    // Capture only last state
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return NO;
    
    double lonTap = lon;
    double latTap = lat;
    
    NSMutableArray<OAMapSymbol *> *foundSymbols = [NSMutableArray array];
    
    CLLocation* myLocation = _app.locationServices.lastKnownLocation;
    if (myLocation)
    {
        CGPoint myLocationScreen;
        OsmAnd::PointI myLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(myLocation.coordinate.latitude, myLocation.coordinate.longitude));
        [_mapView convert:&myLocationI toScreen:&myLocationScreen];
        myLocationScreen.x *= _mapView.contentScaleFactor;
        myLocationScreen.y *= _mapView.contentScaleFactor;
        
        if (fabs(myLocationScreen.x - touchPoint.x) < 20.0 && fabs(myLocationScreen.y - touchPoint.y) < 20.0)
        {
            OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
            symbol.caption = OALocalizedString(@"my_location");
            symbol.type = OAMapSymbolMyLocation;
            symbol.touchPoint = touchPoint;
            symbol.location = myLocation.coordinate;
            symbol.sortIndex = (NSInteger)symbol.type;
            symbol.poiType = [[OAPOIMyLocationType alloc] init];
            [foundSymbols addObject:symbol];
        }
    }
    
    CGFloat delta = 10.0;

    _obfsDataInterface = _app.resourcesManager->obfsCollection->obtainDataInterface();

    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));

    BOOL doSkip = NO;

    const auto& symbolInfos = [_mapView getSymbolsIn:area strict:NO];
    for (const auto symbolInfo : symbolInfos)
    {
        doSkip = NO;
                
        OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
        symbol.type = OAMapSymbolLocation;
        symbol.touchPoint = touchPoint;
        symbol.location = CLLocationCoordinate2DMake(lat, lon);
        
        if (const auto billboardMapSymbol = std::dynamic_pointer_cast<const OsmAnd::IBillboardMapSymbol>(symbolInfo.mapSymbol))
        {
            lon = OsmAnd::Utilities::get31LongitudeX(billboardMapSymbol->getPosition31().x);
            lat = OsmAnd::Utilities::get31LatitudeY(billboardMapSymbol->getPosition31().y);
            
            if (const auto billboardAdditionalParams = std::dynamic_pointer_cast<const OsmAnd::MapSymbolsGroup::AdditionalBillboardSymbolInstanceParameters>(symbolInfo.instanceParameters)) {
                if (billboardAdditionalParams->overridesPosition31) {
                    lon = OsmAnd::Utilities::get31LongitudeX(billboardAdditionalParams->position31.x);
                    lat = OsmAnd::Utilities::get31LatitudeY(billboardAdditionalParams->position31.y);
                }
            }
        }
        
        if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
        {
            if (markerGroup->getMapMarker() == [_mapLayers.contextMenuLayer getContextPinMarker].get())
            {
                symbol.type = OAMapSymbolContext;
            }
            else
            {
                for (const auto& fav : [_mapLayers.favoritesLayer getFavoritesMarkersCollection]->getMarkers())
                {
                    if (markerGroup->getMapMarker() == fav.get() && ![self containSymbolId:fav->markerId obfId:0 wpt:nil symbolGroupId:nil symbols:foundSymbols])
                    {
                        symbol.symbolId = fav->markerId;
                        symbol.type = OAMapSymbolFavorite;
                        lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition().x);
                        lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition().y);
                        break;
                    }
                }
                for (const auto& dest : [_mapLayers.destinationsLayer getDestinationsMarkersCollection]->getMarkers())
                {
                    if (markerGroup->getMapMarker() == dest.get() && ![self containSymbolId:dest->markerId obfId:0 wpt:nil symbolGroupId:nil symbols:foundSymbols])
                    {
                        symbol.symbolId = dest->markerId;
                        symbol.type = OAMapSymbolDestination;
                        lon = OsmAnd::Utilities::get31LongitudeX(dest->getPosition().x);
                        lat = OsmAnd::Utilities::get31LatitudeY(dest->getPosition().y);
                        break;
                    }
                }
            }
        }
        
        if (symbol.type != OAMapSymbolContext)
        {
            OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup* objSymbolGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
            
            OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup* amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
            
            OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];

            if (amenitySymbolGroup != nullptr)
            {
                const auto amenity = amenitySymbolGroup->amenity;
                if (![self containSymbolId:0 obfId:amenity->id wpt:nil symbolGroupId:nil symbols:foundSymbols])
                {
                    [self processAmenity:amenity symbol:symbol];
                    
                    if (!symbol.poiType && [self findWpt:CLLocationCoordinate2DMake(lat, lon)] && ![self containSymbolId:0 obfId:0 wpt:self.foundWpt symbolGroupId:nil symbols:foundSymbols])
                    {
                        symbol.type = OAMapSymbolWpt;
                        symbol.foundWpt = self.foundWpt;
                        symbol.foundWptGroups = self.foundWptGroups;
                        symbol.foundWptDocPath = self.foundWptDocPath;
                    }
                }
            }
            else if (objSymbolGroup != nullptr && objSymbolGroup->mapObject != nullptr)
            {
                const std::shared_ptr<const OsmAnd::MapObject> mapObject = objSymbolGroup->mapObject;
                BOOL amenityFound = NO;
                BOOL amenityExists = NO;
                if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(objSymbolGroup->mapObject))
                {
                    std::shared_ptr<const OsmAnd::Amenity> amenity;
                    amenityFound = _obfsDataInterface->findAmenityForObfMapObject(obfMapObject, &amenity);
                    amenityExists = amenityFound && [self containSymbolId:0 obfId:amenity->id wpt:nil symbolGroupId:nil symbols:foundSymbols];
                    if (amenityFound && !amenityExists)
                    {
                        [self processAmenity:amenity symbol:symbol];
                    }
                }
                
                for (const auto& ruleId : mapObject->attributeIds)
                {
                    const auto& rule = *mapObject->attributeMapping->decodeMap.getRef(ruleId);
                    if (rule.tag == QString("addr:housenumber"))
                    {
                        symbol.buildingNumber = mapObject->captions.value(ruleId).toNSString();
                        continue;
                    }
                    
                    if (rule.tag == QString("place"))
                        symbol.isPlace = YES;
                    
                    if (rule.tag == QString("highway") && rule.value != QString("bus_stop"))
                        doSkip = YES;
                    
                    if (rule.tag == QString("contour"))
                        doSkip = YES;
                    
                    if (!symbol.poiType)
                        symbol.poiType = [poiHelper getPoiType:rule.tag.toNSString() value:rule.value.toNSString()];
                }
                
                if (symbol.poiType)
                {
                    if ([symbol.poiType.name isEqualToString:@"wiki_place"])
                        symbol.type = OAMapSymbolWiki;
                    else
                        symbol.type = OAMapSymbolPOI;
                }
                else if ([self findWpt:CLLocationCoordinate2DMake(lat, lon)] && ![self containSymbolId:0 obfId:0 wpt:self.foundWpt symbolGroupId:nil symbols:foundSymbols])
                {
                    symbol.type = OAMapSymbolWpt;
                    symbol.foundWpt = self.foundWpt;
                    symbol.foundWptGroups = self.foundWptGroups;
                    symbol.foundWptDocPath = self.foundWptDocPath;
                }
                else
                {
                    symbol.poiType = [[OAPOILocationType alloc] init];
                }
                
                OsmAnd::MapSymbolsGroup* symbolGroup = dynamic_cast<OsmAnd::MapSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
                if (symbolGroup != nullptr)
                {
                    symbol.symbolGroupId = symbolGroup->toString().toNSString();
                    std::shared_ptr<OsmAnd::MapSymbol> mapIconSymbol = symbolGroup->getFirstSymbolWithContentClass(OsmAnd::MapSymbol::ContentClass::Icon);
                    if (mapIconSymbol != nullptr)
                        if (const auto rasterMapSymbol = std::dynamic_pointer_cast<const OsmAnd::RasterMapSymbol>(mapIconSymbol))
                        {
                            std::shared_ptr<const SkBitmap> outIcon;
                            _mapPresentationEnvironment->obtainMapIcon(rasterMapSymbol->content, outIcon);
                            if (outIcon != nullptr)
                                symbol.icon = [OANativeUtilities skBitmapToUIImage:*outIcon];
                        }

                    if (symbolGroup->symbols.count() > 0)
                    {
                        for (const auto& sym : symbolGroup->symbols)
                            if (sym->contentClass == OsmAnd::MapSymbol::ContentClass::Caption)
                                if (const auto rasterMapSymbol = std::dynamic_pointer_cast<const OsmAnd::RasterMapSymbol>(sym))
                                {
                                    NSString *s = rasterMapSymbol->content.toNSString();
                                    if (symbol.caption && ![s hasPrefix:symbol.caption])
                                        symbol.captionExt = s;
                                    if (!symbol.caption && (!symbol.buildingNumber || ![s isEqualToString:symbol.buildingNumber]))
                                        symbol.caption = s;
                                }
                    }
                }
            }
        }

        symbol.location = CLLocationCoordinate2DMake(lat, lon);
        
        if (symbol.type == OAMapSymbolLocation)
            symbol.sortIndex = (((symbol.caption && symbol.caption.length > 0) || symbol.poiType) && symbol.icon) ?  10 : 20;
        else
            symbol.sortIndex = (NSInteger)symbol.type;
        
        if ([self containSymbolId:symbol.symbolId obfId:symbol.obfId wpt:symbol.foundWpt symbolGroupId:symbol.symbolGroupId symbols:foundSymbols])
            doSkip = YES;
        
        if (!doSkip)
            [foundSymbols addObject:symbol];
        
    }
    
    _obfsDataInterface.reset();

    BOOL gpxModeActive = [[OARootViewController instance].mapPanel gpxModeActive];
    
    [foundSymbols sortUsingComparator:^NSComparisonResult(OAMapSymbol *obj1, OAMapSymbol *obj2) {
        
        double dist1 = OsmAnd::Utilities::distance(lonTap, latTap, obj1.location.longitude, obj1.location.latitude);
        double dist2 = OsmAnd::Utilities::distance(lonTap, latTap, obj2.location.longitude, obj2.location.latitude);
        
        NSInteger index1 = obj1.sortIndex;
        if (gpxModeActive && obj1.type == OAMapSymbolWpt)
            index1 = 0;
        
        NSInteger index2 = obj2.sortIndex;
        if (gpxModeActive && obj2.type == OAMapSymbolWpt)
            index2 = 0;
        
        if (index1 >= OAMapSymbolPOI)
            index1 = OAMapSymbolPOI;
        if (index2 >= OAMapSymbolPOI)
            index2 = OAMapSymbolPOI;
        
        if (index1 == index2) {
            if (dist1 == dist2)
                return NSOrderedSame;
            else
                return dist1 < dist2 ? NSOrderedAscending : NSOrderedDescending;
        }
        else
        {
            return index1 < index2 ? NSOrderedAscending : NSOrderedDescending;
        }
    }];
    
    for (OAMapSymbol *s in foundSymbols)
    {
        if (s.type == OAMapSymbolContext)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContextMarkerClicked
                                                                object:self
                                                              userInfo:nil];
            return YES;
        }
    }

    if (foundSymbols.count == 1)
    {
        OAMapSymbol *s = foundSymbols[0];
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
            s.location = CLLocationCoordinate2DMake(latTap, lonTap);
        
        if (s.type == OAMapSymbolWpt)
        {
            self.foundWpt = s.foundWpt;
            self.foundWptGroups = s.foundWptGroups;
            self.foundWptDocPath = s.foundWptDocPath;
        }
        
        [OAMapViewController postTargetNotification:s];
        return YES;
    }
    else if (foundSymbols.count > 1)
    {
        [self.class postTargetNotification:foundSymbols latitude:latTap longitude:lonTap];
        return YES;
    }
    
    // if single press and no symbol found - exit
    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNoSymbolFound
                                                            object:self
                                                          userInfo:nil];
        return NO;
    }
    else
    {
        OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
        symbol.type = OAMapSymbolLocation;
        symbol.touchPoint = touchPoint;
        symbol.location = CLLocationCoordinate2DMake(lat, lon);
        symbol.poiType = [[OAPOILocationType alloc] init];
        [OAMapViewController postTargetNotification:symbol];
        return YES;
    }
}

- (BOOL)containSymbolId:(int)symbolId obfId:(unsigned long long)obfId wpt:(OAGpxWpt *)wpt symbolGroupId:(NSString *)symbolGroupId symbols:(NSArray<OAMapSymbol *> *)symbols
{
    for (OAMapSymbol *s in symbols)
    {
        if ((s.obfId > 0 && s.obfId == obfId) || (s.symbolId > 0 && s.symbolId == symbolId) || (s.foundWpt && s.foundWpt == wpt) || (s.symbolGroupId && [s.symbolGroupId isEqualToString:symbolGroupId]))
        {
            return YES;
        }
    }
    return NO;
}

+ (void)postTargetNotification:(NSArray<OAMapSymbol *> *)symbolArray latitude:(double)latitude longitude:(double)longitude
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:symbolArray forKey:@"symbols"];
    [userInfo setObject:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [userInfo setObject:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object:self
                                                      userInfo:userInfo];
}

+ (void)postTargetNotification:(OAMapSymbol *)symbol
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@[symbol] forKey:@"symbols"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object:self
                                                      userInfo:userInfo];
}

+ (OAMapSymbol *)getMapSymbol:(OAPOI *)poi
{
    OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
    symbol.obfId = poi.obfId;
    symbol.caption = poi.nameLocalized.length > 0 ? poi.nameLocalized : poi.name;
    symbol.poiType = poi.type;
    if ([symbol.poiType.name isEqualToString:@"wiki_place"])
        symbol.type = OAMapSymbolWiki;
    else
        symbol.type = OAMapSymbolPOI;
    symbol.location = CLLocationCoordinate2DMake(poi.latitude, poi.longitude);
    symbol.icon = [poi icon];
    symbol.values = poi.values;
    symbol.localizedNames = poi.localizedNames;
    symbol.localizedContent = poi.localizedContent;
    
    return symbol;
}

-(UIImage *)findIconAtPoint:(OsmAnd::PointI)touchPoint
{
    CGFloat delta = 8.0;
    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));
    const auto& symbolInfos = [_mapView getSymbolsIn:area strict:NO];

    for (const auto symbolInfo : symbolInfos) {
        
        if (const auto rasterMapSymbol = std::dynamic_pointer_cast<const OsmAnd::RasterMapSymbol>(symbolInfo.mapSymbol))
        {
            std::shared_ptr<const SkBitmap> outIcon;
            _mapPresentationEnvironment->obtainMapIcon(rasterMapSymbol->content, outIcon);
            if (outIcon != nullptr)
                return [OANativeUtilities skBitmapToUIImage:*outIcon];
        }
    }
    return nil;
}

- (id<OAMapRendererViewProtocol>)mapRendererView
{
    if (![self isViewLoaded])
        return nil;
    return (OAMapRendererView*)self.view;
}

- (void)postMapGestureAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationMapGestureAction
                                                        object:self
                                                      userInfo:nil];
}

@synthesize stateObservable = _stateObservable;
@synthesize settingsObservable = _settingsObservable;

@synthesize azimuthObservable = _azimuthObservable;


- (void)onMapRendererStateChanged:(id)observer withKey:(id)key
{
    if (![self isViewLoaded])
        return;

    switch ([key unsignedIntegerValue])
    {
        case OAMapRendererViewStateEntryAzimuth:
            [_azimuthObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:_mapView.azimuth]];
            _app.data.mapLastViewedState.azimuth = _mapView.azimuth;
            break;
        case OAMapRendererViewStateEntryZoom:
            [_zoomObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:_mapView.zoom]];
            _app.data.mapLastViewedState.zoom = _mapView.zoom;
            break;
        case OAMapRendererViewStateEntryElevationAngle:
            _app.data.mapLastViewedState.elevationAngle = _mapView.elevationAngle;
            break;
        case OAMapRendererViewStateEntryTarget:
            OsmAnd::PointI newTarget31 = _mapView.target31;
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

    // When user gesture has began, stop all animations
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();

    if (_lastMapMode == OAMapModeFollow) {
        _rotatingToNorth = YES;
        _app.mapMode = OAMapModePositionTrack;
    }
    
    // Animate azimuth change to north
    _mapView.animator->animateAzimuthTo(0.0f,
                                       kQuickAnimationTime * 2.0,
                                       OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                       kUserInteractionAnimationKey);
    _mapView.animator->resume();
    
}

@synthesize zoomObservable = _zoomObservable;

@synthesize mapObservable = _mapObservable;

- (float)currentZoomInDelta
{
    if (![self isViewLoaded])
        return 0.0f;

    const auto currentZoomAnimation = _mapView.animator->getCurrentAnimation(kUserInteractionAnimationKey,
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
    
    return (_mapView.zoom < _mapView.maxZoom);
}

- (void)animatedZoomIn
{
    if (![self isViewLoaded])
        return;

    if (_mapView.zoomLevel >= OsmAnd::ZoomLevel22)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];
    
    while ([_mapView getSymbolsUpdateSuspended] < 0)
        [_mapView suspendSymbolsUpdate];

    // Animate zoom-in by +1
    zoomDelta += 1.0f;
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    if (_lastAppMode == OAAppModeDrive)
    {
        CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
        centerPoint.x *= _mapView.contentScaleFactor;
        centerPoint.y *= _mapView.contentScaleFactor;
        
        // Convert point from screen to location
        OsmAnd::PointI bottomLocation;
        [_mapView convert:centerPoint toLocation:&bottomLocation];
        
        OsmAnd::PointI destLocation(_mapView.target31.x / 2.0 + bottomLocation.x / 2.0, _mapView.target31.y / 2.0 + bottomLocation.y / 2.0);

        _mapView.animator->animateTargetTo(destLocation,
                                          kQuickAnimationTime,
                                          OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomIn,
                                          kUserInteractionAnimationKey);
    }
    
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);

    _mapView.animator->resume();

}


-(float)calculateMapRuler
{
    if (![self isViewLoaded])
        return 0.0f;

    if (self.currentZoomOutDelta != 0 || self.currentZoomInDelta != 0)
        return 0;

    return _mapView.currentPixelsToMetersScaleFactor ;
}

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated
{
    [_mapLayers.contextMenuLayer showContextPinMarker:latitude longitude:longitude animated:animated];
}

- (void) hideContextPinMarker
{
    [_mapLayers.contextMenuLayer hideContextPinMarker];
}

- (float)currentZoomOutDelta
{
    if (![self isViewLoaded])
        return 0.0f;

    const auto currentZoomAnimation = _mapView.animator->getCurrentAnimation(kUserInteractionAnimationKey,
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
    
    return (_mapView.zoom > _mapView.minZoom);
}

- (void)animatedZoomOut
{
    if (![self isViewLoaded])
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];

    while ([_mapView getSymbolsUpdateSuspended] < 0)
        [_mapView suspendSymbolsUpdate];

    // Animate zoom-in by -1
    zoomDelta -= 1.0f;
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    if (_lastAppMode == OAAppModeDrive)
    {
        CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
        centerPoint.x *= _mapView.contentScaleFactor;
        centerPoint.y *= _mapView.contentScaleFactor;
        
        // Convert point from screen to location
        OsmAnd::PointI bottomLocation;
        [_mapView convert:centerPoint toLocation:&bottomLocation];
        
        OsmAnd::PointI destLocation(bottomLocation.x - 2 * (bottomLocation.x - _mapView.target31.x), bottomLocation.y - 2 * (bottomLocation.y - _mapView.target31.y));
        
        _mapView.animator->animateTargetTo(destLocation,
                                          kQuickAnimationTime,
                                          OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomOut,
                                          kUserInteractionAnimationKey);
    }
    
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    _mapView.animator->resume();
    
}

- (void)onAppModeChanged
{
    if (![self isViewLoaded])
        return;

    switch (_app.appMode)
    {
        case OAAppModeBrowseMap:
            
            if (_lastAppMode == OAAppModeDrive) {
                _lastMapMode = OAMapModeFollow;
                _app.mapMode = _lastMapModeBeforeDrive;
            }
            
            break;

        case OAAppModeDrive:
        case OAAppModeNavigation:
            // When switching to Drive and Navigation app-modes,
            // automatically change map-mode to Follow
            _lastMapModeBeforeDrive = _app.mapMode;
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
    
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            // Do nothing
            break;
            
        case OAMapModePositionTrack:
        {
            if (_lastMapMode == OAMapModeFollow && !_rotatingToNorth)
                _isIn3dMode = NO;
            
            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation != nil && !_rotatingToNorth)
            {
                // Fly to last-known position without changing anything but target
                
                _mapView.animator->pause();
                _mapView.animator->cancelAllAnimations();

                OsmAnd::PointI newTarget31(
                    OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                    OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

                // In case previous mode was Follow, restore last azimuth, elevation angle and zoom
                // used in PositionTrack mode
                if (_lastMapMode == OAMapModeFollow && _lastPositionTrackStateCaptured)
                {
                    _startChangingMapMode = [NSDate date];

                    _mapView.animator->animateTargetTo(newTarget31,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                      kLocationServicesAnimationKey);
                    _mapView.animator->animateAzimuthTo(_lastAzimuthInPositionTrack,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                       kLocationServicesAnimationKey);
                    _mapView.animator->animateElevationAngleTo(_lastElevationAngle,
                                                              kOneSecondAnimatonTime,
                                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                              kLocationServicesAnimationKey);
                    _mapView.animator->animateZoomTo(_lastZoom,
                                                    kOneSecondAnimatonTime,
                                                    OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                    kLocationServicesAnimationKey);
                    _lastPositionTrackStateCaptured = false;
                }
                else
                {
                    if ([self screensToFly:[OANativeUtilities convertFromPointI:newTarget31]] <= kScreensToFlyWithAnimation)
                    {
                        _startChangingMapMode = [NSDate date];
                        _mapView.animator->animateTargetTo(newTarget31,
                                                          kQuickAnimationTime,
                                                          OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                          kUserInteractionAnimationKey);
                        if (_mapView.zoom < kGoToMyLocationZoom)
                            _mapView.animator->animateZoomTo(kGoToMyLocationZoom,
                                                          kQuickAnimationTime,
                                                          OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                          kUserInteractionAnimationKey);
                    }
                    else
                    {
                        [_mapView setTarget31:newTarget31];
                        if (_mapView.zoom < kGoToMyLocationZoom)
                            [_mapView setZoom:kGoToMyLocationZoom];
                    }
                }

                _mapView.animator->resume();
            }
            _rotatingToNorth = NO;
            break;
        }
            
        case OAMapModeFollow:
        {
            // In case previous mode was PositionTrack, remember azimuth, elevation angle and zoom
            if (_lastMapMode == OAMapModePositionTrack && !_isIn3dMode)
            {
                _lastAzimuthInPositionTrack = _mapView.azimuth;
                _lastZoom = _mapView.zoom;
                _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
                _lastPositionTrackStateCaptured = true;
                _isIn3dMode = YES;
            }

            _startChangingMapMode = [NSDate date];

            _mapView.animator->pause();
            _mapView.animator->cancelAllAnimations();

            if (_lastAppMode == OAAppModeBrowseMap)
            {
                _mapView.animator->animateZoomTo(kMapModeFollowDefaultZoom,
                                                kOneSecondAnimatonTime,
                                                OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                kLocationServicesAnimationKey);
                
                _mapView.animator->animateElevationAngleTo(kMapModeFollowDefaultElevationAngle,
                                                          kOneSecondAnimatonTime,
                                                          OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                          kLocationServicesAnimationKey);
            }

            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation != nil)
            {
                OsmAnd::PointI newTarget31(
                                           OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                           OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

                if (_lastAppMode == OAAppModeBrowseMap)
                {
                    
                    _mapView.animator->animateTargetTo(newTarget31,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::Linear,
                                                      kLocationServicesAnimationKey);
                    
                    const auto direction = _app.locationServices.lastKnownHeading;
                    
                    if (!isnan(direction) && direction >= 0)
                    {
                        _mapView.animator->animateAzimuthTo(direction,
                                                           kOneSecondAnimatonTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                }
                else
                {
                    _mapView.zoom = kMapModeFollowDefaultZoom;
                    _mapView.elevationAngle = kMapModeFollowDefaultElevationAngle;

                    double direction = newLocation.course;
                    //double direction = _app.locationServices.lastKnownHeading;
                    if (!isnan(direction) && direction >= 0)
                    {
                        // Set rotation
                        _mapView.azimuth = direction;
                    }

                    CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
                    centerPoint.x *= _mapView.contentScaleFactor;
                    centerPoint.y *= _mapView.contentScaleFactor;
                    
                    // Convert point from screen to location
                    OsmAnd::PointI bottomLocation;
                    [_mapView convert:centerPoint toLocation:&bottomLocation];
                    
                    OsmAnd::PointI targetCenter;
                    targetCenter.x = newTarget31.x + _mapView.target31.x - bottomLocation.x;
                    targetCenter.y = newTarget31.y + _mapView.target31.y - bottomLocation.y;
                    
                    _mapView.target31 = targetCenter;
                    //NSLog(@"targetCenter %d %d", targetCenter.x, targetCenter.y);
                }
            }

            _mapView.animator->resume();
            break;
        }

        default:
            return;
    }

    _lastMapMode = _app.mapMode;
}

- (void)onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (![self isViewLoaded])
            return;
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;

        [_mapLayers.myPositionLayer updateLocation:newLocation heading:newHeading];
        
        // Wait for Map Mode changing animation if any, to prevent animation lags
        if (_startChangingMapMode && [[NSDate date] timeIntervalSinceDate:_startChangingMapMode] < kOneSecondAnimatonTime)
            return;
        
        const OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                         OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

        // If map mode is position-track or follow, move to that position
        if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
        {
            _mapView.animator->pause();
            
            const auto targetAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                               OsmAnd::MapAnimator::AnimatedValue::Target);
            
            _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                     OsmAnd::MapAnimator::AnimatedValue::Target);
            
            if (_lastAppMode == OAAppModeBrowseMap)
            {
                // For "follow-me" mode azimuth is also controlled
                if (_app.mapMode == OAMapModeFollow)
                {
                    const auto azimuthAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                                        OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                    _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                             OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                    
                    // Update azimuth if there's one
                    const auto direction = (_lastAppMode == OAAppModeBrowseMap)
                    ? newHeading
                    : newLocation.course;
                    if (!isnan(direction) && direction >= 0)
                    {
                        if (azimuthAnimation)
                        {
                            _mapView.animator->cancelAnimation(azimuthAnimation);
                            
                            _mapView.animator->animateAzimuthTo(direction,
                                                               azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(),
                                                               OsmAnd::MapAnimator::TimingFunction::Linear,
                                                               kLocationServicesAnimationKey);
                        }
                        else
                        {
                            _mapView.animator->animateAzimuthTo(direction,
                                                               kOneSecondAnimatonTime,
                                                               OsmAnd::MapAnimator::TimingFunction::Linear,
                                                               kLocationServicesAnimationKey);
                        }
                    }
                }
                
                // And also update target
                if (targetAnimation)
                {
                    _mapView.animator->cancelAnimation(targetAnimation);
                    
                    double duration = targetAnimation->getDuration() - targetAnimation->getTimePassed();
                    _mapView.animator->animateTargetTo(newTarget31,
                                                      duration,
                                                      OsmAnd::MapAnimator::TimingFunction::Linear,
                                                      kLocationServicesAnimationKey);
                }
                else
                {
                    if (_app.mapMode == OAMapModeFollow)
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                          kOneSecondAnimatonTime,
                                                          OsmAnd::MapAnimator::TimingFunction::Linear,
                                                          kLocationServicesAnimationKey);
                    }
                    else //if (_app.mapMode == OAMapModePositionTrack)
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                          kOneSecondAnimatonTime,
                                                          OsmAnd::MapAnimator::TimingFunction::Linear,
                                                          kLocationServicesAnimationKey);
                    }
                }
            }
            else
            {
                double direction = newLocation.course;
                //double direction = _app.locationServices.lastKnownHeading;
                if (!isnan(direction) && direction >= 0)
                {
                    // Set rotation
                    _mapView.azimuth = direction;
                }
                CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
                centerPoint.x *= _mapView.contentScaleFactor;
                centerPoint.y *= _mapView.contentScaleFactor;
                
                // Convert point from screen to location
                OsmAnd::PointI bottomLocation;
                [_mapView convert:centerPoint toLocation:&bottomLocation];
                
                OsmAnd::PointI targetCenter;
                targetCenter.x = newTarget31.x + _mapView.target31.x - bottomLocation.x;
                targetCenter.y = newTarget31.y + _mapView.target31.y - bottomLocation.y;
                
                _mapView.target31 = targetCenter;
                //NSLog(@"targetCenter2 %d %d", targetCenter.x, targetCenter.y);
            }
            
            _mapView.animator->resume();
        }
    });
}

- (void)onMapSettingsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void)onUpdateGpxTracks
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            _gpxDocs.clear();
            return;
        }
        
        [self refreshGpxTracks];
    });
}

- (void)onUpdateRecTrack
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        if ([OAAppSettings sharedManager].mapSettingShowRecordingTrack)
        {
            if (!_recTrackShowing)
                [self showRecGpxTrack];
        }
        else
        {
            if (_recTrackShowing)
                [self hideRecGpxTrack];
        }
    });
}

- (void)onUpdateRouteTrack
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        [self showRouteGpxTrack];
    });
}

- (void)onTrackRecordingChanged
{
    if (![OAAppSettings sharedManager].mapSettingShowRecordingTrack)
        return;
    
    if (!self.isViewLoaded || self.view.window == nil)
    {
        _mapSourceInvalidated = YES;
        return;
    }
    
    if (!self.minimap)
        [self showRecGpxTrack];
}

- (void)onMapLayerChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_mapLayers.myPositionLayer updateMyLocationCourseProvider];
            [self updateCurrentMapSource];
        });
    });
}

-(void)onLanguageSettingsChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void)onGpxRouteDefined
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [_gpxRouter.routeDoc buildRouteTrack];
            [self setGeoInfoDocsGpxRoute:_gpxRouter.routeDoc];
            [self setDocFileRoute:_gpxRouter.gpx.gpxFileName];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshGpxTracks];
            });
        });
    });
}

- (void)onGpxRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideRouteGpxTrack];
    });
}

- (void)onGpxRouteChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRouteGpxTrack];
    });
}

- (void)updateCurrentMapSource
{
    if (![self isViewLoaded])
        return;
    
    @synchronized(_rendererSync)
    {
        const auto screenTileSize = 256 * self.displayDensityFactor;
        const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
        OALog(@"Screen tile size %fpx, raster tile size %dpx", screenTileSize, rasterTileSize);

        // Set reference tile size on the screen
        _mapView.referenceTileSizeOnScreenInPixels = screenTileSize;

        // Release previously-used resources (if any)
        [_mapLayers resetLayers];
        
        _rasterMapProvider.reset();

        _obfMapObjectsProvider.reset();
        _mapPrimitivesProvider.reset();
        _mapPresentationEnvironment.reset();
        _mapPrimitiviser.reset();

        if (_mapObjectsSymbolsProvider)
            [_mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProvider];
        _mapObjectsSymbolsProvider.reset();

        if (!_gpxDocFileTemp)
            _gpxDocsTemp.clear();
        if (!_gpxDocFileRoute)
            _gpxDocsRoute.clear();

        _gpxDocsRec.clear();
        
        
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

            NSLog(@"%@", [OAUtilities currentLang]);
            
            OsmAnd::MapPresentationEnvironment::LanguagePreference langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
            
            switch ([[OAAppSettings sharedManager] settingMapLanguage]) {
                case 0:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
                case 1:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrNative;
                    break;
                case 2:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeAndLocalized;
                    break;
                case 6:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrTransliterated;
                    break;
                case 4:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedAndNative;
                    break;
                case 5:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrTransliteratedAndNative;
                    break;
                default:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
            }
            
            NSString *langId = [OAUtilities currentLang];
            if ([[OAAppSettings sharedManager] settingPrefMapLanguage])
                langId = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            else if ([[OAAppSettings sharedManager] settingMapLanguageShowLocal] &&
                     [[OAAppSettings sharedManager] settingMapLanguageTranslit])
                langId = @"en";
            
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     1.0,
                                                                                     1.0,
                                                                                     QString::fromNSString(langId),
                                                                                     langPreferences));
            
            
            _mapPrimitiviser.reset(new OsmAnd::MapPrimitiviser(_mapPresentationEnvironment));
            _mapPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_obfMapObjectsProvider,
                                                                           _mapPrimitiviser,
                                                                           rasterTileSize));

            // Configure with preset if such is set
            if (lastMapSource.variant != nil)
            {
                OALog(@"Using '%@' variant of style '%@'", lastMapSource.variant, unresolvedMapStyle->name.toNSString());

                OAAppSettings *settings = [OAAppSettings sharedManager];
                QHash< QString, QString > newSettings;
                
                NSString *appMode = [OAApplicationMode getAppModeByVariantTypeStr:lastMapSource.variant];
                newSettings[QString::fromLatin1("appMode")] = QString([appMode UTF8String]);
                                
                if(settings.settingAppMode == APPEARANCE_MODE_NIGHT)
                    newSettings[QString::fromLatin1("nightMode")] = "true";
                
                // --- Apply Map Style Settings
                OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
                
                NSArray *params = styleSettings.getAllParameters;
                for (OAMapStyleParameter *param in params) {
                    if (param.value.length > 0 && ![param.value isEqualToString:@"false"])
                        newSettings[QString::fromNSString(param.name)] = QString::fromNSString(param.value);
                }
                
                if (!newSettings.isEmpty())
                    _mapPresentationEnvironment->setSettings(newSettings);
            }
        
#if defined(OSMAND_IOS_DEV)
            switch (_visualMetricsMode)
            {
                case OAVisualMetricsModeBinaryMapData:
                    _rasterMapProvider.reset(new OsmAnd::ObfMapObjectsMetricsLayerProvider(_obfMapObjectsProvider,
                                                                                           256 * _mapView.contentScaleFactor,
                                                                                           _mapView.contentScaleFactor));
                    break;

                case OAVisualMetricsModeBinaryMapPrimitives:
                    _rasterMapProvider.reset(new OsmAnd::MapPrimitivesMetricsLayerProvider(_mapPrimitivesProvider,
                                                                                           256 * _mapView.contentScaleFactor,
                                                                                           _mapView.contentScaleFactor));
                    break;

                case OAVisualMetricsModeBinaryMapRasterize:
                {
                    std::shared_ptr<OsmAnd::MapRasterLayerProvider> backendProvider(
                        new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
                    _rasterMapProvider.reset(new OsmAnd::MapRasterMetricsLayerProvider(backendProvider,
                                                                                       256 * _mapView.contentScaleFactor,
                                                                                       _mapView.contentScaleFactor));
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
            [_mapView setProvider:_rasterMapProvider
                        forLayer:0];

#if defined(OSMAND_IOS_DEV)
            if (!_hideStaticSymbols)
            {
                _mapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                       rasterTileSize));
                [_mapView addTiledSymbolsProvider:_mapObjectsSymbolsProvider];
            }
#else
            _mapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                   rasterTileSize));
            [_mapView addTiledSymbolsProvider:_mapObjectsSymbolsProvider];
#endif
            
        }
        else if (mapSourceResource->type == OsmAndResourceType::OnlineTileSources)
        {
            const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(mapSourceResource->metadata)->sources;
            OALog(@"Using '%@' online source from '%@' resource", lastMapSource.variant, mapSourceResource->id.toNSString());

            const auto onlineMapTileProvider = onlineTileSources->createProviderFor(QString::fromNSString(lastMapSource.variant), _webClient);
            if (!onlineMapTileProvider)
            {
                // Missing resource, shift to default
                _app.data.lastMapSource = [OAAppData defaults].lastMapSource;
                return;
            }
            onlineMapTileProvider->setLocalCachePath(QString::fromNSString(_app.cachePath));
            _rasterMapProvider = onlineMapTileProvider;
            [_mapView setProvider:_rasterMapProvider
                        forLayer:0];
            
            lastMapSource = [OAAppData defaults].lastMapSource;
            const auto resourceId = QString::fromNSString(lastMapSource.resourceId);
            const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
            const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
            
            const auto& resolvedMapStyle = _app.resourcesManager->mapStylesCollection->getResolvedStyleByName(unresolvedMapStyle->name);
            OALog(@"Using '%@' style from '%@' resource", unresolvedMapStyle->name.toNSString(), mapSourceResource->id.toNSString());
            
            _obfMapObjectsProvider.reset(new OsmAnd::ObfMapObjectsProvider(_app.resourcesManager->obfsCollection));
            
            NSLog(@"%@", [OAUtilities currentLang]);
            
            OsmAnd::MapPresentationEnvironment::LanguagePreference langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
            
            switch ([[OAAppSettings sharedManager] settingMapLanguage]) {
                case 0:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
                case 1:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrNative;
                    break;
                case 2:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeAndLocalized;
                    break;
                case 6:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrTransliterated;
                    break;
                case 4:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedAndNative;
                    break;
                case 5:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::LocalizedOrTransliteratedAndNative;
                    break;
                default:
                    langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
                    break;
            }
            
            NSString *langId = [OAUtilities currentLang];
            if ([[OAAppSettings sharedManager] settingPrefMapLanguage])
                langId = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            else if ([[OAAppSettings sharedManager] settingMapLanguageShowLocal] &&
                     [[OAAppSettings sharedManager] settingMapLanguageTranslit])
                langId = @"en";
            
            
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     1.0,
                                                                                     1.0,
                                                                                     QString::fromNSString(langId),
                                                                                     langPreferences));
            
            
            _mapPrimitiviser.reset(new OsmAnd::MapPrimitiviser(_mapPresentationEnvironment));
            _mapPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_obfMapObjectsProvider,
                                                                           _mapPrimitiviser,
                                                                           rasterTileSize));
        }
        
        [_mapLayers updateLayers];

        if (!_gpxDocFileTemp && [OAAppSettings sharedManager].mapSettingShowRecordingTrack)
            [self showRecGpxTrack];
        
        if (_gpxRouter.gpx && !_gpxDocFileRoute)
        {
            [_gpxRouter.routeDoc buildRouteTrack];
            [self setGeoInfoDocsGpxRoute:_gpxRouter.routeDoc];
            [self setDocFileRoute:_gpxRouter.gpx.gpxFileName];
        }
        
        [self buildGpxList];
        if (!_gpxDocs.isEmpty() || !_gpxDocsTemp.isEmpty() || !_gpxDocsRoute.isEmpty())
            [self initRendererWithGpxTracks];

        if (_gpxNaviTrack)
            [self initRendererWithNaviTrack];
        
        [self fireWaitForIdleEvent];
    }
}

- (void) showPoiOnMap:(NSString *)category type:(NSString *)type filter:(NSString *)filter keyword:(NSString *)keyword
{
    [_mapLayers.poiLayer showPoiOnMap:category type:type filter:filter keyword:keyword];
}

- (void) showPoiOnMap:(OAPOIUIFilter *)uiFilter keyword:(NSString *)keyword
{
    [_mapLayers.poiLayer showPoiOnMap:uiFilter keyword:keyword];
}

- (void) hidePoi
{
    [_mapLayers.poiLayer hidePoi];
}

- (void) onLayersConfigurationChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayer:value];
    });
}

- (void) runWithRenderSync:(void (^)(void))runnable
{
    if (![self isViewLoaded] || !runnable)
        return;
    
    @synchronized(_rendererSync)
    {
        runnable();
    }
}

- (void) updateLayer:(NSString *)layerId
{
    if (![self isViewLoaded])
        return;

    @synchronized(_rendererSync)
    {
        if ([_app.data.mapLayersConfiguration isLayerVisible:layerId])
            [_mapLayers showLayer:layerId];
        else
            [_mapLayers hideLayer:layerId];
    }
}

- (CGFloat) displayDensityFactor
{
#if defined(OSMAND_IOS_DEV)
    if (_forceDisplayDensityFactor)
        return _forcedDisplayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)

    if (![self isViewLoaded])
        return [UIScreen mainScreen].scale;
    return self.view.contentScaleFactor;
}

- (CGFloat) screensToFly:(Point31)position31
{
    const auto lon1 = OsmAnd::Utilities::get31LongitudeX(position31.x);
    const auto lat1 = OsmAnd::Utilities::get31LatitudeY(position31.y);
    const auto lon2 = OsmAnd::Utilities::get31LongitudeX(_mapView.target31.x);
    const auto lat2 = OsmAnd::Utilities::get31LatitudeY(_mapView.target31.y);
    
    const auto distance = OsmAnd::Utilities::distance(lon1, lat1, lon2, lat2);
    CGFloat distanceInPixels = distance / _mapView.currentPixelsToMetersScaleFactor;
    return distanceInPixels / ((DeviceScreenWidth + DeviceScreenHeight) / 2.0);
}

- (void) goToPosition:(Point31)position31
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;

    @synchronized(_rendererSync)
    {
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            _mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kQuickAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            _mapView.animator->resume();
        }
        else
        {
            [_mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
        }
    }
}

- (void) goToPosition:(Point31)position31
             andZoom:(CGFloat)zoom
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;
    
    @synchronized(_rendererSync)
    {
        CGFloat z = [self normalizeZoom:zoom defaultZoom:_mapView.zoom];
        
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            _mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kQuickAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            _mapView.animator->animateZoomTo(z,
                                            kQuickAnimationTime,
                                            OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                            kUserInteractionAnimationKey);
            _mapView.animator->resume();
        }
        else
        {
            [_mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
            [_mapView setZoom:z];
        }
    }
}

- (void) correctPosition:(Point31)targetPosition31
       originalCenter31:(Point31)originalCenter31
              leftInset:(CGFloat)leftInset
            bottomInset:(CGFloat)bottomInset
             centerBBox:(BOOL)centerBBox
               animated:(BOOL)animated
{
    CGFloat leftTargetInset;
    CGFloat bottomTargetInset;
    if (centerBBox)
    {
        leftTargetInset = kCorrectionMinLeftSpaceBBox;
        bottomTargetInset = kCorrectionMinBottomSpaceBBox;
    }
    else
    {
        leftTargetInset = kCorrectionMinLeftSpace;
        bottomTargetInset = kCorrectionMinBottomSpace;
    }
    
    OsmAnd::PointI originalCenterI = [OANativeUtilities convertFromPoint31:originalCenter31];
    
    CGPoint targetPoint;
    OsmAnd::PointI targetPositionI = [OANativeUtilities convertFromPoint31:targetPosition31];
    [_mapView convert:&targetPositionI toScreen:&targetPoint];
    
    OsmAnd::PointI newPositionI = _mapView.target31;
    
    CGFloat targetY = DeviceScreenHeight - bottomInset - bottomTargetInset;
    
    CGPoint minPoint = CGPointMake(DeviceScreenWidth / 2.0, targetY);
    minPoint.x *= _mapView.contentScaleFactor;
    minPoint.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI minLocation;
    [_mapView convert:minPoint toLocation:&minLocation];
    
    newPositionI.y = _mapView.target31.y - (minLocation.y - targetPosition31.y);
    if (newPositionI.y < originalCenterI.y)
        newPositionI.y = originalCenterI.y;
    
    CGFloat targetX = leftInset + leftTargetInset;
    minPoint = CGPointMake(targetX, DeviceScreenHeight / 2.0);
    minPoint.x *= _mapView.contentScaleFactor;
    minPoint.y *= _mapView.contentScaleFactor;
    [_mapView convert:minPoint toLocation:&minLocation];
    
    newPositionI.x = _mapView.target31.x + (-minLocation.x + targetPosition31.x);
    if (newPositionI.x > originalCenterI.x)
        newPositionI.x = originalCenterI.x;
    
    Point31 newPosition31 = [OANativeUtilities convertFromPointI:newPositionI];
    [self goToPosition:newPosition31 animated:animated];
}

- (CGFloat) normalizeZoom:(CGFloat)zoom defaultZoom:(CGFloat)defaultZoom
{
    OAMapRendererView* renderer = (OAMapRendererView*)self.view;

    if (!isnan(zoom))
    {
        if (zoom < renderer.minZoom)
            return renderer.minZoom;
        if (zoom > renderer.maxZoom)
            return renderer.maxZoom;
        return zoom;
    }
    else if (isnan(zoom) && !isnan(defaultZoom))
    {
        return defaultZoom;
    }
    else
    {
        return 3.0;
    }
}

- (void) showRouteGpxTrack
{
    @synchronized(_rendererSync)
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideRouteGpxTrack
{
    @synchronized(_rendererSync)
    {
        _gpxDocsRoute.clear();
        _gpxDocFileRoute = nil;
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) showTempGpxTrack:(NSString *)fileName
{
    if (_recTrackShowing)
        [self hideRecGpxTrack];

    @synchronized(_rendererSync)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx containsObject:fileName]) {
            _gpxDocFileTemp = nil;
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
            return;
        }
        
        _tempTrackShowing = YES;

        if (![_gpxDocFileTemp isEqualToString:fileName] || _gpxDocsTemp.isEmpty()) {
            _gpxDocsTemp.clear();
            _gpxDocFileTemp = [fileName copy];
            NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
            _gpxDocsTemp.append(OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path)));
        }
        
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideTempGpxTrack
{
    @synchronized(_rendererSync)
    {
        _tempTrackShowing = NO;
        
        _gpxDocsTemp.clear();
        _gpxDocFileTemp = nil;

        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) showRecGpxTrack
{
    if (_tempTrackShowing)
        [self hideTempGpxTrack];
    
    @synchronized(_rendererSync)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        if (![helper hasData])
            return;
        else
            [_mapLayers.gpxRecMapLayer resetLayer];
    
        [helper runSyncBlock:^{
            
            const auto& doc = [[OASavingTrackHelper sharedInstance].currentTrack getDocument];
            if (doc != nullptr)
            {
                _recTrackShowing = YES;
                
                _gpxDocsRec.clear();
                _gpxDocsRec << doc;
                
                [_mapLayers.gpxRecMapLayer refreshGpxTracks:_gpxDocsRec mapPrimitiviser:_mapPrimitiviser];
            }
        }];
    }
}

- (void) hideRecGpxTrack
{
    @synchronized(_rendererSync)
    {
        _recTrackShowing = NO;
        [_mapLayers.gpxRecMapLayer resetLayer];
        _gpxDocsRec.clear();
    }
}


- (void) keepTempGpxTrackVisible
{
    if (!_gpxDocFileTemp || _gpxDocsTemp.isEmpty())
        return;

    std::shared_ptr<const OsmAnd::GeoInfoDocument> doc = _gpxDocsTemp.first();
    if (!_gpxDocs.contains(doc)) {
        
        _gpxDocs.append(doc);
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpxDocFileTemp];
        _gpxDocsPaths = [_gpxDocsPaths arrayByAddingObjectsFromArray:@[path]];
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        [settings showGpx:_gpxDocFileTemp];
        
        @synchronized(_rendererSync)
        {
            _tempTrackShowing = NO;
            _gpxDocsTemp.clear();
            _gpxDocFileTemp = nil;
        }

        [self initRendererWithGpxTracks];
    }
}

- (void) setWptData:(OASearchWptAPI *)wptApi
{
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > list(_gpxDocs);
    list << _gpxDocsRec;
    [wptApi setWptData:list paths:_gpxDocsPaths];
}

- (void) buildGpxList
{
    NSMutableArray *paths = [NSMutableArray array];
    _gpxDocs.clear();
    OAAppSettings *settings = [OAAppSettings sharedManager];
    for (NSString *fileName in settings.mapSettingVisibleGpx)
    {
        if (_gpxDocFileRoute && [fileName isEqualToString:_gpxDocFileRoute])
            continue;
        
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            _gpxDocs.append(OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path)));
            [paths addObject:path];
        }
        else
        {
            [settings hideGpx:fileName];
        }
    }
    _gpxDocsPaths = [NSArray arrayWithArray:paths];
}

- (BOOL) hasFavoriteAt:(CLLocationCoordinate2D)location
{
    for (const auto& fav : [_mapLayers.favoritesLayer getFavoritesMarkersCollection]->getMarkers())
    {
        double lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition().x);
        double lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition().y);
        if ([OAUtilities doublesEqualUpToDigits:5 source:lat destination:location.latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:lon destination:location.longitude])
        {
            return YES;
        }
    }

    return NO;
}

- (BOOL) hasWptAt:(CLLocationCoordinate2D)location
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
    
    BOOL found = NO;
    
    for (OAGpxWpt *wptItem in helper.currentTrack.locationMarks)
    {
        if ([OAUtilities doublesEqualUpToDigits:5 source:wptItem.position.latitude destination:location.latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:wptItem.position.longitude destination:location.longitude])
        {
            found = YES;
        }
    }
    
    if (found)
        return YES;
    
    int i = 0;
    for (const auto& doc : _gpxDocs)
    {
        for (auto& loc : doc->locationMarks)
        {
            if ([OAUtilities doublesEqualUpToDigits:5 source:loc->position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:loc->position.longitude destination:location.longitude])
            {
                found = YES;
            }
        }
        
        if (found)
            return YES;
        
        i++;
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto& doc = _gpxDocsTemp.first();
        
        for (auto& loc : doc->locationMarks)
        {
            if ([OAUtilities doublesEqualUpToDigits:5 source:loc->position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:loc->position.longitude destination:location.longitude])
            {
                found = YES;
            }
        }
        
        if (found)
            return YES;
    }
    
    if (!_gpxDocsRoute.isEmpty())
    {
        for (OAGpxRoutePoint *point in _gpxRouter.routeDoc.locationMarks)
        {
            if ([OAUtilities doublesEqualUpToDigits:5 source:point.position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:point.position.longitude destination:location.longitude])
            {
                found = YES;
            }
        }
        
        if (found)
            return YES;
    }
    
    return NO;
}

- (BOOL) findWpt:(CLLocationCoordinate2D)location
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];

    BOOL found = NO;
    NSMutableSet *groups = [NSMutableSet set];
    
    for (OAGpxWpt *wptItem in helper.currentTrack.locationMarks)
    {
        if (wptItem.type.length > 0)
            [groups addObject:wptItem.type];
        
        if ([OAUtilities doublesEqualUpToDigits:5 source:wptItem.position.latitude destination:location.latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:wptItem.position.longitude destination:location.longitude])
        {
            self.foundWpt = wptItem;
            self.foundWptDocPath = nil;
            
            found = YES;
        }
    }

    if (found)
    {
        self.foundWptGroups = [groups allObjects];
        return YES;
    }
    else
    {
        [groups removeAllObjects];
    }
    
    int i = 0;
    for (const auto& doc : _gpxDocs)
    {
        for (auto& loc : doc->locationMarks)
        {
            if (!loc->type.isEmpty())
                [groups addObject:loc->type.toNSString()];

            if ([OAUtilities doublesEqualUpToDigits:5 source:loc->position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:loc->position.longitude destination:location.longitude])
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> w = _wpt->shared_ptr();

                OAGpxWpt *wptItem = [OAGPXDocument fetchWpt:w];
                wptItem.wpt = w;
                
                self.foundWpt = wptItem;
                
                self.foundWptDocPath = _gpxDocsPaths[i];
                
                found = YES;
            }
        }
        
        if (found)
        {
            self.foundWptGroups = [groups allObjects];
            return YES;
        }
        else
        {
            [groups removeAllObjects];
        }
        
        i++;
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto& doc = _gpxDocsTemp.first();
    
        for (auto& loc : doc->locationMarks)
        {
            if (!loc->type.isEmpty())
                [groups addObject:loc->type.toNSString()];
            
            if ([OAUtilities doublesEqualUpToDigits:5 source:loc->position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:loc->position.longitude destination:location.longitude])
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> w = _wpt->shared_ptr();
                
                OAGpxWpt *wptItem = [OAGPXDocument fetchWpt:w];
                wptItem.wpt = w;
                
                self.foundWpt = wptItem;
                
                self.foundWptDocPath = _gpxDocFileTemp;
                
                found = YES;
            }
        }
        
        if (found)
        {
            self.foundWptGroups = [groups allObjects];
            return YES;
        }
    }

    if (!_gpxDocsRoute.isEmpty())
    {
        for (OAGpxRoutePoint *point in _gpxRouter.routeDoc.locationMarks)
        {
            if (point.type.length > 0)
                [groups addObject:point.type];

            if ([OAUtilities doublesEqualUpToDigits:5 source:point.position.latitude destination:location.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:point.position.longitude destination:location.longitude])
            {
                self.foundWpt = point;
                self.foundWptDocPath = _gpxDocFileRoute;
                
                found = YES;
            }
        }
        
        if (found)
        {
            self.foundWptGroups = [groups allObjects];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)deleteFoundWpt
{
    if (!self.foundWpt)
        return NO;
    
    if (!self.foundWptDocPath)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        
        [helper deleteWpt:self.foundWpt];
        
        // update map
        [[_app trackRecordingObservable] notifyEvent];
        
        [self hideContextPinMarker];
        
        return YES;
    }
    else if ([_gpxDocFileRoute isEqualToString:[self.foundWptDocPath lastPathComponent]])
    {
        auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocsRoute.first());
        auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
        
        gpx->locationMarks.removeOne(_foundWpt.wpt);

        [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
        [[OAGPXDatabase sharedDb] save];
        
        [[OAGPXRouter sharedInstance].routeDoc removeRoutePoint:self.foundWpt];
        [[OAGPXRouter sharedInstance] saveRouteIfModified];
        
        [self hideContextPinMarker];

        return YES;
    }
    else
    {
        for (int i = 0; i < _gpxDocsPaths.count; i++)
        {
            if ([_gpxDocsPaths[i] isEqualToString:self.foundWptDocPath])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocs[i]);
                auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
                
                if (!gpx->locationMarks.removeOne(_foundWpt.wpt))
                    for (int i = 0; i < gpx->locationMarks.count(); i++)
                    {
                        const auto& w = gpx->locationMarks[i];
                        if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:_foundWpt.wpt->position.latitude] &&
                            [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:_foundWpt.wpt->position.longitude])
                        {
                            gpx->locationMarks.removeAt(i);
                            break;
                        }
                    }
                
                gpx->saveTo(QString::fromNSString(self.foundWptDocPath));
                
                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
                [[OAGPXDatabase sharedDb] save];
                
                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
                
                [self hideContextPinMarker];

                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)saveFoundWpt
{
    if (!self.foundWpt)
        return NO;
    
    if (!self.foundWptDocPath)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        
        [helper saveWpt:self.foundWpt];
        
        // update map
        [[_app trackRecordingObservable] notifyEvent];
        
        return YES;
    }
    else if ([_gpxDocFileRoute isEqualToString:[self.foundWptDocPath lastPathComponent]])
    {
        [[OAGPXRouter sharedInstance].routeChangedObservable notifyEvent];
        [[OAGPXRouter sharedInstance] saveRouteIfModified];
    }
    else
    {
        for (int i = 0; i < _gpxDocsPaths.count; i++)
        {
            if ([_gpxDocsPaths[i] isEqualToString:self.foundWptDocPath])
            {
                const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_gpxDocs[i]);
                
                for (const auto& loc : doc->locationMarks)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&loc;
                    const std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> w = _wpt->shared_ptr();

                    if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:self.foundWpt.position.latitude] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:self.foundWpt.position.longitude])
                    {
                        [OAGPXDocument fillWpt:w usingWpt:self.foundWpt];
                        break;
                    }
                }
                
                doc->saveTo(QString::fromNSString(self.foundWptDocPath));
                
                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
                
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)addNewWpt:(OAGpxWpt *)wpt gpxFileName:(NSString *)gpxFileName
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];

    if (!gpxFileName)
    {
        [helper addWpt:wpt];
        self.foundWpt = wpt;
        self.foundWptDocPath = nil;
        
        NSMutableSet *groups = [NSMutableSet set];
        for (OAGpxWpt *wptItem in helper.currentTrack.locationMarks)
        {
            if (wptItem.type.length > 0)
                [groups addObject:wptItem.type];
        }
        
        self.foundWptGroups = [groups allObjects];
        
        // update map
        [[_app trackRecordingObservable] notifyEvent];
        
        return YES;
    }
    else
    {
        for (int i = 0; i < _gpxDocsPaths.count; i++)
        {
            if ([_gpxDocsPaths[i] isEqualToString:gpxFileName])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocs[i]);
                auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
                
                std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> p;
                p.reset(new OsmAnd::GpxDocument::GpxWpt());
                [OAGPXDocument fillWpt:p usingWpt:wpt];
                
                gpx->locationMarks.append(p);
                gpx->saveTo(QString::fromNSString(gpxFileName));
                
                wpt.wpt = p;
                self.foundWpt = wpt;
                self.foundWptDocPath = gpxFileName;
                
                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
                [[OAGPXDatabase sharedDb] save];
                
                NSMutableSet *groups = [NSMutableSet set];
                for (auto& loc : gpx->locationMarks)
                {
                    if (!loc->type.isEmpty())
                        [groups addObject:loc->type.toNSString()];
                }
                
                self.foundWptGroups = [groups allObjects];

                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
                
                return YES;
            }
        }
        
        if ([_gpxDocFileTemp isEqualToString:[gpxFileName lastPathComponent]])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocsTemp.first());
            auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
            
            std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> p;
            p.reset(new OsmAnd::GpxDocument::GpxWpt());
            [OAGPXDocument fillWpt:p usingWpt:wpt];
            
            gpx->locationMarks.append(p);
            gpx->saveTo(QString::fromNSString(gpxFileName));
            
            wpt.wpt = p;
            self.foundWpt = wpt;
            self.foundWptDocPath = gpxFileName;
            
            [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
            [[OAGPXDatabase sharedDb] save];
            
            NSMutableSet *groups = [NSMutableSet set];
            for (auto& loc : gpx->locationMarks)
            {
                if (!loc->type.isEmpty())
                    [groups addObject:loc->type.toNSString()];
            }
            
            self.foundWptGroups = [groups allObjects];
            
            return YES;
        }
        
        if ([_gpxDocFileRoute isEqualToString:[gpxFileName lastPathComponent]])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocsRoute.first());
            auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
            
            std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> p;
            p.reset(new OsmAnd::GpxDocument::GpxWpt());
            wpt.wpt = p;

            OAGpxRoutePoint *rp = [[OAGPXRouter sharedInstance].routeDoc addRoutePoint:wpt];
            
            gpx->locationMarks.append(p);
            
            self.foundWpt = rp;
            self.foundWptDocPath = gpxFileName;
            
            [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
            [[OAGPXDatabase sharedDb] save];
            
            NSMutableSet *groups = [NSMutableSet set];
            for (auto& loc : gpx->locationMarks)
            {
                if (!loc->type.isEmpty())
                    [groups addObject:loc->type.toNSString()];
            }
            
            self.foundWptGroups = [groups allObjects];
                        
            return YES;
        }
    }
    
    return YES;
}

- (BOOL)updateWpts:(NSArray *)items docPath:(NSString *)docPath updateMap:(BOOL)updateMap
{
    if (items.count == 0)
        return NO;

    BOOL found = NO;
    for (int i = 0; i < _gpxDocsPaths.count; i++)
    {
        if ([_gpxDocsPaths[i] isEqualToString:docPath])
        {
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_gpxDocs[i]);
         
            for (OAGpxWptItem *item in items)
            {
                for (const auto& loc : doc->locationMarks)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&loc;
                    const std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> w = _wpt->shared_ptr();
                    
                    if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                    {
                        [OAGPXDocument fillWpt:w usingWpt:item.point];
                        found = YES;
                        break;
                    }
                }
            }
            
            if (found)
            {
                doc->saveTo(QString::fromNSString(docPath));
                
                // update map
                if (updateMap)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initRendererWithGpxTracks];
                    });
            }
            
            return found;
        }
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_gpxDocsTemp.first());
        
        for (OAGpxWptItem *item in items)
        {
            for (const auto& loc : doc->locationMarks)
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> w = _wpt->shared_ptr();
                
                if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                    [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                {
                    [OAGPXDocument fillWpt:w usingWpt:item.point];
                    found = YES;
                    break;
                }
            }
        }
        
        if (found)
        {
            doc->saveTo(QString::fromNSString(docPath));
            
            // update map
            if (updateMap)
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self showTempGpxTrack:docPath];
                });
            
        }
    }
    
    return found;
}

- (BOOL)updateMetadata:(OAGpxMetadata *)metadata docPath:(NSString *)docPath
{
    if (!metadata)
        return NO;
    
    for (int i = 0; i < _gpxDocsPaths.count; i++)
    {
        if ([_gpxDocsPaths[i] isEqualToString:docPath])
        {
            auto docGeoInfo = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocs[i]);
            auto doc = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(docGeoInfo);
            
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxMetadata> *_meta = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxMetadata>*)&doc->metadata;
            std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata> m = _meta->shared_ptr();
            
            if (m == nullptr)
            {
                m.reset(new OsmAnd::GpxDocument::GpxMetadata());
                doc->metadata = m;
            }
            
            [OAGPXDocument fillMetadata:m usingMetadata:metadata];

            doc->saveTo(QString::fromNSString(docPath));
            
            return YES;
        }
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_gpxDocsTemp.first());
        
        OsmAnd::Ref<OsmAnd::GpxDocument::GpxMetadata> *_meta = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxMetadata>*)&doc->metadata;
        const std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata> m = _meta->shared_ptr();
        
        [OAGPXDocument fillMetadata:m usingMetadata:metadata];
        
        doc->saveTo(QString::fromNSString(docPath));
        
        return YES;
    }
    
    return NO;
}

- (BOOL)deleteWpts:(NSArray *)items docPath:(NSString *)docPath
{
    if (items.count == 0)
        return NO;
    
    BOOL found = NO;
    
    for (int i = 0; i < _gpxDocsPaths.count; i++)
    {
        if ([_gpxDocsPaths[i] isEqualToString:docPath])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocs[i]);
            auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
            
            for (OAGpxWptItem *item in items)
            {
                for (int i = 0; i < gpx->locationMarks.count(); i++)
                {
                    const auto& w = gpx->locationMarks[i];
                    if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                    {
                        gpx->locationMarks.removeAt(i);
                        found = YES;
                        break;
                    }
                }
            }
            
            if (found)
            {
                gpx->saveTo(QString::fromNSString(docPath));
                
                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[docPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
                [[OAGPXDatabase sharedDb] save];
                
                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
                
                return YES;
            }
        }
    }

    if (!_gpxDocsTemp.isEmpty())
    {
        auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_gpxDocsTemp.first());
        auto gpx = std::dynamic_pointer_cast<OsmAnd::GpxDocument>(doc);
        
        for (OAGpxWptItem *item in items)
        {
            for (int i = 0; i < gpx->locationMarks.count(); i++)
            {
                const auto& w = gpx->locationMarks[i];
                if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                    [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                {
                    gpx->locationMarks.removeAt(i);
                    found = YES;
                    break;
                }
            }
        }
        
        if (found)
        {
            gpx->saveTo(QString::fromNSString(docPath));
            
            [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[docPath lastPathComponent] pointsCount:gpx->locationMarks.count()];
            [[OAGPXDatabase sharedDb] save];
            
            // update map
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initRendererWithGpxTracks];
            });
            
            return YES;
        }
    }
    
    return NO;
}

- (void) initRendererWithGpxTracks
{
    if (!_gpxDocs.isEmpty() || !_gpxDocsTemp.isEmpty() || !_gpxDocsRoute.isEmpty())
    {
        QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > docs;
        docs << _gpxDocs << _gpxDocsTemp << _gpxDocsRoute;
        [_mapLayers.gpxMapLayer refreshGpxTracks:docs mapPrimitiviser:_mapPrimitiviser];
    }
}

- (void) resetGpxTracks
{
    @synchronized(_rendererSync)
    {
        [_mapLayers.gpxMapLayer resetLayer];
        _gpxDocs.clear();
    }
}

- (void) refreshGpxTracks
{
    [self resetGpxTracks];
    [self buildGpxList];
    [self initRendererWithGpxTracks];
}

- (void) initRendererWithNaviTrack
{
    if (_gpxNaviTrack)
    {
        [_mapLayers.routeMapLayer refreshRoute:_gpxNaviTrack mapPrimitiviser:_mapPrimitiviser];
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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

#endif // defined(OSMAND_IOS_DEV)

-(BOOL)isMyLocationVisible
{
    OAMapRendererView* renderView = (OAMapRendererView*)self.view;
    CLLocation* myLocation = _app.locationServices.lastKnownLocation;
    if (myLocation)
    {
        OsmAnd::PointI myLocation31(OsmAnd::Utilities::get31TileNumberX(myLocation.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(myLocation.coordinate.latitude));
        
        OsmAnd::AreaI visibleArea = [renderView getVisibleBBox31];
        
        return (visibleArea.topLeft.x < myLocation31.x && visibleArea.topLeft.y < myLocation31.y && visibleArea.bottomRight.x > myLocation31.x && visibleArea.bottomRight.y > myLocation31.y);
    }
    else
    {
        return YES;
    }
}

- (void) fireWaitForIdleEvent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForIdle) object:nil];
        [self performSelector:@selector(waitForIdle) withObject:nil afterDelay:1.0];
    });
}

- (void) waitForIdle
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_idleObservable notifyEvent];
    });
}

MBProgressHUD *calcRouteProgressHUD = nil;

- (void) buildRoute
{
    auto app = [OsmAndApp instance];
    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    
    [app initRoutingFiles];
    
    if (app.defaultRoutingConfig && destinations.count > 1)
    {
        calcRouteProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        calcRouteProgressHUD.minShowTime = .5f;
        calcRouteProgressHUD.removeFromSuperViewOnHide = YES;
        calcRouteProgressHUD.labelText = @"0%";
        [self.view addSubview:calcRouteProgressHUD];
        [calcRouteProgressHUD show:YES];

        OADestination *d1 = destinations[0];
        OADestination *d2 = destinations[1];
        CLLocation *from = [[CLLocation alloc] initWithLatitude:d1.latitude longitude:d1.longitude];
        CLLocation *to = [[CLLocation alloc] initWithLatitude:d2.latitude longitude:d2.longitude];
                
        OARoutingHelper *helper = [OARoutingHelper sharedInstance];
        [helper addListener:self];
        [helper setProgressBar:self];
        
        OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
        
        [helper setAppMode:OAMapVariantCar];
        // save application mode controls
        //settings.FOLLOW_THE_ROUTE.set(false);
        [helper setFollowingMode:false];
        [helper setRoutePlanningMode:true];
        // reset start point
        [targets setStartPoint:from updateRoute:false name:nil];
        [targets navigateToPoint:to updateRoute:true intermediate:-1];

        // then update start and destination point
        //[targets updateRouteAndRefresh:true];
    }
    else
    {
        _gpxNaviTrack = nullptr;
        @synchronized(_rendererSync)
        {
            [_mapLayers.routeMapLayer resetLayer];
            [self initRendererWithNaviTrack];
        }
    }
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{

        OARoutingHelper *helper = [OARoutingHelper sharedInstance];
        NSString *error = [helper getLastRouteCalcError];
        if ([helper isRouteCalculated] && !error)
        {
            NSMutableString *description = [NSMutableString string];
            NSTimeInterval timeInterval = [helper getLeftTime];
            int hours, minutes, seconds;
            [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
            
            NSMutableString *time = [NSMutableString string];
            if (hours > 0)
                [time appendFormat:@"%d %@", hours, OALocalizedString(@"units_hour")];
            if (minutes > 0)
            {
                if (time.length > 0)
                    [time appendString:@" "];
                [time appendFormat:@"%d %@", minutes, OALocalizedString(@"units_min")];
            }
            if (minutes == 0 && hours == 0)
            {
                if (time.length > 0)
                    [time appendString:@" "];
                [time appendFormat:@"%d %@", seconds, OALocalizedString(@"units_sec")];
            }
            
            float completeDistance = [helper getLeftDistance];
            NSString *distance = [[OsmAndApp instance] getFormattedDistance:completeDistance];
            [description appendFormat:@"Distance: %@ Time: %@", distance, time];
            
            [[[UIAlertView alloc] initWithTitle:@"Route calculated" message:description delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];

            OARouteCalculationResult *route = [helper getRoute];
            NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
            
            NSMutableString *gpxStr = [NSMutableString string];
            [gpxStr appendString:@"<?xml version='1.0' encoding='UTF-8' ?><gpx version=\"1.1\" creator=\"OsmAnd\"><trk><trkseg>"];
            for (CLLocation *loc : locations)
            {
                [gpxStr appendFormat:@"<trkpt lat=\"%f\" lon=\"%f\" />\n", loc.coordinate.latitude, loc.coordinate.longitude];
            }
            [gpxStr appendString:@"</trkseg></trk></gpx>"];

            QXmlStreamReader reader([gpxStr UTF8String]);
            _gpxNaviTrack = OsmAnd::GpxDocument::loadFrom(reader);
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Route calculation error" message:error delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];

            _gpxNaviTrack = nullptr;
        }

        @synchronized(_rendererSync)
        {
            [_mapLayers.routeMapLayer resetLayer];
            [self initRendererWithNaviTrack];
        }
    });
}

- (void) routeWasCancelled
{
}

- (void) routeWasFinished
{
}

#pragma mark - OARouteCalculationProgressCallback

- (void) updateProgress:(int)progress
{
    NSLog(@"Route calculation in progress: %d", progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (calcRouteProgressHUD)
            calcRouteProgressHUD.labelText = [NSString stringWithFormat:@"%d%%", progress];
    });
}

- (void) requestPrivateAccessRouting
{
    
}

- (void) finish
{
    NSLog(@"Route calculation finished");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (calcRouteProgressHUD)
            [calcRouteProgressHUD hide:YES];
    });
}


@end
