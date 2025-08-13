//
//  CLLocation+Extension.h
//  OsmAnd
//
//  Created by Max Kojin on 19/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CLLocation (util)

- (double) bearingTo:(CLLocation *)location;
- (BOOL) hasBearing;
- (BOOL) hasSpeed;
- (BOOL) hasAccuracy;

- (CLLocation *) locationWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (CLLocation *) locationWithAltitude:(CLLocationDistance)altitude;
- (CLLocation *) locationWithHorizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy;
- (CLLocation *) locationWithVerticalAccuracy:(CLLocationAccuracy)verticalAccuracy;
- (CLLocation *) locationWithCourse:(CLLocationDirection)course;
- (CLLocation *) locationWithCourseAccuracy:(CLLocationDirectionAccuracy)courseAccuracy;
- (CLLocation *) locationWithSpeed:(CLLocationSpeed)speed;
- (CLLocation *) locationWithSpeedAccuracy:(CLLocationSpeedAccuracy)speedAccuracy;
- (CLLocation *) locationWithTimestamp:(NSDate *)timestamp;

@end
