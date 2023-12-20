//
//  OAMapRendererView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererView.h"
#import "OAMapUtils.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Map/IAtlasMapRenderer.h>
#include <OsmAndCore/Map/AtlasMapRendererConfiguration.h>
#include <OsmAndCore/Map/AtlasMapRenderer_Metrics.h>

#import "OALog.h"

#if defined(DEBUG)
#   define validateGL() [self validateOpenGLES]
#else
#   define validateGL()
#endif

#define _(name) OAMapRendererView__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@implementation OAMapRendererView
{
    EAGLSharegroup* _glShareGroup;
    EAGLContext* _glRenderContext;
    EAGLContext* _glWorkerContext;
    EAGLRenderingAPI _glVersion;
    GLuint _depthRenderBuffer;
    GLuint _colorRenderBuffer;
    GLuint _framebuffer;
    CADisplayLink* _displayLink;

    OsmAnd::PointI _viewSize;
    CGFloat _topOffset;
    CGFloat _bottomOffset;
    OsmAnd::PointI _centerPixel;

    std::shared_ptr<OsmAnd::IMapRenderer> _renderer;
    std::shared_ptr<OsmAnd::MapAnimator> _mapAnimator;
    std::shared_ptr<OsmAnd::MapMarkersAnimator> _mapMarkersAnimator;

    CGRect prevBounds;
    int _frameId;
    NSTimeInterval _lastUpdateTime;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void) awakeFromNib
{
    [self commonInit];
}

- (void) commonInit
{
    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];
    _targetChangedObservable = [[OAObservable alloc] init];

    // Set default values
    _glShareGroup = nil;
    _glRenderContext = nil;
    _glWorkerContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _framebuffer = 0;
    _displayLink = nil;

    _viewportXScale = kViewportScale;
    _viewportYScale = kViewportScale;

    // Create map renderer instance
    _renderer = OsmAnd::createMapRenderer(OsmAnd::MapRendererClass::AtlasMapRenderer_OpenGLES2plus);
    const auto rendererConfig = std::static_pointer_cast<OsmAnd::AtlasMapRendererConfiguration>(_renderer->getConfiguration());
    rendererConfig->texturesFilteringQuality = OsmAnd::TextureFilteringQuality::Good;
    _renderer->setConfiguration(rendererConfig);

    OAObservable* stateObservable = _stateObservable;
    _renderer->stateChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)_stateObservable),
        [stateObservable]
        (const OsmAnd::IMapRenderer* renderer, const OsmAnd::MapRendererStateChange thisChange, const uint32_t allChanges)
        {
            [stateObservable notifyEventWithKey:[NSNumber numberWithUnsignedInteger:(OAMapRendererViewStateEntry)thisChange]];
        });

    OAObservable* framePreparedObservable = _framePreparedObservable;
    _renderer->framePreparedObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)_framePreparedObservable),
        [framePreparedObservable]
        (const OsmAnd::IMapRenderer* renderer)
        {
            [framePreparedObservable notifyEvent];
        });

    OAObservable* targetChangedObservalbe = _targetChangedObservable;
    _renderer->targetChangedObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)_targetChangedObservable),
        [targetChangedObservalbe]
        (const OsmAnd::IMapRenderer* renderer)
        {
            [targetChangedObservalbe notifyEvent];
        });

    // Create animator for that map
    _mapAnimator.reset(new OsmAnd::MapAnimator());
    _mapAnimator->setMapRenderer(_renderer);
    _renderer->setSymbolsUpdateInterval(kSymbolsUpdateInterval);

    // Create animator for map markers
    _mapMarkersAnimator.reset(new OsmAnd::MapMarkersAnimator());
    _mapMarkersAnimator->setMapRenderer(_renderer);

    auto debugSettings = [self getMapDebugSettings];
    //debugSettings->disableSymbolsFastCheckByFrustum = true;
    [self setMapDebugSettings:debugSettings];
}

- (void)deinit
{
    // Unregister observer
    _renderer->stateChangeObservable.detach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)_stateObservable));
    _renderer->framePreparedObservable.detach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)_framePreparedObservable));
}

