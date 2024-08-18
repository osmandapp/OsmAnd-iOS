//
//  OAGPXTrackAnalysis.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OALocationServices.h"
#import "OARouteColorize.h"
#import "OAMapUtils.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAPluginsHelper.h"

#include <OsmAndCore/Utilities.h>


@implementation OASplitMetric

-(double) metric:(OAWptPt *)p1 p2:(OAWptPt *)p2 { return 0; };

@end


@implementation OADistanceMetric

-(double) metric:(OAWptPt *)p1 p2:(OAWptPt *)p2
{
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:p1.position.latitude longitude:p1.position.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:p2.position.latitude longitude:p2.position.longitude];
    return [loc1 distanceFromLocation:loc2];
}

@end


@implementation OATimeSplit

-(double)metric:(OAWptPt *)p1 p2:(OAWptPt *)p2
{
    if(p1.time != 0 && p2.time != 0) {
        return abs((p2.time - p1.time));
    }
    return 0;
}

@end

@implementation OAElevation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstPoint = NO;
        _lastPoint = NO;
    }
    return self;
}

@end

@implementation OASpeed

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstPoint = NO;
        _lastPoint = NO;
    }
    return self;
}

@end

@implementation OASplitSegment

- (instancetype)initWithTrackSegment:(OATrkSegment *)s
{
    self = [super init];
    if (self) {
        _startPointInd = 0;
        _startCoeff = 0;
        _endPointInd = (int)s.points.count - 2;
        _endCoeff = 1;
        self.segment = s;
    }
    return self;
}

- (instancetype)initWithSplitSegment:(OATrkSegment *)s pointInd:(int)pointInd cf:(double)cf
{
    self = [super init];
    if (self) {
        _startPointInd = 0;
        _startCoeff = 0;
        _startPointInd = pointInd;
        _startCoeff = cf;
        self.segment = s;
    }
    return self;
}

-(int) getNumberOfPoints
{
    return _endPointInd - _startPointInd + 2;
}

-(OAWptPt *)get:(int)j
{
    int ind = j + _startPointInd;
    if(j == 0) {
        if(_startCoeff == 0) {
            return [self.segment.points objectAtIndex:ind];
        }
         return [self approx:[self.segment.points objectAtIndex:ind] w2:[self.segment.points objectAtIndex:ind + 1] cf:_startCoeff];
    }
    if(j == [self getNumberOfPoints] - 1) {
        if(_endCoeff == 1) {
            return [self.segment.points objectAtIndex:ind];
        }
        return [self approx:[self.segment.points objectAtIndex:ind - 1] w2:[self.segment.points objectAtIndex:ind] cf:_endCoeff];
    }
    return [self.segment.points objectAtIndex:ind];
}


-(OAWptPt *) approx:(OAWptPt *)w1 w2:(OAWptPt *)w2 cf:(double)cf
{
    long time = [self valueLong:w1.time vl2:w2.time none:0 cf:cf];
    double speed = [self valueDbl:w1.speed vl2:w2.speed none:0 cf:cf];
    double ele = [self valueDbl:w1.elevation vl2:w2.elevation none:0 cf:cf];
    double hdop = [self valueDbl:w1.horizontalDilutionOfPrecision vl2:w2.horizontalDilutionOfPrecision none:0 cf:cf];
    double lat = [self valueDbl:w1.position.latitude vl2:w2.position.latitude none:-360 cf:cf];
    double lon = [self valueDbl:w1.position.longitude vl2:w2.position.longitude none:-360 cf:cf];
    
    OAWptPt *wpt = [[OAWptPt alloc] init];
    wpt.position = CLLocationCoordinate2DMake(lat, lon);
    wpt.time = time;
    wpt.elevation = ele;
    wpt.speed = speed;
    wpt.horizontalDilutionOfPrecision = hdop;
    
    return wpt;
}

-(double) valueDbl:(double)vl vl2:(double)vl2 none:(double)none cf:(double)cf
{
    if (vl == none || isnan(vl)) {
        return vl2;
    } else if (vl2 == none || isnan(vl2)) {
        return vl;
    }
    return vl + cf * (vl2 - vl);
}

-(long) valueLong:(long)vl vl2:(long)vl2 none:(long)none cf:(double)cf
{
    if(vl == none) {
        return vl2;
    } else if(vl2 == none) {
        return vl;
    }
    return vl + ((long) (cf * (vl2 - vl)));
}

