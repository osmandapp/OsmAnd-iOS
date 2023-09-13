//
//  OADestinationsListViewController+cpp.m
//  OsmAnd Maps
//
//  Created by Skalii on 07.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OADistanceAndDirectionsUpdater.h"
#import "OsmAndApp.h"
#import "OAOsmAndFormatter.h"
#import "OADestinationItem.h"

#include <OsmAndCore/Utilities.h>

@implementation OADistanceAndDirectionsUpdater

+ (void)updateDistanceAndDirections:(BOOL)focreUpdate items:(NSMutableArray<OADestinationItem *> *)items
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation *newLocation = app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;

    for (OADestinationItem *item in items)
    {
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          item.destination.longitude, item.destination.latitude);
        
        item.distanceStr = [OAOsmAndFormatter getFormattedDistance:distance];
        item.distance = distance;
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:
                                    [[CLLocation alloc] initWithLatitude:item.destination.latitude
                                                               longitude:item.destination.longitude]];
        item.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    }
}

@end
