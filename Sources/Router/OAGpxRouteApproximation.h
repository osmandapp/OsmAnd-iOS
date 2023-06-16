//
//  OAGpxRouteApproximation.h
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingEnvironment, OARouteCalculationProgress;

NS_ASSUME_NONNULL_BEGIN

@interface OAGpxRouteApproximation : NSObject

- (instancetype)initWithRoutingEnvironment:(OARoutingEnvironment *)routingEnvironment
                  routeCalculationProgress:(OARouteCalculationProgress *)routeCalculationProgress;

@end

NS_ASSUME_NONNULL_END
