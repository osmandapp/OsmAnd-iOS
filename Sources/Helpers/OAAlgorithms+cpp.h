//
//  OAAlgorithms+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 23/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAAlgorithms.h"

#include <OsmAndCore/Utilities.h>

@interface OAAlgorithms(cpp)

+ (BOOL)isFirstPolygonInsideSecond:(QVector< OsmAnd::LatLon >)firstPolygon secondPolygon:(QVector<OsmAnd::LatLon>)secondPolygon;
+ (BOOL)isPointInsidePolygon:(OsmAnd::LatLon)point polygon:(QVector<OsmAnd::LatLon>)polygon;

@end
