//
//  OADestination.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestination.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OADestination


- (instancetype)initWithDesc:(NSString *)desc latitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    if (self) {
        self.desc = desc;
        self.latitude = latitude;
        self.longitude = longitude;
    }
    return self;
}

- (double) distance:(double)latitude longitude:(double)longitude
{
    return OsmAnd::Utilities::distance(longitude,
                                       latitude,
                                       self.longitude, self.latitude);
}

- (NSString *) distanceStr:(double)latitude longitude:(double)longitude
{
    return [[OsmAndApp instance] getFormattedDistance:[self distance:latitude longitude:longitude]];
}

#pragma mark - NSCoding

#define kDestinationDesc @"destination_desc"
#define kDestinationColor @"destination_color"
#define kDestinationLatitude @"destination_latitude"
#define kDestinationLongitude @"destination_longitude"
#define kDestinationMarkerName @"destination_marker_name"
#define kDestinationShowOnTopName @"destination_show_on_top"

#define kDestinationParking @"destination_parking"
#define kDestinationParkingCarPickupDateEnabled @"destination_car_pickup_date_enabled"
#define kDestinationParkingCarPickupDate @"destination_car_pickup_date"
#define kDestinationParkingEventId @"destination_event_id"

#define kDestinationRoutePointName @"destination_route_point"
#define kDestinationRoutePointIndexName @"destination_route_point_index"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_desc forKey:kDestinationDesc];
    [aCoder encodeObject:_color forKey:kDestinationColor];
    [aCoder encodeObject:[NSNumber numberWithDouble:_latitude] forKey:kDestinationLatitude];
    [aCoder encodeObject:[NSNumber numberWithDouble:_longitude] forKey:kDestinationLongitude];
    [aCoder encodeObject:_markerResourceName forKey:kDestinationMarkerName];
    [aCoder encodeObject:[NSNumber numberWithBool:_parking] forKey:kDestinationParking];
    [aCoder encodeObject:[NSNumber numberWithBool:_carPickupDateEnabled] forKey:kDestinationParkingCarPickupDateEnabled];
    [aCoder encodeObject:_carPickupDate forKey:kDestinationParkingCarPickupDate];
    [aCoder encodeObject:_eventIdentifier forKey:kDestinationParkingEventId];
    [aCoder encodeObject:[NSNumber numberWithBool:_showOnTop] forKey:kDestinationShowOnTopName];
    [aCoder encodeObject:[NSNumber numberWithBool:_routePoint] forKey:kDestinationRoutePointName];
    [aCoder encodeObject:[NSNumber numberWithInteger:_routePointIndex] forKey:kDestinationRoutePointIndexName];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _desc = [aDecoder decodeObjectForKey:kDestinationDesc];
        _color = [aDecoder decodeObjectForKey:kDestinationColor];
        _latitude = [[aDecoder decodeObjectForKey:kDestinationLatitude] doubleValue];
        _longitude = [[aDecoder decodeObjectForKey:kDestinationLongitude] doubleValue];
        _markerResourceName = [aDecoder decodeObjectForKey:kDestinationMarkerName];
        _parking = [[aDecoder decodeObjectForKey:kDestinationParking] boolValue];
        _carPickupDateEnabled = [[aDecoder decodeObjectForKey:kDestinationParkingCarPickupDateEnabled] boolValue];
        _carPickupDate = [aDecoder decodeObjectForKey:kDestinationParkingCarPickupDate];
        _eventIdentifier = [aDecoder decodeObjectForKey:kDestinationParkingEventId];
        _showOnTop = [[aDecoder decodeObjectForKey:kDestinationShowOnTopName] boolValue];
        _routePoint = [[aDecoder decodeObjectForKey:kDestinationShowOnTopName] boolValue];
        _routePointIndex = [[aDecoder decodeObjectForKey:kDestinationShowOnTopName] integerValue];
    }
    return self;
}

@end
