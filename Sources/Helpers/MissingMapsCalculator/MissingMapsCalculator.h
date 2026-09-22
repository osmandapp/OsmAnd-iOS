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

@class OAMissingMapsResult, OARouteCalculationResult, OASRoutingContext;

@interface MissingMapsCalculator : NSObject
- (instancetype)init;

/** The maps the route needs and does not have, over the files the C++ planner reads; nil when it has them all. */
- (nullable OAMissingMapsResult *)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                                                       start:(CLLocation *)start
                                                     targets:(NSArray<CLLocation *> *)targets
                                             checkHHEditions:(BOOL)checkHHEditions;

/** The same over the files the OsmAndShared planner reads. */
- (nullable OAMissingMapsResult *)checkIfThereAreMissingSharedMaps:(OASRoutingContext *)ctx
                                                             start:(CLLocation *)start
                                                           targets:(NSArray<CLLocation *> *)targets
                                                   checkHHEditions:(BOOL)checkHHEditions;

/** The same for a profile on its own, over every map the app has open - a check after a download, say. */
- (nullable OAMissingMapsResult *)checkIfThereAreMissingMapsForProfile:(NSString *)profile
                                                                 start:(CLLocation *)start
                                                               targets:(NSArray<CLLocation *> *)targets
                                                       checkHHEditions:(BOOL)checkHHEditions;

/** Puts the regions of an outcome on a route, where the required maps screen reads them. */
- (void)attachResult:(nullable OAMissingMapsResult *)result
toRouteCalculationResult:(nullable OARouteCalculationResult *)routeResult;

@end

NS_ASSUME_NONNULL_END
