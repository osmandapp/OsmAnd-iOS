//
//  OAContextMenuLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/MapMarker.h>


@interface OAContextMenuLayer : OASymbolMapLayer

- (std::shared_ptr<OsmAnd::MapMarker>) getContextPinMarker;

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated;
- (void) hideContextPinMarker;

- (void) showContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation;

@end