- (void)setTextureFilteringQuality:(OsmAnd::TextureFilteringQuality)quality
{
    const auto rendererConfig = std::static_pointer_cast<OsmAnd::AtlasMapRendererConfiguration>(_renderer->getConfiguration());
    rendererConfig->texturesFilteringQuality = quality;
    _renderer->setConfiguration(rendererConfig);
}

- (std::shared_ptr<OsmAnd::IMapLayerProvider>)providerFor:(unsigned int)layer
{
    return _renderer->getState().mapLayersProviders[layer];
}

- (void)setProvider:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer
{
    _renderer->setMapLayerProvider(layer, provider);
}

- (void)setProviderForced:(std::shared_ptr<OsmAnd::IMapLayerProvider>)provider forLayer:(unsigned int)layer
{
    _renderer->setMapLayerProvider(layer, provider, true);
}

- (void)resetProviderFor:(unsigned int)layer
{
    _renderer->resetMapLayerProvider(layer);
}

- (std::shared_ptr<OsmAnd::IMapElevationDataProvider>)elevationDataProvider
{
    return _renderer->getState().elevationDataProvider;
}

- (void)setElevationDataProvider:(std::shared_ptr<OsmAnd::IMapElevationDataProvider>)elevationDataProvider
{
    _renderer->setElevationDataProvider(elevationDataProvider);
}

- (void)resetElevationDataProvider:(BOOL)forcedUpdate
{
    _renderer->resetElevationDataProvider(forcedUpdate);
}

- (void)setElevationConfiguration:(const OsmAnd::ElevationConfiguration&)configuration
forcedUpdate:(BOOL)forcedUpdate
{
    _renderer->setElevationConfiguration(configuration, forcedUpdate);
}

- (int) maxMissingDataZoomShift
{
    return _renderer->getMaxMissingDataZoomShift();
}

- (int) maxMissingDataUnderZoomShift
{
    return _renderer->getMaxMissingDataUnderZoomShift();
}

- (int) heixelsPerTileSide
{
    return _renderer->getHeixelsPerTileSide();
}

- (int) elevationDataTileSize
{
    return _renderer->getElevationDataTileSize();
}

- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsAt:(OsmAnd::PointI)screenPoint
{
    return _renderer->getSymbolsAt(screenPoint);
}

- (QList<OsmAnd::IMapRenderer::MapSymbolInformation>)getSymbolsIn:(OsmAnd::AreaI)screenArea strict:(BOOL)strict
{
    return _renderer->getSymbolsIn(screenArea, strict);
}

- (void)addTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider
{
    _renderer->addSymbolsProvider(provider);
}

- (void)addTiledSymbolsProvider:(int)subsectionIndex provider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider
{
    _renderer->addSymbolsProvider(subsectionIndex, provider);
}

- (void)addKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider
{
    _renderer->addSymbolsProvider(provider);
}

- (bool)removeTiledSymbolsProvider:(std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider>)provider
{
    return _renderer->removeSymbolsProvider(provider);
}

- (bool)removeKeyedSymbolsProvider:(std::shared_ptr<OsmAnd::IMapKeyedSymbolsProvider>)provider
{
    return _renderer->removeSymbolsProvider(provider);
}

- (void)removeAllSymbolsProviders
{
    _renderer->removeAllSymbolsProviders();
}

- (BOOL) setMapLayerConfiguration:(int)layerIndex configuration:(OsmAnd::MapLayerConfiguration)configuration forcedUpdate:(BOOL)forcedUpdate
{
    return _renderer->setMapLayerConfiguration(layerIndex, configuration, forcedUpdate);
}

- (std::shared_ptr<OsmAnd::MapRendererDebugSettings>) getMapDebugSettings
{
    return _renderer->getDebugSettings();
}

- (void) setMapDebugSettings:(std::shared_ptr<OsmAnd::MapRendererDebugSettings>) debugSettings
{
    _renderer->setDebugSettings(debugSettings);
}

- (float)fieldOfView
{
    return _renderer->getState().fieldOfView;
}

