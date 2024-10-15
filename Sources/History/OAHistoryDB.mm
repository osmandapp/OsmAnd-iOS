//
//  OAHistoryDB.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryDB.h"
#import "OABackupHelper.h"
#import "OAPointDescription.h"
#import "OAAppSettings.h"
#import "OAPOIHelper.h"
#import "OAQuickSearchTableController.h"
#import <sqlite3.h>
#import "OALog.h"
#import "NSData+CRC32.h"
#import "OsmAnd_Maps-Swift.h"

#define TABLE_NAME @"history"
#define POINT_COL_HASH @"fhash"
#define POINT_COL_TIME @"ftime"
#define POINT_COL_LAT @"flat"
#define POINT_COL_LON @"flon"
#define POINT_COL_NAME @"fname"
#define POINT_COL_TYPE @"ftype"
#define POINT_COL_ICON_NAME @"ficonname"
#define POINT_COL_TYPE_NAME @"ftypename"
#define POINT_COL_FROM_NAVIGATION @"ffromnavigation"

#define HISTORY_LAST_MODIFIED_NAME @"history_recents"
#define MARKERS_HISTORY_LAST_MODIFIED_NAME @"map_markers_history"

@implementation OAHistoryDB
{
    sqlite3 *historyDB;
    NSString *databasePath;
    dispatch_queue_t dbQueue;
    dispatch_queue_t syncQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        dbQueue = dispatch_queue_create("history_dbQueue", DISPATCH_QUEUE_SERIAL);
        syncQueue = dispatch_queue_create("history_syncQueue", DISPATCH_QUEUE_SERIAL);
        
        [self createDb];
    }
    return self;
}

- (void)createDb
{
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/History"];
    databasePath = [dir stringByAppendingString:@"/history.db"];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    dispatch_sync(dbQueue, ^{
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [databasePath UTF8String];
        
        if ([filemgr fileExistsAtPath: databasePath ] == NO)
        {
            if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ integer, %@ integer, %@ double, %@ double, %@ text, %@ integer, %@ text, %@ text)", TABLE_NAME, POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME] UTF8String];
                
                if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sqlite3_close(historyDB);
            }
            else
            {
                // Failed to open/create database
            }
        }
        else
        {
            // Upgrade if needed
            if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", TABLE_NAME, POINT_COL_ICON_NAME] UTF8String];
                if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //Failed to add column. Already exists;
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ text", TABLE_NAME, POINT_COL_TYPE_NAME] UTF8String];
                if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //Failed to add column. Already exists;
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ integer", TABLE_NAME, POINT_COL_FROM_NAVIGATION] UTF8String];
                if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    //Failed to add column. Already exists;
                }
                if (errMsg != NULL) sqlite3_free(errMsg);

                sqlite3_close(historyDB);
            }
            else
            {
                // Failed to upate database
            }
        }
        
    });
    
}

- (int64_t)getRowHash:(double)latitude longitude:(double)longitude name:(NSString *)name
{
    return ((int64_t)(latitude * 100000)) * 100 +
           ((int64_t)(longitude * 100000)) +
           (int64_t)[[name dataUsingEncoding:NSUTF8StringEncoding] crc32];
}

- (void)addPoint:(OAHistoryItem *)item
{
    int64_t hHash = item.hHash > 0 ? item.hHash : [self getRowHash:item.latitude longitude:item.longitude name:item.name];
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            int64_t hId = 0;
            NSString *querySQL = [NSString stringWithFormat:@"SELECT ROWID FROM %@ WHERE %@ = ? AND %@ = ? ORDER BY %@ DESC LIMIT 1", TABLE_NAME, POINT_COL_HASH, POINT_COL_FROM_NAVIGATION, POINT_COL_TIME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_int64(statement, 1, hHash);
                sqlite3_bind_int(statement, 2, item.fromNavigation ? 1 : 0);

                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    hId = sqlite3_column_int64(statement, 0);
                }
                sqlite3_finalize(statement);
            }

            querySQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@(%@%@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES(%@?, ?, ?, ?, ?, ?, ?, ?, ?)", TABLE_NAME, hId > 0 ? @"ROWID, " : @"", POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, POINT_COL_FROM_NAVIGATION, hId > 0 ? @"?, " : @""];
            query_stmt = [querySQL UTF8String];

            sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL);

            int row = 1;
            if (hId > 0)
                sqlite3_bind_int64(statement, row++, hId);

            NSString *iconName = item.iconName ? item.iconName : @"";
            NSString *typeName = item.typeName ? item.typeName : @"";
            int fromNavigation = item.fromNavigation ? 1 : 0;

            sqlite3_bind_int64(statement, row++, hHash);
            sqlite3_bind_int64(statement, row++, (int64_t) [item.date timeIntervalSince1970]);
            sqlite3_bind_double(statement, row++, item.latitude);
            sqlite3_bind_double(statement, row++, item.longitude);
            sqlite3_bind_text(statement, row++, [item.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, row++, item.hType);
            sqlite3_bind_text(statement, row++, [iconName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, row++, [typeName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, row, fromNavigation);

            sqlite3_step(statement);
            sqlite3_finalize(statement);

            sqlite3_close(historyDB);

            if (item.hType == OAHistoryTypeDirection)
                [self updateMarkersHistoryLastModifiedTime];
            else
                [self updateHistoryLastModifiedTime];
        }
    });
}

