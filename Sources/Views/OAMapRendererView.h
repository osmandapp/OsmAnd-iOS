//
//  OAMapRendererView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapRendererViewProtocol.h"

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Map/MapCommonTypes.h>
#include <OsmAndCore/Map/MapAnimator.h>
#include <OsmAndCore/Map/MapMarkersAnimator.h>
#include <OsmAndCore/Map/MapRendererState.h>
#include <OsmAndCore/Map/IMapLayerProvider.h>
#include <OsmAndCore/Map/IMapElevationDataProvider.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/IMapKeyedSymbolsProvider.h>
#include <OsmAndCore/Map/MapRendererDebugSettings.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Map/MapRendererTypes.h>

static const float kViewportScale = 1.0f;
static const float kViewportBottomScale = 1.5f;

static const int kSymbolsUpdateInterval = 2000;

static const int kObfRasterLayer = 0;
static const int kObfSymbolSection = 1;

static const float kMinAllowedElevationAngle = 10.0f;

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
    _DECLARE_ENTRY(Azimuth),
    _DECLARE_ENTRY(ElevationAngle),
    _DECLARE_ENTRY(Target),
    _DECLARE_ENTRY(Zoom)
};
#undef _DECLARE_ENTRY

@class OAObservable;

@protocol OAMapRendererDelegate

- (void) frameAnimatorsUpdated;
- (void) frameUpdated;
- (void) frameRendered;

@end

struct CLLocationCoordinate2D;

@interface OAMapRendererView : UIView <OAMapRendererViewProtocol>

@property (nonatomic, readonly, assign) std::shared_ptr<OsmAnd::IMapRenderer> renderer;

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)providerFor:(unsigned int)layer;
- (void)setProvider:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer;
- (void)setProviderForced:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer;
- (void)resetProviderFor:(unsigned int)layer;

- (void)setTextureFilteringQuality:(OsmAnd::TextureFilteringQuality)quality;

@property(nonatomic) std::shared_ptr<OsmAnd::IMapElevationDataProvider> elevationDataProvider;

- (void)resetElevationDataProvider:(BOOL)forcedUpdate;
- (void)setElevationConfiguration:(const OsmAnd::ElevationConfiguration&)configuration
                     forcedUpdate:(BOOL)forcedUpdate;
- (void)setElevationScaleFactor:(float)scaleFactor;
- (float)getElevationScaleFactor;
- (void)setMyLocationCircleColor:(OsmAnd::FColorARGB)color;
- (void)setMyLocationCirclePosition:(OsmAnd::PointI)location31;
- (void)setMyLocationCircleRadius:(float)radiusInMeters;
- (void)setMyLocationSectorDirection:(float)directionAngle;
- (void)setMyLocationSectorRadius:(float)radius;

- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsAt:(OsmAnd::PointI)screenPoint;
- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsIn:(OsmAnd::AreaI)screenArea strict:(BOOL)strict;

- (void)addTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (void)addTiledSymbolsProvider:(int)subsectionIndex provider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (void)addKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (bool)removeTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (bool)removeKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (void)removeAllSymbolsProviders;

- (BOOL) setMapLayerConfiguration:(int)layerIndex configuration:(OsmAnd::MapLayerConfiguration)configuration forcedUpdate:(BOOL)forcedUpdate;
- (std::shared_ptr<OsmAnd::MapRendererDebugSettings>) getMapDebugSettings;
- (void) setMapDebugSettings:(std::shared_ptr<OsmAnd::MapRendererDebugSettings>) debugSettings;

- (BOOL) isGpuWorkerPaused;
- (BOOL) suspendGpuWorker;
- (BOOL) resumeGpuWorker;
- (void) invalidateFrame;
- (void) setSymbolsOpacity:(float)opacityFactor;
- (void) setDateTime:(int64_t)dateTime;
- (void) setSymbolSubsectionConfiguration:(int)subsectionIndex configuration:(const OsmAnd::SymbolSubsectionConfiguration &)configuration;

