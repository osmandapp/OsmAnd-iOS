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
#import "OAMapRendererEnvironment.h"
#import "OASRTMPlugin.h"
#import "OAAutoObserverProxy.h"
#import "OAPluginsHelper.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"

#include "OATerrainMapLayerProvider.h"
#include <OsmAndCore/GeoTiffCollection.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/SlopeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HillshadeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HeightRasterMapLayerProvider.h>

@interface OATerrainMapLayer () <OASPaletteRepositoryListener>

@end

@implementation OATerrainMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _layerProvider;

    OAAutoObserverProxy *_verticalExaggerationScaleChangeObservable;
    OAAutoObserverProxy *_applicationModeChangedObserver;

    TerrainMode *_terrainMode;
    OASRTMPlugin *_plugin;
}

- (NSString *) layerId
{
    return kTerrainMapLayerId;
}

- (void) initLayer
{
    _plugin = ((OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class]);
    _terrainMode = [_plugin getTerrainMode];

    _verticalExaggerationScaleChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                           withHandler:@selector(onVerticalExaggerationScaleChanged)
                                                                            andObserve:self.app.data.verticalExaggerationScaleChangeObservable];

    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:OsmAndApp.instance.applicationModeChangedObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onProfileSettingSet:)
                                                 name:kNotificationSetProfileSetting
                                               object:nil];

    [self.app.paletteRepository addListenerListener:self];
}

- (void) deinitLayer
{
    [self.app.paletteRepository removeListenerListener:self];
    if (_verticalExaggerationScaleChangeObservable)
    {
        [_verticalExaggerationScaleChangeObservable detach];
        _verticalExaggerationScaleChangeObservable = nil;
    }
    if (_applicationModeChangedObserver)
    {
        [_applicationModeChangedObserver detach];
        _applicationModeChangedObserver = nil;
    }
}

- (void) resetLayer
{
    _layerProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL)updateLayer
{
    if (![super updateLayer])
        return NO;

    if ([_plugin isTerrainLayerEnabled] && [_plugin isEnabled])
    {
        _terrainMode = [_plugin getTerrainMode];
        _layerProvider = [self createGeoTiffLayerProvider:_terrainMode];
        if (_layerProvider)
        {
            [self.mapView setProvider:_layerProvider forLayer:self.layerIndex];
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor([_terrainMode getTransparency] * 0.01);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }
        else
        {
            [self.mapView resetProviderFor:self.layerIndex];
        }
        [self.mapView setElevationScaleFactor:[_plugin isHeightmapEnabled] ? self.app.data.verticalExaggerationScale : kExaggerationDefScale];
        return YES;
    }
    return NO;
}

- (void)onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTerrainLayer];
        if ([_plugin isTerrainLayerEnabled])
            [self onVerticalExaggerationScaleChanged];
    });
}

- (void)updateTerrainLayer
{
    [self.mapViewController runWithRenderSync:^{
        if (![self updateLayer])
        {
            [self.mapView resetProviderFor:self.layerIndex];
            _layerProvider.reset();
        }
        [self.mapViewController recreateHeightmapProvider];
        [self.mapViewController updateElevationConfiguration];
    }];
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.object == _plugin.terrainEnabledPref || notification.object == _plugin.terrainModeTypePref)
        {
            [self updateTerrainLayer];
            if (_plugin.terrainModeTypePref)
                [self onVerticalExaggerationScaleChanged];
        }
        else if ([notification.object isKindOfClass:OACommonInteger.class])
        {
            if ([_terrainMode isTransparencySetting:notification.object])
            {
                [self.mapViewController runWithRenderSync:^{
                    if ([_terrainMode isTerrainShadows])
                    {
                        [self.mapViewController updateElevationConfiguration];
                        [self onVerticalExaggerationScaleChanged];
                    }
                    else
                    {
                        OsmAnd::MapLayerConfiguration config;
                        config.setOpacityFactor([_terrainMode getTransparency] * 0.01);
                        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
                    }
                }];
            }
            else if ([_terrainMode isZoomSetting:notification.object])
            {
                [self updateTerrainLayer];
            }
        }
    });
}

