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

#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

#define DATABASE_NAME @"tracks"
#define DATABASE_VERSION 3

#define TRACK_NAME @"track"
#define TRACK_COL_DATE @"date"
#define TRACK_COL_LAT @"lat"
#define TRACK_COL_LON @"lon"
#define TRACK_COL_ALTITUDE @"altitude"
#define TRACK_COL_SPEED @"speed"
#define TRACK_COL_HDOP @"hdop"

#define POINT_NAME @"point"
#define POINT_COL_DATE @"date"
#define POINT_COL_LAT @"lat"
#define POINT_COL_LON @"lon"
#define POINT_COL_DESCRIPTION @"description"

#define ACCURACY_FOR_GPX_AND_ROUTING 50.0

@implementation OASavingTrackHelper
{
    OsmAndAppInstance _app;

    sqlite3 *tracksDB;
    NSString *databasePath;
    dispatch_queue_t dbQueue;
    dispatch_queue_t syncQueue;
    
    CLLocationCoordinate2D lastPoint;
    
    OAAutoObserverProxy* _locationServicesUpdateObserver;
}

@synthesize lastTimeUpdated, points, isRecording, distance, currentTrack;

+ (OASavingTrackHelper*)sharedInstance
{
    static OASavingTrackHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OASavingTrackHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        syncQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);

        [self createDb];
        
        currentTrack = [[OAGPXMutableDocument alloc] init];

        if (![self saveIfNeeded])
            [self loadGpxFromDatabase];
        
        [self startLocationUpdate];
    }
    return self;
}

- (void)onTrackRecordingChanged
{
    //
}

- (void)startLocationUpdate
{
    if (_locationServicesUpdateObserver)
        return;
    
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateLocation)
                                                                     andObserve:_app.locationServices.updateObserver];
}

