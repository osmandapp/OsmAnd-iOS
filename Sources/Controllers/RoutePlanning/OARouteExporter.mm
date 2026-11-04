//
//  OARouteExporter.m
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARouteExporter.h"
#import "OAAppVersion.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAMapUtils.h"
#import "OsmAndSharedWrapper.h"


@implementation OARouteExporter
{
    NSString *_name;
    NSArray<OASRouteSegmentResult *> *_route;
    NSArray<CLLocation *> *_locations;
    NSArray<NSNumber *> *_routePointIndexes;
    NSArray<OASWptPt *> *_points;
    BOOL _preserveTimestamps;
}

- (instancetype)initWithName:(NSString *)name
                        route:(NSArray<OASRouteSegmentResult *> *)route
                    locations:(NSArray<CLLocation *> *)locations
            routePointIndexes:(NSArray<NSNumber *> *)routePointIndexes
                       points:(NSArray<OASWptPt *> *)points
           preserveTimestamps:(BOOL)preserveTimestamps
{
    self = [super init];
    if (self) {
        _name = name;
        _route = route;
        _routePointIndexes = routePointIndexes;
        _locations = locations;
        _points = points;
        _preserveTimestamps = preserveTimestamps;
    }
    return self;
}

- (OASGpxFile *)exportRoute
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:OSMAND_ROUTER_V2];
    OASTrack *track = [[OASTrack alloc] init];
    track.name = _name;
    track.segments = [NSMutableArray arrayWithObject:[self generateRouteSegment]];
    [gpx.tracks addObject:track];
    if (_points != nil)
    {
        for (OASWptPt *pt in _points)
        {
            [gpx addPointPoint:pt];
        }
    }
    return gpx;
}

+ (OASGpxFile *)exportRoute:(NSString *)name
                trkSegments:(NSArray<OASTrkSegment *> *)trkSegments
                     points:(NSArray<OASWptPt *> *)points
                routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:OSMAND_ROUTER_V2];
    OASTrack *track = [[OASTrack alloc] init];
    track.name = name;
    [gpx.tracks addObject:track];
    [track.segments addObjectsFromArray:trkSegments];
    if (points != nil)
    {
        for (OASWptPt *pt in points)
        {
            [gpx addPointPoint:pt];
        }
    }
    if (routePoints != nil)
    {
        for (NSArray<OASWptPt *> *wptPts in routePoints)
        {
            [gpx addRoutePointsPoints:wptPts addRoute:YES];
        }
    }
    
    return gpx;
}

+ (OASGpxFile *)exportTrackWithPoints:(NSArray<OASWptPt *> *)points
{
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    OASTrack *track = [[OASTrack alloc] init];
    track.segments = [NSMutableArray array];
    NSMutableArray<OASWptPt *> *trkPoints = [NSMutableArray array];
    OASTrkSegment *segment = [[OASTrkSegment alloc] init];
    OASWptPt *previousPoint = nil;
    double cumulativeDistance = 0;
    for (OASWptPt *point in points)
    {
        if (point.isGap)
        {
            if (trkPoints.count > 0)
            {
                segment.points = trkPoints;
                [track.segments addObject:segment];
            }
            trkPoints = [NSMutableArray array];
            segment = [[OASTrkSegment alloc] init];
            previousPoint = nil;
            cumulativeDistance = 0;
            continue;
        }
        OASWptPt *trkPoint = [[OASWptPt alloc] initWithWptPt:point];
        if (previousPoint != nil)
            cumulativeDistance += [OAMapUtils getDistance:previousPoint.lat lon1:previousPoint.lon lat2:point.lat lon2:point.lon];
        else
            cumulativeDistance = 0;
        trkPoint.distance = cumulativeDistance;
        [trkPoints addObject:trkPoint];
        previousPoint = point;
    }

    if (trkPoints.count > 0)
    {
        segment.points = trkPoints;
        [track.segments addObject:segment];
    }

    gpx.tracks = [@[track] mutableCopy];
    return gpx;
}

