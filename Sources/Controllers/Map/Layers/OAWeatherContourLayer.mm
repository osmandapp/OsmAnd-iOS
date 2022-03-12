//
//  OAWeatherContourLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherContourLayer.h"

#import "OAMapCreatorHelper.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OARootViewController.h"
#import "OAWebClient.h"
#import "OAWeatherHelper.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/WeatherContourLayerProvider.h>

@implementation OAWeatherContourLayer
{
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _resourcesManager;
    std::shared_ptr<OsmAnd::WeatherContourLayerProvider> _provider;

    OAWeatherHelper *_weatherHelper;
    OAAutoObserverProxy* _weatherChangeObserver;
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
    
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
    {
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onWeatherLayerChanged)]];
    }
}

- (void) deinitLayer
{
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
    }
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];

    [_layerChangeObservers removeAllObjects];
}

- (void) resetLayer
{
    _provider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    QList<OsmAnd::BandIndex> bands = [_weatherHelper getVisibleBands];
    if (!self.app.data.weather || bands.empty())
        return NO;
    
    // TODO: WIP - temp band only for now
    if (bands.contains(WEATHER_BAND_TEMPERATURE))
    {
        bands = QList<OsmAnd::BandIndex>();
        bands << WEATHER_BAND_TEMPERATURE;
    }
    else
    {
        return NO;
    }
    
    //[self showProgressHUD];
          
    const auto dateTime = QDateTime::fromNSDate(_date).toUTC();
    if (true)//!_provider)
    {
        _provider = std::make_shared<OsmAnd::WeatherContourLayerProvider>(_resourcesManager, dateTime, bands);
        [self.mapView setProvider:_provider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(1.0f);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
    }
    else
    {
        _provider->setDateTime(dateTime);
        _provider->setBands(bands);
        [self.mapView invalidateFrame];
    }

    //[self hideProgressHUD];
    
    return YES;
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
            {
                //[self.mapView resetProviderFor:0];
                [self.mapView resetProviderFor:self.layerIndex];
                _provider.reset();
            }
        }];
    });
}

@end
