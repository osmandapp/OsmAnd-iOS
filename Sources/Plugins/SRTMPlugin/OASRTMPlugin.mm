//
//  OASRTMPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASRTMPlugin.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"

#define PLUGIN_ID kInAppId_Addon_Srtm

@implementation OASRTMPlugin

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (BOOL)isEnabled
{
    return [super isEnabled] && [[OAIAPHelper sharedInstance].srtm isActive];
}

- (NSArray<OAResourceItem *> *) getSuggestedMaps
{
    NSMutableArray *suggestedMaps = [NSMutableArray new];
    CLLocationCoordinate2D latLon = [OAResourcesUIHelper getMapLocation];
    
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion latLon:latLon]];
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::HillshadeRegion latLon:latLon]];
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::SlopeRegion latLon:latLon]];
    
    return suggestedMaps;
}

- (NSString *) getName
{
    return OALocalizedString(@"srtm_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"srtm_plugin_description");
}

@end

