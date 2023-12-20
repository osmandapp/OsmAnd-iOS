//
//  OAIndexConstants.h
//  OsmAnd
//
//  Created by Paul on 13.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

// Important : Every time you change schema of db upgrade version!!!
// If you want that new application support old index : put upgrade code in android app ResourceManager
//    public final static int POI_TABLE_VERSION = 1;
//    public final static int BINARY_MAP_VERSION = 2; // starts with 1
//    public final static int VOICE_VERSION = 0; //supported download versions
//    public final static int TTSVOICE_VERSION = 1; //supported download versions

#ifndef OAIndexConstants_h
#define OAIndexConstants_h

#define MAP_CREATOR_DIR @"MapCreator"
#define RESOURCES_DIR @"Resources"

#define SQLITE_EXT @".sqlitedb"
#define TEMP_SOURCE_TO_LOAD @"temp"

#define POI_INDEX_EXT @".poi.odb"

#define ZIP_EXT @".zip"
#define BINARY_MAP_INDEX_EXT @".obf"
#define BINARY_MAP_INDEX_EXT_ZIP @".obf.zip"

#define BINARY_WIKIVOYAGE_MAP_INDEX_EXT @".sqlite"
#define BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT @".travel.obf"
#define BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT_ZIP @".travel.obf.zip"
#define BINARY_WIKI_MAP_INDEX_EXT @".wiki.obf"
#define BINARY_WIKI_MAP_INDEX_EXT_ZIP @".wiki.obf.zip"
#define BINARY_ROAD_MAP_INDEX_EXT @".road.obf"
#define BINARY_ROAD_MAP_INDEX_EXT_ZIP @".road.obf.zip"
#define BINARY_SRTM_MAP_INDEX_EXT @".srtm.obf"
#define BINARY_SRTM_MAP_INDEX_EXT_ZIP @".srtm.obf.zip"
#define BINARY_SRTMF_MAP_INDEX_EXT @".srtmf.obf"
#define BINARY_SRTMF_MAP_INDEX_EXT_ZIP @".srtmf.obf.zip"
#define BINARY_DEPTH_MAP_INDEX_EXT @".depth.obf"
#define BINARY_DEPTH_MAP_INDEX_EXT_ZIP @".depth.obf.zip"
#define EXTRA_EXT @".extra"
#define EXTRA_ZIP_EXT @".extra.zip"

#define GEN_LOG_EXT @".gen.log"

#define VOICE_INDEX_EXT_ZIP @".voice.zip"
#define TTSVOICE_INDEX_EXT_JS @"tts.js"
#define ANYVOICE_INDEX_EXT_ZIP @"voice.zip" //to cactch both voices, .voice.zip and .ttsvoice.zip

#define FONT_INDEX_EXT @".otf"
#define FONT_INDEX_EXT_ZIP @".otf.zip"

#define OSMAND_SETTINGS_FILE_EXT @".osf"

#define ROUTING_FILE_EXT @".xml"

#define RENDERER_INDEX_EXT @".render.xml"

#define GPX_FILE_EXT @".gpx"
#define GPX_ZIP_FILE_EXT @".gpx.zip"

#define WPT_CHART_FILE_EXT @".wpt.chart"
#define SQLITE_CHART_FILE_EXT @".3d.chart"

#define POI_TABLE @"poi"

#define INDEX_DOWNLOAD_DOMAIN @"download.osmand.net"
#define APP_DIR @"osmand/"
#define MAPS_PATH @""

static NSString * const HIDDEN_DIR = @"Hidden";

#define BACKUP_INDEX_DIR @"backup/"
#define GPX_INDEX_DIR @"tracks/"
#define HIDDEN_BACKUP_DIR = HIDDEN_DIR + BACKUP_INDEX_DIR;
#define MAP_MARKERS_INDEX_DIR @"/map markers"
//public static final String GPX_RECORDED_INDEX_DIR = GPX_INDEX_DIR + "rec/";
//public static final String GPX_IMPORT_DIR = GPX_INDEX_DIR + "import/";

#define TILES_INDEX_DIR @"tiles"
#define LIVE_INDEX_DIR @"live"
#define TOURS_INDEX_DIR @"tours"
#define SRTM_INDEX_DIR @"srtm"
#define NAUTICAL_INDEX_DIR "nautical"
#define ROADS_INDEX_DIR @"roads"
#define WIKI_INDEX_DIR @"wiki"
#define WIKIVOYAGE_INDEX_DIR @"Travel"
//public static final String GPX_TRAVEL_DIR = GPX_INDEX_DIR + WIKIVOYAGE_INDEX_DIR;
#define AV_INDEX_DIR @"avnotes"
#define FONT_INDEX_DIR @"fonts"
#define VOICE_INDEX_DIR @"voice"
#define RENDERERS_DIR @"rendering"
#define ROUTING_XML_FILE @"routing.xml"
#define SETTINGS_DIR @"settings"
#define TEMP_DIR @"temp"
#define ROUTING_PROFILES_DIR @"routing"
#define PLUGINS_DIR @"Plugins"
#define FAVORITES_INDEX_DIR @"favorites"
#define FAVORITES_BACKUP_DIR @"favorites_backup"

#define VOICE_PROVIDER_SUFFIX @"-tts"

#define GEOTIFF_SQLITE_CACHE_DIR @"geotiff_sqlite_cache"

#endif /* OAIndexConstants_h */
