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

@implementation OAConfiguration
{
    NSUserDefaults* _storage;
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
    
    // Upgrade configuration if needed
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
    
    NSMutableDictionary* defaults = [[NSMutableDictionary alloc] init];
    
    // Map sources defaults
    [defaults setObject:kDefaultMapSource
                 forKey:kMapSource];
    NSMutableDictionary* defaultMapSourcePresets = [[NSMutableDictionary alloc] init];
    [self registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeGeneral"
                                                                              andType:OAMapSourcePresetTypeGeneral
                                                                            andValues:@{ @"appMode" : @"browse map" }]
                           withId:@"05111A11-D000-0000-0001-000000000DEF"
                               in:defaultMapSourcePresets];
    [self registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeCar"
                                                                              andType:OAMapSourcePresetTypeCar
                                                                            andValues:@{ @"appMode" : @"car" }]
                           withId:@"05111A11-D000-0000-0002-000000000CAA"
                               in:defaultMapSourcePresets];
    [self registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeBicycle"
                                                                              andType:OAMapSourcePresetTypeBicycle
                                                                            andValues:@{ @"appMode" : @"bicycle" }]
                           withId:@"05111A11-D000-0000-0003-0000000B1CCE"
                               in:defaultMapSourcePresets];
    [self registerMapSourcePreset:[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypePedestrian"
                                                                              andType:OAMapSourcePresetTypePedestrian
                                                                            andValues:@{ @"appMode" : @"pedestrian" }]
                           withId:@"05111A11-D000-0000-0004-00000000F001"
                               in:defaultMapSourcePresets];
    [defaults setObject:[[NSMutableDictionary alloc] initWithDictionary:@{ kDefaultMapSource : defaultMapSourcePresets }]
                 forKey:kMapSourcesPresets];
    [defaults setObject:@"05111A11-D000-0000-0001-000000000DEF" forKey:kMapSourcePreset];
    
    // Register defaults
    [_storage registerDefaults:[NSDictionary dictionaryWithDictionary:defaults]];
    [_storage setInteger:vCurrentVersion
                  forKey:kVersion];
    [_storage synchronize];
}

- (BOOL)save
{
    return [_storage synchronize];
}

@synthesize observable = _observable;

- (NSString*)getMapSource
{
    @synchronized(self)
    {
        return [_storage stringForKey:kMapSource];
    }
}

- (void)setMapSource:(NSString*)mapSource
{
    @synchronized(self)
    {
        [_storage setObject:mapSource forKey:kMapSource];
        [_observable notifyEventWithKey:kMapSource andValue:mapSource];
    }
}

#define kMapSourcesPresetsOrder @"_order"

- (void)registerMapSourcePreset:(OAMapSourcePreset*)preset withId:(NSString*)presetId in:(NSMutableDictionary*)storage
{
    NSData* encodedPreset = [NSKeyedArchiver archivedDataWithRootObject:preset];
    
    [storage setObject:encodedPreset forKey:presetId];

    NSMutableArray* order = [storage objectForKey:kMapSourcesPresetsOrder];
    BOOL orderWasInflated = NO;
    if(order == nil)
    {
        order = [[NSMutableArray alloc] initWithCapacity:1];
        orderWasInflated = YES;
    }
    [order addObject:presetId];
    
    if(orderWasInflated)
        [storage setObject:order forKey:kMapSourcesPresetsOrder];
}

