//
//  OAMapSourcePresetsCollection.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/20/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcePresetsCollection.h"

#import "OAMapSource.h"

@implementation OAMapSourcePresetsCollection
{
    OAMapSource* _owner;

    NSMutableArray* _presetsOrder;
    NSMutableDictionary* _presets;
}

- (id)init
{
    [NSException raise:@"NSInitUnsupported" format:@"-init is unsupported"];
    return nil;
}

- (id)initWithOwner:(OAMapSource*)owner
{
    self = [super init];
    if (self) {
        [self ctor];
        _owner = owner;
        _presetsOrder = [[NSMutableArray alloc] init];
        _presets = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@synthesize owner = _owner;

- (void)ctor
{
    _collectionChangeObservable = [[OAObservable alloc] init];
}

- (NSUInteger)count
{
    @synchronized(self)
    {
        return [_presetsOrder count];
    }
}

- (NSUInteger)indexOfPresetWithId:(NSUUID*)presetId
{
    @synchronized(self)
    {
        return [_presetsOrder indexOfObject:presetId];
    }
}

- (NSUUID*)idOfPresetAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        return [_presetsOrder objectAtIndex:index];
    }
}

- (OAMapSource*)presetWithId:(NSUUID*)presetId
{
    @synchronized(self)
    {
        return [_presets objectForKey:presetId];
    }
}

- (OAMapSourcePreset*)presetAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        return [_presets objectForKey:[_presetsOrder objectAtIndex:index]];
    }
}

- (NSUUID*)registerAndAddPreset:(OAMapSourcePreset*)preset
{
    @synchronized(self)
    {
        // Generate unique UUID and insert preset into container
        NSUUID* presetId;
        for(;;)
        {
            presetId = [NSUUID UUID];
            if([_presets objectForKey:presetId] == nil)
                break;
        }

        [_presetsOrder addObject:presetId];
        [_presets setObject:preset forKey:presetId];
        [preset registerAs:presetId in:self];

        [_collectionChangeObservable notifyEventWithKey:self andValue:presetId];

        return presetId;
    }
}

- (BOOL)removePresetWithId:(NSUUID*)presetId
{
    @synchronized(self)
    {
        const NSUInteger oldCount = [_presets count];
        [_presets removeObjectForKey:presetId];
        if(oldCount == [_presets count])
            return NO;

        [_presetsOrder removeObject:presetId];

        if([_owner.activePresetId isEqual:presetId])
            _owner.activePresetId = [_presetsOrder firstObject];
        [_collectionChangeObservable notifyEventWithKey:self andValue:presetId];

        return YES;
    }
}

- (void)removePresetAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        NSUUID* const presetId = [_presetsOrder objectAtIndex:index];

        [_presets removeObjectForKey:presetId];
        [_presetsOrder removeObjectAtIndex:index];

        if([_owner.activePresetId isEqual:presetId])
            _owner.activePresetId = [_presetsOrder firstObject];
        [_collectionChangeObservable notifyEventWithKey:self andValue:presetId];
    }
}

@synthesize collectionChangeObservable = _collectionChangeObservable;

#pragma mark - NSCoding

#define kPresets @"presets"
#define kPresetsOrder @"presets_order"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_presets forKey:kPresets];
    [aCoder encodeObject:_presetsOrder forKey:kPresetsOrder];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _presets = [aDecoder decodeObjectForKey:kPresets];
        _presetsOrder = [aDecoder decodeObjectForKey:kPresetsOrder];
        [_presets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSUUID* uniqueId = key;
            OAMapSourcePreset* preset = obj;

            [preset registerAs:uniqueId in:self];
        }];
    }
    return self;
}

#pragma mark -

@end
