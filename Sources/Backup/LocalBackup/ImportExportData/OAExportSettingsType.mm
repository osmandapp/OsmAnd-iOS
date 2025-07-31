//
//  OAExportSettingsType.m
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportSettingsType.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASettingsItem.h"
#import "OARemoteFile.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAExportSettingsCategory.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAFavoritesHelper.h"
#import "OAPluginsHelper.h"
#import "OALocalItemType.h"

static OAExportSettingsType * PROFILE;
static OAExportSettingsType * GLOBAL;
static OAExportSettingsType * QUICK_ACTIONS;
static OAExportSettingsType * POI_TYPES;
static OAExportSettingsType * AVOID_ROADS;
static OAExportSettingsType * FAVORITES;
static OAExportSettingsType * TRACKS;
static OAExportSettingsType * OSM_NOTES;
static OAExportSettingsType * OSM_EDITS;
// static OAExportSettingsType * MULTIMEDIA_NOTES;
static OAExportSettingsType * ACTIVE_MARKERS;
static OAExportSettingsType * HISTORY_MARKERS;
static OAExportSettingsType * SEARCH_HISTORY;
static OAExportSettingsType * NAVIGATION_HISTORY;
// static OAExportSettingsType * ITINERARY_GROUPS;
static OAExportSettingsType * CUSTOM_RENDER_STYLE;
static OAExportSettingsType * CUSTOM_ROUTING;
static OAExportSettingsType * ONLINE_ROUTING_ENGINES;
static OAExportSettingsType * MAP_SOURCES;
static OAExportSettingsType * STANDARD_MAPS;
static OAExportSettingsType * WIKI_AND_TRAVEL;
static OAExportSettingsType * DEPTH_DATA;
// static OAExportSettingsType * ROAD_MAPS;
static OAExportSettingsType * TERRAIN_DATA;
static OAExportSettingsType * TTS_VOICE;
static OAExportSettingsType * VOICE;
// static OAExportSettingsType * FAVORITES_BACKUP;
static OAExportSettingsType * COLOR_PALETTE;

static NSArray<OAExportSettingsType *> *allValues;


@interface OAExportSettingsType ()

@end

@implementation OAExportSettingsType

+ (OAExportSettingsType *)findBySettingsItem:(OASettingsItem *)item
{
    if (item.type == EOASettingsItemTypeFile)
        return [self findByFileSubtype:((OAFileSettingsItem *) item).subtype];

    for (OAExportSettingsType *exportType in self.getAllValues)
    {
        if ([exportType.itemName isEqualToString:[OASettingsItemType typeName:item.type]])
            return exportType;
    }
    return nil;
}

+ (OAExportSettingsType *)findByRemoteFile:(OARemoteFile *)remoteFile
{
    if (remoteFile.item != nil)
        return [self findBySettingsItem:remoteFile.item];

    if ([[OASettingsItemType typeName:EOASettingsItemTypeFile] isEqualToString:remoteFile.type])
        return [self findByFileSubtype:((OAFileSettingsItem *) remoteFile.item).subtype];

    for (OAExportSettingsType *exportType in self.getAllValues)
    {
        if ([exportType.itemName isEqualToString:remoteFile.type])
            return exportType;
    }
    return nil;
}

+ (OAExportSettingsType *)findByFileSubtype:(EOASettingsItemFileSubtype)subtype
{
    if (subtype == EOASettingsItemFileSubtypeRenderingStyle)
        return CUSTOM_RENDER_STYLE;
    else if (subtype == EOASettingsItemFileSubtypeRoutingConfig)
        return CUSTOM_ROUTING;
//    else if (subtype == EOASettingsItemFileSubtypeMultimediaFile)
//        return MULTIMEDIA_NOTES;
    else if (subtype == EOASettingsItemFileSubtypeGpx)
        return TRACKS;
    else if (subtype == EOASettingsItemFileSubtypeColorPalette)
        return COLOR_PALETTE;
    else if ([OAFileSettingsItemFileSubtype isMap:subtype])
        return STANDARD_MAPS;
//    else if (subtype == FileSubtype.TTS_VOICE)
//        return ExportSettingsType.TTS_VOICE;
//    else if (subtype == FileSubtype.VOICE)
//        return ExportSettingsType.VOICE;
    return nil;
}

