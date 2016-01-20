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
 
}

-(NSDictionary*)getActiveRouteInfoForCurrentLocation:(CLLocationCoordinate2D)currentLocation;

@end
