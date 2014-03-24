//
//  OAConfiguration.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAConfiguration.h"

#import "OAMapSourcePreset.h"

#define kVersion @"version"
#define vCurrentVersion 1

#define kMapSourcesPresetsOrder @"_order"

@implementation OAConfiguration
{
    NSUserDefaults* _storage;
    BOOL _needsSerialization;

#define _DECLARE_ENTRY(type, name)                                                  \
    BOOL name##Invalidated;                                                         \
    type name

    _DECLARE_ENTRY(NSString*, _activeMapSource);
    
    _DECLARE_ENTRY(NSMutableDictionary*, _mapSourcePresets);
    
    _DECLARE_ENTRY(NSMutableDictionary*, _selectedMapSourcePresets);
    
    _DECLARE_ENTRY(Point31, _lastViewedTarget31);
    _DECLARE_ENTRY(float, _lastViewedZoom);
    _DECLARE_ENTRY(float, _lastViewedAzimuth);
    _DECLARE_ENTRY(float, _lastViewedElevationAngle);
                   
#undef _DECLARE_ENTRY
}

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _observable = [[OAObservable alloc] init];
    _storage = [NSUserDefaults standardUserDefaults];
    
    // Perform upgrade procedures (if such required)
    for(;;)
    {
        const NSInteger storedVersion = [_storage integerForKey:kVersion];
        
        // If no previous version was stored or stored version equals current version,
        // nothing needs to be upgraded
        if(storedVersion == 0 || storedVersion == vCurrentVersion)
            break;
        
        //NOTE: Here place the upgrade code. Template provided
        /*
        if(storedVersion == 4)
        {
            //NOTE: Operations to upgrade from version 4 to version 5
            
            // Save version
            [_storage setInteger:storedVersion+1
                          forKey:kVersion];
            [_storage synchronize];
        }
        */
    }
    
    // Register defaults
    [_storage registerDefaults:[OAConfiguration inflateDefaults]];
    [_storage setInteger:vCurrentVersion
                  forKey:kVersion];
    [_storage synchronize];
    
    // Deserialize data from storage
    _needsSerialization = _activeMapSourceInvalidated = _mapSourcePresetsInvalidated = _selectedMapSourcePresetsInvalidated
        = _lastViewedTarget31Invalidated = _lastViewedZoomInvalidated = _lastViewedAzimuthInvalidated
        = _lastViewedElevationAngleInvalidated
        = NO;
    [self deserializeAll];
}

+ (NSMutableDictionary*)inflateDefaults
{
    NSMutableDictionary* defaults = [[NSMutableDictionary alloc] init];
    
    // Map sources defaults
    [defaults setObject:kDefaultMapSource
                 forKey:kActiveMapSource];
    NSMutableDictionary* defaultMapSourcePresets = [[NSMutableDictionary alloc] init];
    [OAConfiguration registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeGeneral"
                                                                                         andType:OAMapSourcePresetTypeGeneral
                                                                                       andValues:@{ @"appMode" : @"browse map" }]
                                      withId:@"05111A11-D000-0000-0001-000000000DEF"
                                          in:defaultMapSourcePresets];
    [OAConfiguration registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeCar"
                                                                                         andType:OAMapSourcePresetTypeCar
                                                                                       andValues:@{ @"appMode" : @"car" }]
                                      withId:@"05111A11-D000-0000-0002-000000000CAA"
                                          in:defaultMapSourcePresets];
    [OAConfiguration registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeBicycle"
                                                                                         andType:OAMapSourcePresetTypeBicycle
                                                                                       andValues:@{ @"appMode" : @"bicycle" }]
                                      withId:@"05111A11-D000-0000-0003-0000000B1CCE"
                                          in:defaultMapSourcePresets];
    [OAConfiguration registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypePedestrian"
                                                                                         andType:OAMapSourcePresetTypePedestrian
                                                                                       andValues:@{ @"appMode" : @"pedestrian" }]
                                      withId:@"05111A11-D000-0000-0004-00000000F001"
                                          in:defaultMapSourcePresets];
    [defaults setObject:@{ kDefaultMapSource : defaultMapSourcePresets }
                 forKey:kMapSourcesPresets];
    [defaults setObject:@{ kDefaultMapSource : @"05111A11-D000-0000-0001-000000000DEF" }
                 forKey:kSelectedMapSourcePresets];
    
    return defaults;
}

