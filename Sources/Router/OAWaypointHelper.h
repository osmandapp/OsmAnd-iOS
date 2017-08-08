//
//  OAWaypointHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARouteCalculationResult;

@interface OAWaypointHelper : NSObject

+ (OAWaypointHelper *) sharedInstance;

- (void) setNewRoute:(OARouteCalculationResult *)route;

@end
