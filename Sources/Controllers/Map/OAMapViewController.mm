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
#import <UIViewController+JASidePanel.h>
#import <MBProgressHUD.h>
#import "OAAppData.h"
#import "OAMapRendererView.h"
#import "OAIndexConstants.h"
#import "OAAutoObserverProxy.h"
#import "OANavigationController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAFloatingButtonsHudViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAMapStyleSettings.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAGpxWptItem.h"
#import "OADestination.h"
#import "OAPluginPopupViewController.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAMapCreatorHelper.h"
#import "OAPOI.h"
#import "OAMapSettingsPOIScreen.h"
#import "OAPOILocationType.h"
#import "OAPOIMyLocationType.h"
#import "OAPOIUIFilter.h"
#import "OAQuickSearchHelper.h"
#import "OAMapLayers.h"
#import "OADestinationsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OACurrentPositionHelper.h"
#import "OAColors.h"
#import "OASubscriptionCancelViewController.h"
#import "OARouteStatistics.h"
#import "OAMapRendererEnvironment.h"
#import "OAMapPresentationEnvironment.h"
#import "OAWeatherHelper.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OASRTMPlugin.h"
#import "OAPlugin.h"
#import "OAGPXAppearanceCollection.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAZoom.h"
#import "OAMapSource.h"
#import "OARoutingHelper.h"
#import "OATransportRoutingHelper.h"
#import "OAPointDescription.h"
#import "OARouteCalculationResult.h"
#import "OATargetPointsHelper.h"
#import "OAAvoidSpecificRoads.h"
#import "OAPluginsHelper.h"
#import "OASubscriptionCancelViewController.h"
#import "OAWhatsNewBottomSheetViewController.h"
#import "OAApplicationMode.h"
#import "OAAppVersion.h"
#import "OALocationServices.h"
#import "OsmAnd_Maps-Swift.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OANativeUtilities.h"
#import "OALog.h"
#import "OAObservable.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"


//#include "OAMapMarkersCollection.h"
#include "OASQLiteTileSourceMapLayerProvider.h"
#include "OAWebClient.h"
#include <OsmAndCore/IWebClient.h>
#include <OpenGLES/ES2/gl.h>
#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
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
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/GeoTiffCollection.h>
#include <OsmAndCore/Map/SqliteHeightmapTileProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/MapRendererTypes.h>
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/QKeyValueIterator.h>

#define _(name) OAMapRendererViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

static const float kGestureZoomCoef = 10.0f;

static const float ZONE_0_ANGLE_THRESHOLD = 5.0f;
static const float ZONE_1_ANGLE_THRESHOLD = 20.0f;
static const float ZONE_2_ANGLE_THRESHOLD = 30.0f;
static const float ZONE_3_ANGLE_THRESHOLD = 60.0f;
static const float ZONE_0_ZOOM_THRESHOLD = 0.15f;
static const float ZONE_1_ZOOM_THRESHOLD = 0.6f;
static const float ZONE_2_ZOOM_THRESHOLD = 1.5f;


typedef NS_ENUM(NSInteger, EOAMapPanDirection) {
    EOAMapPanDirectionUp = 0,
    EOAMapPanDirectionDown,
    EOAMapPanDirectionLeft,
    EOAMapPanDirectionRight
};

static const CGFloat kDistanceBetweenFingers = 50.0;
static const NSInteger kReplaceLocalNamesMaxZoom = 6;

@interface OATouchLocation : NSObject

@property (nonatomic) Point31 touchLocation31;
@property (nonatomic) float touchLocationHeight;

@end

@implementation OATouchLocation
@end

@interface OAMapViewController () <OAMapRendererDelegate, OARouteInformationListener>

@property (atomic) BOOL mapViewLoaded;

@end

