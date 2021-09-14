//
//  OAOsmAndFormatter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OALocationConvert.h"

#include <GeographicLib/GeoCoords.hpp>

@implementation OAOsmAndFormatter

+ (NSString *) unitsKm
{
    return OALocalizedString(@"units_km");
}

+ (NSString *) unitsm
{
    return OALocalizedString(@"units_m");
}

+ (NSString *) unitsMi
{
    return OALocalizedString(@"units_mi");
}

+ (NSString *) unitsYd
{
    return OALocalizedString(@"units_yd");
}

+ (NSString *) unitsFt
{
    return OALocalizedString(@"units_ft");
}

+ (NSString *) unitsNm
{
    return OALocalizedString(@"units_nm");
}

+ (NSString *) unitsKmh
{
    return OALocalizedString(@"units_kmh");
}

+ (NSString *) unitsMph
{
    return OALocalizedString(@"units_mph");
}

+ (NSString*) getFormattedTimeHM:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    [time appendFormat:@"%02d:", hours];
    [time appendFormat:@"%02d", minutes];
    
    return time;
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
            [time appendFormat:@"%d %@", hours, OALocalizedString(@"units_hour")];
        if (minutes > 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", minutes, OALocalizedString(@"units_min")];
        }
        if (minutes == 0 && hours == 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", seconds, OALocalizedString(@"units_sec")];
        }
    }
    return time;
}

+ (NSString *) getFormattedAlarmInfoDistance:(float)meters
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    BOOL kmAndMeters = [settings.metricSystem get] == KILOMETERS_AND_METERS;
    float mainUnitInMeters = kmAndMeters ? METERS_IN_KILOMETER : METERS_IN_ONE_MILE;
    return [NSString stringWithFormat:@"%.1f %@", meters / mainUnitInMeters, kmAndMeters ? [self unitsKm] : [self unitsMi]];
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
    OAAppSettings *settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    
    NSString *mainUnitStr;
    float mainUnitInMeters;
    if (mc == KILOMETERS_AND_METERS)
    {
        mainUnitStr = [self unitsKm];
        mainUnitInMeters = METERS_IN_KILOMETER;
    }
    else if (mc == NAUTICAL_MILES)
    {
        mainUnitStr = [self unitsNm];
        mainUnitInMeters = METERS_IN_ONE_NAUTICALMILE;
    }
    else
    {
        mainUnitStr = [self unitsMi];
        mainUnitInMeters = METERS_IN_ONE_MILE;
    }
    
    if (meters >= 100 * mainUnitInMeters)
    {
        return [NSString stringWithFormat:@"%d %@",  (int) (meters / mainUnitInMeters + 0.5), mainUnitStr];
    }
    else if (meters > 9.99f * mainUnitInMeters)
    {
        float num = meters / mainUnitInMeters;
        NSString *numStr = [NSString stringWithFormat:@"%.1f", num];
        if ([[numStr substringFromIndex:numStr.length - 1] isEqualToString:@"0"])
            numStr = [numStr substringToIndex:numStr.length - 2];
        return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
    }
    else if (meters > 0.999f * mainUnitInMeters && mc != NAUTICAL_MILES)
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_FEET && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:FOOTS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_METERS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_YARDS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:YARDS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == NAUTICAL_MILES && meters > 0.99f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else
    {
        if (mc == KILOMETERS_AND_METERS || mc == MILES_AND_METERS || mc == NAUTICAL_MILES)
        {
            return [NSString stringWithFormat:@"%d %@", ((int) (meters + 0.5)), [self unitsm]];
        }
        else if (mc == MILES_AND_FEET)
        {
            int feet = (int) (meters * FOOTS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", feet, [self unitsFt]];
        }
        else if (mc == MILES_AND_YARDS)
        {
            int yards = (int) (meters * YARDS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", yards, [self unitsYd]];
        }
        return [NSString stringWithFormat:@"%d %@", ((int) (meters + 0.5)), [self unitsm]];
    }
}

+ (NSString *) getMilesFormattedStringWithMeters:(float)meters mainUnitInMeters:(float)mainUnitInMeters mainUnitStr:(NSString *)mainUnitStr
{
    float num = meters / mainUnitInMeters;
    NSString *numStr = [NSString stringWithFormat:@"%.2f", num];
    if ([[numStr substringFromIndex:numStr.length - 2] isEqualToString:@"00"])
        numStr = [numStr substringToIndex:numStr.length - 3];
    return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
}

+ (BOOL) isCleanValue:(float)meters inUnits:(float)unitsInOneMeter
{
    if ( int(meters) % int(METERS_IN_ONE_NAUTICALMILE) == 0)
        return NO;

    return (int((meters * unitsInOneMeter) * 100) % 100) < 1;
}

+ (NSString *) getFormattedAlt:(double) alt
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    if ([settings.metricSystem get] == KILOMETERS_AND_METERS) {
        return [NSString stringWithFormat:@"%d %@", ((int) (alt + 0.5)), [self unitsm]];
    } else {
        return [NSString stringWithFormat:@"%d %@", ((int) (alt * FOOTS_IN_ONE_METER + 0.5)), [self unitsFt]];
    }
}

+ (NSString *) getFormattedSpeed:(float) metersperseconds
{
    return [self getFormattedSpeed:metersperseconds drive:NO];
}

+ (NSString *) getFormattedSpeed:(float) metersperseconds drive:(BOOL)drive
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    float kmh = metersperseconds * 3.6f;
    if ([settings.metricSystem get] == KILOMETERS_AND_METERS) {
        if (kmh >= 10 || drive) {
            // case of car
            return [NSString stringWithFormat:@"%d %@", ((int) round(kmh)), [self unitsKmh]];
        }
        int kmh10 = (int) (kmh * 10.0f);
        // calculate 2.0 km/h instead of 2 km/h in order to not stress UI text lengh
        return [NSString stringWithFormat:@"%g %@", (kmh10 / 10.0f), [self unitsKmh]];
    } else {
        float mph = kmh * METERS_IN_KILOMETER / METERS_IN_ONE_MILE;
        if (mph >= 10) {
            return [NSString stringWithFormat:@"%d %@", ((int) round(mph)), [self unitsMph]];
        } else {
            int mph10 = (int) (mph * 10.0f);
            return [NSString stringWithFormat:@"%g %@", (mph10 / 10.0f), [self unitsMph]];
        }
    }
}

+ (double) calculateRoundedDist:(double)baseMetersDist
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    double mainUnitInMeter = 1;
    double metersInSecondUnit = METERS_IN_KILOMETER;
    if (mc == MILES_AND_FEET)
    {
        mainUnitInMeter = FOOTS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == MILES_AND_METERS)
    {
        mainUnitInMeter = 1;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == NAUTICAL_MILES)
    {
        mainUnitInMeter = 1;
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
    while (baseMetersDist * point > generator)
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
    else if (mc == MILES_AND_FEET && roundDist == 2000 / (double) FOOTS_IN_ONE_METER)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_FEET && roundDist == 1000 / (double) FOOTS_IN_ONE_METER)
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
        GeographicLib::GeoCoords pnt(lat, lon);
        [result appendString:[NSString stringWithFormat:@"%i%c ", pnt.Zone(), toupper(pnt.Hemisphere())]];
        [result appendString:[NSString stringWithFormat:@"%i ", int(round(pnt.Easting()))]];
        [result appendString:[NSString stringWithFormat:@"%i", int(round(pnt.Northing()))]];
    }
    else if (outputFormat == FORMAT_OLC)
    {
        NSString *r = [OALocationConvert getLocationOlcName:lat lon:lon];
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


@end
