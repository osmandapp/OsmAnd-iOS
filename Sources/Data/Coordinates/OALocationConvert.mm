//
//  OALocationConvert.m
//  OsmAnd
//
//  Created by Paul on 6/29/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OALocationConvert.h"
#import "OAAppSettings.h"

#import "OsmAnd_Maps-Swift.h"

#include <GeographicLib/GeoCoords.hpp>

#define DELIM @":"
#define DELIMITER_DEGREES @"°"
#define DELIMITER_MINUTES @"′"
#define DELIMITER_SECONDS @"″"
#define DELIMITER_SPACE @" "

#define NORTH @"N"
#define SOUTH @"S"
#define WEST @"W"
#define EAST @"E"

@implementation OALocationConvert

/**
 * Converts a String in one of the formats described by
 * FORMAT_DEGREES, FORMAT_MINUTES, or FORMAT_SECONDS into a
 * double.
 *
 */
+ (double) convert:(NSString *)coordinate
{
    coordinate = [[[[[coordinate stringByReplacingOccurrencesOfString:@" " withString:@":"]
                     stringByReplacingOccurrencesOfString:@"#" withString:@":"]
                    stringByReplacingOccurrencesOfString:@"," withString:@"."]
                   stringByReplacingOccurrencesOfString:@"'" withString:@":"]
                  stringByReplacingOccurrencesOfString:@"\"" withString:@":"];
    if (!coordinate)
        return NAN;
    
    BOOL negative = NO;
    if ([coordinate characterAtIndex:0 == '-'])
    {
        coordinate = [coordinate substringWithRange:NSMakeRange(1, coordinate.length - 1)];
        negative = YES;
    }
    
    NSArray<NSString *> *tokens = [coordinate componentsSeparatedByString:@":"];
    NSInteger count = tokens.count;
    if (count < 1)
        return NAN;
    
    @try {
        NSString *degrees = tokens[0];
        double val;
        if (count == 1)
        {
            val = degrees.doubleValue;
            return negative ? -val : val;
        }
        
        NSString *minutes = tokens[1];
        NSInteger deg = degrees.integerValue;
        double min;
        double sec = 0.0;
        
        if (count > 2)
        {
            min = minutes.doubleValue;
            NSString *seconds = tokens[2];
            sec = seconds.doubleValue;
        }
        else
            min = minutes.doubleValue;
        
        BOOL isNegative180 = negative && (deg == 180) && (min == 0) && (sec == 0);
        
        // deg must be in [0, 179] except for the case of -180 degrees
        if ((deg < 0.0) || (deg > 180 && !isNegative180))
            return NAN;
        
        if (min < 0 || min > 60.)
            return NAN;
        
        if (sec < 0 || sec > 60.)
            return NAN;
        
        val = deg*3600.0 + min*60.0 + sec;
        val /= 3600.0;
        return negative ? -val : val;
    } @catch (NSException *exception) {
        return NAN;
    }
}

+ (NSString *) formatLocationCoordinates:(double) lat lon:(double)lon format:(NSInteger)outputFormat
{
    NSMutableString *result = [[NSMutableString alloc] init];
    if (outputFormat == FORMAT_DEGREES_SHORT)
    {
        [result appendString:[self.class convert:lat outputType:outputFormat]];
        [result appendString:@" "];
        [result appendString:[self.class convert:lon outputType:outputFormat]];
    }
    else if (outputFormat == FORMAT_DEGREES || outputFormat == FORMAT_MINUTES || outputFormat == FORMAT_SECONDS)
    {
        [result appendString:[NSString stringWithFormat:@"%@ %@, %@ %@", [self.class convert:lat outputType:outputFormat],
                              (lat > 0 ? NORTH : SOUTH), [self.class convert:lon outputType:outputFormat], (lon > 0 ? EAST : WEST)]] ;
    }
    else if (outputFormat == FORMAT_UTM)
    {
        [result appendString:[self.class getUTMCoordinateString:lat lon:lon]];
    }
    else if (outputFormat == FORMAT_OLC)
    {
        [result appendString:[self.class getLocationOlcName:lat lon:lon]];
    }
    return [NSString stringWithString:result];
}

