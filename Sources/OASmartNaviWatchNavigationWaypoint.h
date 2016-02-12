//
//  OASmartNaviWatchNavigationWaypoint.h
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
/*!
 *  This model class represents a waypoint with name, position,
 *  distance, bearing and whether the waypoint has been visited.
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_NAME @"name"
/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_LATITUDE @"latitude"
/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_LONGITUDE @"longitude"
/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_DISTANCE @"distance"
/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_BEARING @"bearing"
/*!
 */
#define OA_SMARTNAVIWATCH_WAYPOINT_VISITED @"visited"

@interface OASmartNaviWatchNavigationWaypoint : NSObject<NSCoding> {
    
    NSString *name;
    CLLocationCoordinate2D position;
    CLLocationDistance distance;
    float bearing;
    bool visited;
    
    
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) CLLocationCoordinate2D position;
@property (nonatomic, assign) CLLocationDistance distance;
@property (nonatomic, assign) float bearing;
@property (nonatomic, assign) bool visited;


@end
