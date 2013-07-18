//
//  UIMapRendererView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "UIMapRendererView.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#if defined(DEBUG)
#   define validateGL() [self validateOpenGLES]
#else
#   define validateGL()
#endif

@implementation UIMapRendererView
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _glContext;
    
    GLuint _depthRenderBuffer;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
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
    //[super dealloc]; // Not needed in ARC
}

- (void)ctor
{
    // Set default values
    _eaglLayer = nil;
    _glContext = nil;
    _depthRenderBuffer = 0;
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
    
    _eaglLayer = (CAEAGLLayer*)self.layer;
    
    // Set layer to be opaque to reduce perfomance loss, and anyways we use all area for rendering
    _eaglLayer.opaque = YES;
    
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
    
    // Setup render buffer (depth component)
    glGenRenderbuffers(1, &_depthRenderBuffer);
    validateGL();
    NSAssert(_depthRenderBuffer != 0, @"Failed to allocate render buffer (depth component)");
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    validateGL();
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    validateGL();
    
    // Setup render buffer (color component)
    glGenRenderbuffers(1, &_colorRenderBuffer);
    validateGL();
    NSAssert(_colorRenderBuffer != 0, @"Failed to allocate render buffer (color component)");
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();
    if(![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer])
    {
        [NSException raise:NSGenericException format:@"Failed to create render buffer (color component)"];
        return;
    }
    
    // Setup frame-buffer
    glGenFramebuffers(1, &_frameBuffer);
    validateGL();
    NSAssert(_frameBuffer != 0, @"Failed to allocate frame buffer");
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    validateGL();
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    validateGL();
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    validateGL();
    
    // Setup display link
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)dtor
{
    //TODO: release framebuffers
    
    //[_glContext release]; //NOTE: Not needed in ARC
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

- (void)render:(CADisplayLink*)displayLink
{
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClearDepthf(1.0f);
    glClearDepthf(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //draw..draw
    
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

@end
