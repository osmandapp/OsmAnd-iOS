//
//  OAWeatherContourLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherContourLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OAWeatherHelper.h"
#import "OAMapRendererEnvironment.h"
#import "OAMapStyleSettings.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherToolbar.h"
#import "OAMapLayers.h"
#import "OAPluginsHelper.h"
#import "OAAppData.h"
#import "OAObservable.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/GeoTileObjectsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>

@implementation OAWeatherContourLayer
{
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _resourcesManager;
    std::shared_ptr<OsmAnd::MapPrimitiviser> _primitiviser;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProvider;
    std::shared_ptr<OsmAnd::GeoTileObjectsProvider> _geoTileObjectsProvider;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _mapPrimitivesProvider;
    
    OAWeatherHelper *_weatherHelper;
    OAMapStyleSettings *_styleSettings;
    OAAutoObserverProxy *_weatherToolbarStateChangeObservable;
    BOOL _needsSettingsForToolbar;
    OAAutoObserverProxy* _weatherChangeObserver;
    OAAutoObserverProxy* _weatherUseOfflineDataChangeObserver;
    OAAutoObserverProxy* _alphaChangeObserver;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    
    OsmAnd::BandIndex _cachedBand;
    int64_t _cachedDateTime;
    
    NSDate *_pendingDate;
    OsmAnd::BandIndex _pendingBand;
    NSTimer *_initProvidersTimer;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex date:(NSDate *)date
{
    self = [super initWithMapViewController:mapViewController layerIndex:layerIndex];
    if (self)
    {
        _date = date;
    }
    return self;
}

- (NSString *) layerId
{
    return kWeatherContourMapLayerId;
}

- (void) initLayer
{
    _resourcesManager = self.app.resourcesManager->getWeatherResourcesManager();
    _weatherHelper = [OAWeatherHelper sharedInstance];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    
    _cachedBand = -1;
    _cachedDateTime = 0;
    
    _pendingDate = nil;
    _pendingBand = -1;
    _initProvidersTimer = nil;
    
    _weatherToolbarStateChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherToolbarStateChanged)
                                                                      andObserve:[OARootViewController instance].mapPanel.weatherToolbarStateChangeObservable];
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    _weatherUseOfflineDataChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherLayerChanged)
                                                                      andObserve:self.app.data.weatherUseOfflineDataChangeObservable];
    _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onLayerAlphaChanged)
                                                      andObserve:self.app.data.contoursAlphaChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onWeatherLayerChanged)]];
}

- (void) deinitLayer
{
    if (_weatherToolbarStateChangeObservable)
    {
        [_weatherToolbarStateChangeObservable detach];
        _weatherToolbarStateChangeObservable = nil;
    }
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
    }
    if (_weatherUseOfflineDataChangeObserver)
    {
        [_weatherUseOfflineDataChangeObserver detach];
        _weatherUseOfflineDataChangeObserver = nil;
    }
    if (_alphaChangeObserver)
    {
        [_alphaChangeObserver detach];
        _alphaChangeObserver = nil;
    }
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];

    [_layerChangeObservers removeAllObjects];
}

