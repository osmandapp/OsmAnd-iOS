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

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Map/IAtlasMapRenderer.h>
#include <OsmAndCore/Map/AtlasMapRendererConfiguration.h>
#include <OsmAndCore/Map/MapAnimator.h>

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
    GLuint _depthRenderBuffer;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    CADisplayLink* _displayLink;
    
    OsmAnd::PointI _viewSize;
    
    std::shared_ptr<OsmAnd::IMapRenderer> _renderer;
    std::shared_ptr<OsmAnd::MapAnimator> _animator;
    
    CGRect prevBounds;
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

- (void) awakeFromNib {
    
    [self commonInit];
}

- (void) commonInit
{
    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];
    _framePreparedObservable = [[OAObservable alloc] init];

    // Set default values
    _glShareGroup = nil;
    _glRenderContext = nil;
    _glWorkerContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    _displayLink = nil;
    
    _viewportXScale = 1.f;
    _viewportYScale = 1.f;

    // Create map renderer instance
    _renderer = OsmAnd::createMapRenderer(OsmAnd::MapRendererClass::AtlasMapRenderer_OpenGLES2);
    const auto rendererConfig = std::static_pointer_cast<OsmAnd::AtlasMapRendererConfiguration>(_renderer->getConfiguration());
    rendererConfig->texturesFilteringQuality = OsmAnd::TextureFilteringQuality::Good;
    _renderer->setConfiguration(rendererConfig);
    
    OAObservable* stateObservable = _stateObservable;
    _renderer->stateChangeObservable.attach((__bridge const void*)_stateObservable,
        [stateObservable]
        (const OsmAnd::IMapRenderer* renderer, const OsmAnd::MapRendererStateChange thisChange, const uint32_t allChanges)
        {
            [stateObservable notifyEventWithKey:[NSNumber numberWithUnsignedInteger:(OAMapRendererViewStateEntry)thisChange]];
        });

    OAObservable* framePreparedObservable = _framePreparedObservable;
    _renderer->framePreparedObservable.attach((__bridge const void*)_framePreparedObservable,
        [framePreparedObservable]
        (const OsmAnd::IMapRenderer* renderer)
        {
            [framePreparedObservable notifyEvent];
        });

    // Create animator for that map
    _animator.reset(new OsmAnd::MapAnimator());
    _animator->setMapRenderer(_renderer);
    
    auto debugSettings = [self getMapDebugSettings];
    //debugSettings->disableSymbolsFastCheckByFrustum = true;
    [self setMapDebugSettings:debugSettings];

#if defined(OSMAND_IOS_DEV)
    _forceRenderingOnEachFrame = NO;
#endif // defined(OSMAND_IOS_DEV)
}

