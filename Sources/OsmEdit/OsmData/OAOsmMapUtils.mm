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
#include <MCBinaryHeap.h>
#define POLY_CENTER_PRECISION 1e-6

// get polygon centroid
@interface OACell : NSObject

@property(nonatomic) double x; // cell center x (lon)
@property(nonatomic) double y; // cell center y (lat)
@property(nonatomic) double h; // half the cell size
@property(nonatomic) double d; // distance from cell center to polygon
@property(nonatomic) double max; // max distance to polygon within a cell

@end

@implementation OACell

- (instancetype)initWithCenter:(double)x y:(double)y h:(double)h rings:(NSArray<NSArray<OANode *> *> *)rings
{
    self = [super init];
    if (self)
    {
        _x = x;
        _y = y;
        _h = h;
        _d = [self pointToPolygonDist:x y:y rings:rings];
        _max = _d + _h * sqrt(2);
    }
    return self;
}

// signed distance from point to polygon outline (negative if point is outside)
- (double) pointToPolygonDist:(double)x y:(double)y rings:(NSArray<NSArray<OANode *> *> *)rings
{
    BOOL inside = NO;
    double minDistSq = DBL_MAX;
    
    for (NSArray<OANode *> *ring in rings)
    {
        int len = (int)ring.count;
        int j = len - 1;
        for (int i = 0; i < len; j = i++)
        {
            CLLocationCoordinate2D a = ring[i].getLatLon;
            CLLocationCoordinate2D b = ring[j].getLatLon;
            
            double aLon = a.longitude;
            double aLat = a.latitude;
            double bLon = b.longitude;
            double bLat = b.latitude;
            
            if (aLat > y != bLat > y && (x < (bLon - aLon) * (y - aLat) / (bLat - aLat) + aLon))
                inside = !inside;
            minDistSq = MIN(minDistSq, [self getSegmentDistanceSqared:x py:y a:a b:b]);
        }
    }
    return (inside ? 1 : -1) * sqrt(minDistSq);
}

- (double) getSegmentDistanceSqared:(double)px py:(double)py a:(CLLocationCoordinate2D)a b:(CLLocationCoordinate2D)b
{
    double x = a.longitude;
    double y = a.latitude;
    double dx = b.longitude - x;
    double dy = b.latitude - y;
    
    if (dx != 0 || dy != 0)
    {
        double t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy);
        
        if (t > 1)
        {
            x = b.longitude;
            y = b.latitude;
        }
        else if (t > 0)
        {
            x += dx * t;
            y += dy * t;
        }
    }
    dx = px - x;
    dy = py - y;
    return dx * dx + dy * dy;
}

- (NSComparisonResult) compare:(OACell *)otherObject
{
    return [OAUtilities compareDouble:self.max y:otherObject.max];
}

@end

@implementation OAOsmMapUtils

