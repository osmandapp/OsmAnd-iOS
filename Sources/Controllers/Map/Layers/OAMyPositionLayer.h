//
//  OAMyPositionLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

@interface OAMyPositionLayer : OASymbolMapLayer<OAContextMenuProvider>

- (void) updateMyLocationCourseProvider;
- (void) updateMode;
- (void) updateLocation:(CLLocation *)newLocation heading:(CLLocationDirection)newHeading;
- (CLLocationCoordinate2D) getActiveMarkerLocation;
- (void) setMyLocationCircleRadius:(float)radiusInMeters;
- (BOOL) shouldShowHeading;
- (BOOL) shouldShowLocationRadius;

@end
