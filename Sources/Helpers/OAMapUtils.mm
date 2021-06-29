//
//  OAMapUtils.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAMapUtils.h"
#import "OAPOI.h"
#import "QuadRect.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define MIN_LATITUDE -85.0511
#define MAX_LATITUDE 85.0511
#define LATITUDE_TURN 180.0
#define MIN_LONGITUDE -180.0
#define MAX_LONGITUDE 180.0
#define LONGITUDE_TURN 360.0

@implementation OAMapUtils

+ (NSArray<OAPOI *> *) sortPOI:(NSArray<OAPOI *> *)array lat:(double)lat lon:(double)lon
{
    return [array sortedArrayUsingComparator:^NSComparisonResult(OAPOI *obj1, OAPOI *obj2)
            {
                const auto distance1 = OsmAnd::Utilities::distance(lon, lat, obj1.longitude, obj1.latitude);
                const auto distance2 = OsmAnd::Utilities::distance(lon, lat, obj2.longitude, obj2.latitude);
                return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
            }];
}

+ (double) scalarMultiplication:(double)xA yA:(double)yA xB:(double)xB yB:(double)yB xC:(double)xC yC:(double)yC
{
    // Scalar multiplication between (AB, AC)
    return (xB - xA) * (xC - xA) + (yB - yA) * (yC - yA);
}

+ (CLLocation *) getProjection:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation
{
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    double fromLat = fromLocation.coordinate.latitude;
    double fromLon = fromLocation.coordinate.longitude;
    double toLat = toLocation.coordinate.latitude;
    double toLon = toLocation.coordinate.longitude;

    // not very accurate computation on sphere but for distances < 1000m it is ok
    double mDist = (fromLat - toLat) * (fromLat - toLat) + (fromLon - toLon) * (fromLon - toLon);
    double projection = [self.class scalarMultiplication:fromLat yA:fromLon xB:toLat yB:toLon xC:lat yC:lon];
    double prlat;
    double prlon;
    if (projection < 0)
    {
        prlat = fromLat;
        prlon = fromLon;
    }
    else if (projection >= mDist)
    {
        prlat = toLat;
        prlon = toLon;
    }
    else
    {
        prlat = fromLat + (toLat - fromLat) * (projection / mDist);
        prlon = fromLon + (toLon - fromLon) * (projection / mDist);
    }
    return [[CLLocation alloc] initWithLatitude:prlat longitude:prlon];
}

+ (double) getOrthogonalDistance:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation
{
    return [[self.class getProjection:location fromLocation:fromLocation toLocation:toLocation] distanceFromLocation:location];
}

+ (BOOL) rightSide:(double)lat lon:(double)lon aLat:(double)aLat aLon:(double)aLon bLat:(double)bLat bLon:(double)bLon
{
    double ax = aLon - lon;
    double ay = aLat - lat;
    double bx = bLon - lon;
    double by = bLat - lat;
    double sa = ax * by - bx * ay;
    return sa < 0;
}

+ (CLLocationDirection) adjustBearing:(CLLocationDirection)bearing
{
    CLLocationDirection b = bearing;
    if (b < 0)
        b += 360;
    else if (b > 360)
        b -= 360;
    
    return b;
}

+ (CLLocation *) calculateMidPoint:(CLLocation *) s1 s2:(CLLocation *) s2
{
    double lat1 = s1.coordinate.latitude / 180 * M_PI;
    double lon1 = s1.coordinate.longitude / 180 * M_PI;
    double lat2 = s2.coordinate.latitude / 180 * M_PI;
    double lon2 = s2.coordinate.longitude  / 180 * M_PI;
    double Bx = cos(lat2) * cos(lon2 - lon1);
    double By = cos(lat2) * sin(lon2 - lon1);
    double latMid = atan2(sin(lat1) + sin(lat2),
            sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By));
    double lonMid = lon1 + atan2(By, cos(lat1) + Bx);
    return [[CLLocation alloc] initWithLatitude:[self checkLatitude:(latMid * 180 / M_PI)] longitude:[self checkLongitude:(lonMid * 180 / M_PI)]];
}

+ (double) checkLatitude:(double) latitude
{
    if (latitude >= MIN_LATITUDE && latitude <= MAX_LATITUDE) {
        return latitude;
    }
    while (latitude < -90 || latitude > 90) {
        if (latitude < 0) {
            latitude += LATITUDE_TURN;
        } else {
            latitude -= LATITUDE_TURN;
        }
    }
    if (latitude < MIN_LATITUDE) {
        return MIN_LATITUDE;
    } else if (latitude > MAX_LATITUDE) {
        return MAX_LATITUDE;
    }
    return latitude;
}

+ (double) checkLongitude:(double) longitude
{
    if (longitude >= MIN_LONGITUDE && longitude <= MAX_LONGITUDE) {
        return longitude;
    }
    while (longitude <= MIN_LONGITUDE || longitude > MAX_LONGITUDE) {
        if (longitude < 0) {
            longitude += LONGITUDE_TURN;
        } else {
            longitude -= LONGITUDE_TURN;
        }
    }
    return longitude;
}
    
/**
 * outx, outy are the coordinates out of the box
 * inx, iny are the coordinates from the box (NOT IMPORTANT in/out, just one should be in second out)
 * @return nil if there is no instersection or CGPoint
 */
