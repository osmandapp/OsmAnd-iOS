//
//  OARouteColorizationHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 24.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARouteColorizationHelper.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXTrackAnalysis.h"

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Utilities.h>

#define SLOPE_MIN_VALUE -0.25 // 25%
#define SLOPE_MAX_VALUE 1.0 // 100%

#define DEFAULT_BASE 17.2
#define MAX_CORRECT_ELEVATION_DISTANCE 100.0 // in meters

#define SLOPE_RANGE 150 //150 meters
#define MIN_DIFFERENCE_SLOPE 0.05 //5%

#define VALUE_INDEX 0
#define DECIMAL_COLOR_INDEX 1 //sRGB decimal format
#define RED_COLOR_INDEX 1 //RGB
#define GREEN_COLOR_INDEX 2 //RGB
#define BLUE_COLOR_INDEX 3 //RGB
#define ALPHA_COLOR_INDEX 4 //RGBA

// Colors
#define LIGHT_GRAY 0xFFC8C8C8
#define GREEN 0xFF5ADC5F
#define YELLOW 0xFFD4EF32
#define RED 0xFFF3374D
#define GREEN_SLOPE 0xFF2EB900
#define WHITE 0xFFFFFFFF
#define YELLOW_SLOPE 0xFFFFDE02
#define RED_SLOPE 0xFFFF0101
#define PURPLE_SLOPE 0xFF8201FF

static NSArray<NSNumber *> *colors;
static NSArray<NSNumber *> *slopeColors;
static NSArray<NSArray<NSNumber *> *> *slopePalette;

@implementation OARouteColorizationHelper
{
    QList<OsmAnd::FColorARGB> _colorMap;
    NSArray<NSNumber *> *_latitudes;
    NSArray<NSNumber *> *_longitudes;
    NSArray<NSNumber *> *_values;
    
    double _minValue;
    double _maxValue;
    
    NSArray<NSArray<NSNumber *> *> *_palette;
    
    EOAColorizationType _colorizationType;
}

+ (void) initialize
{
    if (self == [OARouteColorizationHelper class])
    {
        colors = @[@(GREEN), @(YELLOW), @(RED)];
        slopeColors = @[@(GREEN_SLOPE), @(WHITE), @(YELLOW_SLOPE), @(RED_SLOPE), @(PURPLE_SLOPE)];
        slopePalette = @[@[@(SLOPE_MIN_VALUE), @(GREEN_SLOPE)], @[@(0.0), @(WHITE)], @[@(0.125), @(YELLOW_SLOPE)], @[@(0.25), @(RED_SLOPE)], @[@(SLOPE_MAX_VALUE), @(PURPLE_SLOPE)]];
    }
}

- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile analysis:(OAGPXTrackAnalysis *)analysis type:(EOAColorizationType)type maxProfileSpeed:(float)maxProfileSpeed
{
    if (!gpxFile.hasTrkPt)
    {
        NSLog(@"GPX file is not consist of track points");
        return nil;
    }
    self = [super init];
    if (self)
    {
        _colorizationType = type;
        
        NSMutableArray<NSNumber *> *latList = [NSMutableArray array];
        NSMutableArray<NSNumber *> *lonList = [NSMutableArray array];
        NSMutableArray<NSNumber *> *values = [NSMutableArray array];
        NSInteger wptIdx = 0;
        
        if (analysis)
        {
            // TODO: sync with android
//            gpxFile.path.length == 0 ? [gpxFile getAnalysis:[NSDate date].timeIntervalSince1970] : [gpxFile getAnalysis:gpxFile.modifiedTime]
            analysis = [gpxFile getAnalysis:0];
        }
        for (OAGpxTrk *trk in gpxFile.tracks)
        {
            for (OAGpxTrkSeg *seg in trk.segments)
            {
                if (seg.generalSegment || seg.points.count < 2)
                    continue;
                
                for (OAWptPt *pt in seg.points)
                {
                    [latList addObject:@(pt.getLatitude)];
                    [lonList addObject:@(pt.getLongitude)];
                    if (type == EOAColorizationTypeSpeed)
                        [values addObject:@(analysis.speedData[wptIdx].speed)];
                    else
                        [values addObject:@(analysis.elevationData[wptIdx].elevation)];
                    wptIdx++;
                }
            }
        }
        _latitudes = latList;
        _longitudes = lonList;
        
        if (type == EOAColorizationTypeSlope)
            _values = [self calculateSlopesByElevations:values];
        else
            _values = values;
        
        [self calculateMinMaxValue:analysis maxProfileSpeed:maxProfileSpeed];
        [self checkPalette];
        [self sortPalette];
    }
    return self;
}

