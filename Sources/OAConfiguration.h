//
//  OAConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "CommonTypes.h"
#import "OAObservable.h"
#import "OAMapSourcePresets.h"
#import "OAMapSourcePreset.h"

// Values of map_source are:
// - "offline:<style-name>"
// - "online:<provider-id>"
#define kActiveMapSource @"active_map_source"
#define kMapSource_OfflinePrefix @"offline:"
#define kMapSource_OnlinePrefix @"online:"
#define kDefaultMapSource @"offline:default"

#define kMapSourcesPresets @"map_sources_presets"

#define kSelectedMapSourcePresets @"selected_map_source_presets"

#define kLastViewedTarget31 @"last_viewed_target31"
#define kLastViewedZoom @"last_viewed_zoom"
#define kLastViewedAzimuth @"last_viewed_azimuth"
#define kLastViewedElevationAngle @"last_viewed_elevation_angle"

@interface OAConfiguration : NSObject

- (BOOL)save;

@property(readonly) OAObservable* observable;

@property(getter = getActiveMapSource, setter = setActiveMapSource:) NSString* activeMapSource;

- (OAMapSourcePresets*)mapSourcePresetsFor:(NSString*)mapSource;
- (NSUUID*)addMapSourcePreset:(OAMapSourcePreset*)preset forMapSource:(NSString*)mapSource;
- (BOOL)removeMapSourcePresetWithId:(NSUUID*)presetId forMapSource:(NSString*)mapSource;

- (NSUUID*)selectedMapSourcePresetFor:(NSString*)mapSource;
- (void)selectMapSourcePreset:(NSUUID*)preset for:(NSString*)mapSource;

@property(getter = getLastViewedTarget31, setter = setLastViewedTarget31:) Point31 lastViewedTarget31;
@property(getter = getLastViewedZoom, setter = setLastViewedZoom:) float lastViewedZoom;
@property(getter = getLastViewedAzimuth, setter = setLastViewedAzimuth:) float lastViewedAzimuth;
@property(getter = getLastViewedElevationAngle, setter = setLastViewedElevationAngle:) float lastViewedElevationAngle;

@end
