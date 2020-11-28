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

@implementation OARouteImporter
{

    NSString *_file;
    OAGPXDocument *_gpxFile;
    OAGpxTrkSeg *_segment;

    std::vector<std::shared_ptr<RouteSegmentResult>> _route;
}

//    public RouteImporter(File file) {
//        this.file = file;
//    }

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

//- (std::vector<std::shared_ptr<RouteSegmentResult>>) importRoute
//{
//    if (gpxFile != null || segment != null) {
//        parseRoute();
//    } else if (file != null) {
//        FileInputStream fis = null;
//        try {
//            fis = new FileInputStream(file);
//            gpxFile = GPXUtilities.loadGPXFile(fis);
//            parseRoute();
//            gpxFile.path = file.getAbsolutePath();
//            gpxFile.modifiedTime = file.lastModified();
//        } catch (IOException e) {
//            log.error("Error importing route " + file.getAbsolutePath(), e);
//            return null;
//        } finally {
//            try {
//                if (fis != null) {
//                    fis.close();
//                }
//            } catch (IOException ignore) {
//                // ignore
//            }
//        }
//    }
//    return route;
//}
//
//- (void) parseRoute
//{
//    if (_segment != nil)
//    {
//        [self parseRoute:_segment];
//    }
//    else if (_gpxFile != nil)
//    {
//        NSArray<OAGpxTrkSeg *> *segments = [gpxFile getNonEmptyTrkSegments:YES];
//        for (OAGpxTrkSeg *s in segments)
//            [self parseRoute:s];
//    }
//}
//
//- (void) parseRoute:(OAGpxTrkSeg *)segment
//{
//    OARouteRegion *region = new RouteRegion();
//    OARouteDataResources *resources = new RouteDataResources();
//    
//    collectLocations(resources, segment);
//    List<RouteSegmentResult> route = collectRouteSegments(region, resources, segment);
//    collectRouteTypes(region, segment);
//    for (RouteSegmentResult routeSegment : route) {
//        routeSegment.fillNames(resources);
//    }
//    this.route.addAll(route);
//}
//
//private void collectLocations(RouteDataResources resources, TrkSegment segment) {
//    List<Location> locations = resources.getLocations();
//    double lastElevation = HEIGHT_UNDEFINED;
//    if (segment.hasRoute()) {
//        for (WptPt point : segment.points) {
//            Location loc = new Location("", point.getLatitude(), point.getLongitude());
//            if (!Double.isNaN(point.ele)) {
//                loc.setAltitude(point.ele);
//                lastElevation = point.ele;
//            } else if (lastElevation != HEIGHT_UNDEFINED) {
//                loc.setAltitude(lastElevation);
//            }
//            locations.add(loc);
//        }
//    }
//}
//
//private List<RouteSegmentResult> collectRouteSegments(RouteRegion region, RouteDataResources resources, TrkSegment segment) {
//    List<RouteSegmentResult> route = new ArrayList<>();
//    for (RouteSegment routeSegment : segment.routeSegments) {
//        RouteDataObject object = new RouteDataObject(region);
//        RouteSegmentResult segmentResult = new RouteSegmentResult(object);
//        segmentResult.readFromBundle(new RouteDataBundle(resources, routeSegment.toStringBundle()));
//        route.add(segmentResult);
//    }
//    return route;
//}
//
//private void collectRouteTypes(RouteRegion region, TrkSegment segment) {
//    int i = 0;
//    for (RouteType routeType : segment.routeTypes) {
//        StringBundle bundle = routeType.toStringBundle();
//        String t = bundle.getString("t", null);
//        String v = bundle.getString("v", null);
//        region.initRouteEncodingRule(i++, t, v);
//    }
//}

@end
