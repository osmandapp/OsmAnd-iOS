//
//  OATravelLocalDbHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 26/09/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelLocalDbHelper.h"
#import "OsmAndApp.h"

#import <sqlite3.h>

#define kTravlGuidesDbName @"travel_guides.db"

@implementation OATravelLocalDbHelper
{
    NSString *_dbFilePath;
    sqlite3 *_travelGuidesDB;
    dispatch_queue_t dbQueue;
}

static int DB_VERSION = 8;
static NSString *DB_NAME = @"wikivoyage_local_data";
static NSString *HISTORY_TABLE_NAME = @"wikivoyage_search_history";
static NSString *HISTORY_COL_ARTICLE_TITLE = @"article_title";
static NSString *HISTORY_COL_LANG = @"lang";
static NSString *HISTORY_COL_IS_PART_OF = @"is_part_of";
static NSString *HISTORY_COL_LAST_ACCESSED = @"last_accessed";
static NSString *HISTORY_COL_TRAVEL_BOOK = @"travel_book";
static NSString *VERSION_TABLE_NAME = @"version";
static NSString *VERSION_COL = @"version_number";

+ (NSString *) HISTORY_TABLE_CREATE
{
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT, %@ TEXT, %@ TEXT, %@ long, %@ TEXT);", HISTORY_TABLE_NAME, HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_COL_TRAVEL_BOOK];
}

+ (NSString *) HISTORY_TABLE_SELECT
{
    return [NSString stringWithFormat:@"SELECT %@, %@, %@, %@ FROM %@", HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_TABLE_NAME];
}

static NSString *BOOKMARKS_TABLE_NAME = @"wikivoyage_saved_articles";
static NSString *BOOKMARKS_COL_ARTICLE_TITLE = @"article_title";
static NSString *BOOKMARKS_COL_LANG = @"lang";
static NSString *BOOKMARKS_COL_IS_PART_OF = @"is_part_of";
static NSString *BOOKMARKS_COL_IMAGE_TITLE = @"image_title";
static NSString *BOOKMARKS_COL_PARTIAL_CONTENT = @"partial_content";
static NSString *BOOKMARKS_COL_TRAVEL_BOOK = @"travel_book";
static NSString *BOOKMARKS_COL_LAT = @"lat";
static NSString *BOOKMARKS_COL_LON = @"lon";
static NSString *BOOKMARKS_COL_ROUTE_ID = @"route_id";
static NSString *BOOKMARKS_COL_CONTENT_JSON = @"content_json";
static NSString *BOOKMARKS_COL_CONTENT = @"content";
static NSString *BOOKMARKS_COL_LAST_MODIFIED = @"last_modified";
static NSString *BOOKMARKS_COL_GPX_GZ = @"gpx_gz";

+ (NSString *) BOOKMARKS_TABLE_CREATE
{
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ double, %@ double, %@ TEXT, %@ TEXT, %@ TEXT, %@ long, %@ blob);", BOOKMARKS_TABLE_NAME, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_GPX_GZ];
}

+ (NSString *) BOOKMARKS_TABLE_SELECT
{
    return [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@ FROM %@", BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_GPX_GZ, BOOKMARKS_TABLE_NAME];
}


+ (OATravelLocalDbHelper *)sharedDatabase
{
    static OATravelLocalDbHelper *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OATravelLocalDbHelper alloc] init];
    });
    return _sharedDb;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSString *dir = OsmAndApp.instance.travelGuidesPath;
        _dbFilePath = [dir stringByAppendingPathComponent:kTravlGuidesDbName];
        
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        dbQueue = dispatch_queue_create("backup_dbQueue", DISPATCH_QUEUE_SERIAL);
        
        [self load];
    }
    return self;
}

- (void) load
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath:_dbFilePath] == NO)
    {
        [self onCreate];
    }
    else
    {
        int dbVersion = [self readDBVersion];
        if (dbVersion < DB_VERSION)
        {
            [self onUpgrade];
        }
    }
}

- (void) onCreate
{
    dispatch_sync(dbQueue, ^{
        const char *dbpath = [_dbFilePath UTF8String];
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            //create empty History table
            char *errMsg;
            if (sqlite3_exec(_travelGuidesDB, [[self.class HISTORY_TABLE_CREATE] UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
            {
                NSLog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
            }
            if (errMsg != NULL) sqlite3_free(errMsg);
            
            //create empty Bookmarks table
            if (sqlite3_exec(_travelGuidesDB, [[self.class BOOKMARKS_TABLE_CREATE] UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
            {
                NSLog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
            }
            if (errMsg != NULL) sqlite3_free(errMsg);
            
            //create empty db Version table.
            const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ integer)", VERSION_TABLE_NAME, VERSION_COL] UTF8String];
            if (sqlite3_exec(_travelGuidesDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                NSLog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
            }
            if (errMsg != NULL) sqlite3_free(errMsg);

            //add one row with our current database version
            sqlite3_stmt *insertStatement;
            const char *add_stmt = [[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (?)", VERSION_TABLE_NAME, VERSION_COL] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, add_stmt, -1, &insertStatement, NULL);
            sqlite3_bind_int(insertStatement, 1, DB_VERSION);
            sqlite3_step(insertStatement);
            sqlite3_finalize(insertStatement);
            
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void) onUpgrade
{
    //Add database migrating code here
}

//Sqlite library in Objc don't have get/set db version methods like Sqlite lib for Java.
//So we created special table with only one cell for storing version number. And methods.
- (int) readDBVersion
{
    const char *dbpath = [_dbFilePath UTF8String];
    __block int dbVersion = -1;
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *query_stmt = [[NSString stringWithFormat:@"SELECT * FROM %@", VERSION_TABLE_NAME] UTF8String];
            if (sqlite3_prepare_v2(_travelGuidesDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    dbVersion = sqlite3_column_int(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
        }
        sqlite3_close(_travelGuidesDB);
    });
    return dbVersion;
}

- (void) writeDBVersion:(int)versionNumber
{
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            const char *update_stmt = [[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?", VERSION_TABLE_NAME, VERSION_COL] UTF8String];
            sqlite3_stmt *statement;
            sqlite3_prepare_v2(_travelGuidesDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_int(statement, 1, versionNumber);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

@end
