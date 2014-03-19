//
//  OAConfiguration.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"

// Values of map_source are:
// - "offline:<style-name>"
// - "online:<provider-id>"
#define kMapSource @"map_source"
#define kMapSource_OfflinePrefix @"offline:"
#define kMapSource_OnlinePrefix @"online:"
#define kDefaultMapSource @"offline:default"

#define kMapSourcesPresets @"map_sources_presets"

@interface OAConfiguration : NSObject

- (BOOL)save;
@property(readonly) OAObservable* observable;

@property(getter = getMapSource, setter = setMapSource:) NSString* mapSource;
@property(getter = getMapSourcesPresets, setter = setMapSourcesPresets:) NSDictionary* mapSourcesPresets;

@end
