//
//  OATransportStopsLayer.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

#define kDefaultRouteColor 0xFFFF0000

@interface OATransportStopsLayer : OASymbolMapLayer<OAContextMenuProvider>

@property (nonatomic) std::shared_ptr<OsmAnd::VectorLinesCollection> linesCollection;
@property (nonatomic) std::shared_ptr<OsmAnd::MapMarkersCollection> markersCollection;

@end
