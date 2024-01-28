//
//  OASavingTrackHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASavingTrackHelper.h"
#import "OALog.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAAppSettings.h"
#import "OAGPXTrackAnalysis.h"
#import "OACommonTypes.h"
#import "OARoutingHelper.h"
#import "OAMonitoringPlugin.h"
#import "OAPlugin.h"
#import "Localization.h"
#import "OAGPXAppearanceCollection.h"
#import "OAGPXUIHelper.h"
#import "OASaveTrackViewController.h"
#import "OASelectedGPXHelper.h"
#import "OARootViewController.h"

#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>

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

@interface OASavingTrackHelper() <UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate>

@end


@implementation OASavingTrackHelper
{
    OsmAndAppInstance _app;

    sqlite3 *tracksDB;
    NSString *databasePath;
    dispatch_queue_t dbQueue;
    dispatch_queue_t syncQueue;
    
    CLLocationCoordinate2D lastPoint;
    
    NSString *_exportFileName;
    NSString *_exportFilePath;
    OAGPX *_exportingGpx;
    OAGPXDocument *_exportingGpxDoc;
    BOOL _isExportingCurrentTrack;
    UIDocumentInteractionController *_exportController;
    UIViewController *_exportingHostVC;
    id<OATrackSavingHelperUpdatableDelegate> _exportingHostVCDelegate;
}

@synthesize lastTimeUpdated, points, isRecording, distance, currentTrack, currentTrackIndex;

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
    currentTrack = [[OAGPXMutableDocument alloc] init];
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [currentTrack setWidth:[settings.currentTrackWidth get]];
    [currentTrack setShowArrows:[settings.currentTrackShowArrows get]];
    [currentTrack setShowStartFinish:[settings.currentTrackShowStartFinish get]];
    [currentTrack setColor:[settings.currentTrackColor get]];
    [currentTrack setColoringType:[settings.currentTrackColoringType get].name];
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
    [currentTrack initBounds];
    currentTrack.modifiedTime = (long)[[NSDate date] timeIntervalSince1970];
    
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
            fout = [NSString stringWithFormat:@"%@%@%@.gpx", _app.gpxPath, recordedTrackFolder, f];
            OAGPXMutableDocument *doc = data[f];
            if (![doc isEmpty])
            {
                OAWptPt *pt = [doc findPointToShow];
                
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
            NSString *directory = [fout stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:directory])
                [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];

            OAAppSettings *settings = [OAAppSettings sharedManager];
            [doc setWidth:[settings.currentTrackWidth get]];
            [doc setShowArrows:[settings.currentTrackShowArrows get]];
            [doc setShowStartFinish:[settings.currentTrackShowStartFinish get]];
            [doc setColor:[settings.currentTrackColor get]];
            [doc setColoringType:[settings.currentTrackColoringType get].name];

            [doc saveTo:fout];
            
            NSString *gpxFilePath = [OAUtilities getGpxShortPath:fout];
            [[OAGPXDatabase sharedDb] addGpxItem:gpxFilePath title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds document:doc];
            [[OAGPXDatabase sharedDb] save];
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
        res = [currentTrack saveTo:fileName];
    });
    
    return res;
}