@implementation OAMapViewController
{
    // -------------------------------------------------------------------------------------------

    OAAutoObserverProxy* _updateGpxTracksObserver;
    OAAutoObserverProxy* _updateRecTrackObserver;

    OAAutoObserverProxy* _trackRecordingObserver;
    
    NSString *_gpxDocFileTemp;

    // Temp gpx
   // QList< std::shared_ptr<const OsmAnd::GpxDocument> > _gpxDocsTemp;
    // Currently recording gpx
   // QList< std::shared_ptr<const OsmAnd::GpxDocument> > _gpxDocsRec;
     NSMutableArray *_gpxDocsTemp;
     NSMutableArray *_gpxDocsRec;

    OASelectedGPXHelper *_selectedGpxHelper;
    
    BOOL _tempTrackShowing;
    BOOL _recTrackShowing;

    // -------------------------------------------------------------------------------------------
    
    OsmAndAppInstance _app;
    
    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    CGFloat _contentScaleFactor;
    
    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _obfMapRasterLayerProvider;
    std::shared_ptr<OsmAnd::IWebClient> _webClient;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _obfMapSymbolsProvider;
    std::shared_ptr<OsmAnd::IGeoTiffCollection> _geoTiffCollection;

    std::shared_ptr<OsmAnd::ObfDataInterface> _obfsDataInterface;

    OACurrentPositionHelper *_currentPositionHelper;

    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _mapSettingsChangeObserver;
    OAAutoObserverProxy* _mapLayerChangeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _applicationModeChangedObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _stateObserver;
    OAAutoObserverProxy* _settingsObserver;
    OAAutoObserverProxy* _framePreparedObserver;

    OAAutoObserverProxy* _layersConfigurationObserver;
    
    UIPinchGestureRecognizer* _grZoom;
    CGFloat _initialZoomLevelDuringGesture;
    CGFloat _initialZoomTapPointY;

    UIPanGestureRecognizer* _grMove;
    UIPanGestureRecognizer* _grZoomDoubleTap;
    
    UIRotationGestureRecognizer* _grRotate;

    UITapGestureRecognizer* _grZoomIn;
    UITapGestureRecognizer* _grZoomOut;
    UIPanGestureRecognizer* _grElevation;
    UITapGestureRecognizer* _grSymbolContextMenu;
    UILongPressGestureRecognizer* _grPointContextMenu;
    BOOL _startRotating;
    BOOL _startZooming;
    float _startAzimuth;
    float _startZoom;

    BOOL _targetChanged;
    OsmAnd::PointI _targetPixel;
    OsmAnd::PointI _carPlayScreenPoint;
    NSMutableArray<OATouchLocation *> *_moveTouchLocations;
    NSMutableArray<OATouchLocation *> *_zoomTouchLocations;
    NSMutableArray<OATouchLocation *> *_rotateTouchLocations;
    OATouchLocation *_carPlayMapTouchLocation;

    CLLocationCoordinate2D _centerLocationForMapArrows;
    OsmAnd::PointI _cachedTarget31;
    OsmAnd::PointI _cachedFixedPixel;
    CLLocation *_cachedMapLocation;

    MBProgressHUD *_progressHUD;
    BOOL _rotationAnd3DViewDisabled;
    // Stores the tilt angle of the map that the user made with a UIPanGestureRecognizer gesture (moving 2 fingers)
    float _map3DModeElevationAngle;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
    self.mapViewLoaded = NO;
    
    _app = [OsmAndApp instance];
    _selectedGpxHelper = [OASelectedGPXHelper instance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
    
    _webClient = std::make_shared<OAWebClient>();

    _rendererSync = [[NSObject alloc] init];

    _moveTouchLocations = [NSMutableArray array];
    _zoomTouchLocations = [NSMutableArray array];
    _rotateTouchLocations = [NSMutableArray array];
    
    _gpxDocsRec = [NSMutableArray array];
    _gpxDocsTemp = [NSMutableArray array];

    _mapLayerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onMapLayerChanged)
                                                              andObserve:_app.data.mapLayerChangeObservable];

    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];
    
    /*
        _app.resourcesManager->localResourcesChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
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

    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onTrackRecordingChanged:withKey:)
                                                         andObserve:_app.trackRecordingObservable];

    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _azimuthObservable = [[OAObservable alloc] init];
    _zoomObservable = [[OAObservable alloc] init];
    _elevationAngleObservable = [[OAObservable alloc] init];
    _mapObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];
    _mapSourceUpdatedObservable = [[OAObservable alloc] init];
    
    _stateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                               withHandler:@selector(onMapRendererStateChanged:withKey:)];
    _settingsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onMapRendererSettingsChanged:withKey:)];
    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged:withKey:andValue:)
                                                              andObserve:_app.data.mapLayersConfigurationChangeObservable];
    
    
    _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onMapRendererFramePrepared)];
    
    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:[OsmAndApp instance].applicationModeChangedObservable];

    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:_zoomObservable];

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
                                                        action:@selector(zoomAndRotateGestureDetected:)];
    _grZoom.delegate = self;

    // - Move gesture
    _grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(moveGestureDetected:)];
    _grMove.delegate = self;
    _grMove.minimumNumberOfTouches = 1;
    _grMove.maximumNumberOfTouches = 2;

    // - Zoom double tap gesture
    _grZoomDoubleTap = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(zoomAndRotateGestureDetected:)];
    _grZoomDoubleTap.delegate = self;
    _grZoomDoubleTap.minimumNumberOfTouches = 1;
    _grZoomDoubleTap.maximumNumberOfTouches = 1;
    
    // - Rotation gesture
    _grRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                             action:@selector(zoomAndRotateGestureDetected:)];
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

    // prevents single tap to fire together with double tap
    [_grSymbolContextMenu requireGestureRecognizerToFail:_grZoomIn];
    [_grSymbolContextMenu requireGestureRecognizerToFail:_grZoomDoubleTap];

    [self createGeoTiffCollection];

    _mapLayers = [[OAMapLayers alloc] initWithMapViewController:self];
    
    OARoutingHelper *helper = [OARoutingHelper sharedInstance];
    [helper addListener:self];
}

- (void) deinit
{
    _app.resourcesManager->localResourcesChangeObservable.detach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self));

    [_mapLayers destroyLayers];
    
    // Unsubscribe from application notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadView
{
    OALog(@"Creating Map Renderer view...");

    // Inflate map renderer view
    _mapView = [[OAMapRendererView alloc] init];
    self.view = _mapView;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _contentScaleFactor = [[UIScreen mainScreen] scale];
    _mapView.contentScaleFactor = _contentScaleFactor;
    [_stateObserver observe:_mapView.stateObservable];
    [_settingsObserver observe:_mapView.settingsObservable];
    [_framePreparedObserver observe:_mapView.framePreparedObservable];
    _mapView.rendererDelegate = self;
    
    self.mapViewLoaded = YES;
    
    // Create map layers
    [_mapLayers createLayers];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if (_mapLayers)
        [_mapLayers didReceiveMemoryWarning];
}

- (BOOL) isDisplayedInCarPlay
{
    return self.parentViewController != OARootViewController.instance.mapPanel;
}

#pragma mark - OAMapRendererDelegate

- (void) frameAnimatorsUpdated
{
    if (_mapLayers)
        [_mapLayers onMapFrameAnimatorsUpdated];

    [[OARootViewController instance].mapPanel.hudViewController.mapInfoController onFrameAnimatorsUpdated];
}

- (void) frameUpdated
{
}

- (void) frameRendered
{
    if (_mapLayers)
        [_mapLayers onMapFrameRendered];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    _mapView.displayDensityFactor = self.displayDensityFactor;
    [_mapView createContext];
    
    // Adjust map-view target, zoom, azimuth and elevation angle to match last viewed
    if (_app.initialURLMapState)
    {
        _mapView.target31 = OsmAnd::PointI(_app.initialURLMapState.target31.x,
                                           _app.initialURLMapState.target31.y);
        float zoom = _app.initialURLMapState.zoom;
        _mapView.zoom = qBound(_mapView.minZoom, isnan(zoom) ? 5 : zoom, _mapView.maxZoom);
        float azimuth = _app.initialURLMapState.azimuth;
        _mapView.azimuth = isnan(azimuth) ? 0 : azimuth;
    }
    else
    {
        _mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                           _app.data.mapLastViewedState.target31.y);

        float zoom = MAX([OAZoom getMinValidZoom], _app.data.mapLastViewedState.zoom);
        _mapView.zoom = qBound(_mapView.minZoom, isnan(zoom) ? 5 : zoom, _mapView.maxZoom);
        float azimuth = _app.data.mapLastViewedState.azimuth;
        _mapView.azimuth = isnan(azimuth) ? 0 : azimuth;
        float elevationAngle = _app.data.mapLastViewedState.elevationAngle;
        _mapView.elevationAngle = isnan(elevationAngle) ? kDefaultElevationAngle : elevationAngle;
        _map3DModeElevationAngle = kDefaultElevationAngle;
    }
    
    // Mark that map source is no longer valid
    _mapSourceInvalidated = YES;
    
    [[OAMapViewTrackingUtilities instance] setMapViewController:self];
    [[OAMapViewTrackingUtilities instance] updateSettings];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    
    [self showWhatsNewDialogIfNeeded];
}

- (void) showWhatsNewDialogIfNeeded
{
    if ([OAAppSettings sharedManager].shouldShowWhatsNewScreen && !_isCarPlayActive && !_isCarPlayDashboardActive)
    {
        OAWhatsNewBottomSheetViewController *bottomSheet = [[OAWhatsNewBottomSheetViewController alloc] init];
        [bottomSheet presentInViewController:self];
        [OAAppSettings sharedManager].shouldShowWhatsNewScreen = NO;
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.mapViewLoaded && !_app.carPlayActive)
    {
        // Suspend rendering
        [_mapView suspendRendering];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([OASubscriptionCancelViewController shouldShowDialog])
        [OASubscriptionCancelViewController showInstance:self.navigationController];
    
    if (_app.initialURLMapState)
    {
        OsmAnd::PointI centerPoint(_app.initialURLMapState.target31.x,
                                   _app.initialURLMapState.target31.y);
        OARootViewController *rootViewController = [OARootViewController instance];
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(centerPoint);
        OATargetPoint *targetPoint = [self.mapLayers.contextMenuLayer getUnknownTargetPoint:latLon.latitude longitude:latLon.longitude];
        targetPoint.centerMap = YES;
        [rootViewController.mapPanel showContextMenu:targetPoint];
    }
    
    _mapView.userInteractionEnabled = YES;
    _mapView.multipleTouchEnabled = YES;
    
    // Attach gesture recognizers:
    [_mapView addGestureRecognizer:_grZoom];
    [_mapView addGestureRecognizer:_grMove];
    [_mapView addGestureRecognizer:_grRotate];
    [_mapView addGestureRecognizer:_grZoomIn];
    [_mapView addGestureRecognizer:_grZoomOut];
    [_mapView addGestureRecognizer:_grZoomDoubleTap];
    [_mapView addGestureRecognizer:_grElevation];
    [_mapView addGestureRecognizer:_grSymbolContextMenu];
    [_mapView addGestureRecognizer:_grPointContextMenu];
}

- (void) applicationDidEnterBackground:(UIApplication*)application
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastMapUsedTime];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (self.mapViewLoaded && !_app.carPlayActive)
    {
        // Suspend rendering
        [_mapView suspendRendering];
    }
}

- (void) applicationWillEnterForeground:(UIApplication*)application
{
    if (self.mapViewLoaded && !_app.carPlayActive)
    {
        // Resume rendering
        [_mapView resumeRendering];
    }
}

- (void) applicationDidBecomeActive:(UIApplication*)application
{
    NSDate *lastMapUsedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastMapUsedTime];
    if (lastMapUsedDate)
        if ([[NSDate date] timeIntervalSinceDate:lastMapUsedDate] > kInactiveHoursResetLocation * 60.0 * 60.0) {
            if (_app.mapMode == OAMapModeFree)
                _app.mapMode = OAMapModePositionTrack;
        }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastMapUsedTime];
}

- (void) onApplicationDestroyed
{
    if (self.mapViewLoaded)
    {
        [_mapView suspendSymbolsUpdate];
        [_mapView releaseContext:YES];
        [_mapView removeFromSuperview];
        _mapView = nil;
    }
}

- (void) showProgressHUD
{
    if (_app.carPlayActive)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL wasVisible = NO;
        if (_progressHUD)
        {
            wasVisible = YES;
            [_progressHUD hide:NO];
        }
        UIView *topView = [UIApplication sharedApplication].mainWindow;
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = .5f;
        _progressHUD.removeFromSuperViewOnHide = YES;
        [topView addSubview:_progressHUD];
        
        [_progressHUD show:!wasVisible];
    });
}

- (void) showProgressHUDWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL wasVisible = NO;
        if (_progressHUD)
        {
            wasVisible = YES;
            [_progressHUD hide:NO];
        }
        UIView *topView = [UIApplication sharedApplication].mainWindow;
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = 1.0f;
        _progressHUD.labelText = message;
        _progressHUD.removeFromSuperViewOnHide = YES;
        [topView addSubview:_progressHUD];
        
        [_progressHUD show:!wasVisible];
    });
}

- (void) hideProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressHUD)
        {
            [_progressHUD hide:YES];
            _progressHUD = nil;
        }
    });
}

- (CLLocation *) getMapLocation
{
    OsmAnd::PointI target31 = _mapView.target31;
    OsmAnd::PointI fixedPixel = _mapView.fixedPixel;

	if (target31 == _cachedTarget31 && fixedPixel == _cachedFixedPixel && _cachedMapLocation)
    {
        return _cachedMapLocation;
    }
    else
    {
        _cachedTarget31 = target31;
        _cachedFixedPixel = fixedPixel;

        auto centerPixel = _mapView.getCenterPixel;
        OsmAnd::PointI elevated31 = [OANativeUtilities get31FromElevatedPixel:centerPixel];
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(elevated31);
        CLLocation *mapLocation = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
        _cachedMapLocation = mapLocation;
        return mapLocation;
    }
}

- (float) getMapZoom
{
    return _mapView.zoom;
}

- (float)getMap3DModeElevationAngle
{
    return _map3DModeElevationAngle;
}

- (void)setViewportScaleX:(double)x y:(double)y
{
    [self setViewportScaleX:x];
    [self setViewportScaleY:y];
}

- (void)setViewportScaleX:(double)x
{
    if (_mapView.viewportXScale != x && !_isCarPlayActive && !_isCarPlayDashboardActive)
        _mapView.viewportXScale = x;
}

- (void)setViewportScaleY:(double)y
{
    if (_mapView.viewportYScale != y && !_isCarPlayActive && !_isCarPlayDashboardActive)
        _mapView.viewportYScale = y;
}

- (void)setViewportForCarPlayScaleX:(double)x y:(double)y
{
    [self setViewportForCarPlayScaleX:x];
    [self setViewportForCarPlayScaleY:y];
}

- (void)setViewportForCarPlayScaleX:(double)x
{
    if (_mapView.viewportXScale != x && (_isCarPlayActive || _isCarPlayDashboardActive))
        _mapView.viewportXScale = x;
}

- (void)setViewportForCarPlayScaleY:(double)y
{
    if (_mapView.viewportYScale != y && (_isCarPlayActive || _isCarPlayDashboardActive))
        _mapView.viewportYScale = y;
}

- (void) setMapPosition:(int)mapPosition
{
    _mapPosition = mapPosition;
    [self setViewportScaleY:mapPosition == BOTTOM_CONSTANT ? kViewportBottomScale : kViewportScale];
}

- (void) setupMapArrowsLocation
{
    [self setupMapArrowsLocation:_centerLocationForMapArrows];
}

- (void) setupMapArrowsLocation:(CLLocationCoordinate2D)centerLocation
{
    OAAppSettings * settings = [OAAppSettings sharedManager];
    if (settings.settingMapArrows != MAP_ARROWS_MAP_CENTER)
    {
        settings.mapCenter = centerLocation;
        [settings setSettingMapArrows:MAP_ARROWS_MAP_CENTER];
        [_mapObservable notifyEventWithKey:nil];
    }
}

- (void) restoreMapArrowsLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupMapArrowsLocation) object:nil];
    
    [[OAAppSettings sharedManager] setSettingMapArrows:MAP_ARROWS_LOCATION];
    [_mapObservable notifyEventWithKey:nil];
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.mapViewLoaded)
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
    // If user gesture should begin, stop all animations
    _mapView.mapAnimator->pause();
    _mapView.mapAnimator->cancelAllAnimations();

    if (gestureRecognizer != _grPointContextMenu)
    {
        [self postMapGestureAction];
    }
    
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == _grZoomDoubleTap)
        return touch.tapCount == 2;
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Elevation gesture recognizer should not be mixed with others
    if (gestureRecognizer == _grElevation &&
        (otherGestureRecognizer == _grMove || otherGestureRecognizer == _grRotate || otherGestureRecognizer == _grZoom || otherGestureRecognizer == _grZoomDoubleTap))
        return NO;
    if (gestureRecognizer == _grMove && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grRotate && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grZoom && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grZoomDoubleTap && otherGestureRecognizer == _grElevation)
        return NO;
    if (gestureRecognizer == _grZoom && otherGestureRecognizer == _grZoomDoubleTap)
        return NO;
    if (gestureRecognizer == _grZoomDoubleTap && otherGestureRecognizer == _grZoom)
        return NO;
    
    if (gestureRecognizer == _grPointContextMenu && otherGestureRecognizer == _grSymbolContextMenu)
        return NO;
    if (gestureRecognizer == _grSymbolContextMenu && otherGestureRecognizer == _grPointContextMenu)
        return NO;
    if (gestureRecognizer == _grSymbolContextMenu && otherGestureRecognizer == _grZoomIn)
        return NO;
    if (gestureRecognizer == _grZoomIn && otherGestureRecognizer == _grSymbolContextMenu)
        return NO;
    
    if (gestureRecognizer == _grPointContextMenu && otherGestureRecognizer == _grZoomDoubleTap)
        return NO;
    if (gestureRecognizer == _grSymbolContextMenu && otherGestureRecognizer == _grZoomDoubleTap)
        return NO;
    if (gestureRecognizer == _grMove && otherGestureRecognizer == _grZoomDoubleTap)
        return NO;
    if (gestureRecognizer == _grZoomDoubleTap && otherGestureRecognizer == _grMove)
        return NO;
    
    return YES;
}

- (OATouchLocation *) acquireMapTouchLocation:(CGPoint)touchPoint
{
    OATouchLocation *loc = [[OATouchLocation alloc] init];
    OsmAnd::PointI touchLocation31 = _mapView.getTarget;
    float height = [_mapView getHeightAndLocationFromElevatedPoint:OsmAnd::PointI((int)touchPoint.x, (int)touchPoint.y) location31:&touchLocation31];
    loc.touchLocation31 = [OANativeUtilities convertFromPointI:touchLocation31];
    loc.touchLocationHeight = height > kMinAltitudeValue ? height : 0.0f;
    return loc;
}

- (CGPoint)getTouchPoint:(UIGestureRecognizer *)recognizer touchIndex:(NSUInteger)touchIndex
{
    if ([OAUtilities isiOSAppOnMac])
    {
        if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]])
        {
            UIPinchGestureRecognizer *pinchRecognizer = (UIPinchGestureRecognizer *)recognizer;
            CGPoint cursorCenter = [pinchRecognizer locationInView:pinchRecognizer.view];
            CGFloat adjustedDistance = kDistanceBetweenFingers * pinchRecognizer.scale;
            
            if (touchIndex == 0)
            {
                return [self pointWithMapContentScaleFactor:CGPointMake(cursorCenter.x + adjustedDistance, cursorCenter.y)];
            }
            else if (touchIndex == 1)
            {
                return [self pointWithMapContentScaleFactor:CGPointMake(cursorCenter.x - adjustedDistance, cursorCenter.y)];
            }
        }
        else if ([recognizer isKindOfClass:[UIRotationGestureRecognizer class]])
        {
            UIRotationGestureRecognizer *rotationRecognizer = (UIRotationGestureRecognizer *)recognizer;
            CGPoint cursorCenter = [rotationRecognizer locationInView:rotationRecognizer.view];
            CGFloat rotation = [rotationRecognizer rotation];
            
            if (touchIndex == 0)
            {
                CGFloat simulateFingerPointX = cursorCenter.x + kDistanceBetweenFingers * cos(rotation);
                CGFloat simulateFingerPointY = cursorCenter.y + kDistanceBetweenFingers * sin(rotation);
                
                return [self pointWithMapContentScaleFactor:CGPointMake(simulateFingerPointX, simulateFingerPointY)];
            }
            else if (touchIndex == 1)
            {
                CGFloat simulateFingerPointX = cursorCenter.x + kDistanceBetweenFingers * (-1 * cos(rotation));
                CGFloat simulateFingerPointY = cursorCenter.y + kDistanceBetweenFingers * (-1 * sin(rotation));
                
                return [self pointWithMapContentScaleFactor:CGPointMake(simulateFingerPointX, simulateFingerPointY)];
            }
        }
        else
        {
            if (touchIndex >= 0 && touchIndex < recognizer.numberOfTouches)
            {
                return [self pointWithMapContentScaleFactor:[recognizer locationOfTouch:touchIndex inView:self.view]];
            }
        }
    }
    else
    {
        if (touchIndex >= 0 && touchIndex < recognizer.numberOfTouches)
        {
            return [self pointWithMapContentScaleFactor:[recognizer locationOfTouch:touchIndex inView:self.view]];
        }
    }
    return CGPointZero;
}

- (CGPoint)pointWithMapContentScaleFactor:(CGPoint)point
{
    point.x *= _mapView.contentScaleFactor;
    point.y *= _mapView.contentScaleFactor;
    return point;
}

- (BOOL) isTargetChanged
{
    return _targetChanged;
}

- (BOOL) isLastMultiGesture
{
    return (_movingByGesture && !_zoomingByGesture && !_rotatingByGesture)
    	|| (!_movingByGesture && _zoomingByGesture && !_rotatingByGesture)
    	|| (!_movingByGesture && !_zoomingByGesture && _rotatingByGesture);
}

- (void) storeTargetPosition:(UIGestureRecognizer *)recognizer
{
    if (![self isTargetChanged])
    {
        _targetChanged = YES;

        // Remember last target position before it is changed with map gesture
        _targetPixel = _mapView.getTargetScreenPosition;
    }
    if (recognizer)
    	[self reacquireMapTouchLocations:recognizer];
}

- (void) restorePreviousTarget
{
    if ([self isTargetChanged] && [self isLastMultiGesture])
    {
        _targetChanged = NO;

        // Restore previous target screen position after map gesture
        [_mapView resetMapTargetPixelCoordinates:_targetPixel];
    }
}

- (void) reacquireMapTouchLocations:(UIGestureRecognizer *)recognizer
{
    if (recognizer == _grMove)
        [_moveTouchLocations removeAllObjects];
    else if (recognizer == _grZoom)
        [_zoomTouchLocations removeAllObjects];
    else if (recognizer == _grRotate)
        [_rotateTouchLocations removeAllObjects];

    CGPoint firstPoint = [self getTouchPoint:recognizer touchIndex:0];
    if (!CGPointEqualToPoint(firstPoint, CGPointZero))
    {
        OATouchLocation *firstTouch = [self acquireMapTouchLocation:firstPoint];
        if (recognizer == _grMove)
        	[_moveTouchLocations addObject:firstTouch];
        else if (recognizer == _grZoom)
            [_zoomTouchLocations addObject:firstTouch];
        else if (recognizer == _grRotate)
            [_rotateTouchLocations addObject:firstTouch];
    }
    CGPoint secondPoint = [self getTouchPoint:recognizer touchIndex:1];
    if (!CGPointEqualToPoint(secondPoint, CGPointZero))
    {
        OATouchLocation *secondTouch = [self acquireMapTouchLocation:secondPoint];
        if (recognizer == _grMove)
            [_moveTouchLocations addObject:secondTouch];
        else if (recognizer == _grZoom)
            [_zoomTouchLocations addObject:secondTouch];
        else if (recognizer == _grRotate)
            [_rotateTouchLocations addObject:secondTouch];
    }
}

- (void) moveGestureDetected:(UIPanGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;
    
    self.sidePanelController.recognizesPanGesture = NO;

    if (recognizer.state == UIGestureRecognizerStateBegan && recognizer.numberOfTouches > 0)
    {
        [self storeTargetPosition:recognizer];

        if (_moveTouchLocations.count > 0)
        {
            OATouchLocation *firstTouch = _moveTouchLocations[0];
            double lon = OsmAnd::Utilities::get31LongitudeX(firstTouch.touchLocation31.x);
            double lat = OsmAnd::Utilities::get31LatitudeY(firstTouch.touchLocation31.y);
            _centerLocationForMapArrows = CLLocationCoordinate2DMake(lat, lon);
            [self performSelector:@selector(setupMapArrowsLocation) withObject:nil afterDelay:1.0];
        }

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

        return;
    }

    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (_moveTouchLocations.count != recognizer.numberOfTouches)
            [self reacquireMapTouchLocations:recognizer];

        CGPoint firstPoint = [self getTouchPoint:recognizer touchIndex:0];
        if (!CGPointEqualToPoint(firstPoint, CGPointZero) && _moveTouchLocations.count > 0 && !_rotatingByGesture && !_zoomingByGesture)
        {
            _app.mapMode = OAMapModeFree;
            OATouchLocation *firstTouch = _moveTouchLocations[0];
            OsmAnd::PointI touchLocation31 = [OANativeUtilities convertFromPoint31:firstTouch.touchLocation31];
            [_mapView setMapTarget:OsmAnd::PointI((int)firstPoint.x, (int)firstPoint.y) location31:touchLocation31];
        }
    }

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restorePreviousTarget];
        [self restoreMapArrowsLocation];

        [_moveTouchLocations removeAllObjects];
        _movingByGesture = NO;

        // Resume symbols update
        if (!_rotatingByGesture && !_zoomingByGesture && !_zoomingByTapGesture && !_movingByGesture)
            while (![_mapView resumeSymbolsUpdate]);
    }
    else
    {
        _movingByGesture = YES;
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
        const float angle = qDegreesToRadians(_mapView.azimuth);
        const float cosAngle = cosf(angle);
        const float sinAngle = sinf(angle);

        // Taking into account current zoom, get how many 31-coordinates there are in 1 point
        const uint32_t tileSize31 = (1u << (31 - _mapView.zoomLevel));
        const double scale31 = static_cast<double>(tileSize31) / _mapView.tileSizeOnScreenInPixels;

        CGPoint velocityInMapSpace;
        velocityInMapSpace.x = screenVelocity.x * cosAngle - screenVelocity.y * sinAngle;
        velocityInMapSpace.y = screenVelocity.x * sinAngle + screenVelocity.y * cosAngle;
        
        // Rescale speed to 31 coordinates
        OsmAnd::PointD velocity;
        velocity.x = -velocityInMapSpace.x * scale31;
        velocity.y = -velocityInMapSpace.y * scale31;

#if !TARGET_OS_SIMULATOR
        _mapView.mapAnimator->animateFlatTargetWith(velocity, OsmAnd::PointD(kTargetMoveDeceleration * scale31, kTargetMoveDeceleration * scale31), kUserInteractionAnimationKey);
        _mapView.mapAnimator->resume();
#endif
    }
}

- (void) carPlayMoveGestureDetected:(UIGestureRecognizerState)state
                    numberOfTouches:(NSInteger)numberOfTouches
                        translation:(CGPoint)translation
                           velocity:(CGPoint)screenVelocity
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;

    if (state == UIGestureRecognizerStateBegan && numberOfTouches > 0)
    {
        [self storeTargetPosition:nil];

        CGPoint touchPoint = CGPointMake(_targetPixel.x, _targetPixel.y);
        _carPlayScreenPoint = _targetPixel;
        _carPlayMapTouchLocation = [self acquireMapTouchLocation:touchPoint];

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

        return;
    }

    if (state == UIGestureRecognizerStateChanged && _carPlayMapTouchLocation)
    {
        _carPlayScreenPoint = OsmAnd::PointI(_carPlayScreenPoint.x + translation.x * _mapView.contentScaleFactor, _carPlayScreenPoint.y + translation.y * _mapView.contentScaleFactor);
        auto touchLocation31 = [OANativeUtilities convertFromPoint31:_carPlayMapTouchLocation.touchLocation31];
        [_mapView setMapTarget:_carPlayScreenPoint location31:touchLocation31];
    }

    if (state == UIGestureRecognizerStateEnded ||
        state == UIGestureRecognizerStateCancelled)
    {
        [self restorePreviousTarget];
        [self restoreMapArrowsLocation];
        _carPlayMapTouchLocation = nil;

        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
        _movingByGesture = NO;
    }
    else
    {
        _movingByGesture = YES;
    }

    if (state == UIGestureRecognizerStateEnded)
    {
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
        const float angle = qDegreesToRadians(_mapView.azimuth);
        const float cosAngle = cosf(angle);
        const float sinAngle = sinf(angle);
        // Taking into account current zoom, get how many 31-coordinates there are in 1 point
        const uint32_t tileSize31 = (1u << (31 - _mapView.zoomLevel));
        const double scale31 = static_cast<double>(tileSize31) / _mapView.tileSizeOnScreenInPixels;

        // Take into account current azimuth and reproject to map space (points)
        CGPoint velocityInMapSpace;
        velocityInMapSpace.x = screenVelocity.x * cosAngle - screenVelocity.y * sinAngle;
        velocityInMapSpace.y = screenVelocity.x * sinAngle + screenVelocity.y * cosAngle;
        
        // Rescale speed to 31 coordinates
        OsmAnd::PointD velocity;
        velocity.x = -velocityInMapSpace.x * scale31;
        velocity.y = -velocityInMapSpace.y * scale31;
        
        _mapView.mapAnimator->animateFlatTargetWith(velocity, OsmAnd::PointD(kTargetMoveDeceleration * scale31, kTargetMoveDeceleration * scale31), kUserInteractionAnimationKey);
        _mapView.mapAnimator->resume();
    }
}

- (void) zoomAndRotateGestureDetected:(UIGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;

    UIPinchGestureRecognizer *pinchRecognizer = [recognizer isKindOfClass:UIPinchGestureRecognizer.class] ? (UIPinchGestureRecognizer *) recognizer : nil;
    UIRotationGestureRecognizer *rotationRecognizer = [recognizer isKindOfClass:UIRotationGestureRecognizer.class] ? (UIRotationGestureRecognizer *) recognizer : nil;
    UIPanGestureRecognizer *panRecognizer = [recognizer isKindOfClass:UIPanGestureRecognizer.class] ? (UIPanGestureRecognizer *) recognizer : nil;

    if (_rotationAnd3DViewDisabled && rotationRecognizer)
        return;

    if (rotationRecognizer && [[OAAppSettings sharedManager].rotateMap get] == ROTATE_MAP_NONE)
        return;

    // If gesture has just began, just capture current zoom
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self storeTargetPosition:recognizer];

        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

        _startZoom = _mapView.zoom;
        _startAzimuth = _mapView.azimuth;

        if (panRecognizer)
        {
            _initialZoomLevelDuringGesture = _mapView.zoom;
            _initialZoomTapPointY = [panRecognizer locationInView:recognizer.view].y;

            CGPoint touchPoint = [self getTouchPoint:recognizer touchIndex:0];
            OATouchLocation *touchLocation = [self acquireMapTouchLocation:touchPoint];
            OsmAnd::PointI touchLocation31 = [OANativeUtilities convertFromPoint31:touchLocation.touchLocation31];
            [_mapView setMapTarget:OsmAnd::PointI((int)touchPoint.x, (int)touchPoint.y) location31:touchLocation31];
        }

        return;
    }

    // If gesture has been cancelled or failed, restore previous zoom
    if (recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restorePreviousTarget];
        [self restoreMapArrowsLocation];

        if (rotationRecognizer)
        {
            [_rotateTouchLocations removeAllObjects];
            _rotatingByGesture = NO;
        }
        else if (pinchRecognizer)
        {
            [_zoomTouchLocations removeAllObjects];
            _zoomingByGesture = NO;
        }
        else if (panRecognizer)
        {
            _zoomingByTapGesture = NO;
        }

        _startZooming = NO;
        _startRotating = NO;

        // Resume symbols update
        if (!_rotatingByGesture && !_zoomingByGesture && !_zoomingByTapGesture && !_movingByGesture)
            while (![_mapView resumeSymbolsUpdate]);

        return;
    }

    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (pinchRecognizer || rotationRecognizer)
        {
            NSArray<OATouchLocation *> *touchLocations = [NSArray arrayWithArray:pinchRecognizer ? _zoomTouchLocations : _rotateTouchLocations];
            if (touchLocations.count != recognizer.numberOfTouches && ![OAUtilities isiOSAppOnMac])
            {
                [self reacquireMapTouchLocations:recognizer];
                touchLocations = [NSArray arrayWithArray:pinchRecognizer ? _zoomTouchLocations : _rotateTouchLocations];
            }
            CGPoint firstTouchPoint = [self getTouchPoint:recognizer touchIndex:0];
            CGPoint secondTouchPoint = [self getTouchPoint:recognizer touchIndex:1];
            if (!CGPointEqualToPoint(firstTouchPoint, CGPointZero) && CGPointEqualToPoint(secondTouchPoint, CGPointZero) && touchLocations.count > 0)
            {
                OsmAnd::PointI firstTouchLocation31 = [OANativeUtilities convertFromPoint31:touchLocations[0].touchLocation31];
                [_mapView setMapTarget:OsmAnd::PointI((int)firstTouchPoint.x, (int)firstTouchPoint.y) location31:firstTouchLocation31];
            }
            if (!CGPointEqualToPoint(firstTouchPoint, CGPointZero) && !CGPointEqualToPoint(secondTouchPoint, CGPointZero) && touchLocations.count >= 2)
            {
                OsmAnd::PointI firstTouchLocation31 = [OANativeUtilities convertFromPoint31:touchLocations[0].touchLocation31];
                float firstTouchLocationHeight = touchLocations[0].touchLocationHeight;
                OsmAnd::PointI secondTouchLocation31 = [OANativeUtilities convertFromPoint31:touchLocations[1].touchLocation31];
                float secondTouchLocationHeight = touchLocations[1].touchLocationHeight;

                [_mapView setMapTarget:OsmAnd::PointI((int)firstTouchPoint.x, (int)firstTouchPoint.y) location31:firstTouchLocation31];

                OsmAnd::PointI firstPosition((int)firstTouchPoint.x, (int)firstTouchPoint.y);
                OsmAnd::PointI secondPosition((int)secondTouchPoint.x, (int)secondTouchPoint.y);
                OsmAnd::PointD zoomAndRotation;
                if ([_mapView getZoomAndRotationAfterPinch:firstTouchLocation31 firstHeight:firstTouchLocationHeight firstPoint:firstPosition secondLocation31:secondTouchLocation31 secondHeight:secondTouchLocationHeight secondPoint:secondPosition zoomAndRotate:&zoomAndRotation])
                {
                    auto zoom = zoomAndRotation.x;
                    auto angle = zoomAndRotation.y;
                    if (!isnan(zoom) && !isnan(angle))
                    {
                        float newZoom = _mapView.zoom + (float)zoom;
                        float newAzimuth = _mapView.azimuth + (float)angle;
                        if (pinchRecognizer)
                        {
                            if (ABS(_startZoom - newZoom) <= ZONE_0_ZOOM_THRESHOLD && !_startZooming)
                                zoom = 0; // keep only rotating
                            else
                                _startZooming = YES;

                            if (_startZooming && zoom != 0)
                                _mapView.flatZoom = qBound(_mapView.minZoom, _mapView.flatZoom + (float)zoom, _mapView.maxZoom);
                            
                            [OAMapViewTrackingUtilities.instance setZoomTime:[[NSDate now] timeIntervalSince1970]];
                        }
                        else
                        {
                            if ([self isAngleOverThreshold:ABS(_startAzimuth - newAzimuth) deltaZoom:ABS(_startZoom - newZoom)])
                                _startRotating = YES;
                            else
                                angle = 0;

                            if (_startRotating && angle != 0)
                            {
                                _mapView.azimuth += angle;
                                if ([[OAAppSettings sharedManager].rotateMap get] == ROTATE_MAP_MANUAL)
                                    [[OAAppSettings sharedManager].mapManuallyRotatingAngle set:_mapView.azimuth];
                            }
                        }
                    }
                }
            }
        }
        else if (panRecognizer)
        {
            // Change zoom
            CGFloat gestureScale = ([panRecognizer locationInView:recognizer.view].y * _mapView.contentScaleFactor) / (_initialZoomTapPointY * _mapView.contentScaleFactor);
            CGFloat scale = 1 - gestureScale;
            if (gestureScale < 1 || scale < 0)
                scale = -scale * (kGestureZoomCoef / _mapView.contentScaleFactor);

            _mapView.zoom = qBound(_mapView.minZoom, (float)(_initialZoomLevelDuringGesture - scale), _mapView.maxZoom);
        }
    }

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restorePreviousTarget];
        [self restoreMapArrowsLocation];

        if (rotationRecognizer)
        {
            [_rotateTouchLocations removeAllObjects];
            _rotatingByGesture = NO;
        }
        else if (pinchRecognizer)
        {
            [_zoomTouchLocations removeAllObjects];
            _zoomingByGesture = NO;
        }
        else if (panRecognizer)
        {
            _zoomingByTapGesture = NO;
        }

        _startZooming = NO;
        _startRotating = NO;

        // Resume symbols update
        if (!_rotatingByGesture && !_zoomingByGesture && !_zoomingByTapGesture && !_movingByGesture)
            while (![_mapView resumeSymbolsUpdate]);
    }
    else
    {
        if (rotationRecognizer)
            _rotatingByGesture = YES;
        else if (pinchRecognizer)
            _zoomingByGesture = YES;
        else if (panRecognizer)
            _zoomingByTapGesture = YES;
    }
    // If this is the end of gesture, get velocity for animation
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
//        CGFloat recognizerVelocity = pinchRecognizer ? pinchRecognizer.velocity : 0;
//        float velocity = qBound(-kZoomVelocityAbsLimit, (float)recognizerVelocity, kZoomVelocityAbsLimit);
//        if (velocity != 0)
//            _mapView.mapAnimator->animateZoomWith(velocity,
//                                                  kZoomDeceleration,
//                                                  kUserInteractionAnimationKey);
        _mapView.mapAnimator->resume();
        if (rotationRecognizer)
            [OAMapViewTrackingUtilities.instance setRotationNoneToManual];
    }

    if (rotationRecognizer)
    	_lastRotatingByGestureTime = [NSDate now];
}

- (BOOL) isAngleOverThreshold:(double)angle deltaZoom:(double)deltaZoom
{
    if (_startRotating)
        return YES;
    else if (!_startZooming)
        return ABS(angle) >= ZONE_0_ANGLE_THRESHOLD;
    else if (deltaZoom >= ZONE_2_ZOOM_THRESHOLD)
        return ABS(angle) >= ZONE_3_ANGLE_THRESHOLD;
    else if (deltaZoom >= ZONE_1_ZOOM_THRESHOLD)
        return ABS(angle) >= ZONE_2_ANGLE_THRESHOLD;
    else
        return ABS(angle) >= ZONE_1_ANGLE_THRESHOLD;
}

- (void) zoomInGestureDetected:(UITapGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;
    
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    if (_mapView.zoomLevel >= _mapView.maxZoom)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];

    // Put tap location to center of screen
    CGPoint centerPoint = [self getTouchPoint:recognizer touchIndex:0];
    OsmAnd::PointI centerLocation;
    [_mapView convert:centerPoint toLocation:&centerLocation];

    OsmAnd::PointI destLocation(_mapView.target31.x / 2.0 + centerLocation.x / 2.0, _mapView.target31.y / 2.0 + centerLocation.y / 2.0);
    
    _mapView.mapAnimator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomIn,
                                      kUserInteractionAnimationKey);
    
    // Increate zoom by 1
    zoomDelta += 1.0f;
    _mapView.mapAnimator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    _mapView.mapAnimator->resume();
}

- (void) zoomOutGestureDetected:(UITapGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;
    
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

    if (_mapView.zoomLevel <= _mapView.minZoom)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];

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
    
    _mapView.mapAnimator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomOut,
                                      kUserInteractionAnimationKey);
    
    // Decrease zoom by 1
    zoomDelta -= 1.0f;
    _mapView.mapAnimator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    
    // Launch animation
    _mapView.mapAnimator->resume();
}

- (void) elevationGestureDetected:(UIPanGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view or if 3D view is disabled
    if (!self.mapViewLoaded || _rotationAnd3DViewDisabled)
        return;

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);
    }
    
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat angleDelta = -translation.y / static_cast<CGFloat>(kElevationGesturePointsPerDegree);
    CGFloat angle = _mapView.elevationAngle;
    angle -= angleDelta;
    if (angle < kMinAllowedElevationAngle)
        angle = kMinAllowedElevationAngle;
    _mapView.elevationAngle = angle;
    _map3DModeElevationAngle = angle;
    [recognizer setTranslation:CGPointZero inView:self.view];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
    }
}

- (BOOL) simulateContextMenuPress:(UIGestureRecognizer *)recognizer
{
    return [self pointContextMenuGestureDetected:recognizer];
}

- (BOOL) pointContextMenuGestureDetected:(UIGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
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
    
    BOOL longPress = [recognizer isKindOfClass:[UILongPressGestureRecognizer class]];
    BOOL accepted = longPress && recognizer.state == UIGestureRecognizerStateBegan;
    accepted |= !longPress && recognizer.state == UIGestureRecognizerStateEnded;
    if (accepted)
    {
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OAFloatingButtonsHudViewController *quickAction = mapPanel.hudViewController.floatingButtonsController;
        [quickAction hideActionsSheetAnimated:nil];
        [_mapLayers.contextMenuLayer showContextMenu:touchPoint showUnknownLocation:longPress forceHide:[recognizer isKindOfClass:UITapGestureRecognizer.class] && recognizer.numberOfTouches == 1];
        
        // Handle route planning touch events
        [_mapLayers.routePlanningLayer onMapPointSelected:CLLocationCoordinate2DMake(lat, lon) longPress:longPress];
        return YES;
    }
    return NO;
}

- (id<OAMapRendererViewProtocol>) mapRendererView
{
    if (!self.mapViewLoaded)
        return nil;
    else
        return (OAMapRendererView*)self.view;
}

- (void) postMapGestureAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationMapGestureAction
                                                        object:self
                                                      userInfo:nil];
}

@synthesize stateObservable = _stateObservable;
@synthesize settingsObservable = _settingsObservable;

@synthesize azimuthObservable = _azimuthObservable;
@synthesize mapSourceUpdatedObservable = _mapSourceUpdatedObservable;

- (void) onMapRendererStateChanged:(id)observer withKey:(id)key
{
    if (!self.mapViewLoaded)
            return;

    switch ([key unsignedIntegerValue])
    {
        case OAMapRendererViewStateEntryAzimuth:
            [_azimuthObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:_mapView.azimuth]];
            _app.data.mapLastViewedState.azimuth = _mapView.azimuth;
            break;
        case OAMapRendererViewStateEntryZoom:
        {
            [_zoomObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:_mapView.zoom]];
            _app.data.mapLastViewedState.zoom = _mapView.zoom;
            break;
        }
        case OAMapRendererViewStateEntryElevationAngle:
        {
            _app.data.mapLastViewedState.elevationAngle = _mapView.elevationAngle;
            [_elevationAngleObservable notifyEventWithKey:nil andValue:[NSNumber numberWithFloat:_mapView.elevationAngle]];
            break;
        }
        case OAMapRendererViewStateEntryTarget:
        {
            OsmAnd::PointI newTarget31 = _mapView.target31;
            Point31 newTarget31_converted;
            newTarget31_converted.x = newTarget31.x;
            newTarget31_converted.y = newTarget31.y;
            _app.data.mapLastViewedState.target31 = newTarget31_converted;
            [_mapObservable notifyEventWithKey:nil ];
            break;
        }
        case OAMapRendererViewStateEntryMapLayers_Configuration:
        {
            [self updateSymbolsLayerProviderAlpha];
            [self updateRasterLayerProviderAlpha];
            break;
        }
    }

    [_stateObservable notifyEventWithKey:key];
}

- (void) onMapRendererSettingsChanged:(id)observer withKey:(id)key
{
    [_stateObservable notifyEventWithKey:key];
}

- (void) onMapRendererFramePrepared
{
    [_framePreparedObservable notifyEvent];
}

@synthesize zoomObservable = _zoomObservable;

@synthesize mapObservable = _mapObservable;

@synthesize elevationAngleObservable = _elevationAngleObservable;

- (float) currentZoomInDelta
{
    if (!self.mapViewLoaded)
        return 0.0f;

    const auto currentZoomAnimation = _mapView.mapAnimator->getCurrentAnimation(kUserInteractionAnimationKey,
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

- (BOOL) canZoomIn
{
    if (!self.mapViewLoaded)
        return NO;
    
    return (_mapView.zoom < _mapView.maxZoom);
}

- (void) zoomIn
{
    if (!self.mapViewLoaded)
        return;

    if (_mapView.zoomLevel >= _mapView.maxZoom)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];
    
    while ([_mapView getSymbolsUpdateSuspended] < 0)
        [_mapView suspendSymbolsUpdate];

    // Animate zoom-in by +1
    zoomDelta += 1.0f;
    _mapView.mapAnimator->pause();
    _mapView.mapAnimator->cancelAllAnimations();
    
    _mapView.mapAnimator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);

    _mapView.mapAnimator->resume();

}

- (BOOL) canZoomOut
{
    if (!self.mapViewLoaded)
        return NO;
    
    return (_mapView.zoom > _mapView.minZoom);
}

- (void) zoomOut
{
    if (!self.mapViewLoaded)
        return;

    if (_mapView.zoomLevel <= _mapView.minZoom)
        return;
    
    // Get base zoom delta
    float zoomDelta = [self currentZoomOutDelta];
    
    while ([_mapView getSymbolsUpdateSuspended] < 0)
        [_mapView suspendSymbolsUpdate];

    // Animate zoom-in by -1
    zoomDelta -= 1.0f;
    _mapView.mapAnimator->pause();
    _mapView.mapAnimator->cancelAllAnimations();
    
    _mapView.mapAnimator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    _mapView.mapAnimator->resume();
    
}

- (void) zoomInAndAdjustTiltAngle
{
    [self changeZoomManually:1 adjustTiltAngle:[[OAMapViewTrackingUtilities instance] is3DMode]];
}

- (void) zoomOutAndAdjustTiltAngle
{
    [self changeZoomManually:-1 adjustTiltAngle:[[OAMapViewTrackingUtilities instance] is3DMode]];
}

- (void) changeZoomManually:(int)zoomStep
{
    [self changeZoomManually:NO];
}

- (void) changeZoomManually:(int)zoomStep adjustTiltAngle:(BOOL)adjustTiltAngle
{
    if (!self.mapViewLoaded)
        return;
    
    OAZoom *zoom = [[OAZoom alloc] initWitZoom:_mapView.zoom minZoom:_mapView.minZoom maxZoom:_mapView.maxZoom];
    
    if (zoomStep > 0 && ![zoom isZoomInAllowed])
    {
        [OAUtilities showToast:nil details:OALocalizedString(@"edit_tilesource_maxzoom") duration:4 inView:self.view];
        return;
    }
    else if (zoomStep < 0 && ![zoom isZoomOutAllowed])
    {
        [OAUtilities showToast:nil details:OALocalizedString(@"edit_tilesource_minzoom") duration:4 inView:self.view];
        return;
    }
    
    [zoom changeZoom:zoomStep];
    
    _mapView.mapAnimator->pause();
    _mapView.mapAnimator->cancelAllAnimations();
    
    _mapView.mapAnimator->animateZoomBy(zoomStep,
                                        kQuickAnimationTime,
                                        OsmAnd::MapAnimator::TimingFunction::Linear,
                                        kUserInteractionAnimationKey);
    
    _mapView.mapAnimator->resume();
    
    if (adjustTiltAngle)
    {
        [self adjustTiltAngle:zoom];
    }
}

- (void) adjustTiltAngle:(OAZoom *)zoom
{
    int baseZoom = [zoom getBaseZoom];
    if (baseZoom >= kMinZoomLevelToAjustCameraTilt && baseZoom <= kMaxZoomLimit)
    {
        int angle = 90 - (baseZoom - 2) * 5;
        if (angle >= kMinAllowedElevationAngle && angle < kDefaultElevationAngle)
        {
            [[OAMapViewTrackingUtilities instance] startTilting:angle timePeriod:kQuickAnimationTime];
        }
    }
}

- (void) animatedPanUp
{
    [self animatedMapPan:EOAMapPanDirectionUp];
}

- (void) animatedPanDown
{
    [self animatedMapPan:EOAMapPanDirectionDown];
}

- (void) animatedPanLeft
{
    [self animatedMapPan:EOAMapPanDirectionLeft];
}

- (void) animatedPanRight
{
    [self animatedMapPan:EOAMapPanDirectionRight];
}

- (void) animatedMapPan:(EOAMapPanDirection)panDirection
{
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation;
    CGFloat moveStep = 0.5;
    switch (panDirection) {
        case EOAMapPanDirectionUp:
        {
            translation = CGPointMake(0., self.view.center.y * moveStep);
            break;
        }
        case EOAMapPanDirectionDown:
        {
            translation = CGPointMake(0., -self.view.center.y * moveStep);
            break;
        }
        case EOAMapPanDirectionLeft:
        {
            translation = CGPointMake(self.view.center.x * moveStep, 0.);
            break;
        }
        case EOAMapPanDirectionRight:
        {
            translation = CGPointMake(-self.view.center.x * moveStep, 0.);
            break;
        }
        default:
        {
            return;
        }
    }
    
    translation.x *= self.mapView.contentScaleFactor;
    translation.y *= self.mapView.contentScaleFactor;
    
    const float angle = qDegreesToRadians(self.mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;
    
    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    const uint32_t tileSize31 = (1u << (31 - self.mapView.zoomLevel));
    const double scale31 = static_cast<double>(tileSize31) / self.mapView.tileSizeOnScreenInPixels;
    
    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = self.mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    
    [self goToPosition:[OANativeUtilities convertFromPointI:target31] animated:YES];
}


- (float) calculateMapRuler
{
    if (!self.mapViewLoaded)
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
    [_mapLayers.downloadedRegionsLayer hideRegionHighlight];
}

- (void) highlightRegion:(OAWorldRegion *)region
{
    [_mapLayers.downloadedRegionsLayer highlightRegion:region];
}

- (void) hideRegionHighlight
{
    [_mapLayers.downloadedRegionsLayer hideRegionHighlight];
}

- (float) currentZoomOutDelta
{
    if (!self.mapViewLoaded)
        return 0.0f;

    const auto currentZoomAnimation = _mapView.mapAnimator->getCurrentAnimation(kUserInteractionAnimationKey,
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

- (void) onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void) onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.mapRendererView)
            self.mapRendererView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;
    });
}

- (void) onMapSettingsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void) onUpdateGpxTracks
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        [self refreshGpxTracks];
    });
}

- (void) onUpdateRecTrack
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        if ([[OAAppSettings sharedManager].mapSettingShowRecordingTrack get])
            [self showRecGpxTrack:YES];
        else
            [self hideRecGpxTrack];
    });
}

- (void) onTrackRecordingChanged:(id)observable withKey:(id)key
{
    if (![OAAppSettings sharedManager].mapSettingShowRecordingTrack.get)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        if (!self.minimap)
        {
            [self showRecGpxTrack:key != nil];
        }
    });
}

- (void) onMapLayerChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded || _app.isInBackground /* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void) onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_mapLayers.myPositionLayer updateMyLocationCourseProvider];
            [self updateCurrentMapSource];
        });
        [[OAMapViewTrackingUtilities instance] updateSettings];
    });
}

- (void) onLanguageSettingsChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void) onLocalResourcesChanged:(const QList< QString >&)ids
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mapViewLoaded/* || self.view.window == nil*/)
        {
            _mapSourceInvalidated = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCurrentMapSource];
        });
    });
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OACommonBoolean *keepMapLabelsVisible = settings.keepMapLabelsVisible;
    if (obj)
    {
        if (obj == keepMapLabelsVisible)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSymbolsLayerProviderAlpha];
                [self updateRasterLayerProviderAlpha];
            });
        }
    }
}

