//
//  OAMapLayersConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFavoritesLayerId @"favorites"
#define kDestinationsLayerId @"destinations"
#define kMyPositionLayerId @"my_position"
#define kContextMenuLayerId @"context_menu"
#define kPoiLayerId @"poi_on_map"
#define kOsmEditsLayerId @"osm_edits"
#define kOsmBugsLayerId @"osm_bugs"
#define kMapillaryVectorLayerId @"mapillary_vector"

#define kTerrainMapLayerId @"terrain_map"
#define kOverlayMapLayerId @"overlay_map"
#define kUnderlayMapLayerId @"underlay_map"
#define kGpxLayerId @"gpx_map"
#define kGpxRecLayerId @"gpx_rec_map"
#define kRouteLayerId @"route_map"
#define kRoutePointsLayerId @"route_map_points"
#define kImpassableRoadsLayerId @"impassable_map_roads"
#define kTransportLayerId @"transport_map"
#define kRoutePlanningLayerId @"route_planning_map"
<<<<<<< HEAD
#define kDownloadedRegionsLayerId @"downloaded_regions"
=======
#define kRulerByTapControlLayerId @"ruler_by_tap"
>>>>>>> ad59fa714a1330de273b65c0ffb7e16da68c6b4c

@interface OAMapLayersConfiguration : NSObject

- (instancetype) initWithHiddenLayers:(NSMutableSet *)hiddenLayers;

- (BOOL)isLayerVisible:(NSString*)layerId;
- (void)setLayer:(NSString*)layerId Visibility:(BOOL)isVisible;
- (BOOL)toogleLayerVisibility:(NSString*)layerId;
- (void)resetConfigutation;

@property (nonatomic, readonly) NSMutableSet* hiddenLayers;

@end
