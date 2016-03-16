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
#import "OADefaultFavorite.h"
#import "OAPOIHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXRouteDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAFavoriteItem.h"
#import "OAUtilities.h"
#import "OAGpxWptItem.h"
#import "OAGPXRouter.h"
#import "OAGpxRoutePoint.h"
#import "OADestination.h"
#import "OAPluginPopupViewController.h"
#import "OAIAPHelper.h"
#import "OAMapCreatorHelper.h"

#include "OACoreResourcesAmenityIconProvider.h"
#include "OAHillshadeMapLayerProvider.h"
#include "OASQLiteTileSourceMapLayerProvider.h"

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
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>
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
#import "OASmartNaviWatchSession.h"

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
#define kHillshadeOpacity 0.7f

#define kGpxLayerId 9
#define kGpxRouteLayerId 10
#define kGpxTempLayerId 11
#define kGpxRecLayerId 12
#define kOverlayLayerId 5
#define kUnderlayLayerId -5
#define kHillshadeLayerId 4

#define _(name) OAMapRendererViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@implementation OAMapSymbol
@end


@interface OAMapViewController ()
@end

@implementation OAMapViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _overlayMapSourceChangeObserver;
    OAAutoObserverProxy* _underlayMapSourceChangeObserver;
    OAAutoObserverProxy* _overlayAlphaChangeObserver;
    OAAutoObserverProxy* _underlayAlphaChangeObserver;

    OAAutoObserverProxy* _hillshadeChangeObserver;
    OAAutoObserverProxy* _mapLayerChangeObserver;

    OAAutoObserverProxy* _lastMapSourceChangeObserver;

    OAAutoObserverProxy* _gpxRouteDefinedObserver;
    OAAutoObserverProxy* _gpxRouteCanceledObserver;
    OAAutoObserverProxy* _gpxRouteChangedObserver;

    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;

    // show poi on map
    BOOL _showPoiOnMap;
    NSString *_poiCategoryName;
    NSString *_poiFilterName;
    NSString *_poiTypeName;
    NSString *_poiKeyword;
    NSString *_prefLang;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;

    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;

    std::shared_ptr<OsmAnd::IMapLayerProvider> _hillshadeMapProvider;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterOverlayMapProvider;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterUnderlayMapProvider;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;
    
    NSString *_gpxDocFileTemp;
    NSString *_gpxDocFileRoute;
    NSArray *_geoInfoDocsGpxPaths;

    // Active gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpx;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenter;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpx;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpx;

    // Route gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpxRoute;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenterRoute;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpxRoute;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProviderRoute;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpxRoute;

    // Temp gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpxTemp;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenterTemp;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpxTemp;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProviderTemp;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpxTemp;
    
    // Currently recording gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpxRec;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenterRec;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpxRec;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProviderRec;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpxRec;

    // "My location" marker, "My course" marker and collection
    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKey;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKey;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKey;

    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionPedestrian;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyPedestrian;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerPedestrian;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyPedestrian;

    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionBicycle;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyBicycle;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerBicycle;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyBicycle;

    std::shared_ptr<OsmAnd::MapMarkersCollection> _myMarkersCollectionCar;
    std::shared_ptr<OsmAnd::MapMarker> _myLocationMarkerCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationMainIconKeyCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myLocationHeadingIconKeyCar;
    std::shared_ptr<OsmAnd::MapMarker> _myCourseMarkerCar;
    OsmAnd::MapMarker::OnSurfaceIconKey _myCourseMainIconKeyCar;

    // Context pin marker
    std::shared_ptr<OsmAnd::MapMarkersCollection> _contextPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _contextPinMarker;

    std::shared_ptr<OsmAnd::MapMarkersCollection> _destinationPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _favoritesMarkersCollection;

    std::shared_ptr<OsmAnd::ObfDataInterface> _obfsDataInterface;
    
    //std::shared_ptr<OAMapMarkersCollection> _testMarkersCollection;

    OAAutoObserverProxy* _appModeObserver;
    OAAppMode _lastAppMode;

    OAAutoObserverProxy* _mapModeObserver;
    OAMapMode _lastMapMode;
    OAMapMode _lastMapModeBeforeDrive;
    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _mapSettingsChangeObserver;
    OAAutoObserverProxy* _updateGpxTracksObserver;
    OAAutoObserverProxy* _updateRecTrackObserver;
    OAAutoObserverProxy* _updateRouteTrackObserver;
    
    OAAutoObserverProxy* _locationServicesStatusObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    
    OAAutoObserverProxy* _stateObserver;
    OAAutoObserverProxy* _settingsObserver;
    OAAutoObserverProxy* _framePreparedObserver;

    OAAutoObserverProxy* _trackRecordingObserver;

    OAAutoObserverProxy* _layersConfigurationObserver;

    OAAutoObserverProxy* _destinationShowObserver;
    OAAutoObserverProxy* _destinationHideObserver;

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
    
    BOOL _firstAppear;
    BOOL _rotatingToNorth;
    BOOL _isIn3dMode;
    
    NSDate *_startChangingMapMode;
    
    BOOL _tempTrackShowing;
    BOOL _recTrackShowing;
    
    CLLocationCoordinate2D _centerLocationForMapArrows;
    
    UIImageView *_animatedPin;
    BOOL _animationDone;
    int _animationDoneCounter;
    CGFloat _latPin, _lonPin;
    
    OAGPXRouter *_gpxRouter;
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
    
    _firstAppear = YES;

    _rendererSync = [[NSObject alloc] init];

    _hillshadeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onHillshadeLayerChanged)
                                                                 andObserve:_app.data.hillshadeChangeObservable];
    _overlayMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onOverlayLayerChanged)
                                                              andObserve:_app.data.overlayMapSourceChangeObservable];
    _overlayAlphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onOverlayLayerAlphaChanged)
                                                              andObserve:_app.data.overlayAlphaChangeObservable];
    _underlayMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onUnderlayLayerChanged)
                                                              andObserve:_app.data.underlayMapSourceChangeObservable];
    _underlayAlphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onUnderlayLayerAlphaChanged)
                                                              andObserve:_app.data.underlayAlphaChangeObservable];

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
    _stateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                               withHandler:@selector(onMapRendererStateChanged:withKey:)];
    _settingsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onMapRendererSettingsChanged:withKey:)];
    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged)
                                                              andObserve:_app.data.mapLayersConfiguration.changeObservable];
    
    
    _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onMapRendererFramePrepared)];

    _destinationShowObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationShow:withKey:)
                                                              andObserve:_app.data.destinationShowObservable];
    _destinationHideObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationHide:withKey:)
                                                              andObserve:_app.data.destinationHideObservable];

    
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
    
    // Create location and course markers
    _myMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilder;

    locationAndCourseMarkerBuilder.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilder.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilder.setBaseOrder(-206000);
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

    // Pedestrian
    _myMarkersCollectionPedestrian.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderPedestrian;
    
    locationAndCourseMarkerBuilderPedestrian.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderPedestrian.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderPedestrian.setBaseOrder(-206001);
    locationAndCourseMarkerBuilderPedestrian.setIsHidden(true);
    _myLocationMainIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myLocationMainIconKeyPedestrian,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_icon"]);
    _myLocationHeadingIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myLocationHeadingIconKeyPedestrian,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon"]);
    _myLocationMarkerPedestrian = locationAndCourseMarkerBuilderPedestrian.buildAndAddToCollection(_myMarkersCollectionPedestrian);
    
    locationAndCourseMarkerBuilderPedestrian.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyPedestrian = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderPedestrian.addOnMapSurfaceIcon(_myCourseMainIconKeyPedestrian,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_pedestrian_bearing"]);
    _myCourseMarkerPedestrian = locationAndCourseMarkerBuilderPedestrian.buildAndAddToCollection(_myMarkersCollectionPedestrian);
    
    // Bicycle
    _myMarkersCollectionBicycle.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderBicycle;
    
    locationAndCourseMarkerBuilderBicycle.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderBicycle.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderBicycle.setBaseOrder(-206002);
    locationAndCourseMarkerBuilderBicycle.setIsHidden(true);
    _myLocationMainIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myLocationMainIconKeyBicycle,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_bicycle"]);
    _myLocationHeadingIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myLocationHeadingIconKeyBicycle,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon2"]);
    _myLocationMarkerBicycle = locationAndCourseMarkerBuilderBicycle.buildAndAddToCollection(_myMarkersCollectionBicycle);
    
    locationAndCourseMarkerBuilderBicycle.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyBicycle = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderBicycle.addOnMapSurfaceIcon(_myCourseMainIconKeyBicycle,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_bicycle_bearing"]);
    _myCourseMarkerBicycle = locationAndCourseMarkerBuilderBicycle.buildAndAddToCollection(_myMarkersCollectionBicycle);
    
    // Car
    _myMarkersCollectionCar.reset(new OsmAnd::MapMarkersCollection());
    OsmAnd::MapMarkerBuilder locationAndCourseMarkerBuilderCar;
    
    locationAndCourseMarkerBuilderCar.setIsAccuracyCircleSupported(true);
    locationAndCourseMarkerBuilderCar.setAccuracyCircleBaseColor(OsmAnd::ColorRGB(0x20, 0xad, 0xe5));
    locationAndCourseMarkerBuilderCar.setBaseOrder(-206003);
    locationAndCourseMarkerBuilderCar.setIsHidden(true);
    _myLocationMainIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myLocationMainIconKeyCar,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_car"]);
    _myLocationHeadingIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myLocationHeadingIconKeyCar,
                                                       [OANativeUtilities skBitmapFromPngResource:@"my_location_marker_heading_icon2"]);
    _myLocationMarkerCar = locationAndCourseMarkerBuilderCar.buildAndAddToCollection(_myMarkersCollectionCar);
    
    locationAndCourseMarkerBuilderCar.clearOnMapSurfaceIcons();
    _myCourseMainIconKeyCar = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(0);
    locationAndCourseMarkerBuilderCar.addOnMapSurfaceIcon(_myCourseMainIconKeyCar,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_car_bearing"]);
    _myCourseMarkerCar = locationAndCourseMarkerBuilderCar.buildAndAddToCollection(_myMarkersCollectionCar);
    
    
    // Create context pin marker
    _contextPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    _contextPinMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(-210000)
        .setIsHidden(true)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"ic_map_pin"])
        .setPinIconAlignment((OsmAnd::MapMarker::PinIconAlignment)(OsmAnd::MapMarker::Top | OsmAnd::MapMarker::CenterHorizontal))
        .buildAndAddToCollection(_contextPinMarkersCollection);
    
    // Create favorites presenter
    /*
    _favoritesPresenter.reset(new OsmAnd::FavoriteLocationsPresenter(_app.favoritesCollection,
                                                                     [OANativeUtilities skBitmapFromPngResource:@"favorite_location_pin_marker_icon"]));
     */

    _app.favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });
    
    _app.favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                 const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                {
                                                                    [self onFavoriteLocationChanged:favoriteLocation];
                                                                });

    _destinationPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    
    [self refreshFavoritesMarkersCollection];
    
    //add observer for SmartNaviWatch updates
    [[OASmartNaviWatchSession sharedInstance] registerObserverForUpdates:self];
    
