//
//  OAConcurrentCollections.m
//  OsmAnd Maps
//
//  Created by Paul on 11.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAConcurrentCollections.h"

/*
 Makes the basic insert/remove/get operations concurrent
 Use with caution:
 always check if the operation you need is implemented in these extensions! If not, add it here.
 */

@implementation OAConcurrentArray
{
    NSObject *_lock;
    NSMutableArray *_array;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSObject alloc] init];
        _array = [NSMutableArray array];
    }
    return self;
}

- (void)addObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        [_array addObject:anObject];
    }
}

- (void)addObjectsSync:(NSArray *)anArray
{
    @synchronized (_lock)
    {
        [_array addObjectsFromArray:anArray];
    }
}

- (void)insertObjectSync:(id)anObject atIndex:(NSUInteger)index
{
    @synchronized (_lock)
    {
        [_array insertObject:anObject atIndex:index];
    }
}

- (void)replaceObjectAtIndexSync:(NSUInteger)index withObject:(id)anObject
{
    @synchronized (_lock)
    {
        [_array replaceObjectAtIndex:index withObject:anObject];
    }
}

- (void)replaceAllWithObjectsSync:(NSArray *)anArray
{
    @synchronized (_lock)
    {
        [_array removeAllObjects];
        [_array addObjectsFromArray:anArray];
    }
}

- (void)removeObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        [_array removeObject:anObject];
    }
}

- (void)removeObjectAtIndexSync:(NSUInteger)index
{
    @synchronized (_lock)
    {
        [_array removeObjectAtIndex:index];
    }
}

- (void)removeAllObjectsSync
{
    @synchronized (_lock)
    {
        [_array removeAllObjects];
    }
}

- (id)objectAtIndexSync:(NSUInteger)index
{
    @synchronized (_lock)
    {
        return [_array objectAtIndex:index];
    }
}

- (NSUInteger)indexOfObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        return [_array indexOfObject:anObject];
    }
}

- (NSUInteger)countSync
{
    @synchronized (_lock)
    {
        return [_array count];
    }
}

- (id)firstObjectSync
{
    @synchronized (_lock)
    {
        return [_array firstObject];
    }
}

- (id)lastObjectSync
{
    @synchronized (_lock)
    {
        return [_array lastObject];
    }
}

- (BOOL)containsObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        return [_array containsObject:anObject];
    }
}

- (NSArray *)asArray
{
    return [NSArray arrayWithArray:_array];
}

@end

@implementation OAConcurrentSet
{
    NSObject *_lock;
    NSMutableSet *_set;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSObject alloc] init];
        _set = [NSMutableSet set];
    }
    return self;
}

- (void)addObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        [_set addObject:anObject];
    }
}

- (void)removeObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        [_set removeObject:anObject];
    }
}

- (void)removeAllObjectsSync
{
    @synchronized (_lock)
    {
        [_set removeAllObjects];
    }
}

- (NSUInteger)countSync
{
    @synchronized (_lock)
    {
        return _set.count;
    }
}

- (BOOL)containsObjectSync:(id)anObject
{
    @synchronized (_lock)
    {
        return [_set containsObject:anObject];
    }
}

@end

@implementation OAConcurrentDictionary
{
    NSObject *_lock;
    NSMutableDictionary *_dictionary;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSObject alloc] init];
        _dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setObjectSync:(id)anObject forKey:(id<NSCopying>)aKey
{
    @synchronized (_lock)
    {
        [_dictionary setObject:anObject forKey:aKey];
    }
}

- (void)removeObjectForKeySync:(id)aKey
{
    @synchronized (_lock)
    {
        [_dictionary removeObjectForKey:aKey];
    }
}

- (void)removeAllObjectsSync
{
    @synchronized (_lock)
    {
        [_dictionary removeAllObjects];
    }
}

- (NSUInteger)countSync
{
    @synchronized (_lock)
    {
        return _dictionary.count;
    }
}

- (id)objectForKeySync:(id)aKey
{
    @synchronized (_lock)
    {
        return [_dictionary objectForKey:aKey];
    }
}

- (NSDictionary *)asDictionary
{
    return [NSDictionary dictionaryWithDictionary:_dictionary];
}

@end
