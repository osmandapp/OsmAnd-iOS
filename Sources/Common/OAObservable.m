//
//  OAObservable.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAObservable.h"

#include <dispatch/dispatch.h>

#import "OAObserverProtocol.h"

@implementation OAObservable
{
    NSHashTable* _observers;
    NSLock* _observersLock;
}

- (id)init
{
    self = [super init];
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
    _observers = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:0];
    _observersLock = [[NSLock alloc] init];
}

- (void)dtor
{
    [_observersLock lock];
    _observers = nil;
    [_observersLock unlock];
}

- (void)registerObserver:(id<OAObserverProtocol>)observer
{
    [_observersLock lock];
    [_observers addObject:observer];
    [_observersLock unlock];
}

- (void)unregisterObserver:(id<OAObserverProtocol>)observer
{
    [_observersLock lock];
    [_observers removeObject:observer];
    [_observersLock unlock];
}

- (void)notifyEvent
{
    [self notifyEventWithKey:nil];
}

- (void)notifyEventWithKey:(id)key
{
    [self notifyEventWithKey:key andValue:nil];
}

- (void)notifyEventWithKey:(id)key andValue:(id)value
{
    [_observersLock lock];
    for(id<OAObserverProtocol> observer in _observers)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if ([observer respondsToSelector:@selector(handleObservedEventFrom:withKey:andValue:)])
            {
                [observer handleObservedEventFrom:self
                                          withKey:key
                                         andValue:value];
                return;
            }
            
            if ([observer respondsToSelector:@selector(handleObservedEventFrom:withKey:)])
            {
                [observer handleObservedEventFrom:self
                                          withKey:key];
                return;
            }
            
            if ([observer respondsToSelector:@selector(handleObservedEventFrom:)])
            {
                [observer handleObservedEventFrom:self];
                return;
            }
            
            [observer handleObservedEvent];
        });
    }
    [_observersLock unlock];
}

@end
