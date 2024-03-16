//
//  OAOsmAndFormatter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OALocationConvert.h"

#include <GeographicLib/GeoCoords.hpp>

#define MIN_DURATION_FOR_DATE_FORMAT (48 * 60)

@implementation OAOsmAndFormatter

static NSString * const _unitsKm = OALocalizedString(@"km");
static NSString * const _unitsM = OALocalizedString(@"m");
static NSString * const _unitsMi = OALocalizedString(@"mile");
static NSString * const _unitsYd = OALocalizedString(@"yard");
static NSString * const _unitsFt = OALocalizedString(@"foot");
static NSString * const _unitsNm = OALocalizedString(@"nm");
static NSString * const _unitsKmh = OALocalizedString(@"km_h");
static NSString * const _unitsMph = OALocalizedString(@"mile_per_hour");
static NSString * const _unitsMinKm = OALocalizedString(@"min_km");
static NSString * const _unitsMinMi = OALocalizedString(@"min_mile");
static NSString * const _unitsmps = OALocalizedString(@"m_s");

+ (NSString*) getFormattedTimeHM:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    [time appendFormat:@"%02d:", hours];
    [time appendFormat:@"%02d", minutes];
    
    return time;
}

+ (NSString*) getFormattedTimeInterval:(NSTimeInterval)interval
{
    return [self getFormattedTimeInterval:interval withUnit:YES];
}

+ (NSString*) getFormattedTimeInterval:(NSTimeInterval)interval withUnit:(BOOL)withUnit
{
    NSString *unitsStr;
    double intervalInUnits;
    if (interval < 60)
    {
        unitsStr = OALocalizedString(@"shared_string_sec");
        intervalInUnits = interval;
    }
    else if (((int)interval) % 60 == 0)
    {
        unitsStr = OALocalizedString(@"int_min");
        intervalInUnits = ((int)interval) / 60;
    }
    else
    {
        unitsStr = OALocalizedString(@"int_min");
        intervalInUnits = interval / 60.0;
    }
    
    NSString *formattedInterval = [NSString stringWithFormat:@"%d", (int)intervalInUnits];
    return withUnit
    	? [NSString stringWithFormat:@"%@ %@", formattedInterval, unitsStr]
    	: formattedInterval;

}

+ (NSString *) getFormattedPassedTime:(NSTimeInterval)time def:(NSString *)def
{
    if (time > 0)
    {
        NSTimeInterval duration = (NSDate.date.timeIntervalSince1970 - time);
        if (duration > MIN_DURATION_FOR_DATE_FORMAT)
        {
            return [self getFormattedDate:time];
        }
        else
        {
            NSString *formattedDuration;
            if (duration < 60)
                formattedDuration = [NSString stringWithFormat:@"< 1 %@", OALocalizedString(@"int_min")];
            else
                formattedDuration = [self getFormattedTimeInterval:duration];
            
            return [NSString stringWithFormat:OALocalizedString(@"duration_ago"), formattedDuration];
        }
    }
    return def;
}

+ (NSString *) getFormattedDate:(NSTimeInterval)time
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
}

+ (NSString *)getFormattedDateTime:(NSTimeInterval)time
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
}

+ (NSString*) getFormattedTimeInterval:(NSTimeInterval)timeInterval shortFormat:(BOOL)shortFormat
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    if (shortFormat)
    {
        if (hours > 0)
            [time appendFormat:@"%02d:", hours];
        
        [time appendFormat:@"%02d:", minutes];
        [time appendFormat:@"%02d", seconds];
    }
    else
    {
        if (hours > 0)
            [time appendFormat:@"%d %@", hours, OALocalizedString(@"int_hour")];
        if (minutes > 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", minutes, OALocalizedString(@"int_min")];
        }
        if (minutes == 0 && hours == 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", seconds, OALocalizedString(@"shared_string_sec")];
        }
    }
    return time;
}

+ (NSString *) getFormattedAlarmInfoDistance:(float)meters
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    BOOL kmAndMeters = [settings.metricSystem get] == KILOMETERS_AND_METERS;
    float mainUnitInMeters = kmAndMeters ? METERS_IN_KILOMETER : METERS_IN_ONE_MILE;
    return [NSString stringWithFormat:@"%.1f %@", meters / mainUnitInMeters, kmAndMeters ? _unitsKm : _unitsMi];
}

