//
//  OARouteDataResources.m
//  OsmAnd
//
//  Created by nnngrach on 02.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteDataResources.h"

@implementation OARouteDataResources
{
    NSMutableDictionary *_rules;                //Map<RouteTypeRule, Integer>
    NSMutableArray<CLLocation *> *_locations;
    int _currentLocation;
    NSMutableDictionary *_pointNamesMap;        //Map<RouteDataObject, int[][]>
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _locations = [NSMutableArray new];
    }
    return self;
}

- (instancetype) initWithLocations:(NSMutableArray<CLLocation *> *)locations
{
    self = [super init];
    if (self)
    {
        _locations = locations;
    }
    return self;
}

//I couldn't specify the type.
//Error: "Type argument 'RouteTypeRule' is neither an Objective-C object nor a block type"
//Map<RouteTypeRule, Integer>
- (NSMutableDictionary *) getRules
{
    return _rules;
}

- (NSMutableArray<CLLocation *> *) getLocations
{
    return _locations;
}

- (BOOL) hasLocations
{
    return _locations.count > 0;
}

- (CLLocation *) getLocation:(int)index
{
    index += _currentLocation;
    return index < _locations.count ? _locations[index] : nil;
}

- (void) incrementCurrentLocation:(int)index
{
    _currentLocation += index;
}

//Map<RouteDataObject, int[][]>
- (NSMutableDictionary *) getPointNamesMap
{
    return _pointNamesMap;
}

@end