- (void)setFieldOfView:(float)fieldOfView
{
    _renderer->setFieldOfView(fieldOfView);
}

- (float)azimuth
{
    return _renderer->getState().azimuth;
}

- (void)setAzimuth:(float)azimuth
{
    _renderer->setAzimuth(azimuth);
}

- (float)elevationAngle
{
    return _renderer->getState().elevationAngle;
}

- (float)currentPixelsToMetersScaleFactor
{
    //return _renderer->getCurrentPixelsToMetersScaleFactor();
    return _renderer->getMapState().metersPerPixel;
}

- (double) normalizeElevationAngle:(double)elevationAngle
{
    return elevationAngle > 90 ? 90 : MAX([self getMinAllowedElevationAngle:elevationAngle], elevationAngle);
}

- (double) getMinAllowedElevationAngle:(double)elevationAngle
{
    // TODO: skip normalize temporarily
    if (YES)
        return 10;
    
    int verticalTilesCount = round(UIScreen.mainScreen.bounds.size.height * self.viewportYScale * self.displayDensityFactor / 256.0);
    if (verticalTilesCount < 6)
        return MAX(30.0, elevationAngle);
    else if (verticalTilesCount < 8)
        return MAX(36.0, elevationAngle);
    else if (verticalTilesCount < 9)
        return MAX(40.0, elevationAngle);
    else if (verticalTilesCount < 11)
        return MAX(42.0, elevationAngle);
    else
        return MAX(48.0, elevationAngle);
}

- (void)setElevationAngle:(float)elevationAngle
{
    _renderer->setElevationAngle([self normalizeElevationAngle:elevationAngle]);
}

- (OsmAnd::PointI)target31
{
    auto fixedPixel = _renderer->getState().fixedPixel;
    if (fixedPixel.x >= 0 && fixedPixel.y >= 0)
        return _renderer->getState().fixedLocation31;
    else
        return _renderer->getState().target31;
}

- (OsmAnd::PointI)fixedPixel
{
    return _renderer->getState().fixedPixel;
}

- (void)setTarget31:(OsmAnd::PointI)target31
{
    if (_viewSize.x > 0 && _viewSize.y > 0)
    {
        _renderer->setMapTargetLocation(OsmAnd::Utilities::normalizeCoordinates(target31, OsmAnd::ZoomLevel31));
    }
    else
    {
        _renderer->setTarget(target31);
    }
}

- (float)zoom
{
    return _renderer->getState().surfaceZoomLevel + (_renderer->getState().surfaceVisualZoom >= 1.0f ? _renderer->getState().surfaceVisualZoom - 1.0f : (_renderer->getState().surfaceVisualZoom - 1.0f) * 2.0f);
}

- (void)setZoom:(float)zoom
{
    _renderer->setZoom(zoom);
}

- (float)flatZoom
{
    return _renderer->getState().zoomLevel + (_renderer->getState().visualZoom >= 1.0f ? _renderer->getState().visualZoom - 1.0f : (_renderer->getState().visualZoom - 1.0f) * 2.0f);
}

- (void)setFlatZoom:(float)flatZoom
{
    _renderer->setFlatZoom(flatZoom);
}

- (OsmAnd::ZoomLevel)zoomLevel
{
    return _renderer->getState().surfaceZoomLevel;
}

- (float)tileSizeOnScreenInPixels
{
    return _renderer->getTileSizeOnScreenInPixels();
}

- (float)tileSizeOnScreenInMeters
{
    return _renderer->getTileSizeInMeters();
}

- (float)getCameraHeightInMeters
{
    return _renderer->getCameraHeightInMeters();
}

- (float)getTargetDistanceInMeters
{
    return _renderer->getMapTargetDistance(self.target31) * 1000;
}

- (float)minZoom
{
    return OsmAnd::ZoomLevel1;//_renderer->getMinZoomLevel();
}

- (float)maxZoom
{
    return OsmAnd::ZoomLevel22;//_renderer->getMaxZoomLevel();
}

@synthesize stateObservable = _stateObservable;

