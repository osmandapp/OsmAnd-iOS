//
//  OAMapLayers.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAMapLayer.h"
#import "OAFavoritesLayer.h"
#import "OADestinationsLayer.h"
#import "OAMyPositionLayer.h"
#import "OAContextMenuLayer.h"

@class OAMapViewController;

@interface OAMapLayers : NSObject

@property (nonatomic, readonly) OAFavoritesLayer *favoritesLayer;
@property (nonatomic, readonly) OADestinationsLayer *destinationsLayer;
@property (nonatomic, readonly) OAMyPositionLayer *myPositionLayer;
@property (nonatomic, readonly) OAContextMenuLayer *contextMenuLayer;

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController;
- (void) createLayers;
- (void) destroyLayers;

- (void) showLayer:(NSString *)layerId;
- (void) hideLayer:(NSString *)layerId;

- (void) onFrameRendered;

@end
