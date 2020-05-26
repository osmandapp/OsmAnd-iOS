//
//  OAMapUtils.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAMapUtils.h"
#import "OAPOI.h"

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

@end
