//
//  OARoadSegmentData.h
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <vector>

@class OAApplicationMode, OASWptPt;

@class OASRouteSegmentResult;

@interface OARoadSegmentData : NSObject

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) OASWptPt *start;
@property (nonatomic, readonly) OASWptPt *end;
@property (nonatomic, readonly) NSArray<OASWptPt *> *gpxPoints;
@property (nonatomic, readonly) NSArray<OASRouteSegmentResult *> *segments;
@property (nonatomic, readonly) double distance;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode start:(OASWptPt *)start end:(OASWptPt *)end points:(NSArray<OASWptPt *> *)points segments:(NSArray<OASRouteSegmentResult *> *)segments;

@end