#if defined(OSMAND_IOS_DEV)
    _hideStaticSymbols = NO;
    _visualMetricsMode = OAVisualMetricsModeOff;
    _forceDisplayDensityFactor = NO;
    _forcedDisplayDensityFactor = self.displayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)
}

-(void)smartNaviWatchRequestLocationUpdate {

    //get the current location
    CLLocation* currentLocation = _app.locationServices.lastKnownLocation;

    //get the view to render the images
    OAMapRendererView* viewToRender = (OAMapRendererView*)self.view;
    
    //ensure screen is not turned off
    [viewToRender setHidden:NO];
    if (viewToRender.isRenderingSuspended) {
        //TODO does not work :(
        //[viewToRender resumeRendering];
    }
    

    //rotate in the appropriate angle
    [viewToRender setAzimuth:currentLocation.course];

    //zoom to an appropriate zoom level
    [viewToRender setZoom:17.0];
    
    //set portrait mode in order to fetch the correct images
    dispatch_async(dispatch_get_main_queue(), ^{

    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    });
    
    //move to location
    OsmAnd::PointI myLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude));
    [viewToRender setTarget31:myLocationI];
    
    
    //wait for map to be moved
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        
        NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:3];
        for (int i=1; i<4; ++i) {
            UIImage* renderedImage = [self renderImageFromMapScreen:viewToRender andZoomLevel:i];
            [images addObject:renderedImage];
        }
        
        [[OASmartNaviWatchSession sharedInstance] sendImageData:images forLocation:currentLocation];
        
    });
    


    

}

-(UIImage*)renderImageFromMapScreen:(UIView*)viewToRender andZoomLevel:(int)zoomLevel {
    
    float lengthOfImage = viewToRender.bounds.size.width/zoomLevel;
    
    [viewToRender setHidden:NO];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(lengthOfImage, lengthOfImage), YES, 0);
    [viewToRender drawViewHierarchyInRect:CGRectMake(-viewToRender.bounds.size.width/2+lengthOfImage/2, -viewToRender.bounds.size.height/2+lengthOfImage/2, viewToRender.bounds.size.width, viewToRender.bounds.size.height) afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)refreshFavoritesMarkersCollection
{
    _favoritesMarkersCollection.reset(new OsmAnd::MapMarkersCollection());

    for (const auto& favLoc : _app.favoritesCollection->getFavoriteLocations()) {
        
        UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        
        OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(1600000)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:favCol.iconName])
        .setPosition(favLoc->getPosition31())
        .setPinIconAlignment(OsmAnd::MapMarker::Center)
        .buildAndAddToCollection(_favoritesMarkersCollection);
        
    }
}

- (void)onFavoritesCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLayers];
        [self refreshFavoritesMarkersCollection];
        [self updateLayers];
    });
}

- (void)onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLayers];
        [self refreshFavoritesMarkersCollection];
        [self updateLayers];
    });
}

- (void)deinit
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);

    _app.favoritesCollection->collectionChangeObservable.detach((__bridge const void*)self);
    _app.favoritesCollection->favoriteLocationChangeObservable.detach((__bridge const void*)self);

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

    // Add context pin markers
    [mapView addKeyedSymbolsProvider:_contextPinMarkersCollection];
    [mapView addKeyedSymbolsProvider:_destinationPinMarkersCollection];
    
    // Add "My location" and "My course" markers
    [self updateMyLocationCourseProvider];
}

- (void)updateMyLocationCourseProvider
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    [mapView removeKeyedSymbolsProvider:_myMarkersCollectionCar];
    [mapView removeKeyedSymbolsProvider:_myMarkersCollectionPedestrian];
    [mapView removeKeyedSymbolsProvider:_myMarkersCollectionBicycle];
    [mapView removeKeyedSymbolsProvider:_myMarkersCollection];

    OAMapVariantType variantType = [OAMapStyleSettings getVariantType:_app.data.lastMapSource.variant];
    switch (variantType)
    {
        case OAMapVariantCar:
            [mapView addKeyedSymbolsProvider:_myMarkersCollectionCar];
            break;
        case OAMapVariantPedestrian:
            [mapView addKeyedSymbolsProvider:_myMarkersCollectionPedestrian];
            break;
        case OAMapVariantBicycle:
            [mapView addKeyedSymbolsProvider:_myMarkersCollectionBicycle];
            break;
            
        default:
            [mapView addKeyedSymbolsProvider:_myMarkersCollection];
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    mapView.userInteractionEnabled = YES;
    mapView.multipleTouchEnabled = YES;
    mapView.displayDensityFactor = self.displayDensityFactor;
    [mapView createContext];
    
    // Attach gesture recognizers:
    [mapView addGestureRecognizer:_grZoom];
    [mapView addGestureRecognizer:_grMove];
    [mapView addGestureRecognizer:_grRotate];
    [mapView addGestureRecognizer:_grZoomIn];
    [mapView addGestureRecognizer:_grZoomOut];
    [mapView addGestureRecognizer:_grElevation];
    [mapView addGestureRecognizer:_grSymbolContextMenu];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_firstAppear) {
        _firstAppear = NO;
        [_app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                   Visibility:[[OAAppSettings sharedManager] mapSettingShowFavorites]];
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
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastMapUsedTime];
    [[NSUserDefaults standardUserDefaults] synchronize];

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
    _geoInfoDocsGpxRoute.clear();
    _geoInfoDocsGpxRoute.append([doc getDocument]);
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
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // If gesture has just began, just capture current zoom
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        while (![mapView suspendSymbolsUpdate]);

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
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![mapView resumeSymbolsUpdate]);
    }

    // If this is the end of gesture, get velocity for animation
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        float velocity = qBound(-kZoomVelocityAbsLimit, (float)recognizer.velocity, kZoomVelocityAbsLimit);
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
    
    self.sidePanelController.recognizesPanGesture = NO;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan && recognizer.numberOfTouches > 0)
    {
        // Get location of the gesture
        CGPoint touchPoint = [recognizer locationOfTouch:0 inView:self.view];
        touchPoint.x *= mapView.contentScaleFactor;
        touchPoint.y *= mapView.contentScaleFactor;
        OsmAnd::PointI touchLocation;
        [mapView convert:touchPoint toLocation:&touchLocation];
        
        double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
        double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
        _centerLocationForMapArrows = CLLocationCoordinate2DMake(lat, lon);
        [self performSelector:@selector(setupMapArrowsLocation) withObject:nil afterDelay:1.0];

        // When user gesture has began, stop all animations
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        _app.mapMode = OAMapModeFree;

        // Suspend symbols update
        while (![mapView suspendSymbolsUpdate]);
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
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![mapView resumeSymbolsUpdate]);
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
        while (![mapView suspendSymbolsUpdate]);

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
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![mapView resumeSymbolsUpdate]);
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        //float velocity = qBound(-kRotateVelocityAbsLimitInDegrees, -qRadiansToDegrees((float)recognizer.velocity), kRotateVelocityAbsLimitInDegrees);
        //mapView.animator->animateAzimuthWith(velocity,
        //                                     kRotateDeceleration,
        //                                     kUserInteractionAnimationKey);
        
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

    OsmAnd::PointI destLocation(mapView.target31.x / 2.0 + centerLocation.x / 2.0, mapView.target31.y / 2.0 + centerLocation.y / 2.0);
    
    mapView.animator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomIn,
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
    
    OsmAnd::PointI destLocation(centerLocation.x - 2 * (centerLocation.x - mapView.target31.x), centerLocation.y - 2 * (centerLocation.y - mapView.target31.y));
    
    mapView.animator->animateTargetTo(destLocation,
                                      kQuickAnimationTime,
                                      OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomOut,
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
        while (![mapView suspendSymbolsUpdate]);
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
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![mapView resumeSymbolsUpdate]);
    }
}

-(void)simulateContextMenuPress:(UIGestureRecognizer*)recognizer
{
    [self pointContextMenuGestureDetected:recognizer];
}

- (void)processSymbolFields:(OAMapSymbol *)symbol decodedValues:(const QList<OsmAnd::Amenity::DecodedValue>)decodedValues descFieldLoc:(NSString *)descFieldLoc
{
    NSMutableArray *fuelTagsArr = [NSMutableArray array];
    NSMutableDictionary *content = [NSMutableDictionary dictionary];

    for (const auto& entry : decodedValues)
    {
        if (entry.declaration->tagName == QString("phone"))
            symbol.phone = entry.value.toString().toNSString();
        else if (entry.declaration->tagName == QString("operator"))
            symbol.oper = entry.value.toString().toNSString();
        else if (entry.declaration->tagName == QString("brand"))
            symbol.brand = entry.value.toString().toNSString();
        else if (entry.declaration->tagName == QString("wheelchair"))
            symbol.wheelchair = entry.value.toString().toNSString();
        else if (entry.declaration->tagName == QString("opening_hours"))
            symbol.openingHours = entry.value.toString().toNSString();
        else if (entry.declaration->tagName == QString("website"))
            symbol.url = entry.value.toString().toNSString();
        else if (entry.declaration->tagName.startsWith(QString("content")))
        {
            NSString *key = entry.declaration->tagName.toNSString();
            NSString *loc;
            if (key.length > 8)
                loc = [[key substringFromIndex:8] lowercaseString];
            else
                loc = @"";
            
            [content setObject:entry.value.toString().toNSString() forKey:loc];
        }
        else if (entry.declaration->tagName.startsWith(QString("description")) && !symbol.desc)
            symbol.desc = entry.value.toString().toNSString();
        else if (entry.declaration->tagName.startsWith(QString("fuel:")) && (entry.value.toString() == QString("yes")))
        {
            [fuelTagsArr addObject:entry.declaration->tagName.right(entry.declaration->tagName.length() - 5).toNSString()];
        }
        
        if (descFieldLoc && entry.declaration->tagName == QString::fromNSString(descFieldLoc))
            symbol.desc = entry.value.toString().toNSString();
    }
    if (fuelTagsArr.count > 0)
        symbol.fuelTags = [NSArray arrayWithArray:fuelTagsArr];
    
    symbol.localizedContent = [NSDictionary dictionaryWithDictionary:content];
}

