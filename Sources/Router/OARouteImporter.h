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

@class OAGPXDocument, OATrkSegment, OAWptPt;

struct RouteSegmentResult;

@interface OARouteImporter : NSObject

//- (instancetype) initWithFile:(NSString *)file;
- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile;
- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile leftSide:(BOOL)leftSide;
- (instancetype) initWithTrkSeg:(OATrkSegment *)segment segmentRoutePoints:(NSArray<OAWptPt *> *)segmentRoutePoints;

- (std::vector<std::shared_ptr<RouteSegmentResult>> &) importRoute;

@end

NS_ASSUME_NONNULL_END
