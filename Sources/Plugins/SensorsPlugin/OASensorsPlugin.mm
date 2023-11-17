//
//  OASensorsPlugin.mm
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASensorsPlugin.h"
#import "OARootViewController.h"
#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OAWeatherWidget.h"
#import "OAMapInfoWidgetsFactory.h"
#import "OAMapWidgetRegInfo.h"
#import "OAIAPHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_External_Sensors

@implementation OASensorsPlugin
{
//    OACommonBoolean *_lastUsedWeather;
//
//    OAWeatherWidget *_weatherTempControl;
//    OAWeatherWidget *_weatherPressureControl;
//    OAWeatherWidget *_weatherWindSpeedControl;
//    OAWeatherWidget *_weatherCloudControl;
//    OAWeatherWidget *_weatherPrecipControl;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
//        _lastUsedWeather = [OACommonBoolean withKey:kLastUsedWeatherKey defValue:NO];
//        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherTemperatureWidget appModes:@[]];
//        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherAirPressureWidget appModes:@[]];
//        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherWindWidget appModes:@[]];
//        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherCloudsWidget appModes:@[]];
//        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.weatherPrecipitationWidget appModes:@[]];
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
//    OAAppData *data = [OsmAndApp instance].data;
//    [_lastUsedWeather set:data.weather];
//    [data setWeather:NO];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
   // [[OsmAndApp instance].data setWeather:enabled ? [_lastUsedWeather get] : NO];
}

- (BOOL)isEnabled
{
    return [super isEnabled] && [[OAIAPHelper sharedInstance].sensors isActive];
   // return [super isEnabled] && [[OAIAPHelper sharedInstance].weather isActive];
}

- (BOOL)hasCustomSettings
{
    return YES;
}


//- (NSArray<NSString *> *) getWidgetIds
//{
//    return @[OAWidgetType.weatherTemperatureWidget.id, OAWidgetType.weatherAirPressureWidget.id, OAWidgetType.weatherWindWidget.id, OAWidgetType.weatherCloudsWidget.id, OAWidgetType.weatherPrecipitationWidget.id];
//}

//- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
//{
//    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
//
//    _weatherTempControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherTemperatureWidget customId:nil];
//    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherTempControl]];
//
//    _weatherPressureControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherAirPressureWidget customId:nil];
//    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPressureControl]];
//
//    _weatherWindSpeedControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherWindWidget customId:nil];
//    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherWindSpeedControl]];
//
//    _weatherCloudControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherCloudsWidget customId:nil];
//    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherCloudControl]];
//
//    _weatherPrecipControl = (OAWeatherWidget *) [self createMapWidgetForParams:OAWidgetType.weatherPrecipitationWidget customId:nil];
//    [delegate addWidget:[creator createWidgetInfoWithWidget:_weatherPrecipControl]];
//}

//- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType customId:(NSString *)customId
//{
//    if (widgetType == OAWidgetType.weatherTemperatureWidget)
//        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_TEMPERATURE];
//    else if (widgetType == OAWidgetType.weatherAirPressureWidget)
//        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_PRESSURE];
//    else if (widgetType == OAWidgetType.weatherWindWidget)
//        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_WIND_SPEED];
//    else if (widgetType == OAWidgetType.weatherCloudsWidget)
//        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_CLOUD];
//    else if (widgetType == OAWidgetType.weatherPrecipitationWidget)
//        return [[OAWeatherWidget alloc] initWithType:widgetType band:WEATHER_BAND_PRECIPITATION];
//    return nil;
//}


- (void)updateWidgetsInfo
{
}
// ic_custom_sensor

- (NSString *) getName
{
    return OALocalizedString(@"external_sensors_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"external_sensors_plugin_description");
}


@end
