//
//  OAGpxRouteApproximation.m
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxRouteApproximation.h"

#include <routePlannerFrontEnd.h>

@implementation OAGpxRouteApproximation

- (instancetype) initWithApproximation:(std::shared_ptr<GpxRouteApproximation> &)gpxApproximation
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