- (void)pointContextMenuGestureDetected:(UIGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Get location of the gesture
    CGPoint touchPoint = [recognizer locationOfTouch:0 inView:self.view];
    touchPoint.x *= mapView.contentScaleFactor;
    touchPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [mapView convert:touchPoint toLocation:&touchLocation];
    
    // Format location
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
        [self setupMapArrowsLocation:CLLocationCoordinate2DMake(lat, lon)];

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self restoreMapArrowsLocation];
        // Resume symbols update
        while (![mapView resumeSymbolsUpdate]);
    }
    
    // Capture only last state
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    double lonTap = lon;
    double latTap = lat;
    
    NSMutableArray *foundSymbols = [NSMutableArray array];
    
    CLLocation* myLocation = _app.locationServices.lastKnownLocation;
    CGPoint myLocationScreen;
    OsmAnd::PointI myLocationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(myLocation.coordinate.latitude, myLocation.coordinate.longitude));
    [mapView convert:&myLocationI toScreen:&myLocationScreen];
    myLocationScreen.x *= mapView.contentScaleFactor;
    myLocationScreen.y *= mapView.contentScaleFactor;
    
    if (fabs(myLocationScreen.x - touchPoint.x) < 20.0 && fabs(myLocationScreen.y - touchPoint.y) < 20.0)
    {
        OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
        symbol.caption = OALocalizedString(@"my_location");
        symbol.type = OAMapSymbolMyLocation;
        symbol.touchPoint = touchPoint;
        symbol.location = myLocation.coordinate;
        symbol.sortIndex = (NSInteger)symbol.type;
        [foundSymbols addObject:symbol];
    }
    
    CGFloat delta = 10.0;

    _obfsDataInterface = _app.resourcesManager->obfsCollection->obtainDataInterface();

    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));

    BOOL doSkip = NO;

    const auto& symbolInfos = [mapView getSymbolsIn:area strict:NO];
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
            if (markerGroup->getMapMarker() == _contextPinMarker.get())
            {
                symbol.type = OAMapSymbolContext;
            }
            else
            {
                for (const auto& fav : _favoritesMarkersCollection->getMarkers())
                    if (markerGroup->getMapMarker() == fav.get())
                    {
                        symbol.type = OAMapSymbolFavorite;
                        lon = OsmAnd::Utilities::get31LongitudeX(fav->getPosition().x);
                        lat = OsmAnd::Utilities::get31LatitudeY(fav->getPosition().y);
                        break;
                    }
                for (const auto& dest : _destinationPinMarkersCollection->getMarkers())
                    if (markerGroup->getMapMarker() == dest.get())
                    {
                        symbol.type = OAMapSymbolDestination;
                        lon = OsmAnd::Utilities::get31LongitudeX(dest->getPosition().x);
                        lat = OsmAnd::Utilities::get31LatitudeY(dest->getPosition().y);
                        break;
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

                NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
                NSString *descFieldLoc;
                if (prefLang)
                    descFieldLoc = [@"description:" stringByAppendingString:prefLang];
                
                const auto& decodedCategories = amenity->getDecodedCategories();
                if (!decodedCategories.isEmpty())
                {
                    const auto& entry = decodedCategories.first();
                    if (!symbol.poiType)
                        symbol.poiType = [poiHelper getPoiTypeByCategory:entry.category.toNSString() name:entry.subcategory.toNSString()];
                }

                if (symbol.poiType)
                {
                    symbol.icon = [symbol.poiType mapIcon];
                    if ([symbol.poiType.name isEqualToString:@"wiki_place"])
                        symbol.type = OAMapSymbolWiki;
                    else
                        symbol.type = OAMapSymbolPOI;
                }
                else if ([self findWpt:CLLocationCoordinate2DMake(lat, lon)])
                {
                    symbol.type = OAMapSymbolWpt;
                    symbol.foundWpt = self.foundWpt;
                    symbol.foundWptGroups = self.foundWptGroups;
                    symbol.foundWptDocPath = self.foundWptDocPath;
                }

                symbol.caption = amenity->nativeName.toNSString();

                NSMutableDictionary *names = [NSMutableDictionary dictionary];
                const QString lang = (_prefLang ? QString::fromNSString(_prefLang) : QString::null);
                for(const auto& entry : OsmAnd::rangeOf(amenity->localizedNames))
                {
                    if (lang != QString::null && entry.key() == lang)
                        symbol.caption = entry.value().toNSString();
                    
                    [names setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
                }
                
                if (![names objectForKey:@""])
                    [names setObject:amenity->nativeName.toNSString() forKey:@""];
                
                symbol.localizedNames = [NSDictionary dictionaryWithDictionary:names];
                
                const auto decodedValues = amenity->getDecodedValues();
                [self processSymbolFields:symbol decodedValues:decodedValues descFieldLoc:descFieldLoc];
            }
            else if (objSymbolGroup != nullptr && objSymbolGroup->mapObject != nullptr)
            {
                const std::shared_ptr<const OsmAnd::MapObject> mapObject = objSymbolGroup->mapObject;
                
                NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];

                if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(objSymbolGroup->mapObject))
                {
                    std::shared_ptr<const OsmAnd::Amenity> amenity;
                    if (_obfsDataInterface->findAmenityForObfMapObject(obfMapObject, &amenity))
                    {
                        NSString *descFieldLoc;
                        if (prefLang)
                            descFieldLoc = [@"description:" stringByAppendingString:prefLang];
                        
                        const auto& decodedValues = amenity->getDecodedValues();
                        [self processSymbolFields:symbol decodedValues:decodedValues descFieldLoc:descFieldLoc];
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
                    
                    //NSLog(@"%@=%@", rule.tag.toNSString(), rule.value.toNSString());

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
                else if ([self findWpt:CLLocationCoordinate2DMake(lat, lon)])
                {
                    symbol.type = OAMapSymbolWpt;
                    symbol.foundWpt = self.foundWpt;
                    symbol.foundWptGroups = self.foundWptGroups;
                    symbol.foundWptDocPath = self.foundWptDocPath;
                }
                
                OsmAnd::MapSymbolsGroup* symbolGroup = dynamic_cast<OsmAnd::MapSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
                if (symbolGroup != nullptr)
                {
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
                                    if (symbol.caption)
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
        if (s.type == OAMapSymbolContext)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContextMarkerClicked
                                                                object:self
                                                              userInfo:nil];
            return;
        }
        else
        {
            if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
                s.location = CLLocationCoordinate2DMake(latTap, lonTap);
            
            if (s.type == OAMapSymbolWpt)
            {
                self.foundWpt = s.foundWpt;
                self.foundWptGroups = s.foundWptGroups;
                self.foundWptDocPath = s.foundWptDocPath;
            }
            
            [self postTargetNotification:s];
            return;
        }
    
    // if single press and no symbol found - exit
    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNoSymbolFound
                                                            object:self
                                                          userInfo:nil];
    }
    else
    {
        OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
        symbol.type = OAMapSymbolLocation;
        symbol.touchPoint = touchPoint;
        symbol.location = CLLocationCoordinate2DMake(lat, lon);
        [self postTargetNotification:symbol];
    }
}

- (void)postTargetNotification:(OAMapSymbol *)symbol
{    
    if (!symbol.caption)
        symbol.caption = @"";
    if (!symbol.buildingNumber)
        symbol.buildingNumber = @"";
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (symbol.poiType)
        [userInfo setObject:symbol.poiType forKey:@"poiType"];
    
    if (symbol.isPlace)
        [userInfo setObject:@"yes" forKey:@"place"];

    if (symbol.type == OAMapSymbolFavorite)
        [userInfo setObject:@"favorite" forKey:@"objectType"];
    else if (symbol.type == OAMapSymbolDestination)
        [userInfo setObject:@"destination" forKey:@"objectType"];
    else if (symbol.type == OAMapSymbolWpt)
        [userInfo setObject:@"waypoint" forKey:@"objectType"];
    else if (symbol.type == OAMapSymbolWiki)
        [userInfo setObject:@"wiki" forKey:@"objectType"];

    [userInfo setObject:symbol.caption forKey:@"caption"];
    if (symbol.captionExt)
        [userInfo setObject:symbol.captionExt forKey:@"captionExt"];
    
    [userInfo setObject:symbol.buildingNumber forKey:@"buildingNumber"];
    [userInfo setObject:[NSNumber numberWithDouble:symbol.location.latitude] forKey:@"lat"];
    [userInfo setObject:[NSNumber numberWithDouble:symbol.location.longitude] forKey:@"lon"];
    [userInfo setObject:[NSNumber numberWithFloat:symbol.touchPoint.x] forKey:@"touchPoint.x"];
    [userInfo setObject:[NSNumber numberWithFloat:symbol.touchPoint.y] forKey:@"touchPoint.y"];
    if (symbol.icon)
        [userInfo setObject:symbol.icon forKey:@"icon"];

    if (symbol.phone)
        [userInfo setObject:symbol.phone forKey:@"phone"];
    if (symbol.openingHours)
        [userInfo setObject:symbol.openingHours forKey:@"openingHours"];
    if (symbol.url)
        [userInfo setObject:symbol.url forKey:@"url"];
    if (symbol.desc)
        [userInfo setObject:symbol.desc forKey:@"desc"];

    if (symbol.oper)
        [userInfo setObject:symbol.oper forKey:@"oper"];
    if (symbol.brand)
        [userInfo setObject:symbol.brand forKey:@"brand"];
    if (symbol.wheelchair)
        [userInfo setObject:symbol.wheelchair forKey:@"wheelchair"];
    if (symbol.fuelTags)
        [userInfo setObject:symbol.fuelTags forKey:@"fuelTags"];
    if (symbol.localizedNames)
        [userInfo setObject:symbol.localizedNames forKey:@"names"];
    if (symbol.localizedContent)
        [userInfo setObject:symbol.localizedContent forKey:@"content"];

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object:self
                                                      userInfo:userInfo];
}

