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
            return @"ic_action_speed";
        case GPXDataSetTypeSlope:
            return @"ic_custom_ascent";
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
        default:
            return @"";
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
            BOOL shouldUseFeet = [OAMetricsConstant shouldUseFeet:[[OAAppSettings sharedManager].metricSystem get]];
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
