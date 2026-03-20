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
#import "OAMapRendererView.h"
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
static NSString * const kEnable3dMapObjectsName = @"enable_3d_map_objects";
static NSString * const kBuildings3dAlphaPrefName = @"3d_buildings_alpha";
static NSString * const kBuildings3dViewDistancePrefName = @"3d_buildings_view_distance";
static NSString * const kBuildings3dColorStylePrefName = @"buildings_3d_color_style";
static NSString * const kBuildings3dCustomNightColorPrefName = @"buildings_3d_custom_night_color";
static NSString * const kBuildings3dCustomDayColorPrefName = @"buildings_3d_custom_day_color";
static NSString * const kBuildings3dDetailLevelPrefName = @"show3DbuildingParts";
static NSString * const kBuildings3dEnableColoringPrefName = @"useDefaultBuildingColor";
static NSString * const kBuildings3dColorPrefName = @"base3DBuildingsColor";

NSInteger const terrainMinSupportedZoom = 4;
NSInteger const terrainMaxSupportedZoom = 19;
NSInteger const hillshadeDefaultTrasparency = 100;
NSInteger const defaultTrasparency = 80;
NSInteger const kDefaultBuildings3DColor = 0x666666;
NSInteger const buildings3DViewDistanceDefValue = 1;
double const buildings3DAlphaDefValue = 0.5;

@implementation OASRTMPlugin

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _enable3dMapsPref = [[[settings registerBooleanPreference:kEnable3dMapsPrefName defValue:YES] makeProfile] makeShared];

        _enable3dMapObjectsPref = [[self registerBooleanPreference:kEnable3dMapObjectsName defValue:NO] makeProfile];
        _buildings3dAlphaPref = [[self registerFloatPreference:kBuildings3dAlphaPrefName defValue:buildings3DAlphaDefValue] makeProfile];
        _buildings3dViewDistancePref = [[self registerIntPreference:kBuildings3dViewDistancePrefName defValue:buildings3DViewDistanceDefValue] makeProfile];
        _buildings3dColorStylePref = [[self registerIntPreference:kBuildings3dColorStylePrefName defValue:1] makeProfile];
        _buildings3dCustomNightColorPref = [[self registerIntPreference:kBuildings3dCustomNightColorPrefName defValue:[UIColorFromRGB(kDefaultBuildings3DColor) toARGBNumber]] makeProfile];
        _buildings3dCustomDayColorPref = [[self registerIntPreference:kBuildings3dCustomDayColorPrefName defValue:[UIColorFromRGB(kDefaultBuildings3DColor) toARGBNumber]] makeProfile];
        _buildings3dDetailLevelPref = [settings getCustomRenderBooleanProperty:kBuildings3dDetailLevelPrefName defaultValue:NO];
        _buildings3dEnableColoringPref = [settings getCustomRenderBooleanProperty:kBuildings3dEnableColoringPrefName defaultValue:NO];
        _buildings3dColorPref = [settings getCustomRenderProperty:kBuildings3dColorPrefName defaultValue:@""];

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
    return [NSString stringWithFormat:OALocalizedString(@"srtm_plugin_description"), k_docs_plugin_srtm];
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

- (BOOL)is3dMapObjectsEnabled
{
    return [_enable3dMapObjectsPref get];
}

- (void)setTerrainLayerEnabled:(BOOL)enabled
{
    [_terrainEnabledPref set:enabled];
    [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (void)set3dMapObjectsEnabled:(BOOL)enabled
{
    [_enable3dMapObjectsPref set:enabled];
    [OARootViewController.instance.mapPanel.mapViewController recreate3dObjectsProvider];
}

- (void)reset3DBuildingAlphaToDefault
{
    [_buildings3dAlphaPref set:buildings3DAlphaDefValue];
}

- (void)apply3DBuildingsAlpha:(double)alpha
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
        if (!mapViewController.mapViewLoaded)
            return;
        
        [mapViewController runWithRenderSync:^{
            [mapViewController.mapView set3DBuildingsAlpha:(float) alpha];
        }];
        
        [OARootViewController.instance.mapPanel refreshMap:YES];
    });
}

- (void)apply3DBuildingsDetalization
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
        if (!mapViewController.mapViewLoaded)
            return;
        
        [mapViewController runWithRenderSync:^{
            [mapViewController.mapView set3DBuildingsDetalization:(int) [self->_buildings3dViewDistancePref get]];
        }];
        
        [OARootViewController.instance.mapPanel refreshMap:YES];
    });
}

- (void)apply3DBuildingsColorStyle:(NSInteger)style
{
    Buildings3DColorType colorStyle = style == Buildings3DColorTypeCustom ? Buildings3DColorTypeCustom : Buildings3DColorTypeMapStyle;
    [_buildings3dEnableColoringPref set:NO];
    [_buildings3dColorStylePref set:(int) colorStyle];
    if (colorStyle == Buildings3DColorTypeCustom)
    {
        int color = [OADayNightHelper instance].isNightMode ? [_buildings3dCustomNightColorPref get] : [_buildings3dCustomDayColorPref get];
        [self apply3DBuildingsColor:color];
    }
    
    [self updateMapPresentationEnvironment];
}

- (void)apply3DBuildingsColor:(int)color
{
    UIColor *buildingsColor = UIColorFromARGB(color);
    NSString *colorString = ([buildingsColor toARGBNumber] & 0xFF000000) == 0xFF000000 ? buildingsColor.toHexString.lowercaseString : buildingsColor.toHexARGBString.lowercaseString;
    [_buildings3dColorPref set:colorString];
    [self updateMapPresentationEnvironment];
}

- (NSInteger)get3DBuildingsColorStyle
{
    NSInteger styleId = [_buildings3dColorStylePref get];
    switch (styleId)
    {
        case Buildings3DColorTypeMapStyle:
            return Buildings3DColorTypeMapStyle;
        case Buildings3DColorTypeCustom:
            return Buildings3DColorTypeCustom;
        default:
            return Buildings3DColorTypeMapStyle;
    }
}

- (int)getBuildings3dColor
{
    if ([self get3DBuildingsColorStyle] == Buildings3DColorTypeCustom)
        return [OADayNightHelper instance].isNightMode ? [_buildings3dCustomNightColorPref get] : [_buildings3dCustomDayColorPref get];
    
    NSString *color = [_buildings3dColorPref get];
    if (color.length == 0)
        return 0;
    
    return [UIColor toNumberFromString:[color hasPrefix:@"#"] ? color : [@"#" stringByAppendingString:color]];
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
    return @[OAContourLinesAction.getQuickActionType, OATerrainAction.getQuickActionType];
}

- (void)updateMapPresentationEnvironment
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
        if (!mapViewController.mapViewLoaded)
            return;
        
        [mapViewController runWithRenderSync:^{
            [mapViewController.mapView set3DBuildingsAlpha:(float) [self->_buildings3dAlphaPref get]];
            [mapViewController.mapView set3DBuildingsDetalization:(int) [self->_buildings3dViewDistancePref get]];
        }];
        
        [mapViewController recreate3dObjectsProvider];
        [OARootViewController.instance.mapPanel refreshMap:YES];
    });
}

@end
