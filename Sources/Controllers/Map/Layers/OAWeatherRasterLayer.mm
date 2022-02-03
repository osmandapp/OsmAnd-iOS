//
//  OAWeatherRasterLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherRasterLayer.h"

#import "OAMapCreatorHelper.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OARootViewController.h"
#import "OAWebClient.h"

#include <OsmAndCore/Map/WeatherRasterLayerProvider.h>

@implementation OAWeatherRasterLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _provider;
    OAAutoObserverProxy* _weatherChangeObserver;
    OAAutoObserverProxy* _layerChangeObserver;
    OAAutoObserverProxy* _alphaChangeObserver;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherBand:(EOAWeatherBand)weatherBand date:(NSDate *)date
{
    self = [super initWithMapViewController:mapViewController layerIndex:layerIndex];
    if (self)
    {
        _weatherBand = weatherBand;
        _date = date;
    }
    return self;
}

- (NSString *) layerId
{
    return [NSString stringWithFormat:@"%@_%d", kWeatherRasterMapLayerId, self.layerIndex];
}

- (void) initLayer
{
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    switch (_weatherBand) {
        case WEATHER_BAND_TEMPERATURE:
            _layerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeatherLayerChanged)
                                                              andObserve:self.app.data.weatherTempChangeObservable];
            _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeaherLayerAlphaChanged)
                                                              andObserve:self.app.data.weatherTempAlphaChangeObservable];
            break;
        case WEATHER_BAND_PRESSURE:
            _layerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeatherLayerChanged)
                                                              andObserve:self.app.data.weatherPressureChangeObservable];
            _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeaherLayerAlphaChanged)
                                                              andObserve:self.app.data.weatherPressureAlphaChangeObservable];
            break;
        case WEATHER_BAND_WIND_SPEED:
            _layerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeatherLayerChanged)
                                                              andObserve:self.app.data.weatherWindChangeObservable];
            _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeaherLayerAlphaChanged)
                                                              andObserve:self.app.data.weatherWindAlphaChangeObservable];
            break;
        case WEATHER_BAND_CLOUD:
            _layerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeatherLayerChanged)
                                                              andObserve:self.app.data.weatherCloudChangeObservable];
            _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeaherLayerAlphaChanged)
                                                              andObserve:self.app.data.weatherCloudAlphaChangeObservable];
            break;
        case WEATHER_BAND_PRECIPITATION:
            _layerChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeatherLayerChanged)
                                                              andObserve:self.app.data.weatherPrecipChangeObservable];
            _alphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onWeaherLayerAlphaChanged)
                                                              andObserve:self.app.data.weatherPrecipAlphaChangeObservable];
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
}

- (void) deinitLayer
{
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
    }
    if (_layerChangeObserver)
    {
        [_layerChangeObserver detach];
        _layerChangeObserver = nil;
    }
    if (_alphaChangeObserver)
    {
        [_alphaChangeObserver detach];
        _alphaChangeObserver = nil;
    }
}

- (void) resetLayer
{
    _provider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (void) updateDate:(NSDate *)date
{
    _date = date;

    [self.mapViewController runWithRenderSync:^{
        [self updateLayer];
    }];
}

- (NSString *) getColorFilePath
{
    switch (_weatherBand)
    {
        case WEATHER_BAND_CLOUD:
            return [[NSBundle mainBundle] pathForResource:@"cloud_color" ofType:@"txt"];
        case WEATHER_BAND_TEMPERATURE:
            return [[NSBundle mainBundle] pathForResource:@"temperature_color" ofType:@"txt"];
        case WEATHER_BAND_PRESSURE:
            return [[NSBundle mainBundle] pathForResource:@"pressure_color" ofType:@"txt"];
        case WEATHER_BAND_WIND_SPEED:
            return [[NSBundle mainBundle] pathForResource:@"wind_color" ofType:@"txt"];
        case WEATHER_BAND_PRECIPITATION:
            return [[NSBundle mainBundle] pathForResource:@"precip_color" ofType:@"txt"];
        case WEATHER_BAND_UNDEFINED:
            return nil;
    }
    return nil;
}

- (BOOL) updateLayer
{
    [super updateLayer];

    [self updateOpacitySliderVisibility];
    
    if (!self.app.data.weather || ![self isLayerVisible])
        return NO;
    
    NSString *colorFilePath = [self getColorFilePath];
    if (colorFilePath && [[NSFileManager defaultManager] fileExistsAtPath:colorFilePath] && _weatherBand != WEATHER_BAND_UNDEFINED)
    {
        [self showProgressHUD];
                        
        const auto dateTime = QDateTime::fromNSDate(_date).toUTC();
        _provider = std::make_shared<OsmAnd::WeatherRasterLayerProvider>(
            dateTime,
            _weatherBand,
            QString::fromNSString(colorFilePath),
            256,
            self.displayDensityFactor,
            QString::fromNSString(self.app.cachePath),
            QString::fromNSString([NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/proj"]),
            std::make_shared<const OAWebClient>()
        );
        //[self.mapView setProvider:_provider forLayer:0];
        [self.mapView setProvider:_provider forLayer:self.layerIndex];

        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor([self getLayerOpacity]);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];

        [self hideProgressHUD];
        
        return YES;
    }
    return NO;
}

- (void) onWeatherChanged
{
    [self updateWeatherLayer];
}

- (void) onWeatherLayerChanged
{
    [self updateWeatherLayer];
}

- (void) onWeaherLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor([self getLayerOpacity]);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

- (BOOL) isLayerVisible
{
    switch (_weatherBand)
    {
        case WEATHER_BAND_CLOUD:
            return self.app.data.weatherCloud;
        case WEATHER_BAND_TEMPERATURE:
            return self.app.data.weatherTemp;
        case WEATHER_BAND_PRESSURE:
            return self.app.data.weatherPressure;
        case WEATHER_BAND_WIND_SPEED:
            return self.app.data.weatherWind;
        case WEATHER_BAND_PRECIPITATION:
            return self.app.data.weatherPrecip;
        case WEATHER_BAND_UNDEFINED:
            return NO;
    }
    return NO;
}

- (double) getLayerOpacity
{
    switch (_weatherBand)
    {
        case WEATHER_BAND_CLOUD:
            return self.app.data.weatherCloudAlpha;
        case WEATHER_BAND_TEMPERATURE:
            return self.app.data.weatherTempAlpha;
        case WEATHER_BAND_PRESSURE:
            return self.app.data.weatherPressureAlpha;
        case WEATHER_BAND_WIND_SPEED:
            return self.app.data.weatherWindAlpha;
        case WEATHER_BAND_PRECIPITATION:
            return self.app.data.weatherPrecipAlpha;
        case WEATHER_BAND_UNDEFINED:
            return 0.0;
    }
    return 0.0;
}

- (void) updateWeatherLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            if (![self updateLayer])
            {
                //[self.mapView resetProviderFor:0];
                [self.mapView resetProviderFor:self.layerIndex];
                _provider.reset();
            }
        }];
    });
}

- (void) updateOpacitySliderVisibility
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //TODO [[OARootViewController instance].mapPanel updateWeatherView];
    });
}

@end
