//
//  OAObserver.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAutoObserverProxy.h"
#import "OAObservableProtocol.h"

#include <objc/message.h>

#define _(name) OAAutoObserverProxy__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@implementation OAAutoObserverProxy
{
    NSObject* _lock;
}

@synthesize owner = _owner;
@synthesize handler = _handler;

- (instancetype)initWith:(id<OAObserverProtocol>)owner
{
    self = [super init];
    if (self) {
        [self commonInit:owner
           handler:nil];
    }
    return self;
}

- (instancetype)initWith:(id<OAObserverProtocol>)owner
              andObserve:(id<OAObservableProtocol>)observable
{
    self = [super init];
    if (self) {
        [self commonInit:owner
           handler:nil];
        [self observe:observable];
    }
    return self;
}

- (instancetype)initWith:(id)owner
             withHandler:(SEL)selector
{
    self = [super init];
    if (self) {
        [self commonInit:owner
           handler:selector];
    }
    return self;
}

- (instancetype)initWith:(id)owner
             withHandler:(SEL)selector
              andObserve:(id<OAObservableProtocol>)observable;
{
    self = [super init];
    if (self) {
        [self commonInit:owner
           handler:selector];
        [self observe:observable];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit:(id)owner
     handler:(SEL)selector
{
    _lock = [[NSObject alloc] init];
    _owner = owner;
    _handler = selector;
    _observable = nil;
}

- (void)deinit
{
    [self detach];
}

@synthesize observable = _observable;

- (void)observe:(id<OAObservableProtocol>)observable
{
    @synchronized(_lock)
    {
        [self detach];

        _observable = observable;
        [_observable registerObserver:self];
    }
}

- (void)handleObservedEvent
{
    [self handleObservedEventFrom:nil];
}

- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer
{
    [self handleObservedEventFrom:observer
                          withKey:nil];
}

- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer
                        withKey:(id)key
{
    [self handleObservedEventFrom:observer
                          withKey:key
                         andValue:nil];
}

- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer
                        withKey:(id)key
                       andValue:(id)value
{
    id owner = _owner;
    if (owner == nil)
        return;

    if (_handler != nil)
    {
        NSMethodSignature* handlerSignature = [owner methodSignatureForSelector:_handler];
        NSAssert(handlerSignature != nil, @"Whoa! Something is messed up with selector %@ in %@", NSStringFromSelector(_handler), owner);
        NSUInteger handlerArgsCount = [handlerSignature numberOfArguments] - 2; // Subtract "self" and "cmd_"

        if (handlerArgsCount == 3)
        {
            ((void (*)(id, SEL, id, id, id))objc_msgSend)(owner, _handler, observer, key, value);
            return;
        }
        
        if (handlerArgsCount == 2)
        {
            ((void (*)(id, SEL, id, id))objc_msgSend)(owner, _handler, observer, key);
            return;
        }
        
        if (handlerArgsCount == 1)
        {
            ((void (*)(id, SEL, id))objc_msgSend)(owner, _handler, observer);
            return;
        }
        
        ((void (*)(id, SEL))objc_msgSend)(owner, _handler);
        return;
    }
    
    if ([owner respondsToSelector:@selector(handleObservedEventFrom:withKey:andValue:)])
    {
        [owner handleObservedEventFrom:observer
                               withKey:key
                              andValue:value];
        return;
    }
    
    if ([owner respondsToSelector:@selector(handleObservedEventFrom:withKey:)])
    {
        [owner handleObservedEventFrom:observer
                               withKey:key];
        return;
    }
    
    if ([owner respondsToSelector:@selector(handleObservedEventFrom:)])
    {
        [owner handleObservedEventFrom:observer];
        return;
    }
    
    [owner handleObservedEvent];
}

- (BOOL)isAttached
{
    return (_observable != nil);
}

- (BOOL)detach
{
    @synchronized(_lock)
    {
        if (_observable == nil)
            return NO;

        [_observable unregisterObserver:self];
        _observable = nil;

        return YES;
    }
}

@end
