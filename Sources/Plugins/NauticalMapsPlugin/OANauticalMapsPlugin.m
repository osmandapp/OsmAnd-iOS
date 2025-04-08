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
#import "OsmAnd_Maps-Swift.h"
#import "OAMapSource.h"

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
    return [NSString stringWithFormat:OALocalizedString(@"plugin_nautical_descr"), k_docs_plugin_nautical];
}

- (void)handleActivation
{
    NSString *resourceId = @"nautical.render.xml";
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAApplicationMode *mode = settings.applicationMode.get;
    OAMapSource *mapSource = [app.data lastMapSourceByResourceId:resourceId];
    
    if (!mapSource)
    {
        mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                               andVariant:mode.variantKey
                                                     name:NAUTICAL_RENDER];
    }
    else if (![mapSource.name isEqualToString:NAUTICAL_RENDER])
    {
        mapSource.name = NAUTICAL_RENDER;
    }
    
    OAMapSource *newMapSource = [self isEnabled] ? mapSource : [OAAppData defaultMapSource];
    [app.data setPrevOfflineSource:newMapSource];
    app.data.lastMapSource = newMapSource;
    [settings.renderer set:newMapSource.name];
}

@end

