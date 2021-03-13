//
//  OAGPXUIHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXUIHelper.h"
#import "OAGPXDocument.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAGPXDatabase.h"

@implementation OAGPXUIHelper

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route
{
    double lastHeight = RouteDataObject::HEIGHT_UNDEFINED;
    OAGPXDocument *gpx = [[OAGPXDocument alloc] init];
    NSArray<CLLocation *> *locations = route.getRouteLocations;
    if (locations)
    {
        OAGpxTrk *track = [[OAGpxTrk alloc] init];
        OAGpxTrkSeg *seg = [[OAGpxTrkSeg alloc] init];
        NSMutableArray<OAGpxTrkPt *> *segPoints = [NSMutableArray new];
        for (CLLocation *l in locations)
        {
            OAGpxTrkPt *point = [[OAGpxTrkPt alloc] init];
            [point setPosition:l.coordinate];
            if (l.altitude != 0)
            {
                gpx.hasAltitude = YES;
                CLLocationDistance h = l.altitude;
                point.elevation = h;
                if (lastHeight == RouteDataObject::HEIGHT_UNDEFINED && seg.points.count > 0)
                {
                    for (OAGpxTrkPt *pt in seg.points)
                    {
                        if (pt.elevation == NAN)
                            pt.elevation = h;
                    }
                }
                lastHeight = h;
            }
            [segPoints addObject:point];
        }
        seg.points = segPoints;
        track.segments = @[seg];
        gpx.tracks = @[track];
    }
    return gpx;
}

+ (NSString *) getDescription:(OAGPX *)gpx
{
    NSString *dist = [[OsmAndApp instance] getFormattedDistance:gpx.totalDistance];
    NSString *wpts = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_waypoints"), gpx.wptPoints];
    return [NSString stringWithFormat:@"%@ • %@", dist, wpts];
}

+ (long) getSegmentTime:(OAGpxTrkSeg *)segment
{
    long startTime = LONG_MAX;
    long endTime = LONG_MIN;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OAGpxTrkPt *point = segment.points[i];
        long time = point.time;
        if (time != 0) {
            startTime = MIN(startTime, time);
            endTime = MAX(endTime, time);
        }
    }
    return endTime - startTime;
}

+ (double) getSegmentDistance:(OAGpxTrkSeg *)segment
{
    double distance = 0;
    OAGpxTrkPt *prevPoint = nil;
    for (NSInteger i = 0; i < segment.points.count; i++)
    {
        OAGpxTrkPt *point = segment.points[i];
        if (prevPoint != nil)
            distance += getDistance(prevPoint.getLatitude, prevPoint.getLongitude, point.getLatitude, point.getLongitude);
        prevPoint = point;
    }
    return distance;
}

@end
