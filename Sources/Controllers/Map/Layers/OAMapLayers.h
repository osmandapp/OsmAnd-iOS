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
#import "OAMeasurementToolLayer.h"
#import "OARoutePointsLayer.h"
#import "OAImpassableRoadsLayer.h"
#import "OATransportStopsLayer.h"
#import "OAOsmEditsLayer.h"
#import "OAOsmBugsLayer.h"
#import "OAMapillaryLayer.h"
#import "OAPreviewRouteLineLayer.h"
#import "OADownloadedRegionsLayer.h"
#import "OARulerByTapControlLayer.h"
#import "OACoordinatesGridLayer.h"
#import "OATerrainMapLayer.h"
#import "OAOverlayMapLayer.h"
#import "OAUnderlayMapLayer.h"
#import "OAWeatherRasterLayer.h"
#import "OAWeatherContourLayer.h"

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
@property (nonatomic, readonly) OACoordinatesGridLayer *coordinatesGridLayer;
@property (nonatomic, readonly) OAOsmEditsLayer *osmEditsLayer;
@property (nonatomic, readonly) OAOsmBugsLayer *osmBugsLayer;
@property (nonatomic, readonly) OAMapillaryLayer *mapillaryLayer;
@property (nonatomic, readonly) OARulerByTapControlLayer *rulerByTapControlLayer;

@property (nonatomic) NSDate *weatherDate;
@property (nonatomic, readonly) OAWeatherRasterLayer *weatherLayerLow;
@property (nonatomic, readonly) OAWeatherRasterLayer *weatherLayerHigh;
@property (nonatomic, readonly) OAWeatherContourLayer *weatherContourLayer;

// Raster map layers
@property (nonatomic, readonly) OATerrainMapLayer *terrainMapLayer;
@property (nonatomic, readonly) OAOverlayMapLayer *overlayMapLayer;
@property (nonatomic, readonly) OAUnderlayMapLayer *underlayMapLayer;
@property (nonatomic, readonly) OAGPXLayer *gpxMapLayer;
@property (nonatomic, readonly) OAGPXRecLayer *gpxRecMapLayer;
@property (nonatomic, readonly) OARouteLayer *routeMapLayer;
@property (nonatomic, readonly) OAPreviewRouteLineLayer *routePreviewLayer;
@property (nonatomic, readonly) OAMeasurementToolLayer *routePlanningLayer;
@property (nonatomic, readonly) OADownloadedRegionsLayer *downloadedRegionsLayer;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController;

- (void) createLayers;
- (void) destroyLayers;
- (NSArray<OAMapLayer *> *) getLayers;

- (void) resetLayers;
- (void) updateLayers;

- (void) updateWeatherDate:(NSDate *)date;
- (void) updateWeatherLayers;

- (void) showLayer:(NSString *)layerId;
- (void) hideLayer:(NSString *)layerId;

- (void) onMapFrameAnimatorsUpdated;
- (void) onMapFrameRendered;
- (void) didReceiveMemoryWarning;

@end
