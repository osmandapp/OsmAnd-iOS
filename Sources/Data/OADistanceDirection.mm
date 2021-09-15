//
//  OADistanceDirection.m
//  OsmAnd
//
//  Created by Alexey Kulish on 31/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADistanceDirection.h"
#import "OsmAndApp.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/Utilities.h>

@implementation OADistanceDirection
{
    NSTimeInterval _lastCalculationTime;
}

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    if (self)
    {
        _lastCalculationTime = -1;
        _coordinate.latitude = latitude;
        _coordinate.longitude = longitude;
    }
    return self;
}

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude mapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    self = [self initWithLatitude:latitude longitude:longitude];
    if (self)
    {
        [self setMapCenterCoordinate:mapCenterCoordinate];
    }
    return self;
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    _mapCenterCoordinate = CLLocationCoordinate2DMake(mapCenterCoordinate.latitude, mapCenterCoordinate.longitude);
    _searchNearMapCenter = YES;
    _lastCalculationTime = -1;
}

- (void) resetMapCenterSearch
{
    _searchNearMapCenter = NO;
}

- (BOOL) isInvalidated
{
    return _lastCalculationTime == -1 || (_lastCalculationTime > 0 && [[NSDate date] timeIntervalSince1970] - _lastCalculationTime > 0.3);
}

- (BOOL) evaluateDistanceDirection:(BOOL)decelerating
{
    if ([self isInvalidated])
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        if (self.searchNearMapCenter)
        {
            _lastCalculationTime = 0;
            const auto distance = OsmAnd::Utilities::distance(self.mapCenterCoordinate.longitude,
                                                              self.mapCenterCoordinate.latitude,
                                                              self.coordinate.longitude, self.coordinate.latitude);
            
            _distance = [OAOsmAndFormatter getFormattedDistance:distance];
            _distanceMeters = distance;
            _direction = 0;
        }
        else if (!decelerating || _lastCalculationTime == -1)
        {
            _lastCalculationTime = [[NSDate date] timeIntervalSince1970];
            CLLocation *location = app.locationServices.lastKnownLocation;
            if (location)
            {
                CLLocationDirection heading = app.locationServices.lastKnownHeading;
                CLLocationDirection direction = (location.speed >= 1 /* 3.7 km/h */ && location.course >= 0.0f) ? location.course : heading;
                
                const auto distance = OsmAnd::Utilities::distance(location.coordinate.longitude,
                                                                  location.coordinate.latitude,
                                                                  self.coordinate.longitude, self.coordinate.latitude);
                
                _distance = [OAOsmAndFormatter getFormattedDistance:distance];
                _distanceMeters = distance;
                CGFloat itemDirection = [app.locationServices radiusFromBearingToLatitude:self.coordinate.latitude longitude:self.coordinate.longitude];
                _direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - direction) * (M_PI / 180);
            }
            else
            {
                _lastCalculationTime = 0;
                return NO;
            }

        }
        return YES;
    }
    return NO;
}

@end
