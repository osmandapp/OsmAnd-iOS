//
//  OAOsmandDevelopmentPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 31.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentPlugin.h"
#import "OAProducts.h"

#define PLUGIN_ID kInAppId_Addon_OsmandDevelopment

@implementation OAOsmandDevelopmentPlugin

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (BOOL)isEnableByDefault
{
    return NO;
}

@end
