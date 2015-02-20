//
//  OADebugSettings.m
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppSettings.h"
#import "OsmAndApp.h"

/*
#import "OAResourcesBaseViewController.h"
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/ObfMapObjectsProvider.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapPresentationEnvironment.h>
 */

@implementation OAAppSettings

@synthesize settingShowMapRulet=_settingShowMapRulet, settingMapLanguage=_settingMapLanguage, settingAppMode=_settingAppMode;
@synthesize mapSettingShowFavorites=_mapSettingShowFavorites, mapSettingMoreDetails=_mapSettingMoreDetails, mapSettingRoadSurface=_mapSettingRoadSurface, mapSettingRoadQuality=_mapSettingRoadQuality, mapSettingAccessRestrictions=_mapSettingAccessRestrictions, mapSettingColoredBuildings=_mapSettingColoredBuildings, mapSettingContourLines=_mapSettingContourLines, mapSettingStreetLighting=_mapSettingStreetLighting;
@synthesize mapSettingNoAdminboundaries=_mapSettingNoAdminboundaries, mapSettingNoPolygons=_mapSettingNoPolygons, mapSettingHideBuildings=_mapSettingHideBuildings;
@synthesize mapSettingShowCycleRoutes=_mapSettingShowCycleRoutes, mapSettingOsmcTraces=_mapSettingOsmcTraces, mapSettingAlpineHiking=_mapSettingAlpineHiking, mapSettingRoadStyle=_mapSettingRoadStyle;

+ (OAAppSettings*)sharedManager
{
    static OAAppSettings *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[OAAppSettings alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // Common Settings
        _settingShowMapRulet = [[NSUserDefaults standardUserDefaults] objectForKey:settingShowMapRuletKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingShowMapRuletKey] : YES;
        _settingMapLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingMapLanguageKey] : 0;
        _settingAppMode = [[NSUserDefaults standardUserDefaults] objectForKey:settingAppModeKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingAppModeKey] : 0;

        _settingMetricSystem = [[NSUserDefaults standardUserDefaults] objectForKey:settingMetricSystemKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingMetricSystemKey] : 0;
        _settingShowZoomButton = [[NSUserDefaults standardUserDefaults] objectForKey:settingZoomButtonKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingZoomButtonKey] : YES;
        _settingGeoFormat = [[NSUserDefaults standardUserDefaults] objectForKey:settingGeoFormatKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:settingGeoFormatKey] : 0;
        
        // Map Settings
        _mapSettingShowFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingShowFavoritesKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingShowFavoritesKey] : NO;
        _mapSettingVisibleGpx = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingVisibleGpxKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingVisibleGpxKey] : @[];

        // --- Details
        _mapSettingMoreDetails = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingMoreDetailsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingMoreDetailsKey] : NO;
        _mapSettingRoadSurface = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingRoadSurfaceKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingRoadSurfaceKey] : NO;
        _mapSettingRoadQuality = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingRoadQualityKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingRoadQualityKey] : NO;
        _mapSettingAccessRestrictions = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingAccessRestrictionsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingAccessRestrictionsKey] : NO;
        _mapSettingContourLines = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingContourLinesKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:mapSettingContourLinesKey] : @"--";
        _mapSettingColoredBuildings = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingColoredBuildingsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingColoredBuildingsKey] : NO;
        _mapSettingStreetLighting = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingStreetLightingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingStreetLightingKey] : NO;
        
        // --- Hide
        _mapSettingNoAdminboundaries = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingNoAdminboundariesKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingNoAdminboundariesKey] : NO;
        _mapSettingNoPolygons = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingNoPolygonsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingNoPolygonsKey] : NO;
        _mapSettingHideBuildings = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingHideBuildingsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingHideBuildingsKey] : NO;

        // --- Routes
        _mapSettingShowCycleRoutes = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingShowCycleRoutesKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingShowCycleRoutesKey] : NO;
        _mapSettingOsmcTraces = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingOsmcTracesKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingOsmcTracesKey] : NO;
        _mapSettingAlpineHiking = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingAlpineHikingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingAlpineHikingKey] : NO;
        _mapSettingRoadStyle = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingRoadStyleKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:mapSettingRoadStyleKey] : @"";

    }
    return self;
}

// Common Settings
-(void)setSettingShowMapRulet:(BOOL)settingShowMapRulet {
    _settingShowMapRulet = settingShowMapRulet;
    [[NSUserDefaults standardUserDefaults] setBool:_settingShowMapRulet forKey:settingShowMapRuletKey];
}

-(void)setSettingMapLanguage:(int)settingMapLanguage {
    _settingMapLanguage = settingMapLanguage;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMapLanguage forKey:settingMapLanguageKey];
}

-(void)setSettingAppMode:(int)settingAppMode {
    _settingAppMode = settingAppMode;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingAppMode forKey:settingAppModeKey];
    [[[OsmAndApp instance] dayNightModeObservable] notifyEvent];
}

