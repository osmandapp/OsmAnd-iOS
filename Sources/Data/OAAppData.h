//
//  OAAppData.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapViewState.h"
#import "OAMapSource.h"
#import "OAMapLayersConfiguration.h"
#import "OARTargetPoint.h"
#import "OAAppSettings.h"

#define kWeatherSettingsChanging @"weather_settings_changing"
#define kWeatherSettingsChanged @"weather_settings_changed"
#define kWeatherSettingsReseting @"weather_settings_reseting"
#define kWeatherSettingsReset @"weather_settings_reset"

static const double kHillshadeDefAlpha = 0.45;
static const double kSlopeDefAlpha = 0.35;
static const double kExaggerationDefScale = 1.0;
static const double kGpxExaggerationDefScale = 0.25;
static const NSInteger kElevationDefMeters = 1000;

static const NSInteger kHillshadeDefMinZoom = 3;
static const NSInteger kHillshadeDefMaxZoom = 16;
static const NSInteger kSlopeDefMinZoom = 3;
static const NSInteger kSlopeDefMaxZoom = 16;

@class MutableOrderedDictionary, NSUnitCloud;

@interface OAAppData : NSObject <NSCoding>

@property OAMapSource* lastMapSource;
@property OAMapSource* prevOfflineSource;

@property OAMapSource* overlayMapSource;
@property OAMapSource* lastOverlayMapSource;
@property OAMapSource* underlayMapSource;
@property OAMapSource* lastUnderlayMapSource;
@property (nonatomic) double overlayAlpha;
@property (nonatomic) double underlayAlpha;

@property (readonly) OAObservable* overlayMapSourceChangeObservable;
@property (readonly) OAObservable* underlayMapSourceChangeObservable;
@property (readonly) OAObservable* overlayAlphaChangeObservable;
@property (readonly) OAObservable* underlayAlphaChangeObservable;
@property (readonly) OAObservable* mapLayersConfigurationChangeObservable;

@property (nonatomic) BOOL weather;
@property (nonatomic) BOOL weatherUseOfflineData;
@property (nonatomic) BOOL weatherTemp;
@property (nonatomic) NSUnitTemperature *weatherTempUnit;
@property (nonatomic) BOOL weatherTempUnitAuto;
@property (nonatomic) double weatherTempAlpha;
@property (nonatomic) BOOL weatherPressure;
@property (nonatomic) NSUnitPressure *weatherPressureUnit;
@property (nonatomic) BOOL weatherPressureUnitAuto;
@property (nonatomic) double weatherPressureAlpha;
@property (nonatomic) BOOL weatherWind;
@property (nonatomic) NSUnitSpeed *weatherWindUnit;
@property (nonatomic) BOOL weatherWindUnitAuto;
@property (nonatomic) double weatherWindAlpha;
@property (nonatomic) BOOL weatherCloud;
@property (nonatomic) NSUnitCloud *weatherCloudUnit;
@property (nonatomic) BOOL weatherCloudUnitAuto;
@property (nonatomic) double weatherCloudAlpha;
@property (nonatomic) BOOL weatherPrecip;
@property (nonatomic) NSUnitLength *weatherPrecipUnit;
@property (nonatomic) BOOL weatherPrecipUnitAuto;
@property (nonatomic) double weatherPrecipAlpha;

@property (readonly) OAObservable *weatherSettingsChangeObservable;

