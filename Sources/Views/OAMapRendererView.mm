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

#include <OsmAndCore.h>
#include <OsmAndCore/Map/IMapRenderer.h>

#if defined(DEBUG)
#   define validateGL() [self validateOpenGLES]
#else
#   define validateGL()
#endif

@implementation OAMapRendererView
{
    EAGLContext* _glContext;
    GLuint _depthRenderBuffer;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    CADisplayLink* _displayLink;
    
    OsmAnd::PointI _viewSize;
    
    std::shared_ptr<OsmAnd::IMapRenderer> _renderer;
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
    // Set default values
    _glContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    _displayLink = nil;
    
    // Create map renderer instance
    _renderer = OsmAnd::createAtlasMapRenderer_OpenGLES2();
    
    OsmAnd::MapRendererConfiguration rendererConfig;
    rendererConfig.altasTexturesAllowed = false;
    rendererConfig.texturesFilteringQuality = OsmAnd::TextureFilteringQuality::Good;
    _renderer->setConfiguration(rendererConfig);
}

- (void)dtor
{
    // Just to be sure, try to release context
    [self releaseContext];
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

- (CGFloat)opacityOf:(OsmAnd::RasterMapLayerId)layer
{
    return _renderer->state.rasterLayerOpacity[static_cast<int>(layer)];
}

- (void)setOpacity:(CGFloat)opacity ofLayer:(OsmAnd::RasterMapLayerId)layer
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

- (CGFloat)elevationDataScale
{
    return _renderer->state.elevationDataScaleFactor;
}

- (void)removeElevationDataProvider
{
    _renderer->setElevationDataProvider(std::shared_ptr<OsmAnd::IMapElevationDataProvider>());
}

- (void)setElevationDataScale:(CGFloat)elevationDataScale
{
    _renderer->setElevationDataScaleFactor(elevationDataScale);
}

- (CGFloat)fieldOfView
{
    return _renderer->state.fieldOfView;
}

- (void)setFieldOfView:(CGFloat)fieldOfView
{
    _renderer->setFieldOfView(fieldOfView);
}

- (CGFloat)azimuth
{
    return _renderer->state.azimuth;
}

- (void)setAzimuth:(CGFloat)azimuth
{
    _renderer->setAzimuth(azimuth);
}

- (CGFloat)elevationAngle
{
    return _renderer->state.elevationAngle;
}

- (void)setElevationAngle:(CGFloat)elevationAngle
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

- (CGFloat)zoom
{
    return _renderer->state.requestedZoom;
}

- (void)setZoom:(CGFloat)zoom
{
    _renderer->setZoom(zoom);
}

- (OsmAnd::ZoomLevel)zoomLevel
{
    return _renderer->state.zoomBase;
}

- (CGFloat)scaledTileSizeOnScreen
{
    return _renderer->getScaledTileSizeOnScreen();
}

- (BOOL)convert:(CGPoint)point toLocation:(OsmAnd::PointI*)location
{
    if(!location)
        return NO;
    return _renderer->getLocationFromScreenPoint(OsmAnd::PointI(static_cast<int32_t>(point.x), static_cast<int32_t>(point.y)), *location);
}

- (void)createContext
{
    if(_glContext != nil)
        return;

#if defined(DEBUG)
    NSLog(@"[MapRenderView] Creating context");
#endif
    
    // Set layer to be opaque to reduce perfomance loss, and anyways we use all area for rendering
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = YES;
    
    // Create OpenGLES 2.0 context
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!_glContext)
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES 2.0 context"];
        return;
    }
    
    // Set created context as current active
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return;
    }
    
    OsmAnd::MapRendererSetupOptions rendererSetup;
    rendererSetup.displayDensityFactor = self.contentScaleFactor;
    //TODO: enable background worker
    _renderer->setup(rendererSetup);

    // Initialize rendering
    if(!_renderer->initializeRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to initialize OpenGLES2 map renderer"];
        return;
    }
    
    // Rendering needs to be resumed/started manually, since render target is not created yet
}

