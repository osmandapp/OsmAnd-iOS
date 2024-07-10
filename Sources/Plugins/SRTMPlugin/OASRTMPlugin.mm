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
#import "OAProducts.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAContourLinesAction.h"
#import "OATerrainAction.h"
#import "Localization.h"
#import "OALinks.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const PLUGIN_ID = kInAppId_Addon_Srtm;
static NSString * const kEnable3dMaps = @"enable_3d_maps";
static NSString * const kTerrainMode = @"terrain_mode";
static NSString * const kTerrain = @"terrain_layer";

@implementation OASRTMPlugin

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _enable3DMaps = [[[settings registerBooleanPreference:kEnable3dMaps defValue:YES] makeProfile] makeShared];

        _terrain = [[self registerBooleanPreference:kTerrain defValue:YES] makeProfile];
        NSArray<TerrainMode *> *tms = TerrainMode.values;
        _terrainModeType = [[self registerStringPreference:kTerrainMode defValue:tms.count == 0 ? @"" : [tms.firstObject getKeyName]] makeProfile];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onProfileSettingSet:)
                                                     name:kNotificationSetProfileSetting
                                                   object:nil];
        
    }
    return self;
}

- (NSString *)getId
{
    return PLUGIN_ID;
}

- (BOOL)isEnabled
{
    return [super isEnabled] && [[OAIAPHelper sharedInstance].srtm isActive];
}

- (NSArray<OAResourceItem *> *)getSuggestedMaps
{
    NSMutableArray *suggestedMaps = [NSMutableArray new];
    CLLocationCoordinate2D latLon = [OAResourcesUIHelper getMapLocation];
    
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion latLon:latLon]];
    [suggestedMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:OsmAnd::ResourcesManager::ResourceType::GeoTiffRegion latLon:latLon]];
    
    return suggestedMaps;
}

- (NSString *)getName
{
    return OALocalizedString(@"srtm_plugin_name");
}

- (NSString *)getDescription
{
    return [NSString stringWithFormat:NSLocalizedString(@"srtm_plugin_description", nil), k_docs_plugin_srtm];
}

- (TerrainMode *)getTerrainMode
{
    return [TerrainMode getByKey:[_terrainModeType get]];
}

- (void)setTerrainMode:(TerrainMode *)mode
{
    return [_terrainModeType set:[mode getKeyName]];
}

- (BOOL)isTerrainLayerEnabled
{
    return [_terrain get];
}

- (void)setTerrainLayerEnabled:(BOOL)enabled
{
    [_terrain set:enabled];
    [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (NSInteger)getTerrainMinZoom
{
    return MAX(terrainMinSupportedZoom, [[self getTerrainMode] getMinZoom]);
}


- (NSInteger)getTerrainMaxZoom
{
    return MIN(terrainMaxSupportedZoom, [[self getTerrainMode] getMaxZoom]);
}

- (BOOL)isHeightmapEnabled
{
    return [self isHeightmapAllowed];
}

- (BOOL)isHeightmapAllowed
{
    return [OAIAPHelper isOsmAndProAvailable];
}

- (BOOL)is3DMapsEnabled
{
    return [self isHeightmapEnabled] && [_enable3DMaps get];
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    if (notification.object == _enable3DMaps)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [OARootViewController.instance.mapPanel.mapViewController recreateHeightmapProvider];
        });
    }
}

- (NSArray<QuickActionType *> *)getQuickActionTypes
{
    return @[OAContourLinesAction.TYPE, OATerrainAction.TYPE];
}

@end

