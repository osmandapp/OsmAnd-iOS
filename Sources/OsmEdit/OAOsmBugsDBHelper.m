//
//  OAOsmBugsDBHelper.m
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBugsDBHelper.h"
#import "OABackupHelper.h"
#import "OALog.h"
#import "OAOsmNotePoint.h"
#import "OAOsmPoint.h"
#import "OsmAnd_Maps-Swift.h"

#import <sqlite3.h>

#define kBugsDbName @"osmNotes.db"

#define DATABASE_VERSION 1
#define OSMBUGS_DB_NAME @"osmbugs"
#define OSMBUGS_TABLE_NAME @"osmbugs"
#define OSMBUGS_COL_ID @"id"
#define OSMBUGS_COL_TEXT @"text"
#define OSMBUGS_COL_LAT @"latitude"
#define OSMBUGS_COL_LON @"longitude"
#define OSMBUGS_COL_ACTION @"action"
#define OSMBUGS_COL_AUTHOR @"author"

#define OSMBUGS_DB_LAST_MODIFIED_NAME @"osmbugs"

@interface OAOsmBugsDBHelper ()

@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAOsmBugsDBHelper
{
    sqlite3 *osmBugsDB;
    dispatch_queue_t dbQueue;
    
    NSArray<OAOsmNotePoint *> *_cache;
}

+ (OAOsmBugsDBHelper *)sharedDatabase
{
    static OAOsmBugsDBHelper *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OAOsmBugsDBHelper alloc] init];
    });
    return _sharedDb;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/OsmEditsData/"];
        self.dbFilePath = [dir stringByAppendingString:kBugsDbName];
        
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        dbQueue = dispatch_queue_create("osmBugs_dbQueue", DISPATCH_QUEUE_SERIAL);
        
        [self load];
    }
    return self;
}

- (void) load
{
    dispatch_sync(dbQueue, ^{
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if ([filemgr fileExistsAtPath:self.dbFilePath] == NO)
        {
            if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ bigint, %@ text, %@ double, %@ double, %@ text, %@ text)",
                                         OSMBUGS_DB_NAME, OSMBUGS_COL_ID,
                                         OSMBUGS_COL_TEXT, OSMBUGS_COL_LAT,
                                         OSMBUGS_COL_LON, OSMBUGS_COL_ACTION,
                                         OSMBUGS_COL_AUTHOR] UTF8String];
                
                if (sqlite3_exec(osmBugsDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sqlite3_close(osmBugsDB);
            }
            else
            {
                // Failed to open/create database
            }
        }
        else
        {
            // Upgrade if needed
            //            if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
            //            else
            // Failed to upate database
        }
    });
}

- (long)getLastModifiedTime
{
    long lastModifiedTime = [BackupUtils getLastModifiedTime:OSMBUGS_DB_LAST_MODIFIED_NAME];
    if (lastModifiedTime == 0)
    {
        lastModifiedTime = [self getDBLastModifiedTime];
        [BackupUtils setLastModifiedTime:OSMBUGS_DB_LAST_MODIFIED_NAME
                        lastModifiedTime:lastModifiedTime];
    }
    return lastModifiedTime;
}

- (void)setLastModifiedTime:(long)lastModified
{
    [BackupUtils setLastModifiedTime:OSMBUGS_DB_LAST_MODIFIED_NAME
                    lastModifiedTime:lastModified];
}

- (void)updateLastModifiedTime
{
    [BackupUtils setLastModifiedTime:OSMBUGS_DB_LAST_MODIFIED_NAME
                    lastModifiedTime:(long) NSDate.now.timeIntervalSince1970];
}

- (long) getDBLastModifiedTime
{
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:_dbFilePath])
    {
        NSError *err = nil;
        NSDictionary *attrs = [manager attributesOfItemAtPath:_dbFilePath error:&err];
        if (!err)
        {
            return attrs.fileModificationDate.timeIntervalSince1970;
        }
    }
    return 0;
}

-(NSArray<OAOsmNotePoint *> *) getOsmBugsPoints
{
    if(!_cache)
        return [self checkOsmBugsPoints];
    return _cache;
}

