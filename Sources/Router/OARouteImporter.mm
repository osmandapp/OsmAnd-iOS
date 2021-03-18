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

#include <routeDataResources.h>
#include <routeSegmentResult.h>
#include <routeDataBundle.h>

@implementation OARouteImporter
{

    NSString *_file;
    OAGPXDocument *_gpxFile;
    OAGpxTrkSeg *_segment;

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

- (instancetype) initWithTrkSeg:(OAGpxTrkSeg *)segment
{
    self = [super init];
    if (self) {
        _segment = segment;
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
        [self parseRoute:_segment];
    }
    else if (_gpxFile)
    {
        NSArray<OAGpxTrkSeg *> *segments = [_gpxFile getNonEmptyTrkSegments:YES];
        for (OAGpxTrkSeg *s in segments)
        {
            [self parseRoute:s];
        }
    }
}

- (void) parseRoute:(OAGpxTrkSeg *)segment
{
    RoutingIndex *region = new RoutingIndex();
    auto resources = std::make_shared<RouteDataResources>();
    
    [self collectLocations:resources segment:segment];
    auto route = [self collectRouteSegments:region resources:resources segment:segment];
    [self collectRouteTypes:region segment:segment];
    for (auto& routeSegment : route)
    {
        routeSegment->fillNames(resources);
    }
    _route.insert(_route.end(), route.begin(), route.end());
}

- (void) collectLocations:(std::shared_ptr<RouteDataResources> &)resources segment:(OAGpxTrkSeg *)segment
{
    auto& locations = resources->locations;
    double lastElevation = RouteDataObject::HEIGHT_UNDEFINED;
    if (segment.hasRoute)
    {
        for (OAGpxTrkPt *point in segment.points)
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

- (std::vector<std::shared_ptr<RouteSegmentResult>>) collectRouteSegments:(RoutingIndex *)region resources:(std::shared_ptr<RouteDataResources> &)resources segment:(OAGpxTrkSeg *)segment
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route;
    for (OARouteSegment *routeSegment in segment.routeSegments)
    {
        auto object = std::make_shared<RouteDataObject>(region);
        auto segmentResult = std::make_shared<RouteSegmentResult>(object);
		auto bundle = std::make_shared<RouteDataBundle>(resources, routeSegment.toStringBundle);
        segmentResult->readFromBundle(bundle);
        route.push_back(segmentResult);
    }
    if (!route.empty())
    {
        // Take ownership over region only for one RouteDataObject
        (*route.begin())->object->ownsRegion = true;
    }
    return route;
}

- (void) collectRouteTypes:(RoutingIndex *)region segment:(OAGpxTrkSeg *)segment
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
