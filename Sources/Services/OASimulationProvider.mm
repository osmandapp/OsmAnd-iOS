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
}

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
    auto px = OsmAnd::Utilities::get31TileNumberX(currentLocation.coordinate.longitude);
    auto py = OsmAnd::Utilities::get31TileNumberY(currentLocation.coordinate.latitude);
    double dist = 1000;
    for (int i = 0; i < roads.size(); i++)
    {
        auto road = roads[i];
        BOOL plus = road->getStartPointIndex() < road->getEndPointIndex();
        for (int j = road->getStartPointIndex() + 1; j <= road->getEndPointIndex(); )
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
            j += plus ? 1 : -1;
        }
    }
}

- (float) proceedMeters:(float)meters l:(CLLocation **)l
{
    for (int i = _currentRoad; i < _roads.size(); i++)
    {
        auto road = _roads[i];
        BOOL firstRoad = i == _currentRoad;
        BOOL plus = road->getStartPointIndex() < road->getEndPointIndex();
        for (int j = firstRoad ? _currentSegment : road->getStartPointIndex() + 1; j <= road->getEndPointIndex(); )
        {
            auto obj = road->object;
            int st31x = obj->pointsX[j - 1];
            int st31y = obj->pointsY[j - 1];
            int end31x = obj->pointsX[j];
            int end31y = obj->pointsY[j];
            BOOL last = i == _roads.size() - 1 && j == road->getEndPointIndex();
            BOOL first = firstRoad && j == _currentSegment;
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
            else
            {
                int prx = (int) (st31x + (end31x - st31x) * (meters / dd));
                int pry = (int) (st31y + (end31y - st31y) * (meters / dd));
                
                *l = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(OsmAnd::Utilities::get31LatitudeY(pry), OsmAnd::Utilities::get31LongitudeX(prx)) altitude:(*l).altitude horizontalAccuracy:0 verticalAccuracy:(*l).verticalAccuracy course:(*l).course speed:(*l).speed timestamp:(*l).timestamp];
                return (float) MAX(meters - dd, 0);
            }
            j += plus ? 1 : -1;
        }
    }
    return -1;
}

/**
 * @return null if it is not available of far from boundaries
 */
- (CLLocation *) getSimulatedLocation
{
    if (![self isSimulatedDataAvailable])
        return nil;
    
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0) altitude:_startLocation.altitude horizontalAccuracy:-1 verticalAccuracy:0 course:0 speed:_startLocation.speed timestamp:[NSDate date]];
    float meters = _startLocation.speed * (([[NSDate date] timeIntervalSince1970] - [_startLocation.timestamp timeIntervalSince1970]) / 1000);
    float proc = [self proceedMeters:meters l:&loc];
    if (proc < 0 || proc >= 100) {
        return nil;
    }
    return [[CLLocation alloc] initWithCoordinate:loc.coordinate altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:loc.speed timestamp:loc.timestamp];
}

- (BOOL) isSimulatedDataAvailable
{
    return _startLocation && _startLocation.speed > 0 && _currentRoad >= 0;
}

@end
