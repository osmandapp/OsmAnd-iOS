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
#include <OsmAndCore/Map/MapTypes.h>
#include <OsmAndCore/Map/MapRendererTypes.h>
#include <OsmAndCore/Map/MapRendererState.h>
#include <OsmAndCore/Map/IMapBitmapTileProvider.h>
#include <OsmAndCore/Map/IMapElevationDataProvider.h>
#include <OsmAndCore/Map/IMapSymbolProvider.h>

#import "OAObservable.h"

#define _DECLARE_ENTRY(name)                                                                                                \
    OAMapRendererViewStateEntry##name = (NSUInteger)OsmAnd::MapRendererStateChange::name
typedef NS_OPTIONS(NSUInteger, OAMapRendererViewStateEntry)
{
    _DECLARE_ENTRY(RasterLayers_Providers),
    _DECLARE_ENTRY(RasterLayers_Opacity),
    _DECLARE_ENTRY(ElevationData_Provider),
    _DECLARE_ENTRY(ElevationData_ScaleFactor),
    _DECLARE_ENTRY(Symbols_Providers),
    _DECLARE_ENTRY(WindowSize),
    _DECLARE_ENTRY(Viewport),
    _DECLARE_ENTRY(FieldOfView),
    _DECLARE_ENTRY(SkyColor),
    _DECLARE_ENTRY(FogParameters),
    _DECLARE_ENTRY(Azimuth),
    _DECLARE_ENTRY(ElevationAngle),
    _DECLARE_ENTRY(Target),
    _DECLARE_ENTRY(Zoom)
};
#undef _DECLARE_ENTRY

#define _DECLARE_ENTRY(name)                                                                                                \
    OAMapAnimationTimingFunction##name = (NSUInteger)OsmAnd::MapAnimatorTimingFunction::name
#define _DECLARE_TIMING_FUNCTION(name)                                                                                      \
    _DECLARE_ENTRY(EaseIn##name),                                                                                           \
    _DECLARE_ENTRY(EaseOut##name),                                                                                          \
    _DECLARE_ENTRY(EaseInOut##name),                                                                                        \
    _DECLARE_ENTRY(EaseOutIn##name)
typedef NS_OPTIONS(NSUInteger, OAMapAnimationTimingFunction)
{
    _DECLARE_ENTRY(Invalid),
    _DECLARE_ENTRY(Linear),
    _DECLARE_TIMING_FUNCTION(Quadratic),
    _DECLARE_TIMING_FUNCTION(Cubic),
    _DECLARE_TIMING_FUNCTION(Quartic),
    _DECLARE_TIMING_FUNCTION(Sinusoidal),
    _DECLARE_TIMING_FUNCTION(Exponential),
    _DECLARE_TIMING_FUNCTION(Circular)
};
#undef _DECLARE_TIMING_FUNCTION
#undef _DECLARE_ENTRY

@interface OAMapRendererView : UIView

- (void)createContext;
- (void)releaseContext;

@property(readonly) BOOL isRenderingSuspended;
- (BOOL)suspendRendering;
- (BOOL)resumeRendering;

- (std::shared_ptr<OsmAnd::IMapBitmapTileProvider>)providerOf:(OsmAnd::RasterMapLayerId)layer;
- (void)setProvider:(std::shared_ptr<OsmAnd::IMapBitmapTileProvider>)provider ofLayer:(OsmAnd::RasterMapLayerId)layer;
- (void)removeProviderOf:(OsmAnd::RasterMapLayerId)layer;
- (CGFloat)opacityOf:(OsmAnd::RasterMapLayerId)layer;
- (void)setOpacity:(CGFloat)opacity ofLayer:(OsmAnd::RasterMapLayerId)layer;

@property(nonatomic) std::shared_ptr<OsmAnd::IMapElevationDataProvider> elevationDataProvider;
- (void)removeElevationDataProvider;
@property(nonatomic) CGFloat elevationDataScale;

- (void)addSymbolProvider:(std::shared_ptr<OsmAnd::IMapSymbolProvider>)provider;
- (void)removeSymbolProvider:(std::shared_ptr<OsmAnd::IMapSymbolProvider>)provider;
- (void)removeAllSymbolProviders;
//TODO: return array of symbol providers

@property(nonatomic) CGFloat fieldOfView;
//virtual void setDistanceToFog(const float& fogDistance, bool forcedUpdate = false) = 0;
//virtual void setFogOriginFactor(const float& factor, bool forcedUpdate = false) = 0;
//virtual void setFogHeightOriginFactor(const float& factor, bool forcedUpdate = false) = 0;
//virtual void setFogDensity(const float& fogDensity, bool forcedUpdate = false) = 0;
//virtual void setFogColor(const FColorRGB& color, bool forcedUpdate = false) = 0;
//virtual void setSkyColor(const FColorRGB& color, bool forcedUpdate = false) = 0;
@property(nonatomic) CGFloat azimuth;
@property(nonatomic) CGFloat elevationAngle;
@property(nonatomic) OsmAnd::PointI target31;
@property(nonatomic) CGFloat zoom;
@property(nonatomic, readonly) OsmAnd::ZoomLevel zoomLevel;
@property(nonatomic, readonly) CGFloat scaledTileSizeOnScreen;
@property(readonly) OAObservable* stateObservable;

@property(nonatomic, readonly) CGFloat minZoom;
@property(nonatomic, readonly) CGFloat maxZoom;

- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location;
- (BOOL)convert:(CGPoint)point toLocation64:(OsmAnd::PointI64*)location;

- (void)cancelAnimation;
- (void)resumeAnimation;

- (void)animateZoomWith:(CGFloat)velocity andDeceleration:(CGFloat)deceleration;
- (void)animateZoomBy:(CGFloat)deltaValue during:(CGFloat)duration timing:(OAMapAnimationTimingFunction)function;
- (void)animateTargetWith:(OsmAnd::PointD)velocity andDeceleration:(OsmAnd::PointD)deceleration;
- (void)animateTargetBy:(OsmAnd::PointI)deltaValue during:(CGFloat)duration timing:(OAMapAnimationTimingFunction)function;
- (void)animateTargetBy64:(OsmAnd::PointI64)deltaValue during:(CGFloat)duration timing:(OAMapAnimationTimingFunction)function;
- (void)animateAzimuthWith:(CGFloat)velocity andDeceleration:(CGFloat)deceleration;
- (void)animateAzimuthBy:(CGFloat)deltaValue during:(CGFloat)duration timing:(OAMapAnimationTimingFunction)function;

@end