+ (NSString *) getFormattedAzimuth:(float)bearing
{
    while (bearing < -180.0)
        bearing += 360;
    
    while (bearing > 360.0)
        bearing -= 360;
    
    int azimuth = (int) round(bearing);
    EOAAngularConstant angularConstant = [[OAAppSettings sharedManager].angularUnits get];
    switch (angularConstant)
    {
        case DEGREES360:
        {
            bearing += bearing < 0 ? 360 : 0;
            int b = round(bearing);
            b = b == 360 ? 0 : b;
            return [NSString stringWithFormat:@"%d%@", b, [OAAngularConstant getUnitSymbol:DEGREES360]];
        }
        case MILLIRADS:
        {
            bearing += bearing < 0 ? 360 : 0;
            return [NSString stringWithFormat:@"%d %@", (int) round(bearing * MILS_IN_DEGREE), [OAAngularConstant getUnitSymbol:MILLIRADS]];
        }
        default:
            return [NSString stringWithFormat:@"%d%@", azimuth, [OAAngularConstant getUnitSymbol:DEGREES]];
    }
}

+ (NSString *) getFormattedDistance:(float)meters
{
    return [self getFormattedDistance:meters forceTrailingZeroes:YES];
}

+ (NSString *)getFormattedDistance:(float)meters forceTrailingZeroes:(BOOL)forceTrailingZeroes
{
    return [self getFormattedDistance:meters forceTrailingZeroes:YES roundUp:NO valueUnitArray:nil];
}

+ (NSString *) getFormattedDistance:(float)meters roundUp:(BOOL)isRoundUp
{
    return [self getFormattedDistance:meters forceTrailingZeroes:YES roundUp:isRoundUp valueUnitArray:nil];
}

