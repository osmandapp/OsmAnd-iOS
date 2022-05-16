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
#import <MBProgressHUD.h>

#import "OAAppData.h"
#import "OAMapRendererView.h"

#import "OAAutoObserverProxy.h"
#import "OANavigationController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAQuickActionHudViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAMapStyleSettings.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAGpxWptItem.h"
#import "OADestination.h"
#import "OAPluginPopupViewController.h"
#import "OAIAPHelper.h"
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

#import "OARoutingHelper.h"
#import "OATransportRoutingHelper.h"
#import "OAPointDescription.h"
#import "OARouteCalculationResult.h"
#import "OATargetPointsHelper.h"
#import "OAAvoidSpecificRoads.h"

#import "OASubscriptionCancelViewController.h"
#import "OAWhatsNewBottomSheetViewController.h"
#import "OAAppVersionDependentConstants.h"

#include "OASQLiteTileSourceMapLayerProvider.h"
#include "OAWebClient.h"
#include <OsmAndCore/IWebClient.h>

//#include "OAMapMarkersCollection.h"

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
#include <OsmAndCore/TileSqliteDatabasesCollection.h>
#include <OsmAndCore/Map/SqliteHeightmapTileProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>

#include <OsmAndCore/QKeyValueIterator.h>

#import "OANativeUtilities.h"
#import "OALog.h"
#include "Localization.h"

#define _(name) OAMapRendererViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)
#define kGestureZoomCoef 10.0f

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
    QList< std::shared_ptr<const OsmAnd::GpxDocument> > _gpxDocsTemp;
    // Currently recording gpx
    QList< std::shared_ptr<const OsmAnd::GpxDocument> > _gpxDocsRec;

    OASelectedGPXHelper *_selectedGpxHelper;
    
    BOOL _tempTrackShowing;
    BOOL _recTrackShowing;

    // -------------------------------------------------------------------------------------------
    
    OsmAndAppInstance _app;
    
    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    CGFloat _contentScaleFactor;
    
    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;
    std::shared_ptr<OsmAnd::IWebClient> _webClient;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;

    std::shared_ptr<OsmAnd::ObfDataInterface> _obfsDataInterface;

    OACurrentPositionHelper *_currentPositionHelper;

    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _mapSettingsChangeObserver;
    OAAutoObserverProxy* _mapLayerChangeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _applicationModeChangedObserver;
    
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
    CGFloat _accumulatedRotationAngle;
    
    UITapGestureRecognizer* _grZoomIn;
    UITapGestureRecognizer* _grZoomOut;
    UIPanGestureRecognizer* _grElevation;
    UITapGestureRecognizer* _grSymbolContextMenu;
    UILongPressGestureRecognizer* _grPointContextMenu;
    
    CLLocationCoordinate2D _centerLocationForMapArrows;
    
    MBProgressHUD *_progressHUD;
    BOOL _rotationAnd3DViewDisabled;
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
                                                            andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];
    
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
    
    // - Zoom double tap gesture
    _grZoomDoubleTap = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(zoomGestureDetected:)];
    _grZoomDoubleTap.delegate = self;
    _grZoomDoubleTap.minimumNumberOfTouches = 1;
    _grZoomDoubleTap.maximumNumberOfTouches = 1;
    
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

    // prevents single tap to fire together with double tap
    [_grSymbolContextMenu requireGestureRecognizerToFail:_grZoomIn];
    [_grSymbolContextMenu requireGestureRecognizerToFail:_grZoomDoubleTap];
    
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
        _mapView.zoom = _app.initialURLMapState.zoom;
        _mapView.azimuth = _app.initialURLMapState.azimuth;
    }
    else
    {
        _mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                           _app.data.mapLastViewedState.target31.y);
        _mapView.zoom = _app.data.mapLastViewedState.zoom;
        _mapView.azimuth = _app.data.mapLastViewedState.azimuth;
        _mapView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;
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
    
    [self showWhatsNewDialogIfNeeded];
}