-(UIImage *)findIconAtPoint:(OsmAnd::PointI)touchPoint
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    CGFloat delta = 8.0;
    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));
    const auto& symbolInfos = [mapView getSymbolsIn:area strict:NO];

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

@synthesize stateObservable = _stateObservable;
@synthesize settingsObservable = _settingsObservable;

@synthesize azimuthObservable = _azimuthObservable;


- (void)onMapRendererStateChanged:(id)observer withKey:(id)key
{
    if (![self isViewLoaded])
        return;
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (_animatedPin)
            {
                OAMapRendererView* mapView = (OAMapRendererView*)self.view;
                
                CGPoint targetPoint;
                OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latPin, _lonPin));
                [mapView convert:&targetPositionI toScreen:&targetPoint];
                
                _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
            }
        });

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
    if (_animatedPin && _animationDone && _animationDoneCounter == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideAnimatedPin];
        });
    }
    else if (_animatedPin && _animationDone)
    {
        _animationDoneCounter--;
    }
    
    [_framePreparedObservable notifyEvent];
}

- (void)onDestinationShow:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        BOOL exists = NO;
        for (const auto &marker : _destinationPinMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                exists = YES;
                break;
            }
        }
        
        if (!exists)
            [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];
    }
}

- (void)onDestinationHide:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        for (const auto &marker : _destinationPinMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                _destinationPinMarkersCollection->removeMarker(marker);
                break;
            }
        }
    }
}

- (void)animatedAlignAzimuthToNorth
{
    if (![self isViewLoaded])
        return;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // When user gesture has began, stop all animations
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();

    if (_lastMapMode == OAMapModeFollow) {
        _rotatingToNorth = YES;
        _app.mapMode = OAMapModePositionTrack;
    }
    
    // Animate azimuth change to north
    mapView.animator->animateAzimuthTo(0.0f,
                                       kQuickAnimationTime * 2.0,
                                       OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
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
    if (mapView.zoomLevel >= OsmAnd::ZoomLevel22)
        return;

    // Get base zoom delta
    float zoomDelta = [self currentZoomInDelta];
    
    while ([mapView getSymbolsUpdateSuspended] < 0)
        [mapView suspendSymbolsUpdate];

    // Animate zoom-in by +1
    zoomDelta += 1.0f;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    
    if (_lastAppMode == OAAppModeDrive)
    {
        CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
        centerPoint.x *= mapView.contentScaleFactor;
        centerPoint.y *= mapView.contentScaleFactor;
        
        // Convert point from screen to location
        OsmAnd::PointI bottomLocation;
        [mapView convert:centerPoint toLocation:&bottomLocation];
        
        OsmAnd::PointI destLocation(mapView.target31.x / 2.0 + bottomLocation.x / 2.0, mapView.target31.y / 2.0 + bottomLocation.y / 2.0);

        mapView.animator->animateTargetTo(destLocation,
                                          kQuickAnimationTime,
                                          OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomIn,
                                          kUserInteractionAnimationKey);
    }
    
    mapView.animator->animateZoomBy(zoomDelta,
                                    kQuickAnimationTime,
                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                    kUserInteractionAnimationKey);

    mapView.animator->resume();

}


-(float)calculateMapRuler
{
    if (![self isViewLoaded])
        return 0.0f;

    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    if(self.currentZoomOutDelta != 0 || self.currentZoomInDelta != 0){
        return 0;
    }
    return mapView.currentPixelsToMetersScaleFactor ;
}

- (void)showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated
{
    _contextPinMarker->setIsHidden(true);

    if (!self.view.hidden && animated)
    {
        _animationDone = NO;
        _animationDoneCounter = 1;
        
        _latPin = latitude;
        _lonPin = longitude;
        
        const OsmAnd::LatLon latLon(_latPin, _lonPin);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));

        if (_animatedPin)
            [self hideAnimatedPin];
        
        _animatedPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_map_pin"]];
        
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        
        CGPoint targetPoint;
        OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
        [mapView convert:&targetPositionI toScreen:&targetPoint];
        
        _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                          animationWithKeyPath:@"transform"];
        
        CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
        CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
        CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
        CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
        
        NSArray *frameValues = [NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:scale1],
                                [NSValue valueWithCATransform3D:scale2],
                                [NSValue valueWithCATransform3D:scale3],
                                [NSValue valueWithCATransform3D:scale4],
                                nil];
        [animation setValues:frameValues];
        
        NSArray *frameTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0],
                               [NSNumber numberWithFloat:0.5],
                               [NSNumber numberWithFloat:0.9],
                               [NSNumber numberWithFloat:1.0],
                               nil];
        [animation setKeyTimes:frameTimes];
        
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.duration = .3;
        animation.delegate = self;
        _animatedPin.layer.anchorPoint = CGPointMake(0.5, 1.0);
        [_animatedPin.layer addAnimation:animation forKey:@"popup"];
        
        /*
        const CGFloat kDropCompressAmount = 0.1;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.duration = 0.1;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, -100, 0)];
        animation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        
        CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation2.duration = 0.10;
        animation2.beginTime = animation.duration;
        animation2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation2.toValue = [NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, _animatedPin.layer.frame.size.height * kDropCompressAmount, 0), 1.0, 1.0 - kDropCompressAmount, 1.0)];
        animation2.fillMode = kCAFillModeForwards;
        
        CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation3.duration = 0.15;
        animation3.beginTime = animation.duration + animation2.duration;
        animation3.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation3.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        animation3.fillMode = kCAFillModeForwards;
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = [NSArray arrayWithObjects:animation, animation2, animation3, nil];
        group.duration = animation.duration + animation2.duration + animation3.duration;
        group.fillMode = kCAFillModeForwards;
        
        group.delegate = self;
        
        [_animatedPin.layer addAnimation:group forKey:nil];
         */
        [self.view addSubview:_animatedPin];
    }
    else
    {
        const OsmAnd::LatLon latLon(latitude, longitude);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        _contextPinMarker->setIsHidden(false);
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _animationDone = YES;
    _contextPinMarker->setIsHidden(false);
}

- (void) hideAnimatedPin
{
    if (_animatedPin)
    {
        [_animatedPin.layer removeAllAnimations];
        [_animatedPin removeFromSuperview];
        _animatedPin = nil;
    }
}

