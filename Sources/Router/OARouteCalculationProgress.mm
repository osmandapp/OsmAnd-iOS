//
//  OARouteCalculationProgress.m
//  OsmAnd
//
//  Created by Skalii on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteCalculationProgress.h"

#include "OARouteCalculationProgress+cpp.h"

@interface OARouteCalculationProgress ()

@property (nonatomic) SHARED_PTR<RouteCalculationProgress> routeCalculationProgress;

@end

@implementation OARouteCalculationProgress

- (instancetype) initWithApproximation:(SHARED_PTR<RouteCalculationProgress> &)routeCalculationProgress
{
    self = [super init];
    if (self)
    {
        if (!routeCalculationProgress)
            return nil;
        _routeCalculationProgress = routeCalculationProgress;
    }
    return self;
}

@end
