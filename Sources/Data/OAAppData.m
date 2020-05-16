//
//  OAAppData.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppData.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

#include <objc/runtime.h>

@implementation OAAppData
{
    NSObject* _lock;
    NSMutableDictionary* _lastMapSources;
    
    OAAutoObserverProxy *_applicationModeChangedObserver;
    
    NSMutableArray<OARTargetPoint *> *_intermediates;
}

@synthesize applicationModeChangedObservable = _applicationModeChangedObservable;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _lastMapSource = nil;
        [self safeInit];
    }
    return self;
}

- (void) commonInit
{
    _lock = [[NSObject alloc] init];
    _lastMapSourceChangeObservable = [[OAObservable alloc] init];

    _overlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _overlayAlphaChangeObservable = [[OAObservable alloc] init];
    _underlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _underlayAlphaChangeObservable = [[OAObservable alloc] init];
    _terrainChangeObservable = [[OAObservable alloc] init];
    _terrainResourcesChangeObservable = [[OAObservable alloc] init];
    _terrainAlphaChangeObservable = [[OAObservable alloc] init];
    _mapLayerChangeObservable = [[OAObservable alloc] init];
    _mapillaryChangeObservable = [[OAObservable alloc] init];

    _destinationsChangeObservable = [[OAObservable alloc] init];
    _destinationAddObservable = [[OAObservable alloc] init];
    _destinationRemoveObservable = [[OAObservable alloc] init];
    _destinationShowObservable = [[OAObservable alloc] init];
    _destinationHideObservable = [[OAObservable alloc] init];
    
    _applicationModeChangedObservable = [[OAObservable alloc] init];
    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:_applicationModeChangedObservable];

}

- (void) dealloc
{
    if (_applicationModeChangedObserver)
    {
        [_applicationModeChangedObserver detach];
        _applicationModeChangedObserver = nil;
    }
}

- (void) onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setLastMapSourceVariant:[OAAppSettings sharedManager].applicationMode.variantKey];
    });
}

- (void) safeInit
{
    if (_lastMapSources == nil)
        _lastMapSources = [[NSMutableDictionary alloc] init];
    if (_mapLastViewedState == nil)
        _mapLastViewedState = [[OAMapViewState alloc] init];
    if (_mapLayersConfiguration == nil)
        _mapLayersConfiguration = [[OAMapLayersConfiguration alloc] init];
    if (_destinations == nil)
        _destinations = [NSMutableArray array];
    if (_intermediates == nil)
        _intermediates = [NSMutableArray array];
    
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

@synthesize prevOfflineSource = _prevOfflineSource;

- (OAMapSource*) prevOfflineSource
{
    @synchronized(_lock)
    {
        return _prevOfflineSource;
    }
}

- (void) setPrevOfflineSource:(OAMapSource *)prevOfflineSource
{
    @synchronized(_lock)
    {
        _prevOfflineSource = prevOfflineSource;
    }
}

@synthesize lastMapSource = _lastMapSource;

- (OAMapSource*) lastMapSource
{
    @synchronized(_lock)
    {
        return _lastMapSource;
    }
}

- (void) setLastMapSource:(OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:_lastMapSource])
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
}

- (void) setLastMapSourceVariant:(NSString *)variant
{
    if ([_lastMapSource.resourceId isEqualToString:@"online_tiles"])
        return;
    
    OAMapSource *mapSource = [[OAMapSource alloc] initWithResource:_lastMapSource.resourceId andVariant:variant name:_lastMapSource.name];
    self.lastMapSource = mapSource;
}

@synthesize lastMapSourceChangeObservable = _lastMapSourceChangeObservable;

