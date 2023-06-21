//
//  OARouteImporter.m
//  OsmAnd
//
//  Created by Paul on 27.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteImporter.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"

#include "OAGPXDocumentPrimitives+cpp.h"

#include <routeDataResources.h>
#include <routeSegmentResult.h>
#include <routeDataBundle.h>

@implementation OARouteImporter
{

    NSString *_file;
    OAGPXDocument *_gpxFile;
    OATrkSegment *_segment;
    NSArray<OAWptPt *> *_segmentRoutePoints;

    std::vector<std::shared_ptr<RouteSegmentResult>> _route;
}

- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
    }
    return self;
}

- (instancetype) initWithTrkSeg:(OATrkSegment *)segment segmentRoutePoints:(NSArray<OAWptPt *> *)segmentRoutePoints
{
    self = [super init];
    if (self) {
        _segment = segment;
        _segmentRoutePoints = segmentRoutePoints;
    }
    return self;
}

- (std::vector<std::shared_ptr<RouteSegmentResult>> &) importRoute
{
    if (_gpxFile != nil || _segment != nil)
    {
        [self parseRoute];
    }
    else if (_file != nil)
    {
        _gpxFile = [[OAGPXDocument alloc] initWithGpxFile:_file];
        [self parseRoute];
        _gpxFile.path = _file;
    }
    return _route;
}

- (void) parseRoute
{
    if (_segment)
    {
        [self parseRoute:_segment segmentRoutePoints:_segmentRoutePoints];
    }
    else if (_gpxFile)
    {
        NSArray<OATrkSegment *> *segments = [_gpxFile getNonEmptyTrkSegments:YES];
        for (NSInteger i = 0; i < segments.count; i++)
        {
            OATrkSegment *segment = segments[i];
            [self parseRoute:segment segmentRoutePoints:[_gpxFile getRoutePoints:i]];
        }
    }
}

- (void) parseRoute:(OATrkSegment *)segment segmentRoutePoints:(NSArray<OAWptPt *> *)segmentRoutePoints
{
    RoutingIndex *region = new RoutingIndex();
    auto resources = std::make_shared<RouteDataResources>();
    
    [self collectLocations:resources segment:segment];
    [self collectRoutePointIndexes:resources segmentRoutePoints:segmentRoutePoints];
    auto route = [self collectRouteSegments:region resources:resources segment:segment];
    [self collectRouteTypes:region segment:segment];
    for (auto& routeSegment : route)
    {
        routeSegment->fillNames(resources);
    }
    _route.insert(_route.end(), route.begin(), route.end());
}

- (void) collectRoutePointIndexes:(std::shared_ptr<RouteDataResources> &)resources segmentRoutePoints:(NSArray<OAWptPt *> *)segmentRoutePoints
{
        auto& routePointIndexes = resources->routePointIndexes;
        if (segmentRoutePoints.count > 0)
        {
            for (OAWptPt *routePoint in segmentRoutePoints)
            {
                routePointIndexes.push_back((int)routePoint.getTrkPtIndex);
            }
        }
    }

- (void) collectLocations:(std::shared_ptr<RouteDataResources> &)resources segment:(OATrkSegment *)segment
{
    auto& locations = resources->locations;
    double lastElevation = RouteDataObject::HEIGHT_UNDEFINED;
    if (segment.hasRoute)
    {
        for (OAWptPt *point in segment.points)
        {
            Location loc(point.getLatitude, point.getLongitude);
            if (!isnan(point.elevation))
            {
                loc.altitude = point.elevation;
                lastElevation = point.elevation;
            }
            else if (lastElevation != RouteDataObject::HEIGHT_UNDEFINED)
            {
                loc.altitude = lastElevation;
            }
            locations.push_back(loc);
        }
    }
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) collectRouteSegments:(RoutingIndex *)region resources:(std::shared_ptr<RouteDataResources> &)resources segment:(OATrkSegment *)segment
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route;
    for (OARouteSegment *routeSegment in segment.routeSegments)
    {
        auto object = std::make_shared<RouteDataObject>(region);
        auto segmentResult = std::make_shared<RouteSegmentResult>(object);
		auto bundle = std::make_shared<RouteDataBundle>(resources, routeSegment.toStringBundle);
        try
        {
            segmentResult->readFromBundle(bundle);
            route.push_back(segmentResult);
        }
        catch (const std::exception &ex)
        {
            NSLog(@"%s", ex.what());
        }
    }
    if (!route.empty())
    {
        // Take ownership over region only for one RouteDataObject
        route.back()->object->ownsRegion = true;
    }
    return route;
}

- (void) collectRouteTypes:(RoutingIndex *)region segment:(OATrkSegment *)segment
{
    int i = 0;
    for (OARouteType *routeType in segment.routeTypes)
	{
		auto bundle = routeType.toStringBundle;
        const auto t = bundle->getString("t", "");
        const auto v = bundle->getString("v", "");
        region->initRouteEncodingRule(i++, t, v);
    }
}

@end
