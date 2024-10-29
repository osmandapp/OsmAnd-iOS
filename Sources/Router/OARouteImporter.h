//
//  OARouteImporter.h
//  OsmAnd
//
//  Created by Paul on 27.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <vector>

NS_ASSUME_NONNULL_BEGIN

@class OASGpxFile, OASTrkSegment, OASWptPt;

struct RouteSegmentResult;

@interface OARouteImporter : NSObject
- (instancetype)initWithGpxFile:(OASGpxFile *)gpxFile;
- (instancetype)initWithGpxFile:(OASGpxFile *)gpxFile leftSide:(BOOL)leftSide;
- (instancetype)initWithTrkSeg:(OASTrkSegment *)segment segmentRoutePoints:(NSArray<OASWptPt *> *)segmentRoutePoints;

- (std::vector<std::shared_ptr<RouteSegmentResult>> &) importRoute;

@end

NS_ASSUME_NONNULL_END
