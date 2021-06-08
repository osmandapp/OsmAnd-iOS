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
#import "OrderedDictionary.h"

#include <objc/runtime.h>

#define kLastMapSourceKey @"lastMapSource"
#define kOverlaySourceKey @"overlayMapSource"
#define kUnderlaySourceKey @"underlayMapSource"
#define kLastOverlayKey @"lastOverlayMapSource"
#define kLastUnderlayKey @"lastUnderlayMapSource"
#define kOverlayAlphaKey @"overlayAlpha"
#define kUnderlayAlphaKey @"underlayAlpha"
#define kMapLayersConfigurationKey @"mapLayersConfiguration"

#define kTerrainTypeKey @"terrainType"
#define kLastTerrainTypeKey @"lastTerrainType"
#define kHillshadeAlphaKey @"hillshadeAlpha"
#define kSlopeAlphaKey @"slopeAlpha"
#define kHillshadeMinZoomKey @"hillshadeMinZoom"
#define kHillshadeMaxZoomKey @"hillshadeMaxZoom"
#define kSlopeMinZoomKey @"slopeMinZoom"
#define kSlopeMaxZoomKey @"slopeMaxZoom"
#define kMapillaryKey @"mapillary"

@implementation OAAppData
{
    NSObject* _lock;
    NSMutableDictionary* _lastMapSources;
    
    OAAutoObserverProxy *_applicationModeChangedObserver;
    
    NSMutableArray<OARTargetPoint *> *_intermediates;
    
    OACommonMapSource *_lastMapSourceProfile;
    OACommonMapSource *_overlayMapSourceProfile;
    OACommonMapSource *_lastOverlayMapSourceProfile;
    OACommonMapSource *_underlayMapSourceProfile;
    OACommonMapSource  *_lastUnderlayMapSourceProfile;
    OACommonDouble *_overlayAlphaProfile;
    OACommonDouble *_underlayAlphaProfile;
    OACommonTerrain *_terrainTypeProfile;
    OACommonTerrain *_lastTerrainTypeProfile;
    OACommonDouble *_hillshadeAlphaProfile;
    OACommonInteger *_hillshadeMinZoomProfile;
    OACommonInteger *_hillshadeMaxZoomProfile;
    OACommonDouble *_slopeAlphaProfile;
    OACommonInteger *_slopeMinZoomProfile;
    OACommonInteger *_slopeMaxZoomProfile;
    OACommonBoolean *_mapillaryProfile;
    
    NSMapTable<NSString *, OACommonPreference *> *_registeredPreferences;
}

@synthesize applicationModeChangedObservable = _applicationModeChangedObservable, mapLayersConfiguration = _mapLayersConfiguration;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        [self safeInit];
    }
    return self;
}