/**
     * Calculate slopes from elevations needs for right colorizing
     *
     * @param slopeRange - in what range calculate the derivative, usually we used 150 meters
     * @return slopes array, in the begin and the end present NaN values!
     */
- (NSArray<NSNumber *> *) calculateSlopesByElevations:(NSMutableArray<NSNumber *> *)elevations
{
    [self correctElevations:elevations];
    NSMutableArray<NSNumber *> *newElevations = [NSMutableArray arrayWithArray:elevations];
    for (NSInteger i = 2; i < elevations.count - 2; i++)
    {
        newElevations[i] = @(elevations[i - 2].doubleValue
        + elevations[i - 1].doubleValue
        + elevations[i].doubleValue
        + elevations[i + 1].doubleValue
        + elevations[i + 2].doubleValue);
        newElevations[i] = @(newElevations[i].doubleValue / 5);
    }
    elevations = newElevations;
    
    NSMutableArray<NSNumber *> *slopes = [NSMutableArray arrayWithCapacity:elevations.count];
    if (_latitudes.count != _longitudes.count || _latitudes.count != elevations.count) {
        NSLog(@"Sizes of arrays latitudes, longitudes and values are not match");
        return slopes;
    }
    
    NSMutableArray<NSNumber *> *distances = [NSMutableArray arrayWithCapacity:elevations.count];
    double totalDistance = 0.0;
    distances[0] = @(totalDistance);
    for (NSInteger i = 0; i < elevations.count - 1; i++)
    {
        totalDistance += getDistance(_latitudes[i].doubleValue, _longitudes[i].doubleValue, _latitudes[i + 1].doubleValue, _longitudes[i + 1].doubleValue);
        distances[i + 1] = @(totalDistance);
    }
    
    for (int i = 0; i < elevations.count; i++)
    {
        if (distances[i].doubleValue < SLOPE_RANGE / 2 || distances[i].doubleValue > totalDistance - SLOPE_RANGE / 2)
        {
            slopes[i] = @(NAN);
        }
        else
        {
            NSArray<NSNumber *> *arg = [self findDerivativeArguments:distances elevations:elevations index:i slopeRange:SLOPE_RANGE];
            slopes[i] = @((arg[1].doubleValue - arg[0].doubleValue) / (arg[3].doubleValue - arg[2].doubleValue));
        }
    }
    return slopes;
}

