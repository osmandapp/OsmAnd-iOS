//
//  OAMapLayers.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayers.h"

#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAPlugin.h"

@implementation OAMapLayers
{
    OAMapViewController *_mapViewController;
    OAMapRendererView *_mapView;
    
    NSMapTable<NSString *, OAMapLayer *> *_layers;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController
{
    self = [super init];
    if (self)
    {
        _mapViewController = mapViewController;
        _mapView = mapViewController.mapView;
        _layers = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void) createLayers
{
    _favoritesLayer = [[OAFavoritesLayer alloc] initWithMapViewController:_mapViewController baseOrder:-160000];
    [self addLayer:_favoritesLayer];

    _myPositionLayer = [[OAMyPositionLayer alloc] initWithMapViewController:_mapViewController baseOrder:-206000];
    [self addLayer:_myPositionLayer];

    _destinationsLayer = [[OADestinationsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-207000];
    [self addLayer:_destinationsLayer];

    _contextMenuLayer = [[OAContextMenuLayer alloc] initWithMapViewController:_mapViewController baseOrder:-210000];
    [self addLayer:_contextMenuLayer];

    _poiLayer = [[OAPOILayer alloc] initWithMapViewController:_mapViewController baseOrder:-180000];
    [self addLayer:_poiLayer];

    _terrainMapLayer = [[OATerrainMapLayer alloc] initWithMapViewController:_mapViewController layerIndex:4];
    [self addLayer:_terrainMapLayer];
    
    _overlayMapLayer = [[OAOverlayMapLayer alloc] initWithMapViewController:_mapViewController layerIndex:5];
    [self addLayer:_overlayMapLayer];

    _underlayMapLayer = [[OAUnderlayMapLayer alloc] initWithMapViewController:_mapViewController layerIndex:-5];
    [self addLayer:_underlayMapLayer];

    _gpxMapLayer = [[OAGPXLayer alloc] initWithMapViewController:_mapViewController baseOrder:-100000];
    [self addLayer:_gpxMapLayer];

    _gpxRecMapLayer = [[OAGPXRecLayer alloc] initWithMapViewController:_mapViewController baseOrder:-110000];
    [self addLayer:_gpxRecMapLayer];

    _routeMapLayer = [[OARouteLayer alloc] initWithMapViewController:_mapViewController baseOrder:-150000];
    [self addLayer:_routeMapLayer];
    
    _routePlanningLayer = [[OAMeasurementToolLayer alloc] initWithMapViewController:_mapViewController baseOrder:-160000];
    [self addLayer:_routePlanningLayer];

    _routePointsLayer = [[OARoutePointsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-209000];
    [self addLayer:_routePointsLayer];

    _impassableRoadsLayer = [[OAImpassableRoadsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-206000];
    [self addLayer:_impassableRoadsLayer];
    
    _transportStopsLayer = [[OATransportStopsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-120000];
    [self addLayer:_transportStopsLayer];
    
    _osmEditsLayer = [[OAOsmEditsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-120000];
    [self addLayer:_osmEditsLayer];
    
    _osmBugsLayer = [[OAOsmBugsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-120000];
    [self addLayer:_osmBugsLayer];
    
    _mapillaryLayer = [[OAMapillaryLayer alloc] initWithMapViewController:_mapViewController layerIndex:10];
    [self addLayer:_mapillaryLayer];
    
    _rulerByTapControlLayer = [[OARulerByTapControlLayer alloc] initWithMapViewController:_mapViewController baseOrder:-170000];
    [self addLayer:_rulerByTapControlLayer];

    _downloadedRegionsLayer = [[OADownloadedRegionsLayer alloc] initWithMapViewController:_mapViewController baseOrder:-10000];
    [self addLayer:_downloadedRegionsLayer];

    [OAPlugin createLayers];
}

- (void) destroyLayers
{
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [layer deinitLayer];

    [_layers removeAllObjects];
}

- (NSArray<OAMapLayer *> *) getLayers
{
    NSMutableArray<OAMapLayer *> *res = [NSMutableArray array];
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [res addObject:layer];
    
    return [NSArray arrayWithArray:res];
}

- (void) resetLayers
{
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [layer resetLayer];
}

- (void) updateLayers
{
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [layer updateLayer];
    
    [OAPlugin refreshLayers];
}

- (void) addLayer:(OAMapLayer *)layer
{
    [layer initLayer];
    [_layers setObject:layer forKey:layer.layerId];
}

- (void) showLayer:(NSString *)layerId
{
    OAMapLayer *layer = [_layers objectForKey:layerId];
    if (layer)
        [layer show];
}

- (void) hideLayer:(NSString *)layerId
{
    OAMapLayer *layer = [_layers objectForKey:layerId];
    if (layer)
        [layer hide];
}

- (void) onMapFrameRendered
{
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [layer onMapFrameRendered];
}

- (void) didReceiveMemoryWarning
{
    for (OAMapLayer *layer in _layers.objectEnumerator)
        [layer didReceiveMemoryWarning];
}

@end
