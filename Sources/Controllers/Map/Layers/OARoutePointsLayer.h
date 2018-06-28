//
//  OARoutePointsLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OARoutePointsLayer : OASymbolMapLayer<OAContextMenuProvider>

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getRouteMarkersCollection;

@end