-(double) setLastPoint:(int)pointInd endCf:(double)endCf
{
    _endCoeff = endCf;
    _endPointInd = pointInd;
    return _endCoeff;
}

@end

@implementation OAGPXTrackAnalysis

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _totalDistance = 0.0;
        _totalTracks = 0;
        _startTime = LONG_MAX;
        _endTime = LONG_MIN;
        _timeSpan = 0;
        _timeMoving = 0;
        _totalDistanceMoving = 0.0;
        
        _diffElevationUp = 0.0;
        _diffElevationDown = 0.0;
        _avgElevation = 0.0;
        _minElevation = 99999.0;
        _maxElevation = -100.0;
        _timeSpanWithoutGaps = 0;
        _totalDistanceWithoutGaps = 0.0;
        _timeMovingWithoutGaps = 0.0;
        _totalDistanceMovingWithoutGaps = 0.0;
        _left = 0;
        _right = 0;
        _bottom = 0;
        _top = 0;
        
        _maxSpeed = 0.0;
        _minSpeed = FLT_MAX;
        
        _wptPoints = 0;
        
    }
    return self;
}

- (BOOL) isColorizationTypeAvailable:(NSInteger)colorizationType
{
    if (colorizationType == ColorizationTypeSpeed)
        return [self isSpeedSpecified];
    else if (colorizationType == ColorizationTypeElevation || colorizationType == ColorizationTypeSlope)
        return [self isElevationSpecified];
    else
        return YES;
}
 
-(BOOL) isTimeSpecified
{
    return _startTime != LONG_MAX && _startTime != 0;
}

-(BOOL) isTimeMoving
{
    return _timeMoving != 0;
}

-(BOOL) isElevationSpecified
{
    return _maxElevation != -100;
}

-(int) getTimeHours:(long)time
{
    return (int) ((time / 1000) / 3600);
}


-(int) getTimeSeconds:(long)time
{
    return (int) ((time / 1000) % 60);
}

-(int) getTimeMinutes:(long)time
{
    return (int) (((time / 1000) / 60) % 60);
}

-(BOOL) isSpeedSpecified
{
    return _avgSpeed > 0.0;
}

- (BOOL)hasData:(NSString *)tag
{
    if ([tag isEqualToString:OAPointAttributes.sensorTagTemperature])
        return [_availableAttributes containsObject:OAPointAttributes.sensorTagTemperatureW] || [_availableAttributes containsObject:OAPointAttributes.sensorTagTemperatureA];
    return [_availableAttributes containsObject:tag];
}

- (void)setTag:(NSString *)tag hasData:(BOOL)hasData
{
    if (hasData)
        [_availableAttributes addObject:tag];
    else
        [_availableAttributes removeObject:tag];
}

+(OAGPXTrackAnalysis *) segment:(long)fileTimestamp seg:(OATrkSegment *)seg
{
    OAGPXTrackAnalysis *obj = [[OAGPXTrackAnalysis alloc] init];
    [obj prepareInformation:fileTimestamp splitSegments:@[[[OASplitSegment alloc] initWithTrackSegment:seg]]];
    return obj;
}