- (OAMapSourcePresets*)mapSourcePresetsFor:(NSString*)mapSource
{
    @synchronized(self)
    {
        // Get container with presets for all map-sources
        NSDictionary* container = [_storage objectForKey:kMapSourcesPresets];
        if(container == nil)
            return [[OAMapSourcePresets alloc] initEmpty];
        
        // Get container for presets of specific map-source
        NSMutableDictionary* innerContainer = [container objectForKey:mapSource];
        if(container == nil)
            return [[OAMapSourcePresets alloc] initEmpty];
        
        // Decode presets
        __block NSMutableArray* presetsOrder = nil;
        NSMutableDictionary* decodedPresets = [[NSMutableDictionary alloc] init];
        [innerContainer enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
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
        
        return [[OAMapSourcePresets alloc] initWithPresets:decodedPresets andOrder:presetsOrder];
    }
}

- (NSUUID*)addMapSourcePreset:(OAMapSourcePreset*)preset forMapSource:(NSString*)mapSource
{
    NSData* encodedPreset = [NSKeyedArchiver archivedDataWithRootObject:preset];
    
    NSUUID* presetId;
    @synchronized(self)
    {
        // Get container of all presets (by map-source identifier)
        NSMutableDictionary* container = [_storage objectForKey:kMapSourcesPresets];
        BOOL containerWasInflated = NO;
        if(container == nil)
        {
            container = [[NSMutableDictionary alloc] initWithCapacity:1];
            containerWasInflated = YES;
        }
        
        // Get container for presets of specific map-source
        NSMutableDictionary* innerContainer = [container objectForKey:mapSource];
        BOOL innerContainerWasInflated = NO;
        if(innerContainer == nil)
        {
            innerContainer = [[NSMutableDictionary alloc] initWithCapacity:2];
            innerContainerWasInflated = YES;
        }
        
        // Generate unique UUID and insert preset into container
        for(;;)
        {
            presetId = [NSUUID UUID];
            if([innerContainer objectForKey:presetId] == nil)
                break;
        }
        [innerContainer setObject:encodedPreset forKey:[presetId UUIDString]];
        
        // Insert new UUID into order array
        NSMutableArray* order = [innerContainer objectForKey:kMapSourcesPresetsOrder];
        BOOL orderWasInflated = NO;
        if(order == nil)
        {
            order = [[NSMutableArray alloc] initWithCapacity:1];
            orderWasInflated = YES;
        }
        [order addObject:[presetId UUIDString]];
        
        // Save changes
        if(orderWasInflated)
            [innerContainer setObject:order forKey:kMapSourcesPresetsOrder];
        if(innerContainerWasInflated)
            [container setObject:innerContainer forKey:mapSource];
        if(containerWasInflated)
            [_storage setObject:container forKey:kMapSourcesPresets];
        
        // Notify about change
        [_observable notifyEventWithKey:kMapSourcesPresets andValue:presetId];
    }
    
    return presetId;
}

- (BOOL)removeMapSourcePresetWithId:(NSUUID*)presetId forMapSource:(NSString*)mapSource
{
    NSString* presetIdAsString = [presetId UUIDString];
    @synchronized(self)
    {
        // Get container with all presets
        NSMutableDictionary* container = [_storage objectForKey:kMapSourcesPresets];
        if(container == nil)
            return NO;

        // Get container with presets for specific map-source (and order array)
        NSMutableDictionary* innerContainer = [container objectForKey:mapSource];
        if(innerContainer == nil)
            return NO;
        NSMutableArray* order = [innerContainer objectForKey:kMapSourcesPresetsOrder];
        
        // Check if preset with given identifier exists
        BOOL presetExists = ([innerContainer objectForKey:presetIdAsString] != nil);
        
        // If preset exists, remove it from container and remove from order array
        if(presetExists)
        {
            [innerContainer removeObjectForKey:presetIdAsString];
            [order removeObject:presetIdAsString];
        }
        
        // If inner container is empty, remove it
        if([innerContainer count] == 0)
            [container removeObjectForKey:mapSource];

        [_observable notifyEventWithKey:kMapSourcesPresets andValue:presetId];
        
        return presetExists;
    }
}

- (NSUUID*)getMapSourcePreset
{
    @synchronized(self)
    {
        return [[NSUUID alloc] initWithUUIDString:[_storage stringForKey:kMapSourcePreset]];
    }
}

- (void)setMapSourcePreset:(NSUUID *)mapSourcePreset
{
    @synchronized(self)
    {
        [_storage setObject:[mapSourcePreset UUIDString] forKey:kMapSourcePreset];
        [_observable notifyEventWithKey:kMapSourcePreset andValue:mapSourcePreset];
    }
}

@end