- (void) showWhatsNewDialogIfNeeded
{
    if ([OAAppSettings sharedManager].shouldShowWhatsNewScreen)
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
        _app.initialURLMapState = nil;
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
        UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = .5f;
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
        UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = 1.0f;
        _progressHUD.labelText = message;
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
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_mapView.target31);
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

- (float) getMapZoom
{
    return _mapView.zoom;
}

- (void) setMapPosition:(int)mapPosition
{
    _mapPosition = mapPosition;
    
    if (mapPosition == BOTTOM_CONSTANT && _mapView.viewportYScale != 1.5f)
        _mapView.viewportYScale = 1.5f;
    else if (mapPosition != BOTTOM_CONSTANT && _mapView.viewportYScale != 1.f)
        _mapView.viewportYScale = 1.f;
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
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();

    if (gestureRecognizer != _grPointContextMenu)
    {
        [self postMapGestureAction];
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
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

- (void) zoomGestureDetected:(UIGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded)
        return;
    
    UIPinchGestureRecognizer *pinchRecognizer = [recognizer isKindOfClass:UIPinchGestureRecognizer.class] ? (UIPinchGestureRecognizer *) recognizer : nil;
    UIPanGestureRecognizer *panGestutreRecognizer = [recognizer isKindOfClass:UIPanGestureRecognizer.class] ? (UIPanGestureRecognizer *) recognizer : nil;
    
    // If gesture has just began, just capture current zoom
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);
        _initialZoomLevelDuringGesture = _mapView.zoom;
        if (panGestutreRecognizer)
            _initialZoomTapPointY = [panGestutreRecognizer locationInView:recognizer.view].y;
        return;
    }
    
    // If gesture has been cancelled or failed, restore previous zoom
    if (recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        _mapView.zoom = _initialZoomLevelDuringGesture;

        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
        _zoomingByGesture = NO;
        return;
    }
    
    // Capture current touch center point
    OsmAnd::PointI centerLocationBefore;
    CGPoint centerPoint;
    if (pinchRecognizer)
    {
        centerPoint = [recognizer locationOfTouch:0 inView:recognizer.view];
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
    }
    else
    {
        centerPoint = CGPointMake(DeviceScreenWidth / 2 * _mapView.contentScaleFactor, DeviceScreenHeight / 2 * _mapView.contentScaleFactor);
    }
    [_mapView convert:centerPoint toLocation:&centerLocationBefore];
    
    // Change zoom
    CGFloat gestureScale = pinchRecognizer
        ? pinchRecognizer.scale
        : ([panGestutreRecognizer locationInView:recognizer.view].y * _mapView.contentScaleFactor) / (_initialZoomTapPointY * _mapView.contentScaleFactor);
    CGFloat scale = 1 - gestureScale;

    if (gestureScale < 1 || (scale < 0 && !pinchRecognizer))
        scale = scale * (kGestureZoomCoef / _mapView.contentScaleFactor);
    if (!pinchRecognizer)
        scale = -scale;

    _mapView.zoom = _initialZoomLevelDuringGesture - scale;
    if (_mapView.zoom > _mapView.maxZoom)
        _mapView.zoom = _mapView.maxZoom;
    else if (_mapView.zoom < _mapView.minZoom)
        _mapView.zoom = _mapView.minZoom;

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
        _zoomingByGesture = NO;
    }
    else
    {
        _zoomingByGesture = YES;
    }
    // If this is the end of gesture, get velocity for animation
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGFloat recognizerVelocity = pinchRecognizer ? pinchRecognizer.velocity : 0;
        float velocity = qBound(-kZoomVelocityAbsLimit, (float)recognizerVelocity, kZoomVelocityAbsLimit);
        _mapView.animator->animateZoomWith(velocity,
                                          kZoomDeceleration,
                                          kUserInteractionAnimationKey);
        _mapView.animator->resume();
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
        _movingByGesture = NO;
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
        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);
    }
    
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
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
    
    if (state == UIGestureRecognizerStateEnded ||
        state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
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
}

