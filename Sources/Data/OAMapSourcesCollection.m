//
//  OAMapSourcesCollection.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcesCollection.h"

#import "OAObservable.h"
#import "OAAppData.h"

@implementation OAMapSourcesCollection
{
    OAAppData* _owner;

    NSMutableArray* _mapSourcesOrder;
    NSMutableDictionary* _mapSources;
}

- (id)init
{
    [NSException raise:@"NSInitUnsupported" format:@"-init is unsupported"];
    return nil;
}

- (id)initWithOwner:(OAAppData*)owner
{
    self = [super init];
    if (self) {
        [self ctor];
        _owner = owner;
        _mapSourcesOrder = [[NSMutableArray alloc] init];
        _mapSources = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)ctor
{
    _collectionChangeObservable = [[OAObservable alloc] init];
}

@synthesize owner = _owner;

- (NSUInteger)count
{
    @synchronized(self)
    {
        return [_mapSourcesOrder count];
    }
}

- (NSUInteger)indexOfMapSourceWithId:(NSUUID*)mapSourceId
{
    @synchronized(self)
    {
        return [_mapSourcesOrder indexOfObject:mapSourceId];
    }
}

- (NSUUID*)idOfMapSourceAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        return [_mapSourcesOrder objectAtIndex:index];
    }
}

- (OAMapSource*)mapSourceWithId:(NSUUID*)mapSourceId
{
    @synchronized(self)
    {
        return [_mapSources objectForKey:mapSourceId];
    }
}

- (OAMapSource*)mapSourceAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        return [_mapSources objectForKey:[_mapSourcesOrder objectAtIndex:index]];
    }
}

- (NSUUID*)registerAndAddMapSource:(OAMapSource*)mapSource
{
    @synchronized(self)
    {
        // Generate unique UUID and insert preset into container
        NSUUID* mapSourceId;
        for(;;)
        {
            mapSourceId = [NSUUID UUID];
            if([_mapSources objectForKey:mapSourceId] == nil)
                break;
        }
        
        [_mapSourcesOrder addObject:mapSourceId];
        [_mapSources setObject:mapSource forKey:mapSourceId];
        [mapSource registerAs:mapSourceId in:self];
        
        [_collectionChangeObservable notifyEventWithKey:self andValue:mapSourceId];
        
        return mapSourceId;
    }
}

- (BOOL)removeMapSourceWithId:(NSUUID*)mapSourceId
{
    @synchronized(self)
    {
        const NSUInteger oldCount = [_mapSources count];
        [_mapSources removeObjectForKey:mapSourceId];
        if(oldCount == [_mapSources count])
            return NO;
        
        [_mapSourcesOrder removeObject:mapSourceId];

        if([_owner.activeMapSourceId isEqual:mapSourceId])
            _owner.activeMapSourceId = [_mapSourcesOrder firstObject];
        [_collectionChangeObservable notifyEventWithKey:self andValue:mapSourceId];
        
        return YES;
    }
}

- (void)removeMapSourceAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        NSUUID* const mapSourceId = [_mapSourcesOrder objectAtIndex:index];
        
        [_mapSources removeObjectForKey:mapSourceId];
        [_mapSourcesOrder removeObjectAtIndex:index];

        if([_owner.activeMapSourceId isEqual:mapSourceId])
            _owner.activeMapSourceId = [_mapSourcesOrder firstObject];
        [_collectionChangeObservable notifyEventWithKey:self andValue:mapSourceId];
    }
}

@synthesize collectionChangeObservable = _collectionChangeObservable;

#pragma mark - NSCoding

#define kMapSources @"map_sources"
#define kMapSourcesOrder @"map_sources_order"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_mapSources forKey:kMapSources];
    [aCoder encodeObject:_mapSourcesOrder forKey:kMapSourcesOrder];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _mapSources = [aDecoder decodeObjectForKey:kMapSources];
        _mapSourcesOrder = [aDecoder decodeObjectForKey:kMapSourcesOrder];
        [_mapSources enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSUUID* uniqueId = key;
            OAMapSource* mapSource = obj;

            [mapSource registerAs:uniqueId in:self];
        }];
    }
    return self;
}

#pragma mark -

@end