- (void)releaseContext
{
    if(_glContext == nil)
        return;

#if defined(DEBUG)
    NSLog(@"[MapRenderView] Releasing context");
#endif
    
    // Stop rendering (if it was running)
    [self suspendRendering];
    
    // Release map renderer
    if(!_renderer->releaseRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to release OpenGLES2 map renderer"];
        return;
    }
    
    // Release render-buffers and framebuffer
    [self releaseRenderAndFrameBuffers];
    
    // Tear down context
    if([EAGLContext currentContext] == _glContext)
        [EAGLContext setCurrentContext:nil];
    _glContext = nil;
}

#if defined(DEBUG)
- (GLenum)validateOpenGLES
{
    GLenum result = glGetError();
    if(result == GL_NO_ERROR)
        return result;
    
    NSLog(@"OpenGLES error 0x%08x", result);
    
    return result;
}
#endif

- (void)layoutSubviews
{
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Recreating OpenGLES2 frame and render buffers due to resize");
#endif

    // Kill buffers, since window was resized
    [self releaseRenderAndFrameBuffers];
}

- (void)allocateRenderAndFrameBuffers
{
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Allocating render and frame buffers");
#endif
    if(![EAGLContext setCurrentContext:_glContext])
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
    if(![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer])
    {
        [NSException raise:NSGenericException format:@"Failed to create render buffer (color component)"];
        return;
    }
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewSize.x);
    validateGL();
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewSize.y);
    validateGL();
#if defined(DEBUG)
    NSLog(@"[MapRenderView] View size %dx%d", _viewSize.x, _viewSize.y);
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
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        [NSException raise:NSGenericException format:@"Failed to make complete framebuffer (0x%08x)", glCheckFramebufferStatus(GL_FRAMEBUFFER)];
        return;
    }
    validateGL();
}

- (void)releaseRenderAndFrameBuffers
{
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Releasing render and frame buffers");
#endif
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return;
    }
    
    if(_frameBuffer != 0)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
        validateGL();
    }
    if(_colorRenderBuffer != 0)
    {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
        validateGL();
    }
    if(_depthRenderBuffer != 0)
    {
        glDeleteRenderbuffers(1, &_depthRenderBuffer);
        _depthRenderBuffer = 0;
        validateGL();
    }
}

- (void)render:(CADisplayLink*)displayLink
{
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return;
    }
    
    // Allocate buffers if they are not yet allocated
    if(_frameBuffer == 0)
    {
        // Allocate new buffers
        [self allocateRenderAndFrameBuffers];
        
        // Update size of renderer window and viewport
        _renderer->setWindowSize(_viewSize);
        _renderer->setViewport(OsmAnd::AreaI(OsmAnd::PointI(), _viewSize));
    }
    
    // Process rendering
    if(!_renderer->processRendering())
    {
        [NSException raise:NSGenericException format:@"Failed to process rendering using OpenGLES2 map renderer"];
        return;
    }
    
    // Perform rendering only if frame is marked as invalidated
    if(_renderer->prepareFrame() && (_renderer->frameInvalidated || true))
    {
        // Activate framebuffer
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        validateGL();
    
        // Clear buffer
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        validateGL();

        // Perform rendering
        if(!_renderer->renderFrame())
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
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (BOOL)isRenderingSuspended
{
    return (_displayLink == nil);
}

- (BOOL)resumeRendering
{
    if(_displayLink != nil)
        return FALSE;
    
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return FALSE;
    }
    
    // Setup display link
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Rendering resumed");
#endif
    
    return TRUE;
}

- (BOOL)suspendRendering
{
    if(_displayLink == nil)
        return FALSE;
    
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES2 context"];
        return FALSE;
    }
    
    // Release display link
    [_displayLink invalidate];
    _displayLink = nil;
    
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Rendering suspended");
#endif
    
    return TRUE;
}

@end
