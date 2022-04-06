//
//  OAWeatherPlugin.mm
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherPlugin.h"
#import "OAIAPHelper.h"
#import "OsmAndApp.h"
#import "OAMapInfoController.h"
#import "OAMapInfoWidgetsFactory.h"
#import "OATextInfoWidget.h"

#define PLUGIN_ID kInAppId_Addon_Weather
#define kLastUsedWeatherKey @"lastUsedWeather"

static NSArray<NSString *> * const _weatherSettingKeys = @[kWeatherTemp, kWeatherPressure, kWeatherWind, kWeatherCloud, kWeatherPrecip];

@implementation OAWeatherPlugin
{
    OACommonBoolean *_lastUsedWeather;

    OATextInfoWidget *_weatherTempControl;
    OATextInfoWidget *_weatherPressureControl;
    OATextInfoWidget *_weatherWindSpeedControl;
    OATextInfoWidget *_weatherCloudControl;
    OATextInfoWidget *_weatherPrecipControl;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedWeather = [OACommonBoolean withKey:kLastUsedWeatherKey defValue:NO];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void)disable
{
    [super disable];
    OAAppData *data = [OsmAndApp instance].data;
    [_lastUsedWeather set:data.weather];
    [data setWeather:NO];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [[OsmAndApp instance].data setWeather:enabled ? [_lastUsedWeather get] : NO];
}

- (void)weatherChanged:(BOOL)isOn
{
    [_lastUsedWeather set:isOn];
    [[OsmAndApp instance].data setWeather:isOn];
}

+ (NSArray<NSString *> *)getWeatherSettingKeys
{
    return _weatherSettingKeys;
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isEnabled])
        {
            if (!_weatherTempControl)
                [self registerWidget:WEATHER_BAND_TEMPERATURE];

            if (!_weatherPressureControl)
                [self registerWidget:WEATHER_BAND_PRESSURE];

            if (!_weatherWindSpeedControl)
                [self registerWidget:WEATHER_BAND_WIND_SPEED];

            if (!_weatherCloudControl)
                [self registerWidget:WEATHER_BAND_CLOUD];

            if (!_weatherPrecipControl)
                [self registerWidget:WEATHER_BAND_PRECIPITATION];
        }
        else
        {
            OAMapInfoController *mapInfoController = [self getMapInfoController];
            if (_weatherTempControl)
            {
                [mapInfoController removeSideWidget:_weatherTempControl];
                _weatherTempControl = nil;
            }
            if (_weatherPressureControl)
            {
                [mapInfoController removeSideWidget:_weatherPressureControl];
                _weatherPressureControl = nil;
            }
            if (_weatherWindSpeedControl)
            {
                [mapInfoController removeSideWidget:_weatherWindSpeedControl];
                _weatherWindSpeedControl = nil;
            }
            if (_weatherCloudControl)
            {
                [mapInfoController removeSideWidget:_weatherCloudControl];
                _weatherCloudControl = nil;
            }
            if (_weatherPrecipControl)
            {
                [mapInfoController removeSideWidget:_weatherPrecipControl];
                _weatherPrecipControl = nil;
            }
            [mapInfoController recreateControls];
        }
    });
}

- (void)registerWidget:(EOAWeatherBand)band
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        OAMapInfoWidgetsFactory *mic = [[OAMapInfoWidgetsFactory alloc] init];

        switch (band)
        {
            case WEATHER_BAND_TEMPERATURE:
            {
                _weatherTempControl = [mic createWeatherControl:WEATHER_BAND_TEMPERATURE];
                [mapInfoController registerSideWidget:_weatherTempControl
                                              imageId:[[OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE] getIcon]
                                              message:[[OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE] getMeasurementName]
                                                  key:kWeatherTemp
                                                 left:false
                                        priorityOrder:120];
                break;
            }

            case WEATHER_BAND_PRESSURE:
            {
                _weatherPressureControl = [mic createWeatherControl:WEATHER_BAND_PRESSURE];
                [mapInfoController registerSideWidget:_weatherPressureControl
                                              imageId:[[OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE] getIcon]
                                              message:[[OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE] getMeasurementName]
                                                  key:kWeatherPressure
                                                 left:false
                                        priorityOrder:121];
                break;
            }

            case WEATHER_BAND_WIND_SPEED:
            {
                _weatherWindSpeedControl = [mic createWeatherControl:WEATHER_BAND_WIND_SPEED];
                [mapInfoController registerSideWidget:_weatherWindSpeedControl
                                              imageId:[[OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED] getIcon]
                                              message:[[OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED] getMeasurementName]
                                                  key:kWeatherWind
                                                 left:false
                                        priorityOrder:122];
                break;
            }

            case WEATHER_BAND_CLOUD:
            {
                _weatherCloudControl = [mic createWeatherControl:WEATHER_BAND_CLOUD];
                [mapInfoController registerSideWidget:_weatherCloudControl
                                              imageId:[[OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD] getIcon]
                                              message:[[OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD] getMeasurementName]
                                                  key:kWeatherCloud
                                                 left:false
                                        priorityOrder:123];
            }

            case WEATHER_BAND_PRECIPITATION:
            {
                _weatherPrecipControl = [mic createWeatherControl:WEATHER_BAND_PRECIPITATION];
                [mapInfoController registerSideWidget:_weatherPrecipControl
                                              imageId:[[OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION] getIcon]
                                              message:[[OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION] getMeasurementName]
                                                  key:kWeatherPrecip
                                                 left:false
                                        priorityOrder:124];
                break;
            }

            default:
                return;
        }

        [mapInfoController recreateControls];
    }
}

@end
