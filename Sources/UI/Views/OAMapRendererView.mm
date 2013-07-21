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
    
    int _viewWidth;
    int _viewHeight;
    
    std::shared_ptr<OsmAnd::IMapRenderer> _mapRenderer;
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
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)ctor
{
    // Set default values
    _glContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    _displayLink = nil;
}

- (void)dtor
{
    // Just to be sure, try to release context
    [self releaseContext];
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
        return;
    }
    
    // Create OpenGLES map renderer
    _mapRenderer = OsmAnd::createAtlasMapRenderer_OpenGLES2();
    
    // Rendering needs to be resumed/started manually, since render target is created yet
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
    _mapRenderer.reset();
    
    // Release render-buffers and framebuffer
    [self releaseRenderAndFrameBuffers];
    
    // Tear down context
    if([EAGLContext currentContext] == _glContext)
        [EAGLContext setCurrentContext:nil];
#if !__has_feature(objc_arc)
    [_glContext release];
#endif
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
    NSLog(@"[MapRenderView] Recreating OpenGLES frame and render buffers due to resize");
#endif
    
    //BOOL wasSuspended = [self suspendRendering];
    
    // Recreate render and frame buffers since view has resized
    [self releaseRenderAndFrameBuffers];
    [self allocateRenderAndFrameBuffers];
    
    //if(wasSuspended)
    //    [self resumeRendering];
}

- (void)allocateRenderAndFrameBuffers
{
#if defined(DEBUG)
    NSLog(@"[MapRenderView] Allocating render and frame buffers");
#endif
    if(![EAGLContext setCurrentContext:_glContext])
    {
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
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
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewWidth);
    validateGL();
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewHeight);
    validateGL();
#if defined(DEBUG)
    NSLog(@"[MapRenderView] View size %dx%d", _viewWidth, _viewHeight);
#endif
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();

    // Setup render buffer (depth component)
    glGenRenderbuffers(1, &_depthRenderBuffer);
    validateGL();
    NSAssert(_depthRenderBuffer != 0, @"Failed to allocate render buffer (depth component)");
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    validateGL();
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, _viewWidth, _viewHeight);
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
        return;
    }
    
    // Activate framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    validateGL();

    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    glClearDepthf(1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    validateGL();
    
    //draw..draw
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
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
        [NSException raise:NSGenericException format:@"Failed to set current OpenGLES context"];
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