- (void)stopLocationUpdate
{
    if (_locationServicesUpdateObserver) {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

- (void)createDb
{
    dbQueue = dispatch_queue_create("dbQueue", DISPATCH_QUEUE_SERIAL);
    
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/TracksDatabase"];
    databasePath = [dir stringByAppendingString:@"/tracks.db"];

    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    dispatch_sync(dbQueue, ^{

        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [databasePath UTF8String];
        
        //[filemgr removeItemAtPath:databasePath error:nil];
        if ([filemgr fileExistsAtPath: databasePath ] == NO)
        {
            if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ double, %@ double, %@ double, %@ double, %@ double, %@ double)", TRACK_NAME, TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE] UTF8String];
                
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ double, %@ double, %@ double, %@ text)", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_DESCRIPTION] UTF8String];
                
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
            /*
            if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
            {
                char *errMsg;
                
                // createTableForTrack
                const char *sql_stmt = "ALTER TABLE assets ADD COLUMN is_exported INTEGER DEFAULT 0";
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //Failed to add column. Already exists;
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                // createTableForPoints
                sql_stmt = "ALTER TABLE assets ADD COLUMN camera_roll_name TEXT";
                if (sqlite3_exec(tracksDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //Failed to add column. Already exists;
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                
                sqlite3_close(tracksDB);
                
            } else {
                // Failed to open/create database
            }
            */
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
    return points > 0 || distance > 0;
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

- (void) saveDataToGpx
{
    dispatch_sync(syncQueue, ^{
        
        NSDictionary *data = [self collectRecordedData:NO];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // save file
        NSString *fout;
        for (NSString *f in data.allKeys)
        {
            fout = [NSString stringWithFormat:@"%@/%@.gpx", _app.gpxPath, f];
            OAGPXMutableDocument *doc = data[f];
            if (![doc isEmpty])
            {
                OAGpxWpt *pt = [doc findPointToShow];
                
                NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
                [simpleFormat setDateFormat:@"HH-mm_EEE"];
                
                NSString *fileName = [NSString stringWithFormat:@"%@_%@", f, [simpleFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:pt.time]]];
                fout = [NSString stringWithFormat:@"%@/%@.gpx", _app.gpxPath, fileName];
                int ind = 1;
                while ([fileManager fileExistsAtPath:fout]) {
                    fout = [NSString stringWithFormat:@"%@/%@_%d.gpx", _app.gpxPath, fileName, ++ind];
                }
            }
            
            [doc saveTo:fout];
            
            OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
            [[OAGPXDatabase sharedDb] addGpxItem:[fout lastPathComponent] title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds analysis:analysis];
            [[OAGPXDatabase sharedDb] save];
        }
        
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
        
        lastTimeUpdated = 0;
        lastPoint = CLLocationCoordinate2DMake(0.0, 0.0);
        
        [currentTrack getDocument]->locationMarks.clear();
        [currentTrack getDocument]->tracks.clear();
        
        [currentTrack.locationMarks removeAllObjects];
        [currentTrack.tracks removeAllObjects];
        currentTrack.modifiedTime = (long)[[NSDate date] timeIntervalSince1970];
        
        [self prepareCurrentTrackForRecording];
        
    });
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
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@ FROM %@ ORDER BY %@ ASC", POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_DESCRIPTION, POINT_NAME, POINT_COL_DATE];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAGpxWpt *wpt = [[OAGpxWpt alloc] init];
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    wpt.position = CLLocationCoordinate2DMake(lat, lon);
                    wpt.time = (long)sqlite3_column_double(statement, 2);
                    if (sqlite3_column_text(statement, 3) != nil)
                        wpt.name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    
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
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@ FROM %@ ORDER BY %@ ASC", TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE, TRACK_NAME, TRACK_COL_DATE];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(tracksDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                long previousTime = 0;
                long previousInterval = 0;

                OAGpxTrkSeg *segment;
                OAGpxTrk *track;
                OAGPXMutableDocument *gpx;

                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] init];
                    double lat = sqlite3_column_double(statement, 0);
                    double lon = sqlite3_column_double(statement, 1);
                    pt.position = CLLocationCoordinate2DMake(lat, lon);
                    pt.elevation = sqlite3_column_double(statement, 2);
                    pt.speed = sqlite3_column_double(statement, 3);
                    pt.horizontalDilutionOfPrecision = sqlite3_column_double(statement, 4);
                    pt.time = (long)sqlite3_column_double(statement, 5);

                    long currentInterval = labs(pt.time - previousTime);
                    BOOL newInterval = (lat == 0.0 && lon == 0.0);
                    
                    if (track && !newInterval && (currentInterval < 6 * 60 || currentInterval < 10 * previousInterval))
                    {
                        // 6 minute - same segment
                        [gpx addTrackPoint:pt segment:segment];
                    }
                    else if (track && currentInterval < 2 * 60 * 60)
                    {
                        // 2 hour - same track
                        segment = [[OAGpxTrkSeg alloc] init];
                        segment.points = [NSMutableArray array];
                        
                        [gpx addTrackSegment:segment track:track];

                        if (!newInterval)
                            [gpx addTrackPoint:pt segment:segment];
                    }
                    else
                    {
                        // check if date the same - new track otherwise new file
                        track = [[OAGpxTrk alloc] init];
                        track.segments = [NSMutableArray array];

                        segment = [[OAGpxTrkSeg alloc] init];
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
            lastPoint = CLLocationCoordinate2DMake(0.0, 0.0);
            long time = (long)[[NSDate date] timeIntervalSince1970];
            [self doUpdateTrackLat:0.0 lon:0.0 alt:0.0 speed:0.0 hdop:0.0 time:time];
            [self addTrackPoint:nil newSegment:YES time:time];
        }
    });
}

- (void) updateLocation
{
    dispatch_async(syncQueue, ^{
        
        CLLocation* location = _app.locationServices.lastKnownLocation;
        long locationTime = (long)[location.timestamp timeIntervalSince1970];
        
        BOOL record = NO;
        isRecording = NO;
        
        if ([self isPointAccurateForRouting:location])
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            
            if (settings.mapSettingTrackRecording
                && locationTime - lastTimeUpdated > settings.mapSettingSaveTrackInterval)
            {
                record = true;
            }
            
            if (settings.mapSettingTrackRecording) {
                isRecording = true;
            }
        }
        
        if (record)
        {
            [self insertDataLat:location.coordinate.latitude lon:location.coordinate.longitude alt:location.altitude speed:location.speed hdop:location.horizontalAccuracy time:(long)[location.timestamp timeIntervalSince1970]];
            
            [[_app trackRecordingObservable] notifyEvent];
        }
        
    });
}

