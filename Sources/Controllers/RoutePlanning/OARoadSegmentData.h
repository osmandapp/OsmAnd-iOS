//
//  OARoadSegmentData.h
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <vector>

@class OAApplicationMode, OAWptPt;

struct RouteSegmentResult;

@interface OARoadSegmentData : NSObject

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) OAWptPt *start;
@property (nonatomic, readonly) OAWptPt *end;
@property (nonatomic, readonly) NSArray<OAWptPt *> *gpxPoints;
@property (nonatomic, readonly) std::vector<std::shared_ptr<RouteSegmentResult>> segments;
@property (nonatomic, readonly) double distance;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode start:(OAWptPt *)start end:(OAWptPt *)end points:(NSArray<OAWptPt *> *)points segments:(std::vector<std::shared_ptr<RouteSegmentResult>>)segments;

@end
