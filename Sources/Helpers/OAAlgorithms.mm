//
//  OAAlgorithms.mm
//  OsmAnd
//
//  Created by Max Kojin on 23/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAAlgorithms.h"
#import "OAAlgorithms+cpp.h"

@implementation OAAlgorithms

+ (BOOL)isFirstPolygonInsideSecond:(QVector< OsmAnd::LatLon >)firstPolygon secondPolygon:(QVector<OsmAnd::LatLon>)secondPolygon
{
    for (OsmAnd::LatLon pointI : firstPolygon)
    {
        if (![self.class isPointInsidePolygon:pointI polygon:secondPolygon])
        {
            // if at least one point is not inside the boundary, return false
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isPointInsidePolygon:(OsmAnd::LatLon)point polygon:(QVector<OsmAnd::LatLon>)polygon
{
    double px = point.longitude;
    double py = point.latitude;
    BOOL oddNodes = NO;

    for (int i = 0, j = polygon.size() - 1; i < polygon.size(); j = i++)
    {
        double x1 = polygon.at(i).longitude;
        double y1 = polygon.at(i).latitude;
        double x2 = polygon.at(j).longitude;
        double y2 = polygon.at(j).latitude;
        if (((y1 < py && y2 >= py)
                || (y2 < py && y1 >= py))
                && (x1 <= px || x2 <= px))
        {
            if (x1 + (py - y1) / (y2 - y1) * (x2 - x1) < px)
                oddNodes = !oddNodes;
        }
    }
    return oddNodes;
}

@end
