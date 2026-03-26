//
//  MissingMapsCalculator.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWorldRegion.h"

#include <routingContext.h>

NS_ASSUME_NONNULL_BEGIN

@class OARouteCalculationResult;

@interface MissingMapsCalculator : NSObject
- (instancetype)init;

- (BOOL)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                             start:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets
                   checkHHEditions:(BOOL)checkHHEditions;
- (void)attachToRouteCalculationResult:(OARouteCalculationResult *)routeResult
                              progress:(std::shared_ptr<RouteCalculationProgress>)progress;

@end

NS_ASSUME_NONNULL_END
