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

#import "OAMapRendererViewProtocol.h"
#import "OAObservable.h"

#define _DECLARE_ENTRY(name)                                                                                                \
    OAMapRendererViewStateEntry##name = (NSUInteger)OsmAnd::MapRendererStateChange::name
typedef NS_OPTIONS(NSUInteger, OAMapRendererViewStateEntry)
{
    _DECLARE_ENTRY(MapLayers_Providers),
    _DECLARE_ENTRY(MapLayers_Configuration),
    _DECLARE_ENTRY(ElevationData_Provider),
    _DECLARE_ENTRY(ElevationData_Configuration),
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

@interface OAMapRendererView : UIView <OAMapRendererViewProtocol>

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)providerFor:(unsigned int)layer;
- (void)setProvider:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer;
- (void)resetProviderFor:(unsigned int)layer;

@property(nonatomic) std::shared_ptr<OsmAnd::IMapElevationDataProvider> elevationDataProvider;

- (QList< std::shared_ptr<const OsmAnd::MapSymbol> >)getSymbolsAt:(OsmAnd::PointI)screenPoint;
- (void)addTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (void)addKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (void)removeTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider;
- (void)removeKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider;
- (void)removeAllSymbolsProviders;

- (UIImage*) getGLScreenshot;

@property(nonatomic) CGFloat displayDensityFactor;
@property(nonatomic) OsmAnd::PointI target31;
@property(nonatomic) OsmAnd::ZoomLevel zoomLevel;

@property(nonatomic, readonly) unsigned int symbolsCount;
@property(nonatomic, readonly) BOOL isSymbolsUpdateSuspended;
- (BOOL)suspendSymbolsUpdate;
- (BOOL)resumeSymbolsUpdate;

// Misc properties:
@property(nonatomic, readonly) QList<OsmAnd::TileId> visibleTiles;

@property(nonatomic, readonly) float currentPixelsToMetersScaleFactor;

// Utilities:
- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location;
- (BOOL)convert:(CGPoint)point toLocation64:(OsmAnd::PointI64*)location;

@property(readonly) OAObservable* framePreparedObservable;

@property(nonatomic, readonly, getter=getAnimator) const std::shared_ptr<OsmAnd::MapAnimator>& animator;

@end
