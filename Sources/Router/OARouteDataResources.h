//
//  OARouteDataResources.h
//  OsmAnd
//
//  Created by nnngrach on 02.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <routeTypeRule.h>
#include <binaryRead.h>

@interface OARouteDataResources : NSObject

- (instancetype) init;
- (instancetype) initWithLocations:(NSMutableArray<CLLocation *> *)locations;
- (NSMutableDictionary *) getRules;
- (NSMutableArray<CLLocation *> *) getLocations;
- (BOOL) hasLocations;
- (CLLocation *) getLocation:(int)index;
- (void) incrementCurrentLocation:(int)index;
- (NSMutableDictionary *) getPointNamesMap;

@end


