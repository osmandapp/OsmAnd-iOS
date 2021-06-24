//
//  OADestination.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestination.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"

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
        self.index = 0;
        self.hidden = NO;
        self.manual = NO;
        self.creationDate = [NSDate date];
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

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[OADestination class]])
        return NO;
    
    OADestination *obj = (OADestination *)object;
    return [obj.desc isEqualToString:self.desc] && [OAUtilities doublesEqualUpToDigits:5 source:obj.latitude destination:self.latitude] && [OAUtilities doublesEqualUpToDigits:5 source:obj.longitude destination:self.longitude] && obj.routePoint == self.routePoint;
}

-(NSUInteger)hash
{
    return [self.desc hash] + self.longitude * 10000 + self.latitude * 10000 + (self.routePoint ? 1 : 0);
}

#pragma mark - NSCoding

#define kDestinationDesc @"destination_desc"
#define kDestinationColor @"destination_color"
#define kDestinationLatitude @"destination_latitude"
#define kDestinationLongitude @"destination_longitude"
#define kDestinationMarkerName @"destination_marker_name"
#define kDestinationIndexName @"destination_index"

#define kDestinationRoutePointName @"destination_route_point"
#define kDestinationRouteTargetPointName @"destination_route_target_point"
#define kDestinationRoutePointIndexName @"destination_route_point_index"

#define kDestinationHidden @"destination_hidden"
#define kDestinationManual @"destination_manual"

#define kDestinationCreationDate @"destination_creation_date"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_desc forKey:kDestinationDesc];
    [aCoder encodeObject:_color forKey:kDestinationColor];
    [aCoder encodeObject:[NSNumber numberWithDouble:_latitude] forKey:kDestinationLatitude];
    [aCoder encodeObject:[NSNumber numberWithDouble:_longitude] forKey:kDestinationLongitude];
    [aCoder encodeObject:_markerResourceName forKey:kDestinationMarkerName];
    [aCoder encodeObject:[NSNumber numberWithInteger:_index] forKey:kDestinationIndexName];
    [aCoder encodeObject:[NSNumber numberWithBool:_routePoint] forKey:kDestinationRoutePointName];
    [aCoder encodeObject:[NSNumber numberWithBool:_routeTargetPoint] forKey:kDestinationRouteTargetPointName];
    [aCoder encodeObject:[NSNumber numberWithInteger:_routePointIndex] forKey:kDestinationRoutePointIndexName];
    [aCoder encodeObject:[NSNumber numberWithBool:_hidden] forKey:kDestinationHidden];
    [aCoder encodeObject:[NSNumber numberWithBool:_manual] forKey:kDestinationManual];
    [aCoder encodeObject:_creationDate forKey:kDestinationCreationDate];
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
        _index = [[aDecoder decodeObjectForKey:kDestinationIndexName] integerValue];
        _routePoint = [[aDecoder decodeObjectForKey:kDestinationRoutePointName] boolValue];
        _routeTargetPoint = [[aDecoder decodeObjectForKey:kDestinationRouteTargetPointName] boolValue];
        _routePointIndex = [[aDecoder decodeObjectForKey:kDestinationRoutePointIndexName] integerValue];
        _hidden = [[aDecoder decodeObjectForKey:kDestinationHidden] boolValue];
        _manual = [[aDecoder decodeObjectForKey:kDestinationManual] boolValue];
        _creationDate = [aDecoder decodeObjectForKey:kDestinationCreationDate];
    }
    return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OADestination* clone = [[OADestination alloc] initWithDesc:_desc latitude:_latitude longitude:_longitude];
    clone.color = _color;
    clone.markerResourceName = _markerResourceName;
    clone.index = _index;
    clone.routePoint = _routePoint;
    clone.routeTargetPoint = _routeTargetPoint;
    clone.routePointIndex = _routePointIndex;
    clone.hidden = _hidden;
    clone.manual = _manual;
    clone.creationDate = _creationDate;

    return clone;
}

@end
