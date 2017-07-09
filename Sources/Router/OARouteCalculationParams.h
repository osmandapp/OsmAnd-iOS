//
//  OARouteCalculationParams.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OARouteCalculationResult.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"

#include <OsmAndCore.h>
#include <routeCalculationProgress.h>

@interface OARouteCalculationParams : NSObject

@property (nonatomic) CLLocation *start;
@property (nonatomic) CLLocation *end;
@property (nonatomic) NSArray<CLLocation *> *intermediates;

@property (nonatomic) OAMapVariantType mode;
@property (nonatomic) EOARouteService type;
@property (nonatomic) OAGPXRouteParams *gpxRoute;
@property (nonatomic) OARouteCalculationResult *previousToRecalculate;
@property (nonatomic) BOOL onlyStartPointChanged;
@property (nonatomic) BOOL fast;
@property (nonatomic) BOOL leftSide;
@property (nonatomic, assign) std::shared_ptr<RouteCalculationProgress> calculationProgress;

@end
