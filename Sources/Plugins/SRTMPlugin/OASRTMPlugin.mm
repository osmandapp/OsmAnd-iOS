//
//  OASRTMPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASRTMPlugin.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAContourLinesAction.h"
#import "OATerrainAction.h"
#import "Localization.h"
#import "OALinks.h"

#define PLUGIN_ID kInAppId_Addon_Srtm

#define kEnable3dMaps @"enable_3d_maps"

@implementation OASRTMPlugin
{
    OACommonBoolean *_enable3dMap;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _enable3DMaps = [[[settings registerBooleanPreference:kEnable3dMaps defValue:YES] makeProfile] makeShared];
        [[settings getPreferences:NO] setObject:_enable3DMaps forKey:@"enable_3d_maps"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    }
    return self;
}

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
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::GeoTiffRegion latLon:latLon]];
    
    return suggestedMaps;
}

- (NSString *) getName
{
    return OALocalizedString(@"srtm_plugin_name");
}

- (NSString *)getDescription {
    return [NSString stringWithFormat:NSLocalizedString(@"srtm_plugin_description", nil), k_docs_plugin_srtm];
}



- (BOOL) isHeightmapEnabled
{
    return [self isHeightmapAllowed];
}

- (BOOL) isHeightmapAllowed
{
    return [OAIAPHelper isOsmAndProAvailable];
}

- (BOOL) is3DMapsEnabled
{
    return [self isHeightmapEnabled] && [_enable3DMaps get];
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    if (obj == _enable3DMaps)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [OARootViewController.instance.mapPanel.mapViewController recreateHeightmapProvider];
        });
    }
}

- (NSArray *)getQuickActionTypes
{
    return @[OAContourLinesAction.TYPE, OATerrainAction.TYPE];
}

@end