- (void) correctElevations:(NSMutableArray<NSNumber *> *)elevations
{
    for (NSInteger i = 0; i < elevations.count; i++)
    {
        if (isnan(elevations[i].doubleValue))
        {
            double leftDist = MAX_CORRECT_ELEVATION_DISTANCE;
            double rightDist = MAX_CORRECT_ELEVATION_DISTANCE;
            double leftElevation = NAN;
            double rightElevation = NAN;
            for (NSInteger left = i - 1; left > 0 && leftDist <= MAX_CORRECT_ELEVATION_DISTANCE; left--)
            {
                if (!isnan(elevations[left].doubleValue))
                {
                    double dist = getDistance(_latitudes[left].doubleValue, _longitudes[left].doubleValue, _latitudes[i].doubleValue, _longitudes[i].doubleValue);
                    if (dist < leftDist)
                    {
                        leftDist = dist;
                        leftElevation = elevations[left].doubleValue;
                    } else
                    {
                        break;
                    }
                }
            }
            for (NSInteger right = i + 1; right < elevations.count && rightDist <= MAX_CORRECT_ELEVATION_DISTANCE; right++)
            {
                if (!isnan(elevations[right].doubleValue))
                {
                    double dist = getDistance(_latitudes[right].doubleValue, _longitudes[right].doubleValue, _latitudes[i].doubleValue, _longitudes[i].doubleValue);
                    if (dist < rightDist)
                    {
                        rightElevation = elevations[right].doubleValue;
                        rightDist = dist;
                    } else
                    {
                        break;
                    }
                }
            }
            if (!isnan(leftElevation) && !isnan(rightElevation))
            {
                elevations[i] = @((leftElevation + rightElevation) / 2);
            } else if (isnan(leftElevation) && !isnan(rightElevation))
            {
                elevations[i] = @(rightElevation);
            } else if (!isnan(leftElevation) && isnan(rightElevation))
            {
                elevations[i] = @(leftElevation);
            }
            else
            {
                for (NSInteger right = i + 1; right < elevations.count; right++)
                {
                    if (!isnan(elevations[right].doubleValue)) {
                        elevations[i] = elevations[right];
                        break;
                    }
                }
            }
        }
    }
}

- (QList<OsmAnd::FColorARGB>) getResult
{
    QList<OsmAnd::FColorARGB> result;
    for (int i = 0; i < _values.count; i++)
    {
        result.push_back([self getColorByValue:_values[i].doubleValue]);
    }
    return result;
}

- (OsmAnd::FColorARGB) getColorByValue:(double)value
{
    if (isnan(value))
        return OsmAnd::ColorARGB(LIGHT_GRAY);
    
    for (int i = 0; i < _palette.count - 1; i++)
    {
        if (value == _palette[i][VALUE_INDEX].doubleValue)
            return OsmAnd::ColorARGB(_palette[i][DECIMAL_COLOR_INDEX].intValue);
        if (value >= _palette[i][VALUE_INDEX].doubleValue && value <= _palette[i + 1][VALUE_INDEX].doubleValue)
        {
            int minPaletteColor = _palette[i][DECIMAL_COLOR_INDEX].intValue;
            int maxPaletteColor = _palette[i + 1][DECIMAL_COLOR_INDEX].intValue;
            double minPaletteValue = _palette[i][VALUE_INDEX].doubleValue;
            double maxPaletteValue = _palette[i + 1][VALUE_INDEX].doubleValue;
            double percent = (value - minPaletteValue) / (maxPaletteValue - minPaletteValue);
            return [self.class getIntermediateColor:minPaletteColor maxPaletteColor:maxPaletteColor percent:percent];
        }
    }
    if (value <= _palette[0][0].doubleValue)
        return OsmAnd::ColorARGB(_palette[0][1].intValue);
    else if (value >= _palette.lastObject[0].doubleValue)
        return OsmAnd::ColorARGB(_palette.lastObject[1].intValue);
    return OsmAnd::FColorARGB(0., 0., 0., 0);
}

/**
 * @return double[minElevation, maxElevation, minDist, maxDist]
 */
