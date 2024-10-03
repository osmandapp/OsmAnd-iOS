//
//  OARouteColorize.mm
//  OsmAnd Maps
//
//  Created by Paul on 24.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARouteColorize.h"
#import "OARouteColorize+cpp.h"
#import "OAGPXDocumentPrimitives.h"
#import "OANode.h"
#import "OAOsmMapUtils.h"
#import "OAMapUtils.h"
#import "OsmAnd_Maps-Swift.h"
#import <CoreLocation/CoreLocation.h>

static CGFloat const defaultBase = 17.2;
static CGFloat const maxCorrectElevationDistance = 100.0; // in meters
static CGFloat const slopeRange = 150; //150 meters
static CGFloat const minDifferenceSlope = 0.05; //5%

@implementation OARouteColorizationPoint

- (instancetype)initWithIdentifier:(NSInteger)identifier lat:(CGFloat)lat lon:(CGFloat)lon val:(CGFloat)val
{
    self = [super init];
    if (self)
    {
        self.identifier = identifier;
        self.lat = lat;
        self.lon = lon;
        self.val = val;
        self.color = 0;
    }
    return self;
}

@end

@implementation OARouteColorize
{
    NSArray<NSNumber *> *_latitudes;
    NSArray<NSNumber *> *_longitudes;
    NSArray<NSNumber *> *_values;
    double _minValue;
    double _maxValue;
    ColorPalette *_palette;
    NSMutableArray<OARouteColorizationPoint *> *_dataList;
    ColorizationType _colorizationType;
}

- (instancetype) initWithGpxFile:(OASGpxFile *)gpxFile
                        analysis:(OASGpxTrackAnalysis *)analysis
                            type:(NSInteger)colorizaionType
                         palette:(ColorPalette *)palette
                 maxProfileSpeed:(float)maxProfileSpeed
{
    if (!gpxFile.hasTrkPt)
    {
        NSLog(@"GPX file is not consist of track points");
        return nil;
    }
    self = [super init];
    if (self)
    {
        _colorizationType = (ColorizationType) colorizaionType;

        NSMutableArray<NSNumber *> *latList = [NSMutableArray array];
        NSMutableArray<NSNumber *> *lonList = [NSMutableArray array];
        NSMutableArray<NSNumber *> *values = [NSMutableArray array];
        NSInteger wptIdx = 0;

        if (!analysis)
            analysis = !gpxFile.path || gpxFile.path.length == 0 ? [gpxFile getAnalysisFileTimestamp:(long) [NSDate date].timeIntervalSince1970] : [gpxFile getAnalysisFileTimestamp:0];

        for (OASTrack *trk in gpxFile.tracks)
        {
            for (OASTrkSegment *seg in trk.segments)
            {
                if (seg.generalSegment || seg.points.count < 2)
                    continue;
                
                for (OAWptPt *pt in seg.points)
                {
                    [latList addObject:@(pt.getLatitude)];
                    [lonList addObject:@(pt.getLongitude)];
                    if (colorizaionType == ColorizationTypeSpeed)
                        [values addObject:@(analysis.speedData[wptIdx].speed)];
                    else
                        [values addObject:@(analysis.elevationData[wptIdx].elevation)];
                    wptIdx++;
                }
            }
        }
        if (values.count < 2)
            return nil;

        _latitudes = latList;
        _longitudes = lonList;

        if (colorizaionType == ColorizationTypeSlope)
            _values = [self calculateSlopesByElevations:values];
        else
            _values = values;

        [self calculateMinMaxValue:analysis maxProfileSpeed:maxProfileSpeed];
        if (colorizaionType == ColorizationTypeSlope)
            _palette = [self isValidPalette:palette] ? palette : ColorPalette.slopePalette;
        else
            _palette = [[ColorPalette alloc] init:[self isValidPalette:palette] ? palette : ColorPalette.minMaxPalette minVal:_minValue
                                           maxVal:_maxValue];
    }
    return self;
}

