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
    OACommonString *_speedSensorWriteToTrackDeviceID;
    OACommonString *_cadenceSensorWriteToTrackDeviceID;
    OACommonString *_powerSensorWriteToTrackDeviceID;
    OACommonString *_heartSensorWriteToTrackDeviceID;
    OACommonString *_temperatureSensorWriteToTrackDeviceID;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedSensor = [OACommonBoolean withKey:kLastUsedExternalSensorKey defValue:NO];

        _speedSensorWriteToTrackDeviceID = [OACommonString withKey:@"speed_sensor_write_to_track_device" defValue:@""];
        _cadenceSensorWriteToTrackDeviceID = [OACommonString withKey:@"cadence_sensor_write_to_track_device" defValue:@""];
        _powerSensorWriteToTrackDeviceID = [OACommonString withKey:@"power_sensor_write_to_track_device" defValue:@""];
        _heartSensorWriteToTrackDeviceID = [OACommonString withKey:@"heart_rate_sensor_write_to_track_device" defValue:@""];
        _temperatureSensorWriteToTrackDeviceID = [OACommonString withKey:@"temperature_sensor_write_to_track_device" defValue:@""];

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
    [[OADeviceHelper shared] disconnectAllDevices];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [[OARootViewController instance] updateLeftPanelMenu];
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

- (NSArray<OAWidgetType *> *)getExternalSensorTrackDataType
{
    return @[OAWidgetType.heartRate,
             OAWidgetType.bicycleCadence,
             OAWidgetType.bicyclePower,
             OAWidgetType.bicycleSpeed,
             OAWidgetType.temperature];
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    auto widgetTypeArray = @[OAWidgetType.heartRate,
                             OAWidgetType.bicycleCadence,
                             OAWidgetType.bicyclePower,
                             OAWidgetType.bicycleDistance,
                             OAWidgetType.bicycleSpeed,
                             OAWidgetType.temperature];
    for (OAWidgetType *widgetType in widgetTypeArray)
    {
        [delegate addWidget:[creator createWidgetInfoWithWidget:(SensorTextWidget *) [self createMapWidgetForParams:widgetType]]];
    }
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
{
    return [[SensorTextWidget alloc] initWithCustomId:@"" widgetType:widgetType widgetParams:nil];
}

- (NSString *) getName
{
    return OALocalizedString(@"external_sensors_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"external_sensors_plugin_description");
}

- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json
{
    for (OAWidgetType *widgetType in [self getExternalSensorTrackDataType])
    {
        [self attachDeviceSensorInfoToRecordedTrack:widgetType json:json];
    }
}

- (void)attachDeviceSensorInfoToRecordedTrack:(OAWidgetType *)widgetType json:(NSMutableData *)json
{
    OAApplicationMode *selectedAppMode = [[OAAppSettings sharedManager].applicationMode get];
    OACommonString *deviceIdPref = [self getWriteToTrackDeviceIdPref:widgetType];
    if (deviceIdPref)
    {
        NSString *speedDeviceId = [deviceIdPref get:selectedAppMode];
        if (speedDeviceId && speedDeviceId.length > 0 && ![speedDeviceId isEqualToString:kDenyWriteSensorDataToTrackKey])
        {
            OADevice *device = [[OADeviceHelper shared] getConnectedAndPaireDisconnectedDeviceForType:widgetType deviceId:speedDeviceId];
            if (device)
                [device writeSensorDataToJsonWithJson:json widgetDataFieldType:widgetType];
        }
    }
}

- (OACommonString *)getWriteToTrackDeviceIdPref:(OAWidgetType *)dataType
{
    if ([dataType isEqual:OAWidgetType.bicycleSpeed])
        return _speedSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.bicyclePower])
        return _powerSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.bicycleCadence])
        return _cadenceSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.heartRate])
        return _heartSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.temperature])
        return _temperatureSensorWriteToTrackDeviceID;
    return nil;
}

@end
