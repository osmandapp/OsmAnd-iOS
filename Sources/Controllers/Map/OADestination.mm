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

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_desc forKey:kDestinationDesc];
    [aCoder encodeObject:_color forKey:kDestinationColor];
    [aCoder encodeObject:[NSNumber numberWithDouble:_latitude] forKey:kDestinationLatitude];
    [aCoder encodeObject:[NSNumber numberWithDouble:_longitude] forKey:kDestinationLongitude];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _desc = [aDecoder decodeObjectForKey:kDestinationDesc];
        _color = [aDecoder decodeObjectForKey:kDestinationColor];
        _latitude = [[aDecoder decodeObjectForKey:kDestinationLatitude] doubleValue];
        _longitude = [[aDecoder decodeObjectForKey:kDestinationLongitude] doubleValue];
    }
    return self;
}

@end
