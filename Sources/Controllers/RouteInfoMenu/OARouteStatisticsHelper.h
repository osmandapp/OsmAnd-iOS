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
#include <OsmAndCore/Map/MapPresentationEnvironment.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *ROUTE_INFO_PREFIX = @"routeInfo_";

@class OARouteStatistics, OARouteSegmentAttribute, OARouteStatisticsComputer;

typedef NSDictionary<NSString *, NSNumber *> * _Nullable (^OARouteStatisticsRenderingLookup)(
    NSString *attribute,
    NSDictionary<NSString *, NSString *> *settings);

@interface OARouteSegmentWithIncline : NSObject

@property (nonatomic) std::shared_ptr<RouteDataObject> obj;

@end

@interface OARouteStatisticsHelper : NSObject

+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(std::vector<SHARED_PTR<RouteSegmentResult> >)route;
+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route attributeNames:(NSArray<NSString *> *)attributeNames;
+ (NSArray<OARouteStatistics *> *) calculateRouteStatistic:(vector<SHARED_PTR<RouteSegmentResult> >)route
                                            attributeNames:(NSArray<NSString *> *)attributeNames
                                        statisticsComputer:(OARouteStatisticsComputer *)statisticsComputer;
+ (NSArray<NSString *> *) getRouteStatisticAttrsNames:(BOOL)excludeSteepness;

@end

@interface OARouteStatisticsComputer : NSObject

- (instancetype)initWithPresentationEnvironment:(std::shared_ptr<OsmAnd::MapPresentationEnvironment>)defaultPresentationEnv;

/** Testable renderer boundary with the same current/default fallback as production. */
- (instancetype)initWithCurrentRendererLookup:(OARouteStatisticsRenderingLookup)currentRendererLookup
                        defaultRendererLookup:(OARouteStatisticsRenderingLookup)defaultRendererLookup;

- (OARouteSegmentAttribute *) classifySegment:(NSString *) attribute slopeClass:(int) slopeClass segment:(OARouteSegmentWithIncline *) segment;

@end

NS_ASSUME_NONNULL_END
