//
//  OAObserver.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAutoObserverProxy.h"

@implementation OAAutoObserverProxy
{
}

@synthesize owner = _owner;
@synthesize handler = _handler;

- (id)initWith:(id<OAObserverProtocol>)owner_
{
    self = [super init];
    if (self) {
        [self ctor:owner_
           handler:nil];
    }
    return self;
}

- (id)initWith:(id<OAObserverProtocol>)owner_ withHandler:(SEL)handler_
{
    self = [super init];
    if (self) {
        [self ctor:owner_
           handler:handler_];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor:(id<OAObserverProtocol>)owner_ handler:(SEL)handler_
{
    _owner = owner_;
    _handler = handler_;
    _observable = nil;
}

- (void)dtor
{
    if(_observable != nil)
    {
        [_observable unregisterObserver:self];
        _observable = nil;
    }
}

@synthesize observable = _observable;

- (void)observe:(id<OAObservableProtocol>)observable
{
    if(_observable != nil)
    {
        [_observable unregisterObserver:self];
        _observable = nil;
    }

    _observable = observable;
    [_observable registerObserver:self];
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

- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key
{
    [self handleObservedEventFrom:observer
                          withKey:key
                         andValue:nil];
}

- (void)handleObservedEventFrom:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    if(_handler != nil)
    {
        NSMethodSignature* handlerSignature = [_owner methodSignatureForSelector:_handler];
        NSUInteger handlerArgsCount = [handlerSignature numberOfArguments] - 2; // Subtract "self" and "cmd_"
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:handlerSignature];
        [invocation setTarget:_owner];
        [invocation setSelector:_handler];

        if(handlerArgsCount == 3)
        {
            [invocation setArgument:observer
                            atIndex:2+0];
            [invocation setArgument:key
                            atIndex:2+1];
            [invocation setArgument:value
                            atIndex:2+2];
            [invocation invoke];
            return;
        }
        
        if(handlerArgsCount == 2)
        {
            [invocation setArgument:observer
                            atIndex:2+0];
            [invocation setArgument:key
                            atIndex:2+1];
            [invocation invoke];
            return;
        }
        
        if(handlerArgsCount == 1)
        {
            [invocation setArgument:observer
                            atIndex:2+0];
            [invocation invoke];
            return;
        }
        
        [invocation invoke];
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:withKey:andValue:)])
    {
        [_owner handleObservedEventFrom:self
                                withKey:key
                               andValue:value];
        return;
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:withKey:)])
    {
        [_owner handleObservedEventFrom:self
                                withKey:key];
        return;
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:)])
    {
        [_owner handleObservedEventFrom:self];
        return;
    }
    
    [_owner handleObservedEvent];
}

@end