- (unsigned int)symbolsCount
{
    return _renderer->getSymbolsCount();
}

- (BOOL)isSymbolsUpdateSuspended
{
    return _renderer->isSymbolsUpdateSuspended();
}

- (int)getSymbolsUpdateSuspended
{
    int count;
    _renderer->isSymbolsUpdateSuspended(&count);
    return count;
}

- (BOOL)suspendSymbolsUpdate
{
    return _renderer->suspendSymbolsUpdate();
}

- (BOOL)isIdle
{
    return _renderer->isIdle();
}

- (BOOL)resumeSymbolsUpdate
{
    return _renderer->resumeSymbolsUpdate();
}

- (void) setVisualZoomShift:(double)shift
{
    _renderer->setVisualZoomShift(shift - 1.0);
}

- (void) cancelAllAnimations
{
    _mapAnimator->cancelAllAnimations();
}

- (QVector<OsmAnd::TileId>)visibleTiles
{
    return std::dynamic_pointer_cast<OsmAnd::IAtlasMapRenderer>(_renderer)->getVisibleTiles();
}

- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location
{
    if (!location)
        return NO;
    if (_heightmapSupported)
        return _renderer->getLocationFromElevatedPoint(OsmAnd::PointI(static_cast<int32_t>(point.x), static_cast<int32_t>(point.y)), *location);
    else
        return _renderer->getLocationFromScreenPoint(OsmAnd::PointI(static_cast<int32_t>(point.x), static_cast<int32_t>(point.y)), *location);
}

// virtual bool obtainScreenPointFromPosition(const PointI64& position, PointI& outScreenPoint) const = 0;
// virtual bool obtainScreenPointFromPosition(const PointI& position31, PointI& outScreenPoint) const = 0;

- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point checkOffScreen:(BOOL)offScreen
{
    if (!pos)
        return NO;

    OsmAnd::PointI _point(0, 0);
    BOOL res;
    if (_heightmapSupported)
        res = _renderer->obtainElevatedPointFromPosition(*pos, _point, offScreen);
    else
        res = _renderer->obtainScreenPointFromPosition(*pos, _point, offScreen);

    if (res) {
        point->x = _point.x / [UIScreen mainScreen].scale;
        point->y = _point.y / [UIScreen mainScreen].scale;
    }
    return res;
}

- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point
{
    return [self convert:pos toScreen:point checkOffScreen:NO];
}

- (OsmAnd::PointI) getTarget
{
    auto fixedPixel = _renderer->getState().fixedPixel;
    if (fixedPixel.x >= 0 && fixedPixel.y >= 0)
        return _renderer->getState().fixedLocation31;
    else
        return _renderer->getState().target31;
}

- (OsmAnd::PointI) getTargetScreenPosition
{
    return _renderer->getState().fixedPixel;
}

- (float) getHeightAndLocationFromElevatedPoint:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI*)location31
{
    return _renderer->getHeightAndLocationFromElevatedPoint(screenPoint, *location31);
}

- (BOOL) getZoomAndRotationAfterPinch:(OsmAnd::PointI)firstLocation31 firstHeight:(float)firstHeight firstPoint:(OsmAnd::PointI)firstPoint secondLocation31:(OsmAnd::PointI)secondLocation31 secondHeight:(float)secondHeight secondPoint:(OsmAnd::PointI)secondPoint zoomAndRotate:(OsmAnd::PointD*)zoomAndRotate
{
    return _renderer->getZoomAndRotationAfterPinch(firstLocation31, firstHeight, firstPoint, secondLocation31, secondHeight, secondPoint, *zoomAndRotate);
}

- (BOOL) setMapTarget:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI)location31
{
    return _renderer->setMapTarget(screenPoint, location31);
}

- (BOOL) resetMapTarget
{
    return _renderer->resetMapTarget();
}

- (BOOL) resetMapTargetPixelCoordinates:(OsmAnd::PointI)screenPoint
{
    return _renderer->resetMapTargetPixelCoordinates(screenPoint);
}

- (OsmAnd::AreaI) getVisibleBBox31
{
    return _renderer->getVisibleBBox31();
}