- (void) rotateGestureDetected:(UIRotationGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view
    if (!self.mapViewLoaded || _rotationAnd3DViewDisabled)
        return;
    
    // Zeroify accumulated rotation on gesture begin
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Suspend symbols update
        while (![_mapView suspendSymbolsUpdate]);

        _accumulatedRotationAngle = 0.0f;
    }
    
    // Check if accumulated rotation is greater than threshold
    if (fabs(_accumulatedRotationAngle) < kRotationGestureThresholdDegrees)
    {
        _accumulatedRotationAngle += qRadiansToDegrees(recognizer.rotation);
        [recognizer setRotation:0];

        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![_mapView resumeSymbolsUpdate]);
        _rotatingByGesture = NO;
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
        _rotatingByGesture = NO;
    }
    else
    {
        _rotatingByGesture = YES;
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

- (void) elevationGestureDetected:(UIPanGestureRecognizer *)recognizer
{
    // Ignore gesture if we have no view or if 3D view is disabled
    if (!self.mapViewLoaded || ![OAAppSettings.sharedManager.settingAllow3DView get] || _rotationAnd3DViewDisabled)
        return;

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
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

-(BOOL) simulateContextMenuPress:(UIGestureRecognizer *)recognizer
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
        OAQuickActionHudViewController *quickAction = [OARootViewController instance].mapPanel.hudViewController.quickActionController;
        [quickAction hideActionsSheetAnimated];
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

- (float) currentZoomInDelta
{
    if (!self.mapViewLoaded)
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

- (BOOL) canZoomIn
{
    if (!self.mapViewLoaded)
        return NO;
    
    return (_mapView.zoom < _mapView.maxZoom);
}

- (void) animatedZoomIn
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
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);

    _mapView.animator->resume();

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

- (BOOL) canZoomOut
{
    if (!self.mapViewLoaded)
        return NO;
    
    return (_mapView.zoom > _mapView.minZoom);
}

- (void) animatedZoomOut
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
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    _mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);
    _mapView.animator->resume();
    
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
}

