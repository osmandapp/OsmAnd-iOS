//
//  OAFavoritesLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OAFavoritesLayer : OASymbolMapLayer

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getFavoritesMarkersCollection;

@end
