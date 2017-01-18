//
//  OAAtomicInteger.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAtomicInteger.h"

@implementation OAAtomicInteger
{
    int _value;
}

+ (OAAtomicInteger *) atomicInteger:(int)value
{
    return [[OAAtomicInteger alloc] initWithInteger:value];
}

- (instancetype)initWithInteger:(int)value
{
    self = [super init];
    if (self)
    {
        _value = value;
    }
    return self;
}

- (int) get
{
    @synchronized (self)
    {
        return _value;
    }
}

- (void) set:(int)value
{
    @synchronized (self)
    {
        _value = value;
    }
}

- (int) getAndSet:(int)value
{
    @synchronized (self)
    {
        int res = _value;
        _value = value;
        return res;
    }
}

- (void) compareAndSet:(int)value
{
    @synchronized (self)
    {
        if (_value != value)
            _value = value;
    }
}

- (int) getAndAdd:(int)value
{
    @synchronized (self)
    {
        int res = _value;
        _value += value;
        return res;
    }
}

- (int) addAndGet:(int)value
{
    @synchronized (self)
    {
        _value += value;
        return _value;
    }
}

- (int) getAndIncrement
{
    @synchronized (self)
    {
        return _value++;
    }
}

- (int) getAndDecrement
{
    @synchronized (self)
    {
        return _value--;
    }
}

- (int) incrementAndGet
{
    @synchronized (self)
    {
        return ++_value;
    }
}

- (int) decrementAndGet
{
    @synchronized (self)
    {
        return --_value;
    }
}

@end
