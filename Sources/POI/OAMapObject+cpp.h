//
//  OAMapObject+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 23/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"

#include <OsmAndCore/Utilities.h>

@interface OAMapObject(cpp)

- (QVector< OsmAnd::LatLon >) getPolygon;

@end
