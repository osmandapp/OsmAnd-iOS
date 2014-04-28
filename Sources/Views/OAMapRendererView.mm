//
//  OAMapRendererView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererView.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Map/MapAnimator.h>

#import "OALog.h"

#if defined(DEBUG)
#   define validateGL() [self validateOpenGLES]
#else
#   define validateGL()
#endif

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
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _stateObservable = [[OAObservable alloc] init];
    _settingsObservable = [[OAObservable alloc] init];

    _forcedRenderingOnEachFrame = NO;
    
    // Set default values
    _glShareGroup = nil;
    _glRenderContext = nil;
    _glWorkerContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    _displayLink = nil;
    
    // Create map renderer instance
    _renderer = OsmAnd::createMapRenderer(OsmAnd::MapRendererClass::AtlasMapRenderer_OpenGLES2);
    
    OsmAnd::MapRendererConfiguration rendererConfig;
    rendererConfig.texturesFilteringQuality = OsmAnd::TextureFilteringQuality::Good;
    _renderer->setConfiguration(rendererConfig);
    OAObservable* stateObservable = _stateObservable;
    _renderer->stateChangeObservable.attach((__bridge const void*)_stateObservable,
        [stateObservable](const OsmAnd::MapRendererStateChange thisChange, const uint32_t allChanges){
            [stateObservable notifyEventWithKey:[NSNumber numberWithUnsignedInteger:(OAMapRendererViewStateEntry)thisChange]];
        });
    
    // Create animator for that map
    _animator.reset(new OsmAnd::MapAnimator());
    _animator->setMapRenderer(_renderer);
}

- (void)dtor
{
    // Just to be sure, try to release context
    [self releaseContext];
    
    // Unregister observer
    _renderer->stateChangeObservable.detach((__bridge const void*)_stateObservable);
}

- (std::shared_ptr<OsmAnd::IMapBitmapTileProvider>)providerOf:(OsmAnd::RasterMapLayerId)layer
{
    return _renderer->state.rasterLayerProviders[static_cast<int>(layer)];
}

- (void)setProvider:(std::shared_ptr<OsmAnd::IMapBitmapTileProvider>)provider ofLayer:(OsmAnd::RasterMapLayerId)layer
{
    _renderer->setRasterLayerProvider(layer, provider);
}

- (void)removeProviderOf:(OsmAnd::RasterMapLayerId)layer
{
    _renderer->setRasterLayerProvider(layer, std::shared_ptr<OsmAnd::IMapBitmapTileProvider>());
}

- (float)opacityOf:(OsmAnd::RasterMapLayerId)layer
{
    return _renderer->state.rasterLayerOpacity[static_cast<int>(layer)];
}

- (void)setOpacity:(float)opacity ofLayer:(OsmAnd::RasterMapLayerId)layer
{
    _renderer->setRasterLayerOpacity(layer, opacity);
}

- (std::shared_ptr<OsmAnd::IMapElevationDataProvider>)elevationDataProvider
{
    return _renderer->state.elevationDataProvider;
}

- (void)setElevationDataProvider:(std::shared_ptr<OsmAnd::IMapElevationDataProvider>)elevationDataProvider
{
    _renderer->setElevationDataProvider(elevationDataProvider);
}

- (float)elevationDataScale
{
    return _renderer->state.elevationDataScaleFactor;
}

- (void)removeElevationDataProvider
{
    _renderer->setElevationDataProvider(std::shared_ptr<OsmAnd::IMapElevationDataProvider>());
}

- (void)setElevationDataScale:(float)elevationDataScale
{
    _renderer->setElevationDataScaleFactor(elevationDataScale);
}

- (void)addSymbolProvider:(std::shared_ptr<OsmAnd::IMapSymbolProvider>)provider
{
    _renderer->addSymbolProvider(provider);
}

- (void)removeSymbolProvider:(std::shared_ptr<OsmAnd::IMapSymbolProvider>)provider
{
    _renderer->removeSymbolProvider(provider);
}

- (void)removeAllSymbolProviders
{
    _renderer->removeAllSymbolProviders();
}

- (float)fieldOfView
{
    return _renderer->state.fieldOfView;
}

- (void)setFieldOfView:(float)fieldOfView
{
    _renderer->setFieldOfView(fieldOfView);
}

- (float)azimuth
{
    return _renderer->state.azimuth;
}

- (void)setAzimuth:(float)azimuth
{
    _renderer->setAzimuth(azimuth);
}

- (float)elevationAngle
{
    return _renderer->state.elevationAngle;
}

- (void)setElevationAngle:(float)elevationAngle
{
    _renderer->setElevationAngle(elevationAngle);
}

- (OsmAnd::PointI)target31
{
    return _renderer->state.target31;
}

- (void)setTarget31:(OsmAnd::PointI)target31
{
    _renderer->setTarget(target31);
}

- (float)zoom
{
    return _renderer->state.requestedZoom;
}