- (OAMapSource*) lastMapSourceByResourceId:(NSString*)resourceId
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
@synthesize destinationsChangeObservable = _destinationsChangeObservable;
@synthesize destinationAddObservable = _destinationAddObservable;
@synthesize destinationRemoveObservable = _destinationRemoveObservable;
@synthesize terrainChangeObservable = _terrainChangeObservable;
@synthesize terrainResourcesChangeObservable = _terrainResourcesChangeObservable;
@synthesize terrainAlphaChangeObservable = _terrainAlphaChangeObservable;
@synthesize mapLayerChangeObservable = _mapLayerChangeObservable;
@synthesize mapillaryChangeObservable = _mapillaryChangeObservable;

@synthesize overlayMapSource = _overlayMapSource;

- (OAMapSource*) overlayMapSource
{
    @synchronized(_lock)
    {
        return _overlayMapSource;
    }
}

- (void) setOverlayMapSource:(OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        _overlayMapSource = [overlayMapSource copy];
        [_overlayMapSourceChangeObservable notifyEventWithKey:self andValue:_overlayMapSource];
    }
}

@synthesize lastOverlayMapSource = _lastOverlayMapSource;

- (OAMapSource*) lastOverlayMapSource
{
    @synchronized(_lock)
    {
        return _lastOverlayMapSource;
    }
}

- (void) setLastOverlayMapSource:(OAMapSource*)lastOverlayMapSource
{
    @synchronized(_lock)
    {
        _lastOverlayMapSource = [lastOverlayMapSource copy];
    }
}


@synthesize underlayMapSource = _underlayMapSource;

- (OAMapSource*) underlayMapSource
{
    @synchronized(_lock)
    {
        return _underlayMapSource;
    }
}

- (void) setUnderlayMapSource:(OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        _underlayMapSource = [underlayMapSource copy];
        [_underlayMapSourceChangeObservable notifyEventWithKey:self andValue:_underlayMapSource];
    }
}

@synthesize lastUnderlayMapSource = _lastUnderlayMapSource;

- (OAMapSource*) lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        return _lastUnderlayMapSource;
    }
}

- (void) setLastUnderlayMapSource:(OAMapSource*)lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        _lastUnderlayMapSource = [lastUnderlayMapSource copy];
    }
}


@synthesize overlayAlpha = _overlayAlpha;
@synthesize underlayAlpha = _underlayAlpha;

- (void) setOverlayAlpha:(double)overlayAlpha
{
    @synchronized(_lock)
    {
        _overlayAlpha = overlayAlpha;
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_overlayAlpha]];
    }
}

- (void) setUnderlayAlpha:(double)underlayAlpha
{
    @synchronized(_lock)
    {
        _underlayAlpha = underlayAlpha;
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_underlayAlpha]];
    }
}

@synthesize hillshadeMinZoom = _hillshadeMinZoom;

- (NSInteger) hillshadeMinZoom
{
    @synchronized(_lock)
    {
        return _hillshadeMinZoom;
    }
}

- (void) setHillshadeMinZoom:(NSInteger)hillshadeMinZoom
{
    @synchronized(_lock)
    {
        _hillshadeMinZoom = hillshadeMinZoom;
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

@synthesize hillshadeMaxZoom = _hillshadeMaxZoom;

- (NSInteger) hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        return _hillshadeMaxZoom;
    }
}

- (void) setHillshadeMaxZoom:(NSInteger)hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        _hillshadeMaxZoom = hillshadeMaxZoom;
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

@synthesize slopeMinZoom = _slopeMinZoom;

- (NSInteger) slopeMinZoom
{
    @synchronized(_lock)
    {
        return _slopeMinZoom;
    }
}

