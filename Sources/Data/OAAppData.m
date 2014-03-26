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

#pragma mark - defaults

+ (OAAppData*)defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];

    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    OAMapSource* defaultMapSource = [[OAMapSource alloc] initWithLocalizedNameKey:@"OsmAndOfflineMapSource"
                                                                          andType:OAMapSourceTypeOffline
                                                              andTypedReferenceId:@"default"];
    defaultMapSource.activePresetId =
    [defaultMapSource.presets registerAndAddPreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeGeneral"
                                                                                               andType:OAMapSourcePresetTypeGeneral
                                                                                             andValues:@{ @"appMode" : @"browse map" }]];
    [defaultMapSource.presets registerAndAddPreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeCar"
                                                                                               andType:OAMapSourcePresetTypeCar
                                                                                             andValues:@{ @"appMode" : @"car" }]];
    [defaultMapSource.presets registerAndAddPreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeBicycle"
                                                                                               andType:OAMapSourcePresetTypeBicycle
                                                                                             andValues:@{ @"appMode" : @"bicycle" }]];
    [defaultMapSource.presets registerAndAddPreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypePedestrian"
                                                                                               andType:OAMapSourcePresetTypePedestrian
                                                                                             andValues:@{ @"appMode" : @"pedestrian" }]];
    defaults.activeMapSourceId = [defaults.mapSources registerAndAddMapSource:defaultMapSource];

    return defaults;
}

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
