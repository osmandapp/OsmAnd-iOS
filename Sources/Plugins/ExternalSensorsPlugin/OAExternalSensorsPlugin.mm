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
#import "OAGPXDocumentPrimitives.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"

#define PLUGIN_ID kInAppId_Addon_External_Sensors

#define kLastUsedExternalSensorKey @"kLastUsedExternalSensorKey"

NSString * const OATrackRecordingAnyConnectedDevice = @"any_connected_device_write_sensor_data_to_track_key";

@implementation OAExternalSensorsPlugin
{
    OACommonBoolean *_lastUsedSensor;
    OACommonString *_speedSensorWriteToTrackDeviceID;
    OACommonString *_cadenceSensorWriteToTrackDeviceID;
    OACommonString *_heartSensorWriteToTrackDeviceID;
    OACommonString *_temperatureSensorWriteToTrackDeviceID;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedSensor = [OACommonBoolean withKey:kLastUsedExternalSensorKey defValue:NO];

        _speedSensorWriteToTrackDeviceID = [[self registerStringPreference:@"speed_sensor_write_to_track_device" defValue:@""] makeProfile];
        _cadenceSensorWriteToTrackDeviceID = [[self registerStringPreference:@"cadence_sensor_write_to_track_device" defValue:@""] makeProfile];
        _heartSensorWriteToTrackDeviceID = [[self registerStringPreference:@"heart_rate_sensor_write_to_track_device" defValue:@""] makeProfile];
        _temperatureSensorWriteToTrackDeviceID = [[self registerStringPreference:@"temperature_sensor_write_to_track_device" defValue:@""] makeProfile];

        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.heartRate appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleCadence appModes:@[]];
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
    [[OADeviceHelper shared] disconnectAllDevicesWithReason:DisconnectDeviceReasonPluginOff];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (OsmAndApp.instance.initialized)
        dispatch_async(dispatch_get_main_queue(), ^{
            [[OARootViewController instance] updateLeftPanelMenu];
        });
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
             OAWidgetType.bicycleDistance.id,
             OAWidgetType.bicycleSpeed.id,
             OAWidgetType.temperature.id];
}

- (NSArray<OAWidgetType *> *)getExternalSensorTrackDataType
{
    return @[OAWidgetType.heartRate,
             OAWidgetType.bicycleCadence,
             OAWidgetType.bicycleSpeed,
             OAWidgetType.temperature];
}

- (NSString *)batteryOutlinedIconNameForWidgetType:(OAWidgetType *)widgetType {
    if (widgetType == OAWidgetType.heartRate) {
        return @"ic_custom_sensor_heart_rate_battery_outlined";
    } else if (widgetType == OAWidgetType.bicycleCadence) {
        return @"ic_custom_sensor_cadence_battery_outlined";
    } else if (widgetType == OAWidgetType.bicycleSpeed) {
        return @"ic_custom_sensor_speed_battery_outlined";
    } else if (widgetType == OAWidgetType.bicycleDistance) {
        return @"ic_custom_sensor_distance_battery_outlined";
    } else if (widgetType == OAWidgetType.temperature) {
        return @"ic_custom_sensor_temperature_battery_outlined";
    } else {
        return @"";
    }
}

- (NSString *)batteryIconNameForWidgetType:(OAWidgetType *)widgetType {
    if (widgetType == OAWidgetType.heartRate) {
        return @"widget_sensor_heart_rate_battery";
    } else if (widgetType == OAWidgetType.bicycleCadence) {
        return @"widget_sensor_cadence_battery";
    } else if (widgetType == OAWidgetType.bicycleSpeed) {
        return @"widget_sensor_speed_battery";
    } else if (widgetType == OAWidgetType.bicycleDistance) {
        return @"widget_sensor_distance_battery";
    } else if (widgetType == OAWidgetType.temperature) {
        return @"widget_sensor_temperature_battery";
    } else {
        return @"";
    }
}

- (NSString *)getAnyConnectedDeviceId
{
    return OATrackRecordingAnyConnectedDevice;
}

