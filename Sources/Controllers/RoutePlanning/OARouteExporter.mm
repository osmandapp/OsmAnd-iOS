//
//  OARouteExporter.m
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARouteExporter.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"

#include "OAGPXDocumentPrimitives+cpp.h"

#include <routeSegmentResult.h>
#include <routeDataBundle.h>
#include <routeDataResources.h>

@implementation OARouteExporter
{
    NSString *_name;
    std::vector<std::shared_ptr<RouteSegmentResult>> _route;
    NSArray<CLLocation *> *_locations;
    std::vector<int> _routePointIndexes;
    NSArray<OAWptPt *> *_points;
}

- (instancetype) initWithName:(NSString *)name route:(std::vector<std::shared_ptr<RouteSegmentResult>> &)route locations:(NSArray<CLLocation *> *)locations routePointIndexes:(std::vector<int>)routePointIndexes points:(NSArray<OAWptPt *> *)points
{
    self = [super init];
    if (self) {
        _name = name;
        _route = route;
        _routePointIndexes = routePointIndexes;
        _locations = locations;
        _points = points;
    }
    return self;
}

- (OAGPXDocument *) exportRoute
{
    OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
    gpx.creator = OSMAND_ROUTER_V2;
    OATrack *track = [[OATrack alloc] init];
    track.name = _name;
    track.segments = @[[self generateRouteSegment]];
    [gpx addTrack:track];
    if (_points != nil)
    {
        for (OAWptPt *pt in _points)
        {
            [gpx addWpt:pt];
        }
    }
    return gpx;
}

+ (OAGPXMutableDocument *)exportRoute:(NSString *)name trkSegments:(NSArray<OATrkSegment *> *)trkSegments points:(NSArray<OAWptPt *> *)points
{
    OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
    gpx.creator = OSMAND_ROUTER_V2;
    OATrack *track = [[OATrack alloc] init];
    track.name = name;
    [gpx addTrack:track];
    for (OATrkSegment *seg in trkSegments)
        [gpx addTrackSegment:seg track:track];
    if (points != nil)
    {
        for (OAWptPt *pt in points)
        {
            [gpx addWpt:pt];
        }
    }
    return gpx;
}

- (OATrkSegment *) generateRouteSegment
{
    std::shared_ptr<RouteDataResources> resources = std::make_shared<RouteDataResources>([self coordinatesToLocationVector:_locations], _routePointIndexes);
    std::vector<std::shared_ptr<RouteDataBundle>> routeItems;
    if (_route.size() > 0)
    {
        for (const auto& sr : _route)
            sr->collectTypes(resources);
        for (const auto& sr : _route) {
            sr->collectNames(resources);
        }
        
        for (const auto& sr : _route)
        {
            auto itemBundle = std::make_shared<RouteDataBundle>(resources);
            sr->writeToBundle(itemBundle);
            routeItems.push_back(itemBundle);
        }
    }
    std::vector<std::shared_ptr<RouteDataBundle>> typeList;
    for (const auto& rule : resources->insertOrder)
    {
        auto typeBundle = std::make_shared<RouteDataBundle>(resources);
        rule.writeToBundle(typeBundle);
        typeList.push_back(typeBundle);
    }
    
    OATrkSegment *trkSegment = [[OATrkSegment alloc] init];
    trkSegment.points = @[];
    if (_locations == nil || _locations.count == 0)
        return trkSegment;
    
    for (NSInteger i = 0; i < _locations.count; i++)
    {
        CLLocation *loc = _locations[i];
        OAWptPt *pt = [[OAWptPt alloc] init];
        [pt setPosition:loc.coordinate];
        if (loc.speed > 0)
            pt.speed = loc.speed;
        
        if (loc.altitude > 0)
            pt.elevation = loc.altitude;
        
//        if (loc.horizontalAccuracy)
//            pt.hdop = loc.horizontalAccuracy;
        
        trkSegment.points = [trkSegment.points arrayByAddingObject:pt];
    }
    NSMutableArray<OARouteSegment *> *routeSegments = [NSMutableArray new];
    for (const auto& item : routeItems)
    {
        [routeSegments addObject:[OARouteSegment fromStringBundle:item]];
    }
    trkSegment.routeSegments = routeSegments;
    NSMutableArray<OARouteType *> *routeTypes = [NSMutableArray new];
    for (const auto& item : typeList)
    {
        [routeTypes addObject:[OARouteType fromStringBundle:item]];
    }
    trkSegment.routeTypes = routeTypes;
    [trkSegment fillExtensions];
    return trkSegment;
}

- (std::vector<Location>) coordinatesToLocationVector:(NSArray<CLLocation *> *)points
{
    std::vector<Location> res;
    for (CLLocation *pt in points)
    {
        Location loc(pt.coordinate.latitude, pt.coordinate.longitude);
        loc.altitude = pt.altitude;
        res.push_back(loc);
    }
    return res;
}

@end