- (void) setSlopeMinZoom:(NSInteger)slopeMinZoom
{
    @synchronized(_lock)
    {
        _slopeMinZoom = slopeMinZoom;
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

@synthesize slopeMaxZoom = _slopeMaxZoom;

- (NSInteger) slopeMaxZoom
{
    @synchronized(_lock)
    {
        return _slopeMaxZoom;
    }
}

- (void) setSlopeMaxZoom:(NSInteger)slopeMaxZoom
{
    @synchronized(_lock)
    {
        _slopeMaxZoom = slopeMaxZoom;
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

@synthesize terrainType = _terrainType;

- (EOATerrainType) terrainType
{
    @synchronized(_lock)
    {
        return _terrainType;
    }
}

- (void) setTerrainType:(EOATerrainType)hillshade
{
    @synchronized(_lock)
    {
        _terrainType = hillshade;
        if (hillshade == EOATerrainTypeHillshade || hillshade == EOATerrainTypeSlope)
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
        else
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(NO)];
    }
}

@synthesize lastTerrainType = _lastTerrainType;

- (EOATerrainType) lastTerrainType
{
    @synchronized(_lock)
    {
        return _lastTerrainType;
    }
}

- (void) setLastTerrainType:(EOATerrainType)lastTerrainType
{
    @synchronized(_lock)
    {
        _lastTerrainType = lastTerrainType;
    }
}

@synthesize hillshadeAlpha = _hillshadeAlpha;

- (void) setHillshadeAlpha:(double)hillshadeAlpha
{
    @synchronized(_lock)
    {
        _hillshadeAlpha = hillshadeAlpha;
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_hillshadeAlpha]];
    }
}

@synthesize slopeAlpha = _slopeAlpha;

- (void) setSlopeAlpha:(double)slopeAlpha
{
    @synchronized(_lock)
    {
        _slopeAlpha = slopeAlpha;
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:_slopeAlpha]];
    }
}

@synthesize mapillary = _mapillary;

- (BOOL) mapillary
{
    @synchronized (_lock)
    {
        return _mapillary;
    }
}

- (void) setMapillary:(BOOL)mapillary
{
    @synchronized (_lock)
    {
        _mapillary = mapillary;
        [_mapillaryChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithBool:_mapillary]];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;
@synthesize mapLayersConfiguration = _mapLayersConfiguration;

- (void) backupTargetPoints
{
    @synchronized (_lock)
    {
        _pointToNavigateBackup = _pointToNavigate;
        _pointToStartBackup = _pointToStart;
        _intermediatePointsBackup = [NSMutableArray arrayWithArray:_intermediates];
    }
}

- (void) restoreTargetPoints
{
    _pointToNavigate = _pointToNavigateBackup;
    _pointToStart = _pointToStartBackup;
    _intermediates = [NSMutableArray arrayWithArray:_intermediatePointsBackup];
}

- (BOOL) restorePointToStart
{
    return (_pointToStartBackup != nil);
}

- (void) setPointToStart:(OARTargetPoint *)pointToStart
{
    _pointToStart = pointToStart;
    [self backupTargetPoints];
}

- (void) setPointToNavigate:(OARTargetPoint *)pointToNavigate
{
    _pointToNavigate = pointToNavigate;
    if (pointToNavigate && pointToNavigate.pointDescription)
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = pointToNavigate.pointDescription.name;
        h.latitude = [pointToNavigate getLatitude];
        h.longitude = [pointToNavigate getLongitude];
        h.date = [NSDate date];
        h.hType = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigate.pointDescription].hType;
        
        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
    
    [self backupTargetPoints];
}

- (NSArray<OARTargetPoint *> *) intermediatePoints
{
    return [NSArray arrayWithArray:_intermediates];
}

- (void) setIntermediatePoints:(NSArray<OARTargetPoint *> *)intermediatePoints
{
    _intermediates = [NSMutableArray arrayWithArray:intermediatePoints];
    [self backupTargetPoints];
}

- (void) addIntermediatePoint:(OARTargetPoint *)point
{
    [_intermediates addObject:point];
    [self backupTargetPoints];
}

- (void) insertIntermediatePoint:(OARTargetPoint *)point index:(int)index
{
    [_intermediates insertObject:point atIndex:index];
    [self backupTargetPoints];
}

- (void) deleteIntermediatePoint:(int)index
{
    [_intermediates removeObjectAtIndex:index];
    [self backupTargetPoints];
}

- (void) clearPointToStart
{
    _pointToStart = nil;
}

