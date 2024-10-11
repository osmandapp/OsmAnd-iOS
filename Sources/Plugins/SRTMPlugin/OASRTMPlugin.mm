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
static NSString * const kEnable3dMapsPrefName = @"enable_3d_maps";
static NSString * const kTerrainModePrefName = @"terrain_mode";
static NSString * const kTerrainEnabledPrefName = @"terrain_layer";

NSInteger const terrainMinSupportedZoom = 4;
NSInteger const terrainMaxSupportedZoom = 19;
NSInteger const hillshadeDefaultTrasparency = 100;
NSInteger const defaultTrasparency = 80;

@implementation OASRTMPlugin

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _enable3dMapsPref = [[[settings registerBooleanPreference:kEnable3dMapsPrefName defValue:YES] makeProfile] makeShared];

        _terrainEnabledPref = [[self registerBooleanPreference:kTerrainEnabledPrefName defValue:YES] makeProfile];
        NSArray<TerrainMode *> *tms = TerrainMode.values;
        _terrainModeTypePref = [[self registerStringPreference:kTerrainModePrefName defValue:tms.count == 0 ? @"" : [tms.firstObject getKeyName]] makeProfile];

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
    return [NSString stringWithFormat:OALocalizedString(@"srtm_plugin_description", nil), k_docs_plugin_srtm];
}

- (TerrainMode *)getTerrainMode
{
    return [TerrainMode getByKey:[_terrainModeTypePref get]];
}

- (void)setTerrainMode:(TerrainMode *)mode
{
    return [_terrainModeTypePref set:[mode getKeyName]];
}

- (BOOL)isTerrainLayerEnabled
{
    return [_terrainEnabledPref get];
}

- (void)setTerrainLayerEnabled:(BOOL)enabled
{
    [_terrainEnabledPref set:enabled];
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
    return [self isHeightmapEnabled] && [_enable3dMapsPref get];
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    if (notification.object == _enable3dMapsPref)
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

