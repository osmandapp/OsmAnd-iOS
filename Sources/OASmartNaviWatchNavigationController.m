//
//  OASmartNaviWatchNavigationController.m
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASmartNaviWatchNavigationController.h"
#import "OASmartNaviWatchNavigationWaypoint.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OASmartNaviWatchConstants.h"
#import "OsmAndApp.h"
#import <math.h>

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

@implementation OASmartNaviWatchNavigationController

-(NSDictionary*)getActiveRouteInfoForCurrentLocation:(CLLocation*)currentLocation {
    NSMutableDictionary *routingInfoDict = [[NSMutableDictionary alloc] init];

    //check if routing is active
    NSString *routeFileName = [[OAAppSettings sharedManager] mapSettingActiveRouteFileName];
    BOOL isRouteActive = (routeFileName != nil);
    if (!isRouteActive) {
        return routingInfoDict;
    }
    
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    
    //update street names for location waypoints, not needed later on when routing is officially available
    for (OASmartNaviWatchNavigationWaypoint* wp in waypoints) {
        
        if (wp.name == nil || [wp.name isEqualToString:@""]) {
            NSString *address = [mapPanel findRoadNameByLat:wp.position.latitude lon:wp.position.longitude];
            [wp setName:address];
        }
        
    }
    
    NSData *archivedWaypoints =[NSKeyedArchiver archivedDataWithRootObject: waypoints];
    [routingInfoDict setObject:archivedWaypoints forKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_WAYPOINTS];
    
    //fetch title of route
    NSString *title = [[OAGPXRouter sharedInstance] getTitleOfActiveRoute];
    [routingInfoDict setObject:title forKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_TITLE];
    
    //increment index to point to the next waypoint only when on Route
    NSNumber *index = [NSNumber numberWithInteger:self.currentIndexForRouting];
    if (onRoute) {
        index = [NSNumber numberWithInteger:self.currentIndexForRouting+1];
    }
    [routingInfoDict setObject:index forKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_CURRENT_WAYPOINT_INDEX];
    
    return routingInfoDict;
    
}

-(void)setActiveRouteForLocation:(CLLocation*)currentLocation {
    //fetch waypoints of route
    activeRoute = [[OAGPXRouter sharedInstance] getCurrentWaypointsForCurrentLocation:currentLocation];
    waypoints = [[NSMutableArray alloc] initWithArray:activeRoute];
    onRoute = NO;
}

-(BOOL)hasActiveRoute:(CLLocation*)currentLocation {
    activeRoute = [[OAGPXRouter sharedInstance] getCurrentWaypointsForCurrentLocation:currentLocation];
    return activeRoute.count > 0;
}

-(BOOL)calculateClosestWaypointIndexFromLocation:(CLLocation *)currentLocation {
    double closestDistance = DBL_MAX;
    int indexForClosestWaypoint = -1;
    if(waypoints != nil && waypoints.count > 0) {
        
        for (int i=0; i<waypoints.count; ++i) {
            
            OASmartNaviWatchNavigationWaypoint *waypoint = [waypoints objectAtIndex:i];
            double newDistance = [currentLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:waypoint.position.latitude longitude:waypoint.position.longitude]];

            if (newDistance < closestDistance && !waypoint.visited) {
                closestDistance = newDistance;
                indexForClosestWaypoint = i;
                
            }
            //update waypoint distances and bearings
            [waypoint setDistance:newDistance];
            [waypoint setBearing:[self getBearingFrom:currentLocation toCoordinate:waypoint.position]];

            if (newDistance <= 40) {
                waypoint.visited = YES;
                onRoute = YES;
            }
            
        }
        
    }
    
    if (self.currentIndexForRouting != indexForClosestWaypoint) {
        self.currentIndexForRouting = indexForClosestWaypoint;
        return YES;
    } else {
        self.currentIndexForRouting = indexForClosestWaypoint;
        return NO;
    }
    
}

- (float)getBearingFrom:(CLLocation*)fromLocation toCoordinate:(CLLocationCoordinate2D)toCoord
{
    CLLocationCoordinate2D fromCoord = fromLocation.coordinate;
    float fLat = degreesToRadians(fromCoord.latitude);
    float fLng = degreesToRadians(fromCoord.longitude);
    float tLat = degreesToRadians(toCoord.latitude);
    float tLng = degreesToRadians(toCoord.longitude);
    
    float degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
    
    //include course of movement
    float course = fromLocation.course;
    if (course >= 0) {
        degree = degree-course;
    }
    
    if (degree >= 0) {
        return degree;
    } else {
        return 360+degree;
    }
}

@end
