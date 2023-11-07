//
//  OASensorsPlugin.mm
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2023 OsmAnd. All rights reserved.
//

#import "OAExternalSensorsPlugin.h"
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

#define kLastUsedExternalSensorKey @"kLastUsedExternalSensorKey"

@implementation OAExternalSensorsPlugin
{
    OACommonBoolean *_lastUsedSensor;
    
    SensorTextWidget *_heartRateTempControl;
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
        _lastUsedSensor = [OACommonBoolean withKey:kLastUsedExternalSensorKey defValue:NO];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.heartRate appModes:@[]];
        
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
    [[DeviceHelper shared] disconnectAllDevices];
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
}

- (BOOL)hasCustomSettings
{
    return YES;
}

- (NSArray<NSString *> *)getWidgetIds
{
    return @[OAWidgetType.heartRate.id];
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    
    _heartRateTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.heartRate];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_heartRateTempControl]];
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
{
    return [[SensorTextWidget alloc] initWithCustomId:@"" widgetType:widgetType widgetParams:nil];
}

- (void)updateWidgetsInfo
{
    if (_heartRateTempControl)
        [_heartRateTempControl updateInfo];
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
