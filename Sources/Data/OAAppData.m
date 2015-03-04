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
    NSObject* _lock;
    NSMutableDictionary* _lastMapSources;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
        _lastMapSource = nil;
        [self safeInit];
    }
    return self;
}

- (void)commonInit
{
    _lock = [[NSObject alloc] init];
    _lastMapSourceChangeObservable = [[OAObservable alloc] init];
}

- (void)safeInit
{
    if (_lastMapSources == nil)
        _lastMapSources = [[NSMutableDictionary alloc] init];
    if (_mapLastViewedState == nil)
        _mapLastViewedState = [[OAMapViewState alloc] init];
    if (_mapLayersConfiguration == nil)
        _mapLayersConfiguration = [[OAMapLayersConfiguration alloc] init];
    if (_destinations == nil)
        _destinations = [NSMutableArray array];
}

@synthesize lastMapSource = _lastMapSource;

- (OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        return _lastMapSource;
    }
}

- (void)setLastMapSource:(OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        // Store previous, if such exists
        if (_lastMapSource != nil)
        {
            [_lastMapSources setObject:_lastMapSource.variant != nil ? _lastMapSource.variant : [NSNull null]
                                forKey:_lastMapSource.resourceId];
        }

        // Save new one
        _lastMapSource = [lastMapSource copy];
        [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:_lastMapSource];
    }
}

@synthesize lastMapSourceChangeObservable = _lastMapSourceChangeObservable;

- (OAMapSource*)lastMapSourceByResourceId:(NSString*)resourceId
{
    @synchronized(_lock)
    {
        if (_lastMapSource != nil && [_lastMapSource.resourceId isEqualToString:resourceId])
            return _lastMapSource;

        NSNull* variant = [_lastMapSources objectForKey:resourceId];
        if (variant == nil || variant == [NSNull null])
            return nil;

        return [[OAMapSource alloc] initWithResource:resourceId
                                          andVariant:(NSString*)variant];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;

@synthesize mapLayersConfiguration = _mapLayersConfiguration;

#pragma mark - defaults

+ (OAAppData*)defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];

    // Imagine that last viewed location was center of the world
    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    // Set offline maps as default map source
    defaults.lastMapSource = [[OAMapSource alloc] initWithResource:@"default.render.xml"
                                                        andVariant:@"type_general"];

    return defaults;
}

#pragma mark - NSCoding

#define kLastMapSource @"last_map_source"
#define kLastMapSources @"last_map_sources"
#define kMapLastViewedState @"map_last_viewed_state"
#define kMapLayersConfiguration @"map_layers_configuration"
#define kDestinations @"destinations"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSource forKey:kLastMapSource];
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_mapLayersConfiguration forKey:kMapLayersConfiguration];
    [aCoder encodeObject:_destinations forKey:kDestinations];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _lastMapSource = [aDecoder decodeObjectForKey:kLastMapSource];
        _lastMapSources = [aDecoder decodeObjectForKey:kLastMapSources];
        _mapLastViewedState = [aDecoder decodeObjectForKey:kMapLastViewedState];
        _mapLayersConfiguration = [aDecoder decodeObjectForKey:kMapLayersConfiguration];
        _destinations = [aDecoder decodeObjectForKey:kDestinations];
        [self safeInit];
    }
    return self;
}

#pragma mark -

@end
