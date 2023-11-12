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
    SensorTextWidget *_bicycleCadenceTempControl;
    SensorTextWidget *_bicyclePowerTempControl;
    SensorTextWidget *_bicycleDistanceTempControl;
    SensorTextWidget *_bicycleSpeedTempControl;
    SensorTextWidget *_temperatureTempControl;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedSensor = [OACommonBoolean withKey:kLastUsedExternalSensorKey defValue:NO];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.heartRate appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleCadence appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicyclePower appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleDistance appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleSpeed appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.temperature appModes:@[]];
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
    return [super isEnabled] && [OAIAPHelper isSensorPurchased];
}

- (BOOL)hasCustomSettings
{
    return YES;
}

- (NSArray<NSString *> *)getWidgetIds
{
    return @[OAWidgetType.heartRate.id,
             OAWidgetType.bicycleCadence.id,
             OAWidgetType.bicyclePower.id,
             OAWidgetType.bicycleDistance.id,
             OAWidgetType.bicycleSpeed.id,
             OAWidgetType.temperature.id];
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    
    _heartRateTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.heartRate];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_heartRateTempControl]];
    
    _bicycleCadenceTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.bicycleCadence];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_bicycleCadenceTempControl]];
    
    _bicyclePowerTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.bicyclePower];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_bicyclePowerTempControl]];
    
    _bicycleDistanceTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.bicycleDistance];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_bicycleDistanceTempControl]];
    
    _bicycleSpeedTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.bicycleSpeed];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_bicycleSpeedTempControl]];
    
    _temperatureTempControl = (SensorTextWidget *) [self createMapWidgetForParams:OAWidgetType.temperature];
    [delegate addWidget:[creator createWidgetInfoWithWidget:_temperatureTempControl]];
    
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
{
    return [[SensorTextWidget alloc] initWithCustomId:@"" widgetType:widgetType widgetParams:nil];
}

- (void)updateWidgetsInfo
{
    if (_heartRateTempControl)
        [_heartRateTempControl updateInfo];
    if (_bicycleCadenceTempControl)
        [_bicycleCadenceTempControl updateInfo];
    if (_bicyclePowerTempControl)
        [_bicyclePowerTempControl updateInfo];
    if (_bicycleDistanceTempControl)
        [_bicycleDistanceTempControl updateInfo];
    if (_bicycleSpeedTempControl)
        [_bicycleSpeedTempControl updateInfo];
    if (_temperatureTempControl)
        [_temperatureTempControl updateInfo];
}

- (NSString *) getName
{
    return OALocalizedString(@"external_sensors_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"external_sensors_plugin_description");
}

@end
