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

#define OSMAND_ROUTER_V2 @"OsmAndRouterV2"

@class OAWptPt, OAGPXMutableDocument, OAGPXDocument, OATrkSegment;
struct RouteSegmentResult;

@interface OARouteExporter : NSObject

- (instancetype) initWithName:(NSString *)name route:(std::vector<std::shared_ptr<RouteSegmentResult>> &)route locations:(NSArray<CLLocation *> *)locations points:(NSArray<OAWptPt *> *)points;
- (OAGPXDocument *) exportRoute;
- (OATrkSegment *) generateRouteSegment;

+ (OAGPXMutableDocument *)exportRoute:(NSString *)name trkSegments:(NSArray<OATrkSegment *> *)trkSegments points:(NSArray<OAWptPt *> *)points;

@end