- (void)deinit
{
    // Just to be sure, try to release context
    [self releaseContext];
    
    // Unregister observer
    _renderer->stateChangeObservable.detach((__bridge const void*)_stateObservable);
    _renderer->framePreparedObservable.detach((__bridge const void*)_framePreparedObservable);
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

- (void)setElevationAngle:(float)elevationAngle
{
    _renderer->setElevationAngle(elevationAngle);
}

- (OsmAnd::PointI)target31
{
    return _renderer->getState().target31;
}

- (void)setTarget31:(OsmAnd::PointI)target31
{
    _renderer->setTarget(target31);
}

- (float)zoom
{
    return _renderer->getState().zoomLevel + (_renderer->getState().visualZoom >= 1.0f ? _renderer->getState().visualZoom - 1.0f : (_renderer->getState().visualZoom - 1.0f) * 2.0f);
}

- (void)setZoom:(float)zoom
{
    _renderer->setZoom(zoom);
}

- (OsmAnd::ZoomLevel)zoomLevel
{
    return _renderer->getState().zoomLevel;
}

- (float)currentTileSizeOnScreenInPixels
{
    return std::dynamic_pointer_cast<OsmAnd::IAtlasMapRenderer>(_renderer)->getCurrentTileSizeOnScreenInPixels();
}


- (float)currentTileSizeOnScreenInMeters
{
    return _renderer->getCurrentTileSizeInMeters();
    
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

- (QVector<OsmAnd::TileId>)visibleTiles
{
    return std::dynamic_pointer_cast<OsmAnd::IAtlasMapRenderer>(_renderer)->getVisibleTiles();
}

- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location
{
    if (!location)
        return NO;
    return _renderer->getLocationFromScreenPoint(OsmAnd::PointI(static_cast<int32_t>(point.x), static_cast<int32_t>(point.y)), *location);
}

- (BOOL)convert:(CGPoint)point toLocation64:(OsmAnd::PointI64*)location
{
    if (!location)
        return NO;
    return _renderer->getLocationFromScreenPoint(OsmAnd::PointI(static_cast<int32_t>(point.x), static_cast<int32_t>(point.y)), *location);
}

// virtual bool obtainScreenPointFromPosition(const PointI64& position, PointI& outScreenPoint) const = 0;
// virtual bool obtainScreenPointFromPosition(const PointI& position31, PointI& outScreenPoint) const = 0;

- (BOOL)convert:(OsmAnd::PointI*)pos toScreen:(CGPoint*)point checkOffScreen:(BOOL)offScreen
{
    if (!pos)
        return NO;
    OsmAnd::PointI _point(0, 0);
    BOOL res = _renderer->obtainScreenPointFromPosition(*pos, _point, offScreen);
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

- (BOOL)convert:(OsmAnd::PointI64*)pos64 toScreen64:(CGPoint*)point
{
    if (!pos64)
        return NO;
    OsmAnd::PointI _point(0, 0);
    BOOL res = _renderer->obtainScreenPointFromPosition(*pos64, _point);
    if (res) {
        point->x = _point.x / [UIScreen mainScreen].scale;
        point->y = _point.y / [UIScreen mainScreen].scale;
    }
    return res;
}

- (OsmAnd::AreaI)getVisibleBBox31
{
    return _renderer->getVisibleBBox31();
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

- (void)dumpResourcesInfo
{
    _renderer->dumpResourcesInfo();
}

@synthesize framePreparedObservable = _framePreparedObservable;

- (const std::shared_ptr<OsmAnd::MapAnimator>&)getAnimator
{
    return _animator;
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
    
    // Create OpenGLES 2.0 contexts
    _glRenderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_glRenderContext)
    {
        [NSException raise:NSGenericException
                    format:@"Failed to initialize OpenGLES 2.0 render context 0x%08x", glGetError()];
        return;
    }
    _glShareGroup = [_glRenderContext sharegroup];
    if (!_glShareGroup)
    {
        [NSException raise:NSGenericException
                    format:@"Failed to initialize OpenGLES 2.0 render context has no sharegroup 0x%08x", glGetError()];
        return;
    }
    _glWorkerContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_glShareGroup];
    if (!_glWorkerContext)
    {
        [NSException raise:NSGenericException
                    format:@"Failed to initialize OpenGLES 2.0 worker context 0x%08x", glGetError()];
        return;
    }
    
    // Set created context as current active
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
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
                            format:@"Failed to set current OpenGLES2 context in GPU worker thread 0x%08x", glGetError()];
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
    if (!_renderer->initializeRendering())
    {
        [NSException raise:NSGenericException
                    format:@"Failed to initialize OpenGLES2 map renderer 0x%08x", glGetError()];
        return;
    }
    
    // Rendering needs to be resumed/started manually, since render target is not created yet
}

- (void)releaseContext
{
    if (_glShareGroup == nil)
        return;

    OALog(@"[OAMapRendererView %p] Releasing context", self);

    // Stop rendering (if it was running)
    [self suspendRendering];
    
    // Release map renderer
    if (!_renderer->releaseRendering())
    {
        [NSException raise:NSGenericException
                    format:@"Failed to release OpenGLES2 map renderer 0x%08x", glGetError()];
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
    
    OALog(@"[OAMapRendererView %p] Recreating OpenGLES2 frame and render buffers due to resize", self);

    // Kill buffers, since window was resized
    [self releaseRenderAndFrameBuffers];
}

- (void) setViewportXScale:(float)viewportXScale
{
    _viewportXScale = viewportXScale;

    // Kill buffers, since viewport was resized
    [self releaseRenderAndFrameBuffers];
}

- (void) setViewportYScale:(float)viewportYScale
{
    _viewportYScale = viewportYScale;
    
    // Kill buffers, since viewport was resized
    [self releaseRenderAndFrameBuffers];
}

- (void) setSkyColor:(OsmAnd::FColorRGB)skyColor
{
    _renderer->setSkyColor(skyColor);
}

- (void) allocateRenderAndFrameBuffers
{
    OALog(@"[OAMapRendererView %p] Allocating render and frame buffers", self);

    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
        return;
    }
    
    // Setup frame-buffer
    glGenFramebuffers(1, &_frameBuffer);
    validateGL();
    NSAssert(_frameBuffer != 0, @"Failed to allocate frame buffer");
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    validateGL();
    
    // Setup render buffer (color component)
    glGenRenderbuffers(1, &_colorRenderBuffer);
    validateGL();
    NSAssert(_colorRenderBuffer != 0, @"Failed to allocate render buffer (color component)");
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
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
        return;
    }
    
    if (_frameBuffer != 0)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
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

- (void)render:(CADisplayLink*)displayLink
{
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
        return;
    }
    
    // Update animator
    _animator->update(displayLink.duration * displayLink.frameInterval);
    
    // Allocate buffers if they are not yet allocated
    if (_frameBuffer == 0)
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
        BOOL isYScaleDown = _viewportYScale < 1.0;
        BOOL isXScaleDown = _viewportXScale < 1.0;
        float correctedX = isXScaleDown ? -_viewSize.x * _viewportXScale : 0;
        float correctedY = isYScaleDown ? -_viewSize.y * _viewportYScale : 0;
        _renderer->setViewport(OsmAnd::AreaI(OsmAnd::PointI(correctedX, correctedY),
                                             OsmAnd::PointI(_viewSize.x * (isXScaleDown ? 1.0 :_viewportXScale),
                                                            _viewSize.y * (isYScaleDown ? 1.0 :_viewportYScale))));
    }
    
    // Process update
    if (!_renderer->update())
    {
        [NSException raise:NSGenericException
                    format:@"Failed to update OpenGLES2 map renderer 0x%08x", glGetError()];
        return;
    }
    
    // Perform rendering only if frame is marked as invalidated
    bool shouldRenderFrame = false;
    shouldRenderFrame = shouldRenderFrame || _renderer->isFrameInvalidated();
