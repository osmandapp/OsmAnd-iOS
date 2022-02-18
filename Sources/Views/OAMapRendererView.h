//
//  OAMapRendererView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Map/MapCommonTypes.h>
#include <OsmAndCore/Map/MapAnimator.h>
#include <OsmAndCore/Map/MapRendererState.h>
#include <OsmAndCore/Map/IMapLayerProvider.h>
#include <OsmAndCore/Map/IMapElevationDataProvider.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/IMapKeyedSymbolsProvider.h>
#include <OsmAndCore/Map/MapRendererDebugSettings.h>
#include <OsmAndCore/Map/IMapRenderer.h>

#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"

#define _DECLARE_ENTRY(name)                                                                                                \
    OAMapRendererViewStateEntry##name = (NSUInteger)OsmAnd::MapRendererStateChange::name
typedef NS_OPTIONS(NSUInteger, OAMapRendererViewStateEntry)
{
    _DECLARE_ENTRY(MapLayers_Providers),
    _DECLARE_ENTRY(MapLayers_Configuration),
    _DECLARE_ENTRY(Elevation_DataProvider),
    _DECLARE_ENTRY(Elevation_Configuration),
    _DECLARE_ENTRY(Symbols_Providers),
    _DECLARE_ENTRY(WindowSize),
    _DECLARE_ENTRY(Viewport),
    _DECLARE_ENTRY(FieldOfView),
    _DECLARE_ENTRY(SkyColor),
    _DECLARE_ENTRY(FogConfiguration),
    _DECLARE_ENTRY(Azimuth),
    _DECLARE_ENTRY(ElevationAngle),
    _DECLARE_ENTRY(Target),
    _DECLARE_ENTRY(Zoom)
};
#undef _DECLARE_ENTRY

@protocol OAMapRendererDelegate

- (void) frameRendered;

@end

struct CLLocationCoordinate2D;

@interface OAMapRendererView : UIView <OAMapRendererViewProtocol>

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)providerFor:(unsigned int)layer;
- (void)setProvider:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer;
- (void)setProviderForced:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer;
- (void)resetProviderFor:(unsigned int)layer;

- (void)setTextureFilteringQuality:(OsmAnd::TextureFilteringQuality)quality;

@property(nonatomic) std::shared_ptr<OsmAnd::IMapElevationDataProvider> elevationDataProvider;

- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsAt:(OsmAnd::PointI)screenPoint;
- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsIn:(OsmAnd::AreaI)screenArea strict:(BOOL)strict;

- (void)addTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (void)addKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (bool)removeTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (bool)removeKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (void)removeAllSymbolsProviders;

- (BOOL) setMapLayerConfiguration:(int)layerIndex configuration:(OsmAnd::MapLayerConfiguration)configuration forcedUpdate:(BOOL)forcedUpdate;
- (std::shared_ptr<OsmAnd::MapRendererDebugSettings>) getMapDebugSettings;
- (void) setMapDebugSettings:(std::shared_ptr<OsmAnd::MapRendererDebugSettings>) debugSettings;

- (UIImage*) getGLScreenshot;

- (BOOL) isGpuWorkerPaused;
- (BOOL) suspendGpuWorker;
- (BOOL) resumeGpuWorker;
- (void) invalidateFrame;

@property (nonatomic) CGFloat displayDensityFactor;
@property (nonatomic) OsmAnd::PointI target31;
@property (nonatomic) OsmAnd::ZoomLevel zoomLevel;
@property (nonatomic) float viewportXScale;
@property (nonatomic) float viewportYScale;

@property (nonatomic, readonly) unsigned int symbolsCount;
@property (nonatomic, readonly) BOOL isSymbolsUpdateSuspended;
- (BOOL)suspendSymbolsUpdate;
- (BOOL)resumeSymbolsUpdate;
- (int)getSymbolsUpdateSuspended;
- (void)setVisualZoomShift:(double)shift;

- (BOOL)isIdle;

- (void) setSkyColor:(OsmAnd::FColorRGB)skyColor;

// Misc properties:
@property(nonatomic, readonly) QVector<OsmAnd::TileId> visibleTiles;

@property(nonatomic, readonly) float currentPixelsToMetersScaleFactor;

// Utilities:
- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location;
- (BOOL)convert:(CGPoint)point toLocation64:(OsmAnd::PointI64*)location;

- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point;
- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point checkOffScreen:(BOOL)offScreen;
- (BOOL)convert:(OsmAnd::PointI64*)pos64 toScreen64:(CGPoint*)point;

- (OsmAnd::AreaI)getVisibleBBox31;
- (NSArray<NSValue *> *) getVisibleLineFromLat:(double)fromLat fromLon:(double)fromLon toLat:(double)toLat toLon:(double)toLon;
- (BOOL)isPositionVisible:(OsmAnd::PointI)pos;

- (void)dumpResourcesInfo;

@property (readonly) OAObservable* framePreparedObservable;
@property (nonatomic, weak) id<OAMapRendererDelegate> rendererDelegate;

@property(nonatomic, readonly, getter=getAnimator) const std::shared_ptr<OsmAnd::MapAnimator>& animator;

@property (nonatomic) int maxMissingDataZoomShift;
@property (nonatomic) int maxMissingDataUnderZoomShift;
@property (nonatomic) int heixelsPerTileSide;
@property (nonatomic) int elevationDataTileSize;



@end
