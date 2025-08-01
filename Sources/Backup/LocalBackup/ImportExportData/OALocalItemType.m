//
//  OALocalItemType.m
//  OsmAnd
//
//  Created by Max Kojin on 31/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OALocalItemType.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAExportSettingsCategory.h"

static OALocalItemType * MAP_DATA;
static OALocalItemType * ROAD_DATA;
static OALocalItemType * LIVE_UPDATES;
static OALocalItemType * TTS_VOICE_DATA;
static OALocalItemType * VOICE_DATA;
static OALocalItemType * FONT_DATA;
static OALocalItemType * TERRAIN_DATA;
static OALocalItemType * DEPTH_DATA;
static OALocalItemType * WIKI_AND_TRAVEL_MAPS;
static OALocalItemType * TILES_DATA;
static OALocalItemType * WEATHER_DATA;
static OALocalItemType * RENDERING_STYLES;
static OALocalItemType * ROUTING;
static OALocalItemType * CACHE;
static OALocalItemType * FAVORITES;
static OALocalItemType * TRACKS;
static OALocalItemType * OSM_NOTES;
static OALocalItemType * OSM_EDITS;
static OALocalItemType * MULTIMEDIA_NOTES;
static OALocalItemType * ACTIVE_MARKERS;
static OALocalItemType * HISTORY_MARKERS;
static OALocalItemType * ITINERARY_GROUPS;
static OALocalItemType * COLOR_DATA;
static OALocalItemType * PROFILES;
static OALocalItemType * OTHER;

static NSArray<OALocalItemType *> *allValues;


@implementation OALocalItemType

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName
{
    self = [super init];
    if (self) {
        _title = title;
        _iconName = iconName;
    }
    return self;
}

#pragma mark - Getters

+ (OALocalItemType *) MAP_DATA
{
    if (!MAP_DATA)
        MAP_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"standard_maps") iconName:@"ic_custom_map"];
    return MAP_DATA;
}

+ (OALocalItemType *) ROAD_DATA
{
    return nil;  // Not implemented
}

+ (OALocalItemType *) LIVE_UPDATES
{
    if (!LIVE_UPDATES)
        LIVE_UPDATES = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"download_live_updates") iconName:@"ic_custom_map"];
    return LIVE_UPDATES;
}

+ (OALocalItemType *) TTS_VOICE_DATA
{
    if (!TTS_VOICE_DATA)
        TTS_VOICE_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"local_indexes_cat_tts") iconName:@"ic_custom_sound"];
    return TTS_VOICE_DATA;
}

+ (OALocalItemType *) VOICE_DATA
{
    if (!VOICE_DATA)
        VOICE_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"local_indexes_cat_voice") iconName:@"ic_custom_sound"];
    return VOICE_DATA;
}

+ (OALocalItemType *) FONT_DATA
{
    return nil;  // Not implemented
}

+ (OALocalItemType *) TERRAIN_DATA
{
    if (!TERRAIN_DATA)
        TERRAIN_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"topography_maps") iconName:@"ic_custom_terrain"];
    return TERRAIN_DATA;
}

+ (OALocalItemType *) DEPTH_DATA
{
    if (!DEPTH_DATA)
        DEPTH_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"nautical_maps") iconName:@"ic_live_nautical_depth"];
    return DEPTH_DATA;
}

+ (OALocalItemType *) WIKI_AND_TRAVEL_MAPS
{
    if (!DEPTH_DATA)
        DEPTH_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"wikipedia_and_travel_maps") iconName:@"ic_custom_wikipedia"];
    return DEPTH_DATA;
}

+ (OALocalItemType *) TILES_DATA
{
    if (!TILES_DATA)
        TILES_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"quick_action_map_source_title") iconName:@"ic_custom_overlay_map"];
    return TILES_DATA;
}

+ (OALocalItemType *) WEATHER_DATA
{
    if (!WEATHER_DATA)
        WEATHER_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_weather") iconName:@"ic_custom_umbrella"];
    return WEATHER_DATA;
}

+ (OALocalItemType *) RENDERING_STYLES
{
    if (!RENDERING_STYLES)
        RENDERING_STYLES = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"rendering_styles") iconName:@"ic_custom_map_outline"];
    return RENDERING_STYLES;
}

+ (OALocalItemType *) ROUTING
{
    if (!ROUTING)
        ROUTING = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_routing") iconName:@"ic_custom_file_routing"];
    return ROUTING;
}

+ (OALocalItemType *) CACHE
{
    return nil;  // Not implemented
}

+ (OALocalItemType *) FAVORITES
{
    if (!FAVORITES)
        FAVORITES = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"favorites_item") iconName:@"ic_custom_my_places"];
    return FAVORITES;
}

+ (OALocalItemType *) TRACKS
{
    if (!TRACKS)
        TRACKS = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_gpx_tracks") iconName:@"ic_custom_trip"];
    return TRACKS;
}

+ (OALocalItemType *) OSM_NOTES
{
    if (!OSM_NOTES)
        OSM_NOTES = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"osm_notes") iconName:@"ic_action_osm_note"];
    return OSM_NOTES;
}

+ (OALocalItemType *) OSM_EDITS
{
    if (!OSM_EDITS)
        OSM_EDITS = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"osm_edits_title") iconName:@"ic_custom_osm_edits"];
    return OSM_EDITS;
}