- (int) getFrameId
{
    return _frameId;
}

- (BOOL)isPositionVisible:(OsmAnd::PointI)pos
{
    return _renderer->isPositionVisible(pos);
}

- (NSArray<NSValue *> *) getVisibleLineFromLat:(double)fromLat fromLon:(double)fromLon toLat:(double)toLat toLon:(double)toLon;
{
    // first calculate visible line in 31 within VisibleBBox
    const OsmAnd::LatLon fromLatLon(fromLat, fromLon);
    const auto fromI = OsmAnd::Utilities::convertLatLonTo31(fromLatLon);
    const OsmAnd::LatLon toLatLon(toLat, toLon);
    const auto toI = OsmAnd::Utilities::convertLatLonTo31(toLatLon);
    const auto areaI = [self getVisibleBBox31];

    CGRect rect31 = CGRectMake(areaI.left(), areaI.top(), areaI.width(), areaI.height());
    CGPoint start31 = CGPointMake(fromI.x, fromI.y);
    CGPoint end31 = CGPointMake(toI.x, toI.y);
    NSArray<NSValue *> *line31 = [OAMapUtils calculateLineInRect:rect31 start:start31 end:end31];
    if (line31.count == 2)
    {
        // then convert line points to screen coords and trim by screen bounds
        CGPoint a = line31[0].CGPointValue;
        CGPoint b = line31[1].CGPointValue;
        auto pointAI = OsmAnd::PointI(a.x, a.y);
        auto pointBI = OsmAnd::PointI(b.x, b.y);
        CGPoint screenPointA;
        CGPoint screenPointB;
        if ([self convert:&pointAI toScreen:&screenPointA checkOffScreen:YES] &&
            [self convert:&pointBI toScreen:&screenPointB checkOffScreen:YES])
        {
            return [OAMapUtils calculateLineInRect:self.bounds start:screenPointA end:screenPointB];
        }
    }
    return nil;
}

- (void) dumpResourcesInfo
{
    _renderer->dumpResourcesInfo();
}

@synthesize framePreparedObservable = _framePreparedObservable;

- (const std::shared_ptr<OsmAnd::MapAnimator>&) getMapAnimator
{
    return _mapAnimator;
}

- (const std::shared_ptr<OsmAnd::MapMarkersAnimator>&) getMapMarkersAnimator
{
    return _mapMarkersAnimator;
}

- (void)createContext
{
    if (_glShareGroup != nil)
        return;

    OALog(@"[OAMapRendererView %p] Creating context", self);

    // Set layer to be opaque to reduce perfomance loss, and anyways we use all area for rendering
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],
        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
    };

    // Initialize OpenGLES
    for (auto glVersion : { kEAGLRenderingAPIOpenGLES3, kEAGLRenderingAPIOpenGLES2 })
    {
        _glRenderContext = [[EAGLContext alloc] initWithAPI:glVersion];
        if (!_glRenderContext)
            continue;

        _glShareGroup = [_glRenderContext sharegroup];
        if (!_glShareGroup)
            continue;

        _glWorkerContext = [[EAGLContext alloc] initWithAPI:glVersion sharegroup:_glShareGroup];
        if (!_glWorkerContext)
            continue;

        _glVersion = glVersion;
        break;
    }
    if (!_glRenderContext || !_glShareGroup || !_glWorkerContext)
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES2+"];
        return;
    }

    // Set created context as current active
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return;
    }

    // Setup renderer
    OsmAnd::MapRendererSetupOptions rendererSetup;
    rendererSetup.gpuWorkerThreadEnabled = true;
    rendererSetup.displayDensityFactor = _displayDensityFactor;
    const auto capturedWorkerContext = _glWorkerContext;
    rendererSetup.gpuWorkerThreadPrologue =
        [capturedWorkerContext]
        (const OsmAnd::IMapRenderer* const renderer)
        {
            // Activate worker context
            if (![EAGLContext setCurrentContext:capturedWorkerContext])
            {
                [NSException raise:NSGenericException
                            format:@"Failed to set current OpenGLES2+ context in GPU worker thread 0x%08x", glGetError()];
                return;
            }
        };
    rendererSetup.gpuWorkerThreadEpilogue =
        []
        (const OsmAnd::IMapRenderer* const renderer)
        {
            // Nothing to do
        };
    _renderer->setup(rendererSetup);

    // Initialize rendering
    if (!_renderer->initializeRendering(false))
    {
        [NSException raise:NSGenericException
                    format:@"Failed to initialize OpenGLES2+ map renderer 0x%08x", glGetError()];
        return;
    }

    // Rendering needs to be resumed/started manually, since render target is not created yet
}