-(void)setSettingMetricSystem:(int)settingMetricSystem {
    _settingMetricSystem = settingMetricSystem;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMetricSystem forKey:settingMetricSystemKey];
}

-(void)setSettingShowZoomButton:(BOOL)settingShowZoomButton {
    _settingShowZoomButton = settingShowZoomButton;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingShowZoomButton forKey:settingZoomButtonKey];
}

-(void)setSettingGeoFormat:(int)settingGeoFormat {
    _settingGeoFormat = settingGeoFormat;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingGeoFormat forKey:settingGeoFormatKey];
}

// Map Settings
-(void)setMapSettingShowFavorites:(BOOL)mapSettingShowFavorites {
    _mapSettingShowFavorites = mapSettingShowFavorites;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingShowFavorites forKey:mapSettingShowFavoritesKey];

    OsmAndAppInstance app = [OsmAndApp instance];
    [app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                   Visibility:_mapSettingShowFavorites];
}


-(void)setMapSettingVisibleGpx:(NSArray *)mapSettingVisibleGpx
{
    _mapSettingVisibleGpx = mapSettingVisibleGpx;
    [[NSUserDefaults standardUserDefaults] setObject:_mapSettingVisibleGpx forKey:mapSettingVisibleGpxKey];
    //[[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

-(void)showGpx:(NSString *)fileName
{
    if (![_mapSettingVisibleGpx containsObject:fileName]) {
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
        [arr addObject:fileName];
        self.mapSettingVisibleGpx = arr;
    }
}

-(void)hideGpx:(NSString *)fileName
{
    if ([_mapSettingVisibleGpx containsObject:fileName]) {
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
        [arr removeObject:fileName];
        self.mapSettingVisibleGpx = arr;
    }
}


// --- Details
-(void)setMapSettingMoreDetails:(BOOL)mapSettingMoreDetails {
    _mapSettingMoreDetails = mapSettingMoreDetails;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingMoreDetails forKey:mapSettingMoreDetailsKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingRoadSurface:(BOOL)mapSettingRoadSurface {
    _mapSettingRoadSurface = mapSettingRoadSurface;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingRoadSurface forKey:mapSettingRoadSurfaceKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingRoadQuality:(BOOL)mapSettingRoadQuality {
    _mapSettingRoadQuality = mapSettingRoadQuality;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingRoadQuality forKey:mapSettingRoadQualityKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingAccessRestrictions:(BOOL)mapSettingAccessRestrictions {
    _mapSettingAccessRestrictions = mapSettingAccessRestrictions;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingAccessRestrictions forKey:mapSettingAccessRestrictionsKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingContourLines:(NSString *)mapSettingContourLines {
    _mapSettingContourLines = mapSettingContourLines;
    [[NSUserDefaults standardUserDefaults] setObject:_mapSettingContourLines forKey:mapSettingContourLinesKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingColoredBuildings:(BOOL)mapSettingColoredBuildings {
    _mapSettingColoredBuildings = mapSettingColoredBuildings;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingColoredBuildings forKey:mapSettingColoredBuildingsKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingStreetLighting:(BOOL)mapSettingStreetLighting {
    _mapSettingStreetLighting = mapSettingStreetLighting;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingStreetLighting forKey:mapSettingStreetLightingKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

// --- Hide
-(void)setMapSettingNoAdminboundaries:(BOOL)mapSettingNoAdminboundaries {
    _mapSettingNoAdminboundaries = mapSettingNoAdminboundaries;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingNoAdminboundaries forKey:mapSettingNoAdminboundariesKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingNoPolygons:(BOOL)mapSettingNoPolygons {
    _mapSettingNoPolygons = mapSettingNoPolygons;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingNoPolygons forKey:mapSettingNoPolygonsKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingHideBuildings:(BOOL)mapSettingHideBuildings {
    _mapSettingHideBuildings = mapSettingHideBuildings;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingHideBuildings forKey:mapSettingHideBuildingsKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

// Routes
-(void)setMapSettingShowCycleRoutes:(BOOL)mapSettingShowCycleRoutes {
    _mapSettingShowCycleRoutes = mapSettingShowCycleRoutes;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingShowCycleRoutes forKey:mapSettingShowCycleRoutesKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingOsmcTraces:(BOOL)mapSettingOsmcTraces {
    _mapSettingOsmcTraces = mapSettingOsmcTraces;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingOsmcTraces forKey:mapSettingOsmcTracesKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingAlpineHiking:(BOOL)mapSettingAlpineHiking {
    _mapSettingAlpineHiking = mapSettingAlpineHiking;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingAlpineHiking forKey:mapSettingAlpineHikingKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}
-(void)setMapSettingRoadStyle:(NSString *)mapSettingRoadStyle {
    _mapSettingRoadStyle = mapSettingRoadStyle;
    [[NSUserDefaults standardUserDefaults] setObject:_mapSettingRoadStyle forKey:mapSettingRoadStyleKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}


@end
