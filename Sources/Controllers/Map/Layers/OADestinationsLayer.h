//
//  OADestinationsLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OADestinationsLayer : OASymbolMapLayer<OAContextMenuProvider>

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getDestinationsMarkersCollection;

- (void)addDestinationPin:(NSString *)markerResourceName color:(UIColor *)color latitude:(double)latitude longitude:(double)longitude;
- (void)removeDestinationPin:(double)latitude longitude:(double)longitude;

@end
