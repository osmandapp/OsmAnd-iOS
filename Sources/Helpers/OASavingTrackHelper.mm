//
//  OASavingTrackHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASavingTrackHelper.h"
#import "OALog.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAAppSettings.h"
#import "OACommonTypes.h"
#import "OARoutingHelper.h"
#import "OAMonitoringPlugin.h"
#import "OAPlugin.h"
#import "Localization.h"
#import "OAGPXAppearanceCollection.h"
#import "OAPluginsHelper.h"
#import "OAGPXDatabase.h"
#import "OAColoringType.h"
#import "OAObservable.h"
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>
#import "OAAppVersion.h"

#import "OsmAndSharedWrapper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define DATABASE_NAME @"tracks"
#define DATABASE_VERSION 4

#define TRACK_NAME @"track"
#define TRACK_COL_DATE @"date"
#define TRACK_COL_LAT @"lat"
#define TRACK_COL_LON @"lon"
#define TRACK_COL_ALTITUDE @"altitude"
#define TRACK_COL_SPEED @"speed"
#define TRACK_COL_HDOP @"hdop"
#define TRACK_COL_HEADING @"heading"
#define TRACK_COL_PLUGINS_INFO @"plugins_info"

#define POINT_NAME @"point"
#define POINT_COL_DATE @"date"
#define POINT_COL_LAT @"lat"
#define POINT_COL_LON @"lon"
#define POINT_COL_NAME @"description"
#define POINT_COL_CATEGORY @"group_name"
#define POINT_COL_DESCRIPTION @"desc_text"
#define POINT_COL_COLOR @"color"
#define POINT_COL_ICON @"icon"
#define POINT_COL_BACKGROUND @"background"

#define ACCURACY_FOR_GPX_AND_ROUTING 50.0

#define recordedTrackFolder @"/rec/"

@implementation OASavingTrackHelper
{
    OsmAndAppInstance _app;

    sqlite3 *tracksDB;
    NSString *databasePath;
    dispatch_queue_t dbQueue;
    dispatch_queue_t syncQueue;
    
    CLLocationCoordinate2D lastPoint;
}

@synthesize lastTimeUpdated, points, isRecording, distance, currentTrackIndex;

+ (OASavingTrackHelper*)sharedInstance
{
    static OASavingTrackHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OASavingTrackHelper alloc] init];
    });
    return _sharedInstance;
}

- (void)setupCurrentTrack
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
        
    _currentTrack = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
    _currentTrack.showCurrentTrack = YES;
    [_currentTrack setWidthWidth:[settings.currentTrackWidth get]];
    [_currentTrack setShowArrowsShowArrows:[settings.currentTrackWidth get]];
    [_currentTrack setShowStartFinishShowStartFinish:[settings.currentTrackShowStartFinish get]];
    // setVerticalExaggerationScale -> setAdditionalExaggerationAdditionalExaggeration (SharedLib)
    [_currentTrack setAdditionalExaggerationAdditionalExaggeration:[settings.currentTrackVerticalExaggerationScale get]];
    [_currentTrack setElevationMetersElevation:[settings.currentTrackElevationMeters get]];
   
    [_currentTrack set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)[settings.currentTrackVisualization3dByType get]]];
    
    [_currentTrack set3DWallColoringTypeTrackWallColoringType:[OAGPXDatabase lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)[settings.currentTrackVisualization3dWallColorType get]]];
    
    [_currentTrack set3DLinePositionTypeTrackLinePositionType:[OAGPXDatabase lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)[settings.currentTrackVisualization3dPositionType get]]];
    
    OASInt *color = [[OASInt alloc] initWithInt:[settings.currentTrackColor get]];
    [_currentTrack setColorColor:color];
    [_currentTrack setColoringTypeColoringType:[settings.currentTrackColoringType get].name];
    
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        currentTrackIndex = 1;
        syncQueue = dispatch_queue_create("sth_syncQueue", DISPATCH_QUEUE_SERIAL);

        [self createDb];
        
        [self setupCurrentTrack];

        if (![self saveIfNeeded])
            [self loadGpxFromDatabase];
    }
    return self;
}

- (void)onTrackRecordingChanged
{
    //
}