- (void) setSettingValue:(NSString *)value forKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        if ([key isEqualToString:@"terrain_mode"])
        {
            [_lastTerrainTypeProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_min_zoom"])
        {
            [_hillshadeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_max_zoom"])
        {
            [_hillshadeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_hillshadeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_slopeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_min_zoom"])
        {
            [_slopeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"slope_max_zoom"])
        {
            [_slopeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"show_mapillary"])
        {
            [_mapillaryProfile setValueFromString:value appMode:mode];
        }
    }
}

- (void) addPreferenceValuesToDictionary:(MutableOrderedDictionary *)prefs mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        prefs[@"terrain_mode"] = [_lastTerrainTypeProfile toStringValue:mode];
        prefs[@"hillshade_min_zoom"] = [_hillshadeMinZoomProfile toStringValue:mode];
        prefs[@"hillshade_max_zoom"] = [_hillshadeMaxZoomProfile toStringValue:mode];
        prefs[@"hillshade_transparency"] = [NSString stringWithFormat:@"%d", (int) ([_hillshadeAlphaProfile get:mode] * 100)];
        prefs[@"slope_transparency"] = [NSString stringWithFormat:@"%d", (int) ([_slopeAlphaProfile get:mode] * 100)];
        prefs[@"slope_min_zoom"] = [_slopeMinZoomProfile toStringValue:mode];
        prefs[@"slope_max_zoom"] = [_slopeMaxZoomProfile toStringValue:mode];
        prefs[@"show_mapillary"] = [_mapillaryProfile toStringValue:mode];
    }
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
    _mapLayersConfigurationChangeObservable = [[OAObservable alloc] init];
    
    _applicationModeChangedObservable = [[OAObservable alloc] init];
    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:_applicationModeChangedObservable];
    _mapLayersConfiguration = [[OAMapLayersConfiguration alloc] init];
    // Profile settings
    _lastMapSourceProfile = [OACommonMapSource withKey:kLastMapSourceKey defValue:[[OAMapSource alloc] initWithResource:@"default.render.xml"
                                                                                                             andVariant:@"type_default"]];
    _overlayMapSourceProfile = [OACommonMapSource withKey:kOverlaySourceKey defValue:nil];
    _underlayMapSourceProfile = [OACommonMapSource withKey:kUnderlaySourceKey defValue:nil];
    _lastOverlayMapSourceProfile = [OACommonMapSource withKey:kLastOverlayKey defValue:nil];
    _lastUnderlayMapSourceProfile = [OACommonMapSource withKey:kLastUnderlayKey defValue:nil];
    _overlayAlphaProfile = [OACommonDouble withKey:kOverlayAlphaKey defValue:0.5];
    _underlayAlphaProfile = [OACommonDouble withKey:kUnderlayAlphaKey defValue:0.5];
    _terrainTypeProfile = [OACommonTerrain withKey:kTerrainTypeKey defValue:EOATerrainTypeDisabled];
    _lastTerrainTypeProfile = [OACommonTerrain withKey:kLastTerrainTypeKey defValue:EOATerrainTypeHillshade];
    _hillshadeAlphaProfile = [OACommonDouble withKey:kHillshadeAlphaKey defValue:0.45];
    _slopeAlphaProfile = [OACommonDouble withKey:kSlopeAlphaKey defValue:0.35];
    _hillshadeMinZoomProfile = [OACommonInteger withKey:kHillshadeMinZoomKey defValue:3];
    _hillshadeMaxZoomProfile = [OACommonInteger withKey:kHillshadeMaxZoomKey defValue:16];
    _slopeMinZoomProfile = [OACommonInteger withKey:kSlopeMinZoomKey defValue:3];
    _slopeMaxZoomProfile = [OACommonInteger withKey:kSlopeMaxZoomKey defValue:16];
    _mapillaryProfile = [OACommonBoolean withKey:kMapillaryKey defValue:NO];

    _registeredPreferences = [NSMapTable strongToStrongObjectsMapTable];
    [_registeredPreferences setObject:_overlayMapSourceProfile forKey:@"map_overlay_previous"];
    [_registeredPreferences setObject:_underlayMapSourceProfile forKey:@"map_underlay_previous"];
    [_registeredPreferences setObject:_overlayAlphaProfile forKey:@"overlay_transparency"];
    [_registeredPreferences setObject:_underlayAlphaProfile forKey:@"map_transparency"];
    [_registeredPreferences setObject:_lastTerrainTypeProfile forKey:@"terrain_mode"];
    [_registeredPreferences setObject:_hillshadeAlphaProfile forKey:@"hillshade_transparency"];
    [_registeredPreferences setObject:_slopeAlphaProfile forKey:@"slope_transparency"];
    [_registeredPreferences setObject:_hillshadeMinZoomProfile forKey:@"hillshade_min_zoom"];
    [_registeredPreferences setObject:_hillshadeMaxZoomProfile forKey:@"hillshade_max_zoom"];
    [_registeredPreferences setObject:_slopeMinZoomProfile forKey:@"slope_min_zoom"];
    [_registeredPreferences setObject:_slopeMaxZoomProfile forKey:@"slope_max_zoom"];
    [_registeredPreferences setObject:_mapillaryProfile forKey:@"show_mapillary"];
    [_registeredPreferences setObject:_terrainTypeProfile forKey:@"terrain_mode"];
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
        [_mapLayersConfiguration resetConfigutation];
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@YES];
        if (self.terrainType != EOATerrainTypeDisabled)
            [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:self.terrainType == EOATerrainTypeHillshade ? @(self.hillshadeAlpha) : @(self.slopeAlpha)];
        [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        [self setLastMapSourceVariant:[OAAppSettings sharedManager].applicationMode.variantKey];
    });
}

