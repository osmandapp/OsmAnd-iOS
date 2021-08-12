//
//  OARouteExporter.h
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

@class OAGpxTrkPt, OAGPXMutableDocument, OAGPXDocument, OAGpxTrkSeg;
struct RouteSegmentResult;

@interface OARouteExporter : NSObject

- (instancetype) initWithName:(NSString *)name route:(std::vector<std::shared_ptr<RouteSegmentResult>> &)route locations:(NSArray<CLLocation *> *)locations points:(NSArray<OAGpxTrkPt *> *)points;
- (OAGPXDocument *) exportRoute;
- (OAGpxTrkSeg *) generateRouteSegment;

+ (OAGPXMutableDocument *) exportRoute:(NSString *)name trkSegments:(NSArray<OAGpxTrkSeg *> *)trkSegments points:(NSArray<OAGpxTrkPt *> *)points;

@end
