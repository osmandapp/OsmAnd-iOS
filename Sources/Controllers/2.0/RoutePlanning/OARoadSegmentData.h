//
//  OARoadSegmentData.h
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode, OAGpxTrkPt, RouteSegmentResult;

@interface OARoadSegmentData : NSObject

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) OAGpxTrkPt *start;
@property (nonatomic, readonly) OAGpxTrkPt *end;
@property (nonatomic, readonly) NSArray<OAGpxTrkPt *> *points;
@property (nonatomic, readonly) std::vector<std::shared_ptr<RouteSegmentResult>> segments;
@property (nonatomic, readonly) double distance;

@end
