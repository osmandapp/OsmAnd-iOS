//
//  OAWeatherBand.m
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherBand.h"
#import "OsmAndApp.h"

@interface OAWeatherBand()

@property (nonatomic) EOAWeatherBand bandIndex;

@end

@implementation OAWeatherBand
{
    OsmAndAppInstance _app;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
    }
    return self;
}

+ (instancetype) withWeatherBand:(EOAWeatherBand)bandIndex
{
    OAWeatherBand *obj = [[OAWeatherBand alloc] init];
    if (obj)
    {
        obj.bandIndex = bandIndex;
    }
    return obj;
}

- (BOOL) isBandVisible
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloud;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTemp;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressure;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWind;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecip;
        case WEATHER_BAND_UNDEFINED:
            return NO;
    }
    return NO;
}

- (double) getBandOpacity
{
    switch (self.bandIndex)
    {
        case WEATHER_BAND_CLOUD:
            return _app.data.weatherCloudAlpha;
        case WEATHER_BAND_TEMPERATURE:
            return _app.data.weatherTempAlpha;
        case WEATHER_BAND_PRESSURE:
            return _app.data.weatherPressureAlpha;
        case WEATHER_BAND_WIND_SPEED:
            return _app.data.weatherWindAlpha;
        case WEATHER_BAND_PRECIPITATION:
            return _app.data.weatherPrecipAlpha;
        case WEATHER_BAND_UNDEFINED:
            return 0.0;
    }
    return 0.0;
}

- (NSString *) getColorFilePath
{
    switch (self.bandIndex)
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

- (OAAutoObserverProxy *) createSwitchObserver:(id)owner handler:(SEL)handler
{
    switch (self.bandIndex) {
        case WEATHER_BAND_TEMPERATURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherTempChangeObservable];
            break;
        case WEATHER_BAND_PRESSURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPressureChangeObservable];
            break;
        case WEATHER_BAND_WIND_SPEED:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherWindChangeObservable];
            break;
        case WEATHER_BAND_CLOUD:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherCloudChangeObservable];
            break;
        case WEATHER_BAND_PRECIPITATION:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPrecipChangeObservable];
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
}

- (OAAutoObserverProxy *) createAlphaObserver:(id)owner handler:(SEL)handler
{
    switch (self.bandIndex) {
        case WEATHER_BAND_TEMPERATURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherTempAlphaChangeObservable];
            break;
        case WEATHER_BAND_PRESSURE:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPressureAlphaChangeObservable];
            break;
        case WEATHER_BAND_WIND_SPEED:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherWindAlphaChangeObservable];
            break;
        case WEATHER_BAND_CLOUD:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherCloudAlphaChangeObservable];
            break;
        case WEATHER_BAND_PRECIPITATION:
            return [[OAAutoObserverProxy alloc] initWith:owner
                                             withHandler:handler
                                              andObserve:_app.data.weatherPrecipAlphaChangeObservable];
            break;
        case WEATHER_BAND_UNDEFINED:
            break;
    }
}

@end
