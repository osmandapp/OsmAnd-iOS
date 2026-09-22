//
//  OARouteExporter.h
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define OSMAND_ROUTER_V2 @"OsmAndRouterV2"

@class OASWptPt, OASTrkSegment, OASGpxFile, OASRouteSegmentResult;

@interface OARouteExporter : NSObject

- (instancetype)initWithName:(NSString *)name
                       route:(NSArray<OASRouteSegmentResult *> *)route
                   locations:(NSArray<CLLocation *> *)locations
           routePointIndexes:(NSArray<NSNumber *> *)routePointIndexes
                      points:(NSArray<OASWptPt *> *)points
          preserveTimestamps:(BOOL)preserveTimestamps;
- (OASGpxFile *)exportRoute;
- (OASTrkSegment *)generateRouteSegment;

+ (OASGpxFile *)exportRoute:(NSString *)name trkSegments:(NSArray<OASTrkSegment *> *)trkSegments points:(NSArray<OASWptPt *> *)points routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints;
+ (OASGpxFile *)exportTrackWithPoints:(NSArray<OASWptPt *> *)points;

@end