+ (NSString *) convert:(double) coordinate outputType:(NSInteger)outputType
{
    if (coordinate < -180.0 || coordinate > 180.0 || coordinate == NAN)
        return nil;
    if ((outputType != FORMAT_DEGREES) &&
        (outputType != FORMAT_MINUTES) &&
        (outputType != FORMAT_SECONDS) &&
        (outputType != FORMAT_DEGREES_SHORT))
    {
        return nil;
    }
    
    NSNumberFormatter *df = [[NSNumberFormatter alloc] init];
    [df setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    NSMutableString *res = [[NSMutableString alloc] init];
    
    if (coordinate < 0)
    {
        if (outputType == FORMAT_DEGREES_SHORT)
            [res appendString:@"-"];
        coordinate = -coordinate;
    }
    
    if (outputType == FORMAT_DEGREES_SHORT)
    {
        [df setPositiveFormat:@"##00.00000"];
        [res appendString:[df stringFromNumber:@(coordinate)]];
    }
    else if (outputType == FORMAT_DEGREES)
    {
        [df setPositiveFormat:@"##00.00000"];
        [res appendString:[df stringFromNumber:@(coordinate)]];
        [res appendString:DELIMITER_DEGREES];
    }
    else if (outputType == FORMAT_MINUTES)
    {
        [df setPositiveFormat:@"00.0000"];
        [res appendString:[df stringFromNumber:@([self.class formatCoordinate:coordinate string:res delimeter:DELIMITER_DEGREES])]];
        [res appendString:DELIMITER_MINUTES];
    }
    else
    {
        [df setPositiveFormat:@"00.000"];
        [res appendString:[df stringFromNumber:@([self.class formatCoordinate:[self.class formatCoordinate:coordinate string:res delimeter:DELIMITER_DEGREES]
                                                                       string:res
                                                                    delimeter:DELIMITER_MINUTES])]];
        [res appendString:DELIMITER_SECONDS];
    }
    
    return [NSString stringWithString:res];
}

+ (double) formatCoordinate:(double) coordinate string:(NSMutableString *)str delimeter:(NSString *) delimenter
{
    NSInteger deg = floor(coordinate);
    if (deg < 10)
        [str appendString:@"0"];
    
    [str appendString:[@(deg) stringValue]];
    [str appendString:delimenter];
    coordinate -= deg;
    coordinate *= 60.0;
    return coordinate;
}

+ (NSString *) getUTMCoordinateString:(double)lat lon:(double)lon
{
    GeographicLib::GeoCoords pnt(lat, lon);
    return [NSString stringWithFormat:@"%d%c %.0f %.0f", pnt.Zone(), toupper(pnt.Hemisphere()), pnt.Easting(), pnt.Northing()];
}

+ (NSString *) getLocationOlcName:(double) lat lon:(double)lon
{
    return [OLCConverter encodeLatitude:lat longitude:lon];
}


+ (NSString *) convertLatitude:(double) latitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection
{
    if (latitude < -90.0 || latitude > 90.0 || latitude == NAN)
        return nil;
    if ((outType != MAP_GEO_FORMAT_DEGREES) && (outType != MAP_GEO_FORMAT_MINUTES) && (outType != MAP_GEO_FORMAT_SECONDS))
        return nil;
    
    NSMutableString *res = [[NSMutableString alloc] init];
    
    // Handle negative values and append cardinal directions if necessary
    if (addCardinalDirection)
        [res appendString:latitude < 0 ? @"S" : @"N"];
    else if (latitude < 0)
        [res appendString:@"-"];

    if (latitude < 0)
        latitude = -latitude;
    
    return [self.class formatDegrees:latitude outputType:outType string:res];
}

+ (NSString *) convertLongitude:(double) longitude outputType:(NSInteger)outType addCardinalDirection:(BOOL)addCardinalDirection
{
    if (longitude < -180.0 || longitude > 180.0 || longitude == NAN)
        return nil;
    if ((outType != MAP_GEO_FORMAT_DEGREES) && (outType != MAP_GEO_FORMAT_MINUTES) && (outType != MAP_GEO_FORMAT_SECONDS))
        return nil;
    
    
    NSMutableString *res = [[NSMutableString alloc] init];
    
    // Handle negative values and append cardinal directions if necessary
    if (addCardinalDirection)
        [res appendString:longitude < 0 ? @"W" : @"E"];
    else if (longitude < 0)
        [res appendString:@"-"];

    if (longitude < 0)
        longitude = -longitude;
    
    return [self.class formatDegrees:longitude outputType:outType string:res];
}

+ (NSString *) formatDegrees:(double) coordinate outputType:(NSInteger)outputType string:(NSMutableString *)string
{
    NSNumberFormatter *df = [[NSNumberFormatter alloc] init];
    [df setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    if (outputType == MAP_GEO_FORMAT_DEGREES)
    {
        [df setPositiveFormat:@"##0.0000"];
        [string appendString:[df stringFromNumber:@(coordinate)]];
        [string appendString:DELIMITER_DEGREES];
    }
    else if (outputType == MAP_GEO_FORMAT_MINUTES)
    {
        [df setPositiveFormat:@"##0.00"];
        coordinate = [self.class formatCoordinate:coordinate string:string delimeter:DELIMITER_DEGREES];
        [string appendString:DELIMITER_SPACE];
        [string appendString:[df stringFromNumber:@(coordinate)]];
        [string appendString:DELIMITER_MINUTES];
    }
    else if (outputType == MAP_GEO_FORMAT_SECONDS)
    {
        coordinate = [self.class formatCoordinate:coordinate string:string delimeter:DELIMITER_DEGREES];
        [string appendString:DELIMITER_SPACE];
        coordinate = [self.class formatCoordinate:coordinate string:string delimeter:DELIMITER_MINUTES];
        [string appendString:DELIMITER_SPACE];
        [self.class formatCoordinate:coordinate string:string delimeter:DELIMITER_SECONDS];
    }
    return [NSString stringWithString:string];
}

@end
