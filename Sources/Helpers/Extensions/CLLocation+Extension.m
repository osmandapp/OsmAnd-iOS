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
    return !isnan(self.course) && self.course != -1 && self.course != 0;
}


- (BOOL) hasSpeed;
{
    return !isnan(self.speed);
}

- (CLLocation *) locationWithBearing:(double)bearing
{
    return [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:self.altitude horizontalAccuracy:self.horizontalAccuracy verticalAccuracy:self.verticalAccuracy course:bearing courseAccuracy:self.courseAccuracy speed:self.speed speedAccuracy:self.speedAccuracy timestamp:self.timestamp sourceInfo:self.sourceInformation];
}

@end