- (void)setZoom:(float)zoom
{
    _renderer->setZoom(zoom);
}

- (OsmAnd::ZoomLevel)zoomLevel
{
    return _renderer->state.zoomBase;
}

- (float)scaledTileSizeOnScreen
{
    return _renderer->getScaledTileSizeOnScreen();
}

- (float)minZoom
{
    return _renderer->getMinZoom();
}

- (float)maxZoom
{
    return _renderer->getMaxZoom();
}

@synthesize stateObservable = _stateObservable;

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

- (void)cancelAnimation
{
    _animator->cancelAnimation();
}

- (void)resumeAnimation
{
    _animator->resumeAnimation();
}

- (void)animateZoomWith:(float)velocity andDeceleration:(float)deceleration
{
    _animator->animateZoomWith(velocity, deceleration);
}

- (void)animateZoomBy:(float)deltaValue during:(float)duration timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateZoomBy(deltaValue, duration, static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateTargetWith:(OsmAnd::PointD)velocity andDeceleration:(OsmAnd::PointD)deceleration
{
    _animator->animateTargetWith(velocity, deceleration);
}

- (void)animateTargetBy:(OsmAnd::PointI)deltaValue during:(float)duration timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateTargetBy(deltaValue, duration, static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateTargetBy64:(OsmAnd::PointI64)deltaValue during:(float)duration timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateTargetBy(deltaValue, duration, static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)parabolicAnimateTargetWith:(OsmAnd::PointD)velocity andDeceleration:(OsmAnd::PointD)deceleration
{
    _animator->parabolicAnimateTargetWith(velocity, deceleration);
}

- (void)parabolicAnimateTargetBy:(OsmAnd::PointI)deltaValue
                          during:(float)duration
                    targetTiming:(OAMapAnimationTimingFunction)targetTimingFunction
                      zoomTiming:(OAMapAnimationTimingFunction)zoomTimingFunction
{
    _animator->parabolicAnimateTargetBy(deltaValue,
                                        duration,
                                        static_cast<OsmAnd::MapAnimatorTimingFunction>(targetTimingFunction),
                                        static_cast<OsmAnd::MapAnimatorTimingFunction>(zoomTimingFunction));
}

- (void)parabolicAnimateTargetBy64:(OsmAnd::PointI64)deltaValue
                            during:(float)duration
                      targetTiming:(OAMapAnimationTimingFunction)targetTimingFunction
                        zoomTiming:(OAMapAnimationTimingFunction)zoomTimingFunction
{
    _animator->parabolicAnimateTargetBy(deltaValue,
                                        duration,
                                        static_cast<OsmAnd::MapAnimatorTimingFunction>(targetTimingFunction),
                                        static_cast<OsmAnd::MapAnimatorTimingFunction>(zoomTimingFunction));
}

- (void)animateAzimuthWith:(float)velocity andDeceleration:(float)deceleration
{
    _animator->animateAzimuthWith(velocity, deceleration);
}

- (void)animateAzimuthBy:(float)deltaValue during:(float)duration timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateAzimuthBy(deltaValue, duration, static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateElevationAngleWith:(float)velocity andDeceleration:(float)deceleration
{
    _animator->animateElevationAngleWith(velocity, deceleration);
}

- (void)animateElevationAngleBy:(float)deltaValue during:(float)duration timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateElevationAngleBy(deltaValue, duration, static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateMoveBy:(OsmAnd::PointI)deltaValue
               during:(float)duration
       zeroizeAzimuth:(BOOL)zeroizeAzimuth
invZeroizeElevationAngle:(BOOL)invZeroizeElevationAngle
               timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateMoveBy(deltaValue,
                             duration,
                             static_cast<bool>(zeroizeAzimuth),
                             static_cast<bool>(invZeroizeElevationAngle),
                             static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateMoveBy64:(OsmAnd::PointI64)deltaValue
                 during:(float)duration
         zeroizeAzimuth:(BOOL)zeroizeAzimuth
invZeroizeElevationAngle:(BOOL)invZeroizeElevationAngle
                 timing:(OAMapAnimationTimingFunction)function
{
    _animator->animateMoveBy(deltaValue,
                             duration,
                             static_cast<bool>(zeroizeAzimuth),
                             static_cast<bool>(invZeroizeElevationAngle),
                             static_cast<OsmAnd::MapAnimatorTimingFunction>(function));
}

- (void)animateMoveWith:(OsmAnd::PointD)velocity
        andDeceleration:(OsmAnd::PointD)deceleration
         zeroizeAzimuth:(BOOL)zeroizeAzimuth
invZeroizeElevationAngle:(BOOL)invZeroizeElevationAngle
{
    _animator->animateMoveWith(velocity, deceleration, zeroizeAzimuth, invZeroizeElevationAngle);
}

- (void)createContext
{
    if (_glShareGroup != nil)
        return;

#if defined(DEBUG)
    OALog(@"[MapRenderView] Creating context");
#endif
    
    // Set layer to be opaque to reduce perfomance loss, and anyways we use all area for rendering
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = YES;
    
    // Create OpenGLES 2.0 contexts
    _glRenderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_glRenderContext)
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES 2.0 render context"];
        return;
    }
    _glShareGroup = [_glRenderContext sharegroup];
    if (!_glShareGroup)
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES 2.0 render context has no sharegroup"];
        return;
    }
    _glWorkerContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_glShareGroup];
    if (!_glWorkerContext)
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES 2.0 worker context"];
        return;
    }
    
    // Set created context as current active
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return;
    }
    
    OsmAnd::MapRendererSetupOptions rendererSetup;
    rendererSetup.displayDensityFactor = self.contentScaleFactor;
    rendererSetup.gpuWorkerThreadEnabled = true;
    const auto capturedWorkerContext = _glWorkerContext;
    rendererSetup.gpuWorkerThreadPrologue = [capturedWorkerContext](const OsmAnd::IMapRenderer* const renderer)
    {
        // Activate worker context
        if (![EAGLContext setCurrentContext:capturedWorkerContext])
        {
            [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context in GPU worker thread"];
            return;
        }
    };
    rendererSetup.gpuWorkerThreadEpilogue = [](const OsmAnd::IMapRenderer* const renderer)
    {
        // Nothing to do
    };
    _renderer->setup(rendererSetup);

    // Initialize rendering
    if (!_renderer->initializeRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES2 map renderer"];
        return;
    }
    
    // Rendering needs to be resumed/started manually, since render target is not created yet
}

