//
//  OAExportSettingsType.h
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAExportSettingsCategory, OASettingsItem, OARemoteFile;

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

+ (OAExportSettingsType *) getExportSettingsTypeForItem:(OASettingsItem *)item;
+ (OAExportSettingsType *) getExportSettingsTypeForRemoteFile:(OARemoteFile *)remoteFile;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) UIImage *icon;

- (BOOL) isSettingsCategory;
- (BOOL) isMyPlacesCategory;
- (BOOL) isResourcesCategory;

- (OAExportSettingsCategory *) getCategory;

@end

NS_ASSUME_NONNULL_END