+ (NSString *)getFormattedDistance:(float)meters forceTrailingZeroes:(BOOL)forceTrailingZeroes roundUp:(BOOL)isRoundUp valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    
    NSString *mainUnitStr;
    float mainUnitInMeters;
    if (mc == KILOMETERS_AND_METERS)
    {
        mainUnitStr = _unitsKm;
        mainUnitInMeters = METERS_IN_KILOMETER;
    }
    else if (mc == NAUTICAL_MILES_AND_METERS || mc == NAUTICAL_MILES_AND_FEET)
    {
        mainUnitStr = _unitsNm;
        mainUnitInMeters = METERS_IN_ONE_NAUTICALMILE;
    }
    else
    {
        mainUnitStr = _unitsMi;
        mainUnitInMeters = METERS_IN_ONE_MILE;
    }

    float floatDistance = meters / mainUnitInMeters;
    if (isRoundUp)
        floatDistance = [self roundedDistanceValueForUnit:floatDistance];

    if (meters >= 100 * mainUnitInMeters)
    {
        return [self formatValue:(int) (meters / mainUnitInMeters + 0.5) unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
    }
    else if (meters > 9.99f * mainUnitInMeters)
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:1 valueUnitArray:valueUnitArray];
    }
    else if (meters > 0.999f * mainUnitInMeters && (mc != NAUTICAL_MILES_AND_METERS || mc != NAUTICAL_MILES_AND_FEET))
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else if (mc == MILES_AND_FEET && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:FEET_IN_ONE_METER])
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else if (mc == MILES_AND_METERS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:1.0000f])
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else if (mc == MILES_AND_YARDS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:YARDS_IN_ONE_METER])
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else if (mc == NAUTICAL_MILES_AND_METERS && meters > 0.99f * mainUnitInMeters && ![self isCleanValue:meters inUnits:1.0000f])
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else if (mc == NAUTICAL_MILES_AND_FEET && meters > 0.99f * mainUnitInMeters && ![self isCleanValue:meters inUnits:1.0000f])
    {
        return [self formatValue:floatDistance unit:mainUnitStr forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:2 valueUnitArray:valueUnitArray];
    }
    else
    {
        if (mc == KILOMETERS_AND_METERS || mc == MILES_AND_METERS || mc == NAUTICAL_MILES_AND_METERS)
        {
            return [self formatValue:isRoundUp ? [self roundedDistanceValueForUnit:(int) (meters + 0.5)] : (int) (meters + 0.5) unit:_unitsM forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
        }
        else if (mc == MILES_AND_FEET || mc == NAUTICAL_MILES_AND_FEET)
        {
            int feet = isRoundUp ? [self roundedDistanceValueForUnit:(int) (meters * FEET_IN_ONE_METER + 0.5)] : (int) (meters * FEET_IN_ONE_METER + 0.5);
            return [self formatValue:feet unit:_unitsFt forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
        }
        else if (mc == MILES_AND_YARDS)
        {
            int yards = isRoundUp ? [self roundedDistanceValueForUnit:(int) (meters * YARDS_IN_ONE_METER + 0.5)] : (int) (meters * YARDS_IN_ONE_METER + 0.5);
            return [self formatValue:yards unit:_unitsYd forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
        }
        return [self formatValue:isRoundUp ? [self roundedDistanceValueForUnit:(int) (meters + 0.5)] : (int) (meters + 0.5) unit:_unitsM forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
    }
}

+ (NSString *)formatValue:(float)value
                     unit:(NSString *)unit
      forceTrailingZeroes:(BOOL)forceTrailingZeroes
      decimalPlacesNumber:(NSInteger)decimalPlacesNumber
{
    return [self formatValue:value unit:unit forceTrailingZeroes:forceTrailingZeroes decimalPlacesNumber:decimalPlacesNumber valueUnitArray:nil];
}

+ (NSString *)formatValue:(float)value
                     unit:(NSString *)unit
      forceTrailingZeroes:(BOOL)forceTrailingZeroes
      decimalPlacesNumber:(NSInteger)decimalPlacesNumber
           valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSMutableString *pattern = [NSMutableString string];
    [pattern appendString:@"0"];
    if (decimalPlacesNumber > 0)
    {
        [pattern appendString:@"."];
        NSString *fractionDigitPattern = forceTrailingZeroes ? @"0" : @"#";
        for (NSInteger i = 0; i < decimalPlacesNumber; i++)
        {
            [pattern appendString:fractionDigitPattern];
        }
    }
    numberFormatter.positiveFormat = pattern;

    NSString *preferredLocale = OAUtilities.currentLang;
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:preferredLocale];

    numberFormatter.locale = locale;
    numberFormatter.groupingSeparator = @" ";

    BOOL fiveOrMoreDigits = ABS(value) >= 10000;
    numberFormatter.usesGroupingSeparator = fiveOrMoreDigits;
    if (fiveOrMoreDigits)
        numberFormatter.groupingSize = 3;

    NSMutableString *formattedValue = [NSMutableString stringWithString:[numberFormatter stringFromNumber:@(value)]];
    if (decimalPlacesNumber > 0 && forceTrailingZeroes)
    {
        while ([formattedValue hasSuffix:@"0"])
        {
            [formattedValue deleteCharactersInRange:NSMakeRange(formattedValue.length - 1, 1)];
        }
        if ([formattedValue hasSuffix:@","] || [formattedValue hasSuffix:@"."])
            [formattedValue deleteCharactersInRange:NSMakeRange(formattedValue.length - 1, 1)];
    }
    [valueUnitArray addObject:formattedValue];
    [valueUnitArray addObject:unit];

    return [OAUtilities getFormattedValue:formattedValue unit:unit];
}

+ (BOOL) isCleanValue:(float)meters inUnits:(float)unitsInOneMeter
{
    if ( int(meters) % int(METERS_IN_ONE_NAUTICALMILE) == 0)
        return NO;

    return (int((meters * unitsInOneMeter) * 100) % 100) < 1;
}

+ (NSString *) getFormattedAlt:(double)alt
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    return [self getFormattedAlt:alt mc:mc];
}