-(void) prepareInformation:(long)fileStamp  splitSegments:(NSArray *)splitSegments
{
    long startTimeOfSingleSegment = 0;
    long endTimeOfSingleSegment = 0;
    
    float distanceOfSingleSegment = 0;
    float distanceMovingOfSingleSegment = 0;
    long timeMovingOfSingleSegment = 0;
    
    float totalElevation = 0;
    NSInteger elevationPoints = 0;
    NSInteger speedCount = 0;
    NSInteger timeDiffSec = 0;
    double totalSpeedSum = 0;
    _points = 0;

    _pointAttributes = [NSMutableArray array];
    _availableAttributes = [NSMutableSet set];

    NSMutableArray<OAElevation *> *elevationData = [NSMutableArray new];
    NSMutableArray<OASpeed *> *speedData = [NSMutableArray new];
    
    for (OASplitSegment *s in splitSegments)
    {
        int numberOfPoints = s.getNumberOfPoints;
        float segmentDistance = 0.;
        _metricEnd += s.metricEnd;
        _secondaryMetricEnd += s.secondaryMetricEnd;
        _points += numberOfPoints;
        for (NSInteger j = 0; j < numberOfPoints; j++)
        {
            OAWptPt *point = [s get:j];
            if (j == 0 && self.locationStart == nil)
                _locationStart = point;
            if (j == numberOfPoints - 1)
                _locationEnd = point;
            
            long time = point.time;
            if (time != 0)
            {
                if (s.metricEnd == 0)
                {
                    if (s.segment.generalSegment)
                    {
                        if (point.firstPoint)
                            startTimeOfSingleSegment = time;
                        else if (point.lastPoint)
                            endTimeOfSingleSegment = time;
                        
                        if (startTimeOfSingleSegment != 0 && endTimeOfSingleSegment != 0)
                        {
                            _timeSpanWithoutGaps += endTimeOfSingleSegment - startTimeOfSingleSegment;
                            startTimeOfSingleSegment = 0;
                            endTimeOfSingleSegment = 0;
                        }
                    }
                }
                _startTime = MIN(_startTime, time);
                _endTime = MAX(_endTime, time);
            }
            
            if (_left == 0 && _right == 0)
            {
                _left = point.getLongitude;
                _right = point.getLongitude;
                _top = point.getLatitude;
                _bottom = point.getLatitude;
            }
            else
            {
                _left = MIN(_left, point.getLongitude);
                _right = MAX(_right, point.getLongitude);
                _top = MAX(_top, point.getLatitude);
                _bottom = MIN(_bottom, point.getLatitude);
            }
            
            CLLocationDistance elevation = point.elevation;
            OAElevation *elevation1 = [[OAElevation alloc] init];
            if (!isnan(elevation))
            {
                totalElevation += elevation;
                elevationPoints++;
                _minElevation = MIN(elevation, _minElevation);
                _maxElevation = MAX(elevation, _maxElevation);
                
                elevation1.elevation = elevation;
            }
            else
            {
                elevation1.elevation = NAN;
            }
            
            CLLocationSpeed speed = point.speed;
            if (speed > 0)
                _hasSpeedInTrack = YES;
            
            // float[1] calculations
            double distance = 0, bearing = 0;
            
            if (j > 0) {
                OAWptPt *prev = [s get:j - 1];
                
                // Old complete summation approach for elevation gain/loss
                //if (!Double.isNaN(point.ele) && !Double.isNaN(prev.ele)) {
                //    double diff = point.ele - prev.ele;
                //    if (diff > 0) {
                //        diffElevationUp += diff;
                //    } else {
                //        diffElevationDown -= diff;
                //    }
                //}
                
                // totalDistance += MapUtils.getDistance(prev.lat, prev.lon, point.lat, point.lon);
                // using ellipsoidal 'distanceBetween' instead of spherical haversine (MapUtils.getDistance) is
                // a little more exact, also seems slightly faster:
                [OALocationServices computeDistanceAndBearing:prev.getLatitude lon1:prev.getLongitude lat2:point.getLatitude lon2:point.getLongitude distance:&distance initialBearing:&bearing];
                _totalDistance += distance;
                segmentDistance += distance;
                point.distance = segmentDistance;
                timeDiffSec = MAX(0, point.time - prev.time);
                //Last resort: Derive speed values from displacement if track does not originally contain speed
                if (!self.hasSpeedInTrack && speed == 0 && timeDiffSec > 0)
                    speed = distance / timeDiffSec;
                
                // Motion detection:
                //   speed > 0  uses GPS chipset's motion detection
                //   calculations[0] > minDisplacment * time  is heuristic needed because tracks may be filtered at recording time, so points at rest may not be present in file at all
                BOOL timeSpecified = point.time != 0 && prev.time != 0;
                if (speed > 0 && timeSpecified && distance > timeDiffSec / 10.)
                {
                    _timeMoving += timeDiffSec;
                    _totalDistanceMoving += distance;
                    if (s.segment.generalSegment && !point.firstPoint)
                    {
                        timeMovingOfSingleSegment += timeDiffSec;
                        distanceMovingOfSingleSegment += distance;
                    }
                }
                
                //Next few lines for Issue 3222 heuristic testing only
                //    if (speed > 0 && point.time != 0 && prev.time != 0) {
                //        timeMoving0 = timeMoving0 + (point.time - prev.time);
                //        totalDistanceMoving0 += calculations[0];
                //    }
            }
            
            elevation1.time = timeDiffSec;
            elevation1.distance = (j > 0) ? distance : 0;
            [elevationData addObject:elevation1];
            if (!_hasElevationData && !isnan(elevation1.elevation) && _totalDistance > 0)
                _hasElevationData = YES;
            
            _minSpeed = MIN(speed, _minSpeed);
            if (speed > 0)
            {
                totalSpeedSum += speed;
                _maxSpeed = MAX(speed, _maxSpeed);
                speedCount++;
            }
            
            OASpeed *speed1 = [[OASpeed alloc] init];
            speed1.speed = speed;
            speed1.time = timeDiffSec;
            speed1.distance = elevation1.distance;
            [speedData addObject:speed1];
            if (!_hasSpeedData && speed1.speed > 0 && _totalDistance > 0)
                _hasSpeedData = YES;

            BOOL firstPoint = NO;
            BOOL lastPoint = NO;
            if (s.segment.generalSegment)
            {
                distanceOfSingleSegment += distance;
                if (point.firstPoint)
                {
                    firstPoint = j > 0;
                    distanceOfSingleSegment = 0;
                    timeMovingOfSingleSegment = 0;
                    distanceMovingOfSingleSegment = 0;
                    if (firstPoint)
                    {
                        elevation1.firstPoint = YES;
                        speed1.firstPoint = YES;
                    }
                }
                if (point.lastPoint)
                {
                    lastPoint = j < numberOfPoints - 1;
                    _totalDistanceWithoutGaps += distanceOfSingleSegment;
                    _timeMovingWithoutGaps += timeMovingOfSingleSegment;
                    _totalDistanceMovingWithoutGaps += distanceMovingOfSingleSegment;
                    if (lastPoint)
                    {
                        elevation1.lastPoint = true;
                        speed1.lastPoint = true;
                    }
                }
            }
            float attrDistance = (j > 0) ? distance : 0;
            OAPointAttributes *attribute = [[OAPointAttributes alloc] initWithDistance:attrDistance timeDiff:timeDiffSec firstPoint:firstPoint lastPoint:lastPoint];
            attribute.speed = speed;
            attribute.elevation = elevation;
            [self addWptAttribute:point attribute:attribute];
        }
        OAElevationApproximator *approximator = [[OAElevationApproximator alloc] init];
        NSArray<OAApproxResult *> *approxData = [approximator approximate:s];
        if (approxData)
        {
            OAElevationDiffsCalculator *elevationDiffsCalc = [[OAElevationDiffsCalculator alloc] initWithApproxData:approxData];
            [elevationDiffsCalc calculateElevationDiffs];
            _diffElevationUp += elevationDiffsCalc.diffElevationUp;
            _diffElevationDown += elevationDiffsCalc.diffElevationDown;
        }
    }
    if (_totalDistance < 0)
    {
        _hasElevationData = NO;
        _hasSpeedData = NO;
        [_availableAttributes removeAllObjects];
    }

    if (![self isTimeSpecified])
    {
        _startTime = fileStamp;
        _endTime = fileStamp;
    }
    
    // OUTPUT:
    // 1. Total distance, Start time, End time
    // 2. Time span
    if (_timeSpan == 0) {
        _timeSpan = _endTime - _startTime;
    }
    
    // 3. Time moving, if any
    // 4. Elevation, eleUp, eleDown, if recorded
    if (elevationPoints > 0)
        _avgElevation = totalElevation / elevationPoints;
    
    // 5. Max speed and Average speed, if any. Average speed is NOT overall (effective) speed, but only calculated for "moving" periods.
    //    Averaging speed values is less precise than totalDistanceMoving/timeMoving
    if (speedCount > 0)
    {
        if (_timeMoving > 0)
            _avgSpeed = ((float) _totalDistanceMoving / (float) _timeMoving);
        else
            _avgSpeed = (float) totalSpeedSum / (float) speedCount;
    }
    else
    {
        _avgSpeed = -1;
    }
    _elevationData = [NSArray arrayWithArray:elevationData];
    _speedData = [NSArray arrayWithArray:speedData];
}

