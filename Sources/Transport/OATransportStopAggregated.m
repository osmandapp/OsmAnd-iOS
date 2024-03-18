//
//  OATransportStopAggregated.m
//  OsmAnd
//
//  Created by Max Kojin on 08/03/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OATransportStopAggregated.h"

@implementation OATransportStopAggregated

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _localTransportStops = [NSMutableArray new];
        _nearbyTransportStops = [NSMutableArray new];
    }
    return self;
}

- (void) addLocalTransportStop:(OATransportStop *)transportStop
{
    [_localTransportStops addObject:transportStop];
}

- (void) addNearbyTransportStop:(OATransportStop *)transportStop
{
    [_nearbyTransportStops addObject:transportStop];
}

@end