- (void) clearPointToNavigate
{
    _pointToNavigate = nil;
}

- (void) clearIntermediatePoints
{
    [_intermediates removeAllObjects];
}

#pragma mark - defaults

+ (OAAppData*) defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];

    defaults.overlayAlpha = 0.5;
    defaults.underlayAlpha = 0.5;
    defaults.lastOverlayMapSource = nil;
    defaults.lastUnderlayMapSource = nil;
    defaults.terrainType = EOATerrainTypeDisabled;
    defaults.lastTerrainType = EOATerrainTypeHillshade;
    defaults.hillshadeAlpha = 0.45;
    defaults.slopeAlpha = 0.35;
    defaults.hillshadeMinZoom = 3;
    defaults.hillshadeMaxZoom = 16;
    defaults.slopeMinZoom = 3;
    defaults.slopeMaxZoom = 16;
    
    // Imagine that last viewed location was center of the world
    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    // Set offline maps as default map source
    defaults.lastMapSource = [[OAMapSource alloc] initWithResource:@"default.render.xml"
                                                        andVariant:@"type_default"];

    return defaults;
}

#pragma mark - NSCoding

#define kLastMapSource @"last_map_source"
#define kLastMapSources @"last_map_sources"
#define kMapLastViewedState @"map_last_viewed_state"
#define kMapLayersConfiguration @"map_layers_configuration"
#define kDestinations @"destinations"

#define kOverlayMapSource @"overlay_map_source"
#define kLastOverlayMapSource @"last_overlay_map_source"
#define kUnderlayMapSource @"underlay_map_source"
#define kLastUnderlayMapSource @"last_underlay_map_source"
#define kOverlayAlpha @"overlay_alpha"
#define kUnderlayAlpha @"underlay_alpha"

#define kHillshadeMinZoom @"hillshade_min_zoom"
#define kHillshadeMaxZoom @"hillshade_max_zoom"
#define kHillshadeAlpha @"hillshade_alpha"
#define kSlopeMinZoom @"slope_min_zoom"
#define kSlopeMaxZoom @"slope_max_zoom"
#define kSlopeAlpha @"slope_alpha"
#define kTerrainType @"terrain_type"
#define kLastTerrainType @"last_terrain_type"
#define kMapillary @"mapillary"

#define kPointToStart @"pointToStart"
#define kPointToNavigate @"pointToNavigate"
#define kIntermediatePoints @"intermediatePoints"

#define kPointToStartBackup @"pointToStartBackup"
#define kPointToNavigateBackup @"pointToNavigateBackup"
#define kIntermediatePointsBackup @"intermediatePointsBackup"