- (NSArray<NSNumber *> *) findDerivativeArguments:(NSArray<NSNumber *> *)distances elevations:(NSArray<NSNumber *> *)elevations index:(NSInteger)index slopeRange:(double)slopeRange
{
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:4];
    double minDist = distances[index].doubleValue - slopeRange / 2;
    double maxDist = distances[index].doubleValue + slopeRange / 2;
    result[0] = @(NAN);
    result[1] = @(NAN);
    result[2] = @(minDist);
    result[3] = @(maxDist);
    NSInteger closestMaxIndex = -1;
    NSInteger closestMinIndex = -1;
    for (NSInteger i = index; i < distances.count; i++)
    {
        if (distances[i].doubleValue == maxDist)
        {
            result[1] = elevations[i];
            break;
        }
        if (distances[i].doubleValue > maxDist)
        {
            closestMaxIndex = i;
            break;
        }
    }
    for (NSInteger i = index; i >= 0; i--)
    {
        if (distances[i].doubleValue == minDist)
        {
            result[0] = elevations[i];
            break;
        }
        if (distances[i].doubleValue < minDist)
        {
            closestMinIndex = i;
            break;
        }
    }
    if (closestMaxIndex > 0) {
        double diff = distances[closestMaxIndex].doubleValue - distances[closestMaxIndex - 1].doubleValue;
        double coef = (maxDist - distances[closestMaxIndex - 1].doubleValue) / diff;
        if (coef > 1 || coef < 0)
            NSLog(@"Coefficient fo max must be 0..1 , coef=%f", coef);

        result[1] = @((1 - coef) * elevations[closestMaxIndex - 1].doubleValue + coef * elevations[closestMaxIndex].doubleValue);
    }
    if (closestMinIndex >= 0)
    {
        double diff = distances[closestMinIndex + 1].doubleValue - distances[closestMinIndex].doubleValue;
        double coef = (minDist - distances[closestMinIndex].doubleValue) / diff;
        if (coef > 1 || coef < 0)
            NSLog(@"Coefficient for min must be 0..1 , coef=%f", coef);
        result[0] = @((1 - coef) * elevations[closestMinIndex].doubleValue + coef * elevations[closestMinIndex + 1].doubleValue);
    }
    if (isnan(result[0].doubleValue) || isnan(result[1].doubleValue))
        NSLog(@"Elevations weren't calculated");
    return result;
}

- (void) calculateMinMaxValue
{
    if (_values.count == 0)
        return;
    _minValue = _maxValue = NAN;
    for (NSNumber *numValue in _values)
    {
        double value = numValue.doubleValue;
        if ((isnan(_maxValue) || isnan(_minValue)) && !isnan(value))
            _maxValue = _minValue = value;
        if (_minValue > value)
            _minValue = value;
        if (_maxValue < value)
            _maxValue = value;
    }
}

- (void) calculateMinMaxValue:(OAGPXTrackAnalysis *)analysis maxProfileSpeed:(float)maxProfileSpeed
{
    [self calculateMinMaxValue];
    // set strict limitations for maxValue
    _maxValue = [self.class getMaxValue:_colorizationType analysis:analysis minValue:_minValue maxProfileSpeed:maxProfileSpeed];
}

- (void) checkPalette
{
    if (_palette == nil || _palette.count < 2 || _palette[0].count < 2 || _palette[1].count < 2)
    {
        NSLog(@"Will use default palette");
        _palette = [self getDefaultPalette];
    }
    double min;
    double max = min = _palette[0][VALUE_INDEX].doubleValue;
    int minIndex = 0;
    int maxIndex = 0;
    NSMutableArray<NSArray<NSNumber *> *> *sRGBPalette = [NSMutableArray arrayWithCapacity:_palette.count];
    for (int i = 0; i < _palette.count; i++)
    {
        NSArray<NSNumber *> *p = _palette[i];
        if (p.count == 2)
        {
            sRGBPalette[i] = p;
        }
        else if (p.count == 4)
        {
            int color = [self.class rgbaToDecimal:p[RED_COLOR_INDEX].intValue g:p[GREEN_COLOR_INDEX].intValue b:p[BLUE_COLOR_INDEX].intValue a:255];
            sRGBPalette[i] = @[p[VALUE_INDEX], @(color)];
        } else if (p.count >= 5) {
            int color = [self.class rgbaToDecimal:p[RED_COLOR_INDEX].intValue g:p[GREEN_COLOR_INDEX].intValue b:p[BLUE_COLOR_INDEX].intValue a:p[ALPHA_COLOR_INDEX].intValue];
            sRGBPalette[i] = @[p[VALUE_INDEX], @(color)];
        }
        if (p[VALUE_INDEX].doubleValue > max) {
            max = p[VALUE_INDEX].doubleValue;
            maxIndex = i;
        }
        if (p[VALUE_INDEX].doubleValue < min) {
            min = p[VALUE_INDEX].doubleValue;
            minIndex = i;
        }
    }
    if (_minValue < min)
    {
        NSMutableArray<NSNumber *> *paletteArray = [NSMutableArray arrayWithArray:sRGBPalette[minIndex]];
        paletteArray[VALUE_INDEX] = @(_minValue);
        sRGBPalette[minIndex] = paletteArray;
    }
    if (_maxValue > max)
    {
        NSMutableArray<NSNumber *> *paletteArray = [NSMutableArray arrayWithArray:sRGBPalette[maxIndex]];
        paletteArray[VALUE_INDEX] = @(_maxValue);
        sRGBPalette[maxIndex] = paletteArray;
    }
    _palette = sRGBPalette;
}