- (void) refreshMap
{
    if (_app.locationServices.status == OALocationServicesStatusActive)
        [[OAMapViewTrackingUtilities instance] refreshLocation];
}

- (void) disableRotationAnd3DView:(BOOL)disabled
{
    _rotationAnd3DViewDisabled = disabled;
}

- (void) resetViewAngle
{
    _mapView.elevationAngle = 90.;
    _map3DModeElevationAngle = _mapView.elevationAngle;
}

- (void)onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    @synchronized(_rendererSync)
    {
        [self updateMapLocaleLanguage];
    }
}

- (void)updateMapLocaleLanguage
{
    if (_mapPresentationEnvironment != nullptr)
    {
        NSString *langId = [self getMapPreferredLocale:_mapView.zoomLevel];
        if (![langId isEqualToString:_mapPresentationEnvironment->getLocaleLanguageId().toNSString()])
            _mapPresentationEnvironment->setLocaleLanguageId(QString::fromNSString(langId));
    }
}

- (NSString *)getMapPreferredLocale:(int)zoom
{
    return [self useAppLocaleForMap:zoom]
            ? [OAUtilities currentLang]
            : [[OAAppSettings sharedManager].settingPrefMapLanguage get];
}

- (BOOL)useAppLocaleForMap:(int)zoom
{
    BOOL replaceLocalNamesToAppLocale = zoom <= kReplaceLocalNamesMaxZoom;
    NSString *settingPrefMapLanguage = [[OAAppSettings sharedManager].settingPrefMapLanguage get];
    BOOL useLocalNames = !settingPrefMapLanguage || settingPrefMapLanguage.length == 0;
    return replaceLocalNamesToAppLocale && useLocalNames;
}

