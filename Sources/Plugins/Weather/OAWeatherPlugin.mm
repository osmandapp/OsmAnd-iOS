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
#import "OAMapInfoWidgetsFactory.h"
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

- (NSArray<NSString *> *) getWidgetIds
{
    return @[OAWidgetType.weatherTemperatureWidget.id, OAWidgetType.weatherAirPressureWidget.id, OAWidgetType.weatherWindWidget.id, OAWidgetType.weatherCloudsWidget.id, OAWidgetType.weatherPrecipitationWidget.id];
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate
               appMode:(OAApplicationMode *)appMode
          widgetParams:(NSDictionary *)widgetParams
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];

    _weatherTempControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherTemperatureWidget customId:nil appMode:appMode widgetParams:widgetParams];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherTempControl]];

    _weatherPressureControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherAirPressureWidget customId:nil appMode:appMode widgetParams:widgetParams];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPressureControl]];

    _weatherWindSpeedControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherWindWidget customId:nil appMode:appMode widgetParams:widgetParams];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherWindSpeedControl]];

    _weatherCloudControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherCloudsWidget customId:nil appMode:appMode widgetParams:widgetParams];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherCloudControl]];

    _weatherPrecipControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherPrecipitationWidget customId:nil appMode:appMode widgetParams:widgetParams];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPrecipControl]];
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
                                      customId:(NSString *)customId
                                       appMode:(OAApplicationMode *)appMode
                                  widgetParams:(NSDictionary *)widgetParams
{
    if (widgetType == OAWidgetType.weatherTemperatureWidget)
        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_TEMPERATURE customId:customId appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.weatherAirPressureWidget)
        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_PRESSURE customId:customId appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.weatherWindWidget)
        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_WIND_SPEED customId:customId appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.weatherCloudsWidget)
        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_CLOUD customId:customId appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.weatherPrecipitationWidget)
        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_PRECIPITATION customId:customId appMode:appMode widgetParams:widgetParams];
    return nil;
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
    return [NSString stringWithFormat:NSLocalizedString(@"weather_plugin_description", nil), k_weather_global_forecast_system];
}

- (NSArray *)getQuickActionTypes
{
    return @[OAShowHideTemperatureAction.TYPE, OAShowHideWindAction.TYPE, OAShowHideAirPressureAction.TYPE, OAShowHidePrecipitationAction.TYPE, OAShowHideCloudAction.TYPE];
}

- (NSArray<OAWeatherWidget *> *)createWidgetsControls
{
    OAApplicationMode *appMode = [OAAppSettings sharedManager].applicationMode.get;
    return @
    [[[OAWeatherWidget alloc] initWithType:OAWidgetType.weatherTemperatureWidget
                                      band:WEATHER_BAND_TEMPERATURE
                                  customId:nil
                                   appMode:appMode
                              widgetParams:nil],
     [[OAWeatherWidget alloc] initWithType:OAWidgetType.weatherAirPressureWidget
                                      band:WEATHER_BAND_PRESSURE
                                  customId:nil
                                   appMode:appMode
                              widgetParams:nil],
     [[OAWeatherWidget alloc] initWithType:OAWidgetType.weatherCloudsWidget
                                      band:WEATHER_BAND_CLOUD
                                  customId:nil
                                   appMode:appMode widgetParams:nil],
     [[OAWeatherWidget alloc] initWithType:OAWidgetType.weatherPrecipitationWidget
                                      band:WEATHER_BAND_PRECIPITATION
                                  customId:nil
                                   appMode:appMode
                              widgetParams:nil],
     [[OAWeatherWidget alloc] initWithType:OAWidgetType.weatherWindWidget
                                      band:WEATHER_BAND_WIND_SPEED
                                  customId:nil
                                   appMode:appMode
                              widgetParams:nil]
    ];
}

@end