- (void) insertDataLat:(double)lat  lon:(double)lon alt:(double)alt speed:(double)speed hdop:(double)hdop time:(long)time
{
    [self doUpdateTrackLat:lat lon:lon alt:alt speed:speed hdop:hdop time:time];
    
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
    
    OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] init];
    pt.position = CLLocationCoordinate2DMake(lat, lon);
    pt.time = time;
    pt.elevation = alt;
    pt.speed = speed;
    pt.horizontalDilutionOfPrecision = hdop;

    [self addTrackPoint:pt newSegment:newSegment time:time];
}

- (void) addTrackPoint:(OAGpxTrkPt *)pt newSegment:(BOOL)newSegment time:(long)time
{
        OAGpxTrk *track = [currentTrack.tracks firstObject];
        if(track.segments.count == 0 || newSegment)
        {
            OAGpxTrkSeg *segment = [[OAGpxTrkSeg alloc] init];
            segment.points = [NSMutableArray array];
            [currentTrack addTrackSegment:segment track:track];
        }
        if (pt != nil) {
            OAGpxTrkSeg *lt = [track.segments lastObject];
            [currentTrack addTrackPoint:pt segment:lt];
        }
        currentTrack.modifiedTime = time;
    }
    
- (void) insertPointDataLat:(double)lat lon:(double)lon time:(long)time desc:(NSString*)desc
{
    OAGpxWpt *pt = [[OAGpxWpt alloc] init]; // new WptPt(lat, lon, time, Double.NaN, 0, Double.NaN);
    pt.position = CLLocationCoordinate2DMake(lat, lon);
    pt.time = time;
    pt.name = desc;
    
    [currentTrack addWpt:pt];
    currentTrack.modifiedTime = time;
    
    points++;
    
    [self doUpdatePointsLat:lat lon:lon time:time desc:desc];
}

- (void) doUpdateTrackLat:(double)lat lon:(double)lon alt:(double)alt speed:(double)speed hdop:(double)hdop time:(long)time
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@) VALUES (%f, %f, %f, %f, %f, %ld)", TRACK_NAME, TRACK_COL_LAT, TRACK_COL_LON, TRACK_COL_ALTITUDE, TRACK_COL_SPEED, TRACK_COL_HDOP, TRACK_COL_DATE, lat, lon, alt, speed, hdop, time];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) doUpdatePointsLat:(double)lat lon:(double)lon time:(long)time desc:(NSString *)desc
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &tracksDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@) VALUES (%f, %f, %ld, %@)", POINT_NAME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_DATE, POINT_COL_DESCRIPTION, lat, lon, time, desc];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(tracksDB, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(tracksDB);
        }
    });
}

- (void) loadGpxFromDatabase
{
    dispatch_sync(syncQueue, ^{
        
        [currentTrack.locationMarks removeAllObjects];
        [currentTrack.tracks removeAllObjects];
        [self collectRecordedData:YES];
        
        [self prepareCurrentTrackForRecording];
        
        OAGPXTrackAnalysis *analysis = [currentTrack getAnalysis:(long)[[NSDate date] timeIntervalSince1970]];
        distance = analysis.totalDistance;
        points = analysis.wptPoints;
    });
}

- (void) prepareCurrentTrackForRecording
{
    if (currentTrack.tracks.count == 0)
        [currentTrack addTrack:[[OAGpxTrk alloc] init]];
}

- (BOOL) saveIfNeeded
{
    if ([self hasDataToSave] && ([[NSDate date] timeIntervalSince1970] - [self getLastTrackPointTime] >= 60 * 30))
    {
        [self saveDataToGpx];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL) isPointAccurateForRouting:(CLLocation *)loc
{
    return loc != nil && (loc.horizontalAccuracy < ACCURACY_FOR_GPX_AND_ROUTING * 3.0 / 2.0);
}

- (void) runSyncBlock:(void (^)(void))block
{
    dispatch_sync(syncQueue, ^{
        
        block();
        
    });
}

@end
