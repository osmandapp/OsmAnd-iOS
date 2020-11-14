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

#define SQLITE_EXT @".sqlitedb" //$NON-NLS-1$
#define TEMP_SOURCE_TO_LOAD @"temp"

#define POI_INDEX_EXT @".poi.odb" //$NON-NLS-1$

#define ZIP_EXT @".zip" //$NON-NLS-1$
#define BINARY_MAP_INDEX_EXT @".obf" //$NON-NLS-1$
#define BINARY_MAP_INDEX_EXT_ZIP @".obf.zip" //$NON-NLS-1$

#define BINARY_WIKIVOYAGE_MAP_INDEX_EXT @".sqlite" //$NON-NLS-1$
#define BINARY_WIKI_MAP_INDEX_EXT @".wiki.obf" //$NON-NLS-1$
#define BINARY_WIKI_MAP_INDEX_EXT_ZIP @".wiki.obf.zip" //$NON-NLS-1$
#define BINARY_ROAD_MAP_INDEX_EXT @".road.obf" //$NON-NLS-1$
#define BINARY_ROAD_MAP_INDEX_EXT_ZIP @".road.obf.zip" //$NON-NLS-1$
#define BINARY_SRTM_MAP_INDEX_EXT @".srtm.obf" //$NON-NLS-1$
#define BINARY_SRTM_MAP_INDEX_EXT_ZIP @".srtm.obf.zip" //$NON-NLS-1$
#define EXTRA_EXT @".extra"
#define EXTRA_ZIP_EXT @".extra.zip"

#define GEN_LOG_EXT @".gen.log" //$NON-NLS-1$

#define VOICE_INDEX_EXT_ZIP @".voice.zip" //$NON-NLS-1$
#define TTSVOICE_INDEX_EXT_JS @"tts.js"
#define ANYVOICE_INDEX_EXT_ZIP @"voice.zip" //$NON-NLS-1$ //to cactch both voices, .voice.zip and .ttsvoice.zip

#define FONT_INDEX_EXT @".otf" //$NON-NLS-1$
#define FONT_INDEX_EXT_ZIP @".otf.zip" //$NON-NLS-1$

#define OSMAND_SETTINGS_FILE_EXT @".osf"

#define ROUTING_FILE_EXT @".xml"

#define RENDERER_INDEX_EXT @".render.xml" //$NON-NLS-1$

#define GPX_FILE_EXT @".gpx" //$NON-NLS-1$

#define WPT_CHART_FILE_EXT @".wpt.chart"
#define SQLITE_CHART_FILE_EXT @".3d.chart"

#define POI_TABLE @"poi" //$NON-NLS-1$

#define INDEX_DOWNLOAD_DOMAIN @"download.osmand.net"
#define APP_DIR @"osmand/" //$NON-NLS-1$
#define MAPS_PATH @""
#define BACKUP_INDEX_DIR @"backup/"
#define GPX_INDEX_DIR @"tracks/"
#define MAP_MARKERS_INDEX_DIR @"/map markers"
//public static final String GPX_RECORDED_INDEX_DIR = GPX_INDEX_DIR + "rec/";
//public static final String GPX_IMPORT_DIR = GPX_INDEX_DIR + "import/";

#define TILES_INDEX_DIR @"tiles/"
#define LIVE_INDEX_DIR @"live/"
#define TOURS_INDEX_DIR @"tours/"
#define SRTM_INDEX_DIR @"srtm/" //$NON-NLS-1$
#define ROADS_INDEX_DIR @"roads/" //$NON-NLS-1$
#define WIKI_INDEX_DIR @"wiki/" //$NON-NLS-1$
#define WIKIVOYAGE_INDEX_DIR @"travel/"
//public static final String GPX_TRAVEL_DIR = GPX_INDEX_DIR + WIKIVOYAGE_INDEX_DIR;
#define AV_INDEX_DIR @"avnotes/" //$NON-NLS-1$
#define FONT_INDEX_DIR @"fonts/" //$NON-NLS-1$
#define VOICE_INDEX_DIR @"voice/" //$NON-NLS-1$
#define RENDERERS_DIR @"rendering/" //$NON-NLS-1$
#define ROUTING_XML_FILE @"routing.xml"
#define SETTINGS_DIR @"settings/" //$NON-NLS-1$
#define TEMP_DIR @"temp/"
#define ROUTING_PROFILES_DIR @"routing/"
#define PLUGINS_DIR @"plugins/"

#define VOICE_PROVIDER_SUFFIX @"-tts"

#endif /* OAIndexConstants_h */
