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
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/SlopeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HillshadeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HeightRasterMapLayerProvider.h>

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onColorPalettesFilesUpdated:)
                                                 name:ColorPaletteHelper.colorPalettesUpdatedNotification
                                               object:nil];
}

- (void) deinitLayer
{
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
        [self.mapView setProvider:_layerProvider forLayer:self.layerIndex];

        OsmAnd::MapLayerConfiguration config;
        config.setOpacityFactor([_terrainMode getTransparency] * 0.01);
        [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        [self.mapView setElevationScaleFactor:self.app.data.verticalExaggerationScale];
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
        }
        else if ([notification.object isKindOfClass:OACommonInteger.class])
        {
            if ([_terrainMode isTransparencySetting:notification.object])
            {
                [self.mapViewController runWithRenderSync:^{
                    OsmAnd::MapLayerConfiguration config;
                    config.setOpacityFactor([_terrainMode getTransparency] * 0.01);
                    [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
                }];
            }
            else if ([_terrainMode isZoomSetting:notification.object])
            {
                [self updateTerrainLayer];
            }
        }
    });
}

- (void)onColorPalettesFilesUpdated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSDictionary.class])
        return;

    NSDictionary<NSString *, NSString *> *colorPaletteFiles = (NSDictionary *) notification.object;
    if (!colorPaletteFiles)
        return;

    NSString *currentPaletteFile = [_terrainMode getMainFile];
    if ([colorPaletteFiles.allKeys containsObject:currentPaletteFile])
    {
        if ([colorPaletteFiles[currentPaletteFile] isEqualToString:ColorPaletteHelper.deletedFileKey])
        {
            TerrainMode *defaultTerrainMode = [TerrainMode getDefaultMode:_terrainMode.type];
            if (defaultTerrainMode)
            {
                _terrainMode = defaultTerrainMode;
                [_plugin setTerrainMode:defaultTerrainMode];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTerrainLayer];
        });
    }
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

- (OsmAnd::ZoomLevel)getMinZoom
{
    return OsmAnd::ZoomLevel([_plugin getTerrainMinZoom]);
}

- (OsmAnd::ZoomLevel)getMaxZoom
{
    return OsmAnd::ZoomLevel([_plugin getTerrainMaxZoom]);
}

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)createGeoTiffLayerProvider:(TerrainMode *)mode
{
    auto geoTiffCollection = self.mapViewController.mapRendererEnv.geoTiffCollection;
    NSString *heightmapDir = self.app.colorsPalettePath;
    auto mainColorFilename = QString::fromNSString([heightmapDir stringByAppendingPathComponent:[mode getMainFile]]);

    if ([mode isHillshade])
    {
        auto slopeSecondaryColorFilename = QString::fromNSString([heightmapDir stringByAppendingPathComponent:[mode getSecondFile]]);
        auto hillshadeLayerProvider = std::make_shared<OsmAnd::HillshadeRasterMapLayerProvider>(geoTiffCollection, mainColorFilename, slopeSecondaryColorFilename);
        hillshadeLayerProvider->setMinVisibleZoom([self getMinZoom]);
        hillshadeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);
        return hillshadeLayerProvider;
    }
    else if ([mode isSlope])
    {
        auto slopeLayerProvider = std::make_shared<OsmAnd::SlopeRasterMapLayerProvider>(geoTiffCollection, mainColorFilename);
        slopeLayerProvider->setMinVisibleZoom([self getMinZoom]);
        slopeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);
        return slopeLayerProvider;
    }
    else
    {
        auto heightLayerProvider = std::make_shared<OsmAnd::HeightRasterMapLayerProvider>(geoTiffCollection, mainColorFilename);
        heightLayerProvider->setMinVisibleZoom([self getMinZoom]);
        heightLayerProvider->setMaxVisibleZoom([self getMaxZoom]);
        return heightLayerProvider;
    }
}

@end