- (void)openExportForTrack:(OAGPX *)gpx gpxDoc:(id)gpxDoc isCurrentTrack:(BOOL)isCurrentTrack inViewController:(UIViewController *)hostViewController hostViewControllerDelegate:(id)hostViewControllerDelegate
{
    _isExportingCurrentTrack = isCurrentTrack;
    _exportingHostVC = hostViewController;
    _exportingHostVCDelegate = hostViewControllerDelegate;
    _exportingGpx = gpx;
    _exportingGpxDoc = gpxDoc;
    if (isCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];

        _exportFileName = [NSString stringWithFormat:@"%@_%@",
                                                     [fmt stringFromDate:[NSDate date]],
                                                     [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx",
                                                     NSTemporaryDirectory(),
                                                     _exportFileName];

        [self saveCurrentTrack:_exportFilePath];
        _exportingGpxDoc = currentTrack;
        _exportingGpx = [self getCurrentGPX];
    }
    else
    {
        _exportFileName = gpx.gpxFileName;
        _exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:gpx.gpxFileName];
        if (!_exportingGpxDoc || ![_exportingGpxDoc isKindOfClass:OAGPXDocument.class])
        {
            NSString *absoluteGpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:_exportFileName];
            _exportingGpxDoc = [[OAGPXDocument alloc] initWithGpxFile:absoluteGpxFilepath];
        }
        else
        {
            _exportingGpxDoc = gpxDoc;
        }
        [OAGPXUIHelper addAppearanceToGpx:_exportingGpxDoc gpxItem:_exportingGpx];
        [_exportingGpxDoc saveTo:_exportFilePath];
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero inView:_exportingHostVC.view animated:YES];
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
        
        OAGPXMutableDocument *gpx;
        
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
                    OAWptPt *wpt = [[OAWptPt alloc] init];
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    wpt.position = CLLocationCoordinate2DMake(lat, lon);
                    wpt.time = (long)sqlite3_column_double(statement, 2);
                    if (sqlite3_column_text(statement, 3) != nil)
                        wpt.name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    
                    if (sqlite3_column_text(statement, 4) != nil)
                        [wpt setColor:[[UIColor colorFromString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)]] toARGBNumber]];
                    if (sqlite3_column_text(statement, 5) != nil)
                        wpt.type = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
                    if (sqlite3_column_text(statement, 6) != nil)
                        wpt.desc = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
                    if (sqlite3_column_text(statement, 7) != nil)
                        [wpt setIcon:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)]];
                    if (sqlite3_column_text(statement, 8) != nil)
                        [wpt setBackgroundIcon:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)]];

                    NSString *date = [fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:wpt.time]];
                    
                    if (fillCurrentTrack)
                        gpx = currentTrack;
                    else
                        gpx = dataTracks[date];
                    
                    if (!gpx)
                    {
                        gpx  = [[OAGPXMutableDocument alloc] init];
                        [dataTracks setObject:gpx forKey:date];
                    }
                    [gpx addWpt:wpt];
                    
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) collectDBTracks:(NSMutableDictionary *)dataTracks fillCurrentTrack:(BOOL)fillCurrentTrack
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

                OATrkSegment *segment;
                OATrack *track;
                OAGPXMutableDocument *gpx;

                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAWptPt *pt = [[OAWptPt alloc] init];
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    pt.position = CLLocationCoordinate2DMake(lat, lon);
                    pt.elevation = sqlite3_column_double(statement, 2);
                    pt.speed = sqlite3_column_double(statement, 3);
                    double hdop = sqlite3_column_double(statement, 4);
                    pt.horizontalDilutionOfPrecision = hdop == 0 ? NAN : hdop;
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
                            [self addPluginsExtensions:extensions toPoint:pt];
                        }
                    }

                    long currentInterval = labs(pt.time - previousTime);
                    BOOL newInterval = (lat == 0.0 && lon == 0.0);
                    
                    if (track && !newInterval && (![OAAppSettings sharedManager].autoSplitRecording.get || currentInterval < 6 * 60 || currentInterval < 10 * previousInterval))
                    {
                        // 6 minute - same segment
                        [gpx addTrackPoint:pt segment:segment];
                    }
                    else if (track && [OAAppSettings sharedManager].autoSplitRecording.get && currentInterval < 2 * 60 * 60)
                    {
                        // 2 hour - same track
                        segment = [[OATrkSegment alloc] init];
                        segment.points = [NSMutableArray array];
                        
                        [gpx addTrackSegment:segment track:track];

                        if (!newInterval)
                            [gpx addTrackPoint:pt segment:segment];
                    }
                    else
                    {
                        // check if date the same - new track otherwise new file
                        track = [[OATrack alloc] init];
                        track.segments = [NSMutableArray array];

                        segment = [[OATrkSegment alloc] init];
                        segment.points = [NSMutableArray array];
                        
                        NSString *date = [fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:pt.time]];
                        
                        if (fillCurrentTrack)
                            gpx = currentTrack;
                        else
                            gpx = dataTracks[date];
                        
                        if (!gpx)
                        {
                            gpx  = [[OAGPXMutableDocument alloc] init];
                            [dataTracks setObject:gpx forKey:date];
                        }
                        [gpx addTrack:track];
                        [gpx addTrackSegment:segment track:track];
                        
                        if (!newInterval)
                            [gpx addTrackPoint:pt segment:segment];

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
            [self addTrackPoint:nil newSegment:YES time:time];
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
    if ([OAPlugin getEnabledPlugin:OAMonitoringPlugin.class])
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
    [OAPlugin attachAdditionalInfoToRecordedTrack:location json:json];
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