- (void) updateCurrentMapSource
{
    if (!self.mapViewLoaded)
        return;
    
    [self showProgressHUD];
    
    @synchronized(_rendererSync)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        const auto screenTileSize = 256 * self.displayDensityFactor;
        const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor * [settings.mapDensity get]);
        const unsigned int rasterTileSizeOrig = (unsigned int)(256 * self.displayDensityFactor * [settings.mapDensity get]);
        OALog(@"Screen tile size %fpx, raster tile size %dpx", screenTileSize, rasterTileSize);

        // Set reference tile size on the screen
        _mapView.referenceTileSizeOnScreenInPixels = screenTileSize;
        self.referenceTileSizeRasterOrigInPixels = rasterTileSizeOrig;

        // Release previously-used resources (if any)
        [_mapLayers resetLayers];
        
        _rasterMapProvider.reset();

        _obfMapObjectsProvider.reset();
        _mapPrimitivesProvider.reset();
        _mapPresentationEnvironment.reset();
        _mapPrimitiviser.reset();
        [OAWeatherHelper.sharedInstance updateMapPresentationEnvironment:nil];

        if (_mapObjectsSymbolsProvider)
            [_mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProvider];
        _mapObjectsSymbolsProvider.reset();

        if (!_gpxDocFileTemp)
            _gpxDocsTemp.clear();

        _gpxDocsRec.clear();
        
        
        // TODO: Setup heights map from Documents folder temporarily
        // >>>---------------
        /*
        std::shared_ptr<const OsmAnd::ITileSqliteDatabasesCollection> heightsCollection;
        const auto manualHeightsCollection = new OsmAnd::TileSqliteDatabasesCollection();
        manualHeightsCollection->addDirectory(_app.resourcesManager->userStoragePath);
        heightsCollection.reset(manualHeightsCollection);
        [_mapView setElevationDataProvider:
            std::make_shared<OsmAnd::SqliteHeightmapTileProvider>(heightsCollection, _mapView.elevationDataTileSize)];
         */
        // <<<---------------
        
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
            
            NSString *langId = [OAUtilities currentLang];
            if (settings.settingPrefMapLanguage.get)
                langId = settings.settingPrefMapLanguage.get;
            else if (settings.settingMapLanguageShowLocal &&
                     settings.settingMapLanguageTranslit.get)
                langId = @"en";
            double mapDensity = [settings.mapDensity get];
            [_mapView setVisualZoomShift:mapDensity];
            _mapPresentationEnvironment.reset(new OsmAnd::MapPresentationEnvironment(resolvedMapStyle,
                                                                                     self.displayDensityFactor,
                                                                                     mapDensity,
                                                                                     [settings.textSize get:settings.applicationMode.get],
                                                                                     QString::fromNSString(langId),
                                                                                     langPreferences));
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
                    [_mapView setSkyColor:OsmAnd::ColorRGB(5, 20, 46)];
                }
                else
                {
                    [_mapView setSkyColor:OsmAnd::ColorRGB(140, 190, 214)];
                }
                
                // --- Apply Map Style Settings
                OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
                
                NSArray *params = styleSettings.getAllParameters;
                for (OAMapStyleParameter *param in params)
                {
                    if ([param.name isEqualToString:@"contourLines"] && ![[OAIAPHelper sharedInstance].srtm isActive])
                    {
                        newSettings[QString::fromNSString(param.name)] = QStringLiteral("disabled");
                        continue;
                    }
                    if (param.value.length > 0 && ![param.value isEqualToString:@"false"])
                        newSettings[QString::fromNSString(param.name)] = QString::fromNSString(param.value);
                }
                
                if (!newSettings.isEmpty())
                    _mapPresentationEnvironment->setSettings(newSettings);
            }
        
            _rasterMapProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_mapPrimitivesProvider));
            [_mapView setProvider:_rasterMapProvider forLayer:0];

            _mapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_mapPrimitivesProvider,
                                                                                   rasterTileSize));
            [_mapView addTiledSymbolsProvider:_mapObjectsSymbolsProvider];
            
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
                _rasterMapProvider = onlineMapTileProvider;
                [_mapView setProvider:_rasterMapProvider forLayer:0];
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

                _rasterMapProvider = sqliteTileSourceMapProvider;
                [_mapView setProvider:_rasterMapProvider forLayer:0];
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
            
            NSString *langId = [OAUtilities currentLang];
            if (settings.settingPrefMapLanguage.get)
                langId = settings.settingPrefMapLanguage.get;
            else if ([settings settingMapLanguageShowLocal] &&
                     settings.settingMapLanguageTranslit.get)
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
        else
        {
            // Missing resource, shift to default
            _app.data.lastMapSource = [OAAppData defaultMapSource];
            return;
        }

        [_mapLayers updateLayers];

        if (!_gpxDocFileTemp && [OAAppSettings sharedManager].mapSettingShowRecordingTrack.get)
            [self showRecGpxTrack:YES];
        
        [_selectedGpxHelper buildGpxList];
        if (!_selectedGpxHelper.activeGpx.isEmpty() || !_gpxDocsTemp.isEmpty())
            [self initRendererWithGpxTracks];

        [self hideProgressHUD];
        [_mapSourceUpdatedObservable notifyEvent];
    }
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
        _mapView.animator->pause();
        _mapView.animator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            _mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kFastAnimationTime,
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
    if (!self.mapViewLoaded || (position31.x == 0 && position31.y == 0))
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
                                              kFastAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            _mapView.animator->animateZoomTo(z,
                                            kFastAnimationTime,
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
            _gpxDocsTemp.clear();
            _gpxDocFileTemp = nil;
            return;
        }
        
        _tempTrackShowing = YES;

        if (![_gpxDocFileTemp isEqualToString:filePath] || _gpxDocsTemp.isEmpty()) {
            _gpxDocsTemp.clear();
            _gpxDocFileTemp = [filePath copy];
            OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filePath];
            NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
            _gpxDocsTemp.append(OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path)));
        }
        
        if (update)
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideTempGpxTrack:(BOOL)update
{
    @synchronized(_rendererSync)
    {
        BOOL wasTempTrackShowing = _tempTrackShowing;
        _tempTrackShowing = NO;
        
        _gpxDocsTemp.clear();
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
            
            const auto& doc = [helper.currentTrack getDocument];
            if (doc != nullptr && [helper hasData])
            {
                _recTrackShowing = YES;
                
                _gpxDocsRec.clear();
                _gpxDocsRec << doc;

                QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > gpxDocs;
                gpxDocs[QString::fromNSString(kCurrentTrack)] = doc;
                [_mapLayers.gpxRecMapLayer refreshGpxTracks:gpxDocs];
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

    std::shared_ptr<const OsmAnd::GpxDocument> doc = _gpxDocsTemp.first();
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:_gpxDocFileTemp];
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath]; 
    QString qPath = QString::fromNSString(path);
    if (![[OAAppSettings sharedManager].mapSettingVisibleGpx.get containsObject:_gpxDocFileTemp])
    {
        _selectedGpxHelper.activeGpx[qPath] = doc;

        NSString *gpxDocFileTemp = _gpxDocFileTemp;
        @synchronized(_rendererSync)
        {
            _tempTrackShowing = NO;
            _gpxDocsTemp.clear();
            _gpxDocFileTemp = nil;
        }

        [[OAAppSettings sharedManager] showGpx:@[gpxDocFileTemp] update:NO];
    }
}

