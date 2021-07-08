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

#define PLUGIN_ID kInAppId_Addon_Srtm

@implementation OASRTMPlugin

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [OAApplicationMode regWidgetVisibility:PLUGIN_ID am:nil];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
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

@end

