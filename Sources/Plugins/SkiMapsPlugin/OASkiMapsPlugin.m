//
//  OASkiMapsPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASkiMapsPlugin.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"

#define PLUGIN_ID kInAppId_Addon_SkiMap

@implementation OASkiMapsPlugin

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (NSArray<OAApplicationMode *> *) getAddedAppModes
{
    return @[OAApplicationMode.SKI];
}

@end