- (void)addWptAttribute:(OAWptPt *)point attribute:(OAPointAttributes *)attribute
{
    if (![self hasData:OAPointAttributes.pointSpeed] && attribute.speed > 0 && _totalDistance > 0)
        [self setTag:OAPointAttributes.pointSpeed hasData:YES];
    if (![self hasData:OAPointAttributes.pointElevation] && !isnan(attribute.elevation) && _totalDistance > 0)
        [self setTag:OAPointAttributes.pointElevation hasData:YES];
    [OAPluginsHelper analysePoint:self point:point attribute:attribute];
    [_pointAttributes addObject:attribute];
}

+(void) splitSegment:(OASplitMetric*)metric
     secondaryMetric:(OASplitMetric *)secondaryMetric
         metricLimit:(double)metricLimit
       splitSegments:(NSMutableArray*)splitSegments
             segment:(OATrkSegment*)segment
        joinSegments:(BOOL)joinSegments
{
    double currentMetricEnd = metricLimit;
    double secondaryMetricEnd = 0;
    OASplitSegment *sp = [[OASplitSegment alloc] initWithSplitSegment:segment pointInd:0 cf:0];
    double total = 0;
    OAWptPt *prev = nil;
    for (int k = 0; k < segment.points.count; k++) {
        OAWptPt *point = [segment.points objectAtIndex:k];
        if (k > 0) {
            double currentSegment = 0;
            if (!(segment.generalSegment && !joinSegments && point.firstPoint))
            {
                currentSegment = [metric metric:prev p2:point];
                secondaryMetricEnd += [secondaryMetric metric:prev p2:point];
            }
            while (total + currentSegment > currentMetricEnd) {
                double p = currentMetricEnd - total;
                double cf = (p / currentSegment);
                [sp setLastPoint:k - 1 endCf:cf];
                sp.metricEnd = currentMetricEnd;
                sp.secondaryMetricEnd = secondaryMetricEnd;
                [splitSegments addObject:sp];
                
                sp = [[OASplitSegment alloc] initWithSplitSegment:segment pointInd:k-1 cf:cf];
                currentMetricEnd += metricLimit;
                prev = [sp get:0];
            }
            total += currentSegment;
        }
        prev = point;
    }
    if (segment.points.count > 0
        && !(sp.endPointInd == segment.points.count - 1 && sp.startCoeff == 1)) {
        sp.metricEnd = total;
        sp.secondaryMetricEnd = secondaryMetricEnd;
        [sp setLastPoint:(int)segment.points.count - 2 endCf:1.0];
        [splitSegments addObject:(sp)];
    }
}

