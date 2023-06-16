//
//  OAGpxRouteApproximation+cpp.h
//  OsmAnd
//
//  Created by Skalii on 12.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGpxRouteApproximation.h"

#include <routePlannerFrontEnd.h>

@interface OAGpxRouteApproximation(cpp)

@property (nonatomic) SHARED_PTR<GpxRouteApproximation> gpxApproximation;

- (instancetype) initWithApproximation:(SHARED_PTR<GpxRouteApproximation> &)gpxApproximation;

@end
