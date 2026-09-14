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

@class OASRouteSegmentResult;

@interface OASimulationProvider : NSObject

- (void) startSimulation:(NSArray<OASRouteSegmentResult *> *)roads currentLocation:(CLLocation *)currentLocation;
- (OALocation *) getSimulatedLocationForTunnel;
- (BOOL) isSimulatedDataAvailable;

@end
