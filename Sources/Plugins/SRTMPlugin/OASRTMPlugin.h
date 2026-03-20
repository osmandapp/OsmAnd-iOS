//
//  OASRTMPlugin.h
//  OsmAnd
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

extern NSInteger const terrainMinSupportedZoom;
extern NSInteger const terrainMaxSupportedZoom;
extern NSInteger const hillshadeDefaultTrasparency;
extern NSInteger const defaultTrasparency;

@class OACommonBoolean, OACommonDouble, OACommonInteger, OACommonString, TerrainMode;

@interface OASRTMPlugin : OAPlugin

@property (nonatomic) OACommonBoolean *enable3dMapsPref;
@property (nonatomic) OACommonBoolean *enable3dMapObjectsPref;
@property(nonatomic, strong) OACommonDouble *buildings3dAlphaPref;
@property(nonatomic, strong) OACommonInteger *buildings3dViewDistancePref;
@property(nonatomic, strong) OACommonInteger *buildings3dColorStylePref;
@property(nonatomic, strong) OACommonInteger *buildings3dCustomNightColorPref;
@property(nonatomic, strong) OACommonInteger *buildings3dCustomDayColorPref;
@property(nonatomic, strong) OACommonBoolean *buildings3dDetailLevelPref;
@property(nonatomic, strong) OACommonBoolean *buildings3dEnableColoringPref;
@property(nonatomic, strong) OACommonString *buildings3dColorPref;
@property (nonatomic) OACommonBoolean *terrainEnabledPref;
@property (nonatomic) OACommonString *terrainModeTypePref;

- (TerrainMode *)getTerrainMode;
- (void)setTerrainMode:(TerrainMode *)mode;
- (BOOL)isTerrainLayerEnabled;
- (void)setTerrainLayerEnabled:(BOOL)enabled;
- (BOOL)is3dMapObjectsEnabled;
- (void)set3dMapObjectsEnabled:(BOOL)enabled;
- (void)reset3DBuildingAlphaToDefault;
- (void)apply3DBuildingsAlpha:(double)alpha;
- (void)apply3DBuildingsDetalization;
- (NSInteger)get3DBuildingsColorStyle;
- (void)apply3DBuildingsColorStyle:(NSInteger)style;
- (void)apply3DBuildingsColor:(int)color;
- (int)getBuildings3dColor;
- (NSInteger)getTerrainMinZoom;
- (NSInteger)getTerrainMaxZoom;

- (BOOL)isHeightmapEnabled;
- (BOOL)isHeightmapAllowed;
- (BOOL)is3DMapsEnabled;

@end
