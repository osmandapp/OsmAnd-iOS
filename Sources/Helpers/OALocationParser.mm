//
//  OALocationParser.m
//  OsmAnd
//
//  Created by Paul on 02.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALocationParser.h"
#import "OASearchPhrase.h"
#import "OsmAnd_Maps-Swift.h"

#include <GeographicLib/GeoCoords.hpp>
#include <GeographicLib/MGRS.hpp>

#define SEPARATOR @"+"
#define SEPARATOR_POSITION 8

@implementation OAParsedOpenLocationCode
{
    
}

- (instancetype) initWithText:(NSString *) text
{
    self = [super init];
    if (self) {
        _text = text;
        [self parse];
    }
    return self;
}

- (void) parse
{
    if (_text.length > 0)
    {
        NSArray<NSString *> *split = [_text componentsSeparatedByString:@" "];
        if (split.count > 0)
        {
            _code = split.firstObject;
            if ([OLCConverter isValidCode:_code])
            {
                _full = [OLCConverter isFullCode:_code];
                if (_full)
                {
                    OLCArea *codeArea = [OLCConverter decode:_code];
                    _latLon = [[CLLocation alloc] initWithLatitude:codeArea.latitudeCenter longitude:codeArea.longitudeCenter];
                }
                else
                {
                    if (split.count > 1)
                    {
                        _placeName = [_text substringFromIndex:_code.length + 1];
                    }
                }
            }
            else
            {
                _code = nil;
            }
        }
    }
}

- (CLLocation *) recover:(CLLocation *) searchLocation
{
    if (_code)
    {
        NSString *newCode = [OLCConverter recoverNearestWithShortcode:_code referenceLatitude:searchLocation.coordinate.latitude referenceLongitude:searchLocation.coordinate.longitude];
        OLCArea *codeArea = [OLCConverter decode:newCode];
        _latLon = [[CLLocation alloc] initWithLatitude:codeArea.latitudeCenter longitude:codeArea.longitudeCenter];
    }
    return _latLon;
}

- (BOOL) isValidCode
{
    return _code && _code.length > 0;
}

@end

@implementation OALocationParser

+ (BOOL) isValidOLC:(NSString *) code
{
    return [OLCConverter isValidCode:code];
}

+ (BOOL) isShortCode:(NSString *) code
{
    return [OLCConverter isShortCode:code];
}

+ (OAParsedOpenLocationCode *) parseOpenLocationCode:(NSString *) locPhrase
{
    OAParsedOpenLocationCode *parsedCode = [[OAParsedOpenLocationCode alloc] initWithText:[locPhrase trim]];
    return !parsedCode.isValidCode ? nil : parsedCode;
}