- (void)addPluginsExtensions:(NSDictionary<NSString *, NSString *> *)extensions toPoint:(OAWptPt *)point
{
    if (extensions && extensions.count > 0)
    {
        OAGpxExtension *trackPointExtension = [[OAGpxExtension alloc] init];
        trackPointExtension.prefix = @"gpxtpx";
        trackPointExtension.name = @"TrackPointExtension";
        NSMutableArray<OAGpxExtension *> *subextensions = [NSMutableArray array];
        for (NSString *key in extensions.allKeys)
        {
            OAGpxExtension *subextension = [[OAGpxExtension alloc] init];
            subextension.prefix = @"gpxtpx";
            subextension.name = key;
            subextension.value = extensions[key];
            [subextensions addObject:subextension];
        }
        [trackPointExtension setSubextensions:subextensions];
        [point addExtension:trackPointExtension];
    }
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
    
    OAWptPt *pt = [[OAWptPt alloc] init];
    pt.position = CLLocationCoordinate2DMake(lat, lon);
    pt.time = time;
    pt.elevation = alt;
    pt.speed = speed;
    pt.horizontalDilutionOfPrecision = hdop;
    pt.heading = heading;

    NSDictionary<NSString *, NSString *> *extensions = [self getPluginsExtensions:pluginsInfo];
    [self addPluginsExtensions:extensions toPoint:pt];

    [self addTrackPoint:pt newSegment:newSegment time:time];
}

- (void) addTrackPoint:(OAWptPt *)pt newSegment:(BOOL)newSegment time:(long)time
{
    OATrack *track = [currentTrack.tracks firstObject];
    BOOL segmentAdded = NO;
    if (track.segments.count == 0 || newSegment)
    {
        OATrkSegment *segment = [[OATrkSegment alloc] init];
        segment.points = [NSMutableArray array];
        [currentTrack addTrackSegment:segment track:track];
        segmentAdded = YES;
    }
    if (pt != nil)
    {
        OATrkSegment *lt = [track.segments lastObject];
        [currentTrack addTrackPoint:pt segment:lt];
    }
    if (segmentAdded)
        [currentTrack processPoints];
    currentTrack.modifiedTime = time;
}
    