-(NSArray<OAOsmNotePoint *> *) checkOsmBugsPoints
{
    NSMutableArray<OAOsmNotePoint * > *result = [NSMutableArray new];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [self.dbFilePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@ FROM %@",
                                  OSMBUGS_COL_ID,
                                  OSMBUGS_COL_TEXT, OSMBUGS_COL_LAT,
                                  OSMBUGS_COL_LON, OSMBUGS_COL_ACTION,
                                  OSMBUGS_COL_AUTHOR, OSMBUGS_DB_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(osmBugsDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAOsmNotePoint *p = [[OAOsmNotePoint alloc] init];
                    [p setId:sqlite3_column_int64(statement, 0)];
                    [p setText:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)]];
                    [p setLatitude:sqlite3_column_double(statement, 2)];
                    [p setLongitude:sqlite3_column_double(statement, 3)];
                    [p setActionString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)]];
                    if (sqlite3_column_text(statement, 5))
                        [p setAuthor:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)]];
                    [result addObject:p];
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(osmBugsDB);
        }
    });
    _cache = result;
    return result;
}

-(void) updateOsmBug:(long) identifier text:(NSString *)text
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *updateStmt = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ = ?",
                                    OSMBUGS_TABLE_NAME,
                                    OSMBUGS_COL_TEXT,
                                    OSMBUGS_COL_ID];
            
            const char *update_stmt = [updateStmt UTF8String];
            
            sqlite3_prepare_v2(osmBugsDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [text UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(statement, 2, identifier);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmBugsDB);
            [self updateLastModifiedTime];
        }
    });
    [self checkOsmBugsPoints];
}

- (void) updateOsmBugLocation:(long long)identifier newPosition:(CLLocationCoordinate2D)newPosition
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *updateStmt = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ? WHERE %@ = ?",
                                    OSMBUGS_TABLE_NAME,
                                    OSMBUGS_COL_LAT,
                                    OSMBUGS_COL_LON,
                                    OSMBUGS_COL_ID];
            
            const char *update_stmt = [updateStmt UTF8String];
            
            sqlite3_prepare_v2(osmBugsDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_double(statement, 1, newPosition.latitude);
            sqlite3_bind_double(statement, 2, newPosition.longitude);
            sqlite3_bind_int64(statement, 3, identifier);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmBugsDB);
            [self updateLastModifiedTime];
        }
    });
    [self checkOsmBugsPoints];
}

-(void)addOsmbugs:(OAOsmNotePoint *)point
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *insertStmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?)",
                                    OSMBUGS_DB_NAME, OSMBUGS_COL_ID,
                                    OSMBUGS_COL_TEXT, OSMBUGS_COL_LAT,
                                    OSMBUGS_COL_LON, OSMBUGS_COL_ACTION,
                                    OSMBUGS_COL_AUTHOR];
            
            const char *insert_stmt = [insertStmt UTF8String];
            
            sqlite3_prepare_v2(osmBugsDB, insert_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, [point getId]);
            sqlite3_bind_text(statement, 2, [[point getText] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 3, [point getLatitude]);
            sqlite3_bind_double(statement, 4, [point getLongitude]);
            sqlite3_bind_text(statement, 5, [[point getActionString] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [[point getAuthor] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmBugsDB);
            [self updateLastModifiedTime];
        }
    });
    [self checkOsmBugsPoints];
}

-(void)deleteAllBugModifications:(OAOsmNotePoint *) point
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                                    OSMBUGS_TABLE_NAME,
                                    OSMBUGS_COL_ID];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_prepare_v2(osmBugsDB, delete_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, [point getId]);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmBugsDB);
            [self updateLastModifiedTime];
        }
    });
    [self checkOsmBugsPoints];
}

-(long long) getMinID
{
    __block long long minId = 0;
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmBugsDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT MIN(%@) FROM %@",
                                  OSMBUGS_COL_ID,
                                  OSMBUGS_TABLE_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(osmBugsDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    minId = sqlite3_column_int64(statement, 0);
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(osmBugsDB);
        }
    });
    return minId;
}

@end

