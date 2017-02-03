//
//  OADistanceDirection.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OADistanceDirection : NSObject

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;

@property (nonatomic, readonly) NSString *distance;
@property (nonatomic, readonly) CGFloat distanceMeters;
@property (nonatomic, readonly) CGFloat direction;

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude;
- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude mapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (BOOL) isInvalidated;
- (BOOL) evaluateDistanceDirection:(BOOL)decelerating;

@end