+ (NSArray<OAExportSettingsType *> *) getAllValues
{
    if (!allValues)
    {
        NSMutableArray<OAExportSettingsType *> *res = [NSMutableArray array];
        [res addObject:self.PROFILE];
        [res addObject:self.GLOBAL];
        [res addObject:self.QUICK_ACTIONS];
        [res addObject:self.POI_TYPES];
        [res addObject:self.AVOID_ROADS];
        [res addObject:self.FAVORITES];
        [res addObject:self.TRACKS];
        [res addObject:self.OSM_NOTES];
        [res addObject:self.OSM_EDITS];
//        [res addObject:self.MULTIMEDIA_NOTES];
        [res addObject:self.ACTIVE_MARKERS];
        [res addObject:self.HISTORY_MARKERS];
        [res addObject:self.SEARCH_HISTORY];
        [res addObject:self.NAVIGATION_HISTORY];
        [res addObject:self.CUSTOM_RENDER_STYLE];
        [res addObject:self.CUSTOM_ROUTING];
        [res addObject:self.MAP_SOURCES];
        [res addObject:self.STANDARD_MAPS];
        [res addObject:self.WIKI_AND_TRAVEL];
        [res addObject:self.DEPTH_DATA];
        [res addObject:self.TERRAIN_DATA];
//        [res addObject:self.TTS_VOICE];
//        [res addObject:self.VOICE];
//        [res addObject:self.ONLINE_ROUTING_ENGINES];
        [res addObject:self.COLOR_PALETTE];
        allValues = res;
    }
    
    return allValues;
}

+ (NSArray<OAExportSettingsType *> *)getEnabledTypes
{
    NSMutableArray<OAExportSettingsType *> *result = [NSMutableArray arrayWithArray:self.getAllValues];
    OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class];
    if (![osmEditingPlugin isEnabled])
    {
        [result removeObject:OAExportSettingsType.OSM_EDITS];
        [result removeObject:OAExportSettingsType.OSM_NOTES];
    }
//    AudioVideoNotesPlugin avNotesPlugin = OsmandPlugin.getActivePlugin(AudioVideoNotesPlugin.class);
//    if (avNotesPlugin == null) {
//        result.remove(ExportSettingsType.MULTIMEDIA_NOTES);
//    }
    return result;
}

+ (BOOL) isTypeEnabled:(OAExportSettingsType *)type
{
    return [[self getEnabledTypes] containsObject:type];
}

- (instancetype)initWithTitle:(NSString *)title
                         name:(NSString *)name
                     itemName:(NSString *)itemName
                         iconName:(NSString *)iconName
     isAvailableInFreeVersion:(BOOL)isAvailableInFreeVersion
{
    self = [super init];
    if (self)
    {
        _title = title;
        _name = name;
        _itemName = itemName;
        _iconName = iconName;
        _icon = [UIImage templateImageNamed:iconName];
        _isAvailableInFreeVersion = isAvailableInFreeVersion;
    }
    return self;
}

+ (OAExportSettingsType *)PROFILE
{
    if (!PROFILE)
        PROFILE = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_profiles") name:@"PROFILE" itemName:@"PROFILE" iconName:@"ic_custom_manage_profiles" isAvailableInFreeVersion:YES];
    return PROFILE;
}

+ (OAExportSettingsType *)GLOBAL
{
    if (!GLOBAL)
        GLOBAL = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"general_settings_2") name:@"GLOBAL" itemName:@"GLOBAL" iconName:@"left_menu_icon_settings" isAvailableInFreeVersion:YES];
    return GLOBAL;
}

+ (OAExportSettingsType *)QUICK_ACTIONS
{
    if (!QUICK_ACTIONS)
        QUICK_ACTIONS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_quick_actions") name:@"QUICK_ACTIONS" itemName:@"QUICK_ACTIONS" iconName:@"ic_custom_quick_action" isAvailableInFreeVersion:NO];
    return QUICK_ACTIONS;
}

+ (OAExportSettingsType *)POI_TYPES
{
    if (!POI_TYPES)
        POI_TYPES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_poi_types") name:@"POI_TYPES" itemName:@"POI_UI_FILTERS" iconName:@"ic_custom_search_categories" isAvailableInFreeVersion:NO];
    return POI_TYPES;
}

+ (OAExportSettingsType *)AVOID_ROADS
{
    if (!AVOID_ROADS)
        AVOID_ROADS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"avoid_road") name:@"AVOID_ROADS" itemName:@"AVOID_ROADS" iconName:@"ic_custom_alert" isAvailableInFreeVersion:NO];
    return AVOID_ROADS;
}

+ (OAExportSettingsType *)FAVORITES
{
    if (!FAVORITES)
        FAVORITES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"favorites_item") name:@"FAVORITES" itemName:@"FAVOURITES" iconName:@"ic_custom_my_places" isAvailableInFreeVersion:YES];
    return FAVORITES;
}

+ (OAExportSettingsType *)TRACKS
{
    if (!TRACKS)
        TRACKS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_gpx_tracks") name:@"TRACKS" itemName:@"GPX" iconName:@"ic_custom_trip" isAvailableInFreeVersion:NO];
    return TRACKS;
}

