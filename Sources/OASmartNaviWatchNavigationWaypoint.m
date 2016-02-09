//
//  OASmartNaviWatchNavigationWaypoint.m
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASmartNaviWatchNavigationWaypoint.h"

@implementation OASmartNaviWatchNavigationWaypoint

@synthesize name, position, distance, bearing, visited;

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.name = [aDecoder decodeObjectForKey:OA_SMARTNAVIWATCH_WAYPOINT_NAME];
    self.position = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:OA_SMARTNAVIWATCH_WAYPOINT_LATITUDE], [aDecoder decodeDoubleForKey:OA_SMARTNAVIWATCH_WAYPOINT_LONGITUDE]);
    self.distance = [aDecoder decodeDoubleForKey:OA_SMARTNAVIWATCH_WAYPOINT_DISTANCE];
    self.bearing = [aDecoder decodeDoubleForKey:OA_SMARTNAVIWATCH_WAYPOINT_BEARING];
    self.visited = [aDecoder decodeBoolForKey:OA_SMARTNAVIWATCH_WAYPOINT_VISITED];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.name forKey:OA_SMARTNAVIWATCH_WAYPOINT_NAME];
    
    [aCoder encodeDouble:self.position.latitude forKey:OA_SMARTNAVIWATCH_WAYPOINT_LATITUDE];
    [aCoder encodeDouble:self.position.longitude forKey:OA_SMARTNAVIWATCH_WAYPOINT_LONGITUDE];
    [aCoder encodeDouble:self.distance forKey:OA_SMARTNAVIWATCH_WAYPOINT_DISTANCE];
    [aCoder encodeDouble:self.bearing forKey:OA_SMARTNAVIWATCH_WAYPOINT_BEARING];
    [aCoder encodeBool:self.visited forKey:OA_SMARTNAVIWATCH_WAYPOINT_VISITED];
    
}

@end
