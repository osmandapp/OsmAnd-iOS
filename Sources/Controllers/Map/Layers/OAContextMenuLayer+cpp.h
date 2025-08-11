//
//  OAContextMenuLayer+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuLayer.h"

#include <OsmAndCore/Map/MapMarker.h>

@interface OAContextMenuLayer(cpp)

- (std::shared_ptr<OsmAnd::MapMarker>)getContextPinMarker;

- (void) highlightPolygon:(QVector<OsmAnd::PointI>)points;

@end