- (void) safeInit
{
    if (_lastMapSources == nil)
        _lastMapSources = [[NSMutableDictionary alloc] init];
    if (_mapLastViewedState == nil)
        _mapLastViewedState = [[OAMapViewState alloc] init];
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

- (OAMapSource*) lastMapSource
{
    @synchronized(_lock)
    {
        return [_lastMapSourceProfile get];
    }
}

- (OAMapSource *) getLastMapSource:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastMapSourceProfile get:mode];
    }
}

- (void) setLastMapSource:(OAMapSource *)lastMapSource mode:(OAApplicationMode *)mode
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:[_lastMapSourceProfile get:mode]])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get:mode];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            [_lastMapSourceProfile set:[lastMapSource copy] mode:mode];
        }
    }
}

- (void) setLastMapSource:(OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:self.lastMapSource])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            
            // Save new one
            [_lastMapSourceProfile set:[lastMapSource copy]];
            [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        }
    }
}

- (void) setLastMapSourceVariant:(NSString *)variant
{
    OAMapSource *lastSource = self.lastMapSource;
    if ([lastSource.resourceId isEqualToString:@"online_tiles"])
        return;
    
    OAMapSource *mapSource = [[OAMapSource alloc] initWithResource:lastSource.resourceId andVariant:variant name:lastSource.name];
    [_lastMapSourceProfile set:mapSource];
}

@synthesize lastMapSourceChangeObservable = _lastMapSourceChangeObservable;

- (OAMapSource*) lastMapSourceByResourceId:(NSString*)resourceId
{
    @synchronized(_lock)
    {
        OAMapSource *lastMapSource = self.lastMapSource;
        if (lastMapSource != nil && [lastMapSource.resourceId isEqualToString:resourceId])
            return lastMapSource;

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

- (OAMapSource*) overlayMapSource
{
    @synchronized(_lock)
    {
        return [_overlayMapSourceProfile get];
    }
}

- (void) setOverlayMapSource:(OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        [_overlayMapSourceProfile set:[overlayMapSource copy]];
        [_overlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.overlayMapSource];
    }
}

- (OAMapSource*) lastOverlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastOverlayMapSourceProfile get];
    }
}

- (void) setLastOverlayMapSource:(OAMapSource*)lastOverlayMapSource
{
    @synchronized(_lock)
    {
        [_lastOverlayMapSourceProfile set:[lastOverlayMapSource copy]];
    }
}

- (OAMapSource*) underlayMapSource
{
    @synchronized(_lock)
    {
        return [_underlayMapSourceProfile get];
    }
}

- (void) setUnderlayMapSource:(OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        [_underlayMapSourceProfile set:[underlayMapSource copy]];
        [_underlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.underlayMapSource];
    }
}

- (OAMapSource*) lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastUnderlayMapSourceProfile get];
    }
}

- (void) setLastUnderlayMapSource:(OAMapSource*)lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        [_lastUnderlayMapSourceProfile set:[lastUnderlayMapSource copy]];
    }
}

- (double) overlayAlpha
{
    @synchronized (_lock)
    {
        return [_overlayAlphaProfile get];
    }
}

- (void) setOverlayAlpha:(double)overlayAlpha
{
    @synchronized(_lock)
    {
        [_overlayAlphaProfile set:overlayAlpha];
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
    }
}