+(NSArray*) convert:(NSArray*)splitSegments
{
    NSMutableArray *ls = [NSMutableArray array];
    for(OASplitSegment *s : splitSegments) {
        OAGPXTrackAnalysis *a = [[OAGPXTrackAnalysis alloc] init];
        [a prepareInformation:0 splitSegments:@[s]];
        [ls addObject:a];
    }
    return ls;
}

@end


@implementation OAApproxResult

- (instancetype) initWithDist:(double)dist ele:(double)ele
{
    self = [super init];
    if (self)
    {
        _dist = dist;
        _ele = ele;
    }
    return self;
}

@end

static const double SLOPE_THRESHOLD = 70.0;

@implementation OAElevationApproximator

- (NSArray<OAApproxResult *> *) approximate:(OASplitSegment *)splitSegment
{
    int pointsCount = splitSegment.getNumberOfPoints;
    if (pointsCount < 4)
        return nil;

    NSMutableArray<NSNumber *> *survived = [NSMutableArray arrayWithObject:@NO count:pointsCount];
    int lastSurvived = 0;
    int survidedCount = 0;
    for (int i = 1; i < pointsCount - 1; i++)
    {
        double prevEle = [splitSegment get:lastSurvived].elevation;
        double ele = [splitSegment get:i].elevation;
        double eleNext = [splitSegment get:i + 1].elevation;
        if ((ele - prevEle) * (eleNext - ele) > 0)
        {
            survived[i] = @YES;
            lastSurvived = i;
            survidedCount++;
        }
    }
    if (survidedCount < 2)
        return nil;

    lastSurvived = 0;
    survidedCount = 0;
    for (int i = 1; i < pointsCount - 1; i++)
    {
        if (![survived[i] boolValue])
            continue;

        OAWptPt *point = [splitSegment get:i];
        OAWptPt *lastPoint = [splitSegment get:lastSurvived];
        double ele = point.elevation;
        double prevEle = lastPoint.elevation;
        double dist = [OAMapUtils getDistance:point.position second:lastPoint.position];
        double slope = (ele - prevEle) * 100 / dist;
        if (ABS(slope) > SLOPE_THRESHOLD)
        {
            survived[i] = @NO;
            continue;
        }
        lastSurvived = i;
        survidedCount++;
    }
    if (survidedCount < 2)
        return nil;

    survived[0] = @YES;
    survived[pointsCount - 1] = @YES;
    NSMutableArray<OAApproxResult *> *res = [NSMutableArray array];
    int k = 0;
    lastSurvived = 0;
    for (int i = 0; i < pointsCount; i++)
    {
        if (![survived[i] boolValue])
            continue;

        OAWptPt *point = [splitSegment get:i];
        OAWptPt *lastPoint = [splitSegment get:lastSurvived];

        [res addObject:[[OAApproxResult alloc] initWithDist:lastSurvived == 0 
                        ? 0 : [OAMapUtils getDistance:point.position second:lastPoint.position]
                                                        ele:point.elevation]];

        k++;
        lastSurvived = i;
    }
    return res;
}

