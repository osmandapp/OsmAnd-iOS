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
#define POINT_COL_OBJECT_TYPE @"fobjecttype"
#define POINT_COL_CITY_TYPE @"fcitytype"
#define POINT_COL_DISPLAY_NAME @"fdisplayname"
#define POINT_COL_POI_CATEGORY_KEY @"fpoicategorykey"
#define POINT_COL_POI_SUBTYPE_KEY @"fpoisubtypekey"
#define POINT_COL_ADDRESS @"faddress"
#define POINT_COL_RELATED_OBJECT_NAME @"frelatedobjectname"
#define POINT_COL_OPENING_HOURS @"fopeninghours"
#define POINT_COL_ALTERNATE_NAME @"falternatename"
#define POINT_COL_PHOTO_URL @"fphotourl"
#define POINT_COL_OSM_ID @"fosmid"

#define HISTORY_LIMIT 1500

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

- (void)checkError:(int) result
{
    if (result != SQLITE_DONE && result != SQLITE_OK) {
        const char *errorMessage = sqlite3_errmsg(historyDB);
        NSString *errorString = [NSString stringWithUTF8String:errorMessage];
        NSLog(@"SQLite error: %@", errorString);
    }
}

- (void)createDb
{
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/History"];
    databasePath = [dir stringByAppendingString:@"/history.db"];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    dispatch_sync(dbQueue, ^{
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ integer, %@ integer, %@ double, %@ double, %@ text, %@ integer, %@ text, %@ text, %@ integer)", TABLE_NAME, POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, POINT_COL_FROM_NAVIGATION] UTF8String];
            if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                OALog(@"Failed to create table: %@", errMsg ? [NSString stringWithUTF8String:errMsg] : @"");
            }
            if (errMsg != NULL) sqlite3_free(errMsg);

            [self addMissingColumns];

            sql_stmt = [[NSString stringWithFormat:@"UPDATE %@ SET %@ = 0 WHERE %@ IS NULL", TABLE_NAME, POINT_COL_FROM_NAVIGATION, POINT_COL_FROM_NAVIGATION] UTF8String];
            if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                OALog(@"Failed to migrate %@: %@", POINT_COL_FROM_NAVIGATION, errMsg ? [NSString stringWithUTF8String:errMsg] : @"");
            }
            if (errMsg != NULL) sqlite3_free(errMsg);

            sqlite3_close(historyDB);
        }
    });
}

