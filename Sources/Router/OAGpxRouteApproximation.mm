//
//  OAGpxRouteApproximation.m
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxRouteApproximation.h"
#import "OARouteCalculationProgress.h"
#import "OARouteProvider.h"

#include "OAGpxRouteApproximation+cpp.h"
#include "OARouteCalculationProgress+cpp.h"
#include "OARouteProvider+cpp.h"

#include <routingContext.h>
#include <routePlannerFrontEnd.h>

@interface OAGpxRouteApproximation ()

@property (nonatomic) SHARED_PTR<GpxRouteApproximation> gpxApproximation;

@end

@implementation OAGpxRouteApproximation

- (instancetype)initWithRoutingEnvironment:(OARoutingEnvironment *)routingEnvironment
                  routeCalculationProgress:(OARouteCalculationProgress *)routeCalculationProgress
{
    self = [super init];
    if (self)
    {
        routingEnvironment.ctx.get()->progress = routeCalculationProgress.routeCalculationProgress;
        _gpxApproximation = std::make_shared<GpxRouteApproximation>(routingEnvironment.ctx.get());
    }
    return self;
}

- (instancetype) initWithApproximation:(SHARED_PTR<GpxRouteApproximation> &)gpxApproximation
{
	self = [super init];
	if (self) {
		if (!gpxApproximation)
			return nil;
		_gpxApproximation = gpxApproximation;
	}
	return self;
}

@end