- (void)deserializeAll
{
    NSDictionary* serializedMap;
    //NSArray* serializedArray;
    
    _activeMapSource = [_storage stringForKey:kActiveMapSource];
    
    serializedMap = [_storage objectForKey:kMapSourcesPresets];
    _mapSourcePresets = [[NSMutableDictionary alloc] initWithCapacity:[serializedMap count]];
    [serializedMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* mapSource = key;
        
        NSDictionary* container = obj;
        __block NSMutableArray* presetsOrder = nil;
        NSMutableDictionary* decodedPresets = [[NSMutableDictionary alloc] init];
        [container enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            // Skip order storage
            if([kMapSourcesPresetsOrder isEqualToString:key])
            {
                presetsOrder = [[NSMutableArray alloc] initWithCapacity:[obj count]];
                for (NSString* presetId in obj)
                    [presetsOrder addObject:[[NSUUID alloc] initWithUUIDString:presetId]];
                return;
            }
            
            // Decode preset
            NSUUID* presetId = [[NSUUID alloc] initWithUUIDString:key];
            OAMapSourcePreset* preset = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
            
            [decodedPresets setObject:preset forKey:presetId];
        }];
        
        [_mapSourcePresets setObject:[[OAMapSourcePresets alloc] initWithPresets:decodedPresets andOrder:presetsOrder]
                              forKey:mapSource];
    }];
    
    serializedMap = [_storage objectForKey:kSelectedMapSourcePresets];
    _selectedMapSourcePresets = [[NSMutableDictionary alloc] initWithCapacity:[serializedMap count]];
    [serializedMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [_selectedMapSourcePresets setObject:[[NSUUID alloc] initWithUUIDString:obj] forKey:key];
    }];
    
    _lastViewedTarget31.x = [_storage floatForKey:kLastViewedTarget31".x"];
    _lastViewedTarget31.y = [_storage floatForKey:kLastViewedTarget31".y"];
    _lastViewedZoom = [_storage floatForKey:kLastViewedZoom];
    _lastViewedAzimuth = [_storage floatForKey:kLastViewedAzimuth];
    _lastViewedElevationAngle = [_storage floatForKey:kLastViewedElevationAngle];
}

- (void)serialize
{
    @synchronized(self)
    {
        if(!_needsSerialization)
            return;
        
        NSMutableDictionary* serializedMap;
        
        if(_activeMapSourceInvalidated)
        {
            [_storage setObject:_activeMapSource forKey:kActiveMapSource];
            
            _activeMapSourceInvalidated = NO;
        }
        
        if(_mapSourcePresetsInvalidated)
        {
            serializedMap = [[NSMutableDictionary alloc] initWithCapacity:[_mapSourcePresets count]];
            [_mapSourcePresets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString* mapSource = key;
                OAMapSourcePresets* presets = obj;
                
                NSMutableDictionary* encoded = [[NSMutableDictionary alloc] initWithCapacity:[presets.presets count]+1];
                
                [presets.presets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [encoded setObject:[NSKeyedArchiver archivedDataWithRootObject:obj] forKey:[key UUIDString]];
                }];
                
                NSMutableArray* encodedOrder = [[NSMutableArray alloc] initWithCapacity:[presets.order count]];
                for(NSUUID* presetId in presets.order)
                    [encodedOrder addObject:[presetId UUIDString]];
                [encoded setObject:encodedOrder forKey:kMapSourcesPresetsOrder];
                
                [serializedMap setObject:encoded forKey:mapSource];
            }];
            [_storage setObject:serializedMap forKey:kMapSourcesPresets];
            
            _mapSourcePresetsInvalidated = NO;
        }
        
        if(_selectedMapSourcePresetsInvalidated)
        {
            serializedMap = [[NSMutableDictionary alloc] initWithCapacity:[_selectedMapSourcePresets count]];
            [_selectedMapSourcePresets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [serializedMap setObject:[obj UUIDString] forKey:key];
            }];
            [_storage setObject:serializedMap forKey:kSelectedMapSourcePresets];
            
            _selectedMapSourcePresetsInvalidated = NO;
        }
        
        if(_lastViewedTarget31Invalidated)
        {
            [_storage setFloat:_lastViewedTarget31.x forKey:kLastViewedTarget31".x"];
            [_storage setFloat:_lastViewedTarget31.y forKey:kLastViewedTarget31".y"];
         
            _lastViewedTarget31Invalidated = NO;
        }
        
        if(_lastViewedZoomInvalidated)
        {
            [_storage setFloat:_lastViewedZoom forKey:kLastViewedZoom];
            
            _lastViewedZoomInvalidated = NO;
        }
        
        if(_lastViewedAzimuthInvalidated)
        {
            [_storage setFloat:_lastViewedAzimuth forKey:kLastViewedAzimuth];
         
            _lastViewedAzimuthInvalidated = NO;
        }
        
        if(_lastViewedElevationAngleInvalidated)
        {
            [_storage setFloat:_lastViewedElevationAngle forKey:kLastViewedElevationAngle];
         
            _lastViewedElevationAngleInvalidated = NO;
        }
        
        _needsSerialization = NO;
    }
}

