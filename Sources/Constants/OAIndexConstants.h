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

static NSString * const MAP_CREATOR_DIR = @"MapCreator";
static NSString * const RESOURCES_DIR = @"Resources";

static NSString * const SQLITE_EXT = @".sqlitedb";
static NSString * const TEMP_SOURCE_TO_LOAD = @"temp";

static NSString * const POI_INDEX_EXT = @".poi.odb";

static NSString * const ZIP_EXT = @".zip";
static NSString * const BINARY_MAP_INDEX_EXT = @".obf";
static NSString * const BINARY_MAP_INDEX_EXT_ZIP = @".obf.zip";

static NSString * const BINARY_WIKIVOYAGE_MAP_INDEX_EXT = @".sqlite";
static NSString * const BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT = @".travel.obf";
static NSString * const BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT_ZIP = @".travel.obf.zip";
static NSString * const BINARY_WIKI_MAP_INDEX_EXT = @".wiki.obf";
static NSString * const BINARY_WIKI_MAP_INDEX_EXT_ZIP = @".wiki.obf.zip";
static NSString * const BINARY_ROAD_MAP_INDEX_EXT = @".road.obf";
static NSString * const BINARY_ROAD_MAP_INDEX_EXT_ZIP = @".road.obf.zip";
static NSString * const BINARY_SRTM_MAP_INDEX_EXT = @".srtm.obf";
static NSString * const BINARY_SRTM_MAP_INDEX_EXT_ZIP = @".srtm.obf.zip";
static NSString * const BINARY_SRTMF_MAP_INDEX_EXT = @".srtmf.obf";
static NSString * const BINARY_SRTMF_MAP_INDEX_EXT_ZIP = @".srtmf.obf.zip";
static NSString * const BINARY_DEPTH_MAP_INDEX_EXT = @".depth.obf";
static NSString * const BINARY_DEPTH_MAP_INDEX_EXT_ZIP = @".depth.obf.zip";
static NSString * const EXTRA_EXT = @".extra";
static NSString * const EXTRA_ZIP_EXT = @".extra.zip";
static NSString * const TXT_EXT = @".txt";

static NSString * const GEN_LOG_EXT = @".gen.log";

static NSString * const VOICE_INDEX_EXT_ZIP = @".voice.zip";
static NSString * const TTSVOICE_INDEX_EXT_JS = @"tts.js";
static NSString * const ANYVOICE_INDEX_EXT_ZIP = @"voice.zip"; //to cactch both voices, .voice.zip and .ttsvoice.zip

static NSString * const FONT_INDEX_EXT = @".otf";
static NSString * const FONT_INDEX_EXT_ZIP = @".otf.zip";

static NSString * const OSMAND_SETTINGS_FILE_EXT = @".osf";

static NSString * const ROUTING_FILE_EXT = @".xml";

static NSString * const RENDERER_INDEX_EXT = @".render.xml";

static NSString * const GPX_FILE_EXT = @".gpx";
static NSString * const GPX_ZIP_FILE_EXT = @".gpx.zip";

static NSString * const WPT_CHART_FILE_EXT = @".wpt.chart";
static NSString * const SQLITE_CHART_FILE_EXT = @".3d.chart";

static NSString * const POI_TABLE = @"poi";

static NSString * const INDEX_DOWNLOAD_DOMAIN = @"download.osmand.net";
static NSString * const APP_DIR = @"osmand/";
static NSString * const MAPS_PATH = @"";

static NSString * const HIDDEN_DIR = @"Hidden";

static NSString * const BACKUP_INDEX_DIR = @"backup/";
static NSString * const GPX_INDEX_DIR = @"tracks/";
static NSString * const MAP_MARKERS_INDEX_DIR = @"/map markers";
//public static final String GPX_RECORDED_INDEX_DIR = GPX_INDEX_DIR + "rec/";
//public static final String GPX_IMPORT_DIR = GPX_INDEX_DIR + "import/";

static NSString * const TILES_INDEX_DIR = @"tiles";
static NSString * const LIVE_INDEX_DIR = @"live";
static NSString * const TOURS_INDEX_DIR = @"tours";
static NSString * const SRTM_INDEX_DIR = @"srtm";
static NSString * const NAUTICAL_INDEX_DIR = @"nautical";
static NSString * const ROADS_INDEX_DIR = @"roads";
static NSString * const WIKI_INDEX_DIR = @"wiki";
static NSString * const WIKIVOYAGE_INDEX_DIR = @"Travel";
//public static final String GPX_TRAVEL_DIR = GPX_INDEX_DIR + WIKIVOYAGE_INDEX_DIR;
static NSString * const AV_INDEX_DIR = @"avnotes";
static NSString * const FONT_INDEX_DIR = @"fonts";
static NSString * const VOICE_INDEX_DIR = @"voice";
static NSString * const RENDERERS_DIR = @"rendering";
static NSString * const ROUTING_XML_FILE = @"routing.xml";
static NSString * const SETTINGS_DIR = @"settings";
static NSString * const TEMP_DIR = @"temp";
static NSString * const ROUTING_PROFILES_DIR = @"routing";
static NSString * const PLUGINS_DIR = @"Plugins";
static NSString * const FAVORITES_INDEX_DIR = @"favorites";
static NSString * const FAVORITES_BACKUP_DIR = @"favorites_backup";
static NSString * const COLOR_PALETTE_DIR = @"color-palette";

static NSString * const VOICE_PROVIDER_SUFFIX = @"-tts";

static NSString * const GEOTIFF_SQLITE_CACHE_DIR = @"geotiff_sqlite_cache";

#endif /* OAIndexConstants_h */
