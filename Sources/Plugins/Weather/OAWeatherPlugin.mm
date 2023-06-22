//
//  OAWeatherPlugin.mm
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherPlugin.h"
#import "OARootViewController.h"
#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OAWeatherWidget.h"
#import "OAMapInfoWidgetsFactory.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAIAPHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_Weather
#define kLastUsedWeatherKey @"lastUsedWeather"

@implementation OAWeatherPlugin
{
    OACommonBoolean *_lastUsedWeather;

    OAWeatherWidget *_weatherTempControl;
    OAWeatherWidget *_weatherPressureControl;
    OAWeatherWidget *_weatherWindSpeedControl;
    OAWeatherWidget *_weatherCloudControl;
    OAWeatherWidget *_weatherPrecipControl;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedWeather = [OACommonBoolean withKey:kLastUsedWeatherKey defValue:NO];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherTemperatureWidget appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherAirPressureWidget appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherWindWidget appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherCloudsWidget appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherPrecipitationWidget appModes:@[]];
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

- (BOOL)isEnabled
{
    return [super isEnabled] && [[OAIAPHelper sharedInstance].weather isActive];
}

- (void)weatherChanged:(BOOL)isOn
{
    [_lastUsedWeather set:isOn];
    [[OsmAndApp instance].data setWeather:isOn];
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];

    _weatherTempControl = [self createMapWidgetForParams:OAWidgetType.weatherTemperatureWidget band:WEATHER_BAND_TEMPERATURE];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherTempControl]];
    
    _weatherPressureControl = [self createMapWidgetForParams:OAWidgetType.weatherAirPressureWidget band:WEATHER_BAND_PRESSURE];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPressureControl]];
    
    _weatherWindSpeedControl = [self createMapWidgetForParams:OAWidgetType.weatherWindWidget band:WEATHER_BAND_WIND_SPEED];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherWindSpeedControl]];
    
    _weatherCloudControl = [self createMapWidgetForParams:OAWidgetType.weatherCloudsWidget band:WEATHER_BAND_CLOUD];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherCloudControl]];
    
    _weatherPrecipControl = [self createMapWidgetForParams:OAWidgetType.weatherPrecipitationWidget band:WEATHER_BAND_PRECIPITATION];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPrecipControl]];
}

- (OAWeatherWidget *) createMapWidgetForParams:(OAWidgetType *)widgetType band:(EOAWeatherBand)band
{
    return [[OAWeatherWidget alloc] initWithType:widgetType band:band];
}

- (void) updateLayers
{
}

- (void)updateWidgetsInfo
{
    if (_weatherTempControl)
        [_weatherTempControl updateInfo];
    if (_weatherPressureControl)
        [_weatherPressureControl updateInfo];
    if (_weatherWindSpeedControl)
        [_weatherWindSpeedControl updateInfo];
    if (_weatherCloudControl)
        [_weatherCloudControl updateInfo];
    if (_weatherPrecipControl)
        [_weatherPrecipControl updateInfo];
}

- (NSString *) getName
{
    return OALocalizedString(@"shared_string_weather");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"weather_plugin_description");
}

@end
