//
//  OAOsmMapUtils.m
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmMapUtils.h"
#import "OANode.h"
#import "OAWay.h"

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Utilities.h>


@implementation OAOsmMapUtils

+(CLLocationCoordinate2D)getWeightCenterForWay:(OAWay *)way
{
    NSArray<OANode *> *nodes = [way getNodes];
    if ([nodes count] == 0)
        return kCLLocationCoordinate2DInvalid;
    BOOL area = [way getFirstNodeId] == [way getLastNodeId];
    CLLocationCoordinate2D ll = area ? [self.class getMathWeightCenterForNodes:nodes] : [self.class getWeightCenterForNodes:nodes];
    if(!CLLocationCoordinate2DIsValid(ll))
        return ll;

    double flat = ll.latitude;
    double flon = ll.longitude;
    if(!area || [self.class containsPoint:nodes lat:ll.latitude lon:ll.longitude]) {
        double minDistance = DBL_MAX;
        for (OANode *n in nodes) {
            if (n) {
                double d = OsmAnd::Utilities::distance([n getLatitude], [n getLongitude], ll.latitude, ll.longitude);
                if(d < minDistance) {
                    flat = [n getLatitude];
                    flon = [n getLongitude];
                    minDistance = d;
                }
            }
        }
    }
    
    return CLLocationCoordinate2DMake(flat, flon);
}


+(BOOL)containsPoint:(NSArray<OANode *> *) polyNodes lat:(double)latitude lon:(double) longitude
{
    return [self.class countIntersections:polyNodes lat:latitude lon:longitude] % 2 == 1;
}

/**
 * count the intersections when going from lat, lon to outside the ring
 * @param polyNodes2
 */
+(NSInteger) countIntersections:(NSArray<OANode *> *)polyNodes lat:(double)latitude lon:(double) longitude
{
    NSInteger intersections = 0;
    if ([polyNodes count] == 0)
        return 0;
    OANode *prev = nil;
    OANode *first = nil;
    OANode *last = nil;
    for(OANode *n in polyNodes) {
        if(!prev) {
            prev = n;
            first = prev;
            continue;
        }
        if(!n) {
            continue;
        }
        last = n;
        if ([self.class ray_intersect_lon:prev second:n lat:latitude lon:longitude] != -360.0) {
            intersections++;
        }
        prev = n;
    }
    if(first == nil || last == nil) {
        return 0;
    }
    // special handling, also count first and last, might not be closed, but
    // we want this!
    if ([self.class ray_intersect_lon:first second:last lat:latitude lon:longitude] != -360.0) {
        intersections++;
    }
    return intersections;
}

// try to intersect from left to right
+(double)ray_intersect_lon:(OANode *)node second:(OANode *)node2 lat:(double)latitude lon:(double)longitude
{
    // a node below
    OANode *a = [node getLatitude] < [node2 getLatitude] ? node : node2;
    // b node above
    OANode *b = a == node2 ? node : node2;
    if (latitude == [a getLatitude] || latitude == [b getLatitude]) {
        latitude += 0.00000001;
    }
    if (latitude < [a getLatitude] || latitude > [b getLatitude]) {
        return -360.0;
    } else {
        if (longitude < MIN([a getLongitude], [b getLongitude])) {
            return -360.0;
        } else {
            if ([a getLongitude] == [b getLongitude] && longitude == [a getLongitude]) {
                // the node on the boundary !!!
                return longitude;
            }
            // that tested on all cases (left/right)
            double lon = [b getLongitude] - ([b getLatitude] - latitude) * ([b getLongitude] - [a getLongitude])
            / ([b getLatitude] - [a getLatitude]);
            if (lon <= longitude) {
                return lon;
            } else {
                return -360.0;
            }
        }
    }
}


+(CLLocationCoordinate2D)getMathWeightCenterForNodes:(NSArray<OANode *> *)nodes
{
    if ([nodes count] == 0)
        return kCLLocationCoordinate2DInvalid;
    double latitude = 0.0, longitude = 0.0, sumDist = 0.0;
    OANode *prev = nil;
    for (OANode *n in nodes) {
        if (n) {
            if (!prev) {
                prev = n;
            } else {
                double dist = [self getDistance:prev second:n];
                sumDist += dist;
                longitude += ([prev getLongitude] + [n getLongitude]) * dist / 2;
                latitude += ([n getLatitude] + [n getLatitude]) * dist / 2;
                prev = n;
            }
        }
    }
    if (sumDist == 0) {
        if (!prev) {
            return kCLLocationCoordinate2DInvalid;
        }
        return [prev getLatLon];
    }
    return CLLocationCoordinate2DMake(latitude / sumDist, longitude / sumDist);
}

+(CLLocationCoordinate2D)getWeightCenterForNodes:(NSArray<OANode *> *)nodes
{
    if ([nodes count] == 0)
        return kCLLocationCoordinate2DInvalid;

    double longitude = 0, latitude = 0;
    int count = 0;
    for (OANode *n in nodes) {
        if (n)
        {
            count++;
            longitude += [n getLongitude];
            latitude += [n getLatitude];
        }
    }
    if (count == 0)
        return kCLLocationCoordinate2DInvalid;
    return CLLocationCoordinate2DMake(latitude / count, longitude / count);
}

+(double)getDistance:(OANode *) e1 second:(OANode *)e2
{
    return OsmAnd::Utilities::distance([e1 getLatitude], [e1 getLongitude], [e2 getLatitude], [e2 getLongitude]);
}

+(double)getDistance:(OANode *)e1 lat:(double)latitude lon:(double)longitude
{
    return OsmAnd::Utilities::distance([e1 getLatitude], [e1 getLongitude], latitude, longitude);
}

+(double) getDistance:(OANode *)e1 location:(CLLocationCoordinate2D)point
{
    return OsmAnd::Utilities::distance([e1 getLatitude], [e1 getLongitude], point.latitude, point.longitude);
}

@end