#define kHomePoint @"homePoint"
#define kWorkPoint @"workPoint"
#define kMyLocationToStart @"myLocationToStart"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSource forKey:kLastMapSource];
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_mapLayersConfiguration forKey:kMapLayersConfiguration];
    [aCoder encodeObject:_destinations forKey:kDestinations];

    [aCoder encodeObject:_overlayMapSource forKey:kOverlayMapSource];
    [aCoder encodeObject:_lastOverlayMapSource forKey:kLastOverlayMapSource];
    [aCoder encodeObject:_underlayMapSource forKey:kUnderlayMapSource];
    [aCoder encodeObject:_lastUnderlayMapSource forKey:kLastUnderlayMapSource];
    [aCoder encodeObject:[NSNumber numberWithDouble:_overlayAlpha] forKey:kOverlayAlpha];
    [aCoder encodeObject:[NSNumber numberWithDouble:_underlayAlpha] forKey:kUnderlayAlpha];

    [aCoder encodeObject:[NSNumber numberWithInteger:_hillshadeMinZoom] forKey:kHillshadeMinZoom];
    [aCoder encodeObject:[NSNumber numberWithInteger:_hillshadeMaxZoom] forKey:kHillshadeMaxZoom];
    [aCoder encodeObject:[NSNumber numberWithInteger:_slopeMinZoom] forKey:kSlopeMinZoom];
    [aCoder encodeObject:[NSNumber numberWithInteger:_slopeMaxZoom] forKey:kSlopeMaxZoom];
    [aCoder encodeObject:[NSNumber numberWithInteger:_terrainType] forKey:kTerrainType];
    [aCoder encodeObject:[NSNumber numberWithInteger:_lastTerrainType] forKey:kLastTerrainType];
    [aCoder encodeObject:[NSNumber numberWithDouble:_hillshadeAlpha] forKey:kHillshadeAlpha];
    [aCoder encodeObject:[NSNumber numberWithDouble:_slopeAlpha] forKey:kSlopeAlpha];
    [aCoder encodeObject:[NSNumber numberWithBool:_mapillary] forKey:kMapillary];
    
    [aCoder encodeObject:_pointToStart forKey:kPointToStart];
    [aCoder encodeObject:_pointToNavigate forKey:kPointToNavigate];
    [aCoder encodeObject:_intermediates forKey:kIntermediatePoints];
    [aCoder encodeObject:_pointToStartBackup forKey:kPointToStartBackup];
    [aCoder encodeObject:_pointToNavigateBackup forKey:kPointToNavigateBackup];
    [aCoder encodeObject:_intermediatePointsBackup forKey:kIntermediatePointsBackup];
    [aCoder encodeObject:_homePoint forKey:kHomePoint];
    [aCoder encodeObject:_workPoint forKey:kWorkPoint];
    [aCoder encodeObject:_myLocationToStart forKey:kMyLocationToStart];
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
        _lastOverlayMapSource = [aDecoder decodeObjectForKey:kLastOverlayMapSource];
        _underlayMapSource = [aDecoder decodeObjectForKey:kUnderlayMapSource];
        _lastUnderlayMapSource = [aDecoder decodeObjectForKey:kLastUnderlayMapSource];
        _overlayAlpha = [[aDecoder decodeObjectForKey:kOverlayAlpha] doubleValue];
        _underlayAlpha = [[aDecoder decodeObjectForKey:kUnderlayAlpha] doubleValue];

        _hillshadeMinZoom = [[aDecoder decodeObjectForKey:kHillshadeMinZoom] integerValue];
        _hillshadeMaxZoom = [[aDecoder decodeObjectForKey:kHillshadeMaxZoom] integerValue];
        _slopeMinZoom = [[aDecoder decodeObjectForKey:kSlopeMinZoom] integerValue];
        _slopeMaxZoom = [[aDecoder decodeObjectForKey:kSlopeMaxZoom] integerValue];
        _terrainType = [[aDecoder decodeObjectForKey:kTerrainType] integerValue];
        _lastTerrainType = [[aDecoder decodeObjectForKey:kLastTerrainType] integerValue];
        _hillshadeAlpha = [[aDecoder decodeObjectForKey:kHillshadeAlpha] doubleValue];
        _slopeAlpha = [[aDecoder decodeObjectForKey:kSlopeAlpha] doubleValue];
        _mapillary = [[aDecoder decodeObjectForKey:kMapillary] boolValue];

        _pointToStart = [aDecoder decodeObjectForKey:kPointToStart];
        _pointToNavigate = [aDecoder decodeObjectForKey:kPointToNavigate];
        _intermediates = [aDecoder decodeObjectForKey:kIntermediatePoints];
        _pointToStartBackup = [aDecoder decodeObjectForKey:kPointToStartBackup];
        _pointToNavigateBackup = [aDecoder decodeObjectForKey:kPointToNavigateBackup];
        _intermediatePointsBackup = [aDecoder decodeObjectForKey:kIntermediatePointsBackup];
        _homePoint = [aDecoder decodeObjectForKey:kHomePoint];
        _workPoint = [aDecoder decodeObjectForKey:kWorkPoint];
        _myLocationToStart = [aDecoder decodeObjectForKey:kMyLocationToStart];
        
        [self safeInit];
    }
    return self;
}

#pragma mark -

@end
