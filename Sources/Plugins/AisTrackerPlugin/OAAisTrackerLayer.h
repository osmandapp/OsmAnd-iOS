//
//  OAAisTrackerLayer.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"
#import "OAContextMenuProvider.h"

@class AisObject;

@interface OAAisTrackerLayer : OAMapLayer<OAContextMenuProvider>

- (void)reloadAisObjects;
- (void)onAisObjectReceived:(AisObject *)object;
- (void)onAisObjectRemoved:(AisObject *)object;

@end
