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
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_External_Sensors

#define kLastUsedExternalSensorKey @"kLastUsedExternalSensorKey"

NSString * const OATrackRecordingNone = @"OATrackRecordingNone";
NSString * const OATrackRecordingAnyConnected = @"OATrackRecordingAnyConnected";

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
        
        _speedSensorWriteToTrackDeviceID = [OACommonString withKey:@"speed_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _cadenceSensorWriteToTrackDeviceID = [OACommonString withKey:@"cadence_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _heartSensorWriteToTrackDeviceID = [OACommonString withKey:@"heart_rate_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _temperatureSensorWriteToTrackDeviceID = [OACommonString withKey:@"temperature_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        
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
        if (deviceId && ![deviceId isEqualToString:OATrackRecordingNone])
        {
            OADevice *device = nil;
            if ([deviceId isEqualToString:OATrackRecordingAnyConnected])
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

- (void)getAvailableGPXDataSetTypes:(OAGPXTrackAnalysis *)analysis
                     availableTypes:(NSMutableArray<NSArray<NSNumber *> *> *)availableTypes
{
    [OASensorAttributesUtils getAvailableGPXDataSetTypesWithAnalysis:analysis availableTypes:availableTypes];
}

- (void)onAnalysePoint:(OAGPXTrackAnalysis *)analysis point:(NSObject *)point attribute:(OAPointAttributes *)attribute
{
    if ([point isKindOfClass:OAWptPt.class])
    {
        for (NSString *tag in OASensorAttributesUtils.sensorGpxTags)
        {
            CGFloat defaultValue = [OAPointAttributes.sensorTagTemperature isEqualToString:tag] ?  NAN : 0;
            
            CGFloat value = defaultValue;
            OAGpxExtension *trackpointextension = [((OAWptPt *) point) getExtensionByKey:@"trackpointextension"];
            if (trackpointextension)
            {
                for (OAGpxExtension *subextension in trackpointextension.subextensions)
                {
                    if ([subextension.name isEqualToString:tag])
                    {
                        NSNumber *val = [[[NSNumberFormatter alloc] init] numberFromString:subextension.value];
                        if (val)
                            value = val.floatValue;
                    }
                }
            }
            
            [attribute setAttributeValueFor:tag value:value];
            
            if (![analysis hasData:tag] && [attribute hasValidValueFor:tag] && analysis.totalDistance > 0)
                [analysis setTag:tag hasData:YES];
        }
    }
}

@end