- (OASTrkSegment *)generateRouteSegment
{
    OASRouteDataResources *resources = [[OASRouteDataResources alloc] initWithLocations:[self toLocations:_locations]
                                                                     routePointIndexes:[self toRoutePointIndexes:_routePointIndexes]];
    NSMutableArray<OASRouteDataBundle *> *routeItems = [NSMutableArray array];
    if (_route.count > 0)
    {
        for (OASRouteSegmentResult *sr in _route)
            [sr collectTypesResources:resources];
        for (OASRouteSegmentResult *sr in _route)
            [sr collectNamesResources:resources];

        for (OASRouteSegmentResult *sr in _route)
        {
            OASRouteDataBundle *itemBundle = [[OASRouteDataBundle alloc] initWithResources:resources];
            [sr writeToBundleBundle:itemBundle];
            [routeItems addObject:itemBundle];
        }
    }
    
    OASTrkSegment *trkSegment = [[OASTrkSegment alloc] init];
    trkSegment.points = [@[] mutableCopy];
    if (_locations == nil || _locations.count == 0)
        return trkSegment;
    
    NSMutableArray<OASWptPt *> *newPoints = [NSMutableArray arrayWithCapacity:_locations.count];
    for (NSInteger i = 0; i < _locations.count; i++)
    {
        CLLocation *loc = _locations[i];
        OASWptPt *pt = [[OASWptPt alloc] initWithLat:loc.coordinate.latitude lon:loc.coordinate.longitude];
        if (loc.speed > 0)
            pt.speed = loc.speed;

        if (_preserveTimestamps)
        {
            NSTimeInterval timestamp = loc.timestamp.timeIntervalSince1970;
            if (timestamp > 0)
                pt.time = (int64_t)(timestamp * 1000.0);
        }
        
        if (loc.altitude > 0)
            pt.ele = loc.altitude;
        
        [newPoints addObject:pt];
    }
    trkSegment.points = newPoints;
    
    NSMutableArray<OASGpxUtilitiesRouteSegment *> *routeSegments = [NSMutableArray new];
    for (OASRouteDataBundle *item in routeItems)
        [routeSegments addObject:[self.class getRouteSegmentFromStringBundle:item]];

    trkSegment.routeSegments = routeSegments;
    trkSegment.routeTypes = [self.class getRouteTypes:resources];
    return trkSegment;
}

- (NSMutableArray<OASKLocation *> *) toLocations:(NSArray<CLLocation *> *)points
{
    NSMutableArray<OASKLocation *> *res = [NSMutableArray arrayWithCapacity:points.count];
    for (CLLocation *pt in points)
    {
        OASKLocation *loc = [[OASKLocation alloc] initWithProvider:@"" latitude:pt.coordinate.latitude longitude:pt.coordinate.longitude];
        loc.altitude = pt.altitude;
        [res addObject:loc];
    }
    return res;
}

- (NSMutableArray<OASInt *> *) toRoutePointIndexes:(NSArray<NSNumber *> *)indexes
{
    NSMutableArray<OASInt *> *res = [NSMutableArray arrayWithCapacity:indexes.count];
    for (NSNumber *index in indexes)
        [res addObject:[OASInt numberWithInt:index.intValue]];

    return res;
}

/**
 * The rules the segments collected, in the order the segments refer to them by: the map holds each
 * rule's index, and going through it by index is what the java exporter's insertion-ordered map
 * gives it. The tag and value are written straight out - putting them through a bundle first, as
 * the segments go, would only be putting them in to take them back out.
 */
+ (NSMutableArray<OASGpxUtilitiesRouteType *> *) getRouteTypes:(OASRouteDataResources *)resources
{
    NSDictionary<OASRouteTypeRule *, OASInt *> *rules = [resources getRules];
    NSMutableArray<OASGpxUtilitiesRouteType *> *res = [NSMutableArray arrayWithCapacity:rules.count];
    for (int i = 0; i < (int) rules.count; i++)
        [res addObject:[[OASGpxUtilitiesRouteType alloc] init]];

    for (OASRouteTypeRule *rule in rules)
    {
        int index = rules[rule].intValue;
        if (index < 0 || index >= (int) res.count)
            continue;

        res[index].tag = rule.getTag;
        res[index].value = rule.getValue ? rule.getValue : @"";
    }
    return res;
}

+ (OASGpxUtilitiesRouteSegment *) getRouteSegmentFromStringBundle:(OASRouteDataBundle *)bundle
{
    OASGpxUtilitiesRouteSegment *s = [[OASGpxUtilitiesRouteSegment alloc] init];
    s.id = [bundle getStringKey:@"id" defaultValue:@""];
    s.length = [bundle getStringKey:@"length" defaultValue:@""];
    s.startTrackPointIndex = [bundle getStringKey:@"startTrkptIdx" defaultValue:@""];
    s.segmentTime = [bundle getStringKey:@"segmentTime" defaultValue:@""];
    s.speed = [bundle getStringKey:@"speed" defaultValue:@""];
    s.turnType = [bundle getStringKey:@"turnType" defaultValue:@""];
    s.turnAngle = [bundle getStringKey:@"turnAngle" defaultValue:@""];
    s.types = [bundle getStringKey:@"types" defaultValue:@""];
    s.pointTypes = [bundle getStringKey:@"pointTypes" defaultValue:@""];
    s.names = [bundle getStringKey:@"names" defaultValue:@""];
    return s;
}

@end
