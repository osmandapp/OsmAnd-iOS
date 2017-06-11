//
//  OAMyPositionLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"

@interface OAMyPositionLayer : OAMapLayer

- (void) updateMyLocationCourseProvider;
- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading;

@end