- (BOOL)save
{
    [self serialize];
    return [_storage synchronize];
}

@synthesize observable = _observable;

- (NSString*)getActiveMapSource
{
    @synchronized(self)
    {
        return [NSString stringWithString:_activeMapSource];
    }
}

- (void)setActiveMapSource:(NSString *)activeMapSource
{
    @synchronized(self)
    {
        _activeMapSource = [NSString stringWithString:activeMapSource];

        _needsSerialization = YES;
        _activeMapSourceInvalidated = YES;
        
        [_observable notifyEventWithKey:kActiveMapSource andValue:_activeMapSource];
    }
}

+ (void)registerMapSourcePreset:(OAMapSourcePreset*)preset withId:(NSString*)presetId in:(NSMutableDictionary*)storage
{
    NSData* encodedPreset = [NSKeyedArchiver archivedDataWithRootObject:preset];
    
    [storage setObject:encodedPreset forKey:presetId];

    NSMutableArray* order = [[storage objectForKey:kMapSourcesPresetsOrder] mutableCopy];
    if(order == nil)
        order = [[NSMutableArray alloc] initWithCapacity:1];

    [order addObject:presetId];
    
    [storage setObject:order forKey:kMapSourcesPresetsOrder];
}

- (OAMapSourcePresets*)mapSourcePresetsFor:(NSString *)mapSource
{
    @synchronized(self)
    {
        OAMapSourcePresets* originalPresets = [_mapSourcePresets objectForKey:mapSource];
        if(originalPresets == nil)
            return [[OAMapSourcePresets alloc] initEmpty];
        
        return [[OAMapSourcePresets alloc] initWithPresets:[[NSDictionary alloc] initWithDictionary:originalPresets.presets]
                                                  andOrder:[[NSArray alloc] initWithArray:originalPresets.order]];
    }
}

- (NSUUID*)addMapSourcePreset:(OAMapSourcePreset *)preset forMapSource:(NSString *)mapSource
{
    @synchronized(self)
    {
        OAMapSourcePresets* originalPresetsContainer = [_mapSourcePresets objectForKey:mapSource];
        NSMutableDictionary* presets = nil;
        NSMutableArray* order = nil;
        if(originalPresetsContainer == nil)
        {
            presets = [[NSMutableDictionary alloc] initWithCapacity:1];
            order = [[NSMutableArray alloc] initWithCapacity:1];
        }
        else
        {
            presets = (NSMutableDictionary*)originalPresetsContainer.presets;
            order = (NSMutableArray*)originalPresetsContainer.order;
        }
        
        // Generate unique UUID and insert preset into container
        NSUUID* presetId;
        for(;;)
        {
            presetId = [NSUUID UUID];
            if([presets objectForKey:presetId] == nil)
                break;
        }
        [presets setObject:preset forKey:presetId];
        [order addObject:presetId];
        
        if(originalPresetsContainer == nil)
        {
            [_mapSourcePresets setObject:[[OAMapSourcePresets alloc] initWithPresets:presets
                                                                            andOrder:order]
                                  forKey:mapSource];
        }
        
        _needsSerialization = YES;
        _mapSourcePresetsInvalidated = YES;
        
        // Notify about change
        [_observable notifyEventWithKey:kMapSourcesPresets andValue:mapSource];
        
        return presetId;
    }
}