- (void) updateCurrentMapSource
{
    if (!self.mapViewLoaded)
        return;
    
    //[self showProgressHUD];
    
    @synchronized(_rendererSync)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        const auto screenTileSize = 256 * self.displayDensityFactor;
        double mapDensity = [settings.mapDensity get];
        double mapDensityAligned;
        if (mapDensity > 2)
            mapDensityAligned = 2.0;
        else if (mapDensity > 1)
            mapDensityAligned = 1.0;
        else
            mapDensityAligned = mapDensity;

        const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor * mapDensityAligned);
        const unsigned int rasterTileSizeOrig = (unsigned int)(256 * self.displayDensityFactor * mapDensity);
        OALog(@"Screen tile size %fpx, raster tile size %dpx", screenTileSize, rasterTileSize);

		if ([settings.batterySavingMode get])
            [_mapView limitFrameRefreshRate];
        else
            [_mapView restoreFrameRefreshRate];

        // Set reference tile size on the screen
        _mapView.referenceTileSizeOnScreenInPixels = screenTileSize;
        self.referenceTileSizeRasterOrigInPixels = rasterTileSizeOrig;

        // Release previously-used resources (if any)
        [_mapLayers resetLayers];
        
        _obfMapRasterLayerProvider.reset();

        _obfMapObjectsProvider.reset();
        _mapPrimitivesProvider.reset();
        _mapPresentationEnvironment.reset();
        _mapPrimitiviser.reset();
        [OAWeatherHelper.sharedInstance updateMapPresentationEnvironment:nil];

        if (_obfMapSymbolsProvider)
            [_mapView removeTiledSymbolsProvider:_obfMapSymbolsProvider];
        _obfMapSymbolsProvider.reset();

        if (!_gpxDocFileTemp)
            [_gpxDocsTemp removeAllObjects];

        [_gpxDocsRec removeAllObjects];
        
        [self recreateHeightmapProvider];
        [self updateElevationConfiguration];
        
        // Determine what type of map-source is being activated
        typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
        OAMapSource* lastMapSource = _app.data.lastMapSource;
        const auto resourceId = QString::fromNSString(lastMapSource.resourceId);
        const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
        OsmAnd::ResourcesManager::ResourceType resourceType = OsmAnd::ResourcesManager::ResourceType::Unknown;
        NSString *mapCreatorFilePath = [OAMapCreatorHelper sharedInstance].files[lastMapSource.resourceId];
        if (mapSourceResource)
            resourceType = mapSourceResource->type;
            
        if (resourceType == OsmAndResourceType::MapStyle)
        {
            const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
            
            const auto& resolvedMapStyle = _app.resourcesManager->mapStylesCollection->getResolvedStyleByName(unresolvedMapStyle->name);
            OALog(@"Using '%@' style from '%@' resource", unresolvedMapStyle->name.toNSString(), mapSourceResource->id.toNSString());

            _obfMapObjectsProvider.reset(new OsmAnd::ObfMapObjectsProvider(_app.resourcesManager->obfsCollection));

            NSLog(@"%@", [OAUtilities currentLang]);
            
            OsmAnd::MapPresentationEnvironment::LanguagePreference langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
            
            switch (settings.settingMapLanguage.get) {
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
            
            double mapDensity = [settings.mapDensity get];
            [_mapView setVisualZoomShift:mapDensity];
            
            QSet<QString> disabledPoiTypes = QSet<QString>();
            for (NSString *disabledPoiType in [settings getDisabledTypes])
            {
                disabledPoiTypes.insert(QString::fromNSString(disabledPoiType));
            }
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     mapDensity,
                                                                                     [settings.textSize get:settings.applicationMode.get],
                                                                                     nullptr,
                                                                                     disabledPoiTypes));
            [self updateMapLocaleLanguage];
            _mapPresentationEnvironment->setLanguagePreference(langPreferences);
            [OAWeatherHelper.sharedInstance updateMapPresentationEnvironment:self.mapPresentationEnv];
            
            _mapPrimitiviser.reset(new OsmAnd::MapPrimitiviser(_mapPresentationEnvironment));
            _mapPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_obfMapObjectsProvider,
                                                                           _mapPrimitiviser,
                                                                           rasterTileSize));

            // Configure with preset if such is set
            if (lastMapSource.variant != nil)
            {
                OALog(@"Using '%@' variant of style '%@'", lastMapSource.variant, unresolvedMapStyle->name.toNSString());

                QHash< QString, QString > newSettings;
                
                OAApplicationMode *am = settings.applicationMode.get;
                NSString *appMode = am.stringKey;
                newSettings[QString::fromLatin1("appMode")] = QString([appMode UTF8String]);
                NSString *baseMode = am.parent && am.parent.stringKey.length > 0 ? am.parent.stringKey : am.stringKey;
                newSettings[QString::fromLatin1("baseAppMode")] = QString([baseMode UTF8String]);
                                
                if (settings.nightMode)
                {
                    newSettings[QString::fromLatin1("nightMode")] = "true";
                    [_mapView setSkyColor:OsmAnd::ColorRGB(48, 64, 128)];
                    [_mapView setFogColor:OsmAnd::ColorRGB(36, 48, 96)];
                }
                else
                {
                    [_mapView setSkyColor:OsmAnd::ColorRGB(255, 255, 255)];
                    [_mapView setFogColor:OsmAnd::ColorRGB(235, 231, 228)];
                }
                
                // --- Apply Map Style Settings
                OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
                NSArray *params = styleSettings.getAllParameters;
                OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
                BOOL useContours = [iapHelper.srtm isActive];
                BOOL useDepthContours = [iapHelper.nautical isActive] && ([OAIAPHelper isPaidVersion] || [OAIAPHelper isDepthContoursPurchased]);
                for (OAMapStyleParameter *param in params)
                {
                    if ([param.name isEqualToString:CONTOUR_LINES] && !useContours)
                    {
                        newSettings[QString::fromNSString(param.name)] = QStringLiteral("disabled");
                        continue;
                    }
                    if ([param.name isEqualToString:NAUTICAL_DEPTH_CONTOURS] && !useDepthContours)
                    {
                        newSettings[QString::fromNSString(param.name)] = QStringLiteral("false");
                        continue;
                    }
                    if (param.value.length > 0 && ![param.value isEqualToString:@"false"])
                        newSettings[QString::fromNSString(param.name)] = QString::fromNSString(param.value);
                }
                
                if (!newSettings.isEmpty())
                    _mapPresentationEnvironment->setSettings(newSettings);
            }
        
            _obfMapRasterLayerProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
            [_mapView setProvider:_obfMapRasterLayerProvider forLayer:kObfRasterLayer];

            _obfMapSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                   rasterTileSize,
                                                                                   nullptr,
                                                                                   false,
                                                                                   false));
            
            [_mapView addTiledSymbolsProvider:kObfSymbolSection provider:_obfMapSymbolsProvider];
            
            _app.resourcesManager->getWeatherResourcesManager()->setBandSettings(OAWeatherHelper.sharedInstance.getBandSettings);
        }
        else if (resourceType == OsmAndResourceType::OnlineTileSources || mapCreatorFilePath)
        {
            if (resourceType == OsmAndResourceType::OnlineTileSources)
            {
                const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(mapSourceResource->metadata)->sources;
                OALog(@"Using '%@' online source from '%@' resource", lastMapSource.variant, mapSourceResource->id.toNSString());
                
                const auto onlineMapTileProvider = onlineTileSources->createProviderFor(QString::fromNSString(lastMapSource.variant), _webClient);
                if (!onlineMapTileProvider)
                {
                    // Missing resource, shift to default
                    _app.data.lastMapSource = [OAAppData defaultMapSource];
                    return;
                }
                onlineMapTileProvider->setLocalCachePath(QString::fromNSString(_app.cachePath));
                _obfMapRasterLayerProvider = onlineMapTileProvider;
                [_mapView setProvider:_obfMapRasterLayerProvider forLayer:kObfRasterLayer];
            }
            else
            {
                OALog(@"Using '%@' source", lastMapSource.resourceId);
                
                const auto sqliteTileSourceMapProvider = std::make_shared<OASQLiteTileSourceMapLayerProvider>(QString::fromNSString(mapCreatorFilePath));
                if (!sqliteTileSourceMapProvider)
                {
                    // Missing resource, shift to default
                    _app.data.lastMapSource = [OAAppData defaultMapSource];
                    return;
                }

                _obfMapRasterLayerProvider = sqliteTileSourceMapProvider;
                [_mapView setProvider:_obfMapRasterLayerProvider forLayer:kObfRasterLayer];
            }
            
            lastMapSource = [OAAppData defaultMapSource];
            const auto resourceId = QString::fromNSString(lastMapSource.resourceId);
            const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
            const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
            
            const auto& resolvedMapStyle = _app.resourcesManager->mapStylesCollection->getResolvedStyleByName(unresolvedMapStyle->name);
            OALog(@"Using '%@' style from '%@' resource", unresolvedMapStyle->name.toNSString(), mapSourceResource->id.toNSString());
            
            _obfMapObjectsProvider.reset(new OsmAnd::ObfMapObjectsProvider(_app.resourcesManager->obfsCollection));
            
            NSLog(@"%@", [OAUtilities currentLang]);
            
            OsmAnd::MapPresentationEnvironment::LanguagePreference langPreferences = OsmAnd::MapPresentationEnvironment::LanguagePreference::NativeOnly;
            
            switch (settings.settingMapLanguage.get) {
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

            QSet<QString> disabledPoiTypes = QSet<QString>();
            for (NSString *disabledPoiType in [settings getDisabledTypes])
            {
                disabledPoiTypes.insert(QString::fromNSString(disabledPoiType));
            }
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     1.0,
                                                                                     1.0,
                                                                                     nullptr,
                                                                                     disabledPoiTypes));
            [self updateMapLocaleLanguage];
            _mapPresentationEnvironment->setLanguagePreference(langPreferences);
            _mapPrimitiviser.reset(new OsmAnd::MapPrimitiviser(_mapPresentationEnvironment));
            _mapPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_obfMapObjectsProvider,
                                                                           _mapPrimitiviser,
                                                                           rasterTileSize));
        }
        else
        {
            // Missing resource, shift to default
            _app.data.lastMapSource = [OAAppData defaultMapSource];
            return;
        }
        [[OAGPXAppearanceCollection sharedInstance] onUpdateMapSource:self];
        [[OAGPXAppearanceCollection sharedInstance] generateAvailableColors];

        [_mapLayers updateLayers];

        if (!_gpxDocFileTemp && [OAAppSettings sharedManager].mapSettingShowRecordingTrack.get)
            [self showRecGpxTrack:YES];

        [_selectedGpxHelper buildGpxList];
        if (_selectedGpxHelper.activeGpx.allKeys.count != 0 || _gpxDocsTemp.count != 0)
            [self initRendererWithGpxTracks];

        //[self hideProgressHUD];
        [_mapSourceUpdatedObservable notifyEvent];
    }
}

