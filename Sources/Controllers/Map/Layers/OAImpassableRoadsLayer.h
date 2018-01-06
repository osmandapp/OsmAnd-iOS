//
//  OAImpassableRoadsLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OAImpassableRoadsLayer : OASymbolMapLayer

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getImpassableMarkersCollection;

@end
