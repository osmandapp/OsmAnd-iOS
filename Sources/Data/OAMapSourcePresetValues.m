//
//  OAMapSourcePresetValues.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/26/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcePresetValues.h"

#import "OAMapSourcePreset.h"

@implementation OAMapSourcePresetValues
{
    NSMutableDictionary* _storage;
}
- (id)init

{
    [NSException raise:@"NSInitUnsupported" format:@"-init is unsupported"];
    return nil;
}

- (id)initWithOwner:(OAMapSourcePreset*)owner
{
    self = [super init];
    if (self) {
        [self ctor];
        _owner = owner;
        _storage = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)ctor
{
    _changeObservable = [[OAObservable alloc] init];
}

@synthesize owner = _owner;

- (NSUInteger)count
{
    @synchronized(self)
    {
        return [_storage count];
    }
}

- (void)setValue:(NSString *)value forKey:(NSString *)key
{
    @synchronized(self)
    {
        NSString* oldValue = [_storage objectForKey:key];
        if(oldValue != nil && [oldValue isEqualToString:value])
            return;

        [_storage setValue:value forKey:key];

        [_changeObservable notifyEventWithKey:self andValue:key];
        [_owner.changeObservable notifyEventWithKey:_owner];
    }
}

- (NSString*)valueOfKey:(NSString *)key;
{
    @synchronized(self)
    {
        return [[_storage valueForKey:key] copy];
    }
}

- (BOOL)removeValueOfKey:(NSString *)key;
{
    @synchronized(self)
    {
        NSUInteger previousCount = [_storage count];
        [_storage removeObjectForKey:key];
        if(previousCount == [_storage count])
            return NO;
        
        [_changeObservable notifyEventWithKey:self andValue:key];
        [_owner.changeObservable notifyEventWithKey:_owner];

        return YES;
    }
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString* key, NSString* value, BOOL *stop))block
{
    @synchronized(self)
    {
        [_storage enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            block(key, obj, stop);
        }];
    }
}

@synthesize changeObservable = _changeObservable;

#pragma mark - NSCoding

#define kValues @"values"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_storage forKey:kValues];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _storage = [aDecoder decodeObjectForKey:kValues];
    }
    return self;
}

#pragma mark -

@end
