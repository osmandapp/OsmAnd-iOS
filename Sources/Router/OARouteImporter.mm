//
//  OARouteImporter.m
//  OsmAnd
//
//  Created by Paul on 27.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteImporter.h"
#import "OAGPXDocumentPrimitives.h"

#import "OsmAndSharedWrapper.h"

@implementation OARouteImporter
{

    NSString *_file;
    OASGpxFile *_gpxFile;
    OASTrkSegment *_segment;
    NSArray<OASWptPt *> *_segmentRoutePoints;
    BOOL _leftSide;

    NSMutableArray<OASRouteSegmentResult *> *_route;
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

- (NSArray<OASRouteSegmentResult *> *) importRoute
{
    _route = [NSMutableArray array];
    if (_gpxFile != nil || _segment != nil)
    {
        [self parseRoute];
    }
    else if (_file != nil)
    {
        OASKFile *file = [[OASKFile alloc] initWithFilePath:_file];
        _gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];
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
    OASRouteRegion *region = [[OASRouteRegion alloc] init];
    OASRouteDataResources *resources = [[OASRouteDataResources alloc] initWithLocations:[NSMutableArray array]
                                                                     routePointIndexes:[NSMutableArray array]];

    [self collectLocations:resources segment:segment];
    [self collectRoutePointIndexes:resources segmentRoutePoints:segmentRoutePoints];
    NSArray<OASRouteSegmentResult *> *route = [self collectRouteSegments:region resources:resources segment:segment];
    [self collectRouteTypes:region segment:segment];
    for (OASRouteSegmentResult *routeSegment in route)
        [routeSegment fillNamesResources:resources];

    [_route addObjectsFromArray:route];
}

- (void) collectRoutePointIndexes:(OASRouteDataResources *)resources segmentRoutePoints:(NSArray<OASWptPt *> *)segmentRoutePoints
{
    NSMutableArray<OASInt *> *routePointIndexes = [resources getRoutePointIndexes];
    for (OASWptPt *routePoint in segmentRoutePoints)
        [routePointIndexes addObject:[OASInt numberWithInt:(int) routePoint.getTrkPtIndex]];
}

- (void) collectLocations:(OASRouteDataResources *)resources segment:(OASTrkSegment *)segment
{
    NSMutableArray<OASKLocation *> *locations = [resources getLocations];
    double lastElevation = OASRouteDataObject.companion.HEIGHT_UNDEFINED;
    if (segment.hasRoute)
    {
        for (OASWptPt *point in segment.points)
        {
            OASKLocation *loc = [[OASKLocation alloc] initWithProvider:@"" latitude:point.getLatitude longitude:point.getLongitude];
            if (!isnan(point.ele))
            {
                loc.altitude = point.ele;
                lastElevation = point.ele;
            }
            else if (lastElevation != OASRouteDataObject.companion.HEIGHT_UNDEFINED)
            {
                loc.altitude = lastElevation;
            }
            [locations addObject:loc];
        }
    }
}

- (NSArray<OASRouteSegmentResult *> *) collectRouteSegments:(OASRouteRegion *)region resources:(OASRouteDataResources *)resources segment:(OASTrkSegment *)segment
{
    NSMutableArray<OASRouteSegmentResult *> *route = [NSMutableArray array];
    for (OASGpxUtilitiesRouteSegment *routeSegment in segment.routeSegments)
    {
        // A segment that claims more track points than the track has would read past the end of the
        // locations, which the shared reader answers with an exception rather than a return value.
        int length = abs(routeSegment.length.intValue);
        if ([resources getCurrentSegmentStartLocationIndex] + length > (int) [resources getLocations].count)
        {
            NSLog(@"Route segment of %d points does not fit the track", length);
            continue;
        }

        OASRouteDataObject *object = [[OASRouteDataObject alloc] initWithRegion:region];
        OASRouteSegmentResult *segmentResult = [[OASRouteSegmentResult alloc] initWithRouteObject:object leftside:_leftSide];
        [segmentResult readFromBundleBundle:[self routeSegmentToBundle:routeSegment resources:resources]];
        [route addObject:segmentResult];
    }
    return route;
}

- (OASRouteDataBundle *) routeSegmentToBundle:(OASGpxUtilitiesRouteSegment *)routeSegment resources:(OASRouteDataResources *)resources
{
    OASRouteDataBundle *bundle = [[OASRouteDataBundle alloc] initWithResources:resources];
    [self addToBundleIfNotNull:@"id" value:routeSegment.id bundle:bundle];
    [self addToBundleIfNotNull:@"length" value:routeSegment.length bundle:bundle];
    [self addToBundleIfNotNull:@"startTrkptIdx" value:routeSegment.startTrackPointIndex bundle:bundle];
    [self addToBundleIfNotNull:@"segmentTime" value:routeSegment.segmentTime bundle:bundle];
    [self addToBundleIfNotNull:@"speed" value:routeSegment.speed bundle:bundle];
    [self addToBundleIfNotNull:@"turnType" value:routeSegment.turnType bundle:bundle];
    [self addToBundleIfNotNull:@"turnAngle" value:routeSegment.turnAngle bundle:bundle];
    [self addToBundleIfNotNull:@"types" value:routeSegment.types bundle:bundle];
    [self addToBundleIfNotNull:@"pointTypes" value:routeSegment.pointTypes bundle:bundle];
    [self addToBundleIfNotNull:@"names" value:routeSegment.names bundle:bundle];
    return bundle;
}

- (void) addToBundleIfNotNull:(NSString *)key value:(NSString *)value bundle:(OASRouteDataBundle *)bundle
{
    if (value)
        [bundle putStringKey:key value:value];
}

- (void) collectRouteTypes:(OASRouteRegion *)region segment:(OASTrkSegment *)segment
{
    int i = 0;
    for (OASGpxUtilitiesRouteType *routeType in segment.routeTypes)
    {
        OASStringBundle *bundle = routeType.toStringBundle;
        [region doInitRouteEncodingRuleId:i++
                                     tags:[bundle getStringKey:@"t" defaultValue:@""]
                                      val:[bundle getStringKey:@"v" defaultValue:@""]];
    }
}

@end
