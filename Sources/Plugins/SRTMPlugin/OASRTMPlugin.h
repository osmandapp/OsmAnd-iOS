//
//  OASRTMPlugin.h
//  OsmAnd
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@class OACommonBoolean, TerrainMode;

@interface OASRTMPlugin : OAPlugin

@property (nonatomic) OACommonBoolean *enable3DMaps;
@property (nonatomic) OACommonBoolean *terrain;
@property (nonatomic) OACommonString *terrainSettingMode;

- (TerrainMode *)getTerrainSettingMode;
- (void)setTerrainMode:(TerrainMode *)mode;
- (BOOL)isTerrainLayerEnabled;
- (void)setTerrainLayerEnabled:(BOOL)enabled;

- (BOOL)isHeightmapEnabled;
- (BOOL)isHeightmapAllowed;
- (BOOL) is3DMapsEnabled;

@end
