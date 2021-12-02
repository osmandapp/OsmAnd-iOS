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

@class MutableOrderedDictionary;

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
@property (readonly) OAObservable* mapElevationAngleChangeObservable;

@property (readonly) OAMapLayersConfiguration* mapLayersConfiguration;

@property (nonatomic) EOATerrainType terrainType;
@property (nonatomic) EOATerrainType lastTerrainType;
@property (nonatomic) double hillshadeAlpha;
@property (nonatomic) NSInteger hillshadeMinZoom;
@property (nonatomic) NSInteger hillshadeMaxZoom;
@property (nonatomic) double slopeAlpha;
@property (nonatomic) NSInteger slopeMinZoom;
@property (nonatomic) NSInteger slopeMaxZoom;

@property (readonly) OAObservable* terrainChangeObservable;
@property (readonly) OAObservable* terrainResourcesChangeObservable;
@property (readonly) OAObservable* terrainAlphaChangeObservable;

@property (nonatomic) BOOL mapillary;
@property (readonly) OAObservable* mapillaryChangeObservable;

@property (nonatomic) BOOL wikipedia;
@property (readonly) OAObservable* wikipediaChangeObservable;

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


@end
