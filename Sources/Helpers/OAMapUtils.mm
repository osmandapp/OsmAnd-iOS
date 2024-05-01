//
//  OAMapUtils.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAMapUtils.h"
#import "OANativeUtilities.h"
#import "OAPOI.h"
#import "QuadRect.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAHeightsResolverTask.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

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
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(prlat, prlon) altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
}

+ (double) getProjectionCoeff:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation
{
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    double fromLat = fromLocation.coordinate.latitude;
    double fromLon = fromLocation.coordinate.longitude;
    double toLat = toLocation.coordinate.latitude;
    double toLon = toLocation.coordinate.longitude;
    
    double mDist = (fromLat - toLat) * (fromLat - toLat) + (fromLon - toLon) * (fromLon - toLon);
    double projection = [self.class scalarMultiplication:fromLat yA:fromLon xB:toLat yB:toLon xC:lat yC:lon];
    if (projection < 0)
        return 0;
    else 
        return projection >= mDist ? 1 : projection / mDist;
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

+ (CLLocationDirection) normalizeDegrees360:(CLLocationDirection)bearing
{
    CLLocationDirection degrees = bearing;
    while (degrees < 0.0) {
        degrees += 360.0;
    }
    while (degrees >= 360.0) {
        degrees -= 360.0;
    }
    return degrees;
}

+ (double) unifyRotationDiff:(double)rotate targetRotate:(double)targetRotate
{
    double d = targetRotate - rotate;
    while (d >= 180.0) {
        d -= 360.0;
    }
    while (d < -180.0) {
        d += 360.0;
    }
    return d;
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

+ (double) getAngleBetween:(CGPoint)start end:(CGPoint)end
{
    double dx = start.x - end.x;
    double dy = start.y - end.y;
    return dx ? atan(dy/dx) : (dy < 0 ? M_PI_2 : -M_PI_2);
}

+ (double) getDistance:(CLLocationCoordinate2D)first second:(CLLocationCoordinate2D)second
{
    return OsmAnd::Utilities::distance(first.longitude, first.latitude, second.longitude, second.latitude);
}

+ (double) getDistance:(double)lat1 lon1:(double)lon1 lat2:(double)lat2 lon2:(double)lon2
{
    return OsmAnd::Utilities::distance(lon1, lat1, lon2, lat2);
}

+ (BOOL)areLocationEqual:(CLLocation *)l1 l2:(CLLocation *)l2
{
    return (l1 == nil && l2 == nil) || (l2 != nil && [self areLocationEqual:l1 lat:l2.coordinate.latitude lon:l2.coordinate.longitude]);
}

+ (BOOL)areLocationEqual:(CLLocation *)l lat:(CGFloat)lat lon:(CGFloat)lon
{
    return l != nil && [self areLatLonEqual:l.coordinate.latitude lon1:l.coordinate.longitude lat2:lat lon2:lon];
}

+ (BOOL)areLatLonEqual:(CLLocationCoordinate2D)l1 coordinate2:(CLLocationCoordinate2D)l2 precision:(double)precision
{
    if (!CLLocationCoordinate2DIsValid(l1) || !CLLocationCoordinate2DIsValid(l2))
        return NO;
    
    double lat1 = l1.latitude;
    double lon1 = l1.longitude;
    double lat2 = l2.latitude;
    double lon2 = l2.longitude;
    
    BOOL latEqual = (isnan(lat1) && isnan(lat2)) || fabs(lat1 - lat2) < precision;
    BOOL lonEqual = (isnan(lon1) && isnan(lon2)) || fabs(lon1 - lon2) < precision;
    
    return latEqual && lonEqual;
}

+ (BOOL)areLatLonEqual:(CLLocationCoordinate2D)l1 l2:(CLLocationCoordinate2D)l2
{
    return (!CLLocationCoordinate2DIsValid(l1) && !CLLocationCoordinate2DIsValid(l2))
        || (CLLocationCoordinate2DIsValid(l2) && [self areLatLonEqual:l1 lat:l2.latitude lon:l1.longitude]);
}

+ (BOOL)areLatLonEqual:(CLLocationCoordinate2D)l lat:(CGFloat)lat lon:(CGFloat)lon
{
    return CLLocationCoordinate2DIsValid(l) && [self areLatLonEqual:l.latitude lon1:l.longitude lat2:lat lon2:lon];
}

+ (BOOL)areLatLonEqual:(CGFloat)lat1 lon1:(CGFloat)lon1 lat2:(CGFloat)lat2 lon2:(CGFloat)lon2
{
    BOOL latEqual = (isnan(lat1) && isnan(lat2)) || (abs(lat1 - lat2) < 0.00001);
    BOOL lonEqual = (isnan(lon1) && isnan(lon2)) || (abs(lon1 - lon2) < 0.00001);
    return latEqual && lonEqual;
}

+ (void)getAltitudeForLatLon:(CLLocationCoordinate2D)latLon callback:(void (^ _Nonnull)(CGFloat height))callback
{
    if (CLLocationCoordinate2DIsValid(latLon))
    {
        CGFloat altitude = [OAMapUtils getAltitudeForLatLon:latLon];
        if (altitude != kMinAltitudeValue)
        {
            callback(altitude);
        }
        else
        {
            NSArray<CLLocation *> *points = @[[[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude]];
            HeightsResolverTaskCallback heightsCallback = ^(NSArray<NSNumber *> *heights) {
                callback(heights.count > 0 ? heights.firstObject.floatValue : kMinAltitudeValue);
            };
            OAHeightsResolverTask *task = [[OAHeightsResolverTask alloc] initWithPoints:points callback:heightsCallback];
            [task execute];
        }
    }
    else
    {
        callback(kMinAltitudeValue);
    }
}

+ (CGFloat)getAltitudeForLatLon:(CLLocationCoordinate2D)latLon
{
    return CLLocationCoordinate2DIsValid(latLon) ? [self getAltitudeForLatLon:latLon.latitude lon:latLon.longitude] : kMinAltitudeValue;
}

+ (CGFloat)getAltitudeForLatLon:(double)lat lon:(double)lon
{
    OsmAnd::PointI elevatedPoint = [OANativeUtilities getPoint31FromLatLon:lat lon:lon];
    return [self getAltitudeForElevatedPoint:elevatedPoint];
}

+ (CGFloat)getAltitudeForElevatedPoint:(OsmAnd::PointI)elevatedPoint
{
    CGFloat altitude = kMinAltitudeValue;
    if (elevatedPoint != OsmAnd::PointI())
    {
        OAMapRendererView *mapRenderer = [OARootViewController instance].mapPanel.mapViewController.mapView;
        altitude = [mapRenderer getLocationHeightInMeters:elevatedPoint];
    }
    return altitude;
}

@end
