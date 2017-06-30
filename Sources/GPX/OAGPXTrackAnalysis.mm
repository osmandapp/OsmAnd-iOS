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

#include <OsmAndCore/Utilities.h>


@implementation OASplitMetric

-(double) metric:(OAGpxWpt*)p1 p2:(OAGpxWpt*)p2 { return 0; };

@end


@implementation OADistanceMetric

-(double) metric:(OAGpxWpt*)p1 p2:(OAGpxWpt*)p2
{
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:p1.position.latitude longitude:p1.position.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:p2.position.latitude longitude:p2.position.longitude];
    return [loc1 distanceFromLocation:loc2];
}

@end


@implementation OATimeSplit

-(double) metric:(OALocationMark *)p1 p2:(OALocationMark *)p2
{
    if(p1.time != 0 && p2.time != 0) {
        return abs((p2.time - p1.time) / 1000l);
    }
    return 0;
}

@end




@implementation OASplitSegment

- (instancetype)initWithTrackSegment:(OAGpxTrkSeg *)s
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

- (instancetype)initWithSplitSegment:(OAGpxTrkSeg *)s pointInd:(int)pointInd cf:(double)cf
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

-(OALocationMark *) get:(int)j
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


-(OAGpxWpt *) approx:(OAGpxTrkPt *)w1 w2:(OAGpxTrkPt *)w2 cf:(double)cf
{
    long time = [self valueLong:w1.time vl2:w2.time none:0 cf:cf];
    double speed = [self valueDbl:w1.speed vl2:w2.speed none:0 cf:cf];
    double ele = [self valueDbl:w1.elevation vl2:w2.elevation none:0 cf:cf];
    double hdop = [self valueDbl:w1.horizontalDilutionOfPrecision vl2:w2.horizontalDilutionOfPrecision none:0 cf:cf];
    double lat = [self valueDbl:w1.position.latitude vl2:w2.position.latitude none:-360 cf:cf];
    double lon = [self valueDbl:w1.position.longitude vl2:w2.position.longitude none:-360 cf:cf];
    
    OAGpxWpt *wpt = [[OAGpxWpt alloc] init];
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
        
        _maxSpeed = 0.0;
        
        _wptPoints = 0;
        
    }
    return self;
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

+(OAGPXTrackAnalysis *) segment:(long)fileTimestamp seg:(OAGpxTrkSeg *)seg
{
    OAGPXTrackAnalysis *obj = [[OAGPXTrackAnalysis alloc] init];
    [obj prepareInformation:fileTimestamp splitSegments:@[[[OASplitSegment alloc] initWithTrackSegment:seg]]];
    return obj;
}

-(void) prepareInformation:(long)fileStamp  splitSegments:(NSArray *)splitSegments
{
    float totalElevation = 0;
    int elevationPoints = 0;
    int speedCount = 0;
    double totalSpeedSum = 0;
    _points = 0;
    
    for (OASplitSegment *s : splitSegments) {
        int numberOfPoints = [s getNumberOfPoints];
        _metricEnd += s.metricEnd;
        _points += numberOfPoints;
        for (int j = 0; j < numberOfPoints; j++) {
            OAGpxWpt *point = [s get:j];
            if(j == 0 && self.locationStart == nil) {
                self.locationStart = point;
            }
            if(j == numberOfPoints - 1) {
                self.locationEnd = point;
            }
            long time = point.time;
            if (time != 0) {
                _startTime = MIN(_startTime, time);
                _endTime = MAX(_endTime, time);
            }
            
            double elevation = point.elevation;
            if (!isnan(elevation)) {
                totalElevation += elevation;
                elevationPoints++;
                _minElevation = MIN(elevation, _minElevation);
                _maxElevation = MAX(elevation, _maxElevation);
            }
            
            float speed = (float) point.speed;
            if (speed > 0) {
                totalSpeedSum += speed;
                _maxSpeed = MAX(speed, _maxSpeed);
                speedCount++;
            }
            
            if (j > 0) {
                OAGpxWpt *prev = [s get:j - 1];
                
                if (!isnan(point.elevation) && !isnan(prev.elevation)) {
                    double diff = point.elevation - prev.elevation;
                    if (diff > 0) {
                        _diffElevationUp += diff;
                    } else {
                        _diffElevationDown -= diff;
                    }
                }
                
                double distance = OsmAnd::Utilities::distance(prev.position.longitude, prev.position.latitude, point.position.longitude, point.position.latitude);
                _totalDistance += distance;
                
                // Averaging speed values is less exact than totalDistance/timeMoving
                if (speed > 0 && point.time != 0 && prev.time != 0) {
                    _timeMoving = _timeMoving + (point.time - prev.time);
                    _totalDistanceMoving += distance;
                }
            }
        }
    }
    
    if (_maxElevation < _minElevation)
    {
        _maxElevation = 0.0;
        _minElevation = 0.0;
    }
    
    if(![self isTimeSpecified]){
        _startTime = fileStamp;
        _endTime = fileStamp;
    }
    
    // OUTPUT:
    // 1. Total distance, Start time, End time
    // 2. Time span
    _timeSpan = _endTime - _startTime;
    
    // 3. Time moving, if any
    // 4. Elevation, eleUp, eleDown, if recorded
    if (elevationPoints > 0) {
        _avgElevation =  totalElevation / elevationPoints;
    }
    
    
    
    // 5. Max speed and Average speed, if any. Average speed is NOT overall (effective) speed, but only calculated for "moving" periods.
    if(speedCount > 0) {
        if(_timeMoving > 0){
            _avgSpeed = (float) (_totalDistanceMoving / _timeMoving);
        } else {
            _avgSpeed = (float) (totalSpeedSum / speedCount);
        }
    } else {
        _avgSpeed = -1;
    }
    
}



+(void) splitSegment:(OASplitMetric*)metric metricLimit:(double)metricLimit splitSegments:(NSMutableArray*)splitSegments
             segment:(OAGpxTrkSeg*)segment
{
    double currentMetricEnd = metricLimit;
    OASplitSegment *sp = [[OASplitSegment alloc] initWithSplitSegment:segment pointInd:0 cf:0];
    double total = 0;
    OALocationMark *prev = nil;
    for (int k = 0; k < segment.points.count; k++) {
        OALocationMark *point = [segment.points objectAtIndex:k];
        if (k > 0) {
            double currentSegment = [metric metric:prev p2:point];
            while (total + currentSegment > currentMetricEnd) {
                double p = currentMetricEnd - total;
                double cf = (p / currentSegment);
                [sp setLastPoint:k - 1 endCf:cf];
                sp.metricEnd = currentMetricEnd;
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
