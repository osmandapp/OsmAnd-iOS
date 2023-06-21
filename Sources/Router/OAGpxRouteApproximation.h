//
//  OAGpxRouteApproximation.h
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingEnvironment, OARouteCalculationProgress;

@interface OAGpxRouteApproximation : NSObject

- (instancetype)initWithRoutingEnvironment:(OARoutingEnvironment *)routingEnvironment
                  routeCalculationProgress:(OARouteCalculationProgress * _Nullable)routeCalculationProgress;

@end