- (BOOL)isValidPalette:(ColorPalette *)palette
{
    return palette && palette.colorValues.count >= 2;
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
        totalDistance += [OAMapUtils getDistance:_latitudes[i].doubleValue
                                            lon1:_longitudes[i].doubleValue
                                            lat2:_latitudes[i + 1].doubleValue
                                            lon2:_longitudes[i + 1].doubleValue];
        distances[i + 1] = @(totalDistance);
    }
    
    for (int i = 0; i < elevations.count; i++)
    {
        if (distances[i].doubleValue < slopeRange / 2 || distances[i].doubleValue > totalDistance - slopeRange / 2)
        {
            slopes[i] = @(NAN);
        }
        else
        {
            NSArray<NSNumber *> *arg = [self findDerivativeArguments:distances elevations:elevations index:i slopeRange:slopeRange];
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
            double leftDist = maxCorrectElevationDistance;
            double rightDist = maxCorrectElevationDistance;
            double leftElevation = NAN;
            double rightElevation = NAN;
            for (NSInteger left = i - 1; left > 0 && leftDist <= maxCorrectElevationDistance; left--)
            {
                if (!isnan(elevations[left].doubleValue))
                {
                    double dist = [OAMapUtils getDistance:_latitudes[left].doubleValue
                                                     lon1:_longitudes[left].doubleValue
                                                     lat2:_latitudes[i].doubleValue
                                                     lon2:_longitudes[i].doubleValue];
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
            for (NSInteger right = i + 1; right < elevations.count && rightDist <= maxCorrectElevationDistance; right++)
            {
                if (!isnan(elevations[right].doubleValue))
                {
                    double dist = [OAMapUtils getDistance:_latitudes[right].doubleValue
                                                     lon1:_longitudes[right].doubleValue
                                                     lat2:_latitudes[i].doubleValue
                                                     lon2:_longitudes[i].doubleValue];
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

- (NSArray<OARouteColorizationPoint *> *)getResult
{
    NSMutableArray<OARouteColorizationPoint *> *result = [NSMutableArray array];
    for (int i = 0; i < _latitudes.count; i++)
    {
        [result addObject:[[OARouteColorizationPoint alloc] initWithIdentifier:i lat:_latitudes[i].doubleValue lon:_longitudes[i].doubleValue val:_values[i].doubleValue]];
    }
    [self setColorsToPoints:result];
    return result;
}

- (QList<OsmAnd::FColorARGB>)getResultQList
{
    NSArray<OARouteColorizationPoint *> *result = [self getResult];
    QList<OsmAnd::FColorARGB> qResult;
    for (OARouteColorizationPoint *colorizationPoint in result)
    {
        qResult.append(OsmAnd::ColorARGB(colorizationPoint.color));
    }
    return qResult;
}

- (void)setColorsToPoints:(NSArray<OARouteColorizationPoint *> *)points
{
    for (OARouteColorizationPoint *point in points)
    {
        point.color = [_palette getColorByValue:point.val];
    }
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

+ (double)getMinValue:(ColorizationType)type analysis:(OASGpxTrackAnalysis *)analysis
{
    switch (type)
    {
        case ColorizationTypeSpeed:
            return .0;
        case ColorizationTypeElevation:
            return analysis.minElevation;
        case ColorizationTypeSlope:
            return ColorPalette.slopeMinValue;
        default:
            return -1;
    }
}

+ (double)getMaxValue:(ColorizationType)type analysis:(OASGpxTrackAnalysis *)analysis minValue:(double)minValue maxProfileSpeed:(double)maxProfileSpeed
{
    switch (type)
    {
        case ColorizationTypeSpeed:
            return fmax(analysis.maxSpeed, maxProfileSpeed);
        case ColorizationTypeElevation:
            return fmax(analysis.maxElevation, minValue + 50);
        case ColorizationTypeSlope:
            return ColorPalette.slopeMaxValue;
        default:
            return -1;
    }
}

- (void)calculateMinMaxValue
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

- (void)calculateMinMaxValue:(OASGpxTrackAnalysis *)analysis maxProfileSpeed:(float)maxProfileSpeed
{
    [self calculateMinMaxValue];
    // set strict limitations for maxValue
    _maxValue = [self.class getMaxValue:_colorizationType analysis:analysis minValue:_minValue maxProfileSpeed:maxProfileSpeed];
}

+ (ColorPalette *)getDefaultPalette:(NSInteger)colorizationType
{
    return colorizationType == ColorizationTypeSlope ? ColorPalette.slopePalette : ColorPalette.minMaxPalette;
}

- (ColorPalette *)getDefaultPalette
{
    if (_colorizationType == ColorizationTypeSlope)
        return ColorPalette.slopePalette;
    else
        return ColorPalette.minMaxPalette;
}

@end