- (void)addWpt:(OAWptPt *)wpt
{
    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    [appearanceCollection selectColor:[appearanceCollection getColorItemWithValue:[wpt getColor:0]]];

    [currentTrack addWpt:wpt];
    currentTrack.modifiedTime = wpt.time;
    
    points++;

    [self doAddPointsLat:wpt.position.latitude
                     lon:wpt.position.longitude
                    time:wpt.time
                    desc:wpt.desc
                    name:wpt.name
                   color:UIColorFromARGB([wpt getColor:0]).toHexARGBString
                   group:wpt.type
                    icon:[wpt getIcon]
              background:[wpt getBackgroundIcon]];
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

- (void) updatePointCoordinates:(OAWptPt *)wpt newLocation:(CLLocationCoordinate2D)newLocation
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=?, %@=? WHERE %@=? AND %@=? AND %@=? AND %@=? AND %@=? AND %@=? AND %@=?", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DESCRIPTION, POINT_COL_NAME, POINT_COL_COLOR, POINT_COL_CATEGORY, POINT_COL_ICON, POINT_COL_BACKGROUND, POINT_COL_DATE];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_double(statement, 1, newLocation.latitude);
            sqlite3_bind_double(statement, 2, newLocation.longitude);
            sqlite3_bind_text(statement, 3, [(wpt.desc ? wpt.desc : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [(wpt.name ? wpt.name : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [UIColorFromRGBA([wpt getColor:0]).toHexARGBString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [(wpt.type ? wpt.type : @"") UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, [[wpt getIcon] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, [[wpt getBackgroundIcon] UTF8String], -1, SQLITE_TRANSIENT);
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

- (void)deleteWpt:(OAWptPt *)wpt
{
    [currentTrack deleteWpt:wpt];
    
    points--;
    
    [self doDeletePointsLat:wpt.position.latitude lon:wpt.position.longitude time:wpt.time];
}

- (void)deleteAllWpts
{
    [currentTrack deleteAllWpts];
    
    points = 0;
    
    [self doDeleteAllPoints];
}

- (void)saveWpt:(OAWptPt *)wpt
{
    [self doUpdatePointsLat:wpt.position.latitude
                        lon:wpt.position.longitude
                       time:wpt.time
                       desc:wpt.desc
                       name:wpt.name
                      color:UIColorFromARGB([wpt getColor:0]).toHexARGBString
                      group:wpt.type
                       icon:[wpt getIcon]
                 background:[wpt getBackgroundIcon]];
}

- (void) loadGpxFromDatabase
{
    dispatch_sync(syncQueue, ^{
        
        [currentTrack.points removeAllObjects];
        [currentTrack.tracks removeAllObjects];
        [self collectRecordedData:YES];
        [currentTrack applyBounds];

        [currentTrack processPoints];
        [self prepareCurrentTrackForRecording];
        
        OAGPXTrackAnalysis *analysis = [currentTrack getAnalysis:(long)[[NSDate date] timeIntervalSince1970]];
        distance = analysis.totalDistance;
        points = analysis.wptPoints;
    });
}

- (void) prepareCurrentTrackForRecording
{
    if (currentTrack.tracks.count == 0)
        [currentTrack addTrack:[[OATrack alloc] init]];
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

- (OAGPX *)getCurrentGPX
{
    [currentTrack applyBounds];
    return [[OAGPXDatabase sharedDb] buildGpxItem:OALocalizedString(@"shared_string_currently_recording_track") title:currentTrack.metadata.name desc:currentTrack.metadata.desc bounds:currentTrack.bounds document:currentTrack];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OAGPX *)gpx
{
    NSString *gpxFilepath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:gpxFilepath];
    if (doc)
    {
        [self copyGPXToNewFolder:newFolderName renameToNewName:newFileName deleteOriginalFile:deleteOriginalFile openTrack:openTrack gpx:gpx doc:doc];
    }
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
                       gpx:(OAGPX *)gpx
                       doc:(OAGPXDocument *)doc
{
    NSString *oldPath = gpx.gpxFilePath;
    NSString *sourcePath = [_app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [_app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = gpx.gpxFileName;

    if (newFileName)
    {
        if ([[NSFileManager defaultManager]
                fileExistsAtPath:[newFolderPath stringByAppendingPathComponent:newFileName]])
            newName = [OAUtilities createNewFileName:newFileName];
        else
            newName = newFileName;
    }

    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [gpx updateFolderName:newStoringPath];
        doc.path = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXMutableDocument *gpxDoc = [[OAGPXMutableDocument alloc] initWithGpxFile:sourcePath];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                          title:newName
                           desc:gpxDoc.metadata.desc
                         bounds:gpxDoc.bounds
                       document:gpxDoc];

        
        if ([OAAppSettings.sharedManager.mapSettingVisibleGpx.get containsObject:oldPath])
            [OAAppSettings.sharedManager showGpx:@[newStoringPath]];
    }
    if (openTrack)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[newFolderName stringByAppendingPathComponent:newFileName]];
        if (gpx)
        {
            
            [_exportingHostVC dismissViewControllerAnimated:YES completion:^{
                [OARootViewController.instance.mapPanel targetHideContextPinMarker];
                [OARootViewController.instance.mapPanel openTargetViewWithGPX:gpx];
            }];
        }
    }
}

- (void)renameTrack:(OAGPX *)gpx newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    NSString *docPath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] initWithGpxFile:docPath];
    [self renameTrack:gpx doc:doc newName:newName hostVC:hostVC];
}

- (void)renameTrack:(OAGPX *)gpx doc:(OAGPXMutableDocument *)doc newName:(NSString *)newName hostVC:(UIViewController*)hostVC
{
    if (newName.length > 0)
    {
        NSString *oldFilePath = gpx.gpxFilePath;
        NSString *oldPath = [_app.gpxPath stringByAppendingPathComponent:oldFilePath];
        NSString *newFileName = [newName stringByAppendingPathExtension:@"gpx"];
        NSString *newFilePath = [[gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        NSString *newPath = [_app.gpxPath stringByAppendingPathComponent:newFilePath];
        if (![NSFileManager.defaultManager fileExistsAtPath:newPath])
        {
            gpx.gpxTitle = newName;
            gpx.gpxFileName = newFileName;
            gpx.gpxFilePath = newFilePath;
            [[OAGPXDatabase sharedDb] save];

            OAMetadata *metadata;
            if (doc.metadata)
            {
                metadata = doc.metadata;
            }
            else
            {
                metadata = [[OAMetadata alloc] init];
                long time = 0;
                if (doc.points.count > 0)
                    time = doc.points[0].time;
                if (doc.tracks.count > 0)
                {
                    OATrack *track = doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OATrkSegment *seg = track.segments[0];
                        if (seg.points.count > 0)
                         {
                            OAWptPt *p = seg.points[0];
                            if (time > p.time)
                                time = p.time;
                        }
                    }
                }
                metadata.time = time == 0 ? (long) [[NSDate date] timeIntervalSince1970] : time;
            }
            metadata.name = newFileName;

            if ([NSFileManager.defaultManager fileExistsAtPath:oldPath])
                [NSFileManager.defaultManager removeItemAtPath:oldPath error:nil];

            BOOL saveFailed = ![OARootViewController.instance.mapPanel.mapViewController updateMetadata:metadata oldPath:oldPath docPath:newPath];
            doc.path = newPath;
            doc.metadata = metadata;

            if (saveFailed)
                [doc saveTo:newPath];

            [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:newFilePath];
        }
        else
        {
            [self showAlertWithText:OALocalizedString(@"gpx_already_exsists") inViewController:hostVC];
        }
    }
    else
    {
        [self showAlertWithText:OALocalizedString(@"empty_filename") inViewController:hostVC];
    }
}

- (void) onCloseShareMenu
{
    _exportFileName = nil;
    _exportFilePath = nil;
    _exportingGpx = nil;
    _exportingGpxDoc = nil;
    _exportingHostVC = nil;
    _exportController = nil;
    if (_exportingHostVCDelegate)
    {
        [_exportingHostVCDelegate onNeedUpdateHostData];
        _exportingHostVCDelegate = nil;
    }
}

- (void)showAlertWithText:(NSString *)text inViewController:(UIViewController *)viewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:text
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [viewController presentViewController:alert animated:YES completion:nil];
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if (_isExportingCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:@"net.osmand.maps"])
    {
        [_exportController dismissMenuAnimated:YES];
        _exportFilePath = nil;
        _exportController = nil;

        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:_exportFileName
                        filePath:_exportFilePath
                       showOnMap:YES
                 simplifiedTrack:YES
                       duplicate:NO];

        saveTrackViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:saveTrackViewController];
        [_exportingHostVC presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self onCloseShareMenu];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName
               showOnMap:(BOOL)showOnMap
         simplifiedTrack:(BOOL)simplifiedTrack
               openTrack:(BOOL)openTrack
{
    [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
             renameToNewName:[fileName.lastPathComponent stringByAppendingPathExtension:@"gpx"] 
          deleteOriginalFile:NO
                   openTrack:YES
                         gpx:_exportingGpx
                         doc:_exportingGpxDoc];
    [self onCloseShareMenu];
}

@end
