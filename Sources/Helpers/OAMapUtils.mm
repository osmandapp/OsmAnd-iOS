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
    // not very accurate computation on sphere but for distances < 1000m it is ok
    double mDist = [fromLocation distanceFromLocation:toLocation];
    double projection = [self.class scalarMultiplication:fromLocation.coordinate.latitude yA:fromLocation.coordinate.longitude xB:toLocation.coordinate.latitude yB:toLocation.coordinate.longitude xC:location.coordinate.latitude yC:location.coordinate.longitude];
    double prlat;
    double prlon;
    if (projection < 0) {
        prlat = fromLocation.coordinate.latitude;
        prlon = fromLocation.coordinate.longitude;
    } else if (projection >= mDist) {
        prlat = toLocation.coordinate.latitude;
        prlon = toLocation.coordinate.longitude;
    } else {
        prlat = fromLocation.coordinate.latitude + (toLocation.coordinate.latitude - fromLocation.coordinate.latitude) * (projection / mDist);
        prlon = fromLocation.coordinate.longitude + (toLocation.coordinate.longitude - fromLocation.coordinate.longitude) * (projection / mDist);
    }
    return [[CLLocation alloc] initWithLatitude:prlat longitude:prlon];;
}

+ (double) getOrthogonalDistance:(CLLocation *)location fromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation
{
    return [[self.class getProjection:location fromLocation:fromLocation toLocation:toLocation] distanceFromLocation:location];
}


@end
