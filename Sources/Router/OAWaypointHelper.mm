//
//  OAWaypointHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAWaypointHelper.h"
#import "OARouteCalculationResult.h"

@implementation OAWaypointHelper

+ (OAWaypointHelper *) sharedInstance
{
    static OAWaypointHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWaypointHelper alloc] init];
    });
    return _sharedInstance;
}


- (void) setNewRoute:(OARouteCalculationResult *)route
{
    // TODO
    //List<List<LocationPointWrapper>> locationPoints = new ArrayList<List<LocationPointWrapper>>();
    //recalculatePoints(route, -1, locationPoints);
    //setLocationPoints(locationPoints, route);
}

@end