- (void) createGeoTiffCollection
{
    const auto manualTilesCollection = new OsmAnd::GeoTiffCollection();
    NSString *cacheDir = [_app.cachePath stringByAppendingPathComponent:GEOTIFF_SQLITE_CACHE_DIR];
    if (![NSFileManager.defaultManager fileExistsAtPath:cacheDir])
        [NSFileManager.defaultManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    manualTilesCollection->setLocalCache(QString::fromNSString(cacheDir));
    manualTilesCollection->addDirectory(_app.documentsDir.absoluteFilePath(QString::fromNSString(RESOURCES_DIR)));
    _geoTiffCollection.reset(manualTilesCollection);
}

- (void) recreateHeightmapProvider
{
    OASRTMPlugin *plugin = (OASRTMPlugin *) [OAPluginsHelper getEnabledPlugin:OASRTMPlugin.class];
    if (!plugin || ![plugin is3DMapsEnabled] || ![plugin isTerrainLayerEnabled])
    {
        _mapView.heightmapSupported = NO;
        [_mapView resetElevationDataProvider:YES];
        return;
    }
    _mapView.heightmapSupported = YES;
    [_mapView setElevationDataProvider:
        std::make_shared<OsmAnd::SqliteHeightmapTileProvider>(_geoTiffCollection, _mapView.elevationDataTileSize)];
}

- (void) updateElevationConfiguration
{
    OASRTMPlugin *plugin = (OASRTMPlugin *) [OAPluginsHelper getEnabledPlugin:OASRTMPlugin.class];
    BOOL disableVertexHillshade = !plugin || ![plugin is3DMapsEnabled] || ![plugin isTerrainLayerEnabled];
    OsmAnd::ElevationConfiguration elevationConfiguration;
    if (disableVertexHillshade)
    {
        elevationConfiguration.setSlopeAlgorithm(OsmAnd::ElevationConfiguration::SlopeAlgorithm::None);
        elevationConfiguration.setVisualizationStyle(OsmAnd::ElevationConfiguration::VisualizationStyle::None);
    }
    [_mapView setElevationConfiguration:elevationConfiguration forcedUpdate:YES];
}

- (void) updateRasterLayerProviderAlpha
{
    BOOL isUnderlayLayerDisplayed = _app.data.underlayMapSource;
    float alpha = isUnderlayLayerDisplayed ? _app.data.underlayAlpha : 0.0f;
    OsmAnd::MapLayerConfiguration mapLayerConfiguration;
    mapLayerConfiguration.setOpacityFactor(1.0f - alpha);
    [_mapView setMapLayerConfiguration:kObfRasterLayer configuration:mapLayerConfiguration forcedUpdate:NO];
}

- (void) updateSymbolsLayerProviderAlpha
{
    float symbolsAlpha = 1.0;
    if (![[OAAppSettings sharedManager].keepMapLabelsVisible get])
    {
        float overlayAlpha = _app.data.overlayMapSource ? _app.data.overlayAlpha : 0.0;
        float underlayAlpha = _app.data.underlayMapSource ? _app.data.underlayAlpha : 0.0;
        symbolsAlpha = 1.0 - overlayAlpha - underlayAlpha;
        if (symbolsAlpha < 0)
            symbolsAlpha = 0;
    }
    
    OsmAnd::SymbolSubsectionConfiguration symbolSubsectionConfiguration;
    symbolSubsectionConfiguration.setOpacityFactor(symbolsAlpha);
    [_mapView setSymbolSubsectionConfiguration:kObfSymbolSection configuration:symbolSubsectionConfiguration];
}

- (void) updatePoiLayer
{
    [_mapLayers.poiLayer updateLayer];
}

- (void) onLayersConfigurationChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayer:value];
    });
}