- (void)createDb
{
    dbQueue = dispatch_queue_create("sth_dbQueue", DISPATCH_QUEUE_SERIAL);
    
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/TracksDatabase"];
    databasePath = [dir stringByAppendingString:@"/tracks.db"];

    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    dispatch_sync(dbQueue, ^{

        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [databasePath UTF8String];
        
        if ([filemgr fileExistsAtPath: databasePath ] == NO)
        {
            if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ double, %@ double, %@ double, %@ double, %@ double, %@ double, %@ double, %@ text)", TRACK_NAME, TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE, TRACK_COL_HEADING, TRACK_COL_PLUGINS_INFO] UTF8String];
                
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ double, %@ double, %@ double, %@ text, %@ text, %@ text, %@ text, %@ text, %@ text)", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_DESCRIPTION, POINT_COL_ICON, POINT_COL_BACKGROUND] UTF8String];
                
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sqlite3_close(tracksDB);
            }
            else
            {
                // Failed to open/create database
            }
        }
        else
        {
            // Upgrade if needed
            if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
            {
                char *errMsg;
                
                const char *sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", POINT_NAME, POINT_COL_COLOR] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", POINT_COL_COLOR, POINT_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", POINT_NAME, POINT_COL_CATEGORY] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", POINT_COL_CATEGORY, POINT_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", POINT_NAME, POINT_COL_DESCRIPTION] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", POINT_COL_DESCRIPTION, POINT_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", POINT_NAME, POINT_COL_ICON] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", POINT_COL_ICON, POINT_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", POINT_NAME, POINT_COL_BACKGROUND] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", POINT_COL_BACKGROUND, POINT_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ double", TRACK_NAME, TRACK_COL_HEADING] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", TRACK_COL_HEADING, TRACK_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", TRACK_NAME, TRACK_COL_PLUGINS_INFO] UTF8String];
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to add column - %@, for table - %@ | error: %s", TRACK_COL_PLUGINS_INFO, TRACK_NAME, errMsg);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sqlite3_close(tracksDB);
            }
            else
            {
                // Failed to upate database
            }
        }
        
    });

}
    
- (long)getLastTrackPointTime
{
    long __block res = 0;
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt    *statement;
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ ORDER BY %@ DESC", TRACK_COL_DATE, TRACK_NAME, TRACK_COL_DATE];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    res = (long)sqlite3_column_double(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(tracksDB);
        }
    });

    return res;
}

- (BOOL) hasData
{
    return points > 0 || distance > 0 || lastPoint.longitude > 0 || lastPoint.latitude > 0;
}

- (BOOL) hasDataToSave
{
    BOOL __block res = NO;
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT count(*) FROM %@", TRACK_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    res = sqlite3_column_int(statement, 0) > 0;
                    break;
                }
                sqlite3_finalize(statement);
            }
            
            if (!res) {
                querySQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@", POINT_COL_LAT, POINT_COL_LON, POINT_NAME];
                const char *query_stmt = [querySQL UTF8String];
                if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
                {
                    while (sqlite3_step(statement) == SQLITE_ROW)
                    {
                        double lat = sqlite3_column_double(statement, 0);
                        double lon = sqlite3_column_double(statement, 1);
                        
                        if (lat != 0.0 || lon != 0.0)
                        {
                            res = YES;
                            break;
                        }
                    }
                    sqlite3_finalize(statement);
                }
            }
            
            sqlite3_close(tracksDB);
        }
    });
    
    return res;
}

- (void) clearData
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat: @"DELETE FROM %@ WHERE %@ <= %f", TRACK_NAME, TRACK_COL_DATE, [[NSDate date] timeIntervalSince1970]];
            const char *update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            updateSQL = [NSString stringWithFormat: @"DELETE FROM %@ WHERE %@ <= %f", POINT_NAME, POINT_COL_DATE, [[NSDate date] timeIntervalSince1970]];
            update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
    
    distance = 0;
    points = 0;
    currentTrackIndex++;

    lastTimeUpdated = 0;
    lastPoint = kCLLocationCoordinate2DInvalid;
    
    [self setupCurrentTrack];
    
    _currentTrack.modifiedTime = (long)[[NSDate date] timeIntervalSince1970];
    
    [self prepareCurrentTrackForRecording];
}

- (void) saveDataToGpx
{
    [self saveDataToGpxWithCompletionHandler:nil];
}