- (void)hideContextPinMarker
{
    _contextPinMarker->setIsHidden(true);
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

    while ([mapView getSymbolsUpdateSuspended] < 0)
        [mapView suspendSymbolsUpdate];

    // Animate zoom-in by -1
    zoomDelta -= 1.0f;
    mapView.animator->pause();
    mapView.animator->cancelAllAnimations();
    
    if (_lastAppMode == OAAppModeDrive)
    {
        CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
        centerPoint.x *= mapView.contentScaleFactor;
        centerPoint.y *= mapView.contentScaleFactor;
        
        // Convert point from screen to location
        OsmAnd::PointI bottomLocation;
        [mapView convert:centerPoint toLocation:&bottomLocation];
        
        OsmAnd::PointI destLocation(bottomLocation.x - 2 * (bottomLocation.x - mapView.target31.x), bottomLocation.y - 2 * (bottomLocation.y - mapView.target31.y));
        
        mapView.animator->animateTargetTo(destLocation,
                                          kQuickAnimationTime,
                                          OsmAnd::MapAnimator::TimingFunction::Victor_ReverseExponentialZoomOut,
                                          kUserInteractionAnimationKey);
    }
    
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
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
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
                
                mapView.animator->pause();
                mapView.animator->cancelAllAnimations();

                OsmAnd::PointI newTarget31(
                    OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                    OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

                // In case previous mode was Follow, restore last azimuth, elevation angle and zoom
                // used in PositionTrack mode
                if (_lastMapMode == OAMapModeFollow && _lastPositionTrackStateCaptured)
                {
                    _startChangingMapMode = [NSDate date];

                    mapView.animator->animateTargetTo(newTarget31,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                      kLocationServicesAnimationKey);
                    mapView.animator->animateAzimuthTo(_lastAzimuthInPositionTrack,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                       kLocationServicesAnimationKey);
                    mapView.animator->animateElevationAngleTo(_lastElevationAngle,
                                                              kOneSecondAnimatonTime,
                                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                              kLocationServicesAnimationKey);
                    mapView.animator->animateZoomTo(_lastZoom,
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
                        mapView.animator->animateTargetTo(newTarget31,
                                                          kQuickAnimationTime,
                                                          OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                          kUserInteractionAnimationKey);
                        if (mapView.zoom < kGoToMyLocationZoom)
                            mapView.animator->animateZoomTo(kGoToMyLocationZoom,
                                                          kQuickAnimationTime,
                                                          OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                          kUserInteractionAnimationKey);
                    }
                    else
                    {
                        [mapView setTarget31:newTarget31];
                        if (mapView.zoom < kGoToMyLocationZoom)
                            [mapView setZoom:kGoToMyLocationZoom];
                    }
                }

                mapView.animator->resume();
            }
            _rotatingToNorth = NO;
            break;
        }
            
        case OAMapModeFollow:
        {
            // In case previous mode was PositionTrack, remember azimuth, elevation angle and zoom
            if (_lastMapMode == OAMapModePositionTrack && !_isIn3dMode)
            {
                _lastAzimuthInPositionTrack = mapView.azimuth;
                _lastZoom = mapView.zoom;
                _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
                _lastPositionTrackStateCaptured = true;
                _isIn3dMode = YES;
            }

            _startChangingMapMode = [NSDate date];

            mapView.animator->pause();
            mapView.animator->cancelAllAnimations();

            if (_lastAppMode == OAAppModeBrowseMap)
            {
                mapView.animator->animateZoomTo(kMapModeFollowDefaultZoom,
                                                kOneSecondAnimatonTime,
                                                OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                kLocationServicesAnimationKey);
                
                mapView.animator->animateElevationAngleTo(kMapModeFollowDefaultElevationAngle,
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
                    
                    mapView.animator->animateTargetTo(newTarget31,
                                                      kOneSecondAnimatonTime,
                                                      OsmAnd::MapAnimator::TimingFunction::Linear,
                                                      kLocationServicesAnimationKey);
                    
                    const auto direction = _app.locationServices.lastKnownHeading;
                    
                    if (!isnan(direction) && direction >= 0)
                    {
                        mapView.animator->animateAzimuthTo(direction,
                                                           kOneSecondAnimatonTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                }
                else
                {
                    mapView.zoom = kMapModeFollowDefaultZoom;
                    mapView.elevationAngle = kMapModeFollowDefaultElevationAngle;

                    double direction = newLocation.course;
                    //double direction = _app.locationServices.lastKnownHeading;
                    if (!isnan(direction) && direction >= 0)
                    {
                        // Set rotation
                        mapView.azimuth = direction;
                    }

                    CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
                    centerPoint.x *= mapView.contentScaleFactor;
                    centerPoint.y *= mapView.contentScaleFactor;
                    
                    // Convert point from screen to location
                    OsmAnd::PointI bottomLocation;
                    [mapView convert:centerPoint toLocation:&bottomLocation];
                    
                    OsmAnd::PointI targetCenter;
                    targetCenter.x = newTarget31.x + mapView.target31.x - bottomLocation.x;
                    targetCenter.y = newTarget31.y + mapView.target31.y - bottomLocation.y;
                    
                    mapView.target31 = targetCenter;
                    //NSLog(@"targetCenter %d %d", targetCenter.x, targetCenter.y);
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
    if (![self isViewLoaded])
        return;
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;

    OAMapVariantType variantType = [OAMapStyleSettings getVariantType:_app.data.lastMapSource.variant];

    // In case there's no known location, do nothing and hide all markers
    if (newLocation == nil)
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myLocationMarkerCar->setIsHidden(true);
                _myCourseMarkerCar->setIsHidden(true);
                break;
            case OAMapVariantPedestrian:
                _myLocationMarkerPedestrian->setIsHidden(true);
                _myCourseMarkerPedestrian->setIsHidden(true);
                break;
            case OAMapVariantBicycle:
                _myLocationMarkerBicycle->setIsHidden(true);
                _myCourseMarkerBicycle->setIsHidden(true);
                break;
                
            default:
                _myLocationMarker->setIsHidden(true);
                _myCourseMarker->setIsHidden(true);
                break;
        }
        
        return;
    }

    const OsmAnd::PointI newTarget31(
                                     OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                     OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

    // Update "My" markers
    if (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0)
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myLocationMarkerCar->setIsHidden(true);
                
                _myCourseMarkerCar->setIsHidden(false);
                _myCourseMarkerCar->setPosition(newTarget31);
                _myCourseMarkerCar->setIsAccuracyCircleVisible(true);
                _myCourseMarkerCar->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerCar->setOnMapSurfaceIconDirection(_myCourseMainIconKeyCar,
                                                              OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            case OAMapVariantPedestrian:
                _myLocationMarkerPedestrian->setIsHidden(true);
                
                _myCourseMarkerPedestrian->setIsHidden(false);
                _myCourseMarkerPedestrian->setPosition(newTarget31);
                _myCourseMarkerPedestrian->setIsAccuracyCircleVisible(true);
                _myCourseMarkerPedestrian->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerPedestrian->setOnMapSurfaceIconDirection(_myCourseMainIconKeyPedestrian,
                                                              OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            case OAMapVariantBicycle:
                _myLocationMarkerBicycle->setIsHidden(true);
                
                _myCourseMarkerBicycle->setIsHidden(false);
                _myCourseMarkerBicycle->setPosition(newTarget31);
                _myCourseMarkerBicycle->setIsAccuracyCircleVisible(true);
                _myCourseMarkerBicycle->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarkerBicycle->setOnMapSurfaceIconDirection(_myCourseMainIconKeyBicycle,
                                                              OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
                
            default:
                _myLocationMarker->setIsHidden(true);
                
                _myCourseMarker->setIsHidden(false);
                _myCourseMarker->setPosition(newTarget31);
                _myCourseMarker->setIsAccuracyCircleVisible(true);
                _myCourseMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myCourseMarker->setOnMapSurfaceIconDirection(_myCourseMainIconKey,
                                                              OsmAnd::Utilities::normalizedAngleDegrees(newLocation.course + 180.0f));
                break;
        }
    }
    else
    {
        switch (variantType)
        {
            case OAMapVariantCar:
                _myCourseMarkerCar->setIsHidden(true);
                
                _myLocationMarkerCar->setIsHidden(false);
                _myLocationMarkerCar->setPosition(newTarget31);
                _myLocationMarkerCar->setIsAccuracyCircleVisible(true);
                _myLocationMarkerCar->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerCar->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyCar,
                                                                OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;

            case OAMapVariantPedestrian:
                _myCourseMarkerPedestrian->setIsHidden(true);
                
                _myLocationMarkerPedestrian->setIsHidden(false);
                _myLocationMarkerPedestrian->setPosition(newTarget31);
                _myLocationMarkerPedestrian->setIsAccuracyCircleVisible(true);
                _myLocationMarkerPedestrian->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerPedestrian->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyPedestrian,
                                                                OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;

            case OAMapVariantBicycle:
                _myCourseMarkerBicycle->setIsHidden(true);
                
                _myLocationMarkerBicycle->setIsHidden(false);
                _myLocationMarkerBicycle->setPosition(newTarget31);
                _myLocationMarkerBicycle->setIsAccuracyCircleVisible(true);
                _myLocationMarkerBicycle->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarkerBicycle->setOnMapSurfaceIconDirection(_myLocationHeadingIconKeyBicycle,
                                                                OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
                
            default:
                _myCourseMarker->setIsHidden(true);
                
                _myLocationMarker->setIsHidden(false);
                _myLocationMarker->setPosition(newTarget31);
                _myLocationMarker->setIsAccuracyCircleVisible(true);
                _myLocationMarker->setAccuracyCircleRadius(newLocation.horizontalAccuracy);
                _myLocationMarker->setOnMapSurfaceIconDirection(_myLocationHeadingIconKey,
                                                                OsmAnd::Utilities::normalizedAngleDegrees(newHeading + 180.0f));
                break;
        }
    }

    // Wait for Map Mode changing animation if any, to prevent animation lags
    if (_startChangingMapMode && [[NSDate date] timeIntervalSinceDate:_startChangingMapMode] < kOneSecondAnimatonTime)
        return;
    
    // If map mode is position-track or follow, move to that position
    if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
    {
        mapView.animator->pause();

        const auto targetAnimation = mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                           OsmAnd::MapAnimator::AnimatedValue::Target);

        mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                 OsmAnd::MapAnimator::AnimatedValue::Target);

        if (_lastAppMode == OAAppModeBrowseMap)
        {
            // For "follow-me" mode azimuth is also controlled
            if (_app.mapMode == OAMapModeFollow)
            {
                const auto azimuthAnimation = mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                                    OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                         OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                
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
                
                double duration = targetAnimation->getDuration() - targetAnimation->getTimePassed();
                mapView.animator->animateTargetTo(newTarget31,
                                                  duration,
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
                    mapView.animator->animateTargetTo(newTarget31,
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
                mapView.azimuth = direction;
            }
            CGPoint centerPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 1.5);
            centerPoint.x *= mapView.contentScaleFactor;
            centerPoint.y *= mapView.contentScaleFactor;
            
            // Convert point from screen to location
            OsmAnd::PointI bottomLocation;
            [mapView convert:centerPoint toLocation:&bottomLocation];
            
            OsmAnd::PointI targetCenter;
            targetCenter.x = newTarget31.x + mapView.target31.x - bottomLocation.x;
            targetCenter.y = newTarget31.y + mapView.target31.y - bottomLocation.y;

            mapView.target31 = targetCenter;
            //NSLog(@"targetCenter2 %d %d", targetCenter.x, targetCenter.y);
        }

        mapView.animator->resume();
    }
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
            [self updateMyLocationCourseProvider];
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
                [self showRouteGpxTrack];
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

        _hillshadeMapProvider.reset();

        _rasterOverlayMapProvider.reset();
        _rasterUnderlayMapProvider.reset();

        _obfMapObjectsProvider.reset();
        _mapPrimitivesProvider.reset();
        _mapPresentationEnvironment.reset();
        _mapPrimitiviser.reset();

        if (_mapObjectsSymbolsProvider)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProvider];
        _mapObjectsSymbolsProvider.reset();

        // Reset active GPX
        if (_mapObjectsSymbolsProviderGpx)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpx];
        _mapObjectsSymbolsProviderGpx.reset();

        // Reset temp gpx
        if (_mapObjectsSymbolsProviderGpxTemp)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxTemp];
        _mapObjectsSymbolsProviderGpxTemp.reset();

        // Reset route gpx
        if (_mapObjectsSymbolsProviderGpxRoute)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRoute];
        _mapObjectsSymbolsProviderGpxRoute.reset();

        // Reset currently recording gpx
        if (_mapObjectsSymbolsProviderGpxRec)
            [mapView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRec];
        _mapObjectsSymbolsProviderGpxRec.reset();

        if (_amenitySymbolsProvider)
        {
            [mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
            _amenitySymbolsProvider.reset();
        }

        [mapView resetProviderFor:kGpxLayerId];
        [mapView resetProviderFor:kGpxRouteLayerId];
        [mapView resetProviderFor:kGpxTempLayerId];
        [mapView resetProviderFor:kGpxRecLayerId];

        [mapView resetProviderFor:kHillshadeLayerId];
        [mapView resetProviderFor:kOverlayLayerId];
        [mapView resetProviderFor:kUnderlayLayerId];

        _gpxPrimitivesProvider.reset();
        _gpxPrimitivesProviderTemp.reset();
        _gpxPrimitivesProviderRoute.reset();
        _gpxPrimitivesProviderRec.reset();
        
        _gpxPresenterTemp.reset();
        _gpxPresenterRoute.reset();
        _gpxPresenterRec.reset();
        _gpxPresenter.reset();

        if (!_gpxDocFileTemp)
            _geoInfoDocsGpxTemp.clear();
        if (!_gpxDocFileRoute)
            _geoInfoDocsGpxRoute.clear();

        _geoInfoDocsGpxRec.clear();
        
        
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
            
            NSString *langId = [[NSLocale preferredLanguages] firstObject];
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
                
                NSString *appMode = [OAMapStyleSettings getAppModeByVariantTypeStr:lastMapSource.variant];
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

            if (_showPoiOnMap)
            {
                auto categoriesFilter = QHash<QString, QStringList>();
                if (_poiCategoryName && _poiTypeName) {
                    categoriesFilter.insert(QString::fromNSString(_poiCategoryName), QStringList(QString::fromNSString(_poiTypeName)));
                } else if (_poiCategoryName) {
                    categoriesFilter.insert(QString::fromNSString(_poiCategoryName), QStringList());
                }
                
                OsmAnd::ObfPoiSectionReader::VisitorFunction amenityFilter = ([self]
                                                (const std::shared_ptr<const OsmAnd::Amenity>& amenity)
                                                {
                                                    bool res = false;
                                                    
                                                    if (_poiFilterName)
                                                    {
                                                        NSString *category;
                                                        NSString *type;
                                                        const auto& decodedCategories = amenity->getDecodedCategories();
                                                        if (!decodedCategories.isEmpty())
                                                        {
                                                            const auto& entry = decodedCategories.first();
                                                            category = entry.category.toNSString();
                                                            type = entry.subcategory.toNSString();
                                                        }
                                                        
                                                        if (category && type)
                                                        {
                                                            OAPOIType *poiType = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:category name:type];
                                                            if (poiType && [poiType.filter isEqualToString:_poiFilterName])
                                                                res = true;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        res = true;
                                                    }
                                                    
                                                    if (res && _poiKeyword)
                                                    {
                                                        NSString *name = amenity->nativeName.toNSString();

                                                        NSString *nameLocalized;
                                                        const QString lang = (_prefLang ? QString::fromNSString(_prefLang) : QString::null);
                                                        for(const auto& entry : OsmAnd::rangeOf(amenity->localizedNames))
                                                        {
                                                            if (lang != QString::null && entry.key() == lang)
                                                                nameLocalized = entry.value().toNSString();
                                                        }
                                                        
                                                        if (_poiKeyword.length == 0 || [self beginWith:_poiKeyword text:nameLocalized] || [self beginWithAfterSpace:_poiKeyword text:nameLocalized] || [self beginWith:_poiKeyword text:name] || [self beginWithAfterSpace:_poiKeyword text:name])
                                                        {
                                                            res = true;
                                                        }
                                                        else
                                                        {
                                                            res = false;
                                                        }

                                                    }
                                                    
                                                    return res;
                                                });
                
                if (categoriesFilter.count() > 0)
                    _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(_app.resourcesManager->obfsCollection, &categoriesFilter, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.displayDensityFactor, 1.0)));
                else
                    _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(_app.resourcesManager->obfsCollection, nullptr, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.displayDensityFactor, 1.0)));

                [mapView addTiledSymbolsProvider:_amenitySymbolsProvider];
            }

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
            onlineMapTileProvider->setLocalCachePath(QString::fromNSString(_app.cachePath));
            _rasterMapProvider = onlineMapTileProvider;
            [mapView setProvider:_rasterMapProvider
                        forLayer:0];
            
            lastMapSource = [OAAppData defaults].lastMapSource;
            const auto resourceId = QString::fromNSString(lastMapSource.resourceId);
            const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
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
            
            NSString *langId = [[NSLocale preferredLanguages] firstObject];
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
        
        if (_gpxDocFileRoute)
            [self showRouteGpxTrack];

        if (_gpxDocFileTemp)
            [self showTempGpxTrack:_gpxDocFileTemp];
        else if ([OAAppSettings sharedManager].mapSettingShowRecordingTrack)
            [self showRecGpxTrack];
        
        if (_gpxRouter.gpx && !_gpxDocFileRoute)
        {
            [_gpxRouter.routeDoc buildRouteTrack];
            [self setGeoInfoDocsGpxRoute:_gpxRouter.routeDoc];
            [self setDocFileRoute:_gpxRouter.gpx.gpxFileName];
            
            [self showRouteGpxTrack];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildGpxInfoDocList];
            
            if (!_geoInfoDocsGpx.isEmpty())
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initRendererWithGpxTracks];
                });
        });
        
        
        if (_app.data.hillshade)
            [self doUpdateHillshade];

        if (_app.data.overlayMapSource)
            [self doUpdateOverlay];
        
        if (_app.data.underlayMapSource)
            [self doUpdateUnderlay];
        
        /*
        if (_testMarkersCollection != nullptr)
            [mapView removeKeyedSymbolsProvider:_testMarkersCollection];
        
        _testMarkersCollection = std::make_shared<OAMapMarkersCollection>();
        [mapView addKeyedSymbolsProvider:_testMarkersCollection];
         */

    }
}