+ (NSString *)getFormattedAlt:(double)alt mc:(EOAMetricsConstant)mc valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray {
    BOOL useFeet = mc == MILES_AND_FEET || mc == MILES_AND_YARDS || mc == NAUTICAL_MILES_AND_FEET;
    if (useFeet)
    {
        int feet = (int) (alt * FEET_IN_ONE_METER + 0.5);
        return [self formatValue:feet unit:_unitsFt forceTrailingZeroes:NO decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
    }
    else
    {
        int meters = (int) (alt + 0.5);
        return [self formatValue:meters unit:_unitsM forceTrailingZeroes:NO decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
    }
}

+ (NSString *)getFormattedAlt:(double)alt mc:(EOAMetricsConstant)mc
{
    return [self getFormattedAlt:alt mc:mc valueUnitArray:nil];
}

+ (NSString *)getFormattedSpeed:(float)metersperseconds valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    return [self getFormattedSpeed:metersperseconds drive:NO valueUnitArray:valueUnitArray];
}

+ (NSString *)getFormattedSpeed:(float) metersperseconds
{
    return [self getFormattedSpeed:metersperseconds drive:NO valueUnitArray:nil];
}

+ (NSString *)getFormattedSpeed:(float) metersperseconds drive:(BOOL)drive valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    float kmh = metersperseconds * 3.6f;
    if ([settings.speedSystem get] == KILOMETERS_PER_HOUR)
    {
        int kmh10 = (int) (kmh * 10.0f);
        if (kmh >= 20)
        {
            return [self getFormattedSpeed:(int) kmh10 / 10.0f unit:_unitsKmh valueUnitArray:valueUnitArray];
        }
        // calculate 2.0 km/h instead of 2 km/h in order to not stress UI text lengh
        return [self getFormattedLowSpeed:kmh10 / 10.0f unit:_unitsKmh valueUnitArray:valueUnitArray];
    }
    else if ([settings.speedSystem get] == MILES_PER_HOUR)
    {
        float mph = kmh * METERS_IN_KILOMETER / METERS_IN_ONE_MILE;
        int mph10 = (int) (mph * 10.0f);
        if (mph >= 20)
        {
            return [self getFormattedSpeed:mph10 / 10.0f unit:_unitsMph valueUnitArray:valueUnitArray];
        }
        return [self getFormattedLowSpeed:mph10 / 10.0f unit:_unitsMph valueUnitArray:valueUnitArray];
    }
    else if ([settings.speedSystem get] == NAUTICALMILES_PER_HOUR)
    {
        float mph = kmh * METERS_IN_KILOMETER / METERS_IN_ONE_NAUTICALMILE;
        int mph10 = (int) (mph * 10.0f);
        if (mph >= 20)
        {
            return [self getFormattedSpeed:mph10 / 10.0f unit:_unitsNm valueUnitArray:valueUnitArray];
        }
        return [self getFormattedLowSpeed:mph10 / 10.0f unit:_unitsNm valueUnitArray:valueUnitArray];
    }
    else if ([settings.speedSystem get] == MINUTES_PER_KILOMETER)
    {
        if (metersperseconds < 0.111111111)
        {
            [valueUnitArray addObject:@"-"];
            [valueUnitArray addObject:_unitsMinKm];
            return [OAUtilities getFormattedValue:@"-" unit:_unitsMinKm];
        }
        float minPerKm = METERS_IN_KILOMETER / (METERS_PER_SECOND * 60);
        if (minPerKm >= 10)
        {
            return [self getFormattedSpeed:minPerKm unit:_unitsMinKm valueUnitArray:valueUnitArray];
        }
        else
        {
            int seconds = round(minPerKm * 60);
            NSString *value = [self getFormattedTimeInterval:seconds withUnit:NO];
            [valueUnitArray addObject:value];
            [valueUnitArray addObject:_unitsMinKm];
            return [OAUtilities getFormattedValue:value unit:_unitsMinKm];
        }
    }
    else if ([settings.speedSystem get] == MINUTES_PER_MILE)
    {
        if (metersperseconds < 0.111111111)
        {
            [valueUnitArray addObject:@"-"];
            [valueUnitArray addObject:_unitsMinMi];
            return [OAUtilities getFormattedValue:@"-" unit:_unitsMinMi];
        }
        float minPerM = (METERS_IN_ONE_MILE) / (metersperseconds * 60);
        if (minPerM >= 10)
        {
            int rounded = round(minPerM);
            return [self getFormattedSpeed:rounded unit:_unitsMinMi valueUnitArray:valueUnitArray];
        }
        else
        {
            int mph10 = round(minPerM * 10.0f);
            return [self getFormattedLowSpeed: mph10/10.0f unit:_unitsMinMi valueUnitArray:valueUnitArray];
        }
    }
    else
    {
        if (metersperseconds >= 10)
        {
            return [self getFormattedSpeed:metersperseconds unit:_unitsmps valueUnitArray:valueUnitArray];
        }
        // for smaller values display 1 decimal digit x.y km/h, (0.5% precision at 20 km/h)
        int kmh10 = round(metersperseconds * 10.0f);
        return [self getFormattedLowSpeed:kmh10 / 10.0f unit:_unitsmps valueUnitArray:valueUnitArray];
    }
}