- (void)deletePoint:(OAHistoryItem *)item
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt    *statement;
        
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE ROWID=?", TABLE_NAME];
            
            const char *update_stmt = [query UTF8String];
            
            sqlite3_prepare_v2(historyDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, item.hId);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(historyDB);

            if (item.hType == OAHistoryTypeDirection)
                [self updateMarkersHistoryLastModifiedTime];
            else
                [self updateHistoryLastModifiedTime];
        }
    });
}

- (OAHistoryItem *)getPointByName:(NSString *)name fromNavigation:(BOOL)fromNavigation
{
    __block OAHistoryItem *item = nil;

    dispatch_sync(dbQueue, ^{
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            NSMutableString *querySQL = [NSMutableString stringWithString:[NSString stringWithFormat:@"SELECT ROWID, %@, %@, %@, %@, %@, %@, %@ FROM %@ WHERE %@ = %@ AND %@ = %d", POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, TABLE_NAME, POINT_COL_NAME, name, POINT_COL_FROM_NAVIGATION, (fromNavigation ? 1 : 0)]];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    item = [[OAHistoryItem alloc] init];
                    int64_t hId = sqlite3_column_int64(statement, 0);
                    int64_t hHash = sqlite3_column_int64(statement, 1);
                    int64_t time = sqlite3_column_int64(statement, 2);
                    
                    double lat = sqlite3_column_double(statement, 3);
                    double lon = sqlite3_column_double(statement, 4);
                    
                    OAHistoryType type = (OAHistoryType) sqlite3_column_int(statement, 5);

                    NSString *iconName;
                    if (sqlite3_column_text(statement, 6) != nil)
                        iconName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];

                    NSString *typeName;
                    if (sqlite3_column_text(statement, 7) != nil)
                        typeName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];

                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
                    
                    item.hId = hId;
                    item.hHash = hHash;
                    item.date = date;
                    item.latitude = lat;
                    item.longitude = lon;
                    item.name = name;
                    item.hType = type;
                    item.iconName = iconName;
                    item.typeName = typeName;
                    item.fromNavigation = fromNavigation;
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(historyDB);
        }
    });
    
    return item;
}

- (NSArray<OAHistoryItem *> *)getPoints:(NSString *)selectPostfix limit:(int)limit
{
    return [self getPoints:selectPostfix ignoreDisabledResult:NO limit:limit];
}

- (NSArray<OAHistoryItem *> *)getPoints:(NSString *)selectPostfix ignoreDisabledResult:(BOOL)ignoreDisabledResult limit:(int)limit
{
    NSMutableArray *arr = [NSMutableArray array];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            NSMutableString *querySQL = [NSMutableString stringWithString:[NSString stringWithFormat:@"SELECT ROWID, %@, %@, %@, %@, %@, %@, %@, %@, %@ FROM %@", POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, POINT_COL_FROM_NAVIGATION, TABLE_NAME]];
            
            if (selectPostfix)
                [querySQL appendFormat:@" %@", selectPostfix];

            [querySQL appendFormat:@" ORDER BY %@ DESC", POINT_COL_TIME];
            
            if (limit > 0)
                [querySQL appendFormat:@" LIMIT %d", limit];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                OAAppSettings *settings = [OAAppSettings sharedManager];
                OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAHistoryItem *item = [[OAHistoryItem alloc] init];
                    
                    int64_t hId = sqlite3_column_int64(statement, 0);
                    int64_t hHash = sqlite3_column_int64(statement, 1);
                    int64_t time = sqlite3_column_int64(statement, 2);
                    
                    double lat = sqlite3_column_double(statement, 3);
                    double lon = sqlite3_column_double(statement, 4);
                    
                    NSString *name;
                    if (sqlite3_column_text(statement, 5) != nil)
                        name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];

                    OAHistoryType type = (OAHistoryType) sqlite3_column_int(statement, 6);

                    NSString *typeName;
                    if (sqlite3_column_text(statement, 8) != nil)
                        typeName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];

                    NSInteger navigation = sqlite3_column_int(statement, 9);
                    BOOL fromNavigation = navigation == 1 ? YES : NO;

                    BOOL skipDisabledResult = NO;
                    if (!ignoreDisabledResult)
                    {
                        NSSet<NSString *> *disabledPoiTypes = [settings getDisabledTypes];
                        for (NSString *disabledPoiType in disabledPoiTypes)
                        {
                            if ([[poiHelper getPhraseByName:disabledPoiType] isEqualToString:typeName])
                                skipDisabledResult = YES;
                        }
                        if (!skipDisabledResult)
                            skipDisabledResult = type == OAHistoryTypePOI && ![OAPOIHelper findPOIByName:name lat:lat lon:lon];
                    }
                    if (!skipDisabledResult)
                    {
                        NSString *iconName;
                        if (sqlite3_column_text(statement, 7) != nil)
                            iconName = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];

                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];

                        item.hId = hId;
                        item.hHash = hHash;
                        item.date = date;
                        item.latitude = lat;
                        item.longitude = lon;
                        item.name = name;
                        item.hType = type;
                        item.iconName = iconName;
                        item.typeName = typeName;
                        item.fromNavigation = fromNavigation;

                        [arr addObject:item];
                    }
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(historyDB);
        }
    });
    
    return [NSArray arrayWithArray:arr];
}

