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
#import "OsmAnd_Maps-Swift.h"

#include "OATerrainMapLayerProvider.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/SlopeRasterMapLayerProvider.h>
#include <OsmAndCore/Map/HillshadeRasterMapLayerProvider.h>

static NSString * const SLOPE_MAIN_COLOR_FILENAME = @"slope_default";
static NSString * const HILLSHADE_MAIN_COLOR_FILENAME = @"hillshade_main_default";
static NSString * const SLOPE_SECONDARY_COLOR_FILENAME = @"hillshade_color_default";

@implementation OATerrainMapLayer
{
    std::shared_ptr<OsmAnd::IMapLayerProvider> _terrainMapProvider;
    
    std::shared_ptr<const OsmAnd::IGeoTiffCollection> _heightsCollection;
    std::shared_ptr<OsmAnd::SlopeRasterMapLayerProvider> _slopeLayerProvider;
    std::shared_ptr<OsmAnd::HillshadeRasterMapLayerProvider> _hillshadeLayerProvider;

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
                                                            andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onProfileSettingSet:)
                                                 name:kNotificationSetProfileSetting
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
    _terrainMapProvider.reset();
    _slopeLayerProvider.reset();
    _hillshadeLayerProvider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL)updateLayer
{
    [super updateLayer];

    if ([_plugin isTerrainLayerEnabled] && [_plugin isEnabled])
    {
        _terrainMode = [_plugin getTerrainMode];
        if ([_terrainMode isSlope])
            [self setupSlopeLayerProvider];
        else if ([_terrainMode isHillshade])
            [self setupHillshadeLayerProvider];
        else
            [self setupTerrainMapProvider];

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
            _terrainMapProvider.reset();
            _slopeLayerProvider.reset();
            _hillshadeLayerProvider.reset();
        }
        [self.mapViewController recreateHeightmapProvider];
        [self.mapViewController updateElevationConfiguration];
    }];
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    if (notification.object == _plugin.terrain || notification.object == _plugin.terrainModeType)
    {
        [self updateTerrainLayer];
    }
    else if ([notification.object isKindOfClass:OACommonInteger.class])
    {
        if ([_terrainMode isTransparencySetting:notification.object])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mapViewController runWithRenderSync:^{
                    OsmAnd::MapLayerConfiguration config;
                    config.setOpacityFactor([_terrainMode getTransparency] * 0.01);
                    [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
                }];
            });
        }
        else if ([_terrainMode isZoomSetting:notification.object])
        {
            [self updateTerrainLayer];
        }
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
    return OsmAnd::ZoomLevel([_terrainMode getMinZoom]);
}

- (OsmAnd::ZoomLevel)getMaxZoom
{
    return OsmAnd::ZoomLevel([_terrainMode getMaxZoom]);
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
    auto slopeColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:SLOPE_MAIN_COLOR_FILENAME ofType:@"txt"]);
    _slopeLayerProvider = std::make_shared<OsmAnd::SlopeRasterMapLayerProvider>(self.mapViewController.mapRendererEnv.geoTiffCollection, slopeColorFilename);
    _slopeLayerProvider->setMinVisibleZoom([self getMinZoom]);
    _slopeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);

    [self.mapView setProvider:_slopeLayerProvider forLayer:self.layerIndex];
    _hillshadeLayerProvider.reset();
    _terrainMapProvider.reset();
}

- (void) setupHillshadeLayerProvider
{
    auto hillshadeColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:HILLSHADE_MAIN_COLOR_FILENAME ofType:@"txt"]);
    auto slopeSecondaryColorFilename = QString::fromNSString([[NSBundle mainBundle] pathForResource:SLOPE_SECONDARY_COLOR_FILENAME ofType:@"txt"]);
    _hillshadeLayerProvider = std::make_shared<OsmAnd::HillshadeRasterMapLayerProvider>(self.mapViewController.mapRendererEnv.geoTiffCollection, hillshadeColorFilename, slopeSecondaryColorFilename);
    _hillshadeLayerProvider->setMinVisibleZoom([self getMinZoom]);
    _hillshadeLayerProvider->setMaxVisibleZoom([self getMaxZoom]);

    [self.mapView setProvider:_hillshadeLayerProvider forLayer:self.layerIndex];
    _slopeLayerProvider.reset();
    _terrainMapProvider.reset();
}

@end
