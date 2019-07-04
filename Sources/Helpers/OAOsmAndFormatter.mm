//
//  OAOsmAndFormatter.m
//  OsmAnd
//
//  Created by Paul on 7/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmAndFormatter.h"
#import "OAAppSettings.h"

#import "OsmAnd_Maps-Swift.h"

#include <GeographicLib/GeoCoords.hpp>

#define DELIMITER_DEGREES @"°"
#define DELIMITER_MINUTES @"′"
#define DELIMITER_SECONDS @"″"

#define NORTH @"N"
#define SOUTH @"S"
#define WEST @"W"
#define EAST @"E"

@implementation OAOsmAndFormatter

+ (NSString *) formatLocationCoordinates:(double) lat lon:(double)lon format:(NSInteger)outputFormat
{
    NSMutableString *result = [[NSMutableString alloc] init];
    if (outputFormat == FORMAT_DEGREES_SHORT)
    {
        [result appendString:[self.class formatCoordinate:lat format:outputFormat]];
        [result appendString:@" "];
        [result appendString:[self.class formatCoordinate:lon format:outputFormat]];
    }
    else if (outputFormat == FORMAT_DEGREES || outputFormat == FORMAT_MINUTES || outputFormat == FORMAT_SECONDS)
    {
        [result appendString:[NSString stringWithFormat:@"%@ %@, %@ %@", [self.class formatCoordinate:lat format:outputFormat],
          (lat > 0 ? NORTH : SOUTH), [self.class formatCoordinate:lon format:outputFormat], (lon > 0 ? EAST : WEST)]] ;
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

+ (NSString *) formatCoordinate:(double) coordinate format:(NSInteger)outputType
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

@end