- (void)releaseContext:(BOOL)gpuContextLost
{
    if (_glShareGroup == nil)
        return;

    OALog(@"[OAMapRendererView %p] Releasing context", self);

    // Stop rendering (if it was running)
    [self suspendRendering];

    // Release map renderer
    if (!_renderer->releaseRendering(gpuContextLost))
    {
        [NSException raise:NSGenericException
                    format:@"Failed to release OpenGLES2+ map renderer 0x%08x", glGetError()];
        return;
    }

    // Release render-buffers and framebuffer
    [self releaseRenderAndFrameBuffers];

    // Tear down contexts
    if ([EAGLContext currentContext] == _glRenderContext || [EAGLContext currentContext] == _glWorkerContext)
        [EAGLContext setCurrentContext:nil];
    _glWorkerContext = nil;
    _glRenderContext = nil;
    _glShareGroup = nil;
}

#if defined(DEBUG)
- (GLenum)validateOpenGLES
{
    GLenum result = glGetError();
    if (result == GL_NO_ERROR)
        return result;

    OALog(@"OpenGLES error 0x%08x", result);

    return result;
}
#endif

- (void)layoutSubviews
{
    if (CGRectEqualToRect(prevBounds, self.bounds))
        return;

    if (!CGRectIsEmpty(self.bounds))
        prevBounds = self.bounds;

    // Normalize elevation angle
    [self setElevationAngle:self.elevationAngle];

    OALog(@"[OAMapRendererView %p] Recreating OpenGLES2+ frame and render buffers due to resize", self);

    // Kill buffers, since window was resized
    [self releaseRenderAndFrameBuffers];
}

- (void) setViewportXScale:(float)viewportXScale
{
    if (_viewportXScale == viewportXScale)
        return;

    _viewportXScale = viewportXScale;
}

- (void) setViewportYScale:(float)viewportYScale
{
    if (_viewportYScale == viewportYScale)
        return;

    _viewportYScale = viewportYScale;
}

- (void) setSkyColor:(OsmAnd::FColorRGB)skyColor
{
    _renderer->setSkyColor(skyColor);
}

- (void) setFogColor:(OsmAnd::FColorRGB)fogColor
{
    _renderer->setFogColor(fogColor);
}

- (void) allocateRenderAndFrameBuffers
{
    OALog(@"[OAMapRendererView %p] Allocating render and frame buffers", self);

    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return;
    }

    // Setup frame-buffer
    glGenFramebuffers(1, &_framebuffer);
    validateGL();
    NSAssert(_framebuffer != 0, @"Failed to allocate frame buffer");
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    validateGL();

    // Setup color component of renderbuffer
    glGenRenderbuffers(1, &_colorRenderBuffer);
    validateGL();
    NSAssert(_colorRenderBuffer != 0, @"Failed to allocate color component for renderbuffer");
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();
    if (![_glRenderContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to create render buffer (color component) 0x%08x", glGetError()];
        return;
    }
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewSize.x);
    validateGL();
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewSize.y);
    validateGL();
    OALog(@"[OAMapRendererView %p] View size %dx%d", self, _viewSize.x, _viewSize.y);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();

    // Setup render buffer (depth component)
    glGenRenderbuffers(1, &_depthRenderBuffer);
    validateGL();
    NSAssert(_depthRenderBuffer != 0, @"Failed to allocate render buffer (depth component)");
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    validateGL();
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _viewSize.x, _viewSize.y);
    validateGL();
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    validateGL();

    // Check that we've initialized our framebuffer fully
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        [NSException raise:NSGenericException
                    format:@"Failed to make complete framebuffer (status 0x%08x) 0x%08x", glCheckFramebufferStatus(GL_FRAMEBUFFER), glGetError()];
        return;
    }
    validateGL();
}

