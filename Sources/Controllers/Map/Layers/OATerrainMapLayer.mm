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
#import "OASRTMPlugin.h"
#import "OAMapStyleSettings.h"
#import "OAAutoObserverProxy.h"
#import "OAMapRendererEnvironment.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAPluginsHelper.h"

#include "OATerrainMapLayerProvider.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/SlopeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HillshadeRasterMapLayerProvider.h>

@implementation OATerrainMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _terrainMapProvider;
    
    std::shared_ptr<const OsmAnd::IGeoTiffCollection> _heightsCollection;
    std::shared_ptr<OsmAnd::SlopeRasterMapLayerProvider> _slopeLayerProvider;
    std::shared_ptr<OsmAnd::HillshadeRasterMapLayerProvider> _hillshadeLayerProvider;

    OAAutoObserverProxy *_terrainChangeObserver;
    OAAutoObserverProxy *_terrainAlphaChangeObserver;
    OAAutoObserverProxy *_verticalExaggerationScaleChangeObservable;
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
    
    _verticalExaggerationScaleChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                           withHandler:@selector(onVerticalExaggerationScaleChanged)
                                                                            andObserve:self.app.data.verticalExaggerationScaleChangeObservable];
    
    
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
    if (_verticalExaggerationScaleChangeObservable)
    {
        [_verticalExaggerationScaleChangeObservable detach];
        _verticalExaggerationScaleChangeObservable = nil;
    }
}

- (void) resetLayer
{
    _terrainMapProvider.reset();
    _slopeLayerProvider.reset();
    _hillshadeLayerProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    [super updateLayer];

    EOATerrainType type = self.app.data.terrainType;
    if (type != EOATerrainTypeDisabled && [[OAPluginsHelper getPlugin:OASRTMPlugin.class] isEnabled])
    {
        if (type == EOATerrainTypeSlope)
            [self setupSlopeLayerProvider];
        else if (type == EOATerrainTypeHillshade)
            [self setupHillshadeLayerProvider];
        else
            [self setupTerrainMapProvider];

        OsmAnd::MapLayerConfiguration config;
        double layerAlpha = self.app.data.hillshadeAlpha;
        if (type == EOATerrainTypeSlope)
            layerAlpha = self.app.data.slopeAlpha;
        else if (type == EOATerrainTypeHillshade)
            layerAlpha = self.app.data.hillshadeAlpha;

        config.setOpacityFactor(layerAlpha);
        
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        [self.mapView setElevationScaleFactor:self.app.data.verticalExaggerationScale];
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
            _slopeLayerProvider.reset();
            _hillshadeLayerProvider.reset();
        }
        [self.mapViewController recreateHeightmapProvider];
        [self.mapViewController updateElevationConfiguration];
    }];
}

- (void) onTerrainLayerAlphaChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            EOATerrainType type = self.app.data.terrainType;
            double layerAlpha = self.app.data.hillshadeAlpha;
            if (type == EOATerrainTypeSlope)
                layerAlpha = self.app.data.slopeAlpha;
            else if (type == EOATerrainTypeHillshade)
                layerAlpha = self.app.data.hillshadeAlpha;
            config.setOpacityFactor(layerAlpha);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
}

- (void)onVerticalExaggerationScaleChanged
{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.mapViewController runWithRenderSync:^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf)
                [strongSelf.mapView setElevationScaleFactor:strongSelf.app.data.verticalExaggerationScale];
        }];
    });
}

- (OsmAnd::ZoomLevel) getMinZoom
{
    EOATerrainType type = self.app.data.terrainType;
    if (type == EOATerrainTypeSlope)
        return OsmAnd::ZoomLevel(self.app.data.slopeMinZoom);
    else if (type == EOATerrainTypeHillshade)
        return OsmAnd::ZoomLevel(self.app.data.hillshadeMinZoom);
    else
        return OsmAnd::ZoomLevel1;
}

- (OsmAnd::ZoomLevel) getMaxZoom
{
    EOATerrainType type = self.app.data.terrainType;
    if (type == EOATerrainTypeSlope)
        return OsmAnd::ZoomLevel(self.app.data.slopeMaxZoom);
    else if (type == EOATerrainTypeHillshade)
        return OsmAnd::ZoomLevel(self.app.data.hillshadeMaxZoom);
    else
        return OsmAnd::ZoomLevel11;
}

- (void) setupTerrainMapProvider
{
    _terrainMapProvider = std::make_shared<OATerrainMapLayerProvider>([self getMinZoom], [self getMaxZoom]);

    [self.mapView setProvider:_terrainMapProvider forLayer:self.layerIndex];
    _slopeLayerProvider.reset();
    _hillshadeLayerProvider.reset();
}

- (void) setupSlopeLayerProvider
{
    auto slopeColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:@"slopes_main" ofType:@"txt"]);
    _slopeLayerProvider = std::make_shared<OsmAnd::SlopeRasterMapLayerProvider>(self.mapViewController.mapRendererEnv.geoTiffCollection, slopeColorFilename);
    _slopeLayerProvider->setMinVisibleZoom([self getMinZoom]);
    _slopeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);

    [self.mapView setProvider:_slopeLayerProvider forLayer:self.layerIndex];
    _hillshadeLayerProvider.reset();
    _terrainMapProvider.reset();
}

- (void) setupHillshadeLayerProvider
{
    auto hillshadeColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:@"hillshade_main" ofType:@"txt"]);
    auto slopeSecondaryColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:@"color_slope" ofType:@"txt"]);
    _hillshadeLayerProvider = std::make_shared<OsmAnd::HillshadeRasterMapLayerProvider>(self.mapViewController.mapRendererEnv.geoTiffCollection, hillshadeColorFilename, slopeSecondaryColorFilename);
    _hillshadeLayerProvider->setMinVisibleZoom([self getMinZoom]);
    _hillshadeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);

    [self.mapView setProvider:_hillshadeLayerProvider forLayer:self.layerIndex];
    _slopeLayerProvider.reset();
    _terrainMapProvider.reset();
}

@end
