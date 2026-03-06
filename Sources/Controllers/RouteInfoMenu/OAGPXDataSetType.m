//
//  OAGPXDataSetType.m
//  OsmAnd Maps
//
//  Created by Skalii on 09.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAGPXDataSetType.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGPXDataSetType

+ (NSString *) getTitle:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
            return OALocalizedString(@"altitude");
        case GPXDataSetTypeSpeed:
            return OALocalizedString(@"shared_string_speed");
        case GPXDataSetTypeSlope:
            return OALocalizedString(@"shared_string_slope");
        case GPXDataSetTypeSensorSpeed:
            return OALocalizedString(@"shared_string_speed");
        case GPXDataSetTypeSensorHeartRate:
            return OALocalizedString(@"map_widget_ant_heart_rate");
        case GPXDataSetTypeSensorBikePower:
            return OALocalizedString(@"map_widget_ant_bicycle_power");
        case GPXDataSetTypeSensorBikeCadence:
            return OALocalizedString(@"map_widget_ant_bicycle_cadence");
        case GPXDataSetTypeSensorTemperatureA:
            return OALocalizedString(@"map_settings_weather_temp_air");
        case GPXDataSetTypeSensorTemperatureW:
            return OALocalizedString(@"map_settings_weather_temp_water");
        case GPXDataSetTypeIntakeTemperature:
            return OALocalizedString(@"obd_air_intake_temp");
        case GPXDataSetTypeAmbientTemperature:
            return OALocalizedString(@"obd_ambient_air_temp");
        case GPXDataSetTypeCoolantTemperature:
            return OALocalizedString(@"obd_engine_coolant_temp");
        case GPXDataSetTypeEngineOilTemperature:
            return OALocalizedString(@"obd_engine_oil_temperature");
        case GPXDataSetTypeEngineSpeed:
            return OALocalizedString(@"obd_widget_engine_speed");
        case GPXDataSetTypeEngineRuntime:
            return OALocalizedString(@"obd_engine_runtime");
        case GPXDataSetTypeEngineLoad:
            return OALocalizedString(@"obd_calculated_engine_load");
        case GPXDataSetTypeFuelPressure:
            return OALocalizedString(@"obd_fuel_pressure");
        case GPXDataSetTypeFuelConsumption:
            return OALocalizedString(@"obd_fuel_consumption");
        case GPXDataSetTypeRemainingFuel:
            return OALocalizedString(@"remaining_fuel");
        case GPXDataSetTypeBatteryLevel:
            return OALocalizedString(@"obd_battery_voltage");
        case GPXDataSetTypeVehicleSpeed:
            return OALocalizedString(@"obd_widget_vehicle_speed");
        case GPXDataSetTypeThrottlePosition:
            return OALocalizedString(@"obd_throttle_position");
        default:
            return @"";
    }
}

+ (NSString *) getIconName:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
            return @"ic_custom_altitude";
        case GPXDataSetTypeSpeed:
            return @"ic_custom_speed";
        case GPXDataSetTypeSlope:
            return @"ic_custom_slope";
        case GPXDataSetTypeSensorSpeed:
            return @"ic_custom_sensor_speed_outlined";
        case GPXDataSetTypeSensorHeartRate:
            return @"ic_custom_sensor_heart_rate_outlined";
        case GPXDataSetTypeSensorBikePower:
            return @"ic_custom_sensor_bicycle_power_outlined";
        case GPXDataSetTypeSensorBikeCadence:
            return @"ic_custom_sensor_cadence_outlined";
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return @"ic_custom_sensor_thermometer";
        case GPXDataSetTypeIntakeTemperature:
            return @"ic_custom_obd_temperature_intake";
        case GPXDataSetTypeAmbientTemperature:
            return @"ic_custom_obd_temperature_outside";
        case GPXDataSetTypeCoolantTemperature:
            return @"ic_custom_obd_temperature_coolant";
        case GPXDataSetTypeEngineOilTemperature:
            return @"ic_custom_obd_temperature_engine_oil";
        case GPXDataSetTypeEngineSpeed:
            return @"ic_custom_obd_engine_speed";
        case GPXDataSetTypeEngineRuntime:
            return @"ic_custom_car_running_time";
        case GPXDataSetTypeEngineLoad:
            return @"ic_custom_car_info";
        case GPXDataSetTypeFuelPressure:
            return @"ic_custom_obd_fuel_pressure";
        case GPXDataSetTypeFuelConsumption:
            return @"ic_custom_obd_fuel_consumption";
        case GPXDataSetTypeRemainingFuel:
            return @"ic_custom_obd_fuel_remaining";
        case GPXDataSetTypeBatteryLevel:
            return @"ic_custom_obd_battery_voltage";
        case GPXDataSetTypeVehicleSpeed:
            return @"ic_custom_obd_speed";
        case GPXDataSetTypeThrottlePosition:
            return @"ic_custom_obd_throttle_position";
        default:
            return @"";
    }
}