- (void)showPoiOnMap:(NSString *)category type:(NSString *)type filter:(NSString *)filter keyword:(NSString *)keyword
{
    _showPoiOnMap = YES;
    _poiCategoryName = category;
    _poiFilterName = filter;
    _poiTypeName = type;
    _poiKeyword = keyword;
    _prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateCurrentMapSource];
    });
}

- (void)hidePoi
{
    if (!_showPoiOnMap)
        return;
    
    _showPoiOnMap = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateCurrentMapSource];
    });
}

- (BOOL)beginWithOrAfterSpace:(NSString *)str text:(NSString *)text
{
    return [self beginWith:str text:text] || [self beginWithAfterSpace:str text:text];
}

- (BOOL)beginWith:(NSString *)str text:(NSString *)text
{
    return [[text lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
}

- (BOOL)beginWithAfterSpace:(NSString *)str text:(NSString *)text
{
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0 || r.location + 1 >= text.length)
        return NO;
    
    NSString *s = [text substringFromIndex:r.location + 1];
    return [[s lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
}

- (void)doUpdateHillshade
{
    if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_Srtm])
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        
        _hillshadeMapProvider = std::make_shared<OAHillshadeMapLayerProvider>();
        [mapView setProvider:_hillshadeMapProvider forLayer:kHillshadeLayerId];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(kHillshadeOpacity);
        [mapView setMapLayerConfiguration:kHillshadeLayerId configuration:config forcedUpdate:NO];
    }
}

- (void)doUpdateOverlay
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if ([_app.data.overlayMapSource.name isEqualToString:@"sqlitedb"])
    {
        NSString *path = [[OAMapCreatorHelper sharedInstance].filesDir stringByAppendingPathComponent:_app.data.overlayMapSource.resourceId];
        
        const auto sqliteTileSourceMapProvider = std::make_shared<OASQLiteTileSourceMapLayerProvider>(QString::fromNSString(path));

        _rasterOverlayMapProvider = sqliteTileSourceMapProvider;
        [mapView setProvider:_rasterOverlayMapProvider forLayer:kOverlayLayerId];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(_app.data.overlayAlpha);
        [mapView setMapLayerConfiguration:kOverlayLayerId configuration:config forcedUpdate:NO];
    }
    else
    {
        const auto resourceId = QString::fromNSString(_app.data.overlayMapSource.resourceId);
        const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
        if (mapSourceResource)
        {
            const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(mapSourceResource->metadata)->sources;
            OALog(@"Overlay Map: Using online source from '%@' resource", mapSourceResource->id.toNSString());
            
            const auto onlineMapTileProvider = onlineTileSources->createProviderFor(QString::fromNSString(_app.data.overlayMapSource.variant));
            if (onlineMapTileProvider)
            {
                onlineMapTileProvider->setLocalCachePath(QString::fromNSString(_app.cachePath));
                _rasterOverlayMapProvider = onlineMapTileProvider;
                [mapView setProvider:_rasterOverlayMapProvider forLayer:kOverlayLayerId];
                
                OsmAnd::MapLayerConfiguration config;
                config.setOpacityFactor(_app.data.overlayAlpha);
                [mapView setMapLayerConfiguration:kOverlayLayerId configuration:config forcedUpdate:NO];
            }
        }
    }
}

- (void)doUpdateUnderlay
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if ([_app.data.underlayMapSource.name isEqualToString:@"sqlitedb"])
    {
        NSString *path = [[OAMapCreatorHelper sharedInstance].filesDir stringByAppendingPathComponent:_app.data.underlayMapSource.resourceId];
        
        const auto sqliteTileSourceMapProvider = std::make_shared<OASQLiteTileSourceMapLayerProvider>(QString::fromNSString(path));
        
        _rasterUnderlayMapProvider = sqliteTileSourceMapProvider;
        [mapView setProvider:_rasterUnderlayMapProvider forLayer:kUnderlayLayerId];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(1.0 - _app.data.underlayAlpha);
        [mapView setMapLayerConfiguration:kUnderlayLayerId configuration:config forcedUpdate:NO];
    }
    else
    {    const auto resourceId = QString::fromNSString(_app.data.underlayMapSource.resourceId);
        const auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
        if (mapSourceResource)
        {
            const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(mapSourceResource->metadata)->sources;
            OALog(@"Underlay Map: Using online source from '%@' resource", mapSourceResource->id.toNSString());
            
            const auto onlineMapTileProvider = onlineTileSources->createProviderFor(QString::fromNSString(_app.data.underlayMapSource.variant));
            if (onlineMapTileProvider)
            {
                onlineMapTileProvider->setLocalCachePath(QString::fromNSString(_app.cachePath));
                _rasterUnderlayMapProvider = onlineMapTileProvider;
                [mapView setProvider:_rasterUnderlayMapProvider forLayer:kUnderlayLayerId];
                
                OsmAnd::MapLayerConfiguration config;
                config.setOpacityFactor(1.0 - _app.data.underlayAlpha);
                [mapView setMapLayerConfiguration:kUnderlayLayerId configuration:config forcedUpdate:NO];
            }
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
            [mapView addKeyedSymbolsProvider:_favoritesMarkersCollection];
        else
            [mapView removeKeyedSymbolsProvider:_favoritesMarkersCollection];
    }
}

