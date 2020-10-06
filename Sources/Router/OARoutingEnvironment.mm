//
//  OARoutingEnvironment.m
//  OsmAnd
//
//  Created by nnngrach on 01.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutingEnvironment.h"

@implementation OARoutingEnvironment
{
    std::shared_ptr<RoutePlannerFrontEnd> _router;
    std::shared_ptr<RoutingContext> _ctx;
    std::shared_ptr<RoutingContext> _complexCtx;
    std::shared_ptr<PrecalculatedRouteDirection> _precalculated;
}

- (instancetype) initWithRouter:(std::shared_ptr<RoutePlannerFrontEnd>)router ctx:(std::shared_ptr<RoutingContext>)ctx complexCtx:(std::shared_ptr<RoutingContext>)complexCtx precalculated:(std::shared_ptr<PrecalculatedRouteDirection>)precalculated
{
    self = [super init];
    if (self) {
        _router = router;
        _ctx = ctx;
        _complexCtx = complexCtx;
        _precalculated = precalculated;
    }
    return self;
}

- (std::shared_ptr<RoutePlannerFrontEnd>) getRouter
{
    return _router;
}

- (std::shared_ptr<RoutingContext>) getCtx
{
    return _ctx;
}

- (std::shared_ptr<RoutingContext>) getComplexCtx
{
    return _complexCtx;
}

- (std::shared_ptr<PrecalculatedRouteDirection>) getPrecalculated
{
    return _precalculated;
}

@end