- (void) saveDataToGpxWithCompletionHandler:(void (^)(void))completionHandler
{
    dispatch_sync(syncQueue, ^{
        
        NSDictionary *data = [self collectRecordedData:NO];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // save file
        NSString *fout;
        for (NSString *f in data.allKeys)
        {
            // .../Documents/GPX/rec/2024-09-30.gpx
            fout = [NSString stringWithFormat:@"%@%@%@.gpx", _app.gpxPath, recordedTrackFolder, f];

            OASGpxFile *gpxFile = data[f];
            if (![gpxFile isEmpty])
            {
                OASWptPt *pt = [gpxFile findPointToShow];
                
                NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
                [simpleFormat setDateFormat:@"HH-mm_EEE"];
                
                NSString *fileName = [NSString stringWithFormat:@"%@_%@", f, [simpleFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:pt.time]]];
                fout = [NSString stringWithFormat:@"%@%@%@.gpx", _app.gpxPath, recordedTrackFolder, fileName];
                int ind = 1;
                while ([fileManager fileExistsAtPath:fout]) {
                    fout = [NSString stringWithFormat:@"%@%@%@_%d.gpx", _app.gpxPath, recordedTrackFolder, fileName, ++ind];
                }
            }
            
            NSFileManager *fileManager = NSFileManager.defaultManager;
            // ...Documents/GPX/rec/2024-09-30_14-28_Пн.gpx
            NSString *directory = [fout stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:directory])
                [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];
            
            OAAppSettings *settings = [OAAppSettings sharedManager];
            
            [gpxFile setWidthWidth:[settings.currentTrackWidth get]];
            [gpxFile setShowArrowsShowArrows:[settings.currentTrackWidth get]];
            [gpxFile setShowStartFinishShowStartFinish:[settings.currentTrackShowStartFinish get]];
            // setVerticalExaggerationScale -> setAdditionalExaggerationAdditionalExaggeration (SharedLib)
            [gpxFile setAdditionalExaggerationAdditionalExaggeration:[settings.currentTrackVerticalExaggerationScale get]];
            [gpxFile setElevationMetersElevation:[settings.currentTrackElevationMeters get]];
            [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationByTypeNameForType:(EOAGPX3DLineVisualizationByType)[settings.currentTrackVisualization3dByType get]]];
            
            [gpxFile set3DWallColoringTypeTrackWallColoringType:[OAGPXDatabase lineVisualizationWallColorTypeNameForType:(EOAGPX3DLineVisualizationWallColorType)[settings.currentTrackVisualization3dWallColorType get]]];
            
            [gpxFile set3DVisualizationTypeVisualizationType:[OAGPXDatabase lineVisualizationPositionTypeNameForType:(EOAGPX3DLineVisualizationPositionType)[settings.currentTrackVisualization3dPositionType get]]];
           
            OASInt *color = [[OASInt alloc] initWithInt:[settings.currentTrackColor get]];
            [gpxFile setColorColor:color];
            [gpxFile setColoringTypeColoringType:[settings.currentTrackColoringType get].name];
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:fout];
           
            // save to disk
            OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpxFile];
            if (!exception)
            {
                if (![[OAGPXDatabase sharedDb] containsGPXItem:file.absolutePath])
                {
                    [[OAGPXDatabase sharedDb] addGPXFileToDBIfNeeded:file.absolutePath];
                }
                // save to db
                // FIXME: update if exist
               
                
            } else {
                NSLog(@"[ERROR] -> OASavingTrackHelper | save gpx");
            }
        }
        
        [self clearData];
        
        if (completionHandler)
            completionHandler();
    });
}

- (BOOL) saveCurrentTrack:(NSString *)fileName
{
    BOOL __block res = NO;
    dispatch_sync(syncQueue, ^{
        OASKFile *filePathToSaveGPX = [[OASKFile alloc] initWithFilePath:fileName];
        OASKException *exception = [[OASGpxUtilities shared] writeGpxFileFile:filePathToSaveGPX gpxFile:_currentTrack];
        res = !exception;
    });
    
    return res;
}

- (NSDictionary *) collectRecordedData:(BOOL)fillCurrentTrack
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    [self collectDBPoints:data fillCurrentTrack:fillCurrentTrack];
    [self collectDBTracks:data fillCurrentTrack:fillCurrentTrack];

    return [NSDictionary dictionaryWithDictionary:data];
}
    