- (void)releaseContext
{
    if (_glShareGroup == nil)
        return;

#if defined(DEBUG)
    OALog(@"[MapRenderView] Releasing context");
#endif
    
    // Stop rendering (if it was running)
    [self suspendRendering];
    
    // Release map renderer
    if (!_renderer->releaseRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to release OpenGLES2 map renderer"];
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
#if defined(DEBUG)
    OALog(@"[MapRenderView] Recreating OpenGLES2 frame and render buffers due to resize");
#endif

    // Kill buffers, since window was resized
    [self releaseRenderAndFrameBuffers];
}

- (void)allocateRenderAndFrameBuffers
{
#if defined(DEBUG)
    OALog(@"[MapRenderView] Allocating render and frame buffers");
#endif
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
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
        [NSException raise:NSGenericException format:@"Failed to create render buffer (color component)"];
        return;
    }
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewSize.x);
    validateGL();
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewSize.y);
    validateGL();
#if defined(DEBUG)
    OALog(@"[MapRenderView] View size %dx%d", _viewSize.x, _viewSize.y);
#endif
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
        [NSException raise:NSGenericException format:@"Failed to make complete framebuffer (0x%08x)", glCheckFramebufferStatus(GL_FRAMEBUFFER)];
        return;
    }
    validateGL();
}

- (void)releaseRenderAndFrameBuffers
{
#if defined(DEBUG)
    OALog(@"[MapRenderView] Releasing render and frame buffers");
#endif
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
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

@synthesize forcedRenderingOnEachFrame = _forcedRenderingOnEachFrame;
- (void)setForcedRenderingOnEachFrame:(BOOL)forcedRenderingOnEachFrame
{
    _forcedRenderingOnEachFrame = forcedRenderingOnEachFrame;

    [_settingsObservable notifyEvent];
}

- (void)render:(CADisplayLink*)displayLink
{
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return;
    }
    
    // Update animator
    _animator->update(displayLink.duration * displayLink.frameInterval);
    
    // Allocate buffers if they are not yet allocated
    if (_frameBuffer == 0)
    {
        // Allocate new buffers
        [self allocateRenderAndFrameBuffers];
        
        // Update size of renderer window and viewport
        _renderer->setWindowSize(_viewSize);
        _renderer->setViewport(OsmAnd::AreaI(OsmAnd::PointI(), _viewSize));
    }
    
    // Process rendering
    if (!_renderer->processRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to process rendering using OpenGLES2 map renderer"];
        return;
    }
    
    // Perform rendering only if frame is marked as invalidated
    if (_renderer->prepareFrame() && (_renderer->isFrameInvalidated() || _forcedRenderingOnEachFrame))
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
            [NSException raise:NSGenericException format:@"Failed to render frame using OpenGLES2 map renderer"];
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return FALSE;
    }
    
    // Setup display link
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
#if defined(DEBUG)
    OALog(@"[MapRenderView] Rendering resumed");
#endif
    
    return TRUE;
}

- (BOOL)suspendRendering
{
    if (_displayLink == nil)
        return FALSE;
    
    if (![EAGLContext setCurrentContext:_glRenderContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return FALSE;
    }
    
    // Release display link
    [_displayLink invalidate];
    _displayLink = nil;
    
#if defined(DEBUG)
    OALog(@"[MapRenderView] Rendering suspended");
#endif
    
    return TRUE;
}

@end