+(CLLocationCoordinate2D)getWeightCenterForWay:(OAWay *)way
{
    NSArray<OANode *> *nodes = [way getNodes];
    if ([nodes count] == 0)
        return kCLLocationCoordinate2DInvalid;
    BOOL area = [way getFirstNodeId] == [way getLastNodeId];
    // double check for area (could be negative all)
    if (area)
    {
        OANode *fn = [way getFirstNode];
        OANode *ln = [way getLastNode];
        if (fn && ln && [self getDistance:fn second:ln] < 50)
            area = YES;
        else
            area = NO;
    }
    CLLocationCoordinate2D ll = area ? [self.class getComplexPolyCenter:nodes inner:nil] : [self.class getWeightCenterForNodes:nodes];
    if(!CLLocationCoordinate2DIsValid(ll))
        return ll;

    double flat = ll.latitude;
    double flon = ll.longitude;
    if(!area || [self.class containsPoint:nodes lat:ll.latitude lon:ll.longitude]) {
        double minDistance = DBL_MAX;
        for (OANode *n in nodes) {
            if (n) {
                double d = OsmAnd::Utilities::distance([n getLongitude], [n getLatitude], ll.longitude, ll.latitude);
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
    return OsmAnd::Utilities::distance([e1 getLongitude], [e1 getLatitude], [e2 getLongitude], [e2 getLatitude]);
}

+(double)getDistance:(OANode *)e1 lat:(double)latitude lon:(double)longitude
{
    return OsmAnd::Utilities::distance([e1 getLongitude], [e1 getLatitude], longitude, latitude);
}

+(double) getDistance:(OANode *)e1 location:(CLLocationCoordinate2D)point
{
    return OsmAnd::Utilities::distance([e1 getLongitude], [e1 getLatitude], point.longitude, point.latitude);
}

+ (CLLocationCoordinate2D) getComplexPolyCenter:(NSArray<OANode *>*)outer inner:(NSArray<NSArray<OANode *> *> *)inner
{
    if (outer.count > 3 && outer.count <= 5 && inner == nil)
    {
        NSArray<OANode *> *sub = [NSArray arrayWithArray:outer];
        return [self.class getWeightCenterForNodes:[sub subarrayWithRange:NSMakeRange(0, sub.count - 1)]];
    }
    NSMutableArray *outerRing = [NSMutableArray array];
    NSMutableArray *rings = [NSMutableArray array];
    
    for (OANode *n in outer)
    {
        CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake([n getLatitude], [n getLongitude]);
        [outerRing addObject:[NSData dataWithBytes:&coordinates length:sizeof(coordinates)]];
    }
    [rings addObject:outerRing];
    if (inner)
    {
        for (NSArray* ring in inner)
        {
            if (ring)
            {
                NSMutableArray *ringll = [NSMutableArray array];
                for (OANode *n in ring)
                {
                    CLLocationCoordinate2D coordinates = n.getLatLon;
                    [ringll addObject:[NSData dataWithBytes:&coordinates length:sizeof(coordinates)]];
                }
            }
        }
    }
    return [self getPolylabelPoint:rings];
}


+ (CLLocationCoordinate2D) getPolylabelPoint:(NSArray<NSArray *> *)rings
{
    double minX = DBL_MAX;
    double minY = DBL_MAX;
    double maxX = DBL_MAX;
    double maxY = DBL_MAX;
    
    NSArray *outerRingCoordinates = rings.firstObject;
    for (OANode *p in outerRingCoordinates)
    {
        double lat = p.getLatitude;
        double lon = p.getLongitude;
        
        minX = MIN(minX, lon);
        minY = MIN(minY, lat);
        maxX = MAX(maxX, lon);
        maxY = MAX(maxY, lat);
    }
    
    double width = maxX - minX;
    double height = maxY - minY;
    double cellSize = MIN(width, height);
    double h = cellSize / 2;
    
    if (cellSize == 0)
        return CLLocationCoordinate2DMake(minX, minY);
    
    // a priority queue of cells in order of their "potential" (max distance to polygon)
    MCBinaryHeap *cellQueue = [MCBinaryHeap heap];
    
    // cover polygon with initial cells
    for (double x = minX; x < maxX; x += cellSize)
    {
        for (double y = minY; y < maxY; y += cellSize)
            [cellQueue addObject:[[OACell alloc] initWithCenter:x + h y:y + h h:h rings:rings]];
    }
    
    // take centroid as the first best guess
    OACell *bestCell = [self.class getCentroidCell:rings];
    if (!bestCell)
        return CLLocationCoordinate2DMake(minX, minY);
    
    // special case for rectangular polygons
    OACell *bboxCell = [[OACell alloc] initWithCenter:minX + width / 2 y:minY + height / 2 h:0 rings:rings];
    if (bboxCell.d > bestCell.d)
        bestCell = bboxCell;
    
    
    while (cellQueue.count != 0)
    {
        OACell *cell = [cellQueue popMinimumObject];
        
        // update the best cell if we found a better one
        if (cell.d > bestCell.d)
        bestCell = cell;
        
        // do not drill down further if there's no chance of a better solution
        // System.out.println(String.format("check for precision: cell.max - bestCell.d = %f Precision: %f", cell.max, precision));
        if (cell.max - bestCell.d <= POLY_CENTER_PRECISION)
            continue;
        
        // split the cell into four cells
        h = cell.h / 2;
        [cellQueue addObject:[[OACell alloc] initWithCenter:cell.x - h y:cell.y - h h:h rings:rings]];
        [cellQueue addObject:[[OACell alloc] initWithCenter:cell.x + h y:cell.y - h h:h rings:rings]];
        [cellQueue addObject:[[OACell alloc] initWithCenter:cell.x - h y:cell.y + h h:h rings:rings]];
        [cellQueue addObject:[[OACell alloc] initWithCenter:cell.x + h y:cell.y + h h:h rings:rings]];
    }
    // System.out.println(String.format("Best lat/lon: %f, %f", bestCell.y, bestCell.x));
    return CLLocationCoordinate2DMake(bestCell.y, bestCell.x);
}

- (OACell *) getCentroidCell:(NSArray<NSArray<OANode *> *> *)rings
{
    double area = 0;
    double x = 0;
    double y = 0;
    
    NSArray<OANode *> *points = rings[0];
    int len = (int)points.count;
    int j = len - 1;
    for (int i = 0; i < len; j = i++)
    {
        CLLocationCoordinate2D a = points[i].getLatLon;
        CLLocationCoordinate2D b = points[j].getLatLon;
        double aLon = a.longitude;
        double aLat = a.latitude;
        double bLon = b.longitude;
        double bLat = b.latitude;
        
        double f = aLon * bLat - bLon * aLat;
        x += (aLon + bLon) * f;
        y += (aLat + bLat) * f;
        area += f * 3;
    }
    
    if (area == 0) {
        if (points.count == 0)
            return nil;
        OANode *p = points.firstObject;
        return [[OACell alloc] initWithCenter:p.getLatitude y:p.getLongitude h:0 rings:rings];
    }
    
    return [[OACell alloc] initWithCenter:x / area y:y / area h:0 rings:rings];
}

@end
