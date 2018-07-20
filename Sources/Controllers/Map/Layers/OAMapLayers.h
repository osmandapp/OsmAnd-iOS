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
#import "OAPOILayer.h"
#import "OAGPXLayer.h"
#import "OAGPXRecLayer.h"
#import "OARouteLayer.h"
#import "OARoutePointsLayer.h"
#import "OAImpassableRoadsLayer.h"
#import "OATransportStopsLayer.h"

#import "OAHillshadeMapLayer.h"
#import "OAOverlayMapLayer.h"
#import "OAUnderlayMapLayer.h"

@class OAMapViewController;

@interface OAMapLayers : NSObject

// Symbol map layers
@property (nonatomic, readonly) OAFavoritesLayer *favoritesLayer;
@property (nonatomic, readonly) OADestinationsLayer *destinationsLayer;
@property (nonatomic, readonly) OAMyPositionLayer *myPositionLayer;
@property (nonatomic, readonly) OAContextMenuLayer *contextMenuLayer;
@property (nonatomic, readonly) OAPOILayer *poiLayer;
@property (nonatomic, readonly) OARoutePointsLayer *routePointsLayer;
@property (nonatomic, readonly) OAImpassableRoadsLayer *impassableRoadsLayer;
@property (nonatomic, readonly) OATransportStopsLayer *transportStopsLayer;

// Raster map layers
@property (nonatomic, readonly) OAHillshadeMapLayer *hillshadeMapLayer;
@property (nonatomic, readonly) OAOverlayMapLayer *overlayMapLayer;
@property (nonatomic, readonly) OAUnderlayMapLayer *underlayMapLayer;
@property (nonatomic, readonly) OAGPXLayer *gpxMapLayer;
@property (nonatomic, readonly) OAGPXRecLayer *gpxRecMapLayer;
@property (nonatomic, readonly) OARouteLayer *routeMapLayer;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController;

- (void) createLayers;
- (void) destroyLayers;
- (NSArray<OAMapLayer *> *) getLayers;

- (void) resetLayers;
- (void) updateLayers;

- (void) showLayer:(NSString *)layerId;
- (void) hideLayer:(NSString *)layerId;

- (void) onMapFrameRendered;

@end