- (void) runWithRenderSync:(void (^)(void))runnable
{
    if (!self.mapViewLoaded || !runnable)
        return;
    
    @synchronized(_rendererSync)
    {
        runnable();
    }
}

- (void) updateLayer:(NSString *)layerId
{
    if (!self.mapViewLoaded)
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

    if (!self.mapViewLoaded || _contentScaleFactor == 0.0)
        return [UIScreen mainScreen].scale;
    
    return _contentScaleFactor;
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
    if (!self.mapViewLoaded || (position31.x == 0 && position31.y == 0))
        return;

    @synchronized(_rendererSync)
    {
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        _mapView.mapAnimator->pause();
        _mapView.mapAnimator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            _mapView.mapAnimator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kFastAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            _mapView.mapAnimator->resume();
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
    if (!self.mapViewLoaded || (position31.x == 0 && position31.y == 0))
        return;
    
    @synchronized(_rendererSync)
    {
        CGFloat z = [self normalizeZoom:zoom defaultZoom:_mapView.zoom];
        
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        _mapView.mapAnimator->pause();
        _mapView.mapAnimator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            _mapView.mapAnimator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kFastAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            _mapView.mapAnimator->animateZoomTo(z,
                                            kFastAnimationTime,
                                            OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                            kUserInteractionAnimationKey);
            _mapView.mapAnimator->resume();
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

    CGPoint center;
    OsmAnd::PointI centerI = _mapView.target31;
    [_mapView convert:&centerI toScreen:&center checkOffScreen:YES];

    CGPoint originalCenter;
    OsmAnd::PointI originalCenterI = [OANativeUtilities convertFromPoint31:originalCenter31];
    [_mapView convert:&originalCenterI toScreen:&originalCenter checkOffScreen:YES];

    CGPoint targetPoint;
    OsmAnd::PointI targetPositionI = [OANativeUtilities convertFromPoint31:targetPosition31];
    [_mapView convert:&targetPositionI toScreen:&targetPoint checkOffScreen:YES];
    
    CGPoint newPosition = center;

    CGFloat targetX = leftInset + leftTargetInset;
    CGFloat minPointX = targetX;
    CGFloat targetY = DeviceScreenHeight - bottomInset - bottomTargetInset;
    CGFloat minPointY = targetY;

    newPosition.y = center.y - (minPointY - targetPoint.y);
    if (newPosition.y < originalCenter.y)
        newPosition.y = originalCenter.y;
        
    newPosition.x = center.x + (-minPointX + targetPoint.x);
    if (newPosition.x > originalCenter.x)
        newPosition.x = originalCenter.x;
    
    newPosition.x *= _mapView.contentScaleFactor;
    newPosition.y *= _mapView.contentScaleFactor;
    OsmAnd::PointI newPositionI;
    [_mapView convert:newPosition toLocation:&newPositionI];
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

- (void) showTempGpxTrack:(NSString *)filePath
{
    [self showTempGpxTrack:filePath update:YES];
}

- (void) showTempGpxTrack:(NSString *)filePath update:(BOOL)update
{
    if (_recTrackShowing)
        [self hideRecGpxTrack];

    @synchronized(_rendererSync)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx.get containsObject:filePath]) {
            [_gpxDocsTemp removeAllObjects];
            _gpxDocFileTemp = nil;
            return;
        }
        
        _tempTrackShowing = YES;

        if (![_gpxDocFileTemp isEqualToString:filePath] || _gpxDocsTemp.count == 0) {
            [_gpxDocsTemp removeAllObjects];
            _gpxDocFileTemp = [filePath copy];
            OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getNewGPXItem:filePath];
            NSString *path = gpx.file.absolutePath;
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:path];
            OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
            [_gpxDocsTemp addObject:gpxFile];
        }
        
        if (update)
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) showTempGpxTrackFromDocument:(OASGpxFile *)doc
{
    if (_recTrackShowing)
        [self hideRecGpxTrack];
    NSString *filePath = doc.path;

    @synchronized(_rendererSync)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx.get containsObject:filePath]) {
            [_gpxDocsTemp removeAllObjects];
            _gpxDocFileTemp = nil;
            return;
        }
        
        _tempTrackShowing = YES;

        if (![_gpxDocFileTemp isEqualToString:filePath] || _gpxDocsTemp.count == 0) {
            [_gpxDocsTemp removeAllObjects];
            _gpxDocFileTemp = [filePath copy];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
            OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
            
            [_gpxDocsTemp addObject:gpxFile];
        }
        
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideTempGpxTrack:(BOOL)update
{
    @synchronized(_rendererSync)
    {
        BOOL wasTempTrackShowing = _tempTrackShowing;
        _tempTrackShowing = NO;
        
        [_gpxDocsTemp removeAllObjects];
        NSString *folderParh = [_gpxDocFileTemp stringByDeletingLastPathComponent];
        if ([folderParh.lastPathComponent isEqualToString:@"Temp"])
            [NSFileManager.defaultManager removeItemAtPath:folderParh error:nil];
        _gpxDocFileTemp = nil;
        
        if (wasTempTrackShowing && update)
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideTempGpxTrack
{
    [self hideTempGpxTrack:YES];
}

- (void) showRecGpxTrack:(BOOL)refreshData
{
    if (_tempTrackShowing)
        [self hideTempGpxTrack];
    
    @synchronized(_rendererSync)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        if (refreshData)
            [_mapLayers.gpxRecMapLayer resetLayer];
        
        [helper runSyncBlock:^{
            OASGpxFile *doc = helper.currentTrack;
            if (doc && [helper hasData])
            {
                _recTrackShowing = YES;
                
                [_gpxDocsRec removeAllObjects];
                [_gpxDocsRec addObject:doc];

                NSMutableDictionary<NSString *, OASGpxFile *> *gpxDocs = [NSMutableDictionary dictionary];
                gpxDocs[kCurrentTrack] = doc;
                [_mapLayers.gpxRecMapLayer refreshGpxTracks:[gpxDocs copy] reset:NO];
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
        [_gpxDocsRec removeAllObjects];
    }
}


- (void) keepTempGpxTrackVisible
{
    if (!_gpxDocFileTemp || _gpxDocsTemp.count == 0)
        return;

    OASGpxFile *doc = _gpxDocsTemp.firstObject;
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getNewGPXItem:_gpxDocFileTemp];
    NSString *path = gpx.file.absolutePath;
    if (![[OAAppSettings sharedManager].mapSettingVisibleGpx.get containsObject:_gpxDocFileTemp])
    {
        [_selectedGpxHelper addGpxFile:doc for:path];

        NSString *gpxDocFileTemp = _gpxDocFileTemp;
        @synchronized(_rendererSync)
        {
            _tempTrackShowing = NO;
            [_gpxDocsTemp removeAllObjects];
            _gpxDocFileTemp = nil;
        }

        [[OAAppSettings sharedManager] showGpx:@[gpxDocFileTemp] update:NO];
    }
}

//- (void) setWptData:(OASearchWptAPI *)wptApi
//{
//    NSMutableArray *paths = [NSMutableArray array];
//    QList< std::shared_ptr<const OsmAnd::GpxDocument> > list;
//    auto activeGpx = _selectedGpxHelper.activeGpx;
//    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
//    {
//        if (it.value() == nullptr)
//            continue;
//
//        [paths addObject:it.key().toNSString()];
//        list << it.value();
//    }
//    list << _gpxDocsRec;
//    [wptApi setWptData:list paths:paths];
//}

- (void)setWptData:(OASearchWptAPI *)wptApi {
    NSMutableArray *paths = [NSMutableArray array];
    NSMutableArray *gpxDocs = [NSMutableArray array];

    for (NSString *key in _selectedGpxHelper.activeGpx.allKeys) {
        id value = _selectedGpxHelper.activeGpx[key];
        if (value == nil) {
            continue;
        }
        
        [paths addObject:key];
        
        [gpxDocs addObject:value];
    }
    
    if (_gpxDocsRec) {
        [gpxDocs addObject:_gpxDocsRec];
    }
    
    [wptApi setWptData:gpxDocs paths:paths];
}


- (BOOL)hasWptAt:(CLLocationCoordinate2D)location
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
    
    BOOL found = NO;
    
    for (OASWptPt *wptItem in helper.currentTrack.getPointsList)
    {
        if ([OAUtilities isCoordEqual:wptItem.position.latitude srcLon:wptItem.position.longitude destLat:location.latitude destLon:location.longitude])
        {
            found = YES;
        }
    }
    
    if (found)
        return YES;
    
    int i = 0;
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
    for (id key in activeGpx.allKeys)
    {
        OASGpxFile *value = activeGpx[key];
        
        if (value == nil)
        {
            continue;
        }
        for (OASWptPt *pt in value.getPointsList) {
            {
                if ([OAUtilities isCoordEqual:pt.position.latitude srcLon:pt.position.longitude destLat:location.latitude destLon:location.longitude])
                {
                    found = YES;
                }
            }
            
            if (found)
                return YES;
            
            i++;
        }
    }
    
    if (_gpxDocsTemp.count != 0)
    {
        OASGpxFile *doc = _gpxDocsTemp.firstObject;
        
        for (OASWptPt *loc in doc.getPointsList)
        {
            if ([OAUtilities isCoordEqual:loc.position.latitude srcLon:loc.position.longitude destLat:location.latitude destLon:location.longitude])
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
    return [self findWpt:location currentTrackOnly:NO];
}

- (BOOL)findWpt:(CLLocationCoordinate2D)location currentTrackOnly:(BOOL)currentTrackOnly
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];

    BOOL found = NO;
    NSMutableSet *groupSet = [NSMutableSet set];
   
    NSMutableSet<NSString *> *groups = [NSMutableSet set];
    
    for (OASWptPt *wptItem in helper.currentTrack.getPointsList)
    {
        // FIXME:
//        if ([[[OASavingTrackHelper sharedInstance] currentTrack].hiddenGroups containsObject:wptItem.category])
//            continue;

        if (wptItem.category.length > 0)
            [groupSet addObject:wptItem.category];

        if ([OAUtilities isCoordEqual:wptItem.position.latitude srcLon:wptItem.position.longitude destLat:location.latitude destLon:location.longitude])
        {
            self.foundWpt = wptItem;
            self.foundWptDocPath = nil;
            
            found = YES;
        }
    }

    if (found)
    {
        self.foundWptGroups = [groupSet allObjects];
        return YES;
    }
    else
    {
        [groupSet removeAllObjects];
    }
    
    if (currentTrackOnly)
        return NO;
    
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
    for (NSString *key in activeGpx.allKeys) {
        OASGpxFile * doc = activeGpx[key];
        
        if (!doc || [doc getPointsList].count == 0) {
            continue;
        }

        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getNewGPXItem:key];
        for (OASWptPt *loc in [doc getPointsList]) {
            if ([gpx.hiddenGroups containsObject:loc.category])
                continue;

            if (loc.category != nil)
            {
                [groups addObject:loc.category];
            }

            if ([OAUtilities isCoordEqual:loc.position.latitude srcLon:loc.position.longitude destLat:location.latitude destLon:location.longitude])
            {
                self.foundWpt = [[OASWptPt alloc] initWithWptPt:loc];
                self.foundWptDocPath = key;
                
                found = YES;
            }
        }
        
        if (found)
        {
            NSMutableArray *groupList = [NSMutableArray array];
            for (NSString *s in groups)
            {
                [groupList addObject:s];
            }

            self.foundWptGroups = groupList;
            return YES;
        }
        else
        {
            [groups removeAllObjects];
        }
    }
    
    if (_gpxDocsTemp.count != 0)
    {
        OASGpxFile *doc = _gpxDocsTemp.firstObject;
       
        NSString *gpxFilePath = [doc.path
                stringByReplacingOccurrencesOfString:[_app.gpxPath stringByAppendingString:@"/"]
                                          withString:@""];
        OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getNewGPXItem:gpxFilePath];
        
        for (OASWptPt *loc in [doc getPointsList]) {
           
            NSString *locType = loc.category;

            if ([gpx.hiddenGroups containsObject:locType]) {
                continue;
            }

            if (locType != nil)
            {
                [groups addObject:loc.category];
            }
            
            if ([OAUtilities isCoordEqual:loc.position.latitude srcLon:loc.position.longitude destLat:location.latitude destLon:location.longitude])
            {
                self.foundWpt = [[OASWptPt alloc] initWithWptPt:loc];
                self.foundWptDocPath = _gpxDocFileTemp;
                
                found = YES;
            }
        }
        
        if (found)
        {
            NSMutableArray *groupList = [NSMutableArray array];
            for (NSString *s in groups)
            {
                [groupList addObject:s];
            }

            self.foundWptGroups = groupList;
            return YES;
        }
        else
        {
            [groups removeAllObjects];
        }
    }
    
    return NO;
}

