//
//  OARoutingEnvironment.h
//  OsmAnd
//
//  Created by nnngrach on 01.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <precalculatedRouteDirection.h>
#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>

@interface OARoutingEnvironment : NSObject

- (instancetype) initWithRouter:(std::shared_ptr<RoutePlannerFrontEnd>)router ctx:(std::shared_ptr<RoutingContext>)ctx complexCtx:(std::shared_ptr<RoutingContext>)complexCtx precalculated:(std::shared_ptr<PrecalculatedRouteDirection>)precalculated;
- (std::shared_ptr<RoutePlannerFrontEnd>) getRouter;
- (std::shared_ptr<RoutingContext>) getCtx;
- (std::shared_ptr<RoutingContext>) getComplexCtx;
- (std::shared_ptr<PrecalculatedRouteDirection>) getPrecalculated;

@end