- (void) collectDBPoints:(NSMutableDictionary *)dataTracks fillCurrentTrack:(BOOL)fillCurrentTrack
{
    dispatch_sync(dbQueue, ^{
 
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];
        
        OASGpxFile *gpx;
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@, %@, %@, %@ FROM %@ ORDER BY %@ ASC", POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_DESCRIPTION, POINT_COL_ICON, POINT_COL_BACKGROUND, POINT_NAME, POINT_COL_DATE];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OASWptPt *wpt = [[OASWptPt alloc] init];
                    
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    
                    wpt.lat = lat;
                    wpt.lon = lon;
                    wpt.time = (long)sqlite3_column_double(statement, 2);
                    
                    if (sqlite3_column_text(statement, 3) != nil)
                    {
                        wpt.name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    }
                    
                    if (sqlite3_column_text(statement, 4) != nil)
                    {
                        OASInt *color = [[OASInt alloc] initWithInt:[[UIColor colorFromString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)]] toARGBNumber]];
                        [wpt setColorColor:color];
                    }
                    if (sqlite3_column_text(statement, 5) != nil)
                    {
                        wpt.category = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
                    }
                    if (sqlite3_column_text(statement, 6) != nil) {
                        wpt.desc = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
                    }
                    if (sqlite3_column_text(statement, 7) != nil) {
                        [wpt setIconNameIconName:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)]];
                    }
                    if (sqlite3_column_text(statement, 8) != nil) {
                        [wpt setBackgroundTypeBackType:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)]];
                    }

                    NSString *date = [fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:wpt.time]];
                    
                    if (fillCurrentTrack) {
                        gpx = _currentTrack;
                    } else {
                        gpx = dataTracks[date];
                    }
                    
                    if (!gpx)
                    {
                        gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
                        [dataTracks setObject:gpx forKey:date];
                    }
                    [gpx addPointPoint:wpt];
                    
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void)collectDBTracks:(NSMutableDictionary *)dataTracks fillCurrentTrack:(BOOL)fillCurrentTrack
{
    dispatch_sync(dbQueue, ^{
        
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@, %@, %@ FROM %@ ORDER BY %@ ASC", TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE, TRACK_COL_HEADING, TRACK_COL_PLUGINS_INFO, TRACK_NAME, TRACK_COL_DATE];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                long previousTime = 0;
                long previousInterval = 0;
                
                OASTrkSegment *segment;
                OASTrack *track;
                OASGpxFile *gpx;

                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OASWptPt *pt = [[OASWptPt alloc] init];
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    pt.lat = lat;
                    pt.lon = lon;
                    pt.ele = sqlite3_column_double(statement, 2);
                    pt.speed = sqlite3_column_double(statement, 3);
                    double hdop = sqlite3_column_double(statement, 4);
                    pt.hdop = hdop == 0 ? NAN : hdop;
                    pt.time = (long)sqlite3_column_double(statement, 5);
                    double heading = sqlite3_column_double(statement, 6);
                    pt.heading = heading == kTrackNoHeading ? NAN : heading;
                    const unsigned char *pluginsInfoChar = sqlite3_column_text(statement, 7);
                    if (pluginsInfoChar != NULL)
                    {
                        NSString *pluginsInfo = [[NSString alloc] initWithUTF8String:(const char *) pluginsInfoChar];
                        if (pluginsInfo && pluginsInfo.length > 0)
                        {
                            NSDictionary<NSString *, NSString *> *extensions = [self getPluginsExtensions:pluginsInfo];
                            [OASGpxUtilities.shared assignExtensionWriterWptPt:pt extensions:extensions];
                        }
                    }

                    long currentInterval = labs(pt.time - previousTime);
                    BOOL newInterval = (lat == 0.0 && lon == 0.0);
                    
                    if (track && !newInterval && (![OAAppSettings sharedManager].autoSplitRecording.get || currentInterval < 6 * 60 || currentInterval < 10 * previousInterval))
                    {
                        // 6 minute - same segment
                        [segment.points addObject:pt];
                        
                    }
                    else if (track && [OAAppSettings sharedManager].autoSplitRecording.get && currentInterval < 2 * 60 * 60)
                    {
                        // 2 hour - same track
                        segment = [[OASTrkSegment alloc] init];
                        segment.points = [NSMutableArray array];

                        if (!newInterval)
                            [segment.points addObject:pt];
                        
                        [track.segments addObject:segment];
                    }
                    else
                    {
                        // check if date the same - new track otherwise new file
                        track = [[OASTrack alloc] init];
                        track.segments = [NSMutableArray array];

                        segment = [[OASTrkSegment alloc] init];
                        segment.points = [NSMutableArray array];
                        
                        NSString *date = [fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:pt.time]];
                        
                        if (fillCurrentTrack)
                            gpx = _currentTrack;
                        else
                            gpx = dataTracks[date];
                        
                        if (!gpx)
                        {
                            gpx = [[OASGpxFile alloc] initWithAuthor:[OAAppVersion getFullVersionWithAppName]];
                            [dataTracks setObject:gpx forKey:date];
                        }
                        [gpx.tracks addObject:track];
                        [track.segments addObject:segment];
                        
                        if (!newInterval)
                            [segment.points addObject:pt];

                    }
                    previousInterval = currentInterval;
                    previousTime = pt.time;
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) startNewSegment
{
    dispatch_sync(syncQueue, ^{
        
        if (lastTimeUpdated != 0 || lastPoint.latitude != 0 || lastPoint.longitude != 0)
        {
            lastTimeUpdated = 0;
            lastPoint = kCLLocationCoordinate2DInvalid;
            long time = (long)[[NSDate date] timeIntervalSince1970];
            [self doUpdateTrackLat:0.0 lon:0.0 alt:0.0 speed:0.0 hdop:0.0 time:time heading:NAN pluginsInfo:nil];
            [self addTrackPointNew:nil newSegment:YES time:time];
        }
    });
}

- (void) updateLocation:(CLLocation *)location heading:(CLLocationDirection)heading
{
    dispatch_sync(syncQueue, ^{
        if (location)
        {
            long locationTime = (long)[location.timestamp timeIntervalSince1970];
            
            BOOL record = NO;
            
            OAAppSettings *settings = [OAAppSettings sharedManager];
            double headingNew = heading;
            if (headingNew != kTrackNoHeading && settings.saveHeadingToGpx.get)
                headingNew = OsmAnd::Utilities::normalizedAngleDegrees(headingNew);
            else
                headingNew = kTrackNoHeading;

            if ([settings.saveTrackToGPX get]
                && locationTime - lastTimeUpdated > [settings.mapSettingSaveTrackInterval get]
                && [[OARoutingHelper sharedInstance] isFollowingMode])
            {
                record = true;
            }
            else if (settings.mapSettingTrackRecording
                     && locationTime - lastTimeUpdated > [settings.mapSettingSaveTrackIntervalGlobal get])
            {
                record = true;
            }
            float minDistance = [settings.saveTrackMinDistance get];
            if(minDistance > 0 && CLLocationCoordinate2DIsValid(lastPoint) && OsmAnd::Utilities::distance(lastPoint.longitude, lastPoint.latitude,
                                                                                   location.coordinate.longitude, location.coordinate.latitude) <
               minDistance) {
                record = false;
            }
            float precision = [settings.saveTrackPrecision get];
            CLLocationAccuracy hdop = location.horizontalAccuracy;
            if(isnan(hdop) || hdop <= 0 || (precision > 0 && hdop > precision))
            {
                record = false;
            }
            float minSpeed = [settings.saveTrackMinSpeed get];
            if(minSpeed > 0 && (location.speed < 0 || location.speed < minSpeed))
            {
                record = NO;
            }
            
            if (record)
            {
                NSString *pluginsInfo = [self getPluginsInfo:location];
                [self insertDataLat:location.coordinate.latitude
                                lon:location.coordinate.longitude
                                alt:location.altitude
                              speed:location.speed
                               hdop:hdop
                               time:[location.timestamp timeIntervalSince1970]
                            heading:headingNew
                        pluginsInfo:pluginsInfo
                ];
                
                [[_app trackRecordingObservable] notifyEvent];
            }
        }
        
    });
}

- (BOOL) getIsRecording
{
    if ([OAPluginsHelper getEnabledPlugin:OAMonitoringPlugin.class])
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if (settings.mapSettingTrackRecording || ([settings.saveTrackToGPX get] && [[OARoutingHelper sharedInstance] isFollowingMode]))
            return YES;
    }
    return NO;
}

