//
//  OATransportRouteResult.h
//  OsmAnd
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/Data/TransportStop.h>

@interface OATransportRouteResult : NSObject

// properties
//    std::vector<TransportRouteResultSegment> _segments;
//    TransportRoutingConfiguration _cfg;
@property (nonatomic) double finishWalkDist;
@property (nonatomic) double routeTime;

- (double) getWalkingDistance;
- (double) getWalkingSpeed;
- (NSInteger) getStops;
- (BOOL) isRouteStop:(std::shared_ptr<const OsmAnd::TransportStop>) stop;
- (double) getTravelDist;
- (double) getTravelTime;
- (double) getWalkTime;
- (double) getChangeTime;
- (double) getBoardingTime;
- (NSInteger) getChanges;

- (NSString *) toNSString;

@end