+ (NSString *)getFormattedSpeed:(float)speed unit:(NSString *)unit valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    return [self formatValue:speed unit:unit forceTrailingZeroes:false decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
}

+ (NSString *)getFormattedSpeed:(float) speed unit:(NSString*) unit
{
    return [self formatValue:speed unit:unit forceTrailingZeroes:false decimalPlacesNumber:0];
}

+ (NSString *)getFormattedLowSpeed:(float) speed unit:(NSString*) unit
{
    return [self formatValue:speed unit:unit forceTrailingZeroes:false decimalPlacesNumber:1 valueUnitArray:nil];
}

+ (NSString *)getFormattedLowSpeed:(float)speed unit:(NSString *)unit valueUnitArray:(NSMutableArray <NSString *>*)valueUnitArray
{
    return [self formatValue:speed unit:unit forceTrailingZeroes:false decimalPlacesNumber:1 valueUnitArray:valueUnitArray];
}

+ (double) calculateRoundedDist:(double)baseMetersDist
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    double mainUnitInMeter = 1;
    double metersInSecondUnit = METERS_IN_KILOMETER;
    if (mc == MILES_AND_FEET)
    {
        mainUnitInMeter = FEET_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == MILES_AND_METERS)
    {
        mainUnitInMeter = 1;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == NAUTICAL_MILES_AND_METERS)
    {
        mainUnitInMeter = 1;
        metersInSecondUnit = METERS_IN_ONE_NAUTICALMILE;
    }
    else if (mc == NAUTICAL_MILES_AND_FEET)
    {
        mainUnitInMeter = FEET_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_NAUTICALMILE;
    }
    else if (mc == MILES_AND_YARDS)
    {
        mainUnitInMeter = YARDS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    
    // 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000 ...
    int generator = 1;
    int pointer = 1;
    double point = mainUnitInMeter;
    double roundDist = 1;
    while (baseMetersDist * point >= generator)
    {
        roundDist = (generator / point);
        if (pointer++ % 3 == 2)
            generator = generator * 5 / 2;
        else
            generator *= 2;
        
        if (point == mainUnitInMeter && metersInSecondUnit * mainUnitInMeter * 0.9f <= generator)
        {
            point = 1 / metersInSecondUnit;
            generator = 1;
            pointer = 1;
        }
    }
    //Miles exceptions: 2000ft->0.5mi, 1000ft->0.25mi, 1000yd->0.5mi, 500yd->0.25mi, 1000m ->0.5mi, 500m -> 0.25mi
    if (mc == MILES_AND_METERS && roundDist == 1000)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_METERS && roundDist == 500)
        roundDist = 0.25f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_FEET && roundDist == 2000 / (double) FEET_IN_ONE_METER)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_FEET && roundDist == 1000 / (double) FEET_IN_ONE_METER)
        roundDist = 0.25f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_YARDS && roundDist == 1000 / (double) YARDS_IN_ONE_METER)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_YARDS && roundDist == 500 / (double) YARDS_IN_ONE_METER)
        roundDist = 0.25f * METERS_IN_ONE_MILE;

    return roundDist;
}