- (NSString *)getPluginsInfo:(CLLocation *)location
{
    NSMutableData *json = [NSMutableData data];
    [OAPluginsHelper attachAdditionalInfoToRecordedTrack:location json:json];
    return json.length > 0 ? [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] : nil;
}

- (NSDictionary<NSString *, NSString *> *)getPluginsExtensions:(NSString *)pluginsInfo
{
    if (pluginsInfo && pluginsInfo.length > 0)
    {
        NSError *error;
        NSDictionary<NSString *, NSString *> *jsonDictionary = [NSJSONSerialization JSONObjectWithData:[pluginsInfo dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        return jsonDictionary;
    }
    return @{};
}

- (void) insertDataLat:(double)lat
                   lon:(double)lon
                   alt:(double)alt
                 speed:(double)speed
                  hdop:(double)hdop
                  time:(long)time
               heading:(double)heading
           pluginsInfo:(NSString *)pluginsInfo
{
    [self doUpdateTrackLat:lat lon:lon alt:alt speed:speed hdop:hdop time:time heading:heading pluginsInfo:pluginsInfo];
    
    BOOL newSegment = NO;
    if ((lastPoint.latitude == 0.0 && lastPoint.longitude == 0.0) || (time - lastTimeUpdated) > 180)
    {
        lastPoint = CLLocationCoordinate2DMake(lat, lon);
        newSegment = YES;
    }
    else
    {
        double lastInterval = OsmAnd::Utilities::distance(lon, lat, lastPoint.longitude, lastPoint.latitude);
        distance += lastInterval;
        lastPoint = CLLocationCoordinate2DMake(lat, lon);
    }
    
    lastTimeUpdated = time;

    NSDictionary<NSString *, NSString *> *extensions = [self getPluginsExtensions:pluginsInfo];
    
    OASWptPt *ptNew = [[OASWptPt alloc] initWithLat:lat lon:lon time:time ele:alt speed:speed hdop:hdop heading:heading];
    if (extensions.count > 0)
    {
        [OASGpxUtilities.shared assignExtensionWriterWptPt:ptNew extensions:extensions];
    }
    [self addTrackPointNew:ptNew newSegment:newSegment time:time];
}

- (void)addTrackPointNew:(OASWptPt *)pt newSegment:(BOOL)newSegment time:(long)time {
    OASTrack *track = [_currentTrack tracks].firstObject;
    
    BOOL segmentAdded = NO;
    
    if (track.segments.count == 0 || newSegment)
    {
        OASTrkSegment *segment = [[OASTrkSegment alloc] init];
        segment.points = [NSMutableArray array];
        [track.segments addObject:segment];
        segmentAdded = YES;
    }
    if (pt != nil)
    {
        OASTrkSegment *lt = [track.segments lastObject];
        [lt.points addObject:pt];
    }
    if (segmentAdded)
    {
        [_currentTrack processPoints];
    }
    
    _currentTrack.modifiedTime = time;

}

- (void)addWpt:(OASWptPt *)wpt
{
    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[wpt getColor]]];

    [_currentTrack addPointPoint:wpt];
    _currentTrack.modifiedTime = wpt.time;
    
    points++;

    [self doAddPointsLat:wpt.lat
                     lon:wpt.lon
                    time:wpt.time
                    desc:wpt.desc
                    name:wpt.name
                   color:UIColorFromARGB([wpt getColor]).toHexARGBString
                   group:wpt.category
                    icon:wpt.getIconName
              background:[wpt getBackgroundType]];
}

