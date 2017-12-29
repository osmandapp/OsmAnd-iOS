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

@end
