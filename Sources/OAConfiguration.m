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
    NSMutableDictionary* mapSourcesPresets = [[NSMutableDictionary alloc] init];
    OAMapSourcePreset* defaultGeneralPreset = [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeGeneral"
                                                                                          andType:OAMapSourcePresetTypeGeneral
                                                                                        andValues:@{ @"appMode" : @"browse map" }];
    OAMapSourcePreset* defaultCarPreset = [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeCar"
                                                                                      andType:OAMapSourcePresetTypeCar
                                                                                    andValues:@{ @"appMode" : @"car" }];
    OAMapSourcePreset* defaultBicyclePreset = [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeBicycle"
                                                                                          andType:OAMapSourcePresetTypeBicycle
                                                                                        andValues:@{ @"appMode" : @"bicycle" }];
    OAMapSourcePreset* defaultPedestrianPreset = [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypePedestrian"
                                                                                             andType:OAMapSourcePresetTypePedestrian
                                                                                           andValues:@{ @"appMode" : @"pedestrian" }];
    NSMutableDictionary* encodedDefaultPresets = [[NSMutableDictionary alloc] init];
    [encodedDefaultPresets setObject:[NSKeyedArchiver archivedDataWithRootObject:defaultPedestrianPreset]
                              forKey:@"05111A11-D000-0000-0004-00000000F001"];
    [encodedDefaultPresets setObject:[NSKeyedArchiver archivedDataWithRootObject:defaultBicyclePreset]
                              forKey:@"05111A11-D000-0000-0003-0000000B1CCE"];
    [encodedDefaultPresets setObject:[NSKeyedArchiver archivedDataWithRootObject:defaultCarPreset]
                              forKey:@"05111A11-D000-0000-0002-000000000CAA"];
    [encodedDefaultPresets setObject:[NSKeyedArchiver archivedDataWithRootObject:defaultGeneralPreset]
                              forKey:@"05111A11-D000-0000-0001-000000000DEF"];
    [mapSourcesPresets setObject:encodedDefaultPresets
                          forKey:kDefaultMapSource];
    [defaults setObject:mapSourcesPresets
                 forKey:kMapSourcesPresets];
    
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

- (NSDictionary*)getMapSourcesPresets
{
    NSDictionary* container = nil;
    @synchronized(self)
    {
        container = [_storage objectForKey:kMapSourcesPresets];
    }
    
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    
    [container enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* mapSource = key;
        NSDictionary* encodedPresets = obj;
        NSMutableDictionary* decodedPresets = [[NSMutableDictionary alloc] init];
        [encodedPresets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSUUID* presetId = [[NSUUID alloc] initWithUUIDString:key];
            NSData* data = obj;
            OAMapSourcePreset* preset = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            
            [decodedPresets setObject:preset forKey:presetId];
        }];
        
        [result setObject:decodedPresets forKey:mapSource];
    }];
    
    return [NSDictionary dictionaryWithDictionary:result];

}

- (NSUUID*)addMapSourcePreset:(OAMapSourcePreset*)preset forMapSource:(NSString*)mapSource
{
    NSData* encodedPreset = [NSKeyedArchiver archivedDataWithRootObject:preset];
    
    NSUUID* presetId;
    @synchronized(self)
    {
        NSMutableDictionary* container = [_storage objectForKey:kMapSourcesPresets];
        if(container == nil)
            container = [[NSMutableDictionary alloc] init];
        
        NSMutableDictionary* innerContainer = [container objectForKey:mapSource];
        if(innerContainer == nil)
            innerContainer = [[NSMutableDictionary alloc] init];
        for(;;)
        {
            presetId = [NSUUID UUID];
            if([innerContainer objectForKey:presetId] == nil)
                break;
        }
        [innerContainer setObject:encodedPreset forKey:[presetId UUIDString]];
        
        [_storage setObject:container forKey:kMapSourcesPresets];
        [_observable notifyEventWithKey:kMapSourcesPresets andValue:presetId];
    }
    
    return presetId;
}

- (BOOL)removeMapSourcePresetWithId:(NSUUID*)presetId forMapSource:(NSString*)mapSource
{
    NSString* presetIdAsString = [presetId UUIDString];
    @synchronized(self)
    {
        NSMutableDictionary* container = [_storage objectForKey:kMapSourcesPresets];
        NSMutableDictionary* innerContainer = [container objectForKey:mapSource];
        if(innerContainer == nil)
            return NO;
        BOOL hadPreset = ([innerContainer objectForKey:presetIdAsString] != nil);
        if(hadPreset)
            [innerContainer removeObjectForKey:presetIdAsString];

        [_observable notifyEventWithKey:kMapSourcesPresets andValue:presetId];
        
        return hadPreset;
    }
}

@end
