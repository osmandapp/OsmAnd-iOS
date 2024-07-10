//
//  OAOsmEditsLayer.h
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@class OAMapViewController;

@interface OAOsmEditsLayer : OASymbolMapLayer<OAContextMenuProvider, OAMoveObjectProvider>

-(id) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder;

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getOsmEditsCollection;

@end