+ (OALocalItemType *) ACTIVE_MARKERS
{
    if (!ACTIVE_MARKERS)
        ACTIVE_MARKERS = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"map_markers") iconName:@"ic_custom_marker"];
    return ACTIVE_MARKERS;
}

+ (OALocalItemType *) HISTORY_MARKERS
{
    if (!HISTORY_MARKERS)
        HISTORY_MARKERS = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"markers_history") iconName:@"ic_custom_marker"];
    return HISTORY_MARKERS;
}

+ (OALocalItemType *) ITINERARY_GROUPS
{
    return nil;  // Not implemented
}

+ (OALocalItemType *) COLOR_DATA
{
    if (!COLOR_DATA)
        COLOR_DATA = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_colors") iconName:@"ic_custom_appearance"];
    return COLOR_DATA;
}

+ (OALocalItemType *) PROFILES
{
    if (!PROFILES)
        PROFILES = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_profiles") iconName:@"ic_custom_manage_profiles"];
    return PROFILES;
}

+ (OALocalItemType *) OTHER
{
    if (!OTHER)
        OTHER = [[OALocalItemType alloc] initWithTitle:OALocalizedString(@"shared_string_other") iconName:@"ic_custom_settings_outlined"];
    return OTHER;
}

+ (NSArray<OALocalItemType *> *) getAllValues
{
    if (!allValues)
    {
        NSMutableArray<OALocalItemType *> *res = [NSMutableArray array];
        [res addObject:MAP_DATA];
        // [res addObject:self.ROAD_DATA];
        [res addObject:self.LIVE_UPDATES];
        [res addObject:self.TTS_VOICE_DATA];
        [res addObject:self.VOICE_DATA];
        // [res addObject:self.FONT_DATA];
        [res addObject:self.TERRAIN_DATA];
        [res addObject:self.DEPTH_DATA];
        [res addObject:self.WIKI_AND_TRAVEL_MAPS];
        [res addObject:self.TILES_DATA];
        [res addObject:self.WEATHER_DATA];
        [res addObject:self.RENDERING_STYLES];
        [res addObject:self.ROUTING];
        // [res addObject:self.CACHE];
        [res addObject:self.FAVORITES];
        [res addObject:self.TRACKS];
        [res addObject:self.OSM_NOTES];
        [res addObject:self.OSM_EDITS];
        // [res addObject:self.MULTIMEDIA_NOTES];
        [res addObject:self.ACTIVE_MARKERS];
        [res addObject:self.HISTORY_MARKERS];
        // [res addObject:self.ITINERARY_GROUPS];
        [res addObject:self.COLOR_DATA];
        [res addObject:self.PROFILES];
        [res addObject:self.OTHER];
        allValues = res;
    }
    
    return allValues;
}

#pragma mark - Methods

- (OAExportSettingsCategory *) getCategory
{
    if ([self isSettingsCategory])
        return OAExportSettingsCategory.SETTINGS;
    else if ([self isMyPlacesCategory])
        return OAExportSettingsCategory.MY_PLACES;
    else if ([self isResourcesCategory])
        return OAExportSettingsCategory.RESOURCES;
    else
        return nil;
}

- (BOOL) isSettingsCategory
{
    return [@[COLOR_DATA, PROFILES, OTHER] containsObject:self];
}

- (BOOL) isMyPlacesCategory
{
    return [@[FAVORITES, TRACKS, OSM_EDITS, OSM_NOTES, MULTIMEDIA_NOTES, ACTIVE_MARKERS, HISTORY_MARKERS, ITINERARY_GROUPS] containsObject:self];
}

- (BOOL) isResourcesCategory
{
    return [@[MAP_DATA, LIVE_UPDATES, TERRAIN_DATA, WIKI_AND_TRAVEL_MAPS, DEPTH_DATA, WEATHER_DATA, TILES_DATA, RENDERING_STYLES, ROUTING, TTS_VOICE_DATA, VOICE_DATA, FONT_DATA, CACHE] containsObject:self];
}

- (BOOL) isDownloadType
{
    return [@[MAP_DATA, TILES_DATA, TERRAIN_DATA, DEPTH_DATA, WIKI_AND_TRAVEL_MAPS, WEATHER_DATA, TTS_VOICE_DATA, VOICE_DATA, FONT_DATA] containsObject:self];
}

- (BOOL) isUpdateSupported
{
    return self != TILES_DATA && [self isDownloadType];
}

- (BOOL) isDeletionSupported
{
    return [self isDownloadType]
        || self == LIVE_UPDATES
        || self == CACHE
        
    //TODO: implement
//    || ExportType.findBy(this) != null && this != PROFILES;
    ;
}

- (BOOL) isBackupSupported
{
    return [@[MAP_DATA, WIKI_AND_TRAVEL_MAPS, TERRAIN_DATA, DEPTH_DATA] containsObject:self];
}

- (BOOL) isRenamingSupported
{
    return self != TILES_DATA && [self isDownloadType];
}

- (BOOL) isSortingSupported
{
    return [self isMyPlacesCategory] && [self isResourcesCategory];
}

- (BOOL) isDerivedFromAssets
{
    return [@[TTS_VOICE_DATA, COLOR_DATA, FONT_DATA] containsObject:self];
}


#pragma mark - NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    // It is safe to return self here, since the Type is immutable
    return self;
}

@end
