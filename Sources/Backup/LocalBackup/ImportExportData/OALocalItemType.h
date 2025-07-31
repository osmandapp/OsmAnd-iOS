//
//  OALocalItemType.h
//  OsmAnd
//
//  Created by Max Kojin on 31/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAExportSettingsCategory;


@interface OALocalItemType : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *iconName;

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName;

+ (OALocalItemType *) MAP_DATA;
+ (OALocalItemType *) LIVE_UPDATES;
+ (OALocalItemType *) TTS_VOICE_DATA;
+ (OALocalItemType *) VOICE_DATA;
+ (OALocalItemType *) TERRAIN_DATA;
+ (OALocalItemType *) DEPTH_DATA;
+ (OALocalItemType *) WIKI_AND_TRAVEL_MAPS;
+ (OALocalItemType *) TILES_DATA;
+ (OALocalItemType *) WEATHER_DATA;
+ (OALocalItemType *) RENDERING_STYLES;
+ (OALocalItemType *) ROUTING;
+ (OALocalItemType *) FAVORITES;
+ (OALocalItemType *) TRACKS;
+ (OALocalItemType *) OSM_NOTES;
+ (OALocalItemType *) OSM_EDITS;
+ (OALocalItemType *) ACTIVE_MARKERS;
+ (OALocalItemType *) HISTORY_MARKERS;
+ (OALocalItemType *) COLOR_DATA;
+ (OALocalItemType *) PROFILES;
+ (OALocalItemType *) OTHER;

+ (NSArray<OALocalItemType *> *) getAllValues;

- (OAExportSettingsCategory *) getCategory;
- (BOOL) isSettingsCategory;
- (BOOL) isMyPlacesCategory;
- (BOOL) isResourcesCategory;
- (BOOL) isDownloadType;
- (BOOL) isUpdateSupported;
- (BOOL) isDeletionSupported;
- (BOOL) isBackupSupported;
- (BOOL) isRenamingSupported;
- (BOOL) isSortingSupported;
- (BOOL) isDerivedFromAssets;

@end


NS_ASSUME_NONNULL_END
