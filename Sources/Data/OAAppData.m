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

    _overlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _overlayAlphaChangeObservable = [[OAObservable alloc] init];
    _underlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _underlayAlphaChangeObservable = [[OAObservable alloc] init];
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
    
    if (isnan(_mapLastViewedState.zoom) || _mapLastViewedState.zoom < 1.0f || _mapLastViewedState.zoom > 23.0f)
        _mapLastViewedState.zoom = 3.0f;
    
    if (_mapLastViewedState.target31.x < 0 || _mapLastViewedState.target31.y < 0)
    {
        Point31 p;
        p.x = 1073741824;
        p.y = 1073741824;
        _mapLastViewedState.target31 = p;
        _mapLastViewedState.zoom = 3.0f;
    }
    
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

@synthesize overlayMapSourceChangeObservable = _overlayMapSourceChangeObservable;
@synthesize overlayAlphaChangeObservable = _overlayAlphaChangeObservable;
@synthesize underlayMapSourceChangeObservable = _underlayMapSourceChangeObservable;
@synthesize underlayAlphaChangeObservable = _underlayAlphaChangeObservable;

@synthesize overlayMapSource = _overlayMapSource;

- (OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        return _overlayMapSource;
    }
}

- (void)setOverlayMapSource:(OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        _overlayMapSource = [overlayMapSource copy];
        [_overlayMapSourceChangeObservable notifyEventWithKey:self andValue:_overlayMapSource];
    }
}

@synthesize underlayMapSource = _underlayMapSource;

- (OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        return _underlayMapSource;
    }
}

- (void)setUnderlayMapSource:(OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        _underlayMapSource = [underlayMapSource copy];
        [_underlayMapSourceChangeObservable notifyEventWithKey:self andValue:_underlayMapSource];
    }
}

@synthesize overlayAlpha = _overlayAlpha;
@synthesize underlayAlpha = _underlayAlpha;

- (void)setOverlayAlpha:(double)overlayAlpha
{
    @synchronized(_lock)
    {
        _overlayAlpha = overlayAlpha;
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_overlayAlpha]];
    }
}

- (void)setUnderlayAlpha:(double)underlayAlpha
{
    @synchronized(_lock)
    {
        _underlayAlpha = underlayAlpha;
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_underlayAlpha]];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;
@synthesize mapLayersConfiguration = _mapLayersConfiguration;

#pragma mark - defaults

+ (OAAppData*)defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];

    defaults.overlayAlpha = 0.5;
    defaults.underlayAlpha = 0.5;
    
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

#define kOverlayMapSource @"overlay_map_source"
#define kUnderlayMapSource @"underlay_map_source"
#define kOverlayAlpha @"overlay_alpha"
#define kUnderlayAlpha @"underlay_alpha"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSource forKey:kLastMapSource];
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_mapLayersConfiguration forKey:kMapLayersConfiguration];
    [aCoder encodeObject:_destinations forKey:kDestinations];

    [aCoder encodeObject:_overlayMapSource forKey:kOverlayMapSource];
    [aCoder encodeObject:_underlayMapSource forKey:kUnderlayMapSource];
    [aCoder encodeObject:[NSNumber numberWithDouble:_overlayAlpha] forKey:kOverlayAlpha];
    [aCoder encodeObject:[NSNumber numberWithDouble:_underlayAlpha] forKey:kUnderlayAlpha];
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

        _overlayMapSource = [aDecoder decodeObjectForKey:kOverlayMapSource];
        _underlayMapSource = [aDecoder decodeObjectForKey:kUnderlayMapSource];
        _overlayAlpha = [[aDecoder decodeObjectForKey:kOverlayAlpha] doubleValue];
        _underlayAlpha = [[aDecoder decodeObjectForKey:kUnderlayAlpha] doubleValue];

        [self safeInit];
    }
    return self;
}

#pragma mark -

@end