+ (OAExportSettingsType *)OSM_NOTES
{
    if (!OSM_NOTES)
        OSM_NOTES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"osm_notes") name:@"OSM_NOTES" itemName:@"OSM_NOTES" iconName:@"ic_action_osm_note" isAvailableInFreeVersion:YES];
    return OSM_NOTES;
}

+ (OAExportSettingsType *)OSM_EDITS
{
    if (!OSM_EDITS)
        OSM_EDITS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"osm_edits_title") name:@"OSM_EDITS" itemName:@"OSM_EDITS" iconName:@"ic_custom_osm_edits" isAvailableInFreeVersion:YES];
    return OSM_EDITS;
}

+ (OAExportSettingsType *)ACTIVE_MARKERS
{
    if (!ACTIVE_MARKERS)
        ACTIVE_MARKERS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"map_markers") name:@"ACTIVE_MARKERS" itemName:@"ACTIVE_MARKERS" iconName:@"ic_custom_marker" isAvailableInFreeVersion:NO];
    return ACTIVE_MARKERS;
}

+ (OAExportSettingsType *)HISTORY_MARKERS
{
    if (!HISTORY_MARKERS)
        HISTORY_MARKERS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"markers_history") name:@"HISTORY_MARKERS" itemName:@"HISTORY_MARKERS" iconName:@"ic_custom_marker" isAvailableInFreeVersion:NO];
    return HISTORY_MARKERS;
}

+ (OAExportSettingsType *)SEARCH_HISTORY
{
    if (!SEARCH_HISTORY)
        SEARCH_HISTORY = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_search_history") name:@"SEARCH_HISTORY" itemName:@"SEARCH_HISTORY" iconName:@"ic_custom_search" isAvailableInFreeVersion:NO];
    return SEARCH_HISTORY;
}

+ (OAExportSettingsType *)NAVIGATION_HISTORY
{
    if (!NAVIGATION_HISTORY)
        NAVIGATION_HISTORY = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"navigation_history") name:@"NAVIGATION_HISTORY" itemName:@"NAVIGATION_HISTORY" iconName:@"ic_custom_navigation" isAvailableInFreeVersion:NO];
    return NAVIGATION_HISTORY;
}

+ (OAExportSettingsType *)CUSTOM_RENDER_STYLE
{
    if (!CUSTOM_RENDER_STYLE)
        CUSTOM_RENDER_STYLE = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_rendering_style") name:@"CUSTOM_RENDER_STYLE" itemName:@"FILE" iconName:@"ic_custom_map_style" isAvailableInFreeVersion:NO];
    return CUSTOM_RENDER_STYLE;
}

+ (OAExportSettingsType *)CUSTOM_ROUTING
{
    if (!CUSTOM_ROUTING)
        CUSTOM_ROUTING = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_routing") name:@"CUSTOM_ROUTING" itemName:@"FILE" iconName:@"ic_custom_file_routing" isAvailableInFreeVersion:NO];
    return CUSTOM_ROUTING;
}

+ (OAExportSettingsType *)MAP_SOURCES
{
    if (!MAP_SOURCES)
        MAP_SOURCES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"quick_action_map_source_title") name:@"MAP_SOURCES" itemName:@"MAP_SOURCES" iconName:@"ic_custom_overlay_map" isAvailableInFreeVersion:NO];
    return MAP_SOURCES;
}

+ (OAExportSettingsType *)STANDARD_MAPS
{
    if (!STANDARD_MAPS)
        STANDARD_MAPS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"standard_maps") name:@"STANDARD_MAPS" itemName:@"FILE" iconName:@"ic_custom_map" isAvailableInFreeVersion:NO];
    return STANDARD_MAPS;
}

+ (OAExportSettingsType *)WIKI_AND_TRAVEL
{
    if (!WIKI_AND_TRAVEL)
        WIKI_AND_TRAVEL = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"wikipedia_and_travel_maps") name:@"WIKI_AND_TRAVEL" itemName:@"FILE" iconName:@"ic_custom_wikipedia" isAvailableInFreeVersion:NO];
    return WIKI_AND_TRAVEL;
}

+ (OAExportSettingsType *)DEPTH_DATA
{
    if (!DEPTH_DATA)
        DEPTH_DATA = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"nautical_maps") name:@"DEPTH_DATA" itemName:@"FILE" iconName:@"ic_live_nautical_depth" isAvailableInFreeVersion:NO];
    return DEPTH_DATA;
}

+ (OAExportSettingsType *)TERRAIN_DATA
{
    if (!TERRAIN_DATA)
        TERRAIN_DATA = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"topography_maps") name:@"TERRAIN_DATA" itemName:@"FILE" iconName:@"ic_custom_terrain" isAvailableInFreeVersion:NO];
    return TERRAIN_DATA;
}

+ (OAExportSettingsType *)TTS_VOICE
{
    return nil; // Not implemented
}

+ (OAExportSettingsType *)VOICE
{
    return nil; // Not implemented
}

