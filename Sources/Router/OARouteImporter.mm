//
//  OARouteImporter.m
//  OsmAnd
//
//  Created by nnngrach on 02.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteImporter.h"
#import "OAGPXDocument.h"

@implementation OARouteImporter
{
    NSString *_file;
    OAGPXDocument *_gpxFile;
    std::vector<std::shared_ptr<RouteSegmentResult>> _route;
    RoutingIndex* _region;
    std::shared_ptr<RouteDataResources> _resources;
}

- (instancetype) initWithFile:(NSString *)file
{
    self = [super init];
    if (self)
    {
        _file = file;
    }
    return self;
}

- (instancetype) initWithGpxFile:(OAGPXDocument *)gpxFile
{
    self = [super init];
    if (self)
    {
        _gpxFile = gpxFile;
    }
    return self;
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) importRoute
{
    if (_gpxFile)
    {
        [self parseRoute];
    }
    else if (_file != nil)
    {
        try
        {
            _gpxFile = [[OAGPXDocument alloc] initWithGpxFile:_file];
        }
        catch (NSException *e)
        {
            NSLog(@"Error importing route %@ %@ %@", _file, e.name, e.name);
            //return nil;
        }
    }
    return _route;
}

- (void) parseRoute
{
    [self collectLocations];
    [self collectSegments];
    [self collectTypes];
    for (const auto segment : _route)
    {
        segment->fillNames(_resources);
    }
}

- (void) collectLocations
{
    std::vector<std::shared_ptr<OsmAnd::Location>> locations = _resources -> getLocations();
    double lastElevation = RouteDataObject::HEIGHT_UNDEFINED;
    if (_gpxFile.tracks.count > 0 && _gpxFile.tracks[0].segments.count > 0 && _gpxFile.tracks[0].segments[0].points.count > 0)
    {
        for (OAGpxTrkPt *point in _gpxFile.tracks[0].segments[0].points)
        {
            OsmAnd::Location loc(point.getLatitude, point.getLongitude, 0);
            
            if (point.elevation != NAN)
            {
                loc.altitude = point.elevation;
                lastElevation = point.elevation;
            }
            else if (lastElevation != RouteDataObject::HEIGHT_UNDEFINED)
            {
                loc.altitude = lastElevation;
            }
            locations.push_back(std::make_shared<OsmAnd::Location>(loc));
        }
    }
}

- (void) collectSegments
{
    for (OAGpxRouteSegment *segment in _gpxFile.routeSegments)
    {
        std::shared_ptr<RouteDataObject> object;
        object->region = _region;
        RouteSegmentResult segmentResult(object, 0, 0);
  
        //I've skiped this line for now. I'm not shure what shall I do with StringBundle class.
        //https://github.com/osmandapp/OsmAnd/blob/7907e72781c96a1d8bf5225197952d5ebf0774a3/OsmAnd-java/src/main/java/net/osmand/router/RouteImporter.java#L100
        //segmentResult.readFromBundle(new RouteDataBundle(resources, segment.toStringBundle()));
        
        _route.push_back(std::make_shared<RouteSegmentResult>(segmentResult));
    }
    
    //TODO:...
}

- (void) collectTypes
{
    int i = 0;
    for (OAGpxRouteType *routeType in _gpxFile.routeTypes)
    {
        NSDictionary *bundle = [routeType toStringBundle];
        std::string t = std::string( [bundle[@"t"] UTF8String]);
        std::string v = std::string( [bundle[@"v"] UTF8String]);
        _region -> initRouteEncodingRule(i++, t, v);
    }
}

@end
