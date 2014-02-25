//
//  OAObserver.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAutoObserverProxy.h"

#include <objc/message.h>

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

- (id)initWith:(id)owner_ withHandler:(SEL)handler_
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

- (void)ctor:(id)owner_ handler:(SEL)handler_
{
    _owner = owner_;
    _handler = handler_;
    _observable = nil;
}

- (void)dtor
{
    if(_observable != nil)
        [_observable unregisterObserver:self];
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
        NSMethodSignature* handlerSignature = [OAAutoObserverProxy instanceMethodSignatureForSelector:_handler];
        NSUInteger handlerArgsCount = [handlerSignature numberOfArguments] - 2; // Subtract "self" and "cmd_"

        if(handlerArgsCount == 3)
        {
            objc_msgSend(_owner, _handler, observer, key, value);
            return;
        }
        
        if(handlerArgsCount == 2)
        {
            objc_msgSend(_owner, _handler, observer, key);
            return;
        }
        
        if(handlerArgsCount == 1)
        {
            objc_msgSend(_owner, _handler, observer);
            return;
        }
        
        objc_msgSend(_owner, _handler);
        return;
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:withKey:andValue:)])
    {
        [_owner handleObservedEventFrom:observer
                                withKey:key
                               andValue:value];
        return;
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:withKey:)])
    {
        [_owner handleObservedEventFrom:observer
                                withKey:key];
        return;
    }
    
    if([_owner respondsToSelector:@selector(handleObservedEventFrom:)])
    {
        [_owner handleObservedEventFrom:observer];
        return;
    }
    
    [_owner handleObservedEvent];
}

@end
