//
//  OAMapLayersConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

#define kFavoritesLayerId @"favorites"
#define kDestinationsLayerId @"destinations"
#define kMyPositionLayerId @"my_position"
#define kContextMenuLayerId @"context_menu"
#define kPoiLayerId @"poi_on_map"

#define kHillshadeMapLayerId @"hillshade_map"
#define kOverlayMapLayerId @"overlay_map"
#define kUnderlayMapLayerId @"underlay_map"
#define kGpxLayerId @"gpx_map"
#define kRouteLayerId @"route_map"

@interface OAMapLayersConfiguration : NSObject <NSCoding>

- (BOOL)isLayerVisible:(NSString*)layerId;
- (void)setLayer:(NSString*)layerId Visibility:(BOOL)isVisible;
- (BOOL)toogleLayerVisibility:(NSString*)layerId;

@property(readonly) OAObservable* changeObservable;

@end