- (void) doUpdateTrackLat:(double)lat
                      lon:(double)lon
                      alt:(double)alt
                    speed:(double)speed
                     hdop:(double)hdop
                     time:(long)time
                  heading:(double)heading
              pluginsInfo:(NSString *)pluginsInfo
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", TRACK_NAME, TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE, TRACK_COL_HEADING, TRACK_COL_PLUGINS_INFO];
            const char *update_stmt = [query UTF8String];
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);

            int row = 1;
            sqlite3_bind_double(statement, row++, lat);
            sqlite3_bind_double(statement, row++, lon);
            sqlite3_bind_double(statement, row++, alt);
            sqlite3_bind_double(statement, row++, speed);
            sqlite3_bind_double(statement, row++, hdop);
            sqlite3_bind_int64(statement, row++, time);
            sqlite3_bind_double(statement, row++, heading);
            sqlite3_bind_text(statement, row++, (pluginsInfo ? pluginsInfo : @"").UTF8String, -1, SQLITE_TRANSIENT);

            sqlite3_step(statement);
            sqlite3_finalize(statement);

            sqlite3_close(tracksDB);
        }
    });
}

- (void) doAddPointsLat:(double)lat
                    lon:(double)lon
                   time:(long)time
                   desc:(NSString *)desc
                   name:(NSString *)name
                  color:(NSString *)color
                  group:(NSString *)group
                   icon:(NSString *)icon
             background:(NSString *)background
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (%f, %f, %ld, ?, ?, ?, ?, ?, ?)", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_DESCRIPTION, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_ICON, POINT_COL_BACKGROUND, lat, lon, time];

            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [desc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [color UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [icon UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [background UTF8String], -1, SQLITE_TRANSIENT);

            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void)updatePointCoordinates:(OASWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=?, %@=? WHERE %@=? AND %@=? AND %@=? AND %@=? AND %@=? AND %@=? AND %@=?", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DESCRIPTION, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_ICON, POINT_COL_BACKGROUND, POINT_COL_DATE];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_double(statement, 1, newLocation.latitude);
            sqlite3_bind_double(statement, 2, newLocation.longitude);
            sqlite3_bind_text(statement, 3, [(wpt.desc ?: @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [(wpt.name ?: @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [UIColorFromRGBA([wpt getColor]).toHexARGBString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [(wpt.category ?: @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, [wpt.getIconName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, [[wpt getBackgroundType] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(statement, 9, wpt.time);
            
            int res = sqlite3_step(statement);
            if (res != SQLITE_OK && res != SQLITE_DONE)
                NSLog(@"updatePointCoordinates failed: sqlite3_step=%d", res);

            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) doUpdatePointsLat:(double)lat
                       lon:(double)lon
                      time:(long)time
                      desc:(NSString *)desc
                      name:(NSString *)name
                     color:(NSString *)color
                     group:(NSString *)group
                      icon:(NSString *)icon
                background:(NSString *)background
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=?, %@=?, %@=?, %@=? WHERE %@=%f AND %@=%f AND %@=%ld", POINT_NAME, POINT_COL_DESCRIPTION, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_LAT, lat, POINT_COL_LON, lon, POINT_COL_DATE, time];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [(desc ? desc : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [(name ? name : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [(color ? color : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [(group ? group : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [(icon ? icon : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [(background ? background : @"") UTF8String], -1, SQLITE_TRANSIENT);

            int res = sqlite3_step(statement);
            if (res != SQLITE_OK && res != SQLITE_DONE)
                NSLog(@"doUpdatePointsLat failed: sqlite3_step=%d", res);

            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) doDeletePointsLat:(double)lat lon:(double)lon time:(long)time
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%f AND %@=%f AND %@=%ld", POINT_NAME, POINT_COL_LAT, lat, POINT_COL_LON, lon, POINT_COL_DATE, time];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) doDeleteAllPoints
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@", POINT_NAME];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}


- (void)deleteWpt:(OASWptPt *)wpt
{
    [_currentTrack deleteWptPtPoint:wpt];
    
    points--;
    
    [self doDeletePointsLat:wpt.lat lon:wpt.lon time:wpt.time];
}

- (void)deleteAllWpts
{
    [_currentTrack clearPoints];
    
    points = 0;
    
    [self doDeleteAllPoints];
}

- (void)saveWpt:(OASWptPt *)wpt
{
    [self doUpdatePointsLat:wpt.lat
                        lon:wpt.lon
                       time:wpt.time
                       desc:wpt.desc
                       name:wpt.name
                      color:UIColorFromARGB([wpt getColor]).toHexARGBString
                      group:wpt.category
                       icon:[wpt getIconName]
                 background:[wpt getBackgroundType]];
}

- (void) loadGpxFromDatabase
{
    dispatch_sync(syncQueue, ^{
        [_currentTrack clearPoints];
        [[_currentTrack tracks] removeAllObjects];
        [self collectRecordedData:YES];
        [_currentTrack processPoints];
        [self prepareCurrentTrackForRecording];
        
        OASGpxTrackAnalysis *analysisNew = [_currentTrack getAnalysisFileTimestamp:[[NSDate date] timeIntervalSince1970]];
        distance = analysisNew.totalDistance;
        points = analysisNew.wptPoints;
    });
}

- (void) prepareCurrentTrackForRecording
{
    if ([_currentTrack tracks].count == 0)
        [[_currentTrack tracks] addObject:[[OASTrack alloc] init]];
}

- (BOOL) saveIfNeeded
{
    if ([self hasDataToSave] && (distance > 10.0) && ([[NSDate date] timeIntervalSince1970] - [self getLastTrackPointTime] >= 60 * 30))
    {
        [self saveDataToGpx];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) runSyncBlock:(void (^)(void))block
{
    dispatch_sync(syncQueue, ^{
        block();
    });
}

@end