- (void)addMissingColumns
{
    NSMutableSet<NSString *> *existingColumns = [NSMutableSet set];
    sqlite3_stmt *statement;
    const char *query_stmt = [[NSString stringWithFormat:@"PRAGMA table_info(%@)", TABLE_NAME] UTF8String];
    if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSString *column = [self textColumn:statement index:1];
            if (column)
                [existingColumns addObject:column];
        }
        sqlite3_finalize(statement);
    }

    NSDictionary<NSString *, NSString *> *columnTypes = @{
        POINT_COL_ICON_NAME: @"text",
        POINT_COL_TYPE_NAME: @"text",
        POINT_COL_FROM_NAVIGATION: @"integer",
        POINT_COL_OBJECT_TYPE: @"text",
        POINT_COL_CITY_TYPE: @"text",
        POINT_COL_DISPLAY_NAME: @"text",
        POINT_COL_POI_CATEGORY_KEY: @"text",
        POINT_COL_POI_SUBTYPE_KEY: @"text",
        POINT_COL_ADDRESS: @"text",
        POINT_COL_RELATED_OBJECT_NAME: @"text",
        POINT_COL_OPENING_HOURS: @"text",
        POINT_COL_ALTERNATE_NAME: @"text",
        POINT_COL_PHOTO_URL: @"text",
        POINT_COL_OSM_ID: @"integer"
    };
    for (NSString *column in columnTypes)
    {
        if ([existingColumns containsObject:column])
            continue;

        char *errMsg;
        const char *sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", TABLE_NAME, column, columnTypes[column]] UTF8String];
        if (sqlite3_exec(historyDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
        {
            OALog(@"Failed to add column %@: %@", column, errMsg ? [NSString stringWithUTF8String:errMsg] : @"");
        }
        if (errMsg != NULL) sqlite3_free(errMsg);
    }
}

- (NSString *)selectColumns
{
    return [@[@"ROWID", POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, POINT_COL_FROM_NAVIGATION, POINT_COL_OBJECT_TYPE, POINT_COL_CITY_TYPE, POINT_COL_DISPLAY_NAME, POINT_COL_POI_CATEGORY_KEY, POINT_COL_POI_SUBTYPE_KEY, POINT_COL_ADDRESS, POINT_COL_RELATED_OBJECT_NAME, POINT_COL_OPENING_HOURS, POINT_COL_ALTERNATE_NAME, POINT_COL_PHOTO_URL, POINT_COL_OSM_ID] componentsJoinedByString:@", "];
}

- (OAHistoryItem *)readItem:(sqlite3_stmt *)statement
{
    OAHistoryItem *item = [[OAHistoryItem alloc] init];
    int column = 0;
    item.hId = sqlite3_column_int64(statement, column++);
    item.hHash = sqlite3_column_int64(statement, column++);
    item.date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int64(statement, column++)];
    item.latitude = sqlite3_column_double(statement, column++);
    item.longitude = sqlite3_column_double(statement, column++);
    item.name = [self textColumn:statement index:column++];
    item.hType = (OAHistoryType) sqlite3_column_int(statement, column++);
    item.iconName = [self textColumn:statement index:column++];
    item.typeName = [self textColumn:statement index:column++];
    item.fromNavigation = sqlite3_column_int(statement, column++) == 1;
    item.objectType = [self textColumn:statement index:column++];
    item.cityType = [self textColumn:statement index:column++];
    item.displayName = [self textColumn:statement index:column++];
    item.poiCategoryKey = [self textColumn:statement index:column++];
    item.poiSubtypeKey = [self textColumn:statement index:column++];
    item.address = [self textColumn:statement index:column++];
    item.relatedObjectName = [self textColumn:statement index:column++];
    item.openingHours = [self textColumn:statement index:column++];
    item.alternateName = [self textColumn:statement index:column++];
    item.photoUrl = [self textColumn:statement index:column++];
    if (sqlite3_column_type(statement, column) != SQLITE_NULL)
        item.osmId = @(sqlite3_column_int64(statement, column));
    return item;
}

- (NSString *)textColumn:(sqlite3_stmt *)statement index:(int)index
{
    const unsigned char *text = sqlite3_column_text(statement, index);
    return text ? [NSString stringWithUTF8String:(const char *) text] : nil;
}

- (void)bindText:(NSString *)text statement:(sqlite3_stmt *)statement index:(int)index
{
    if (text.length > 0)
        sqlite3_bind_text(statement, index, [text UTF8String], -1, SQLITE_TRANSIENT);
    else
        sqlite3_bind_null(statement, index);
}

- (int64_t)getRowHash:(double)latitude longitude:(double)longitude name:(NSString *)name
{
    return ((int64_t)(latitude * 100000)) * 100 +
           ((int64_t)(longitude * 100000)) +
           (int64_t)[[name dataUsingEncoding:NSUTF8StringEncoding] crc32];
}
- (void)importBackupPoints:(NSArray<OAHistoryItem *> *)items
{
    [self addPoints:items updateLastTime: NO];
}

- (void)addPoint:(OAHistoryItem *)item
{
    [self addPoints: @[item] updateLastTime: YES];
}