- (BOOL)removeMapSourcePresetWithId:(NSUUID*)presetId forMapSource:(NSString*)mapSource
{
    @synchronized(self)
    {
        OAMapSourcePresets* originalPresetsContainer = [_mapSourcePresets objectForKey:mapSource];
        if(originalPresetsContainer == nil)
            return NO;
        
        // Check if preset with given identifier exists
        BOOL presetExists = ([originalPresetsContainer.presets objectForKey:presetId] != nil);
        
        // If preset exists, remove it from container and remove from order array
        if(presetExists)
        {
            [(NSMutableDictionary*)originalPresetsContainer.presets removeObjectForKey:presetId];
            [(NSMutableArray*)originalPresetsContainer.order removeObject:presetId];
        }
        
        // If inner container is empty, remove it
        if([originalPresetsContainer.order count] == 0)
            [_mapSourcePresets removeObjectForKey:mapSource];

        _needsSerialization = YES;
        _mapSourcePresetsInvalidated = YES;
        
        [_observable notifyEventWithKey:kMapSourcesPresets andValue:mapSource];
        
        // If preset existed and it was selected, select any-first other
        if(presetExists && [[self selectedMapSourcePresetFor:mapSource] isEqual:presetId])
        {
            NSUUID* newSelection = [originalPresetsContainer.order firstObject];
            [self selectMapSourcePreset:newSelection for:mapSource];
        }
        
        return presetExists;
    }
}

- (NSUUID*)selectedMapSourcePresetFor:(NSString*)mapSource
{
    @synchronized(self)
    {
        return [_selectedMapSourcePresets objectForKey:mapSource];
    }
}

- (void)selectMapSourcePreset:(NSUUID*)preset for:(NSString*)mapSource
{
    @synchronized(self)
    {
        [_selectedMapSourcePresets setObject:preset forKey:mapSource];
        
        _needsSerialization = YES;
        _selectedMapSourcePresetsInvalidated = YES;

        [_observable notifyEventWithKey:kSelectedMapSourcePresets andValue:mapSource];
    }
}

- (Point31)getLastViewedTarget31
{
    @synchronized(self)
    {
        return _lastViewedTarget31;
    }
}

- (void)setLastViewedTarget31:(Point31)lastViewedTarget31
{
    @synchronized(self)
    {
        _lastViewedTarget31 = lastViewedTarget31;
        
        _needsSerialization = YES;
        _lastViewedTarget31Invalidated = YES;
        
        [_observable notifyEventWithKey:kLastViewedTarget31 andValue:[NSValue valueWithBytes:&_lastViewedTarget31
                                                                                    objCType:@encode(Point31)]];
    }
}

- (float)getLastViewedZoom
{
    @synchronized(self)
    {
        return _lastViewedZoom;
    }
}

- (void)setLastViewedZoom:(float)lastViewedZoom
{
    @synchronized(self)
    {
        _lastViewedZoom = lastViewedZoom;
        
        _needsSerialization = YES;
        _lastViewedZoomInvalidated = YES;
        
        [_observable notifyEventWithKey:kLastViewedZoom andValue:[NSNumber numberWithFloat:_lastViewedZoom]];
    }
}

- (float)getLastViewedAzimuth
{
    @synchronized(self)
    {
        return _lastViewedAzimuth;
    }
}

- (void)setLastViewedAzimuth:(float)lastViewedAzimuth
{
    @synchronized(self)
    {
        _lastViewedAzimuth = lastViewedAzimuth;
        
        _needsSerialization = YES;
        _lastViewedAzimuthInvalidated = YES;
        
        [_observable notifyEventWithKey:kLastViewedAzimuth andValue:[NSNumber numberWithFloat:_lastViewedAzimuth]];
    }
}

- (float)getLastViewedElevationAngle
{
    @synchronized(self)
    {
        return _lastViewedElevationAngle;
    }
}

- (void)setLastViewedElevationAngle:(float)lastViewedElevationAngle
{
    @synchronized(self)
    {
        _lastViewedElevationAngle = lastViewedElevationAngle;
        
        _needsSerialization = YES;
        _lastViewedElevationAngleInvalidated = YES;
        
        [_observable notifyEventWithKey:kLastViewedElevationAngle andValue:[NSNumber numberWithFloat:_lastViewedElevationAngle]];
    }
}

@end
