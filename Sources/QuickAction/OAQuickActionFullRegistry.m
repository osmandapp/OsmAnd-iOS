//
//  OAQuickActionFullRegistry.m
//  OsmAnd
//
//  Created by nnngrach on 18.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAQuickActionFullRegistry.h"
#import "OAPlugin.h"

@implementation OAQuickActionFullRegistry

+ (instancetype)sharedInstance
{
    static OAQuickActionFullRegistry *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAQuickActionFullRegistry alloc] init];
    });
    return _sharedInstance;
}


- (void) registerPluginDependedActions:(NSMutableArray<OAQuickActionType *> *)quickActionTypes
{
    [OAPlugin registerAllQuickActionTypesPlugins:quickActionTypes];
}

@end
