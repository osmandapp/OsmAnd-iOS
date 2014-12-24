//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"
#import "OAAppSettings.h"

#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

#import "OAAutoObserverProxy.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"

#import "OsmAndApp.h"

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


#define kElevationMinAngle 30.0f
#define kMapModePositionTrackingDefaultZoom 15.0f
#define kMapModePositionTrackingDefaultElevationAngle 90.0f
#define kMapModeFollowDefaultZoom 18.0f
#define kMapModeFollowDefaultElevationAngle kElevationMinAngle
#define kOneSecondAnimatonTime 1.0f
#define kLocationServicesAnimationKey reinterpret_cast<OsmAnd::MapAnimator::Key>(2)

#if defined(OSMAND_IOS_DEV)
typedef NS_ENUM(NSInteger, OAVisualMetricsMode)
{
    OAVisualMetricsModeOff = 0,
    OAVisualMetricsModeBinaryMapData,
    OAVisualMetricsModeBinaryMapPrimitives,
    OAVisualMetricsModeBinaryMapRasterize
};
#endif // defined(OSMAND_IOS_DEV)



@interface OAMapStyle : NSObject
    @property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@end
@implementation OAMapStyle
@end

@interface OAMapStylePreset : NSObject
    @property OAMapSource* mapSource;
    @property std::shared_ptr<const OsmAnd::MapStylePreset> mapStylePreset;
    @property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@end
@implementation OAMapStylePreset
@end







@interface OAMapSettingsViewController ()

@property NSArray* tableData;
@property OsmAndAppInstance app;

@property (weak, nonatomic) IBOutlet OAMapRendererView *mapView;

@property(readonly) OAObservable* stateObservable;
@property(readonly) OAObservable* settingsObservable;
@property(readonly) OAObservable* azimuthObservable;
@property(readonly) OAObservable* zoomObservable;
@property(readonly) OAObservable* mapObservable;
@property(readonly) OAObservable* framePreparedObservable;


@property(readonly) CGFloat displayDensityFactor;

#if defined(OSMAND_IOS_DEV)
@property(nonatomic) BOOL hideStaticSymbols;
@property(nonatomic) OAVisualMetricsMode visualMetricsMode;

@property(nonatomic) BOOL forceDisplayDensityFactor;
@property(nonatomic) CGFloat forcedDisplayDensityFactor;
#endif // defined(OSMAND_IOS_DEV)

@end

@implementation OAMapSettingsViewController

    NSObject* _rendererSync;
    BOOL _mapSourceInvalidated;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _appModeObserver;

    OAAutoObserverProxy* _locationServicesStatusObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;

    OAAutoObserverProxy* _stateObserver;
    OAAutoObserverProxy* _settingsObserver;
    OAAutoObserverProxy* _framePreparedObserver;

    OAAutoObserverProxy* _layersConfigurationObserver;
    OAAppMode _lastAppMode;

    OAAutoObserverProxy* _mapModeObserver;
    OAMapMode _lastMapMode;

    // Favorites presenter
    std::shared_ptr<OsmAnd::FavoriteLocationsPresenter> _favoritesPresenter;
    // Current provider of raster map
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;
    std::shared_ptr<OsmAnd::MapPresentationEnvironment> _mapPresentationEnvironment;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _mapPrimitiviser;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;

    // Offline-specific providers & resources
    std::shared_ptr<OsmAnd::ObfMapObjectsProvider> _obfMapObjectsProvider;

    bool _lastPositionTrackStateCaptured;
float _lastAzimuthInPositionTrack;

-(id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    
    // LoadView
    NSLog(@"Creating Map Renderer view...");

    // Inflate map renderer view
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.contentScaleFactor = [[UIScreen mainScreen] scale];
    [_stateObserver observe:self.mapView.stateObservable];
    [_settingsObserver observe:self.mapView.settingsObservable];
    [_framePreparedObserver observe:self.mapView.framePreparedObservable];
    
    // Update layers
    [self updateLayers];
    //
    
    // Tell view to create context
    self.mapView.userInteractionEnabled = YES;
    self.mapView.multipleTouchEnabled = YES;
    [self.mapView createContext];
    
    // Adjust map-view target, zoom, azimuth and elevation angle to match last viewed
    self.mapView.target31 = OsmAnd::PointI(_app.data.mapLastViewedState.target31.x,
                                      _app.data.mapLastViewedState.target31.y);
    self.mapView.zoom = _app.data.mapLastViewedState.zoom;
    self.mapView.azimuth = _app.data.mapLastViewedState.azimuth;
    self.mapView.elevationAngle = _app.data.mapLastViewedState.elevationAngle;
    
    // Mark that map source is no longer valid
    _mapSourceInvalidated = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)commonInit {
    self.app = [OsmAndApp instance];
    _rendererSync = [[NSObject alloc] init];
    
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    
    self.app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
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
    
    
    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];

    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    _lastPositionTrackStateCaptured = false;
    
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


