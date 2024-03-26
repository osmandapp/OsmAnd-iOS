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
- (CLLocation *) locationWithBearing:(double)bearing;

@end