- (void)hideLayers
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    @synchronized(_rendererSync)
    {
        if ([_app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
            [mapView removeKeyedSymbolsProvider:_favoritesMarkersCollection];
    }
}

- (void)onOverlayLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isViewLoaded])
            return;
        
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;

        @synchronized(_rendererSync)
        {
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(_app.data.overlayAlpha);
            [mapView setMapLayerConfiguration:kOverlayLayerId configuration:config forcedUpdate:NO];
        }
    });
}

- (void)onHillshadeLayerChanged
{
    [self updateHillshadeLayer];
}

- (void)updateHillshadeLayer
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    @synchronized(_rendererSync)
    {
        if (_app.data.hillshade)
        {
            [self doUpdateHillshade];
            
        } else {
            [mapView resetProviderFor:kHillshadeLayerId];
            _hillshadeMapProvider.reset();
        }
    }
}

- (void)onOverlayLayerChanged
{
    [self updateOverlayLayer];
}

- (void)updateOverlayLayer
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    @synchronized(_rendererSync)
    {
        if (_app.data.overlayMapSource)
        {
            [self doUpdateOverlay];
        }
        else
        {
            [mapView resetProviderFor:kOverlayLayerId];
            _rasterOverlayMapProvider.reset();
        }
    }
}



- (void)onUnderlayLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isViewLoaded])
            return;
        
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        
        @synchronized(_rendererSync)
        {
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(1.0 - _app.data.underlayAlpha);
            [mapView setMapLayerConfiguration:0 configuration:config forcedUpdate:NO];
        }
    });
}

- (void)onUnderlayLayerChanged
{
    [self updateUnderlayLayer];
}

- (void)updateUnderlayLayer
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    @synchronized(_rendererSync)
    {
        if (_app.data.underlayMapSource)
        {
            [self doUpdateUnderlay];
        }
        else
        {
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(_app.data.underlayAlpha);
            [mapView setMapLayerConfiguration:1.0 configuration:config forcedUpdate:NO];

            [mapView resetProviderFor:kUnderlayLayerId];
            _rasterUnderlayMapProvider.reset();
        }
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

- (CGFloat)screensToFly:(Point31)position31
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    const auto lon1 = OsmAnd::Utilities::get31LongitudeX(position31.x);
    const auto lat1 = OsmAnd::Utilities::get31LatitudeY(position31.y);
    const auto lon2 = OsmAnd::Utilities::get31LongitudeX(mapView.target31.x);
    const auto lat2 = OsmAnd::Utilities::get31LatitudeY(mapView.target31.y);
    
    const auto distance = OsmAnd::Utilities::distance(lon1, lat1, lon2, lat2);
    CGFloat distanceInPixels = distance / mapView.currentPixelsToMetersScaleFactor;
    return distanceInPixels / ((DeviceScreenWidth + DeviceScreenHeight) / 2.0);
}

- (void)goToPosition:(Point31)position31
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;

    @synchronized(_rendererSync)
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kQuickAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            mapView.animator->resume();
        }
        else
        {
            [mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
        }
    }
}

- (void)goToPosition:(Point31)position31
             andZoom:(CGFloat)zoom
            animated:(BOOL)animated
{
    if (![self isViewLoaded])
        return;
    
    @synchronized(_rendererSync)
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        
        CGFloat z = [self normalizeZoom:zoom defaultZoom:mapView.zoom];
        
        CGFloat screensToFly = [self screensToFly:position31];
        
        _app.mapMode = OAMapModeFree;
        mapView.animator->pause();
        mapView.animator->cancelAllAnimations();
        
        if (animated && screensToFly <= kScreensToFlyWithAnimation)
        {
            mapView.animator->animateTargetTo([OANativeUtilities convertFromPoint31:position31],
                                              kQuickAnimationTime,
                                              OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                              kUserInteractionAnimationKey);
            mapView.animator->animateZoomTo(z,
                                            kQuickAnimationTime,
                                            OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                            kUserInteractionAnimationKey);
            mapView.animator->resume();
        }
        else
        {
            [mapView setTarget31:[OANativeUtilities convertFromPoint31:position31]];
            [mapView setZoom:z];
        }
    }
}

- (void)correctPosition:(Point31)targetPosition31
       originalCenter31:(Point31)originalCenter31
              leftInset:(CGFloat)leftInset
            bottomInset:(CGFloat)bottomInset
             centerBBox:(BOOL)centerBBox
               animated:(BOOL)animated
{
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
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
    [mapView convert:&targetPositionI toScreen:&targetPoint];
    
    OsmAnd::PointI newPositionI = mapView.target31;
    
    CGFloat targetY = DeviceScreenHeight - bottomInset - bottomTargetInset;
    
    CGPoint minPoint = CGPointMake(DeviceScreenWidth / 2.0, targetY);
    minPoint.x *= mapView.contentScaleFactor;
    minPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI minLocation;
    [mapView convert:minPoint toLocation:&minLocation];
    
    newPositionI.y = mapView.target31.y - (minLocation.y - targetPosition31.y);
    if (newPositionI.y < originalCenterI.y)
        newPositionI.y = originalCenterI.y;
    
    CGFloat targetX = leftInset + leftTargetInset;
    minPoint = CGPointMake(targetX, DeviceScreenHeight / 2.0);
    minPoint.x *= mapView.contentScaleFactor;
    minPoint.y *= mapView.contentScaleFactor;
    [mapView convert:minPoint toLocation:&minLocation];
    
    newPositionI.x = mapView.target31.x + (-minLocation.x + targetPosition31.x);
    if (newPositionI.x > originalCenterI.x)
        newPositionI.x = originalCenterI.x;
    
    Point31 newPosition31 = [OANativeUtilities convertFromPointI:newPositionI];
    [self goToPosition:newPosition31 animated:animated];
}

- (CGFloat)normalizeZoom:(CGFloat)zoom defaultZoom:(CGFloat)defaultZoom
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

- (void)showRouteGpxTrack
{
    @synchronized(_rendererSync)
    {
        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpxRoute)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRoute];
        _mapObjectsSymbolsProviderGpxRoute.reset();
        [rendererView resetProviderFor:kGpxRouteLayerId];
        
        _gpxPresenterRoute.reset(new OsmAnd::GeoInfoPresenter(_geoInfoDocsGpxRoute));
        
        if (_gpxPresenterRoute) {
            const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
            _gpxPrimitivesProviderRoute.reset(new OsmAnd::MapPrimitivesProvider(_gpxPresenterRoute->createMapObjectsProvider(), _mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
            
            _rasterMapProviderGpxRec.reset(new OsmAnd::MapRasterLayerProvider_Software(_gpxPrimitivesProviderRoute, false));
            [rendererView setProvider:_rasterMapProviderGpxRec forLayer:kGpxRouteLayerId];
            
            _mapObjectsSymbolsProviderGpxRoute.reset(new OsmAnd::MapObjectsSymbolsProvider(_gpxPrimitivesProviderRoute, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
            [rendererView addTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRoute];
        }
    }
}

- (void)hideRouteGpxTrack
{
    @synchronized(_rendererSync)
    {
        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpxRoute)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRoute];
        _mapObjectsSymbolsProviderGpxRoute.reset();
        
        [rendererView resetProviderFor:kGpxRouteLayerId];
        
        _gpxPrimitivesProviderRoute.reset();
        _geoInfoDocsGpxRoute.clear();
        _gpxPresenterRoute.reset();
        
        _gpxDocFileRoute = nil;
        
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void)showTempGpxTrack:(NSString *)fileName
{
    if (_recTrackShowing)
        [self hideRecGpxTrack];

    @synchronized(_rendererSync)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];

        OAAppSettings *settings = [OAAppSettings sharedManager];
        if ([settings.mapSettingVisibleGpx containsObject:fileName]) {
            _gpxDocFileTemp = nil;
            return;
        }
        
        _tempTrackShowing = YES;

        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (_mapObjectsSymbolsProviderGpxTemp)
                [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxTemp];
            _mapObjectsSymbolsProviderGpxTemp.reset();
            [rendererView resetProviderFor:kGpxTempLayerId];
            
            if (![_gpxDocFileTemp isEqualToString:fileName] || _geoInfoDocsGpxTemp.isEmpty()) {
                _geoInfoDocsGpxTemp.clear();
                _gpxDocFileTemp = [fileName copy];
                _geoInfoDocsGpxTemp.append(OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path)));
            }
            _gpxPresenterTemp.reset(new OsmAnd::GeoInfoPresenter(_geoInfoDocsGpxTemp));
            
            //dispatch_async(dispatch_get_main_queue(), ^{
                if (_gpxPresenterTemp) {
                    const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
                    _gpxPrimitivesProviderTemp.reset(new OsmAnd::MapPrimitivesProvider(_gpxPresenterTemp->createMapObjectsProvider(), _mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
                    
                    _rasterMapProviderGpxTemp.reset(new OsmAnd::MapRasterLayerProvider_Software(_gpxPrimitivesProviderTemp, false));
                    [rendererView setProvider:_rasterMapProviderGpxTemp forLayer:kGpxTempLayerId];
                    
                    _mapObjectsSymbolsProviderGpxTemp.reset(new OsmAnd::MapObjectsSymbolsProvider(_gpxPrimitivesProviderTemp, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
                    [rendererView addTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxTemp];
                }
            //});
        //});
    }
}

- (void)hideTempGpxTrack
{
    @synchronized(_rendererSync)
    {
        _tempTrackShowing = NO;

        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpxTemp)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxTemp];
        _mapObjectsSymbolsProviderGpxTemp.reset();
        
        [rendererView resetProviderFor:kGpxTempLayerId];
        
        _gpxPrimitivesProviderTemp.reset();
        _geoInfoDocsGpxTemp.clear();
        _gpxPresenterTemp.reset();
        _gpxDocFileTemp = nil;
    }
}