-(void)onLastMapSourceChanged {
    NSLog(@"onLastMapSourceChanged_Event");
}
- (void)onLocalResourcesChanged:(const QList< QString >&)ids
{
    NSLog(@"onLocalResourcesChanged_Event");
}
-(void)onAppModeChanged {
    NSLog(@"onAppModeChanged_Event");
}
-(void)onLocationServicesStatusChanged {
    NSLog(@"onLocationServicesStatusChanged_Event");
}
-(void)onLocationServicesUpdate {
//    NSLog(@"onLocationServicesUpdate");
}
- (void)onMapRendererStateChanged:(id)observer withKey:(id)key {

    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.mapView;
    
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
            [_mapObservable notifyEventWithKey:nil value1:[NSNumber numberWithInt:newTarget31.x] value2:[NSNumber numberWithInt:newTarget31.y]];
            break;
    }
    
    [_stateObservable notifyEventWithKey:key];
    
    
}
- (void)onMapRendererSettingsChanged:(id)observer withKey:(id)key {
    NSLog(@"onMapRendererSettingsChanged_Event");
}
- (void)onLayersConfigurationChanged {
    NSLog(@"onLayersConfigurationChanged_Event");
}
- (void)onMapRendererFramePrepared {
    [_framePreparedObservable notifyEvent];
}
- (void)applicationDidEnterBackground:(UIApplication*)application {
    NSLog(@"applicationDidEnterBackground_Event");
}
- (void)applicationWillEnterForeground:(UIApplication*)application {
    NSLog(@"applicationWillEnterForeground_Event");
}