- (void) releaseRenderAndFrameBuffers
{
    OALog(@"[OAMapRendererView %p] Releasing render and frame buffers", self);

    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return;
    }

    if (_framebuffer != 0)
    {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
        validateGL();
    }
    if (_colorRenderBuffer != 0)
    {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
        validateGL();
    }
    if (_depthRenderBuffer != 0)
    {
        glDeleteRenderbuffers(1, &_depthRenderBuffer);
        _depthRenderBuffer = 0;
        validateGL();
    }
}

@synthesize settingsObservable = _settingsObservable;

- (void)setTopOffsetOfViewSize:(CGFloat)topOffset bottomOffset:(CGFloat)bottomOffset
{
    CGFloat newTopOffset = topOffset * _displayDensityFactor;
    CGFloat newBottomOffset = bottomOffset * _displayDensityFactor;
    if (_topOffset != newTopOffset || _bottomOffset != newBottomOffset)
    {
        _topOffset = newTopOffset;
        _bottomOffset = newBottomOffset;
    }
}

- (OsmAnd::PointI) getCenterPixel
{
    float viewportYScale = _viewportYScale - _bottomOffset / _viewSize.y;
    if (_viewportYScale == kViewportScale)
        viewportYScale += _topOffset / _viewSize.y;
    return OsmAnd::PointI(_viewSize.x * _viewportXScale / 2.0, _viewSize.y * viewportYScale / 2.0);
}

- (void)render:(CADisplayLink*)displayLink
{
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return;
    }

    NSTimeInterval currentTime = CACurrentMediaTime();
    if (_lastUpdateTime == 0) {
        _lastUpdateTime = currentTime;
        return;
    }
    NSTimeInterval timePassed = currentTime - _lastUpdateTime;
    _lastUpdateTime = CACurrentMediaTime();

    // Update animators
    _mapAnimator->update(timePassed);
    _mapMarkersAnimator->update(timePassed);

    // Allocate buffers if they are not yet allocated
    if (_framebuffer == 0)
    {
        if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0)
        {
            OALog(@"[OAMapRendererView %p] Can not create render&frame buffers with view size of %dx%d",
                  self,
                  (int)self.bounds.size.width,
                  (int)self.bounds.size.height);
            return;
        }

        // Allocate new buffers
        [self allocateRenderAndFrameBuffers];

        // Update size of renderer window and viewport
        _renderer->setWindowSize(_viewSize);
        _renderer->setViewport(OsmAnd::AreaI(OsmAnd::PointI(0, 0), _viewSize));
        _renderer->setMapTarget([self getCenterPixel], self.target31);
    }
    else
    {
        OsmAnd::PointI centerPixel = [self getCenterPixel];
        if (_centerPixel != centerPixel)
        {
            _centerPixel = centerPixel;
            
            // Normalize elevation angle
            [self setElevationAngle:self.elevationAngle];

            _renderer->setMapTarget(centerPixel, self.target31);
        }
    }

    if (self.rendererDelegate)
        [self.rendererDelegate frameAnimatorsUpdated];

    // Process update
    if (!_renderer->update())
    {
        [NSException raise:NSGenericException
                    format:@"Failed to update OpenGLES2+ map renderer 0x%08x", glGetError()];
        return;
    }

    if (self.rendererDelegate)
        [self.rendererDelegate frameUpdated];

    // Perform rendering only if frame is marked as invalidated
    bool shouldRenderFrame = false;
    shouldRenderFrame = shouldRenderFrame || _renderer->isFrameInvalidated();
    if (shouldRenderFrame && _renderer->prepareFrame())
    {
        // Activate framebuffer
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        validateGL();

        // Clear buffer
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        validateGL();

        const auto debugSettings = _renderer->getDebugSettings();

        // Perform rendering
        const auto metric = debugSettings->debugStageEnabled ? std::make_shared<OsmAnd::AtlasMapRenderer_Metrics::Metric_renderFrame>() : nullptr;

        if (!_renderer->renderFrame(metric.get()))
        {
            [NSException raise:NSGenericException
                        format:@"Failed to render frame using OpenGLES2+ map renderer 0x%08x", glGetError()];
            return;
        }

        if (metric)
            OALog(@"Metric_renderFrame = %@", metric->toString().toNSString());

        validateGL();

        //TODO: apply multisampling?

        // Erase depthbuffer, since not needed
        const GLenum buffersToDiscard[] =
        {
            GL_DEPTH_ATTACHMENT
        };
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        validateGL();
        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, buffersToDiscard);
        validateGL();

        // Present results
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        validateGL();
        [_glRenderContext presentRenderbuffer:GL_RENDERBUFFER];

        _frameId++;        
        if (self.rendererDelegate)
            [self.rendererDelegate frameRendered];
    }
}

