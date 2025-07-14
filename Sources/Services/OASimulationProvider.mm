//
//  OASimulationProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASimulationProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#include <routeSegmentResult.h>

@implementation OASimulationProvider
{
    int _currentRoad;
    int _currentSegment;
    std::pair<int, int> _currentPoint;
    CLLocation *_startLocation;
    vector<std::shared_ptr<RouteSegmentResult>> _roads;
    float _minOfMaxSpeedInTunnel;
}

static const float MAX_SPEED_TUNNELS = 25.0f; // 25 m/s, 90 kmh, 56 mph

- (void) startSimulation:(std::vector<std::shared_ptr<RouteSegmentResult>>)roads currentLocation:(CLLocation *)currentLocation
{
    _roads = roads;
    _startLocation = [currentLocation copy];
    NSDate *d = [NSDate date];
    NSTimeInterval s = [d timeIntervalSince1970];
    if (s - [_startLocation.timestamp timeIntervalSince1970] > 5 || s < [_startLocation.timestamp timeIntervalSince1970])
    {
        _startLocation = [[CLLocation alloc] initWithCoordinate:_startLocation.coordinate altitude:_startLocation.altitude horizontalAccuracy:_startLocation.horizontalAccuracy verticalAccuracy:_startLocation.verticalAccuracy course:_startLocation.course speed:_startLocation.speed timestamp:d];
    }
    _currentRoad = -1;
    _minOfMaxSpeedInTunnel = MAX_SPEED_TUNNELS;
    auto px = OsmAnd::Utilities::get31TileNumberX(currentLocation.coordinate.longitude);
    auto py = OsmAnd::Utilities::get31TileNumberY(currentLocation.coordinate.latitude);
    double dist = 1000;
    for (int i = 0; i < roads.size(); i++)
    {
        auto road = roads[i];
        float tunnelSpeed = road->object->getMaximumSpeed(road->isForwardDirection());
        if (tunnelSpeed > 0)
        {
            _minOfMaxSpeedInTunnel = MIN(_minOfMaxSpeedInTunnel, tunnelSpeed);
        }
        int startPointIndex = MIN(road->getStartPointIndex(), road->getEndPointIndex());
        int endPointIndex = MAX(road->getEndPointIndex(), road->getStartPointIndex());
        for (int j = startPointIndex + 1; j <= endPointIndex; j++)
        {
            auto obj = road->object;
            auto proj = getProjectionPoint(px, py, obj->pointsX[j-1], obj->pointsY[j-1], obj->pointsX[j], obj->pointsY[j]);
            double dd = squareRootDist31(proj.first, proj.second, px, py);
            if (dd < dist)
            {
                dist = dd;
                _currentRoad = i;
                _currentSegment = j;
                _currentPoint = proj;
            }
        }
    }
    NSLog(@"Start simulation road=%d segment=%d time=%ld lat=%.5f lon=%.5f",
          _currentRoad, _currentSegment, (long)([_startLocation.timestamp timeIntervalSince1970]),
          _startLocation.coordinate.latitude, _startLocation.coordinate.longitude);
}

- (double) proceedMetersFromStartLocation:(float)meters l:(CLLocation **)l
{
    // Location tried to be precise, but can be overshot for last segment
    // return how many meters overshot for the last point
    if (_currentRoad == -1)
    {
        return -1;
    }
    for (int i = _currentRoad; i < _roads.size(); i++)
    {
        auto road = _roads[i];
        BOOL firstRoad = i == _currentRoad;
        BOOL plus = road->getStartPointIndex() < road->getEndPointIndex();
        int increment = plus ? +1 : -1;
        int start = road->getStartPointIndex();
        if (firstRoad)
        {
                // first segment is [currentSegment - 1, currentSegment]
                if (plus)
                {
                        start = _currentSegment - increment;
                }
                else
                {
                        start = _currentSegment;
                }
        }
        for (int j = start; j != road->getEndPointIndex(); j += increment)
        {
            auto obj = road->object;
            int st31x = obj->getPoint31XTile(j);
            int st31y = obj->getPoint31YTile(j);
            int end31x = obj->getPoint31XTile(j + increment);
            int end31y = obj->getPoint31YTile(j + increment);
            BOOL last = i == _roads.size() - 1 && j == road->getEndPointIndex() - increment;
            BOOL first = firstRoad && j == start;
            if (first)
            {
                st31x = _currentPoint.first;
                st31y = _currentPoint.second;
            }
            double dd = measuredDist31(st31x, st31y, end31x, end31y);
            if (meters > dd && !last)
            {
                meters -= dd;
            }
            else if (dd > 0)
            {
                int prx = (int) (st31x + (end31x - st31x) * (meters / dd));
                int pry = (int) (st31y + (end31y - st31y) * (meters / dd));
                if (prx == 0 || pry == 0)
                {
                    NSLog(@"proceedMeters zero x or y (%d,%d) (%s)", prx, pry, road->toString().c_str());
                    return -1;
                }
                *l = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(OsmAnd::Utilities::get31LatitudeY(pry), OsmAnd::Utilities::get31LongitudeX(prx)) altitude:(*l).altitude horizontalAccuracy:0 verticalAccuracy:(*l).verticalAccuracy course:(*l).course speed:(*l).speed timestamp:(*l).timestamp];
                return MAX(meters - dd, 0);
            }
            else
            {
                NSLog(@"proceedMeters break at the end of the road (sx=%d, sy=%d) (%s)", st31x, st31y, road->toString().c_str());
                break;
            }
        }
    }
    return -1;
}

/**
 * @return null if it is not available of far from boundaries
 */
- (OALocation *) getSimulatedLocationForTunnel
{
    if (![self isSimulatedDataAvailable])
        return nil;
    float spd = MIN(_minOfMaxSpeedInTunnel, _startLocation.speed);
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:_startLocation.altitude horizontalAccuracy:-1 verticalAccuracy:0 course:0 speed:spd timestamp:[NSDate date]];
    // here we can decrease speed - startLocation.getSpeed() or we can real speed BLE sensor
    double metersToPass = spd * ([[NSDate date] timeIntervalSince1970] - [_startLocation.timestamp timeIntervalSince1970]);
    double metersSimLocationFromDesiredLocation = [self proceedMetersFromStartLocation:metersToPass l:&loc];
    if (metersSimLocationFromDesiredLocation < 0)
    {
        return nil; // error simulation
    }
    if (metersSimLocationFromDesiredLocation >= 100)
    {
        return nil; // limit 100m if we overpass tunnel
    }
    return [[OALocation alloc] initWithProvider:@"TUNNEL" location:loc];
}

- (BOOL) isSimulatedDataAvailable
{
    return _startLocation && _startLocation.speed > 0 && _currentRoad >= 0;
}

@end
