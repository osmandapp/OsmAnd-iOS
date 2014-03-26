//
//  OAAppData.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppData.h"

#include <objc/runtime.h>

@implementation OAAppData
{
}

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
        _activeMapSourceId = nil;
        _mapSources = [[OAMapSourcesCollection alloc] initWithOwner:self];
        _mapLastViewedState = [[OAMapCrossSessionState alloc] init];
    }
    return self;
}

- (void)ctor
{
    _activeMapSourceIdChangeObservable = [[OAObservable alloc] init];
}

@synthesize activeMapSourceId = _activeMapSourceId;

- (NSUUID*)activeMapSourceId
{
    @synchronized(self)
    {
        return _activeMapSourceId;
    }
}

- (void)setActiveMapSourceId:(NSUUID *)activeMapSourceId
{
    @synchronized(self)
    {
        _activeMapSourceId = [activeMapSourceId copy];
        
        [_activeMapSourceIdChangeObservable notifyEventWithKey:self andValue:_activeMapSourceId];
    }
}

@synthesize activeMapSourceIdChangeObservable = _activeMapSourceIdChangeObservable;

@synthesize mapSources = _mapSources;

- (OAMapSourcesCollection*)mapSources
{
    @synchronized(self)
    {
        return _mapSources;
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;

#pragma mark - NSCoding

#define kActiveMapSourceId @"active_map_source_id"
#define kMapSourcesContainer @"map_sources_container"
#define kMapLastViewedState @"map_last_viewed_state"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_activeMapSourceId forKey:kActiveMapSourceId];
    [aCoder encodeObject:_mapSources forKey:kMapSourcesContainer];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _activeMapSourceId = [aDecoder decodeObjectForKey:kActiveMapSourceId];
        _mapSources = [aDecoder decodeObjectForKey:kMapSourcesContainer];
        [_mapSources setOwner:self];
        _mapLastViewedState = [aDecoder decodeObjectForKey:kMapLastViewedState];
    }
    return self;
}

#pragma mark -

@end
