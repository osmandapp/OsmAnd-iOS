//
//  OAGPXTrackAnalysis.m
//  OsmAnd
//
//  Created by Admin on 13/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXTrackAnalysis.h"


@implementation OASplitSegment

- (instancetype)initWithTrackSegment:(OATrackSegment *)s
{
    self = [super init];
    if (self) {
        _startPointInd = 0;
        _startCoeff = 0;
        _endPointInd = s.points.count - 2;
        _endCoeff = 1;
        self.segment = s;
    }
    return self;
}

- (instancetype)initWithSplitSegment:(OATrackSegment *)s pointInd:(int)pointInd cf:(double)cf
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
/*
public WptPt get(int j) {
    final int ind = j + startPointInd;
    if(j == 0) {
        if(startCoeff == 0) {
            return segment.points.get(ind);
        }
        return approx(segment.points.get(ind), segment.points.get(ind + 1), startCoeff);
    }
    if(j == getNumberOfPoints() - 1) {
        if(endCoeff == 1) {
            return segment.points.get(ind);
        }
        return approx(segment.points.get(ind - 1), segment.points.get(ind), endCoeff);
    }
    return segment.points.get(ind);
}


private WptPt approx(WptPt w1, WptPt w2, double cf) {
    long time = value(w1.time, w2.time, 0, cf);
    double speed = value(w1.speed, w2.speed, 0, cf);
    double ele = value(w1.ele, w2.ele, 0, cf);
    double hdop = value(w1.hdop, w2.hdop, 0, cf);
    double lat = value(w1.lat, w2.lat, -360, cf);
    double lon = value(w1.lon, w2.lon, -360, cf);
    return new WptPt(lat, lon, time, ele, speed, hdop);
}
*/
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

+(OAGPXTrackAnalysis *) segment:(long)fileTimestamp seg:(OATrackSegment *)seg
{
    return [[[OAGPXTrackAnalysis alloc] init] prepareInformation:fileTimestamp splitSegments:@[[[OASplitSegment alloc] initWithTrackSegment:seg]]];
}

-(OAGPXTrackAnalysis *) prepareInformation:(long)fileStamp  splitSegments:(NSArray *)splitSegments
{
    return nil;
}

