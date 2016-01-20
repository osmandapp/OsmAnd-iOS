//
//  OASmartNaviWatchNavigationController.m
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASmartNaviWatchNavigationController.h"
#import "OASmartNaviWatchNavigationWaypoint.h"

@implementation OASmartNaviWatchNavigationController

-(NSDictionary*)getActiveRouteInfoForCurrentLocation:(CLLocationCoordinate2D)currentLocation {
    
    NSDictionary *routingInfoDict = [[NSDictionary alloc] init];
    
    //TODO create dictionary with navigation information
    
    //TODO fetch nice title name of route, estimated time
    
    //TODO fetch name, direction, distance of active points
    
    
    //TODO send current location for bearing calculation
    
    NSArray *locationMarks = [[OAGPXRouter sharedInstance] getCurrentWaypointsForCurrentLocation:currentLocation];
    

    return routingInfoDict;
    
}

@end