+ (CLLocation *) parseLocation:(NSString *)s
{
    // detect MGRS
    //get rid of all the whitespaces
    NSArray<NSString *> *mgrsSplit = [s componentsSeparatedByString:@" "];
    NSMutableString *mgrsStr = [NSMutableString stringWithString:@""];
    for (NSString *i in mgrsSplit)
        [mgrsStr appendString:i];
    
    if ([self.class isValidMgrsString:mgrsStr])
    {
        try
        {
            int zone;
            bool northp;
            double x;
            double y;
            int prec;
            GeographicLib::MGRS::Reverse([mgrsStr UTF8String], zone, northp, x, y, prec, false);
            
            GeographicLib::GeoCoords geoCoords(zone, northp, x, y);
            return [self validateAndCreateLatitude:geoCoords.Latitude() longitude:geoCoords.Longitude()];
        }
        catch(GeographicLib::GeographicErr err)
        {
            //input was not a valid MGRS string
            //do nothing and proceed with standard parsing
        }
    }
    
    s = [s trim];
    BOOL valid = [self.class isValidLocPhrase:s];
    if (!valid)
    {
        NSArray<NSString *> *split = [s componentsSeparatedByString:@" "];
        if (split.count == 4 && [split[1] containsString:@"."] && [split[3] containsString:@"."])
        {
            s = [NSString stringWithFormat:@"%@ %@", split[1], split[3]];
            valid = [self isValidLocPhrase:s];
        }
    }
    if (!valid)
        return nil;

    NSMutableArray<NSNumber *> *d = [NSMutableArray array];
    NSMutableArray *all = [NSMutableArray array];
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    [self splitObjects:s d:d all:all strings:strings];
    if (d.count == 0)
        return nil;

    // detect UTM
    if (all.count == 4 && d.count == 3 && [all[1] isKindOfClass:[NSString class]])
    {
        unichar ch = [((NSString *)all[1]) characterAtIndex:0];
        if ([[NSCharacterSet letterCharacterSet] characterIsMember:ch])
        {
            try
            {
                GeographicLib::GeoCoords geoCoords(d[0].intValue, ch == 'n' || ch == 'N', d[1].doubleValue, d[2].doubleValue);
                return [self validateAndCreateLatitude:geoCoords.Latitude() longitude:geoCoords.Longitude()];
            }
            catch(GeographicLib::GeographicErr err)
            {
                return nil;
            }
        }
    }
    
    if (all.count == 3 && d.count == 2 && [all[1] isKindOfClass:[NSString class]])
    {
        unichar ch = [((NSString *)all[1]) characterAtIndex:0];
        NSString *combined = strings[2];
        if ([[NSCharacterSet letterCharacterSet] characterIsMember:ch])
        {
            try {
                NSString *east = [combined substringToIndex:combined.length / 2];
                NSString *north = [combined substringFromIndex:combined.length / 2];
                try
                {
                    GeographicLib::GeoCoords geoCoords(d[0].intValue, ch == 'n' || ch == 'N', east.doubleValue, north.doubleValue);
                    return [self validateAndCreateLatitude:geoCoords.Latitude() longitude:geoCoords.Longitude()];
                }
                catch(GeographicLib::GeographicErr err)
                {
                    // ignore
                }
            }
            catch (NSException *e)
            {
                // ignore
            }
        }
    }
    
    // try to find split lat/lon position
    int jointNumbers = 0;
    int lastJoin = 0;
    int degSplit = -1;
    int degType = -1; // 0 - degree, 1 - minutes, 2 - seconds
    bool finishDegSplit = false;
    int northSplit = -1;
    int eastSplit = -1;
    for (int i = 1; i < all.count; i++ )
    {
        if ([all[i - 1] isKindOfClass:[NSNumber class]] && [all[i] isKindOfClass:[NSNumber class]])
        {
            jointNumbers ++;
            lastJoin = i;
        }
        if ([strings[i] isEqualToString:@"n"] || [strings[i] isEqualToString:@"s"] ||
            [strings[i] isEqualToString:@"N"] || [strings[i] isEqualToString:@"S"])
        {
            northSplit = i + 1;
        }
        if ([strings[i] isEqualToString:@"e"] || [strings[i] isEqualToString:@"w"] ||
            [strings[i] isEqualToString:@"E"] || [strings[i] isEqualToString:@"W"])
        {
            eastSplit = i;
        }
        int dg = -1;
        if ([strings[i] isEqualToString:@"°"])
            dg = 0;
        else if ([strings[i] isEqualToString:@"\'"] || [strings[i] isEqualToString:@"′"])
            dg = 1;
        else if ([strings[i] isEqualToString:@"″"] || [strings[i] isEqualToString:@"\""])
            dg = 2;
        
        if (dg != -1)
        {
            if (!finishDegSplit)
            {
                if (degType < dg)
                {
                    degSplit = i + 1;
                    degType = dg;
                }
                else
                {
                    finishDegSplit = true;
                    degType = dg;
                }
            }
            else
            {
                if (degType < dg)
                    degType = dg;
                else
                    degSplit = -1; // reject delimiter
            }
        }
    }
    
    int split = -1;
    if (jointNumbers == 1)
        split = lastJoin;
    
    if (northSplit != -1 && northSplit < all.count -1)
        split = northSplit;
    else if (eastSplit != -1 && eastSplit < all.count -1)
        split = eastSplit;
    else if (degSplit != -1 && degSplit < all.count -1)
        split = degSplit;
    
    if (split != -1)
    {
        double lat = [self parse1Coordinate:all begin:0 end:split];
        double lon = [self parse1Coordinate:all begin:split end:(int)all.count];
        return [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    if (d.count == 2)
        return [self validateAndCreateLatitude:d[0].doubleValue longitude:d[1].doubleValue];

    // simple url case
    if ([s indexOf:@"://"] != -1)
    {
        double lat = 0;
        double lon = 0;
        bool only2decimals = true;
        for (int i = 0; i < d.count; i++)
        {
            if (d[i].doubleValue != d[i].intValue)
            {
                if (lat == 0)
                    lat = d[i].doubleValue;
                else if (lon == 0)
                    lon = d[i].doubleValue;
                else
                    only2decimals = false;
            }
        }
        if (lat != 0 && lon != 0 && only2decimals)
            return [self validateAndCreateLatitude:lat longitude:lon];
    }

    // split by equal number of digits
    if (d.count > 2 && d.count % 2 == 0)
    {
        int ind = (int)(d.count / 2) + 1;
        int splitEq = -1;
        for (int i = 0; i < all.count; i++)
        {
            if ([all[i] isKindOfClass:[NSNumber class]])
                ind --;

            if (ind == 0)
            {
                splitEq = i;
                break;
            }
        }
        if (splitEq != -1)
        {
            double lat = [self parse1Coordinate:all begin:0 end:splitEq];
            double lon = [self parse1Coordinate:all begin:splitEq end:(int)all.count];
            return [self validateAndCreateLatitude:lat longitude:lon];
        }
    }
    return nil;
}

+ (void) splitObjects:(NSString *)s d:(NSMutableArray<NSNumber *> *)d all:(NSMutableArray *)all strings:(NSMutableArray<NSString *> *)strings
{
    bool digit = false;
    int word = -1;
    for (int i = 0; i <= s.length; i++)
    {
        unichar ch = i == s.length ? ' ' : [s characterAtIndex:i];
        bool dg = [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch];
        bool nonwh = ch != ',' && ch != ' ' && ch != ';';
        if (ch == '.' || dg || ch == '-' )
        {
            if (!digit)
            {
                if (word != -1)
                {
                    [all addObject:[s substringWithRange:NSMakeRange(word, i - word)]];
                    [strings addObject:[s substringWithRange:NSMakeRange(word, i - word)]];
                }
                digit = true;
                word = i;
            }
            else
            {
                if (word == -1)
                    word = i;
            }
        }
        else
        {
            if (digit)
            {
                NSString *str = [s substringWithRange:NSMakeRange(word, i - word)];
                double dl;
                if ([[NSScanner scannerWithString:str] scanDouble:&dl])
                {
                    [d addObject:[NSNumber numberWithDouble:dl]];
                    [all addObject:[NSNumber numberWithDouble:dl]];
                    [strings addObject:str];
                    digit = false;
                    word = -1;
                }
            }
            if (nonwh)
            {
                if (![[NSCharacterSet letterCharacterSet] characterIsMember:ch])
                {
                    if (word != -1)
                    {
                        NSString *str = [s substringWithRange:NSMakeRange(word, i - word)];
                        [all addObject:str];
                        [strings addObject:str];
                    }
                    [all addObject:[s substringWithRange:NSMakeRange(i, 1)]];;
                    [strings addObject:[s substringWithRange:NSMakeRange(i, 1)]];
                    word = -1;
                }
                else if (word == -1)
                {
                    word = i;
                }
            }
            else
            {
                if (word != -1)
                {
                    NSString *str = [s substringWithRange:NSMakeRange(word, i - word)];
                    [all addObject:str];
                    [strings addObject:str];
                }
                word = -1;
            }
        }
    }
}

+ (BOOL) isValidMgrsString:(NSString *)s
{
    if (s.length < 3
        || !([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[s characterAtIndex:0]]
             || [s characterAtIndex:0] == 'A' || [s characterAtIndex:0] == 'a'
             || [s characterAtIndex:0] == 'B' || [s characterAtIndex:0] == 'b'
             || [s characterAtIndex:0] == 'Y' || [s characterAtIndex:0] == 'y'
             || [s characterAtIndex:0] == 'Z' || [s characterAtIndex:0] == 'z'
             )
        )
    {
        return false;
    }
    return true;
}

+ (BOOL) isValidLocPhrase:(NSString *)s
{
    if (s.length == 0
        || !([s characterAtIndex:0] == '-'
             || [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[s characterAtIndex:0]]
             || [s characterAtIndex:0] == 'S' || [s characterAtIndex:0] == 's'
             || [s characterAtIndex:0] == 'N' || [s characterAtIndex:0] == 'n'
             || [s indexOf:@"://"] != -1))
    {
        return false;
    }
    return true;
}

+ (double) parse1Coordinate:(NSMutableArray *)all begin:(int)begin end:(int)end
{
    bool neg = false;
    double d = 0;
    int type = 0; // degree - 0, minutes - 1, seconds = 2
    NSNumber *prevDouble = nil;
    for (int i = begin; i <= end; i++)
    {
        id o = i == end ? @"" : all[i];
        NSString *s = @"";
        NSNumber *n;
        if ([o isKindOfClass:[NSString class]])
            s = (NSString *)o;
        else if ([o isKindOfClass:[NSNumber class]])
            n = (NSNumber *)o;
        
        if ([s isEqualToString:@"S"] || [s isEqualToString:@"W"])
            neg = !neg;

        if (prevDouble)
        {
            if ([s isEqualToString:@"°"])
                type = 0;
            else if ([s isEqualToString:@"′"])  //o.equals("'")  ' can be used as delimeter ignore it
                type = 1;
            else if([s isEqualToString:@"\""] || [s isEqualToString:@"″"])
                type = 2;
            
            if (type == 0)
            {
                double ld = prevDouble.doubleValue;
                if(ld < 0)
                {
                    ld = -ld;
                    neg = true;
                }
                d += ld;
            }
            else if (type == 1)
            {
                d += prevDouble.doubleValue / 60.f;
            }
            else
            { //if (type == 1)
                d += prevDouble.doubleValue / 3600.f;
            }
            type++;
        }
        prevDouble = n;
    }
    
    if (neg)
        d = -d;

    return d;
}

+ (CLLocation *) validateAndCreateLatitude:(double)latitude longitude:(double)longitude
{
    if (ABS(latitude) <= 90 && ABS(longitude) <= 180)
        return [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    else
        return nil;
}

@end
