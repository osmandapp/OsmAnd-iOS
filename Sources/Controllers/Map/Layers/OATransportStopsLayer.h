//
//  OATransportStopsLayer.h
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#define kDefaultRouteColor 0xFFFF0000

@class OATransportStopRoute;

@interface OATransportStopsLayer : OASymbolMapLayer<OAContextMenuProvider>

- (void) showStopsOnMap:(OATransportStopRoute *)stopRoute;
- (void) hideRoute;

@end