- (void)addPoints:(NSArray<OAHistoryItem *> *)items updateLastTime:(BOOL)updateLastTime
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            bool updateMarkers = NO;
            bool updateHistory = NO;
            for (OAHistoryItem * item: items)
            {
                OAHistoryItem *existingItem = nil;
                NSString *querySQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ? ORDER BY %@ DESC LIMIT 1", [self selectColumns], TABLE_NAME, POINT_COL_HASH, POINT_COL_FROM_NAVIGATION, POINT_COL_TIME];
                const char *query_stmt = [querySQL UTF8String];
                int64_t hHash = item.hHash > 0 ? item.hHash : [self getRowHash:item.latitude longitude:item.longitude name:item.name];
                if (item.hType == OAHistoryTypeDirection)
                    updateMarkers = YES;
                else
                    updateHistory = YES;
                
                if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_int64(statement, 1, hHash);
                    sqlite3_bind_int(statement, 2, item.fromNavigation ? 1 : 0);
                    
                    if (sqlite3_step(statement) == SQLITE_ROW)
                        existingItem = [self readItem:statement];
                    sqlite3_finalize(statement);
                }

                int64_t hId = existingItem ? existingItem.hId : 0;
                OAHistoryItem *metadata = [[OAHistoryItem alloc] init];
                [metadata fillMissingMetadataFrom:item];
                if (existingItem)
                    [metadata fillMissingMetadataFrom:existingItem];
                
                querySQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@(%@%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES(%@?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", TABLE_NAME, hId > 0 ? @"ROWID, " : @"", POINT_COL_HASH, POINT_COL_TIME, POINT_COL_LAT, POINT_COL_LON, POINT_COL_NAME, POINT_COL_TYPE, POINT_COL_ICON_NAME, POINT_COL_TYPE_NAME, POINT_COL_FROM_NAVIGATION, POINT_COL_OBJECT_TYPE, POINT_COL_CITY_TYPE, POINT_COL_DISPLAY_NAME, POINT_COL_POI_CATEGORY_KEY, POINT_COL_POI_SUBTYPE_KEY, POINT_COL_ADDRESS, POINT_COL_RELATED_OBJECT_NAME, POINT_COL_OPENING_HOURS, POINT_COL_ALTERNATE_NAME, POINT_COL_PHOTO_URL, POINT_COL_OSM_ID, hId > 0 ? @"?, " : @""];
                query_stmt = [querySQL UTF8String];
                
                sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL);
                
                int row = 1;
                if (hId > 0)
                    sqlite3_bind_int64(statement, row++, hId);
                
                NSString *iconName = item.iconName ?: @"";
                NSString *typeName = metadata.typeName ?: @"";
                int fromNavigation = item.fromNavigation ? 1 : 0;
                
                sqlite3_bind_int64(statement, row++, hHash);
                sqlite3_bind_int64(statement, row++, (int64_t) [item.date timeIntervalSince1970]);
                sqlite3_bind_double(statement, row++, item.latitude);
                sqlite3_bind_double(statement, row++, item.longitude);
                sqlite3_bind_text(statement, row++, [item.name UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(statement, row++, (int)item.hType);
                sqlite3_bind_text(statement, row++, [iconName UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, row++, [typeName UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(statement, row++, fromNavigation);
                [self bindText:metadata.objectType statement:statement index:row++];
                [self bindText:metadata.cityType statement:statement index:row++];
                [self bindText:metadata.displayName statement:statement index:row++];
                [self bindText:metadata.poiCategoryKey statement:statement index:row++];
                [self bindText:metadata.poiSubtypeKey statement:statement index:row++];
                [self bindText:metadata.address statement:statement index:row++];
                [self bindText:metadata.relatedObjectName statement:statement index:row++];
                [self bindText:metadata.openingHours statement:statement index:row++];
                [self bindText:metadata.alternateName statement:statement index:row++];
                [self bindText:metadata.photoUrl statement:statement index:row++];
                if (metadata.osmId)
                    sqlite3_bind_int64(statement, row, metadata.osmId.longLongValue);
                else
                    sqlite3_bind_null(statement, row);
                
                [self checkError:sqlite3_step(statement)];
                
                [self checkError:sqlite3_finalize(statement)];
                
            }
            if (updateHistory)
                [self removeExcessHistoryPoints];
            sqlite3_close(historyDB);
            if (updateLastTime && updateMarkers)
                [self updateMarkersHistoryLastModifiedTime];
            
            if (updateLastTime && updateHistory)
                [self updateHistoryLastModifiedTime];
        }
    });
}

- (void)removeExcessHistoryPoints
{
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE ROWID IN (SELECT ROWID FROM %@ WHERE %@ = 1 OR %@ NOT IN (%d, %d, %d) ORDER BY %@ DESC LIMIT -1 OFFSET %d)", TABLE_NAME, TABLE_NAME, POINT_COL_FROM_NAVIGATION, POINT_COL_TYPE, (int)OAHistoryTypeDirection, (int)OAHistoryTypeParking, (int)OAHistoryTypeRouteWpt, POINT_COL_TIME, HISTORY_LIMIT];
    char *errMsg = NULL;
    if (sqlite3_exec(historyDB, query.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK)
        OALog(@"Failed to remove excess history points: %@", errMsg ? [NSString stringWithUTF8String:errMsg] : @"");
    if (errMsg != NULL)
        sqlite3_free(errMsg);
}

- (void)deletePoint:(OAHistoryItem *)item
{
    [self deletePoints:@[item]];
}

- (void)deletePoints:(NSArray<OAHistoryItem *> *)items
{
    if (items.count == 0)
        return;

    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        const char *dbpath = [databasePath UTF8String];

        if (sqlite3_open(dbpath, &historyDB) == SQLITE_OK)
        {
            bool updateMarkers = NO;
            bool updateHistory = NO;
            NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE ROWID=?", TABLE_NAME];
            const char *delete_stmt = [query UTF8String];

            sqlite3_exec(historyDB, "BEGIN TRANSACTION", NULL, NULL, NULL);
            if (sqlite3_prepare_v2(historyDB, delete_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                for (OAHistoryItem *item in items)
                {
                    sqlite3_bind_int64(statement, 1, item.hId);
                    [self checkError:sqlite3_step(statement)];
                    sqlite3_reset(statement);
                    sqlite3_clear_bindings(statement);

                    if (item.hType == OAHistoryTypeDirection)
                        updateMarkers = YES;
                    else
                        updateHistory = YES;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_exec(historyDB, "COMMIT", NULL, NULL, NULL);

            sqlite3_close(historyDB);
            if (updateMarkers)
                [self updateMarkersHistoryLastModifiedTime];
            if (updateHistory)
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
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ? ORDER BY %@ DESC LIMIT 1", [self selectColumns], TABLE_NAME, POINT_COL_NAME, POINT_COL_FROM_NAVIGATION, POINT_COL_TIME];
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(historyDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(statement, 2, fromNavigation ? 1 : 0);
                if (sqlite3_step(statement) == SQLITE_ROW)
                    item = [self readItem:statement];
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
            NSMutableString *querySQL = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", [self selectColumns], TABLE_NAME];
            
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
                NSMutableSet<NSString *> *disabledPoiTypeNames = [NSMutableSet set];
                if (!ignoreDisabledResult)
                {
                    for (NSString *disabledPoiType in [settings getDisabledTypes])
                    {
                        NSString *disabledPoiTypeName = [poiHelper getPhraseByName:disabledPoiType];
                        if (disabledPoiTypeName.length > 0)
                            [disabledPoiTypeNames addObject:disabledPoiTypeName];
                    }
                }
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAHistoryItem *item = [self readItem:statement];
                    if (ignoreDisabledResult || item.typeName.length == 0 || ![disabledPoiTypeNames containsObject:item.typeName])
                        [arr addObject:item];
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

- (NSArray<OAHistoryItem *> *)pointsHavingSearchTypes:(NSArray<NSNumber *> *)searchTypes fromNavigation:(BOOL)fromNavigation limit:(int)limit
{
    NSMutableArray<NSString *> *conditions = [NSMutableArray array];
    if (searchTypes.count > 0)
        [conditions addObject:[NSString stringWithFormat:@"(%@ = 0 AND %@ IN (%@))", POINT_COL_FROM_NAVIGATION, POINT_COL_TYPE, [searchTypes componentsJoinedByString:@","]]];
    if (fromNavigation)
        [conditions addObject:[NSString stringWithFormat:@"%@ = 1", POINT_COL_FROM_NAVIGATION]];
    if (conditions.count == 0)
        return @[];
    return [self getPoints:[NSString stringWithFormat:@"WHERE %@", [conditions componentsJoinedByString:@" OR "]] limit:limit];
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
                    lastModifiedTime:lastModified / 1000];
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
    return lastModifiedTime * 1000;
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
