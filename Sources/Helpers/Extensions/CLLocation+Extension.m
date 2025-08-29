//
//  CLLocation+Extension.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "CLLocation+Extension.h"
#import "OALocationServices.h"

@implementation CLLocation (util)

- (double) bearingTo:(CLLocation *)location
{
    CLLocationCoordinate2D coord1 = self.coordinate;
    CLLocationCoordinate2D coord2 = location.coordinate;
    double distance, bearing;
    [OALocationServices computeDistanceAndBearing:coord1.latitude lon1:coord1.longitude lat2:coord2.latitude lon2:coord2.longitude distance:&distance initialBearing:&bearing];
    
    return bearing;
}

- (BOOL) hasBearing;
{
    return !isnan(self.course) && self.course > 0;
}


- (BOOL) hasSpeed;
{
    return !isnan(self.speed) && self.speed >= 0;
}

- (BOOL) hasAccuracy;
{
    return (!isnan(self.horizontalAccuracy) && self.horizontalAccuracy > 0) ||
           (!isnan(self.verticalAccuracy) && self.verticalAccuracy > 0);
}

- (double)haversineDistanceInMetersTo:(CLLocation *)location
{
    double lat1 = self.coordinate.latitude;
    double lon1 = self.coordinate.longitude;
    double lat2 = location.coordinate.latitude;
    double lon2 = location.coordinate.longitude;

    double R = 6372.8;
    double dLat = (lat2 - lat1) * M_PI / 180.0;
    double dLon = (lon2 - lon1) * M_PI / 180.0;

    double sinHalfLat = sin(dLat / 2.0);
    double sinHalfLon = sin(dLon / 2.0);

    double a = sinHalfLat * sinHalfLat
             + cos(lat1 * M_PI / 180.0) * cos(lat2 * M_PI / 180.0)
             * sinHalfLon * sinHalfLon;

    return 2.0 * R * 1000.0 * asin(sqrt(a));
}

- (CLLocation *) locationWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    return [[CLLocation alloc] initWithCoordinate:coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithAltitude:(CLLocationDistance)altitude
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithHorizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithVerticalAccuracy:(CLLocationAccuracy)verticalAccuracy
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}


- (CLLocation *) locationWithCourse:(CLLocationDirection)course
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithCourseAccuracy:(CLLocationDirectionAccuracy)courseAccuracy
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithSpeed:(CLLocationSpeed)speed
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithSpeedAccuracy:(CLLocationSpeedAccuracy)speedAccuracy
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

- (CLLocation *) locationWithTimestamp:(NSDate *)timestamp
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:self.course courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:timestamp sourceInfo:self.sourceInformation];
}

@end