- (void)showRecGpxTrack
{
    if (_tempTrackShowing)
        [self hideTempGpxTrack];
    
    @synchronized(_rendererSync)
    {
        
        OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
        
        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (_mapObjectsSymbolsProviderGpxRec)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRec];
        _mapObjectsSymbolsProviderGpxRec.reset();
        [rendererView resetProviderFor:kGpxRecLayerId];
        
        if (![helper hasData])
            return;
        
        [[OASavingTrackHelper sharedInstance] runSyncBlock:^{
            
            const auto& doc = [[OASavingTrackHelper sharedInstance].currentTrack getDocument];
            
            if (doc != nullptr)
            {
                _recTrackShowing = YES;
                
                _geoInfoDocsGpxRec.clear();
                _geoInfoDocsGpxRec << doc;
                
                _gpxPresenterRec.reset(new OsmAnd::GeoInfoPresenter(_geoInfoDocsGpxRec));
                
                if (_gpxPresenterRec)
                {
                    const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
                    _gpxPrimitivesProviderRec.reset(new OsmAnd::MapPrimitivesProvider(_gpxPresenterRec->createMapObjectsProvider(), _mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
                    
                    _rasterMapProviderGpxRec.reset(new OsmAnd::MapRasterLayerProvider_Software(_gpxPrimitivesProviderRec, false));
                    
                    //dispatch_async(dispatch_get_main_queue(), ^{
                    [rendererView setProvider:_rasterMapProviderGpxRec forLayer:kGpxRecLayerId];
                    
                    _mapObjectsSymbolsProviderGpxRec.reset(new OsmAnd::MapObjectsSymbolsProvider(_gpxPrimitivesProviderRec, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
                    [rendererView addTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRec];
                    //});
                }
            }
        }];
        //});
        
    }
}

- (void)hideRecGpxTrack
{
    @synchronized(_rendererSync)
    {
        _recTrackShowing = NO;

        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpxRec)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpxRec];
        _mapObjectsSymbolsProviderGpxRec.reset();
        
        [rendererView resetProviderFor:kGpxRecLayerId];
        
        _gpxPrimitivesProviderRec.reset();
        _geoInfoDocsGpxRec.clear();
        _gpxPresenterRec.reset();
    }
}


- (void)keepTempGpxTrackVisible
{
    if (!_gpxDocFileTemp || _geoInfoDocsGpxTemp.isEmpty())
        return;

    std::shared_ptr<const OsmAnd::GeoInfoDocument> doc = _geoInfoDocsGpxTemp.first();
    if (!_geoInfoDocsGpx.contains(doc)) {
        
        _geoInfoDocsGpx.append(doc);
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpxDocFileTemp];
        _geoInfoDocsGpxPaths = [_geoInfoDocsGpxPaths arrayByAddingObjectsFromArray:@[path]];
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        [settings showGpx:_gpxDocFileTemp];
        
        if (!_geoInfoDocsGpx.isEmpty())
            [self initRendererWithGpxTracks];
    }
}

-(void)buildGpxInfoDocList
{
    NSMutableArray *paths = [NSMutableArray array];
    _geoInfoDocsGpx.clear();
    OAAppSettings *settings = [OAAppSettings sharedManager];
    for (NSString *fileName in settings.mapSettingVisibleGpx)
    {
        if (_gpxDocFileRoute && [fileName isEqualToString:_gpxDocFileRoute])
            continue;
        
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            _geoInfoDocsGpx.append(OsmAnd::GpxDocument::loadFrom(QString::fromNSString(path)));
            [paths addObject:path];
        }
        else
        {
            [settings hideGpx:fileName];
        }
    }
    _geoInfoDocsGpxPaths = [NSArray arrayWithArray:paths];
}

- (BOOL)hasFavoriteAt:(CLLocationCoordinate2D)location
{
    for (const auto& fav : _favoritesMarkersCollection->getMarkers())
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

- (BOOL)hasWptAt:(CLLocationCoordinate2D)location
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
    for (const auto& doc : _geoInfoDocsGpx)
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
    
    if (!_geoInfoDocsGpxTemp.isEmpty())
    {
        const auto& doc = _geoInfoDocsGpxTemp.first();
        
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
    
    if (!_geoInfoDocsGpxRoute.isEmpty())
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

- (BOOL)findWpt:(CLLocationCoordinate2D)location
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
    for (const auto& doc : _geoInfoDocsGpx)
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
                
                self.foundWptDocPath = _geoInfoDocsGpxPaths[i];
                
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
    
    if (!_geoInfoDocsGpxTemp.isEmpty())
    {
        const auto& doc = _geoInfoDocsGpxTemp.first();
    
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

    if (!_geoInfoDocsGpxRoute.isEmpty())
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
        auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpxRoute.first());
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
        for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
        {
            if ([_geoInfoDocsGpxPaths[i] isEqualToString:self.foundWptDocPath])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpx[i]);
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
        for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
        {
            if ([_geoInfoDocsGpxPaths[i] isEqualToString:self.foundWptDocPath])
            {
                const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_geoInfoDocsGpx[i]);
                
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
        for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
        {
            if ([_geoInfoDocsGpxPaths[i] isEqualToString:gpxFileName])
            {
                auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpx[i]);
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
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpxTemp.first());
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
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpxRoute.first());
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
    for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
    {
        if ([_geoInfoDocsGpxPaths[i] isEqualToString:docPath])
        {
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_geoInfoDocsGpx[i]);
         
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
    
    if (!_geoInfoDocsGpxTemp.isEmpty())
    {
        const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_geoInfoDocsGpxTemp.first());
        
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
    
    for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
    {
        if ([_geoInfoDocsGpxPaths[i] isEqualToString:docPath])
        {
            auto docGeoInfo = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpx[i]);
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
    
    if (!_geoInfoDocsGpxTemp.isEmpty())
    {
        const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(_geoInfoDocsGpxTemp.first());
        
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
    
    for (int i = 0; i < _geoInfoDocsGpxPaths.count; i++)
    {
        if ([_geoInfoDocsGpxPaths[i] isEqualToString:docPath])
        {
            auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpx[i]);
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

    if (!_geoInfoDocsGpxTemp.isEmpty())
    {
        auto doc = std::const_pointer_cast<OsmAnd::GeoInfoDocument>(_geoInfoDocsGpxTemp.first());
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

-(void)initRendererWithGpxTracks
{
    @synchronized(_rendererSync)
    {
        if (_geoInfoDocsGpx.isEmpty())
            return;
        
        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpx)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpx];
        _mapObjectsSymbolsProviderGpx.reset();
        [rendererView resetProviderFor:kGpxLayerId];
        
        _gpxPresenter.reset(new OsmAnd::GeoInfoPresenter(_geoInfoDocsGpx));
        
        if (_gpxPresenter) {
            const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
            _gpxPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_gpxPresenter->createMapObjectsProvider(), _mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
            
            _rasterMapProviderGpx.reset(new OsmAnd::MapRasterLayerProvider_Software(_gpxPrimitivesProvider, false));
            [rendererView setProvider:_rasterMapProviderGpx forLayer:kGpxLayerId];
            
            _mapObjectsSymbolsProviderGpx.reset(new OsmAnd::MapObjectsSymbolsProvider(_gpxPrimitivesProvider, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
            [rendererView addTiledSymbolsProvider:_mapObjectsSymbolsProviderGpx];
        }
    }
}

- (void)resetGpxTracks
{
    @synchronized(_rendererSync)
    {
        OAMapRendererView* rendererView = (OAMapRendererView*)self.view;
        
        if (_mapObjectsSymbolsProviderGpx)
            [rendererView removeTiledSymbolsProvider:_mapObjectsSymbolsProviderGpx];
        _mapObjectsSymbolsProviderGpx.reset();
        
        [rendererView resetProviderFor:kGpxLayerId];
        
        _gpxPrimitivesProvider.reset();
        _geoInfoDocsGpx.clear();
        _gpxPresenter.reset();
        _gpxDocFileTemp = nil;
    }
}

- (void)refreshGpxTracks
{
    [self resetGpxTracks];
    [self buildGpxInfoDocList];
    [self initRendererWithGpxTracks];
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

- (void)addDestinationPin:(NSString *)markerResourceName color:(UIColor *)color latitude:(double)latitude longitude:(double)longitude
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    OsmAnd::FColorRGB col(r, g, b);

    const OsmAnd::LatLon latLon(latitude, longitude);

    OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(-207000)
    .setIsHidden(false)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:markerResourceName])
    .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
    .setPinIconAlignment((OsmAnd::MapMarker::PinIconAlignment)(OsmAnd::MapMarker::Top | OsmAnd::MapMarker::CenterHorizontal))
    .setAccuracyCircleBaseColor(col)
    .buildAndAddToCollection(_destinationPinMarkersCollection);
}

- (void)removeDestinationPin:(double)latitude longitude:(double)longitude;
{
    for (const auto &marker : _destinationPinMarkersCollection->getMarkers())
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
        if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:longitude])
        {
            _destinationPinMarkersCollection->removeMarker(marker);
            break;
        }
    }
}

-(BOOL)isMyLocationVisible
{
    OAMapRendererView* renderView = (OAMapRendererView*)self.view;
    CLLocation* myLocation = _app.locationServices.lastKnownLocation;
    OsmAnd::PointI myLocation31(OsmAnd::Utilities::get31TileNumberX(myLocation.coordinate.longitude),
                                OsmAnd::Utilities::get31TileNumberY(myLocation.coordinate.latitude));
    
    OsmAnd::AreaI visibleArea = [renderView getVisibleBBox31];
    
    return (visibleArea.topLeft.x < myLocation31.x && visibleArea.topLeft.y < myLocation31.y && visibleArea.bottomRight.x > myLocation31.x && visibleArea.bottomRight.y > myLocation31.y);
}

@end
