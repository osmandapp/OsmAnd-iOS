//
//  OAExportSettingsType.h
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAExportSettingsType : NSObject <NSCopying>

+ (OAExportSettingsType *) PROFILE;
+ (OAExportSettingsType *) GLOBAL;
+ (OAExportSettingsType *) QUICK_ACTIONS;
+ (OAExportSettingsType *) POI_TYPES;
+ (OAExportSettingsType *) AVOID_ROADS;
+ (OAExportSettingsType *) FAVORITES;
+ (OAExportSettingsType *) TRACKS;
+ (OAExportSettingsType *) OSM_NOTES;
+ (OAExportSettingsType *) OSM_EDITS;
+ (OAExportSettingsType *) MULTIMEDIA_NOTES;
+ (OAExportSettingsType *) ACTIVE_MARKERS;
+ (OAExportSettingsType *) HISTORY_MARKERS;
+ (OAExportSettingsType *) SEARCH_HISTORY;
+ (OAExportSettingsType *) CUSTOM_RENDER_STYLE;
+ (OAExportSettingsType *) CUSTOM_ROUTING;
+ (OAExportSettingsType *) MAP_SOURCES;
+ (OAExportSettingsType *) OFFLINE_MAPS;
+ (OAExportSettingsType *) TTS_VOICE;
+ (OAExportSettingsType *) VOICE;
+ (OAExportSettingsType *) ONLINE_ROUTING_ENGINES;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) UIImage *icon;

- (BOOL) isSettingsCategory;
- (BOOL) isMyPlacesCategory;
- (BOOL) isResourcesCategory;

@end

NS_ASSUME_NONNULL_END