- (BOOL)isRenderingSuspended
{
    return (_displayLink == nil);
}

- (void) didMoveToWindow
{
    // Resume rendering only if in foreground
    if ([self isRenderingSuspended] && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground && self.window)
    {
        [self resumeRendering];
    }
}

- (BOOL)resumeRendering
{
    if (_displayLink != nil || self.window == nil)
        return FALSE;

    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return FALSE;
    }

    // Setup display link
    _displayLink = [self.window.screen displayLinkWithTarget:self
                                               selector:@selector(render:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];

    // Resume GPU worker
    _renderer->resumeGpuWorker();

    OALog(@"[OAMapRendererView %p] Rendering resumed", self);

    return TRUE;
}

- (BOOL)suspendRendering
{
    if (_displayLink == nil)
        return FALSE;

    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2+ context 0x%08x", glGetError()];
        return FALSE;
    }

    // Release display link
    [_displayLink invalidate];
    _displayLink = nil;

    // Suspend GPU worker
    _renderer->suspendGpuWorker();

    OALog(@"[OAMapRendererView %p] Rendering suspended", self);

    return TRUE;
}

- (void)invalidateFrame
{
    _renderer->forcedFrameInvalidate();
}

- (CGFloat)referenceTileSizeOnScreenInPixels
{
    const auto configuration = std::static_pointer_cast<OsmAnd::AtlasMapRendererConfiguration>(_renderer->getConfiguration());
    return configuration->referenceTileSizeOnScreenInPixels;
}

- (void)setReferenceTileSizeOnScreenInPixels:(CGFloat)referenceTileSizeOnScreenInPixels
{
    const auto configuration = std::static_pointer_cast<OsmAnd::AtlasMapRendererConfiguration>(_renderer->getConfiguration());
    configuration->referenceTileSizeOnScreenInPixels = referenceTileSizeOnScreenInPixels;
    _renderer->setConfiguration(configuration);
}

- (BOOL) isGpuWorkerPaused
{
    return _renderer->isGpuWorkerPaused();
}

- (BOOL) suspendGpuWorker
{
    return _renderer->suspendGpuWorker();
}

- (BOOL) resumeGpuWorker
{
    return _renderer->resumeGpuWorker();
}

- (void)setSymbolsOpacity:(float)opacityFactor
{
    _renderer->setSymbolsOpacity(opacityFactor);
}

- (void)setSymbolSubsectionConfiguration:(int)subsectionIndex configuration:(const OsmAnd::SymbolSubsectionConfiguration &)configuration
{
    _renderer->setSymbolSubsectionConfiguration(subsectionIndex, configuration);
}

- (BOOL)getLocationFromElevatedPoint:(OsmAnd::PointI)screenPoint location31:(OsmAnd::PointI*)location31
{
    return _renderer->getLocationFromElevatedPoint(screenPoint, *location31);
}

- (float)getLocationHeightInMeters:(OsmAnd::PointI)location31
{
    return _renderer->getLocationHeightInMeters(location31);
}

@end