- (NSString *)getWidgetDataFieldTypeNameByWidgetId:(NSString *)widgetId
{
    NSString *origWidgetId = [widgetId containsString:OAMapWidgetInfo.DELIMITER]
        ? [widgetId substringToIndex:[widgetId indexOf:OAMapWidgetInfo.DELIMITER]]
        : widgetId;

    if ([origWidgetId isEqualToString:OAWidgetType.temperature.id])
        return @"TEMPERATURE";
    if ([origWidgetId isEqualToString:OAWidgetType.heartRate.id])
        return @"HEART_RATE";
    if ([origWidgetId isEqualToString:OAWidgetType.bicycleSpeed.id])
        return @"BIKE_SPEED";
    if ([origWidgetId isEqualToString:OAWidgetType.bicycleCadence.id])
        return @"BIKE_CADENCE";
    if ([origWidgetId isEqualToString:OAWidgetType.bicycleDistance.id])
        return @"BIKE_DISTANCE";
    return nil;
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary *)widgetParams
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    auto widgetTypeArray = @[OAWidgetType.heartRate,
                             OAWidgetType.bicycleCadence,
                             OAWidgetType.bicycleDistance,
                             OAWidgetType.bicycleSpeed,
                             OAWidgetType.temperature];
    for (OAWidgetType *widgetType in widgetTypeArray)
    {
        [delegate addWidget:[creator createWidgetInfoWithWidget:(SensorTextWidget *) [self createMapWidgetForParams:widgetType customId:nil appMode:appMode widgetParams:widgetParams]]];
    }
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
                                      customId:(NSString *)customId
                                       appMode:(OAApplicationMode *)appMode
                                  widgetParams:(NSDictionary *)widgetParams
{
    if (widgetType == OAWidgetType.heartRate)
        return [[SensorTextWidget alloc] initWithCustomId:customId widgetType:OAWidgetType.heartRate appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.bicycleCadence)
        return [[SensorTextWidget alloc] initWithCustomId:customId widgetType:OAWidgetType.bicycleCadence appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.bicycleSpeed)
        return [[SensorTextWidget alloc] initWithCustomId:customId widgetType:OAWidgetType.bicycleSpeed appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.bicycleDistance)
        return [[SensorTextWidget alloc] initWithCustomId:customId widgetType:OAWidgetType.bicycleDistance appMode:appMode widgetParams:widgetParams];
    else if (widgetType == OAWidgetType.temperature)
        return [[SensorTextWidget alloc] initWithCustomId:customId widgetType:OAWidgetType.temperature appMode:appMode widgetParams:widgetParams];
    return nil;
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
        NSString *deviceId = [deviceIdPref get:selectedAppMode];
        if (deviceId && deviceId.length > 0)
        {
            OADevice *device = nil;
            if ([deviceId isEqualToString:[self getAnyConnectedDeviceId]])
                device = [[OADeviceHelper shared] getConnectedDevicesForWidgetWithType:widgetType].firstObject;
            else
                device = [[OADeviceHelper shared] getPairedDevicesForType:widgetType deviceId:deviceId];
            
            if (device)
                [device writeSensorDataToJsonWithJson:json widgetDataFieldType:widgetType];
        }
    }
}

- (NSString *)getDeviceIdForWidgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode {
    if ([widgetType isEqual:OAWidgetType.bicycleSpeed])
        return [_speedSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.bicycleCadence])
        return [_cadenceSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.heartRate])
        return [_heartSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.temperature])
        return [_temperatureSensorWriteToTrackDeviceID get:appMode];
    return @"";
}

- (void)saveDeviceId:(NSString *)deviceID widgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode {
    if ([widgetType isEqual:OAWidgetType.bicycleSpeed])
        [_speedSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.bicycleCadence])
        [_cadenceSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.heartRate])
        [_heartSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.temperature])
        [_temperatureSensorWriteToTrackDeviceID set:deviceID mode:appMode];
}

- (OACommonString *)getWriteToTrackDeviceIdPref:(OAWidgetType *)dataType
{
    if ([dataType isEqual:OAWidgetType.bicycleSpeed])
        return _speedSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.bicycleCadence])
        return _cadenceSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.heartRate])
        return _heartSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.temperature])
        return _temperatureSensorWriteToTrackDeviceID;
    return nil;
}

- (void)getAvailableGPXDataSetTypes:(OASGpxTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes
{
    [OASensorAttributesUtils getAvailableGPXDataSetTypesWithAnalysis:analysis availableTypes:availableTypes];
}

@end