/*
public static class GPXTrackAnalysis {

    
    public GPXTrackAnalysis prepareInformation(long filestamp, SplitSegment... splitSegments) {
        float[] calculations = new float[1];
        
        float totalElevation = 0;
        int elevationPoints = 0;
        int speedCount = 0;
        double totalSpeedSum = 0;
        points = 0;
        
        for (SplitSegment s : splitSegments) {
            final int numberOfPoints = s.getNumberOfPoints();
            metricEnd += s.metricEnd;
            points += numberOfPoints;
            for (int j = 0; j < numberOfPoints; j++) {
                WptPt point = s.get(j);
                if(j == 0 && locationStart == null) {
                    locationStart = point;
                }
                if(j == numberOfPoints - 1) {
                    locationEnd = point;
                }
                long time = point.time;
                if (time != 0) {
                    startTime = Math.min(startTime, time);
                    endTime = Math.max(endTime, time);
                }
                
                double elevation = point.ele;
                if (!Double.isNaN(elevation)) {
                    totalElevation += elevation;
                    elevationPoints++;
                    minElevation = Math.min(elevation, minElevation);
                    maxElevation = Math.max(elevation, maxElevation);
                }
                
                float speed = (float) point.speed;
                if (speed > 0) {
                    totalSpeedSum += speed;
                    maxSpeed = Math.max(speed, maxSpeed);
                    speedCount++;
                }
                
                if (j > 0) {
                    WptPt prev = s.get(j - 1);
                    
                    if (!Double.isNaN(point.ele) && !Double.isNaN(prev.ele)) {
                        double diff = point.ele - prev.ele;
                        if (diff > 0) {
                            diffElevationUp += diff;
                        } else {
                            diffElevationDown -= diff;
                        }
                    }
                    
                    // totalDistance += MapUtils.getDistance(prev.lat, prev.lon, point.lat, point.lon);
                    // using ellipsoidal 'distanceBetween' instead of spherical haversine (MapUtils.getDistance) is
                    // a little more exact, also seems slightly faster:
                    net.osmand.Location.distanceBetween(prev.lat, prev.lon, point.lat, point.lon, calculations);
                    totalDistance += calculations[0];
                    
                    // Averaging speed values is less exact than totalDistance/timeMoving
                    if (speed > 0 && point.time != 0 && prev.time != 0) {
                        timeMoving = timeMoving + (point.time - prev.time);
                        totalDistanceMoving += calculations[0];
                    }
                }
            }
        }
        if(!isTimeSpecified()){
            startTime = filestamp;
            endTime = filestamp;
        }
        
        // OUTPUT:
        // 1. Total distance, Start time, End time
        // 2. Time span
        timeSpan = endTime - startTime;
        
        // 3. Time moving, if any
        // 4. Elevation, eleUp, eleDown, if recorded
        if (elevationPoints > 0) {
            avgElevation =  totalElevation / elevationPoints;
        }
        
        
        
        // 5. Max speed and Average speed, if any. Average speed is NOT overall (effective) speed, but only calculated for "moving" periods.
        if(speedCount > 0) {
            if(timeMoving > 0){
                avgSpeed = (float) (totalDistanceMoving / timeMoving * 1000);
            } else {
                avgSpeed = (float) (totalSpeedSum / speedCount);
            }
        } else {
            avgSpeed = -1;
        }
        return this;
    }
    
}

private static class SplitSegment {

    
    
    public int getNumberOfPoints() {
        return endPointInd - startPointInd + 2;
    }
    
    public WptPt get(int j) {
        final int ind = j + startPointInd;
        if(j == 0) {
            if(startCoeff == 0) {
                return segment.points.get(ind);
            }
            return approx(segment.points.get(ind), segment.points.get(ind + 1), startCoeff);
        }
        if(j == getNumberOfPoints() - 1) {
            if(endCoeff == 1) {
                return segment.points.get(ind);
            }
            return approx(segment.points.get(ind - 1), segment.points.get(ind), endCoeff);
        }
        return segment.points.get(ind);
    }
    
    
    private WptPt approx(WptPt w1, WptPt w2, double cf) {
        long time = value(w1.time, w2.time, 0, cf);
        double speed = value(w1.speed, w2.speed, 0, cf);
        double ele = value(w1.ele, w2.ele, 0, cf);
        double hdop = value(w1.hdop, w2.hdop, 0, cf);
        double lat = value(w1.lat, w2.lat, -360, cf);
        double lon = value(w1.lon, w2.lon, -360, cf);
        return new WptPt(lat, lon, time, ele, speed, hdop);
    }
    
    private double value(double vl, double vl2, double none, double cf) {
        if(vl == none || Double.isNaN(vl)) {
            return vl2;
        } else if (vl2 == none || Double.isNaN(vl2)) {
            return vl;
        }
        return vl + cf * (vl2 - vl);
    }
    
    private long value(long vl, long vl2, long none, double cf) {
        if(vl == none) {
            return vl2;
        } else if(vl2 == none) {
            return vl;
        }
        return vl + ((long) (cf * (vl2 - vl)));
    }
    
    
    public double setLastPoint(int pointInd, double endCf) {
        endCoeff = endCf;
        endPointInd = pointInd;
        return endCoeff;
    }
    
}

private static SplitMetric getDistanceMetric() {
    return new SplitMetric() {
        
        private float[] calculations = new float[1];
        
        @Override
        public double metric(WptPt p1, WptPt p2) {
            net.osmand.Location.distanceBetween(p1.lat, p1.lon, p2.lat, p2.lon, calculations);
            return calculations[0];
        }
    };
}

private static SplitMetric getTimeSplit() {
    return new SplitMetric() {
        
        @Override
        public double metric(WptPt p1, WptPt p2) {
            if(p1.time != 0 && p2.time != 0) {
                return (int) Math.abs((p2.time - p1.time) / 1000l);
            }
            return 0;
        }
    };
}

private abstract static class SplitMetric {
    
    public abstract double metric(WptPt p1, WptPt p2);
    
}

private static void splitSegment(SplitMetric metric, double metricLimit, List<SplitSegment> splitSegments,
                                 TrkSegment segment) {
    double currentMetricEnd = metricLimit;
    SplitSegment sp = new SplitSegment(segment, 0, 0);
    double total = 0;
    WptPt prev = null ;
    for (int k = 0; k < segment.points.size(); k++) {
        WptPt point = segment.points.get(k);
        if (k > 0) {
            double currentSegment = metric.metric(prev, point);
            while (total + currentSegment > currentMetricEnd) {
                double p = currentMetricEnd - total;
                double cf = (p / currentSegment); 
                sp.setLastPoint(k - 1, cf);
                sp.metricEnd = currentMetricEnd;
                splitSegments.add(sp);
                
                sp = new SplitSegment(segment, k - 1, cf);
                currentMetricEnd += metricLimit;
                prev = sp.get(0);
            }
            total += currentSegment;
        }
        prev = point;
    }
    if (segment.points.size() > 0
        && !(sp.endPointInd == segment.points.size() - 1 && sp.startCoeff == 1)) {
        sp.metricEnd = total;
        sp.setLastPoint(segment.points.size() - 2, 1);
        splitSegments.add(sp);
    }
}

private static List<GPXTrackAnalysis> convert(List<SplitSegment> splitSegments) {
    List<GPXTrackAnalysis> ls = new ArrayList<GPXUtilities.GPXTrackAnalysis>();
    for(SplitSegment s : splitSegments) {
        GPXTrackAnalysis a = new GPXTrackAnalysis();
        a.prepareInformation(0, s);
        ls.add(a);
    }
    return ls;
}
 */

@end
