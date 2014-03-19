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
    [mapSourcesPresets setObject:@[[[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeGeneral"
                                                                               andType:OAMapSourcePresetTypeGeneral
                                                                             andValues:@{ @"appMode" : @"browse map" }],
                                   [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeCar"
                                                                               andType:OAMapSourcePresetTypeCar
                                                                             andValues:@{ @"appMode" : @"car" }],
                                   [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypeBicycle"
                                                                               andType:OAMapSourcePresetTypeBicycle
                                                                             andValues:@{ @"appMode" : @"bicycle" }],
                                   [[OAMapSourcePreset alloc] initWithLocalizedNameKey:@"OAMapSourcePresetTypePedestrian"
                                                                               andType:OAMapSourcePresetTypePedestrian
                                                                             andValues:@{ @"appMode" : @"pedestrian" }]]
                          forKey:kDefaultMapSource];
    [defaults setObject:[NSDictionary dictionaryWithDictionary:mapSourcesPresets]
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
    @synchronized(self)
    {
        return [_storage objectForKey:kMapSourcesPresets];
    }
}

- (void)setMapSourcesPresets:(NSDictionary*)mapSourcesPresets
{
    @synchronized(self)
    {
        [_storage setObject:mapSourcesPresets forKey:kMapSourcesPresets];
        [_observable notifyEventWithKey:kMapSourcesPresets andValue:mapSourcesPresets];
    }
}

@end