- (double) underlayAlpha
{
    @synchronized (_lock)
    {
        return [_underlayAlphaProfile get];
    }
}

- (void) setUnderlayAlpha:(double)underlayAlpha
{
    @synchronized(_lock)
    {
        [_underlayAlphaProfile set:underlayAlpha];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
    }
}

- (OAMapLayersConfiguration *)mapLayersConfiguration
{
    @synchronized (_lock)
    {
        return _mapLayersConfiguration;
    }
}

- (NSInteger) hillshadeMinZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMinZoomProfile get];
    }
}

- (void) setHillshadeMinZoom:(NSInteger)hillshadeMinZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMinZoomProfile set:(int)hillshadeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMaxZoomProfile get];
    }
}

- (void) setHillshadeMaxZoom:(NSInteger)hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMaxZoomProfile set:(int)hillshadeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMinZoom
{
    @synchronized(_lock)
    {
        return [_slopeMinZoomProfile get];
    }
}

- (void) setSlopeMinZoom:(NSInteger)slopeMinZoom
{
    @synchronized(_lock)
    {
        [_slopeMinZoomProfile set:(int)slopeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMaxZoom
{
    @synchronized(_lock)
    {
        return [_slopeMaxZoomProfile get];
    }
}

- (void) setSlopeMaxZoom:(NSInteger)slopeMaxZoom
{
    @synchronized(_lock)
    {
        [_slopeMaxZoomProfile set:(int)slopeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (EOATerrainType) terrainType
{
    @synchronized(_lock)
    {
        return [_terrainTypeProfile get];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType
{
    @synchronized(_lock)
    {
        [_terrainTypeProfile set:terrainType];
        if (terrainType == EOATerrainTypeHillshade || terrainType == EOATerrainTypeSlope)
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
        else
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(NO)];
    }
}

- (EOATerrainType) getTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_terrainTypeProfile get:mode];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_terrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) getLastTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastTerrainTypeProfile get:mode];
    }
}

- (void) setLastTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_lastTerrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) lastTerrainType
{
    @synchronized(_lock)
    {
        return [_lastTerrainTypeProfile get];
    }
}

- (void) setLastTerrainType:(EOATerrainType)lastTerrainType
{
    @synchronized(_lock)
    {
        [_lastTerrainTypeProfile set:lastTerrainType];
    }
}


- (double)hillshadeAlpha
{
    @synchronized (_lock)
    {
        return [_hillshadeAlphaProfile get];
    }
}

- (void) setHillshadeAlpha:(double)hillshadeAlpha
{
    @synchronized(_lock)
    {
        [_hillshadeAlphaProfile set:hillshadeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.hillshadeAlpha]];
    }
}

- (double)slopeAlpha
{
    @synchronized (_lock)
    {
        return [_slopeAlphaProfile get];
    }
}

- (void) setSlopeAlpha:(double)slopeAlpha
{
    @synchronized(_lock)
    {
        [_slopeAlphaProfile set:slopeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.slopeAlpha]];
    }
}

- (BOOL) mapillary
{
    @synchronized (_lock)
    {
        return [_mapillaryProfile get];
    }
}

- (void) setMapillary:(BOOL)mapillary
{
    @synchronized (_lock)
    {
        [_mapillaryProfile set:mapillary];
        [_mapillaryChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithBool:self.mapillary]];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;

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
    
    // Imagine that last viewed location was center of the world
    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    return defaults;
}

+ (OAMapSource *) defaultMapSource
{
    return [[OAMapSource alloc] initWithResource:@"default.render.xml"
                                      andVariant:@"type_default"];
}

#pragma mark - NSCoding

#define kLastMapSources @"last_map_sources"
#define kMapLastViewedState @"map_last_viewed_state"
#define kDestinations @"destinations"

#define kPointToStart @"pointToStart"
#define kPointToNavigate @"pointToNavigate"
#define kIntermediatePoints @"intermediatePoints"