- (NSArray<OAHistoryItem *> *)getSearchHistoryPoints:(int)count
{
    return [self getPoints:[NSString stringWithFormat:@"WHERE %@ > %d GROUP BY %@ HAVING MAX(%@)", POINT_COL_TYPE, (int)OAHistoryTypeUnknown, POINT_COL_HASH, POINT_COL_TIME] limit:count];
}

- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit
{
    return [self getPointsHavingTypes:types exceptNavigation:YES limit:limit];
}

- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types exceptNavigation:(BOOL)exceptNavigation limit:(int)limit
{
    NSMutableString *arrayStr = [NSMutableString string];
    for (NSNumber *t in types)
    {
        if (arrayStr.length > 0)
            [arrayStr appendString:@","];
        [arrayStr appendFormat:@"%d", [t intValue]];
    }
    NSString *exceptNavigationStr = exceptNavigation ? [NSString stringWithFormat:@" AND %@ = %d", POINT_COL_FROM_NAVIGATION, exceptNavigation ? 0 : 1] : @"";
    return [self getPoints:[NSString stringWithFormat:@"WHERE %@ in (%@)%@", POINT_COL_TYPE, arrayStr, exceptNavigationStr] limit:limit];
}

- (NSInteger)getPointsCountHavingTypes:(NSArray<NSNumber *> *)types
{
    __block NSInteger res;
    dispatch_sync(dbQueue, ^{
        
        NSMutableString *arrayStr = [NSMutableString string];
        for (NSNumber *t in types)
        {
            if (arrayStr.length > 0)
                [arrayStr appendString:@","];
            [arrayStr appendFormat:@"%d", [t intValue]];
        }
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            NSMutableString *querySQL = [NSMutableString stringWithString:[NSString stringWithFormat:@"SELECT count(*) FROM %@ WHERE %@ in (%@)", TABLE_NAME, POINT_COL_TYPE, arrayStr]];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    res = sqlite3_column_int(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(historyDB);
        }
    });
    return res;
}

- (NSArray<OAHistoryItem *> *)getPointsFromNavigation:(int)limit
{
    return [self getPoints:[NSString stringWithFormat:@"WHERE %@ = %d", POINT_COL_FROM_NAVIGATION, 1] limit:limit];
}

- (NSInteger)getPointsCountFromNavigation
{
    __block NSInteger res;
    dispatch_sync(dbQueue, ^{

        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt *statement;

        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            NSMutableString *querySQL = [NSMutableString stringWithString:[NSString stringWithFormat:@"SELECT count(*) FROM %@ WHERE %@ = %d", TABLE_NAME, POINT_COL_FROM_NAVIGATION, 1]];

            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    res = sqlite3_column_int(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(historyDB);
        }
    });
    return res;
}

- (long)getMarkersHistoryLastModifiedTime
{
    return [self getHistoryLastModifiedTime:MARKERS_HISTORY_LAST_MODIFIED_NAME];
}

- (void)setMarkersHistoryLastModifiedTime:(long)lastModified
{
    [BackupUtils setLastModifiedTime:MARKERS_HISTORY_LAST_MODIFIED_NAME
                    lastModifiedTime:lastModified];
}

- (void)updateMarkersHistoryLastModifiedTime
{
    [BackupUtils setLastModifiedTime:MARKERS_HISTORY_LAST_MODIFIED_NAME
                    lastModifiedTime:(long) NSDate.now.timeIntervalSince1970];
}

- (long)getHistoryLastModifiedTime
{
    return [self getHistoryLastModifiedTime:HISTORY_LAST_MODIFIED_NAME];
}

- (void)setHistoryLastModifiedTime:(long)lastModified
{
    [BackupUtils setLastModifiedTime:HISTORY_LAST_MODIFIED_NAME
                    lastModifiedTime:lastModified];
}

- (void)updateHistoryLastModifiedTime
{
    [BackupUtils setLastModifiedTime:HISTORY_LAST_MODIFIED_NAME
                    lastModifiedTime:(long) NSDate.now.timeIntervalSince1970];
}

- (long)getHistoryLastModifiedTime:(NSString *)key
{
    long lastModifiedTime = [BackupUtils getLastModifiedTime:key];
    if (lastModifiedTime == 0)
    {
        lastModifiedTime = [self getDBLastModifiedTime];
        [BackupUtils setLastModifiedTime:key lastModifiedTime:lastModifiedTime];
    }
    return lastModifiedTime;
}

- (long) getDBLastModifiedTime
{
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:databasePath])
    {
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:databasePath error:&err];
        if (!err)
        {
            return attrs.fileModificationDate.timeIntervalSince1970;
        }
    }
    return 0;
}

@end