@property (readonly) OAObservable* weatherChangeObservable;
@property (readonly) OAObservable* weatherUseOfflineDataChangeObservable;
@property (readonly) OAObservable* weatherTempChangeObservable;
@property (readonly) OAObservable* weatherTempToolbarChangeObservable;
@property (readonly) OAObservable* weatherTempUnitChangeObservable;
@property (readonly) OAObservable* weatherTempUnitToolbarChangeObservable;
@property (readonly) OAObservable* weatherTempAlphaChangeObservable;
@property (readonly) OAObservable* weatherTempAlphaToolbarChangeObservable;
@property (readonly) OAObservable* weatherPressureChangeObservable;
@property (readonly) OAObservable* weatherPressureToolbarChangeObservable;
@property (readonly) OAObservable* weatherPressureUnitChangeObservable;
@property (readonly) OAObservable* weatherPressureUnitToolbarChangeObservable;
@property (readonly) OAObservable* weatherPressureAlphaChangeObservable;
@property (readonly) OAObservable* weatherPressureAlphaToolbarChangeObservable;
@property (readonly) OAObservable* weatherWindChangeObservable;
@property (readonly) OAObservable* weatherWindToolbarChangeObservable;
@property (readonly) OAObservable* weatherWindUnitChangeObservable;
@property (readonly) OAObservable* weatherWindUnitToolbarChangeObservable;
@property (readonly) OAObservable* weatherWindAlphaChangeObservable;
@property (readonly) OAObservable* weatherWindAlphaToolbarChangeObservable;
@property (readonly) OAObservable* weatherCloudChangeObservable;
@property (readonly) OAObservable* weatherCloudToolbarChangeObservable;
@property (readonly) OAObservable* weatherCloudUnitChangeObservable;
@property (readonly) OAObservable* weatherCloudUnitToolbarChangeObservable;
@property (readonly) OAObservable* weatherCloudAlphaChangeObservable;
@property (readonly) OAObservable* weatherCloudAlphaToolbarChangeObservable;
@property (readonly) OAObservable* weatherPrecipChangeObservable;
@property (readonly) OAObservable* weatherPrecipToolbarChangeObservable;
@property (readonly) OAObservable* weatherPrecipUnitChangeObservable;
@property (readonly) OAObservable* weatherPrecipUnitToolbarChangeObservable;
@property (readonly) OAObservable* weatherPrecipAlphaChangeObservable;
@property (readonly) OAObservable* weatherPrecipAlphaToolbarChangeObservable;

@property (nonatomic) NSString *contourName;
@property (nonatomic) NSString *contourNameLastUsed;
@property (nonatomic) double contoursAlpha;
@property (readonly) OAObservable* contourNameChangeObservable;
@property (readonly) OAObservable* contoursAlphaChangeObservable;

@property (readonly) OAMapLayersConfiguration* mapLayersConfiguration;

@property (nonatomic) EOATerrainType terrainType;
@property (nonatomic) EOATerrainType lastTerrainType;
@property (nonatomic) double hillshadeAlpha;
@property (nonatomic) NSInteger hillshadeMinZoom;
@property (nonatomic) NSInteger hillshadeMaxZoom;
@property (nonatomic) double slopeAlpha;
@property (nonatomic) NSInteger slopeMinZoom;
@property (nonatomic) NSInteger slopeMaxZoom;
@property (nonatomic) double verticalExaggerationScale;

@property (readonly) OAObservable* terrainChangeObservable;
@property (readonly) OAObservable* terrainResourcesChangeObservable;
@property (readonly) OAObservable* terrainAlphaChangeObservable;
@property (readonly) OAObservable* verticalExaggerationScaleChangeObservable;

@property (nonatomic) BOOL mapillary;
@property (readonly) OAObservable* mapillaryChangeObservable;

@property (nonatomic) BOOL wikipedia;
@property (readonly) OAObservable* wikipediaChangeObservable;
@property (nonatomic) OADownloadMode *wikipediaImagesDownloadMode;
@property (nonatomic) OADownloadMode *travelGuidesImagesDownloadMode;

@property (readonly) OAObservable* mapLayerChangeObservable;

@property (readonly) OAObservable* lastMapSourceChangeObservable;
- (OAMapSource *) lastMapSourceByResourceId:(NSString *)resourceId;

@property (readonly) OAMapViewState* mapLastViewedState;

@property (nonatomic) NSMutableArray *destinations;
@property (readonly) OAObservable* destinationsChangeObservable;
@property (readonly) OAObservable* destinationAddObservable;
@property (readonly) OAObservable* destinationRemoveObservable;
@property (readonly) OAObservable* destinationShowObservable;
@property (readonly) OAObservable* destinationHideObservable;