- (void) setWptData:(OASearchWptAPI *)wptApi
{
    NSMutableArray *paths = [NSMutableArray array];
    QList< std::shared_ptr<const OsmAnd::GpxDocument> > list;
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        [paths addObject:it.key().toNSString()];
        list << it.value();
    }
    list << _gpxDocsRec;
    [wptApi setWptData:list paths:paths];
}

- (BOOL) hasFavoriteAt:(CLLocationCoordinate2D)location
{
    for (const auto& fav : _app.favoritesCollection->getFavoriteLocations())
    {
        double lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition31().x);
        double lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition31().y);
        if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:location.latitude destLon:location.longitude])
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
    
    for (OAWptPt *wptItem in helper.currentTrack.points)
    {
        if ([OAUtilities isCoordEqual:wptItem.position.latitude srcLon:wptItem.position.longitude destLat:location.latitude destLon:location.longitude])
        {
            found = YES;
        }
    }
    
    if (found)
        return YES;
    
    int i = 0;
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        const auto& doc = it.value();
        for (auto& loc : doc->points)
        {
            if ([OAUtilities isCoordEqual:loc->position.latitude srcLon:loc->position.longitude destLat:location.latitude destLon:location.longitude])
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
        
        for (auto& loc : doc->points)
        {
            if ([OAUtilities isCoordEqual:loc->position.latitude srcLon:loc->position.longitude destLat:location.latitude destLon:location.longitude])
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

- (BOOL) findWpt:(CLLocationCoordinate2D)location currentTrackOnly:(BOOL)currentTrackOnly
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];

    BOOL found = NO;
    NSMutableSet *groupSet = [NSMutableSet set];
    QSet<QString> groups;
    
    for (OAWptPt *wptItem in helper.currentTrack.points)
    {
        if ([[[OASavingTrackHelper sharedInstance] getCurrentGPX].hiddenGroups containsObject:wptItem.type])
            continue;

        if (wptItem.type.length > 0)
            [groupSet addObject:wptItem.type];
        
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
    
    int i = 0;
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        const auto& doc = it.value();
        NSString *gpxFilePath = [it.key().toNSString()
                stringByReplacingOccurrencesOfString:[_app.gpxPath stringByAppendingString:@"/"]
                                          withString:@""];
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:gpxFilePath];
        for (auto locIt = doc->points.begin(); locIt != doc->points.end(); ++locIt)
        {
            auto loc = *locIt;
            if ([gpx.hiddenGroups containsObject:loc->type.toNSString()])
                continue;

            if (!loc->type.isEmpty())
                groups.insert(loc->type);

            if ([OAUtilities isCoordEqual:loc->position.latitude srcLon:loc->position.longitude destLat:location.latitude destLon:location.longitude])
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::WptPt> w = _wpt->shared_ptr();

                OAWptPt *wptItem = [OAGPXDocument fetchWpt:w];
                wptItem.wpt = w;
                
                self.foundWpt = wptItem;
                self.foundWptDocPath = it.key().toNSString();
                
                found = YES;
            }
        }
        
        if (found)
        {
            NSMutableArray *groupList = [NSMutableArray array];
            for (const auto& s : groups)
                [groupList addObject:s.toNSString()];

            self.foundWptGroups = groupList;
            return YES;
        }
        else
        {
            groups.clear();
        }
        
        i++;
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto &doc = std::const_pointer_cast<OsmAnd::GpxDocument>(_gpxDocsTemp.first());
        OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxDocument:doc];
        NSString *gpxFilePath = [document.path
                stringByReplacingOccurrencesOfString:[_app.gpxPath stringByAppendingString:@"/"]
                                          withString:@""];
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:gpxFilePath];
        for (auto& loc : doc->points)
        {
            if ([gpx.hiddenGroups containsObject:loc->type.toNSString()])
                continue;

            if (!loc->type.isEmpty())
                groups.insert(loc->type);
            
            if ([OAUtilities isCoordEqual:loc->position.latitude srcLon:loc->position.longitude destLat:location.latitude destLon:location.longitude])
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::WptPt> w = _wpt->shared_ptr();
                
                OAWptPt *wptItem = [OAGPXDocument fetchWpt:w];
                wptItem.wpt = w;
                
                self.foundWpt = wptItem;
                self.foundWptDocPath = _gpxDocFileTemp;
                
                found = YES;
            }
        }
        
        if (found)
        {
            NSMutableArray *groupList = [NSMutableArray array];
            for (const auto& s : groups)
                [groupList addObject:s.toNSString()];

            self.foundWptGroups = groupList;
            return YES;
        }
        else
        {
            groups.clear();
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
        auto activeGpx = _selectedGpxHelper.activeGpx;
        for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
        {
            NSString *path = it.key().toNSString();
            if ([path isEqualToString:self.foundWptDocPath])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());
                
                if (!doc->points.removeOne(_foundWpt.wpt))
                    for (int i = 0; i < doc->points.count(); i++)
                    {
                        const auto& w = doc->points[i];
                        if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:_foundWpt.wpt->position.latitude] &&
                            [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:_foundWpt.wpt->position.longitude])
                        {
                            doc->points.removeAt(i);
                            break;
                        }
                    }
                
                doc->saveTo(QString::fromNSString(self.foundWptDocPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
                
                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:doc->points.count()];
                [[OAGPXDatabase sharedDb] save];
                
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
        auto activeGpx = _selectedGpxHelper.activeGpx;
        for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
        {
            NSString *path = it.key().toNSString();
            if ([path isEqualToString:self.foundWptDocPath])
            {
                const auto& doc = it.value();
                
                for (const auto& loc : doc->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&loc;
                    const std::shared_ptr<OsmAnd::GpxDocument::WptPt> w = _wpt->shared_ptr();

                    if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:self.foundWpt.position.latitude] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:self.foundWpt.position.longitude])
                    {
                        [OAGPXDocument fillWpt:w usingWpt:self.foundWpt];
                        break;
                    }
                }
                
                doc->saveTo(QString::fromNSString(self.foundWptDocPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
                
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

- (BOOL) addNewWpt:(OAWptPt *)wpt gpxFileName:(NSString *)gpxFileName
{
    if (!gpxFileName)
    {
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];

        [helper addWpt:wpt];
        self.foundWpt = wpt;
        self.foundWptDocPath = nil;
        
        NSMutableSet *groups = [NSMutableSet set];
        for (OAWptPt *wptItem in helper.currentTrack.points)
        {
            if (wptItem.type.length > 0)
                [groups addObject:wptItem.type];
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
        auto activeGpx = _selectedGpxHelper.activeGpx;
        for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
        {
            NSString *path = it.key().toNSString();
            if ([path isEqualToString:gpxFileName])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());

                std::shared_ptr<OsmAnd::GpxDocument::WptPt> p;
                p.reset(new OsmAnd::GpxDocument::WptPt());
                [OAGPXDocument fillWpt:p usingWpt:wpt];
                
                doc->points.append(p);
                doc->saveTo(QString::fromNSString(gpxFileName), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
                
                wpt.wpt = p;
                self.foundWpt = wpt;
                self.foundWptDocPath = gpxFileName;
                
                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:doc->points.count()];
                [[OAGPXDatabase sharedDb] save];
                
                NSMutableSet *groups = [NSMutableSet set];
                for (auto& loc : doc->points)
                {
                    if (!loc->type.isEmpty())
                        [groups addObject:loc->type.toNSString()];
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
            auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(_gpxDocsTemp.first());

            std::shared_ptr<OsmAnd::GpxDocument::WptPt> p;
            p.reset(new OsmAnd::GpxDocument::WptPt());
            [OAGPXDocument fillWpt:p usingWpt:wpt];
            
            doc->points.append(p);
            doc->saveTo(QString::fromNSString(gpxFileName), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
            
            wpt.wpt = p;
            self.foundWpt = wpt;
            self.foundWptDocPath = gpxFileName;
            
            [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[self.foundWptDocPath lastPathComponent] pointsCount:doc->points.count()];
            [[OAGPXDatabase sharedDb] save];
            
            NSMutableSet *groups = [NSMutableSet set];
            for (auto& loc : doc->points)
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

- (NSArray<OAWptPt *> *)getPointsOf:(NSString *)gpxFileName
{
    OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
    if (!gpxFileName)
    {
        return helper.currentTrack.points;
    }
    else
    {
        auto activeGpx = _selectedGpxHelper.activeGpx;
        for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
        {
            NSString *path = it.key().toNSString();
            if ([path isEqualToString:gpxFileName])
            {
                OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(it.value())];
                return document.points;
            }
        }
        if ([_gpxDocFileTemp isEqualToString:[gpxFileName lastPathComponent]])
        {
            OAGPXDocument *document = [[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(_gpxDocsTemp.first())];
            return document.points;
        }
    }
    return nil;
}

- (BOOL) updateWpts:(NSArray *)items docPath:(NSString *)docPath updateMap:(BOOL)updateMap
{
    if (items.count == 0)
        return NO;

    BOOL found = NO;
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        if ([path isEqualToString:docPath])
        {
            const auto& doc = it.value();
         
            for (OAGpxWptItem *item in items)
            {
                for (const auto& loc : doc->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&loc;
                    const std::shared_ptr<OsmAnd::GpxDocument::WptPt> w = _wpt->shared_ptr();
                    
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
                doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
                
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
    
    if (!_gpxDocsTemp.isEmpty())
    {
        const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_gpxDocsTemp.first());
        
        for (OAGpxWptItem *item in items)
        {
            for (const auto& loc : doc->points)
            {
                OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> *_wpt = (OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>*)&loc;
                const std::shared_ptr<OsmAnd::GpxDocument::WptPt> w = _wpt->shared_ptr();
                
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
            doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
            
            // update map
            if (updateMap)
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self showTempGpxTrack:docPath];
                });
            
        }
    }
    
    return found;
}

- (BOOL)updateMetadata:(OAMetadata *)metadata oldPath:(NSString *)oldPath docPath:(NSString *)docPath
{
    if (!metadata)
        return NO;
    
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        if ([path isEqualToString:oldPath])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());
            OsmAnd::Ref<OsmAnd::GpxDocument::Metadata> *_meta = (OsmAnd::Ref<OsmAnd::GpxDocument::Metadata>*)&doc->metadata;
            std::shared_ptr<OsmAnd::GpxDocument::Metadata> m = _meta->shared_ptr();
            
            if (m == nullptr)
            {
                m.reset(new OsmAnd::GpxDocument::Metadata());
                doc->metadata = m;
            }
            
            [OAGPXDocument fillMetadata:m usingMetadata:metadata];

            _selectedGpxHelper.activeGpx.remove(QString::fromNSString(oldPath));
            _selectedGpxHelper.activeGpx[QString::fromNSString(docPath)] = doc;
            
            doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
            
            return YES;
        }
    }
    
    if (!_gpxDocsTemp.isEmpty())
    {
        auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(_gpxDocsTemp.first());
        OsmAnd::Ref<OsmAnd::GpxDocument::Metadata> *_meta = (OsmAnd::Ref<OsmAnd::GpxDocument::Metadata>*)&doc->metadata;
        std::shared_ptr<OsmAnd::GpxDocument::Metadata> m = _meta->shared_ptr();
        
        if (m == nullptr)
        {
            m.reset(new OsmAnd::GpxDocument::Metadata());
            doc->metadata = m;
        }

        [OAGPXDocument fillMetadata:m usingMetadata:metadata];
        
        doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));
        
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
    
    auto activeGpx = _selectedGpxHelper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        if ([path isEqualToString:docPath])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(it.value());

            for (OAGpxWptItem *item in items)
            {
                for (int i = 0; i < doc->points.count(); i++)
                {
                    const auto& w = doc->points[i];
                    if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                        [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                    {
                        doc->points.removeAt(i);
                        found = YES;
                        break;
                    }
                }
            }
            
            if (found)
            {
                doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));

                [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[docPath lastPathComponent] pointsCount:doc->points.count()];
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
        auto doc = std::const_pointer_cast<OsmAnd::GpxDocument>(_gpxDocsTemp.first());

        for (OAGpxWptItem *item in items)
        {
            for (int i = 0; i < doc->points.count(); i++)
            {
                const auto& w = doc->points[i];
                if ([OAUtilities doublesEqualUpToDigits:5 source:w->position.latitude destination:item.point.position.latitude] &&
                    [OAUtilities doublesEqualUpToDigits:5 source:w->position.longitude destination:item.point.position.longitude])
                {
                    doc->points.removeAt(i);
                    found = YES;
                    break;
                }
            }
        }
        
        if (found)
        {
            doc->saveTo(QString::fromNSString(docPath), QString::fromNSString([OAAppVersionDependentConstants getAppVersionWithBundle]));

            [[OAGPXDatabase sharedDb] updateGPXItemPointsCount:[docPath lastPathComponent] pointsCount:doc->points.count()];
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
    QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > docs;
    if (!_selectedGpxHelper.activeGpx.isEmpty() || !_gpxDocsTemp.isEmpty())
    {
        auto activeGpx = _selectedGpxHelper.activeGpx;
        for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
        {
            if (it.value())
                docs[it.key()] = it.value();
        }
        if (_gpxDocFileTemp && !_gpxDocsTemp.isEmpty())
            docs[QString::fromNSString(_gpxDocFileTemp)] = _gpxDocsTemp.first();
    }
    [_mapLayers.gpxMapLayer refreshGpxTracks:docs];
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
    NSMutableDictionary<NSString *, NSNumber *> *result = [NSMutableDictionary new];
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
    const auto &gpxWidthMap = _mapPresentationEnvironment->getGpxWidth();
    NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *result = [NSMutableDictionary new];
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
        return [[NSDictionary<NSString *, NSNumber *> alloc] initWithDictionary:result];;
    }
    else
        return [NSDictionary<NSString *, NSNumber *> new];
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
    
    @synchronized(_rendererSync)
    {
        [_mapLayers.routeMapLayer refreshRoute];
    }
    if (newRoute && [helper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self isDisplayedInCarPlay])
            {
                [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right) animated:NO];
            }
        });
    }
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
                                   mapObjectsSymbolsProvider:_mapObjectsSymbolsProvider
                                           obfsDataInterface:_obfsDataInterface];
}

- (OAMapPresentationEnvironment *)mapPresentationEnv
{
    return [[OAMapPresentationEnvironment alloc] initWithEnvironment:_mapPresentationEnvironment];
}


@end
