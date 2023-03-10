//
//  OARouteKey.m
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"

@implementation OARouteKey

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key
{
    self = [super init];
    if (self) {
        _routeKey = key;
    }
    return self;
}


- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OARouteKey *other = (OARouteKey *)object;
        return self.routeKey == other.routeKey;
    }
    return NO;
}

- (NSUInteger) hash
{
    return self.routeKey.operator int();
}

@end
