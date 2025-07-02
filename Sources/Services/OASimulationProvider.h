//
//  OASimulationProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationSimulation.h"

#include <vector>

struct RouteSegmentResult;

@interface OASimulationProvider : NSObject

- (void) startSimulation:(std::vector<std::shared_ptr<RouteSegmentResult>>)roads currentLocation:(CLLocation *)currentLocation;
- (OALocation *) getSimulatedLocationForTunnel;
- (BOOL) isSimulatedDataAvailable;

@end