- (BOOL) deleteFoundWpt
{
    if (!self.foundWpt)
        return NO;
    
    if (!self.foundWptDocPath)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        [helper deleteWpt:self.foundWpt];
        
        // update map
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        });

        [self hideContextPinMarker];
        
        return YES;
    }
    else
    {
        NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
        for (NSString *key in activeGpx) {
            OASGpxFile *value = activeGpx[key];
            if (value == nil)
                continue;

            NSString *path = key;
            if ([path isEqualToString:self.foundWptDocPath])
            {
                OASGpxFile *doc = value;
                BOOL removed = [doc deleteWptPtPoint:_foundWpt];
                if (!removed)
                {
                      for (NSInteger i = 0; i < doc.getPointsList.count; i++)
                      {
                          OASWptPt *w = doc.getPointsList[i];
                          if ([OAUtilities doublesEqualUpToDigits:5
                                                          source:w.position.latitude
                                                      destination:w.position.latitude] &&
                              [OAUtilities doublesEqualUpToDigits:5
                                                          source:w.position.longitude
                                                      destination:w.position.longitude])
                          {
                              [doc deleteWptPtPoint:w];
                              break;
                          }
                      }
                  }
                
                OASKFile *file = [[OASKFile alloc] initWithFilePath:self.foundWptDocPath];
                doc.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
                
                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mapLayers.gpxMapLayer refreshGpxWaypoints];
                });
                
                [self hideContextPinMarker];

                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) saveFoundWpt
{
    if (!self.foundWpt)
        return NO;
    
    if (!self.foundWptDocPath)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        [helper saveWpt:self.foundWpt];

        // update map
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        });

        return YES;
    }
    else
    {
        NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
        for (NSString *key in activeGpx) {
            OASGpxFile *value = activeGpx[key];

            if (value == nil)
            {
                continue;
            }

            NSString *path = key;
            if ([path isEqualToString:self.foundWptDocPath])
            {
                OASGpxFile *doc = value;
                for (NSInteger i = 0; i < doc.getPointsList.count; i++) {
                    OASWptPt *w = doc.getPointsList[i];
                    

                    if ([OAUtilities doublesEqualUpToDigits:5 source:w.position.latitude destination:self.foundWpt.lat] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w.position.longitude destination:self.foundWpt.lon])
                    {
                        // FIXME:
 //                       [OAGPXDocument fillWpt:w usingWpt:self.foundWpt];
 //                        [OAGPXDocument fillPointsGroup:self.foundWpt wptPtPtr:w doc:doc];
                        OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
                        [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[self.foundWpt getColor]]];
                        break;
                    }
                }
                
                OASKFile *file = [[OASKFile alloc] initWithFilePath:self.foundWptDocPath];
                doc.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];

                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mapLayers.gpxMapLayer refreshGpxWaypoints];
                });
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) addNewWpt:(OASWptPt *)wpt gpxFileName:(NSString *)gpxFileName
{
    if (!gpxFileName)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        [helper addWpt:wpt];
        self.foundWpt = wpt;
        self.foundWptDocPath = nil;
        
        NSMutableSet *groups = [NSMutableSet set];
        for (OASWptPt *wptItem in helper.currentTrack.getPointsList)
        {
            if (wptItem.category.length > 0)
                [groups addObject:wptItem.category];
        }
        
        self.foundWptGroups = [groups allObjects];

        // update map
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        });

        return YES;
    }
    else
    {
        NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
        for (NSString *key in activeGpx) {
            OASGpxFile *value = activeGpx[key];

            if (value == nil)
            {
                continue;
            }

            NSString *path = key;
            if ([path isEqualToString:gpxFileName])
            {
                OASGpxFile *doc = value;

               // std::shared_ptr<OsmAnd::GpxDocument::WptPt> w(new OsmAnd::GpxDocument::WptPt());
                OASWptPt *w = [OASWptPt new];
                // FIXME:
//                [OAGPXDocument fillWpt:w usingWpt:wpt];
//                [OAGPXDocument fillPointsGroup:wpt wptPtPtr:w doc:doc];
                OAGPXAppearanceCollection *appeacaneCollection = [OAGPXAppearanceCollection sharedInstance];
                [appeacaneCollection selectColor:[appeacaneCollection getColorItemWithValue:[wpt getColor]]];
                
                OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileName];
                doc.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];

                self.foundWpt = wpt;
                self.foundWptDocPath = gpxFileName;
                
                NSMutableSet *groups = [NSMutableSet set];
                for (OASWptPt *loc in doc.getPointsList)
                {
                    if (loc.category != nil)
                    {
                        [groups addObject:loc.category];
                    }
                }
                
                self.foundWptGroups = [groups allObjects];

                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mapLayers.gpxMapLayer refreshGpxWaypoints];
                });
                
                return YES;
            }
        }
        
        if ([_gpxDocFileTemp isEqualToString:[gpxFileName lastPathComponent]])
        {
            OASGpxFile *doc = _gpxDocsTemp.firstObject ;

            std::shared_ptr<OsmAnd::GpxDocument::WptPt> w(new OsmAnd::GpxDocument::WptPt());
            // FIXME:
//            [OAGPXDocument fillWpt:w usingWpt:wpt];
//            [OAGPXDocument fillPointsGroup:wpt wptPtPtr:w doc:doc];
            OAGPXAppearanceCollection *appeacaneCollection = [OAGPXAppearanceCollection sharedInstance];
            [appeacaneCollection selectColor:[appeacaneCollection getColorItemWithValue:[wpt getColor]]];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFileName];
            doc.author = [OAAppVersion getFullVersionWithAppName];
            [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
            
            NSMutableSet *groups = [NSMutableSet set];
            for (OASWptPt *loc in doc.getPointsList)
            {
                if (loc.category != nil)
                {
                    [groups addObject:loc.category];
                }
            }
            
            self.foundWptGroups = [groups allObjects];
            
            return YES;
        }
    }
    
    return YES;
}

- (NSArray<OASWptPt *> *)getPointsOf:(NSString *)gpxFileName groupName:(NSString *)groupName
{
    OASGpxFile *gpxDocument;
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
    if (!gpxFileName)
    {
        gpxDocument = helper.currentTrack;
    }
    else if ([_gpxDocFileTemp isEqualToString:[gpxFileName lastPathComponent]])
    {
        gpxDocument = _gpxDocsTemp.firstObject;
    }
    else
    {
        NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
        for (NSString *key in activeGpx) {
            OASGpxFile *value = activeGpx[key];

            if (value == nil)
            {
                continue;
            }


            NSString *path = key;
            
            if ([path isEqualToString:gpxFileName])
            {
                gpxDocument = value;
                break;
            }
        }
    }
    if (gpxDocument)
        return [gpxDocument.pointsGroups.allKeys containsObject:groupName] ? gpxDocument.pointsGroups[groupName].points : gpxDocument.getPointsList;
    else
        return @[];
}

- (BOOL) updateWpts:(NSArray *)items docPath:(NSString *)docPath updateMap:(BOOL)updateMap
{
    if (items.count == 0)
        return NO;

    BOOL found = NO;
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
    for (NSString *key in activeGpx) {
        OASGpxFile *value = activeGpx[key];

        if (value == nil)
        {
            continue;
        }


        NSString *path = key;
        if ([path isEqualToString:docPath])
        {
            OASGpxFile *doc = value;

            for (OAGpxWptItem *item in items)
            {
                for (OASWptPt *loc in doc.getPointsList)
                {
    
                    
                    if ([OAUtilities doublesEqualUpToDigits:5 source:loc.position.latitude destination:item.point.lat] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:loc.position.longitude destination:item.point.lon])
                    {
                        // FIXME:
                       // [OAGPXDocument fillWpt:w usingWpt:item.point];
                      //  [OAGPXDocument fillPointsGroup:item.point wptPtPtr:w doc:doc];
                        OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
                        [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:item.point.getColor]];
                        found = YES;
                        break;
                    }
                }
            }
            
            if (found)
            {
                OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
                doc.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
                
                // update map
                if (updateMap)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_mapLayers.gpxMapLayer refreshGpxWaypoints];
                    });
                }
            }
            
            return found;
        }
    }
    
    if (_gpxDocsTemp.count != 0)
    {
        OASGpxFile *doc = _gpxDocsTemp.firstObject;

        for (OAGpxWptItem *item in items)
        {
            for (OASWptPt *loc in doc.getPointsList)
            {
                if ([OAUtilities doublesEqualUpToDigits:5 source:loc.position.latitude destination:item.point.lat] &&
                    [OAUtilities doublesEqualUpToDigits:5 source:loc.position.longitude destination:item.point.lon])
                {
                    // FIXME:
//                    [OAGPXDocument fillWpt:w usingWpt:item.point];
//                    [OAGPXDocument fillPointsGroup:item.point wptPtPtr:w doc:doc];
                    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
                    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:item.point.getColor]];
                    found = YES;
                    break;
                }
            }
        }
        
        if (found)
        {
            OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
            doc.author = [OAAppVersion getFullVersionWithAppName];
            [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
            
            // update map
            if (updateMap)
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self showTempGpxTrack:docPath];
                });
            
        }
    }
    
    return found;
}

