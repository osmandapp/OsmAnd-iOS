//
//  OANauticalMapsPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OANauticalMapsPlugin.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "Localization.h"
#import "OALinks.h"

#define PLUGIN_ID kInAppId_Addon_Nautical

@implementation OANauticalMapsPlugin

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (NSArray<OAApplicationMode *> *) getAddedAppModes
{
    return @[OAApplicationMode.BOAT];
}

- (NSString *) getName
{
    return OALocalizedString(@"plugin_nautical_name");
}

- (NSString *) getDescription
{
    return [NSString stringWithFormat:NSLocalizedString(@"plugin_nautical_descr", nil), k_docs_plugin_nautical];
}

@end

