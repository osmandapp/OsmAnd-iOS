//
//  OASmartNaviWatchNavigationController.h
//  OsmAnd
//
//  Created by egloff on 18/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGPXRouter.h"
#import <CoreLocation/CoreLocation.h>


@interface OASmartNaviWatchNavigationController : NSObject {
    
    NSMutableArray *waypoints;
    NSArray *activeRoute;
    BOOL onRoute;

}

@property(nonatomic,assign) NSInteger currentIndexForRouting;

/**
 *  <#Description#>
 *
 *  @param currentLocation <#currentLocation description#>
 *
 *  @return <#return value description#>
 */
-(NSDictionary*)getActiveRouteInfoForCurrentLocation:(CLLocation*)currentLocation;

- (float)getBearingFrom:(CLLocation*)fromLocation toCoordinate:(CLLocationCoordinate2D)toCoord;

- (BOOL)calculateClosestWaypointIndexFromLocation:(CLLocation*)currentLocation;

-(void)setActiveRouteForLocation:(CLLocation*)currentLocation;
-(BOOL)hasActiveRoute:(CLLocation*)currentLocation;

@end
