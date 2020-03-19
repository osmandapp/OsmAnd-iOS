//
//  OATransportRouteCalculationParams.h
//  OsmAnd
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OARouteCalculationResult.h"
#import "OARouteProvider.h"

#include <OsmAndCore.h>
#include <routeCalculationProgress.h>

@class OATransportRouteResult;

@protocol OATransportRouteCalculationResultListener <NSObject>

@required

- (void) onRouteCalculated:(NSArray<OATransportRouteResult *> *) route;

@end

@interface OATransportRouteCalculationParams : NSObject

@property (nonatomic) CLLocation *start;
@property (nonatomic) CLLocation *end;

@property (nonatomic) OAApplicationMode *mode;
@property (nonatomic) EOARouteService type;
@property (nonatomic) NSDictionary<NSString *, NSString *> *params;
@property (nonatomic, assign) std::shared_ptr<RouteCalculationProgress> calculationProgress;
@property (nonatomic) id<OATransportRouteCalculationResultListener> resultListener;

@end