- (BOOL)updateMetadata:(OASMetadata *)metadata oldPath:(NSString *)oldPath docPath:(NSString *)docPath
{
    if (!metadata)
        return NO;
    
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
    for (NSString *key in activeGpx) {
        OASGpxFile *value = activeGpx[key];

        if (value == nil)
        {
            continue;
        }


        NSString *path = key;
        if ([path isEqualToString:oldPath])
        {
            OASGpxFile *doc = value;
            OASMetadata *metadata = doc.metadata;

            if (metadata == nil) {
                metadata = [OASMetadata new];
                doc.metadata = metadata;
            }
            
            // FIXME:
            // [OAGPXDocument fillMetadata:m usingMetadata:metadata];
            
            [_selectedGpxHelper removeGpxFileWith:oldPath];
            [_selectedGpxHelper addGpxFile:doc for:docPath];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
            doc.author = [OAAppVersion getFullVersionWithAppName];
            [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
            
            return YES;
        }
    }
    
    if (_gpxDocsTemp.count != 0)
    {
        OASGpxFile *doc = _gpxDocsTemp.firstObject;
        OASMetadata *metadata = doc.metadata;

        if (metadata == nil) {
            metadata = [OASMetadata new];
            doc.metadata = metadata;
        }
// FIXME:
//        [OAGPXDocument fillMetadata:m usingMetadata:metadata];
        
        OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
        doc.author = [OAAppVersion getFullVersionWithAppName];
        [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];

        return YES;
    }
    
    return NO;
}

- (BOOL)deleteWpts:(NSArray *)items docPath:(NSString *)docPath
{
    if (items.count == 0)
        return NO;

    if (!docPath)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        for (OAGpxWptItem *item in items)
        {
            [helper deleteWpt:item.point];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        });
    }

    BOOL found = NO;
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = _selectedGpxHelper.activeGpx;
    for (NSString *key in activeGpx) {
        OASGpxFile *value = activeGpx[key];

        if (value == nil)
        {
            continue;
        }


        NSString *path = key;
        if ([path isEqualToString:docPath])
        {
            OASGpxFile *doc = value;

            for (OAGpxWptItem *item in items)
            {
                for (int i = 0; i < doc.getPointsList.count; i++)
                {
                    OASWptPt *w = doc.getPointsList[i];
                    if ([OAUtilities doublesEqualUpToDigits:5 source:w.position.latitude destination:item.point.lat] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w.position.longitude destination:item.point.lon])
                    {
                        [doc deleteWptPtPoint:w];
                        found = YES;
                        break;
                    }
                }
            }
            
            if (found)
            {
                
                OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
                doc.author = [OAAppVersion getFullVersionWithAppName];
                [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
                
                // update map
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
                
                return YES;
            }
        }
    }

    if (_gpxDocsTemp.count != 0)
    {
        OASGpxFile *doc = _gpxDocsTemp.firstObject;

        for (OAGpxWptItem *item in items)
        {
            for (int i = 0; i < doc.getPointsList.count; i++)
            {
                OASWptPt *w = doc.getPointsList[i];
                if ([OAUtilities doublesEqualUpToDigits:5 source:w.position.latitude destination:item.point.lat] &&
                    [OAUtilities doublesEqualUpToDigits:5 source:w.position.longitude destination:item.point.lon])
                {
                    [doc deleteWptPtPoint:w];
                    found = YES;
                    break;
                }
            }
        }
        
        if (found)
        {
            OASKFile *file = [[OASKFile alloc] initWithFilePath:docPath];
            doc.author = [OAAppVersion getFullVersionWithAppName];
            [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:doc];
            
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
    NSMutableDictionary<NSString *, OASGpxFile *> *docs = [NSMutableDictionary dictionary];
    if (_selectedGpxHelper.activeGpx.allKeys.count > 0 || _gpxDocsTemp.count > 0)
    {
        NSMutableDictionary<NSString *, OASGpxFile *> *activeGpx = [_selectedGpxHelper.activeGpx mutableCopy];
        for (NSString *key in activeGpx.allKeys) {
            OASGpxFile *doc = activeGpx[key];
            if (doc)
            {
                docs[key] = doc;
            }
        }
        if (_gpxDocFileTemp && _gpxDocsTemp.count > 0)
        {
            docs[_gpxDocFileTemp] = _gpxDocsTemp.firstObject;
        }
    }
    [_mapLayers.gpxMapLayer refreshGpxTracks:docs reset:YES];
}

- (void) refreshGpxTracks
{
    @synchronized(_rendererSync)
    {
        [_mapLayers.gpxMapLayer resetLayer];
        if (![_selectedGpxHelper buildGpxList])
            [self initRendererWithGpxTracks];
    }
}

- (UIColor *) getTransportRouteColor:(BOOL)nightMode renderAttrName:(NSString *)renderAttrName
{
    if (_mapPresentationEnvironment)
        return UIColorFromARGB(_mapPresentationEnvironment->getTransportRouteColor(nightMode, QString::fromNSString(renderAttrName)).argb);
    else
        return nil;
}

- (NSDictionary<NSString *, NSNumber *> *) getGpxColors
{
    const auto &gpxColorsMap = _mapPresentationEnvironment->getGpxColors();
    NSMutableDictionary<NSString *, NSNumber *> *result = [NSMutableDictionary dictionary];
    QHashIterator<QString, int> it(gpxColorsMap);
    while (it.hasNext()) {
        it.next();
        NSString *key = (0 == it.key().length()) ? (@"") : (it.key().toNSString());
        NSNumber *value = @(it.value());
        [result setObject:value forKey:key];
    }
    return result;
}

- (NSDictionary<NSString *, NSArray<NSNumber *> *> *) getGpxWidth
{
    auto gpxWidthMap = _mapPresentationEnvironment->getGpxWidth();
    if (gpxWidthMap.isEmpty())
        gpxWidthMap = _app.defaultRenderer->getGpxWidth();
    NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *result = [NSMutableDictionary dictionary];
    QHashIterator<QString, QList<int>> it(gpxWidthMap);
    while (it.hasNext()) {
        it.next();
        NSString *key = (0 == it.key().length()) ? (@"") : (it.key().toNSString());
        NSMutableArray<NSNumber *> *values = [NSMutableArray array];
        QList<int> itValues = it.value();
        for (int itValue : itValues)
        {
            [values addObject:@(itValue)];
        }
        result[key] = values;
    }
    return result;
}

- (NSDictionary<NSString *, NSNumber *> *) getLineRenderingAttributes:(NSString *)renderAttrName
{
    if (_mapPresentationEnvironment)
    {
        NSMutableDictionary<NSString *, NSNumber *> *result = [NSMutableDictionary new];
        QHash<QString, int> renderingAttrs = _mapPresentationEnvironment->getLineRenderingAttributes(QString::fromNSString(renderAttrName));
        QHashIterator<QString, int> it(renderingAttrs);
        while (it.hasNext()) {
            it.next();
            NSString * key = (0 == it.key().length())?(@""):(it.key().toNSString());
            NSNumber *value = @(it.value());
            if (value.intValue == -1)
                continue;
            
            [result setObject:value forKey:key];
        }
        return [[NSDictionary<NSString *, NSNumber *> alloc] initWithDictionary:result];
    }
    else
        return nil;
}

- (NSDictionary<NSString *, NSNumber *> *) getRoadRenderingAttributes:(NSString *)renderAttrName additionalSettings:(NSDictionary<NSString *, NSString*> *) additionalSettings
{
    if (_mapPresentationEnvironment && additionalSettings)
    {
        const auto& pair = _mapPresentationEnvironment->getRoadRenderingAttributes(QString::fromNSString(renderAttrName), [OANativeUtilities dictionaryToQHash:additionalSettings]);
        return @{pair.first.toNSString() : @(pair.second)};
    }
    else
    {
        return @{kUndefinedAttr : @(0xFFFFFFFF)};
    }
}

@synthesize framePreparedObservable = _framePreparedObservable;

- (BOOL) isMyLocationVisible
{
    CLLocation *myLocation = _app.locationServices.lastKnownLocation;
    return myLocation ? [self isLocationVisible:myLocation.coordinate.latitude longitude:myLocation.coordinate.longitude] : YES;
}

- (BOOL) isLocationVisible:(double)latitude longitude:(double)longitude
{
    OAMapRendererView* renderView = (OAMapRendererView*)self.view;
    OsmAnd::PointI location31(OsmAnd::Utilities::get31TileNumberX(longitude), OsmAnd::Utilities::get31TileNumberY(latitude));
    OsmAnd::AreaI visibleArea = [renderView getVisibleBBox31];
    return (visibleArea.topLeft.x < location31.x && visibleArea.topLeft.y < location31.y && visibleArea.bottomRight.x > location31.x && visibleArea.bottomRight.y > location31.y);
}

- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading
{
    [_mapLayers.myPositionLayer updateLocation:newLocation heading:newHeading];
    if (!OARoutingHelper.sharedInstance.isPublicTransportMode)
        [_mapLayers.routeMapLayer refreshRoute];
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    OARoutingHelper *helper = [OARoutingHelper sharedInstance];
    OATransportRoutingHelper *transportHelper = OATransportRoutingHelper.sharedInstance;
    NSString *error = helper.isPublicTransportMode ? [transportHelper getLastRouteCalcError] : [helper getLastRouteCalcError];
    OABBox routeBBox;
    routeBBox.top = DBL_MAX;
    routeBBox.bottom = DBL_MAX;
    routeBBox.left = DBL_MAX;
    routeBBox.right = DBL_MAX;
    if ([helper isRouteCalculated] && !error && !helper.isPublicTransportMode)
    {
        routeBBox = [helper getBBox];
    }
    else if (helper.isPublicTransportMode && transportHelper.getRoutes.size() > 0)
    {
        routeBBox = [transportHelper getBBox];
    }
    else
    {
        if (!helper.isPublicTransportMode)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:error preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapLayers.routeMapLayer refreshRoute];
        if (newRoute && [helper isRoutePlanningMode] && routeBBox.left != DBL_MAX && ![self isDisplayedInCarPlay])
            [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) 
                                                                      bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)
                                                                         animated:NO];
    });
}

- (void) routeWasUpdated
{
}

- (void) routeWasCancelled
{
    @synchronized(_rendererSync)
    {
        [_mapLayers.routeMapLayer resetLayer];
    }
}

- (void) routeWasFinished
{
    @synchronized(_rendererSync)
    {
        [_mapLayers.routeMapLayer resetLayer];
    }
}

- (OAMapRendererEnvironment *)mapRendererEnv
{
    return [[OAMapRendererEnvironment alloc] initWithObjects:_obfMapObjectsProvider
                                  mapPresentationEnvironment:_mapPresentationEnvironment
                                             mapPrimitiviser:_mapPrimitiviser
                                       mapPrimitivesProvider:_mapPrimitivesProvider
                                   mapObjectsSymbolsProvider:_obfMapSymbolsProvider
                                           obfsDataInterface:_obfsDataInterface
                                           geoTiffCollection:_geoTiffCollection];
}

- (OAMapPresentationEnvironment *)mapPresentationEnv
{
    return [[OAMapPresentationEnvironment alloc] initWithEnvironment:_mapPresentationEnvironment];
}

- (void) updateTapRulerLayer
{
    [self.mapLayers.rulerByTapControlLayer updateLayer];
}

- (void)getAltitudeForMapCenter:(void (^ _Nonnull)(float height))callback
{
    auto centerPixel = _mapView.getCenterPixel;
    OsmAnd::PointI elevatedPoint = OsmAnd::PointI();
    if ([_mapView getLocationFromElevatedPoint:centerPixel location31:&elevatedPoint])
        [self getAltitudeForPoint:elevatedPoint callback:callback];
    else
        callback(kMinAltitudeValue);
}

- (void)getAltitudeForLatLon:(CLLocationCoordinate2D)latLon callback:(void (^ _Nonnull)(float height))callback
{
    OsmAnd::PointI point = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.latitude, latLon.longitude));
    return [self getAltitudeForPoint:point callback:callback];
}

- (void)getAltitudeForPoint:(OsmAnd::PointI)point callback:(void (^ _Nonnull)(float height))callback
{
    double altitude = [_mapView getLocationHeightInMeters:point];
    if (altitude > kMinAltitudeValue)
    {
        callback(altitude);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            QList<float> heights = [self getHeightsForPoints:QList<OsmAnd::PointI>({point})];
            callback(heights.count() > 0 ? heights[0] : kMinAltitudeValue);
        });
    }
}

- (QList<float>)getHeightsForPoints:(QList<OsmAnd::PointI>)points
{
    QList<float> heights;
    _geoTiffCollection->calculateHeights(OsmAnd::ZoomLevel14, _mapView.elevationDataTileSize, points, heights);
    return heights;
}

@end
