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
            return ACImageNameIcCustomAltitude;
        case GPXDataSetTypeSpeed:
            return ACImageNameIcCustomSpeed;
        case GPXDataSetTypeSlope:
            return ACImageNameIcCustomSlope;
        case GPXDataSetTypeSensorSpeed:
            return ACImageNameIcCustomSensorSpeedOutlined;
        case GPXDataSetTypeSensorHeartRate:
            return ACImageNameIcCustomSensorHeartRateOutlined;
        case GPXDataSetTypeSensorBikePower:
            return ACImageNameIcCustomSensorBicyclePowerOutlined;
        case GPXDataSetTypeSensorBikeCadence:
            return ACImageNameIcCustomSensorCadenceOutlined;
        case GPXDataSetTypeSensorTemperatureA:
        case GPXDataSetTypeSensorTemperatureW:
            return ACImageNameIcCustomSensorThermometer;
        case GPXDataSetTypeIntakeTemperature:
            return ACImageNameIcCustomObdTemperatureIntake;
        case GPXDataSetTypeAmbientTemperature:
            return ACImageNameIcCustomObdTemperatureOutside;
        case GPXDataSetTypeCoolantTemperature:
            return ACImageNameIcCustomObdTemperatureCoolant;
        case GPXDataSetTypeEngineOilTemperature:
            return ACImageNameIcCustomObdTemperatureEngineOil;
        case GPXDataSetTypeEngineSpeed:
            return ACImageNameIcCustomObdEngineSpeed;
        case GPXDataSetTypeEngineRuntime:
            return ACImageNameIcCustomCarRunningTime;
        case GPXDataSetTypeEngineLoad:
            return ACImageNameIcCustomCarInfo;
        case GPXDataSetTypeFuelPressure:
            return ACImageNameIcCustomObdFuelPressure;
        case GPXDataSetTypeFuelConsumption:
            return ACImageNameIcCustomObdFuelConsumption;
        case GPXDataSetTypeRemainingFuel:
            return ACImageNameIcCustomObdFuelRemaining;
        case GPXDataSetTypeBatteryLevel:
            return ACImageNameIcCustomObdBatteryVoltage;
        case GPXDataSetTypeVehicleSpeed:
            return ACImageNameIcCustomObdSpeed;
        case GPXDataSetTypeThrottlePosition:
            return ACImageNameIcCustomObdThrottlePosition;
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
