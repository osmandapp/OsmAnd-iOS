//
//  OARouteImporter.m
//  OsmAnd
//
//  Created by Paul on 27.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteImporter.h"
#import "OAGPXDocumentPrimitives.h"
//#import "OsmAndSharedWrapper.h"

#include <routeDataResources.h>
#include <routeSegmentResult.h>
#include <routeDataBundle.h>

@implementation OARouteImporter
{

    NSString *_file;
    OASGpxFile *_gpxFile;
    OASTrkSegment *_segment;
    NSArray<OASWptPt *> *_segmentRoutePoints;
    BOOL _leftSide;

    std::vector<std::shared_ptr<RouteSegmentResult>> _route;
}

- (instancetype) initWithGpxFile:(OASGpxFile *)gpxFile
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        _leftSide = false;
    }
    return self;
}

- (instancetype) initWithGpxFile:(OASGpxFile *)gpxFile leftSide:(BOOL)leftSide
{
    self = [super init];
    if (self) {
        _gpxFile = gpxFile;
        _leftSide = leftSide;
    }
    return self;
}

- (instancetype) initWithTrkSeg:(OASTrkSegment *)segment segmentRoutePoints:(NSArray<OASWptPt *> *)segmentRoutePoints
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
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_file];
        OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
        
        _gpxFile = gpxFile;
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
        NSArray<OASTrkSegment *> *segments = [_gpxFile getNonEmptyTrkSegmentsRoutesOnly:YES];
        for (int i = 0; i < segments.count; i++)
        {
            OASTrkSegment *segment = segments[i];
            [self parseRoute:segment segmentRoutePoints:[_gpxFile getRoutePointsRouteIndex:i]];
        }
    }
}

- (void) parseRoute:(OASTrkSegment *)segment segmentRoutePoints:(NSArray<OASWptPt *> *)segmentRoutePoints
{
    auto region = std::make_shared<RoutingIndex>();
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

- (void) collectRoutePointIndexes:(std::shared_ptr<RouteDataResources> &)resources segmentRoutePoints:(NSArray<OASWptPt *> *)segmentRoutePoints
{
        auto& routePointIndexes = resources->routePointIndexes;
        if (segmentRoutePoints.count > 0)
        {
            for (OASWptPt *routePoint in segmentRoutePoints)
            {
                routePointIndexes.push_back((int)routePoint.getTrkPtIndex);
            }
        }
    }

- (void) collectLocations:(std::shared_ptr<RouteDataResources> &)resources segment:(OASTrkSegment *)segment
{
    auto& locations = resources->locations;
    double lastElevation = RouteDataObject::HEIGHT_UNDEFINED;
    if (segment.hasRoute)
    {
        for (OASWptPt *point in segment.points)
        {
            Location loc(point.getLatitude, point.getLongitude);
            if (!isnan(point.ele))
            {
                loc.altitude = point.ele;
                lastElevation = point.ele;
            }
            else if (lastElevation != RouteDataObject::HEIGHT_UNDEFINED)
            {
                loc.altitude = lastElevation;
            }
            locations.push_back(loc);
        }
    }
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) collectRouteSegments:(const std::shared_ptr<RoutingIndex>&)region resources:(std::shared_ptr<RouteDataResources> &)resources segment:(OASTrkSegment *)segment
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route;
    // FIXME:
//    for (OASGpxUtilitiesRouteSegment *routeSegment in segment.routeSegments)
//    {
//        auto object = std::make_shared<RouteDataObject>(region);
//        auto segmentResult = std::make_shared<RouteSegmentResult>(object, _leftSide);
//        // routeSegment.toStringBundle - crash
//		auto bundle = std::make_shared<RouteDataBundle>(resources, routeSegment.toStringBundle);
//        try
//        {
//            segmentResult->readFromBundle(bundle);
//            route.push_back(segmentResult);
//        }
//        catch (const std::exception &ex)
//        {
//            NSLog(@"%s", ex.what());
//        }
//    }
    return route;
}

- (void) collectRouteTypes:(const std::shared_ptr<RoutingIndex>&)region segment:(OASTrkSegment *)segment
{
    int i = 0;
    for (OASGpxUtilitiesRouteType *routeType in segment.routeTypes)
	{
        OASStringBundle *bundle = routeType.toStringBundle;
        
        NSString *t = [bundle getStringKey:@"t" defaultValue:@""];
        NSString *v = [bundle getStringKey:@"v" defaultValue:@""];
       
        region->initRouteEncodingRule(i++, std::string([t UTF8String]), std::string([v UTF8String]));
    }
}

@end
