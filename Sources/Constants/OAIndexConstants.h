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

static NSString *MAP_CREATOR_DIR = @"MapCreator";
static NSString *RESOURCES_DIR = @"Resources";

static NSString *SQLITE_EXT = @".sqlitedb";
static NSString *TEMP_SOURCE_TO_LOAD = @"temp";

static NSString *POI_INDEX_EXT = @".poi.odb";

static NSString *ZIP_EXT = @".zip";
static NSString *BINARY_MAP_INDEX_EXT = @".obf";
static NSString *BINARY_MAP_INDEX_EXT_ZIP = @".obf.zip";

static NSString *BINARY_WIKIVOYAGE_MAP_INDEX_EXT = @".sqlite";
static NSString *BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT = @".travel.obf";
static NSString *BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT_ZIP = @".travel.obf.zip";

static NSString *BINARY_WIKI_MAP_INDEX_EXT = @".wiki.obf";
static NSString *BINARY_WIKI_MAP_INDEX_EXT_ZIP = @".wiki.obf.zip";

static NSString *BINARY_ROAD_MAP_INDEX_EXT = @".road.obf";
static NSString *BINARY_ROAD_MAP_INDEX_EXT_ZIP = @".road.obf.zip";

static NSString *BINARY_SRTM_MAP_INDEX_EXT = @".srtm.obf";
static NSString *BINARY_SRTM_MAP_INDEX_EXT_ZIP = @".srtm.obf.zip";
static NSString *BINARY_SRTMF_MAP_INDEX_EXT = @".srtmf.obf";
static NSString *BINARY_SRTMF_MAP_INDEX_EXT_ZIP = @".srtmf.obf.zip";

static NSString *BINARY_DEPTH_MAP_INDEX_EXT = @".depth.obf";
static NSString *BINARY_DEPTH_MAP_INDEX_EXT_ZIP = @".depth.obf.zip";

static NSString *EXTRA_EXT = @".extra";
static NSString *EXTRA_ZIP_EXT = @".extra.zip";

static NSString *OSM_GZ_EXT = @".osm.gz";
static NSString *HTML_EXT = @".html";
static NSString *GEN_LOG_EXT = @".gen.log";
static NSString *DOWNLOAD_EXT = @".download";

static NSString *TIF_EXT = @".tif";
static NSString *TIFF_DB_EXT = @".tiff.db";

static NSString *WEATHER_EXT = @".tifsqlite";
static NSString *WEATHER_MAP_INDEX_EXT = @".tifsqlite.zip";

static NSString *VOICE_INDEX_EXT_ZIP = @".voice.zip";
static NSString *TTSVOICE_INDEX_EXT_JS = @"tts.js";
static NSString *ANYVOICE_INDEX_EXT_ZIP = @"voice.zip"; //to cactch both voices, .voice.zip and .ttsvoice.zip

static NSString *FONT_INDEX_EXT = @".otf";
static NSString *FONT_INDEX_EXT_ZIP = @".otf.zip";

static NSString *OSMAND_SETTINGS_FILE_EXT = @".osf";

static NSString *ROUTING_FILE_EXT = @".xml";

static NSString *RENDERER_INDEX_EXT = @".render.xml";
static NSString *ADDON_RENDERER_INDEX_EXT = @".addon.render.xml";

static NSString *GPX_FILE_EXT = @".gpx";
static NSString *GPX_ZIP_FILE_EXT = @".gpx.zip";

static NSString *WPT_CHART_FILE_EXT = @".wpt.chart";
static NSString *SQLITE_CHART_FILE_EXT = @".3d.chart";

static NSString *HELP_ARTICLE_FILE_EXT = @".mht";

static NSString *AVOID_ROADS_FILE_EXT = @".geojson";

static NSString *OBJ_FILE_EXT = @".obj";
static NSString *TXT_EXT = @".txt";
static NSString *POI_TABLE = @"poi";

static NSString *INDEX_DOWNLOAD_DOMAIN = @"download.osmand.net";
static NSString *APP_DIR = @"osmand/";
static NSString *MAPS_PATH = @"";

static NSString *HIDDEN_DIR = @"Hidden";
static NSString *BACKUP_INDEX_DIR = @"backup";
static NSString *HIDDEN_BACKUP_DIR = @"Hidden/backup";
static NSString *GPX_INDEX_DIR = @"tracks";
static NSString *FAVORITES_INDEX_DIR = @"favorites";
static NSString *FAVORITES_BACKUP_DIR = @"favorites_backup";
static NSString *MAP_MARKERS_INDEX_DIR = @"map markers";

static NSString *GPX_RECORDED_INDEX_DIR = @"tracks/rec";
static NSString *GPX_IMPORT_DIR = @"tracks/import";

static NSString *TILES_INDEX_DIR = @"tiles";
static NSString *LIVE_INDEX_DIR = @"live";
static NSString *TOURS_INDEX_DIR = @"tours";
static NSString *SRTM_INDEX_DIR = @"srtm";
static NSString *NAUTICAL_INDEX_DIR = @"nautical";
static NSString *ROADS_INDEX_DIR = @"roads";
static NSString *WIKI_INDEX_DIR = @"wiki";
static NSString *HELP_INDEX_DIR = @"help";
static NSString *ARTICLES_DIR = @"help/articles";
static NSString *WIKIVOYAGE_INDEX_DIR = @"Travel";
static NSString *GPX_TRAVEL_DIR = @"tracks/travel";
static NSString *AV_INDEX_DIR = @"avnotes";
static NSString *FONT_INDEX_DIR = @"fonts";
static NSString *VOICE_INDEX_DIR = @"voice";
static NSString *RENDERERS_DIR = @"rendering";
static NSString *ROUTING_XML_FILE = @"routing.xml";
static NSString *SETTINGS_DIR = @"settings";
static NSString *TEMP_DIR = @"temp";
static NSString *ROUTING_PROFILES_DIR = @"routing";
static NSString *PLUGINS_DIR = @"Plugins";

static NSString *GEOTIFF_SQLITE_CACHE_DIR = @"geotiff_sqlite_cache";
static NSString *GEOTIFF_DIR = @"geotiff/";

static NSString *COLOR_PALETTE_DIR = @"color-palette";

static NSString *WEATHER_FORECAST_DIR = @"weather_forecast";

static NSString *MODEL_3D_DIR = @"models";
static NSString *VOICE_PROVIDER_SUFFIX = @"-tts";

static NSString *MODEL_NAME_PREFIX = @"model_";

#endif /* OAIndexConstants_h */