#if defined(OSMAND_IOS_DEV)
    shouldRenderFrame = shouldRenderFrame || _forceRenderingOnEachFrame;
#endif // defined(OSMAND_IOS_DEV)
    if (shouldRenderFrame && _renderer->prepareFrame())
    {
        // Activate framebuffer
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        validateGL();
    
        // Clear buffer
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        validateGL();

        // Perform rendering
        if (!_renderer->renderFrame())
        {
            [NSException raise:NSGenericException
                        format:@"Failed to render frame using OpenGLES2 map renderer 0x%08x", glGetError()];
            return;
        }
        validateGL();
    
        //TODO: apply multisampling?
    
        // Erase depthbuffer, since not needed
        const GLenum buffersToDiscard[] =
        {
            GL_DEPTH_ATTACHMENT
        };
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        validateGL();
        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, buffersToDiscard);
        validateGL();
    
        // Present results
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
        validateGL();
        [_glRenderContext presentRenderbuffer:GL_RENDERBUFFER];
        
        if (self.rendererDelegate)
            [self.rendererDelegate frameRendered];
    }
}

- (BOOL)isRenderingSuspended
{
    return (_displayLink == nil);
}

- (BOOL)resumeRendering
{
    if (_displayLink != nil)
        return FALSE;
    
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
        return FALSE;
    }
    
    // Setup display link
    _displayLink = [CADisplayLink displayLinkWithTarget:self
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
                    format:@"Failed to set current OpenGLES2 context 0x%08x", glGetError()];
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

- (UIImage*) getGLScreenshot {

    int s = (int) [[UIScreen mainScreen] scale];
    const int w = self.frame.size.width;
    const int h = self.frame.size.height;
    
    const NSInteger myDataLength = w * h * 4 * s * s;
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, w*s, h*s, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    // gl renders "upside down" so swap top to bottom into new array.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y < h*s; y++)
    {
        memcpy( buffer2 + (h*s - 1 - y) * w * 4 * s, buffer + (y * 4 * w * s), w * 4 * s );
    }
    free(buffer); // work with the flipped buffer, so get rid of the original one.
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * w * s;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(w*s, h*s, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [ UIImage imageWithCGImage:imageRef scale:s orientation:UIImageOrientationUp ];

    CGImageRelease( imageRef );
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    //free(buffer2);
    
    return myImage;
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


#if defined(OSMAND_IOS_DEV)
@synthesize forceRenderingOnEachFrame = _forceRenderingOnEachFrame;
- (void)setForceRenderingOnEachFrame:(BOOL)forceRenderingOnEachFrame
{
    _forceRenderingOnEachFrame = forceRenderingOnEachFrame;

    [_settingsObservable notifyEvent];
}
#endif // defined(OSMAND_IOS_DEV)

@end
