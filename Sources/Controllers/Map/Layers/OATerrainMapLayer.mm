//
//  OAHillshadeMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATerrainMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAIAPHelper.h"
#import "OAMapStyleSettings.h"
#import "OAAutoObserverProxy.h"

#include "OATerrainMapLayerProvider.h"
#include <OsmAndCore/Utilities.h>

@implementation OATerrainMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _terrainMapProvider;
    OAAutoObserverProxy* _terrainChangeObserver;
    OAAutoObserverProxy* _terrainAlphaChangeObserver;
}

- (NSString *) layerId
{
    return kTerrainMapLayerId;
}

- (void) initLayer
{
    _terrainChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onTerrainLayerChanged)
                                                          andObserve:self.app.data.terrainChangeObservable];
    _terrainAlphaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onTerrainLayerAlphaChanged)
                                                               andObserve:self.app.data.terrainAlphaChangeObservable];
}

- (void) deinitLayer
{
    if (_terrainChangeObserver)
    {
        [_terrainChangeObserver detach];
        _terrainChangeObserver = nil;
    }
    if (_terrainAlphaChangeObserver)
    {
        [_terrainAlphaChangeObserver detach];
        _terrainAlphaChangeObserver = nil;
    }
}

- (void) resetLayer
{
    _terrainMapProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    EOATerrainType type = self.app.data.terrainType;
    if (type != EOATerrainTypeDisabled && [[OAIAPHelper sharedInstance].srtm isActive])
    {
        BOOL isSlope = type == EOATerrainTypeSlope;
        OsmAnd::ZoomLevel minZoom = OsmAnd::ZoomLevel(isSlope ? self.app.data.slopeMinZoom : self.app.data.hillshadeMinZoom);
        OsmAnd::ZoomLevel maxZoom = OsmAnd::ZoomLevel(isSlope ? self.app.data.slopeMaxZoom : self.app.data.hillshadeMaxZoom);
        _terrainMapProvider = std::make_shared<OATerrainMapLayerProvider>(minZoom, maxZoom);
        [self.mapView setProvider:_terrainMapProvider forLayer:self.layerIndex];
        
        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor(isSlope ? self.app.data.slopeAlpha : self.app.data.hillshadeAlpha);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        return YES;
    }
    return NO;
}

- (void) onTerrainLayerChanged
{
    [self updateTerrainLayer];
}

- (void) updateTerrainLayer
{
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _terrainMapProvider.reset();
        }
    }];
}

- (void) onTerrainLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            EOATerrainType type = self.app.data.terrainType;
            BOOL isSlope = type == EOATerrainTypeSlope;
            config.setOpacityFactor(isSlope ? self.app.data.slopeAlpha : self.app.data.hillshadeAlpha);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

- (OsmAnd::ZoomLevel) getMinZoom
{
    return _terrainMapProvider != nullptr ? _terrainMapProvider->getMinZoom() : OsmAnd::ZoomLevel1;
}

- (OsmAnd::ZoomLevel) getMaxZoom
{
    return _terrainMapProvider != nullptr ? _terrainMapProvider->getMaxZoom() : OsmAnd::ZoomLevel11;
}

@end