+ (NSString *) getFormattedCoordinatesWithLat:(double)lat lon:(double)lon outputFormat:(NSInteger)outputFormat
{
    NSMutableString *result = [NSMutableString new];
    
    if (outputFormat == FORMAT_DEGREES_SHORT)
    {
        [result appendString:[self formatCoordinate:lat outputType:outputFormat]];
        [result appendString:@" "];
        [result appendString:[self formatCoordinate:lon outputType:outputFormat]];
    }
    else if (outputFormat == FORMAT_DEGREES || outputFormat == FORMAT_MINUTES || outputFormat == FORMAT_SECONDS)
    {
        BOOL isLeftToRight = UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight;
        NSString *rtlCoordinates = isLeftToRight ? @"" : @"\u200f";
        NSString *rtlCoordinatesPunctuation = isLeftToRight ? @", " : @" ,";
        [result appendString:rtlCoordinates];
        [result appendString:[self formatCoordinate:lat outputType:outputFormat]];
        [result appendString:rtlCoordinates];
        [result appendString:@" "];
        [result appendString:rtlCoordinates];
        [result appendString:lat > 0 ? NORTH : SOUTH];
        [result appendString:rtlCoordinates];
        [result appendString:rtlCoordinatesPunctuation];
        [result appendString:rtlCoordinates];
        [result appendString:[self formatCoordinate:lon outputType:outputFormat]];
        [result appendString:rtlCoordinates];
        [result appendString:@" "];
        [result appendString:rtlCoordinates];
        [result appendString:lon > 0 ? EAST : WEST];
    }
    else if (outputFormat == FORMAT_UTM)
    {
        NSString *r = [OALocationConvert getUTMCoordinateString:lat lon:lon];
        if (!r)
            r = @"0, 0";
        [result appendString:r];
    }
    else if (outputFormat == FORMAT_OLC)
    {
        NSString *r = [OALocationConvert getLocationOlcName:lat lon:lon];
        if (!r)
            r = @"0, 0";
        [result appendString:r];
    }
    else if (outputFormat == FORMAT_MGRS)
    {
        NSString *r = [OALocationConvert getMgrsCoordinateString:lat lon:lon];
        if (!r)
            r = @"0, 0";
        [result appendString:r];
    }
    return [NSString stringWithString:result];
}