+ (NSValue *) calculateIntersection:(CGFloat)inx iny:(CGFloat)iny outx:(CGFloat)outx outy:(CGFloat)outy leftX:(CGFloat)leftX rightX:(CGFloat)rightX bottomY:(CGFloat)bottomY topY:(CGFloat)topY
{
    CGFloat by = -1;
    CGFloat bx = -1;
    // firstly try to search if the line goes in
    if (outy < topY && iny >= topY)
    {
        CGFloat tx = outx + ((inx - outx) * (topY - outy)) / (iny - outy);
        if (leftX <= tx && tx <= rightX)
        {
            bx = tx;
            by = topY;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outy > bottomY && iny <= bottomY)
    {
        CGFloat tx = outx + ((inx - outx) * (outy - bottomY)) / (outy - iny);
        if (leftX <= tx && tx <= rightX)
        {
            bx = tx;
            by = bottomY;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outx < leftX && inx >= leftX)
    {
        CGFloat ty = outy + ((iny - outy) * (leftX - outx)) / (inx - outx);
        if (ty >= topY && ty <= bottomY)
        {
            by = ty;
            bx = leftX;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outx > rightX && inx <= rightX)
    {
        CGFloat ty = outy + ((iny - outy) * (outx - rightX)) / (outx - inx);
        if (ty >= topY && ty <= bottomY)
        {
            by = ty;
            bx = rightX;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }

    // try to search if point goes out
    if (outy > topY && iny <= topY)
    {
        CGFloat tx = outx + ((inx - outx) * (topY - outy)) / (iny - outy);
        if (leftX <= tx && tx <= rightX)
        {
            bx = tx;
            by = topY;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outy < bottomY && iny >= bottomY)
    {
        CGFloat tx = outx + ((inx - outx) * (outy - bottomY)) / (outy - iny);
        if (leftX <= tx && tx <= rightX)
        {
            bx = tx;
            by = bottomY;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outx > leftX && inx <= leftX)
    {
        CGFloat ty = outy + ((iny - outy) * (leftX - outx)) / (inx - outx);
        if (ty >= topY && ty <= bottomY)
        {
            by = ty;
            bx = leftX;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outx < rightX && inx >= rightX)
    {
        CGFloat ty = outy + ((iny - outy) * (outx - rightX)) / (outx - inx);
        if (ty >= topY && ty <= bottomY)
        {
            by = ty;
            bx = rightX;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outx == rightX || outx == leftX)
    {
        if (outy >= topY && outy <= bottomY)
        {
            bx = outx;
            by = outy;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    if (outy == topY || outy == bottomY)
    {
        if (leftX <= outx && outx <= rightX)
        {
            bx = outx;
            by = outy;
            return [NSValue valueWithCGPoint:CGPointMake(bx, by)];
        }
    }
    return nil;
}

+ (NSArray<NSValue *> *) calculateLineInRect:(CGRect)rect start:(CGPoint)start end:(CGPoint)end
{
    NSMutableArray<NSValue *> *coordinates = [NSMutableArray array];
    CGFloat x = end.x;
    CGFloat y = end.y;
    CGFloat px = start.x;
    CGFloat py = start.y;
    BOOL startInside = CGRectContainsPoint(rect, start);
    BOOL endInside = CGRectContainsPoint(rect, end);
    CGFloat leftX = CGRectGetMinX(rect);
    CGFloat rightX = CGRectGetMaxX(rect);
    CGFloat bottomY = CGRectGetMaxY(rect);
    CGFloat topY = CGRectGetMinY(rect);
    if (startInside)
    {
        if (!endInside)
        {
            NSValue *is = [self.class calculateIntersection:x iny:y outx:px outy:py leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
            if (!is)
            {
                // it is an error (!)
                is = [NSValue valueWithCGPoint:CGPointMake(px, py)];
            }
            [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
            [coordinates addObject:is];
        }
        else
        {
            [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
            [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
    }
    else
    {
        NSValue *is = [self.class calculateIntersection:x iny:y outx:px outy:py leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
        if (endInside)
        {
            // assert is != -1;
            [coordinates addObject:is];
            [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
        else if (is)
        {
            int bx = is.CGPointValue.x;
            int by = is.CGPointValue.y;
            [coordinates addObject:is];
            is = [self.class calculateIntersection:x iny:y outx:bx outy:by leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
            [coordinates addObject:is];
        }
    }
    return coordinates;
}

+ (QuadRect *)calculateLatLonBbox:(double)latitude longitude:(double)longitude radiusMeters:(int)radiusMeters
{
    int zoom = 16;
    float coeff = (float) (radiusMeters / OsmAnd::Utilities::getTileDistanceWidth(zoom));
    double tx = OsmAnd::Utilities::getTileNumberX(zoom, longitude);
    double ty = OsmAnd::Utilities::getTileNumberY(zoom, latitude);
    double topLeftX = MAX(0, tx - coeff);
    double topLeftY = MAX(0, ty - coeff);
    int max = (1 << zoom)  - 1;
    double bottomRightX = MIN(max, tx + coeff);
    double bottomRightY = MIN(max, ty + coeff);
    double pw = OsmAnd::Utilities::getPowZoom(31 - zoom);
    QuadRect *rect = [[QuadRect alloc] initWithLeft:topLeftX * pw top:topLeftY * pw right:bottomRightX * pw bottom:bottomRightY * pw];
    double left = OsmAnd::Utilities::get31LongitudeX((int) rect.left);
    double top = OsmAnd::Utilities::get31LatitudeY((int) rect.top);
    double right = OsmAnd::Utilities::get31LongitudeX((int) rect.right);
    double bottom = OsmAnd::Utilities::get31LatitudeY((int) rect.bottom);
    return [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
}

+ (double) getAngleBetween:(CGPoint)start end:(CGPoint)end
{
    double dx = start.x - end.x;
    double dy = start.y - end.y;
    return dx ? atan(dy/dx) : (dy < 0 ? M_PI_2 : -M_PI_2);
}

@end
