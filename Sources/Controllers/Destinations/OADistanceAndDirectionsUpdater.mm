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
#import "OADestination.h"
#import "OADestinationItem.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"

#include <OsmAndCore/Utilities.h>

@implementation OADistanceAndDirectionsUpdater

+ (void)updateDistanceAndDirections:(OATableDataModel *)data
                         indexPaths:(NSArray<NSIndexPath *> *)indexPaths
                            itemKey:(NSString *)itemKey
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

    for (NSInteger i = 0; i < indexPaths.count; i ++)
    {
        OATableRowData *row = [data itemForIndexPath:indexPaths[i]];
        id rowItem = [row objForKey:itemKey];
        if (rowItem && [rowItem isKindOfClass:OADestinationItem.class])
        {
            OADestinationItem *item = (OADestinationItem *) rowItem;
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
}

+ (CGFloat)getDirectionAngleFromLocation:(CLLocation *)currentLocation toDestinationLatitude:(CGFloat)destinationLatitude destinationLongitude:(CGFloat)destinationLongitude
{
    if (!currentLocation)
        return 0;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    CLLocation *newLocation = currentLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:destinationLatitude longitude:destinationLongitude]];
    CGFloat directionAngle = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    return directionAngle;
}

+ (CGFloat)getDistanceFromLocation:(CLLocation *)currentLocation toDestinationLatitude:(CGFloat)destinationLatitude destinationLongitude:(CGFloat)destinationLongitude
{
    if (!currentLocation)
        return 0;
    
    CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:destinationLatitude longitude:destinationLongitude];
    CLLocationDistance distance = [currentLocation distanceFromLocation:destinationLocation];
    return distance;
}

@end