+ (NSString *) formatCoordinate:(double)coordinate outputType:(NSInteger)outputType
{
    if (coordinate < -180.0 || coordinate > 180.0 || isnan(coordinate))
    {
        return @"Error. Wrong coordinates data!";
    }
    if ((outputType != FORMAT_DEGREES) && (outputType != FORMAT_MINUTES) && (outputType != FORMAT_SECONDS) && (outputType != FORMAT_DEGREES_SHORT))
    {
        return @"Unknown Output Format!";
    }
    
    NSNumberFormatter *degDf = [[NSNumberFormatter alloc] init];
    [degDf setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    [degDf setPositiveFormat:@"##0.00000"];
    NSNumberFormatter *minDf = [[NSNumberFormatter alloc] init];
    [minDf setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    [minDf setPositiveFormat:@"00.000"];
    NSNumberFormatter *secDf = [[NSNumberFormatter alloc] init];
    [secDf setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    [secDf setPositiveFormat:@"00.0"];
    
    NSMutableString *result = [NSMutableString new];
    
    if (coordinate < 0)
    {
        if (outputType == FORMAT_DEGREES_SHORT)
        {
            [result appendString:@"-"];
        }
        coordinate = -coordinate;
    }
    
    if (outputType == FORMAT_DEGREES_SHORT)
    {
        [result appendString:[degDf stringFromNumber:@(coordinate)]];
    }
    else if (outputType == FORMAT_DEGREES)
    {
        [result appendString:[degDf stringFromNumber:@(coordinate)]];
        [result appendString:DELIMITER_DEGREES];
    }
    else if (outputType == FORMAT_MINUTES)
    {
        double processedCoordinate = [self formatCoordinate:coordinate text:result delimiter:DELIMITER_DEGREES];
        [result appendString:[minDf stringFromNumber:@(processedCoordinate)]];
        [result appendString:DELIMITER_MINUTES];
    }
    else
    {
        double processedCoordinate = [self formatCoordinate:coordinate text:result delimiter:DELIMITER_DEGREES];
        double postprocessedCoordinate = [self formatCoordinate:processedCoordinate text:result delimiter:DELIMITER_MINUTES];
        [result appendString:[secDf stringFromNumber:@(postprocessedCoordinate)]];
        [result appendString:DELIMITER_SECONDS];
    }
    return [NSString stringWithString:result];
}

+ (double) formatCoordinate:(double)coordinate text:(NSMutableString *)text delimiter:(NSString *)delimiter
{
    int deg = (int) floor(coordinate);
    if (deg < 10)
        [text appendString:@"0"];
    [text appendString:[NSString stringWithFormat:@"%d", deg]];
    [text appendString:delimiter];
    coordinate -= deg;
    coordinate *= 60.0;
    return coordinate;
}

+ (NSString *) getFormattedDistanceInterval:(double)interval
{
    double roundedDist = [self.class calculateRoundedDist:interval];
    return [self.class getFormattedDistance:(float) roundedDist];
}

+ (NSString *) getFormattedOsmTagValue:(NSString *)tagValue
{
    if ([tagValue rangeOfCharacterFromSet: [ [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"] invertedSet] ].location == NSNotFound)
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setGroupingSeparator:@"\u00a0"];
        NSNumber *numberValue = [NSNumber numberWithDouble:[tagValue doubleValue]];
        if (numberValue && numberValue.doubleValue != 0)
            return [numberFormatter stringFromNumber:numberValue];
    }
    return tagValue;
}

+ (NSString *) getFormattedDurationShort:(NSTimeInterval)seconds fullForm:(BOOL) fullForm
{
    NSString *sec = [NSString stringWithFormat:@"%02ld", (long)seconds % 60];
    
    long minutes = seconds / 60;
      if (!fullForm && minutes < 60) {
          return [NSString stringWithFormat:@"%ld:%@", minutes, sec];
      } else {
          NSString *min = [NSString stringWithFormat:@"%02ld", minutes % 60];
          long hours = minutes / 60;
          return [NSString stringWithFormat:@"%ld:%@:%@", hours, min, sec];
      }
}

+ (NSString *)getFormattedDuration:(NSTimeInterval)seconds
{
    NSInteger secondsInt = (NSInteger) seconds;
    NSInteger hours = secondsInt / (60 * 60);
    NSInteger minutes = (secondsInt / 60) % 60;
    
    if (hours > 0)
    {
        NSString *durationString = [NSString stringWithFormat:@"%ld %@", hours, OALocalizedString(@"int_hour")];
        if (minutes > 0)
            durationString = [durationString stringByAppendingFormat:@" %ld %@", minutes, OALocalizedString(@"int_min")];
        return durationString;
    }
    else if (minutes > 0)
    {
        return [NSString stringWithFormat:@"%ld %@", minutes, OALocalizedString(@"int_min")];
    }
    else
    {
        return [NSString stringWithFormat:@"<1 %@", OALocalizedString(@"int_min")];
    }
}

+ (float)roundedDistanceValueForUnit:(float)value
{
    if (value >= 1)
    {
        NSArray<NSNumber *> *roundRange = [self generate10BaseRoundingBoundsWithMax:100 multCoef:5];
        return [self lowerTo10BaseRoundingBounds:value withRoundRange:roundRange];
    }
    else
    {
        return value;
    }
}

+ (NSArray<NSNumber *> *)generate10BaseRoundingBoundsWithMax:(int)max multCoef:(int)multCoef
{
    int basenum = 1;
    int mult = 1;
    int num = basenum * mult;
    int ind = 0;
    NSMutableArray<NSNumber *> *bounds = [[NSMutableArray alloc] init];
    
    while (num < max)
    {
        ind++;
        if (ind % 3 == 1)
        {
            mult = 2;
        }
        else if (ind % 3 == 2)
        {
            mult = 5;
        }
        else
        {
            basenum *= 10;
            mult = 1;
        }
        
        if (ind > 1)
        {
            int bound = num * multCoef;
            while (bound % (basenum * mult) != 0 && bound > basenum * mult)
            {
                bound += num;
            }
            
            [bounds addObject:@(bound)];
        }
        
        num = basenum * mult;
        [bounds addObject:@(num)];
    }
    
    NSMutableArray<NSNumber *> *reversedBounds = [[NSMutableArray alloc] initWithCapacity:[bounds count]];
    for (NSNumber *bound in [bounds reverseObjectEnumerator])
    {
        [reversedBounds addObject:bound];
    }
    
    return reversedBounds;
}

+ (int)lowerTo10BaseRoundingBounds:(int)num withRoundRange:(NSArray<NSNumber *> *)roundRange
{
    int k = 1;
    while (k < [roundRange count] && ([roundRange[k] intValue] > num || [roundRange[k - 1] intValue] > num))
    {
        k += 2;
    }

    if (k < [roundRange count])
        return (num / [roundRange[k - 1] intValue]) * [roundRange[k - 1] intValue];
    
    return num;
}

@end