- (void)onPaletteChangedEvent:(OASPaletteChangeEvent *)event
{
    NSString *currentPaletteFile = [_terrainMode mainFile];
    BOOL isCurrentPaletteEvent = currentPaletteFile.length > 0 && [[GradientPaletteHelper shared] isPaletteChangeEvent:event fileName:currentPaletteFile];
    NSString *updatedTerrainPaletteFile = [[GradientPaletteHelper shared] updatedTerrainPaletteFileName:event];
    if (!isCurrentPaletteEvent && updatedTerrainPaletteFile.length == 0)
        return;
    
    if (isCurrentPaletteEvent && [event isKindOfClass:OASPaletteChangeEventRemoved.class])
    {
        TerrainMode *defaultTerrainMode = [TerrainMode getDefaultMode:_terrainMode.type];
        if (defaultTerrainMode)
        {
            _terrainMode = defaultTerrainMode;
            [_plugin setTerrainMode:defaultTerrainMode];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (updatedTerrainPaletteFile.length > 0)
        {
            auto geoTiffCollection = std::dynamic_pointer_cast<OsmAnd::GeoTiffCollection>(self.mapViewController.mapRendererEnv.geoTiffCollection);
            if (geoTiffCollection)
            {
                auto palettePath = QString::fromNSString([self.app.colorsPalettePath stringByAppendingPathComponent:updatedTerrainPaletteFile]);
                geoTiffCollection->removeFileTilesFromCache(OsmAnd::GeoTiffCollection::RasterType::Slope, palettePath);
                geoTiffCollection->removeFileTilesFromCache(OsmAnd::GeoTiffCollection::RasterType::Height, palettePath);
                geoTiffCollection->removeFileTilesFromCache(OsmAnd::GeoTiffCollection::RasterType::Hillshade, palettePath);
            }
        }

        if (isCurrentPaletteEvent)
            [self updateTerrainLayer];
    });
}

- (void)onVerticalExaggerationScaleChanged
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView setElevationScaleFactor:self.app.data.verticalExaggerationScale];
    }];
}

- (OsmAnd::ZoomLevel)minZoom
{
    return OsmAnd::ZoomLevel([_plugin getTerrainMinZoom]);
}

- (OsmAnd::ZoomLevel)maxZoom
{
    return OsmAnd::ZoomLevel([_plugin getTerrainMaxZoom]);
}

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)createGeoTiffLayerProvider:(TerrainMode *)mode
{
    NSString *mainFile = [mode mainFile];
    if (mainFile.length > 0)
    {
        auto geoTiffCollection = self.mapViewController.mapRendererEnv.geoTiffCollection;
        NSString *heightmapDir = self.app.colorsPalettePath;
        auto mainColorFilename = QString::fromNSString([heightmapDir stringByAppendingPathComponent:mainFile]);

        if ([mode isHillshade])
        {
            auto slopeSecondaryColorFilename = QString::fromNSString([heightmapDir stringByAppendingPathComponent:[mode secondFile]]);
            auto hillshadeLayerProvider = std::make_shared<OsmAnd::HillshadeRasterMapLayerProvider>(geoTiffCollection, mainColorFilename, slopeSecondaryColorFilename);
            hillshadeLayerProvider->setMinVisibleZoom([self minZoom]);
            hillshadeLayerProvider->setMaxVisibleZoom([self maxZoom]);
            return hillshadeLayerProvider;
        }
        else if ([mode isSlope])
        {
            auto slopeLayerProvider = std::make_shared<OsmAnd::SlopeRasterMapLayerProvider>(geoTiffCollection, mainColorFilename);
            slopeLayerProvider->setMinVisibleZoom([self minZoom]);
            slopeLayerProvider->setMaxVisibleZoom([self maxZoom]);
            return slopeLayerProvider;
        }
        else if ([mode isHeight])
        {
            auto heightLayerProvider = std::make_shared<OsmAnd::HeightRasterMapLayerProvider>(geoTiffCollection, mainColorFilename);
            heightLayerProvider->setMinVisibleZoom([self minZoom]);
            heightLayerProvider->setMaxVisibleZoom([self maxZoom]);
            return heightLayerProvider;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

@end