- (void)updateLayers
{
    if (![self isViewLoaded])
        return;
    
    @synchronized(_rendererSync)
    {
        if ([_app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
            [self.mapView addKeyedSymbolsProvider:_favoritesPresenter];
        else
            [self.mapView removeKeyedSymbolsProvider:_favoritesPresenter];
    }
}






- (void)viewWillAppear:(BOOL)animated
{
    // Resume rendering
    [self.mapView resumeRendering];
    
    // Update map source (if needed)
    if (_mapSourceInvalidated)
    {
        //[self updateCurrentMapSource];
        _mapSourceInvalidated = NO;
    }

}




- (void)updateCurrentMapSource
{
    if (![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = self.mapView;
    
    @synchronized(_rendererSync)
    {
        const auto screenTileSize = 256 * self.displayDensityFactor;
        const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.displayDensityFactor);
        NSLog(@"Screen tile size %fpx, raster tile size %dpx", screenTileSize, rasterTileSize);
        
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
            NSLog(@"Using '%@' style from '%@' resource", unresolvedMapStyle->name.toNSString(), mapSourceResource->id.toNSString());
            
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
                NSLog(@"Using '%@' variant of style", lastMapSource.variant);
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
            NSLog(@"Using '%@' online source from '%@' resource", lastMapSource.variant, mapSourceResource->id.toNSString());
            
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








-(void)setupView {
    [self.mapTypeScrollView setContentSize:CGSizeMake(404, 70)];
    
    [self setupMapTypeButtons:self.app.data.lastMapSource.type];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupTableData];
}

-(void)setupMapTypeButtons:(int)selectedMapType {

    UIColor* buttonColor = [UIColor colorWithRed:83.0/255.0 green:109.0/255.0 blue:254.0/255.0 alpha:1.0];
    
    self.mapTypeButtonView.layer.cornerRadius = 5;
    self.mapTypeButtonCar.layer.cornerRadius = 5;
    self.mapTypeButtonWalk.layer.cornerRadius = 5;
    self.mapTypeButtonBike.layer.cornerRadius = 5;

    [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike.png"] forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonCar setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonBike setTitleColor:buttonColor forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonCar setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonWalk setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonBike setBackgroundColor:[UIColor clearColor]];
    
    self.mapTypeButtonView.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonView.layer.borderWidth = 1;
    self.mapTypeButtonCar.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonCar.layer.borderWidth = 1;
    self.mapTypeButtonWalk.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonWalk.layer.borderWidth = 1;
    self.mapTypeButtonBike.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonBike.layer.borderWidth = 1;
    
    switch (selectedMapType) {
        case 0:
            [self.mapTypeButtonView setBackgroundColor:buttonColor];
            [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 1:
            [self.mapTypeButtonCar setBackgroundColor:buttonColor];
            [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonCar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 2:
            [self.mapTypeButtonWalk setBackgroundColor:buttonColor];
            [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonWalk setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 3:
            [self.mapTypeButtonBike setBackgroundColor:buttonColor];
            [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonBike setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

-(void)setupTableData {
    self.tableData = @[@{@"groupName": @"Show on map",
                         @"cells": @[
                                 @{@"name": @"POI",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"GPX",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Favorite",
                                   @"value": @"",
                                   @"type": @"OASwitchCell"},
                                 @{@"name": @"Transport",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}
                                 ]
                         },
                       @{@"groupName": @"Map type",
                         @"cells": @[
                                 @{@"name": @"Map type",
                                   @"value": @"UniRS",
                                   @"type": @"OASettingsCell"}
                                 ],
                         },
                       @{@"groupName": @"Map style",
                         @"cells": @[
                                 @{@"name": @"Details",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Routes",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"},
                                 @{@"name": @"Other",
                                   @"value": @"",
                                   @"type": @"OASettingsCell"}

                                 ],
                         }
                       ];
}

- (IBAction)changeMapTypeButtonClicked:(id)sender {
    int type = ((UIButton*)sender).tag;
    [self setupMapTypeButtons:type];
    
    
    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = self.app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));
    NSString* resourceId = resource->id.toNSString();
    
    // Get the style
    const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
    OAMapStyle* mapStyleItem = [[OAMapStyle alloc] init];
    mapStyleItem.mapStyle = mapStyle;
    const auto& presets = self.app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
    
    OsmAnd::MapStylePreset::Type selectedType = [OAMapSettingsViewController typeToMapStyle:type];

    for(const auto& preset : presets)
    {
        if (preset->type != selectedType)
            continue;
        OAMapStylePreset* item = [[OAMapStylePreset alloc] init];
        item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                    andVariant:preset->name.toNSString()];
        item.mapStylePreset = preset;
        item.mapStyle = mapStyle;
        
        _app.data.lastMapSource = item.mapSource;
    }
    
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"groupName"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"cells"]) count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];

    UITableViewCell* outCell = nil;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[data objectForKey:@"type"]  owner:self options:nil];
    if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"]) {
        OASettingsTableViewCell* cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.descriptionView setText: [data objectForKey:@"value"]];
        }
        outCell = cell;
    } else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"]) {
        OASwitchTableViewCell* cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            [cell.textView setText: [data objectForKey:@"name"]];
        }
        outCell = cell;
    }
    
    return outCell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}


#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
    
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

+(OsmAnd::MapStylePreset::Type)typeToMapStyle:(int)type {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if (type == 1) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if (type == 2) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if (type == 3) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(OsmAnd::MapStylePreset::Type)variantToMapStyle:(NSString*)variant {
    OsmAnd::MapStylePreset::Type mapStyle = OsmAnd::MapStylePreset::Type::General;
    if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Car;
    } else if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Pedestrian;
    } else if ([variant isEqualToString:@""]) {
        mapStyle = OsmAnd::MapStylePreset::Type::Bicycle;
    }
    return mapStyle;
}

+(int)mapStyleToType:(OsmAnd::MapStylePreset::Type)mapStyle {
    int type = 0;
    if (mapStyle == OsmAnd::MapStylePreset::Type::Car) {
        type = 1;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Pedestrian) {
        type = 2;
    } else if (mapStyle == OsmAnd::MapStylePreset::Type::Bicycle) {
        type = 3;
    }
    return type;
}


        
@end