#define kPointToStartBackup @"pointToStartBackup"
#define kPointToNavigateBackup @"pointToNavigateBackup"
#define kIntermediatePointsBackup @"intermediatePointsBackup"

#define kMyLocationToStart @"myLocationToStart"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_destinations forKey:kDestinations];
    
    [aCoder encodeObject:_pointToStart forKey:kPointToStart];
    [aCoder encodeObject:_pointToNavigate forKey:kPointToNavigate];
    [aCoder encodeObject:_intermediates forKey:kIntermediatePoints];
    [aCoder encodeObject:_pointToStartBackup forKey:kPointToStartBackup];
    [aCoder encodeObject:_pointToNavigateBackup forKey:kPointToNavigateBackup];
    [aCoder encodeObject:_intermediatePointsBackup forKey:kIntermediatePointsBackup];
    [aCoder encodeObject:_myLocationToStart forKey:kMyLocationToStart];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _lastMapSources = [aDecoder decodeObjectForKey:kLastMapSources];
        _mapLastViewedState = [aDecoder decodeObjectForKey:kMapLastViewedState];
        _destinations = [aDecoder decodeObjectForKey:kDestinations];

        _pointToStart = [aDecoder decodeObjectForKey:kPointToStart];
        _pointToNavigate = [aDecoder decodeObjectForKey:kPointToNavigate];
        _intermediates = [aDecoder decodeObjectForKey:kIntermediatePoints];
        _pointToStartBackup = [aDecoder decodeObjectForKey:kPointToStartBackup];
        _pointToNavigateBackup = [aDecoder decodeObjectForKey:kPointToNavigateBackup];
        _intermediatePointsBackup = [aDecoder decodeObjectForKey:kIntermediatePointsBackup];
        _myLocationToStart = [aDecoder decodeObjectForKey:kMyLocationToStart];
        
        [self safeInit];
    }
    return self;
}

- (void) resetProfileSettingsForMode:(OAApplicationMode *)mode
{
    for (OACommonPreference *value in [_registeredPreferences objectEnumerator].allObjects)
    {
        [value resetModeToDefault:mode];
    }
}

#pragma mark - Copying profiles

- (void) copyAppDataFrom:(OAApplicationMode *)sourceMode toMode:(OAApplicationMode *)targetMode
{
    [_mapLayersConfiguration resetConfigutation];
    [_lastMapSourceProfile set:[_lastMapSourceProfile get:sourceMode] mode:targetMode];
    [_overlayMapSourceProfile set:[_overlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_underlayMapSourceProfile set:[_underlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_lastOverlayMapSourceProfile set:[_lastOverlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_lastUnderlayMapSourceProfile set:[_lastUnderlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_overlayAlphaProfile set:[_overlayAlphaProfile get:sourceMode] mode:targetMode];
    [_underlayAlphaProfile set:[_underlayAlphaProfile get:sourceMode] mode:targetMode];
    [_terrainTypeProfile set:[_terrainTypeProfile get:sourceMode] mode:targetMode];
    [_lastTerrainTypeProfile set:[_lastTerrainTypeProfile get:sourceMode] mode:targetMode];
    [_hillshadeAlphaProfile set:[_hillshadeAlphaProfile get:sourceMode] mode:targetMode];
    [_slopeAlphaProfile set:[_slopeAlphaProfile get:sourceMode] mode:targetMode];
    [_hillshadeMinZoomProfile set:[_hillshadeMinZoomProfile get:sourceMode] mode:targetMode];
    [_hillshadeMaxZoomProfile set:[_hillshadeMaxZoomProfile get:sourceMode] mode:targetMode];
    [_slopeMinZoomProfile set:[_slopeMinZoomProfile get:sourceMode] mode:targetMode];
    [_slopeMaxZoomProfile set:[_slopeMaxZoomProfile get:sourceMode] mode:targetMode];
    [_mapillaryProfile set:[_mapillaryProfile get:sourceMode] mode:targetMode];
}

@end