- (void) resetLayer
{
    [self deinitProviders];
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    if ([[OAPluginsHelper getPlugin:OAWeatherPlugin.class] isEnabled])
    {
        NSString *parameterName = self.app.data.contourName;
        OsmAnd::BandIndex band = WEATHER_BAND_NOTHING;
        
        OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:WEATHER_TEMP_CONTOUR_LINES_ATTR];
        OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:WEATHER_PRESSURE_CONTOURS_LINES_ATTR];
        OAMapStyleParameter *cloudContourLinesParam = [_styleSettings getParameter:WEATHER_CLOUD_CONTOURS_LINES_ATTR];
        OAMapStyleParameter *windContourLinesParam = [_styleSettings getParameter:WEATHER_WIND_CONTOURS_LINES_ATTR];
        OAMapStyleParameter *precipContourLinesParam = [_styleSettings getParameter:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR];
        
        if (tempContourLinesParam && [parameterName isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
        {
            band = WEATHER_BAND_TEMPERATURE;
        }
        else if (pressureContourLinesParam && [parameterName isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
        {
            band = WEATHER_BAND_PRESSURE;
        }
        else if (cloudContourLinesParam && [parameterName isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
        {
            band = WEATHER_BAND_CLOUD;
        }
        else if (windContourLinesParam && [parameterName isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
        {
            band = WEATHER_BAND_WIND_SPEED;
        }
        else if (precipContourLinesParam && [parameterName isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
        {
            band = WEATHER_BAND_PRECIPITATION;
        }
        
        BOOL needUpdateStyleSettings = (tempContourLinesParam && ![tempContourLinesParam.value isEqualToString:@"true"] && band == WEATHER_BAND_TEMPERATURE)
        || (pressureContourLinesParam && ![pressureContourLinesParam.value isEqualToString:@"true"] && band == WEATHER_BAND_PRESSURE)
        || (cloudContourLinesParam && ![cloudContourLinesParam.value isEqualToString:@"true"] && band == WEATHER_BAND_CLOUD)
        || (windContourLinesParam && ![windContourLinesParam.value isEqualToString:@"true"] && band == WEATHER_BAND_WIND_SPEED)
        || (precipContourLinesParam && ![precipContourLinesParam.value isEqualToString:@"true"] && band == WEATHER_BAND_PRECIPITATION);
        
        if (needUpdateStyleSettings)
        {
            [_styleSettings setWeatherContourLinesEnabled:YES weatherContourLinesAttr:parameterName];
            return NO;
        }
        else if ([_styleSettings isAnyWeatherContourLinesEnabled] && band == WEATHER_BAND_NOTHING)
        {
            [_styleSettings setWeatherContourLinesEnabled:NO weatherContourLinesAttr:parameterName];
            return NO;
        }
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(self.app.data.contoursAlpha);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        
        if (!self.app.data.weather && !_needsSettingsForToolbar)
            return NO;
        if (band == WEATHER_BAND_TEMPERATURE
            || band == WEATHER_BAND_PRESSURE
            || band == WEATHER_BAND_CLOUD
            || band == WEATHER_BAND_WIND_SPEED
            || band == WEATHER_BAND_PRECIPITATION)
        {
            [self initProviders:_date band:band];
            return YES;
        }
    }
    return NO;
}

- (void) initProviders:(NSDate *)date band:(OsmAnd::BandIndex)band
{
    _pendingDate = date;
    _pendingBand = band;
    
    if (_initProvidersTimer)
    {
        [_initProvidersTimer invalidate];
    }
    
    _initProvidersTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                          target:self
                                                        selector:@selector(executeInitProviders)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void) executeInitProviders
{
    if (!_pendingDate)
        return;
        
    NSDate *date = _pendingDate;
    OsmAnd::BandIndex band = _pendingBand;
    
    _pendingDate = nil;
    _pendingBand = -1;
    _initProvidersTimer = nil;
    
    NSTimeInterval timeInterval = date.timeIntervalSince1970;
    NSTimeInterval quantizationInterval = 3600.0;
    
    if ([self.app.data.weatherSource isEqualToString:@"ecmwf"])
    {
        quantizationInterval = 3600.0 * 3;
    }
    
    NSTimeInterval flooredTimeInterval = floor(timeInterval / quantizationInterval) * quantizationInterval;
    int64_t dateTime = flooredTimeInterval * 1000;
    
    BOOL needRecreate = (_geoTileObjectsProvider == nullptr || 
                        _mapPrimitivesProvider == nullptr || 
                        _mapObjectsSymbolsProvider == nullptr || 
                        _rasterMapProvider == nullptr ||
                        _cachedBand != band ||
                        dateTime != _cachedDateTime);
    
    if (needRecreate)
    {
        [self deinitProviders];
        
        OAMapRendererEnvironment *env = self.mapViewController.mapRendererEnv;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        int cacheSize = (screenSize.width * 2 / _resourcesManager->getTileSize()) * (screenSize.height * 2 / _resourcesManager->getTileSize());
        int rasterTileSize = (int) (_resourcesManager->getTileSize() * _resourcesManager->getDensityFactor());
        
        _geoTileObjectsProvider = std::make_shared<OsmAnd::GeoTileObjectsProvider>(_resourcesManager, dateTime, band, self.app.data.weatherUseOfflineData, cacheSize);
        _mapPrimitivesProvider = std::make_shared<OsmAnd::MapPrimitivesProvider>(
            _geoTileObjectsProvider,
            env.mapPrimitiviser,
            rasterTileSize);
        
        _mapObjectsSymbolsProvider = std::make_shared<OsmAnd::MapObjectsSymbolsProvider>(
            _mapPrimitivesProvider, rasterTileSize, nullptr, true);
        self.mapView.renderer->addSymbolsProvider(_mapObjectsSymbolsProvider);
        
        _rasterMapProvider = std::make_shared<OsmAnd::MapRasterLayerProvider_Software>(_mapPrimitivesProvider, false, true);
        self.mapView.renderer->setMapLayerProvider(self.layerIndex, _rasterMapProvider);
        
        _cachedBand = band;
        _cachedDateTime = dateTime;
    }
}

- (void) deinitProviders
{
    self.mapView.renderer->resetMapLayerProvider(self.layerIndex);
    if (_mapObjectsSymbolsProvider)
        self.mapView.renderer->removeSymbolsProvider(_mapObjectsSymbolsProvider);
    
    _mapObjectsSymbolsProvider = nullptr;
    _mapPrimitivesProvider = nullptr;
    _geoTileObjectsProvider = nullptr;
    _rasterMapProvider = nullptr;
    
    _cachedBand = -1;
    _cachedDateTime = 0;
    
    if (_initProvidersTimer)
    {
        [_initProvidersTimer invalidate];
        _initProvidersTimer = nil;
    }
    _pendingDate = nil;
    _pendingBand = -1;
}

- (void)onWeatherToolbarStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needsSettingsForToolbar = [[OARootViewController instance].mapPanel.hudViewController needsSettingsForWeatherToolbar];
        if (_needsSettingsForToolbar != needsSettingsForToolbar)
        {
            _date = self.mapViewController.mapLayers.weatherDate;
            _needsSettingsForToolbar = needsSettingsForToolbar;
            [self updateWeatherLayer];
        }
    });
}

- (void)onLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(self.app.data.contoursAlpha);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

- (void) onWeatherChanged
{
    [self updateWeatherLayer];
}

- (void) updateDate:(NSDate *)date
{
    _date = date;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) setDateTime:(NSTimeInterval)dateTime
{
    _date = [NSDate dateWithTimeIntervalSince1970:dateTime];
}

- (void) onWeatherLayerChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) updateWeatherLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            if (![self updateLayer])
                [self deinitProviders];
        }];
    });
}

@end
