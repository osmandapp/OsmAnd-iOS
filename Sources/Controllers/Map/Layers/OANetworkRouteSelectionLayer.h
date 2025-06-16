//
//  OANetworkRouteSelectionLayer.h
//  OsmAnd
//
//  Created by Max Kojin on 16/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

@class OARouteKey;

@interface OANetworkRouteSelectionLayer : OASymbolMapLayer<OAContextMenuProvider>

- (void) onCancelNetworkGPX;

- (void) removeFromCacheBy:(OARouteKey *)routeKey;
- (void) clearCache;

@end