@property (nonatomic) CGFloat displayDensityFactor;
@property (nonatomic) OsmAnd::PointI target31;
@property (nonatomic) OsmAnd::PointI fixedPixel;
@property (nonatomic) OsmAnd::ZoomLevel zoomLevel;
@property (nonatomic) float viewportXScale;
@property (nonatomic) float viewportYScale;
@property (nonatomic) BOOL heightmapSupported;

@property (nonatomic, readonly) unsigned int symbolsCount;
@property (nonatomic, readonly) BOOL isSymbolsUpdateSuspended;
- (BOOL)suspendSymbolsUpdate;
- (BOOL)resumeSymbolsUpdate;
- (int)getSymbolsUpdateSuspended;
- (void)setVisualZoomShift:(double)shift;

- (BOOL)isIdle;

- (void) setSkyColor:(OsmAnd::FColorRGB)skyColor;

- (void) setFogColor:(OsmAnd::FColorRGB)fogColor;

// Misc properties:
@property(nonatomic, readonly) QVector<OsmAnd::TileId> visibleTiles;

@property(nonatomic, readonly) float currentPixelsToMetersScaleFactor;

// Utilities:
- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location;
- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point;
- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point checkOffScreen:(BOOL)offScreen;
- (BOOL)obtainScreenPointFromPosition:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point checkOffScreen:(BOOL)offScreen;

- (OsmAnd::PointI) getTarget;
- (OsmAnd::PointI) getTargetScreenPosition;
- (BOOL) setMapTarget:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI)location31;
- (BOOL) resetMapTarget;
- (BOOL) resetMapTargetPixelCoordinates:(OsmAnd::PointI)screenPoint;
- (float) getHeightAndLocationFromElevatedPoint:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI*)location31;
- (BOOL) getZoomAndRotationAfterPinch:(OsmAnd::PointI)firstLocation31 firstHeight:(float)firstHeight firstPoint:(OsmAnd::PointI)firstPoint secondLocation31:(OsmAnd::PointI)secondLocation31 secondHeight:(float)secondHeight secondPoint:(OsmAnd::PointI)secondPoint zoomAndRotate:(OsmAnd::PointD*)zoomAndRotate;

- (OsmAnd::AreaI) getVisibleBBox31;
- (NSArray<NSValue *> *) getVisibleLineFromLat:(double)fromLat fromLon:(double)fromLon toLat:(double)toLat toLon:(double)toLon;
- (BOOL)isPositionVisible:(OsmAnd::PointI)pos;

- (void)dumpResourcesInfo;

- (int) getFrameId;

@property (readonly) OAObservable* targetChangedObservable;
@property (readonly) OAObservable* framePreparedObservable;
@property (nonatomic, weak) id<OAMapRendererDelegate> rendererDelegate;

@property(nonatomic, readonly, getter=getMapAnimator) const std::shared_ptr<OsmAnd::MapAnimator>& mapAnimator;
@property(nonatomic, readonly, getter=getMapMarkersAnimator) const std::shared_ptr<OsmAnd::MapMarkersAnimator>& mapMarkersAnimator;

@property (nonatomic) int maxMissingDataZoomShift;
@property (nonatomic) int maxMissingDataUnderZoomShift;
@property (nonatomic) int heixelsPerTileSide;
@property (nonatomic) int elevationDataTileSize;

- (OsmAnd::PointI) getCenterPixel;
- (void)setTopOffsetOfViewSize:(CGFloat)topOffset bottomOffset:(CGFloat)bottomOffset;
- (float)getCameraHeightInMeters;
- (float)getTargetDistanceInMeters;

- (void) cancelAllAnimations;

- (BOOL)getLocationFromElevatedPoint:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI*)location31;
- (float)getLocationHeightInMeters:(OsmAnd::PointI)location31;

@end
