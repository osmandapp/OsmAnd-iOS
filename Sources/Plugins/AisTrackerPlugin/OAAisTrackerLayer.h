//
//  OAAisTrackerLayer.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"
#import "OAContextMenuProvider.h"
#import "OsmAndSharedWrapper.h"

@interface OAAisTrackerLayer : OAMapLayer<OAContextMenuProvider>

- (void)reloadAisObjects;
- (void)onAisObjectReceived:(OASAisObject *)object;
- (void)onAisObjectRemoved:(OASAisObject *)object;

@end