@property (nonatomic) OARTargetPoint *pointToStart;
@property (nonatomic) OARTargetPoint *pointToNavigate;
@property (nonatomic) OARTargetPoint *myLocationToStart;
@property (nonatomic) NSArray<OARTargetPoint *> *intermediatePoints;

@property (nonatomic) OARTargetPoint *pointToStartBackup;
@property (nonatomic) OARTargetPoint *pointToNavigateBackup;
@property (nonatomic) NSMutableArray<OARTargetPoint *> *intermediatePointsBackup;

@property (readonly) OAObservable* applicationModeChangedObservable;

- (void) clearPointToStart;
- (void) clearPointToNavigate;

- (void) addIntermediatePoint:(OARTargetPoint *)point;
- (void) insertIntermediatePoint:(OARTargetPoint *)point index:(int)index;
- (void) deleteIntermediatePoint:(int)index;
- (void) clearIntermediatePoints;
- (void) clearMyLocationToStart;

- (void) clearPointToStartBackup;
- (void) clearPointToNavigateBackup;
- (void) clearIntermediatePointsBackup;

- (void) backupTargetPoints;
- (void) restoreTargetPoints;
- (BOOL) restorePointToStart;

+ (OAAppData*) defaults;
+ (OAMapSource *) defaultMapSource;

- (void) setLastMapSourceVariant:(NSString *)variant;

- (OAMapSource *) getLastMapSource:(OAApplicationMode *)mode;
- (void) setLastMapSource:(OAMapSource *)lastMapSource mode:(OAApplicationMode *)mode;

- (EOATerrainType) getTerrainType:(OAApplicationMode *)mode;
- (void) setTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode;

- (void) resetHillshadeAlpha;
- (void) resetSlopeAlpha;
- (void) resetHillshadeMinZoom;
- (void) resetHillshadeMaxZoom;
- (void) resetSlopeMinZoom;
- (void) resetSlopeMaxZoom;
- (void)resetVerticalExaggerationScale;

- (EOATerrainType) getLastTerrainType:(OAApplicationMode *)mode;
- (void) setLastTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode;

- (void) setSettingValue:(NSString *)value forKey:(NSString *)key mode:(OAApplicationMode *)mode;
- (void) addPreferenceValuesToDictionary:(MutableOrderedDictionary *)prefs mode:(OAApplicationMode *)mode;

- (void) resetProfileSettingsForMode:(OAApplicationMode *)mode;
- (void) copyAppDataFrom:(OAApplicationMode *)sourceMode toMode:(OAApplicationMode *)targetMode;

- (BOOL)getWikipediaAllLanguages;
- (BOOL)getWikipediaAllLanguages:(OAApplicationMode *)mode;
- (void)setWikipediaAllLanguages:(BOOL)allLanguages;
- (void)setWikipediaAllLanguages:(BOOL)allLanguages mode:(OAApplicationMode *)mode;

- (NSArray<NSString *> *)getWikipediaLanguages;
- (NSArray<NSString *> *)getWikipediaLanguages:(OAApplicationMode *)mode;
- (void)setWikipediaLanguages:(NSArray<NSString *> *)languages;
- (void)setWikipediaLanguages:(NSArray<NSString *> *)languages mode:(OAApplicationMode *)mode;

- (OADownloadMode *)getWikipediaImagesDownloadMode:(OAApplicationMode *)mode;
- (void)setWikipediaImagesDownloadMode:(OADownloadMode *)downloadMode mode:(OAApplicationMode *)mode;

- (void)resetWikipediaSettings:(OAApplicationMode *)mode;
- (void)resetWeatherSettings;

- (OADownloadMode *)getTravelGuidesImagesDownloadMode:(OAApplicationMode *)mode;
- (void)setTravelGuidesImagesDownloadMode:(OADownloadMode *)downloadMode mode:(OAApplicationMode *)mode;

@end
