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

+ (BOOL)isFirstPolygonInsideSecond:(QVector< OsmAnd::PointI >)firstPolygon secondPolygon:(QVector<OsmAnd::PointI>)secondPolygon;
+ (BOOL)isPointInsidePolygon:(OsmAnd::PointI)point polygon:(QVector<OsmAnd::PointI>)polygon;

@end
