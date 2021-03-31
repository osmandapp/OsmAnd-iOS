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

static OAExportSettingsType * PROFILE;
static OAExportSettingsType * GLOBAL;
static OAExportSettingsType * QUICK_ACTIONS;
static OAExportSettingsType * POI_TYPES;
static OAExportSettingsType * AVOID_ROADS;
static OAExportSettingsType * FAVORITES;
static OAExportSettingsType * TRACKS;
static OAExportSettingsType * OSM_NOTES;
static OAExportSettingsType * OSM_EDITS;
static OAExportSettingsType * MULTIMEDIA_NOTES;
static OAExportSettingsType * ACTIVE_MARKERS;
static OAExportSettingsType * HISTORY_MARKERS;
static OAExportSettingsType * SEARCH_HISTORY;
static OAExportSettingsType * CUSTOM_RENDER_STYLE;
static OAExportSettingsType * CUSTOM_ROUTING;
static OAExportSettingsType * MAP_SOURCES;
static OAExportSettingsType * OFFLINE_MAPS;
static OAExportSettingsType * TTS_VOICE;
static OAExportSettingsType * VOICE;
static OAExportSettingsType * ONLINE_ROUTING_ENGINES;

@interface OAExportSettingsType ()

- (instancetype) initWithTitle:(NSString *)title icon:(UIImage *)icon;

@end

@implementation OAExportSettingsType

- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
    }
    return self;
}

+ (OAExportSettingsType *)PROFILE
{
    if (!PROFILE)
        PROFILE = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_profiles") icon:[UIImage templateImageNamed:@"ic_custom_manage_profiles"]];
    return PROFILE;
}

+ (OAExportSettingsType *)GLOBAL
{
    if (!GLOBAL)
        GLOBAL = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"general_settings_2") icon:[UIImage templateImageNamed:@"left_menu_icon_settings"]];
    return GLOBAL;
}

+ (OAExportSettingsType *)QUICK_ACTIONS
{
    if (!QUICK_ACTIONS)
        QUICK_ACTIONS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_quick_actions") icon:[UIImage templateImageNamed:@"ic_custom_quick_action"]];
    return QUICK_ACTIONS;
}

+ (OAExportSettingsType *)POI_TYPES
{
    if (!POI_TYPES)
        POI_TYPES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_poi_types") icon:[UIImage templateImageNamed:@"ic_custom_poi"]];
    return POI_TYPES;
}

+ (OAExportSettingsType *)AVOID_ROADS
{
    if (!AVOID_ROADS)
        AVOID_ROADS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"avoid_road") icon:[UIImage templateImageNamed:@"ic_custom_alert"]];
    return AVOID_ROADS;
}

+ (OAExportSettingsType *)FAVORITES
{
    if (!FAVORITES)
        FAVORITES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"favorites") icon:[UIImage templateImageNamed:@"ic_custom_favorites"]];
    return FAVORITES;
}

+ (OAExportSettingsType *)TRACKS
{
    if (!TRACKS)
        TRACKS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"tracks") icon:[UIImage templateImageNamed:@"ic_custom_trip"]];
    return TRACKS;
}

+ (OAExportSettingsType *)OSM_NOTES
{
    if (!OSM_NOTES)
        OSM_NOTES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"osm_notes") icon:[UIImage templateImageNamed:@"ic_action_osm_note"]];
    return OSM_NOTES;
}

+ (OAExportSettingsType *)OSM_EDITS
{
    if (!OSM_EDITS)
        OSM_EDITS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"osm_edits_title") icon:[UIImage templateImageNamed:@"ic_custom_osm_edits"]];
    return OSM_EDITS;
}

+ (OAExportSettingsType *)MULTIMEDIA_NOTES
{
    return nil; // Not implemented
}

+ (OAExportSettingsType *)ACTIVE_MARKERS
{
    if (!ACTIVE_MARKERS)
        ACTIVE_MARKERS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"map_markers") icon:[UIImage templateImageNamed:@"ic_custom_marker"]];
    return ACTIVE_MARKERS;
}

+ (OAExportSettingsType *)HISTORY_MARKERS
{
    if (!HISTORY_MARKERS)
        HISTORY_MARKERS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"markers_history") icon:[UIImage templateImageNamed:@"ic_custom_marker"]];
    return HISTORY_MARKERS;
}

+ (OAExportSettingsType *)SEARCH_HISTORY
{
    if (!SEARCH_HISTORY)
        SEARCH_HISTORY = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"search_history") icon:[UIImage templateImageNamed:@"ic_custom_history"]];
    return SEARCH_HISTORY;
}

+ (OAExportSettingsType *)CUSTOM_RENDER_STYLE
{
    if (!CUSTOM_RENDER_STYLE)
        CUSTOM_RENDER_STYLE = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_rendering_style") icon:[UIImage templateImageNamed:@"ic_custom_map_style"]];
    return CUSTOM_RENDER_STYLE;
}

+ (OAExportSettingsType *)CUSTOM_ROUTING
{
    if (!CUSTOM_ROUTING)
        CUSTOM_ROUTING = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"shared_string_routing") icon:[UIImage templateImageNamed:@"ic_custom_routes"]];
    return CUSTOM_ROUTING;
}

+ (OAExportSettingsType *)MAP_SOURCES
{
    if (!MAP_SOURCES)
        MAP_SOURCES = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"map_sources") icon:[UIImage templateImageNamed:@"ic_custom_map"]];
    return MAP_SOURCES;
}

+ (OAExportSettingsType *)OFFLINE_MAPS
{
    if (!OFFLINE_MAPS)
        OFFLINE_MAPS = [[OAExportSettingsType alloc] initWithTitle:OALocalizedString(@"offline_maps") icon:[UIImage templateImageNamed:@"ic_custom_map"]];
    return OFFLINE_MAPS;
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

- (BOOL) isSettingsCategory
{
    return self == self.class.PROFILE || self == self.class.GLOBAL || self == self.class.QUICK_ACTIONS || self == self.class.POI_TYPES
    || self == self.class.AVOID_ROADS;
}

- (BOOL) isMyPlacesCategory
{
    return self == self.class.FAVORITES || self == self.class.TRACKS || self == self.class.OSM_EDITS || self == self.class.OSM_NOTES
    /*|| self == self.class.MULTIMEDIA_NOTES*/ || self == self.class.ACTIVE_MARKERS || self == self.class.HISTORY_MARKERS
    || self == self.class.SEARCH_HISTORY;
}

- (BOOL) isResourcesCategory
{
    return self == self.class.CUSTOM_RENDER_STYLE /*|| self == self.class.CUSTOM_ROUTING*/ || self == self.class.MAP_SOURCES
    || self == self.class.OFFLINE_MAPS /*|| self == self.class.VOICE || self == self.class.TTS_VOICE || self == self.class.ONLINE_ROUTING_ENGINES*/;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    // It is safe to return self here, since the Type is immutable
    return self;
}

@end
