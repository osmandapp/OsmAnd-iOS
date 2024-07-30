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

@class OACommonBoolean, TerrainMode;

@interface OASRTMPlugin : OAPlugin

@property (nonatomic) OACommonBoolean *enable3dMapsPref;
@property (nonatomic) OACommonBoolean *terrainEnabledPref;
@property (nonatomic) OACommonString *terrainModeTypePref;

- (TerrainMode *)getTerrainMode;
- (void)setTerrainMode:(TerrainMode *)mode;
- (BOOL)isTerrainLayerEnabled;
- (void)setTerrainLayerEnabled:(BOOL)enabled;
- (NSInteger)getTerrainMinZoom;
- (NSInteger)getTerrainMaxZoom;

- (BOOL)isHeightmapEnabled;
- (BOOL)isHeightmapAllowed;
- (BOOL)is3DMapsEnabled;

@end
