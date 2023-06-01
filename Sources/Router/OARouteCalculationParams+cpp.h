//
//  OARouteCalculationParams+cpp.h
//  OsmAnd
//
//  Created by Skalii on 01.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteCalculationParams.h"

#include <routeCalculationProgress.h>

@interface OARouteCalculationParams(cpp)

@property (nonatomic, assign) std::shared_ptr<RouteCalculationProgress> calculationProgress;

@end
