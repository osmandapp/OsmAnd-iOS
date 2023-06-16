//
//  OARouteCalculationProgress+cpp.h
//  OsmAnd
//
//  Created by Skalii on 13.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteCalculationProgress.h"

#include <routeCalculationProgress.h>

@interface OARouteCalculationProgress(cpp)

@property (nonatomic) SHARED_PTR<RouteCalculationProgress> routeCalculationProgress;

- (instancetype)initWithRouteCalculationProgress:(SHARED_PTR<RouteCalculationProgress> &)routeCalculationProgress;

@end
