//
//  OARouteStatisticsHelper.h
//  OsmAnd
//
//  Created by Paul on 13.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "binaryRead.h"
#include "routeSegmentResult.h"

#include <vector>

NS_ASSUME_NONNULL_BEGIN

@class OARouteStatistics;

@interface OARouteSegmentWithIncline : NSObject

@property (nonatomic) std::shared_ptr<RouteDataObject> obj;
@property (nonatomic) float dist;
@property (nonatomic) float h;
@property (nonatomic) NSMutableArray<NSNumber *> *interpolatedHeightByStep;
@property (nonatomic) NSMutableArray<NSNumber *> *slopeByStep;
@property (nonatomic) NSMutableArray<NSString *> *slopeClassUserString;
@property (nonatomic) NSMutableArray<NSNumber *> *slopeClass;

@end

@interface OARouteStatisticsHelper : NSObject

+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(std::vector<SHARED_PTR<RouteSegmentResult> >)route;

@end

@interface OARouteStatisticsComputer : NSObject

- (OARouteStatistics *) computeStatistic:(NSArray<OARouteSegmentWithIncline *> *) route attribute:(NSString *) attribute;

@end

NS_ASSUME_NONNULL_END
