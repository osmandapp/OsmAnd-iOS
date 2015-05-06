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

- (NSString *) distanceStr:(double)latitude longitude:(double)longitude
{
    const auto distance = OsmAnd::Utilities::distance(longitude,
                                                      latitude,
                                                      self.longitude, self.latitude);
    
    return [[OsmAndApp instance] getFormattedDistance:distance];
}

#pragma mark - NSCoding

#define kDestinationDesc @"destination_desc"
#define kDestinationColor @"destination_color"
#define kDestinationLatitude @"destination_latitude"
#define kDestinationLongitude @"destination_longitude"
#define kDestinationMarkerName @"destination_marker_name"

#define kDestinationParking @"destination_parking"
#define kDestinationParkingCarPickupDateEnabled @"destination_car_pickup_date_enabled"
#define kDestinationParkingCarPickupDate @"destination_car_pickup_date"

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
    }
    return self;
}

@end
