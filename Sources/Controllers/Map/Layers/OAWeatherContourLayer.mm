//
//  OAWeatherContourLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherContourLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OAWeatherHelper.h"
#import "OAMapRendererEnvironment.h"
#import "OAMapStyleSettings.h"
#import "OAIAPHelper.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/GeoTileObjectsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>

#define kTempContourLines @"weatherTempContours"
#define kPressureContourLines @"weatherPressureContours"

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
    OAAutoObserverProxy* _weatherChangeObserver;
    OAAutoObserverProxy* _alphaChangeObserver;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
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
    
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onLayerAlphaChanged)
                                                      andObserve:self.app.data.contoursAlphaChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onWeatherLayerChanged)]];
}

- (void) deinitLayer
{
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
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
    [super updateLayer];

    if ([[OAIAPHelper sharedInstance].weather isActive])
    {
        OsmAnd::BandIndex band = WEATHER_BAND_UNDEFINED;
        OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
        OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
        if ([tempContourLinesParam.value isEqualToString:@"true"])
            band = WEATHER_BAND_TEMPERATURE;
        else if ([pressureContourLinesParam.value isEqualToString:@"true"])
            band = WEATHER_BAND_PRESSURE;
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(self.app.data.contoursAlpha);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];

        if (!self.app.data.weather || band == WEATHER_BAND_UNDEFINED)
            return NO;

        //[self showProgressHUD];

        const auto dateTime = QDateTime::fromNSDate(_date).toUTC();
        [self initProviders:dateTime band:band];

        //[self hideProgressHUD];

        return YES;
    }
    return NO;
}

- (void) initProviders:(QDateTime)dateTime band:(OsmAnd::BandIndex)band
{
    [self deinitProviders];
    
    OAMapRendererEnvironment *env = self.mapViewController.mapRendererEnv;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    int cacheSize = (screenSize.width * 2 / _resourcesManager->getTileSize()) * (screenSize.height * 2 / _resourcesManager->getTileSize());
    int rasterTileSize = (int) (_resourcesManager->getTileSize() * _resourcesManager->getDensityFactor());
    _geoTileObjectsProvider = std::make_shared<OsmAnd::GeoTileObjectsProvider>(_resourcesManager, dateTime, band, cacheSize);
    _mapPrimitivesProvider = std::make_shared<OsmAnd::MapPrimitivesProvider>(
        _geoTileObjectsProvider,
        env.mapPrimitiviser,
        rasterTileSize);
    
    _mapObjectsSymbolsProvider = std::make_shared<OsmAnd::MapObjectsSymbolsProvider>(
        _mapPrimitivesProvider,
        rasterTileSize);
    self.mapView.renderer->addSymbolsProvider(_mapObjectsSymbolsProvider);
    
    _rasterMapProvider = std::make_shared<OsmAnd::MapRasterLayerProvider_Software>(_mapPrimitivesProvider, false);
    self.mapView.renderer->setMapLayerProvider(self.layerIndex, _rasterMapProvider);
}

- (void) deinitProviders
{
    self.mapView.renderer->resetMapLayerProvider(self.layerIndex);
    if (_mapObjectsSymbolsProvider)
        self.mapView.renderer->removeSymbolsProvider(_mapObjectsSymbolsProvider);
    
    _mapObjectsSymbolsProvider = nullptr;
    _mapPrimitivesProvider = nullptr;
    _geoTileObjectsProvider = nullptr;
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
