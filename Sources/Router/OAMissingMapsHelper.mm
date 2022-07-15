//
//  OAMissingMapsHelper.m
//  OsmAnd
//
//  Created by nnngrach on 14.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAMissingMapsHelper.h"
#import "OsmAndApp.h"
#import "OAMapUtils.h"

#define MIN_STRAIGHT_DIST 20000

@implementation OAMissingMapsHelper : NSObject
{
    OARouteCalculationParams *_params;
}

- (instancetype) initWithParams:(OARouteCalculationParams *)params
{
    self = [super init];
    if (self)
    {
        _params = params;
    }
    return self;
}

- (BOOL) isAnyPointOnWater:(NSArray<CLLocation *> *) points
{
    for (int i = 0; i < points.count; i++)
    {
        CLLocation *point = points[i];
        // TODO: compare result with getWorldRegionsAt() in Android
        NSArray<OAWorldRegion *> *downloadRegions = [[OsmAndApp instance].worldRegion queryAtLat:point.coordinate.latitude lon:point.coordinate.longitude];
        if (!downloadRegions && downloadRegions.count == 0)
            return YES;
    }
    return NO;
}

- (NSArray<CLLocation *> *) getDistributedPathPoints:(NSArray<CLLocation *> *)points
{
    NSMutableArray<CLLocation *> *result = [NSMutableArray array];
    for (CLLocation *point in points)
    {
        [result addObject: [[CLLocation alloc] initWithCoordinate:point.coordinate altitude:point.altitude horizontalAccuracy:point.horizontalAccuracy verticalAccuracy:point.verticalAccuracy course:point.course speed:point.speed timestamp:point.timestamp]];
    }
    for (int i = 0; i < result.count - 1; i++)
    {
        int nextIndex = i + 1;
        while ([result[i] distanceFromLocation:result[nextIndex]] > MIN_STRAIGHT_DIST)
        {
            CLLocation *location = [OAMapUtils calculateMidPoint:result[i] s2:result[nextIndex]];
            [result insertObject:location atIndex:i];
        }
    }
    return [self removeDensePoints:result];
}

- (NSArray<CLLocation *> *) getStartFinishIntermediatePoints
{
    NSMutableArray<CLLocation *> *points = [NSMutableArray array];
    [points addObject: [[CLLocation alloc] initWithLatitude:_params.start.coordinate.latitude longitude:_params.start.coordinate.longitude]];
    if (_params.intermediates)
    {
        for (CLLocation *l in _params.intermediates)
        {
            [points addObject: [[CLLocation alloc] initWithLatitude:l.coordinate.latitude longitude:l.coordinate.longitude]];
        }
    }
    [points addObject: [[CLLocation alloc] initWithLatitude:_params.end.coordinate.latitude longitude:_params.end.coordinate.longitude]];
    return points;
}

- (NSArray<CLLocation *> *) findOnlineRoutePoints
{
    //TODO: implement
    return nil;
}

- (NSArray<OAWorldRegion *> *) getMissingMaps:(NSArray<CLLocation *> *) points
{
    //TODO: implement
    return nil;
}

- (NSArray<CLLocation *> *) removeDensePoints:(NSArray<CLLocation *> *) routeLocation
{
    NSMutableArray<CLLocation *> *mapsBasedOnPoints = [NSMutableArray array];
    if (routeLocation && routeLocation.count > 0)
    {
        [mapsBasedOnPoints addObject:routeLocation[0]];
        for (int i = 0, j = i + 1; j < routeLocation.count; j++)
        {
            if (j == routeLocation.count - 1 ||
                [routeLocation[i] distanceFromLocation:routeLocation[j]] >= MIN_STRAIGHT_DIST)
            {
                [mapsBasedOnPoints addObject:routeLocation[j]];
                i = j;
            }
        }
    }
    return mapsBasedOnPoints;
}

@end