+ (OAExportSettingsType *)ONLINE_ROUTING_ENGINES
{
    return nil; // Not implemented
}

+ (OAExportSettingsType *)ITINERARY_GROUPS
{
    return nil; // Not implemented
}

+ (OAExportSettingsType *)COLOR_PALETTE
{
    if (!COLOR_PALETTE)
        COLOR_PALETTE = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_colors") name:@"COLOR_PALETTE" itemName:@"FILE" iconName:@"ic_custom_appearance" isAvailableInFreeVersion:NO];
    return COLOR_PALETTE;
}

- (OALocalItemType *)getRelatedLocalItemType
{
    if (self == PROFILE)
        return [OALocalItemType PROFILES];
    else if (self == GLOBAL)
        return nil;
    else if (self == QUICK_ACTIONS)
        return nil;
    else if (self == POI_TYPES)
        return nil;
    else if (self == AVOID_ROADS)
        return nil;
    else if (self == FAVORITES)
        return [OALocalItemType FAVORITES];
    else if (self == TRACKS)
        return [OALocalItemType TRACKS];
    else if (self == OSM_NOTES)
        return [OALocalItemType OSM_NOTES];
    else if (self == OSM_EDITS)
        return [OALocalItemType OSM_EDITS];
    //else if (self == MULTIMEDIA_NOTES)
    //    return [OALocalItemType MULTIMEDIA_NOTES];
    else if (self == ACTIVE_MARKERS)
        return [OALocalItemType ACTIVE_MARKERS];
    else if (self == HISTORY_MARKERS)
        return [OALocalItemType HISTORY_MARKERS];
    else if (self == SEARCH_HISTORY)
        return nil;
    else if (self == NAVIGATION_HISTORY)
        return nil;
    //else if (self == ITINERARY_GROUPS)
    //    return [OALocalItemType ITINERARY_GROUPS];
    else if (self == CUSTOM_RENDER_STYLE)
        return [OALocalItemType RENDERING_STYLES];
    else if (self == CUSTOM_ROUTING)
        return [OALocalItemType ROUTING];
    else if (self == ONLINE_ROUTING_ENGINES)
        return nil;
    else if (self == MAP_SOURCES)
        return [OALocalItemType TILES_DATA];
    else if (self == STANDARD_MAPS)
        return [OALocalItemType MAP_DATA];
    else if (self == WIKI_AND_TRAVEL)
        return [OALocalItemType WIKI_AND_TRAVEL_MAPS];
    else if (self == DEPTH_DATA)
        return [OALocalItemType DEPTH_DATA];
    //else if (self == ROAD_MAPS)
    //    return [OALocalItemType ROAD_MAPS];
    else if (self == TERRAIN_DATA)
        return [OALocalItemType TERRAIN_DATA];
    else if (self == TTS_VOICE)
        return [OALocalItemType TTS_VOICE_DATA];
    else if (self == VOICE)
        return [OALocalItemType VOICE_DATA];
    //else if (self == FAVORITES_BACKUP)
    //    return [OALocalItemType FAVORITES_BACKUP];
    else if (self == COLOR_PALETTE)
        return [OALocalItemType COLOR_DATA];
    return nil;
}

+ (OAExportSettingsType *)findByLocalItemType:(OALocalItemType *)localItemType
{
    for (OAExportSettingsType *value in [self.class getAllValues])
    {
        if ([value getRelatedLocalItemType] == localItemType)
            return value;
    }
    return nil;
}

- (BOOL) isSettingsCategory
{
    return self == self.class.PROFILE || self == self.class.GLOBAL || self == self.class.QUICK_ACTIONS || self == self.class.POI_TYPES
    || self == self.class.AVOID_ROADS || self == self.class.COLOR_PALETTE;
}

- (BOOL) isMyPlacesCategory
{
    return self == self.class.FAVORITES || self == self.class.TRACKS || self == self.class.OSM_EDITS || self == self.class.OSM_NOTES
    /*|| self == self.class.MULTIMEDIA_NOTES*/ || self == self.class.ACTIVE_MARKERS || self == self.class.HISTORY_MARKERS
    || self == self.class.SEARCH_HISTORY || self == self.class.NAVIGATION_HISTORY;
}

- (BOOL) isResourcesCategory
{
    return self == self.class.CUSTOM_RENDER_STYLE || self == self.class.CUSTOM_ROUTING || self == self.class.MAP_SOURCES
    || self == self.class.STANDARD_MAPS || self == self.class.WIKI_AND_TRAVEL || self == self.class.DEPTH_DATA ||self == self.class.TERRAIN_DATA /*|| self == self.class.VOICE || self == self.class.TTS_VOICE || self == self.class.ONLINE_ROUTING_ENGINES*/;
}

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

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    // It is safe to return self here, since the Type is immutable
    return self;
}

@end
