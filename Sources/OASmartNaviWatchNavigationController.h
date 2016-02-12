//
//  OASmartNaviWatchNavigationController.h
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
/*!
 *  This controller class fetches all the information needed 
 *  for facilitating navigation on the watch.
 */
#import <Foundation/Foundation.h>
#import "OAGPXRouter.h"
#import <CoreLocation/CoreLocation.h>


@interface OASmartNaviWatchNavigationController : NSObject {
    
    NSMutableArray *waypoints;
    NSArray *activeRoute;
    BOOL onRoute;

}

@property(nonatomic,assign) NSInteger currentIndexForRouting;

/*!
 *  checks if there is an active route and if so, gathers all missing information
 *  on all waypoints such as address and title of the active route.
 *  It also increments the current index and puts all information the the navigation
 *  data dictionary
 *
 *  @param currentLocation the current location
 *
 *  @return the data dictionary containing all data needed for navigation
 */
-(NSDictionary*)getActiveRouteInfoForCurrentLocation:(CLLocation*)currentLocation;

/*!
 *  calculates the bearing between two location points, if the first location has a current
 *  course it gets included in the calculation.
 *
 *  @param fromLocation the current location
 *  @param toCoord      the location to which the bearing is to be calculated
 *
 *  @return the bearing angle 0<=x<=360
 */
- (float)getBearingFrom:(CLLocation*)fromLocation toCoordinate:(CLLocationCoordinate2D)toCoord;

/*!
 *  checks if currentLocation is within any waypoint of the active route (40m).
 *  In doinig so it also updates distance, bearing and visited of all waypoints
 *
 *  @param currentLocation the current location
 *
 *  @return true if current location is within the reach of a waypoint
 */
- (BOOL)calculateClosestWaypointIndexFromLocation:(CLLocation*)currentLocation;

/*!
 *  sets a new active route
 *
 *  @param currentLocation the current location
 */
-(void)setActiveRouteForLocation:(CLLocation*)currentLocation;

/*!
 *  checks if there is an active route
 *
 *  @param currentLocation the current location
 *
 *  @return true if there is an active route
 */
-(BOOL)hasActiveRoute:(CLLocation*)currentLocation;

@end
