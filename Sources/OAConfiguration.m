//
//  OAConfiguration.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAConfiguration.h"

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
    
    // Set defaults
    NSMutableDictionary* defaults = [[NSMutableDictionary alloc] init];
    [defaults setObject:kMapSourceId_OfflineMaps
                 forKey:kMapSourceId];
    [_storage registerDefaults:defaults];
    [_storage setInteger:vCurrentVersion
                  forKey:kVersion];
    [_storage synchronize];
}

- (BOOL)save
{
    return [_storage synchronize];
}

@synthesize observable = _observable;

- (NSString*)getMapSourceId
{
    return [_storage stringForKey:kMapSourceId];
}

- (void)setMapSourceId:(NSString*)mapSourceId
{
    [_storage setObject:mapSourceId forKey:kMapSourceId];

    [_observable notifyEventWithKey:kMapSourceId andValue:mapSourceId];
}

@end