+ (NSString *) getDataKey:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
            return OASPointAttributes.pointElevation;
        case GPXDataSetTypeSpeed:
            return OASPointAttributes.pointSpeed;
        case GPXDataSetTypeSlope:
            return OASPointAttributes.pointElevation;
        case GPXDataSetTypeSensorSpeed:
            return OASPointAttributes.sensorTagSpeed;
        case GPXDataSetTypeSensorHeartRate:
            return OASPointAttributes.sensorTagHeartRate;
        case GPXDataSetTypeSensorBikePower:
            return OASPointAttributes.sensorTagBikePower;
        case GPXDataSetTypeSensorBikeCadence:
            return OASPointAttributes.sensorTagCadence;
        case GPXDataSetTypeSensorTemperatureA:
            return OASPointAttributes.sensorTagTemperatureA;
        case GPXDataSetTypeSensorTemperatureW:
            return OASPointAttributes.sensorTagTemperatureW;
        case GPXDataSetTypeIntakeTemperature:
            return OASPointAttributes.obdIntakeTemperature;
        case GPXDataSetTypeAmbientTemperature:
            return OASPointAttributes.obdAmbientTemperature;
        case GPXDataSetTypeCoolantTemperature:
            return OASPointAttributes.obdCoolantTemperature;
        case GPXDataSetTypeEngineOilTemperature:
            return OASPointAttributes.obdEngineOilTemperature;
        case GPXDataSetTypeEngineSpeed:
            return OASPointAttributes.obdEngineSpeed;
        case GPXDataSetTypeEngineRuntime:
            return OASPointAttributes.obdEngineRuntime;
        case GPXDataSetTypeEngineLoad:
            return OASPointAttributes.obdEngineLoad;
        case GPXDataSetTypeFuelPressure:
            return OASPointAttributes.obdFuelPressure;
        case GPXDataSetTypeFuelConsumption:
            return OASPointAttributes.obdFuelConsumption;
        case GPXDataSetTypeRemainingFuel:
            return OASPointAttributes.obdRemainingFuel;
        case GPXDataSetTypeBatteryLevel:
            return OASPointAttributes.obdBatteryLevel;
        case GPXDataSetTypeVehicleSpeed:
            return OASPointAttributes.obdVehicleSpeed;
        case GPXDataSetTypeThrottlePosition:
            return OASPointAttributes.obdThrottlePosition;
        default:
            return @"";
    }
}

+ (NSInteger)getTypeGroup:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
        case GPXDataSetTypeSpeed:
        case GPXDataSetTypeSlope:
            return GpxDataSetTypeGroupGeneral;
        case GPXDataSetTypeSensorSpeed:
        case GPXDataSetTypeSensorHeartRate:
        case GPXDataSetTypeSensorBikePower:
        case GPXDataSetTypeSensorBikeCadence:
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return GpxDataSetTypeGroupExternalSensors;
        case GPXDataSetTypeIntakeTemperature:
        case GPXDataSetTypeAmbientTemperature:
        case GPXDataSetTypeCoolantTemperature:
        case GPXDataSetTypeEngineOilTemperature:
        case GPXDataSetTypeEngineSpeed:
        case GPXDataSetTypeEngineRuntime:
        case GPXDataSetTypeEngineLoad:
        case GPXDataSetTypeFuelPressure:
        case GPXDataSetTypeFuelConsumption:
        case GPXDataSetTypeRemainingFuel:
        case GPXDataSetTypeBatteryLevel:
        case GPXDataSetTypeVehicleSpeed:
        case GPXDataSetTypeThrottlePosition:
            return GpxDataSetTypeGroupVehicleMetrics;
        default:
            return GpxDataSetTypeGroupGeneral;
    }
}