- (void) sortPalette
{
    _palette = [_palette sortedArrayUsingComparator:^NSComparisonResult(NSArray<NSNumber *> * obj1, NSArray<NSNumber *> * obj2) {
        return [obj1[VALUE_INDEX] compare:obj2[VALUE_INDEX]];
    }];
}

- (NSArray<NSArray<NSNumber *> *> *) getDefaultPalette
{
    if (_colorizationType == EOAColorizationTypeSlope)
        return slopePalette;
    else
        return @[@[@(_minValue), @(GREEN)], @[@((_minValue + _maxValue) / 2), @(YELLOW)], @[@(_maxValue), @(RED)]];
}


+ (double) getMaxValue:(EOAColorizationType)type analysis:(OAGPXTrackAnalysis *)analysis minValue:(double)minValue maxProfileSpeed:(double)maxProfileSpeed
{
    switch (type) {
        case EOAColorizationTypeSpeed:
            return fmax(analysis.maxSpeed, maxProfileSpeed);
        case EOAColorizationTypeElevation:
            return fmax(analysis.maxElevation, minValue + 50);
        case EOAColorizationTypeSlope:
            return SLOPE_MAX_VALUE;
        default:
            return -1;
    }
}

+ (int) rgbaToDecimal:(int)r g:(int)g b:(int)b a:(int)a
{
    int value = ((a & 0xFF) << 24) |
    ((r & 0xFF) << 16) |
    ((g & 0xFF) << 8)  |
    ((b & 0xFF) << 0);
    return value;
}

+ (OsmAnd::FColorARGB) getIntermediateColor:(int)minPaletteColor maxPaletteColor:(int)maxPaletteColor percent:(double)percent
{
    double resultRed = [self getRed:minPaletteColor] + percent * ([self getRed:maxPaletteColor] - [self getRed:minPaletteColor]);
    double resultGreen = [self getGreen:minPaletteColor] + percent * ([self getGreen:maxPaletteColor] - [self getGreen:minPaletteColor]);
    double resultBlue = [self getBlue:minPaletteColor] + percent * ([self getBlue:maxPaletteColor] - [self getBlue:minPaletteColor]);
    double resultAlpha = [self getAlpha:minPaletteColor] + percent * ([self getAlpha:maxPaletteColor] - [self getAlpha:minPaletteColor]);
    return OsmAnd::ColorARGB([self.class rgbaToDecimal:(int)resultRed g:(int)resultGreen b:(int)resultBlue a:(int)resultAlpha]);
}

+ (int) getRed:(int)value
{
    return (value >> 16) & 0xFF;
}

+ (int) getGreen:(int)value
{
    return (value >> 8) & 0xFF;
}

+ (int) getBlue:(int)value
{
    return (value >> 0) & 0xFF;
}

+ (int) getAlpha:(int) value
{
    return (value >> 24) & 0xff;
}

@end