@end


@implementation OAExtremum

- (instancetype) initWithDist:(double)dist ele:(double)ele
{
    self = [super init];
    if (self)
    {
        _dist = dist;
        _ele = ele;
    }
    return self;
}

@end


@interface OAElevationDiffsCalculator()

@property (nonatomic) NSArray<OAExtremum *> *extremums;

@end

static const double ELE_THRESHOLD = 7.0;

@implementation OAElevationDiffsCalculator
{
    NSArray<OAApproxResult *> *_approxData;
}

- (instancetype) initWithApproxData:(NSArray<OAApproxResult *> *)approxData
{
    self = [super init];
    if (self)
        _approxData = approxData;

    return self;
}

- (double) getProjectionDist:(double)x y:(double)y fromx:(double)fromx fromy:(double)fromy tox:(double)tox toy:(double)toy
{
    double mDist = (fromx - tox) * (fromx - tox) + (fromy - toy) * (fromy - toy);
    double projection = [OAMapUtils scalarMultiplication:fromx yA:fromy xB:tox yB:toy xC:x yC:y];
    double prx;
    double pry;
    if (projection < 0)
    {
        prx = fromx;
        pry = fromy;
    }
    else if (projection >= mDist)
    {
        prx = tox;
        pry = toy;
    }
    else
    {
        prx = fromx + (tox - fromx) * (projection / mDist);
        pry = fromy + (toy - fromy) * (projection / mDist);
    }
    return sqrt((prx - x) * (prx - x) + (pry - y) * (pry - y));
}

- (void) findMaximumExtremumBetween:(int)start end:(int)end points:(NSMutableArray<NSNumber *> *)points
{
    OAApproxResult *firstPoint = _approxData[start];
    OAApproxResult *endPoint = _approxData[end];
    int max = start;
    double maxDiff = ELE_THRESHOLD;
    for (int i = start + 1; i < end; i++)
    {
        OAApproxResult *point = _approxData[i];
        double md = [self getProjectionDist:point.dist y:point.ele fromx:firstPoint.dist fromy:firstPoint.ele tox:endPoint.dist toy:endPoint.ele];
        if (md > maxDiff)
        {
            max = i;
            maxDiff = md;
        }
    }
    if (max != start)
    {
        points[max] = @YES;
        [self findMaximumExtremumBetween:start end:max points:points];
        [self findMaximumExtremumBetween:max end:end points:points];
    }
}

- (void) calculateElevationDiffs
{
    int pointsCount = (int)_approxData.count;
    if (pointsCount < 2)
        return;

    NSMutableArray<NSNumber *> *points = [NSMutableArray arrayWithObject:@NO count:pointsCount];
    points[0] = @YES;
    points[pointsCount - 1] = @YES;
    [self findMaximumExtremumBetween:0 end:pointsCount - 1 points:points];

    NSMutableArray<OAExtremum *> *extremums = [NSMutableArray array];
    for (int i = 0; i < points.count; i++)
        if ([points[i] boolValue])
        {
            OAApproxResult *point = _approxData[i];
            [extremums addObject:[[OAExtremum alloc] initWithDist:point.dist ele:point.ele]];
        }

    for (int i = 1; i < extremums.count; i++)
    {
        double prevElevation = extremums[i - 1].ele;
        double elevation = extremums[i].ele;
        double eleDiffSumm = elevation - prevElevation;
        if (eleDiffSumm > 0) {
            _diffElevationUp += eleDiffSumm;
        } else {
            _diffElevationDown -= eleDiffSumm;
        }
    }
    _extremums = extremums;
}

@end