+ (UIColor *) getTextColor:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
            return [UIColor colorNamed:ACColorNameChartTextColorElevation];
        case GPXDataSetTypeSpeed:
            return [UIColor colorNamed:ACColorNameChartTextColorSpeed];
        case GPXDataSetTypeSlope:
            return [UIColor colorNamed:ACColorNameChartTextColorSlope];
        case GPXDataSetTypeSensorSpeed:
            return [UIColor colorNamed:ACColorNameChartTextColorSpeedSensor];
        case GPXDataSetTypeSensorHeartRate:
            return [UIColor colorNamed:ACColorNameChartTextColorHeartRate];
        case GPXDataSetTypeSensorBikePower:
            return [UIColor colorNamed:ACColorNameChartTextColorBicyclePower];
        case GPXDataSetTypeSensorBikeCadence:
            return [UIColor colorNamed:ACColorNameChartTextColorBicycleCadence];
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return [UIColor colorNamed:ACColorNameChartTextColorTemperature];
        case GPXDataSetTypeIntakeTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorIntakeTemperature];
        case GPXDataSetTypeAmbientTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorAmbientTemperature];
        case GPXDataSetTypeCoolantTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorCoolantTemperature];
        case GPXDataSetTypeEngineOilTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineOilTemperature];
        case GPXDataSetTypeEngineSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineSpeed];
        case GPXDataSetTypeEngineRuntime:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineRuntime];
        case GPXDataSetTypeEngineLoad:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineLoad];
        case GPXDataSetTypeFuelPressure:
            return [UIColor colorNamed:ACColorNameChartLineColorFuelPressure];
        case GPXDataSetTypeFuelConsumption:
            return [UIColor colorNamed:ACColorNameChartLineColorFuelConsumption];
        case GPXDataSetTypeRemainingFuel:
            return [UIColor colorNamed:ACColorNameChartLineColorRemainingFuel];
        case GPXDataSetTypeBatteryLevel:
            return [UIColor colorNamed:ACColorNameChartLineColorBatteryLevel];
        case GPXDataSetTypeVehicleSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorVehicleSpeed];
        case GPXDataSetTypeThrottlePosition:
            return [UIColor colorNamed:ACColorNameChartLineColorThrottlePosition];
        default:
            return nil;
    }
}

+ (UIColor *) getFillColor:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
            return [UIColor colorNamed:ACColorNameChartLineColorElevation];
        case GPXDataSetTypeSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorSpeed];
        case GPXDataSetTypeSlope:
            return [UIColor colorNamed:ACColorNameChartLineColorSlope];
        case GPXDataSetTypeSensorSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorSpeedSensor];
        case GPXDataSetTypeSensorHeartRate:
            return [UIColor colorNamed:ACColorNameChartLineColorHeartRate];
        case GPXDataSetTypeSensorBikePower:
            return [UIColor colorNamed:ACColorNameChartLineColorBicyclePower];
        case GPXDataSetTypeSensorBikeCadence:
            return [UIColor colorNamed:ACColorNameChartLineColorBicycleCadence];
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return [UIColor colorNamed:ACColorNameChartLineColorTemperature];
        case GPXDataSetTypeIntakeTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorIntakeTemperature];
        case GPXDataSetTypeAmbientTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorAmbientTemperature];
        case GPXDataSetTypeCoolantTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorCoolantTemperature];
        case GPXDataSetTypeEngineOilTemperature:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineOilTemperature];
        case GPXDataSetTypeEngineSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineSpeed];
        case GPXDataSetTypeEngineRuntime:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineRuntime];
        case GPXDataSetTypeEngineLoad:
            return [UIColor colorNamed:ACColorNameChartLineColorEngineLoad];
        case GPXDataSetTypeFuelPressure:
            return [UIColor colorNamed:ACColorNameChartLineColorFuelPressure];
        case GPXDataSetTypeFuelConsumption:
            return [UIColor colorNamed:ACColorNameChartLineColorFuelConsumption];
        case GPXDataSetTypeRemainingFuel:
            return [UIColor colorNamed:ACColorNameChartLineColorRemainingFuel];
        case GPXDataSetTypeBatteryLevel:
            return [UIColor colorNamed:ACColorNameChartLineColorBatteryLevel];
        case GPXDataSetTypeVehicleSpeed:
            return [UIColor colorNamed:ACColorNameChartLineColorVehicleSpeed];
        case GPXDataSetTypeThrottlePosition:
            return [UIColor colorNamed:ACColorNameChartLineColorThrottlePosition];
        default:
            return nil;
    }
}

+ (NSString *) getMainUnitY:(NSInteger)type
{
    switch (type)
    {
        case GPXDataSetTypeAltitude:
        {
            BOOL shouldUseFeet = [OAAltitudeMetricsConstant shouldUseFeet:[[OAAppSettings sharedManager].altitudeMetric get]];
            return OALocalizedString(shouldUseFeet ? @"foot" : @"m");
        }
        case GPXDataSetTypeSpeed:
        case GPXDataSetTypeSensorSpeed:
            return [OASpeedConstant toShortString:[[OAAppSettings sharedManager].speedSystem get]];
        case GPXDataSetTypeSlope:
            return @"%";
        case GPXDataSetTypeSensorHeartRate:
            return OALocalizedString(@"beats_per_minute_short");
        case GPXDataSetTypeSensorBikePower:
            return OALocalizedString(@"power_watts_unit");
        case GPXDataSetTypeSensorBikeCadence:
            return OALocalizedString(@"revolutions_per_minute_unit");
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return @"°";
        default:
            return @"";
    }
}

@end
