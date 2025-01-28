//
//  OAMapUtils+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 28/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapUtils.h"

#include <OsmAndCore/Utilities.h>

@interface OAMapUtils(cpp)

+ (BOOL)isFirstPolygonInsideSecond:(QVector< OsmAnd::LatLon >)firstPolygon secondPolygon:(QVector<OsmAnd::LatLon>)secondPolygon;
+ (BOOL)isPointInsidePolygon:(OsmAnd::LatLon)point polygon:(QVector<OsmAnd::LatLon>)polygon;

@end
