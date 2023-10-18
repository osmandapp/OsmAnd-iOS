//
//  OATravelLocalDataDbHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 26/09/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelLocalDataDbHelper.h"
#import "OsmAndApp.h"
#import "OAGPXDocument.h"
#import "OAArchiveReader.h"
#import "OAArchiveWriter.h"

#import "OsmAnd_Maps-Swift.h"
#import <sqlite3.h>

#define kTravlGuidesDbName @"travel_guides.db"
#define DB_VERSION 8
#define DB_NAME @"wikivoyage_local_data"
#define TEMP_DIR_NAME @"travelguides"
#define TEMP_GPX_FILE_NAME @"gpx_tempfile.gpx"
#define TEMP_GPX_ARCHIVE_NAME @"gpx_archive.gzip"

#define HISTORY_TABLE_NAME @"wikivoyage_search_history"
#define HISTORY_COL_ARTICLE_TITLE @"article_title"
#define HISTORY_COL_LANG @"lang"
#define HISTORY_COL_IS_PART_OF @"is_part_of"
#define HISTORY_COL_LAST_ACCESSED @"last_accessed"
#define HISTORY_COL_TRAVEL_BOOK @"travel_book"
#define VERSION_TABLE_NAME @"version"
#define VERSION_COL @"version_number"

#define BOOKMARKS_TABLE_NAME @"wikivoyage_saved_articles"
#define BOOKMARKS_COL_ARTICLE_TITLE @"article_title"
#define BOOKMARKS_COL_LANG @"lang"
#define BOOKMARKS_COL_IS_PART_OF @"is_part_of"
#define BOOKMARKS_COL_IMAGE_TITLE @"image_title"
#define BOOKMARKS_COL_PARTIAL_CONTENT @"partial_content"
#define BOOKMARKS_COL_TRAVEL_BOOK @"travel_book"
#define BOOKMARKS_COL_LAT @"lat"
#define BOOKMARKS_COL_LON @"lon"
#define BOOKMARKS_COL_ROUTE_ID @"route_id"
#define BOOKMARKS_COL_CONTENT_JSON @"content_json"
#define BOOKMARKS_COL_CONTENT @"content"
#define BOOKMARKS_COL_LAST_MODIFIED @"last_modified"
#define BOOKMARKS_COL_GPX_GZ @"gpx_gz"



@interface OAAddArticleGpxReader : NSObject <OAGpxReadDelegate>

@property (nonatomic) BOOL isGpxReading;

@end

@implementation OAAddArticleGpxReader
{
    sqlite3 *_travelGuidesDB;
    dispatch_queue_t _dbQueue;
    NSString *_tmpDir;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dbQueue = dispatch_queue_create("backup_dbQueue", DISPATCH_QUEUE_SERIAL);
        _tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:TEMP_DIR_NAME];
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:_tmpDir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:_tmpDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (void)onGpxFileReadWithGpxFile:(OAGPXDocumentAdapter * _Nullable)gpxFile article:(OATravelArticle * _Nonnull)article {
    NSString *travelBook = [article getTravelBook];
    if (!travelBook)
        return;

    NSString *tmpFilePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_FILE_NAME];
    NSString *tmpArchivePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_ARCHIVE_NAME];
    
    OAGPXDocument *gpx = (OAGPXDocument *) article.gpxFile.object;
    [gpx saveTo:tmpFilePath];
    NSString *gpxFileContent = [gpx saveToStringWith:article.title];
    
    OAArchiveWriter *helper = [[OAArchiveWriter alloc] init];
    NSData *archivedGpxContent = [helper getArchivedFileContent:gpxFileContent];
    QByteArray gpxBlobData;
    if (archivedGpxContent)
        gpxBlobData = QByteArray::fromNSData(archivedGpxContent);
    
    NSString *dir = OsmAndApp.instance.travelGuidesPath;
    const char *dbpath = [[dir stringByAppendingPathComponent:kTravlGuidesDbName] UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *add_stmt = [[NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", BOOKMARKS_TABLE_NAME, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_GPX_GZ] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, add_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [article.title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [article.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [article.isPartOf UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [article.imageTitle UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [travelBook UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 6, article.lat);
            sqlite3_bind_double(statement, 7, article.lon);
            sqlite3_bind_text(statement, 8, [article.routeId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, [article.contentsJson UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 10, [article.content UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 11, article.lastModified);
            sqlite3_bind_blob(statement, 12, gpxBlobData.constData(), gpxBlobData.size(), SQLITE_STATIC);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void)onGpxFileReading {

}

@end



@interface OARemoveArticleGpxReader : NSObject <OAGpxReadDelegate>

@property (nonatomic) BOOL isGpxReading;

@end

@implementation OARemoveArticleGpxReader
{
    sqlite3 *_travelGuidesDB;
    dispatch_queue_t _dbQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dbQueue = dispatch_queue_create("backup_dbQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)onGpxFileReadWithGpxFile:(OAGPXDocumentAdapter * _Nullable)gpxFile article:(OATravelArticle * _Nonnull)article {
    NSString *travelBook = [article getTravelBook];
    if (!travelBook)
        return;
    
    if (gpxFile != nil && gpxFile.object != nil)
    {
        NSString *name = [OATravelObfHelper.shared getGPXNameWithArticle:article];
        gpxFile.path = [OsmAndApp.instance.gpxTravelPath stringByAppendingPathComponent:name];
        
        //TODO: implement hiding track from map
    }
    
    NSString *dir = OsmAndApp.instance.travelGuidesPath;
    const char *dbpath = [[dir stringByAppendingPathComponent:kTravlGuidesDbName] UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            NSString *langPart = (article.lang != nil) ? [NSString stringWithFormat:@" = '%@'", article.lang] : @" IS NULL";
            const char *del_stmt = [[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@  = ? AND %@ = ? AND %@%@ AND %@ = ?", BOOKMARKS_TABLE_NAME, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_LANG, langPart, BOOKMARKS_COL_TRAVEL_BOOK] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, del_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [article.title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [article.routeId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [travelBook UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void)onGpxFileReading {

}

@end



@interface OAUpdateArticleGpxReader : NSObject <OAGpxReadDelegate>

@property (nonatomic) BOOL isGpxReading;
@property (nonatomic) OATravelArticle *articleOld;
@property (nonatomic) OATravelArticle *articleNew;

@end

@implementation OAUpdateArticleGpxReader
{
    sqlite3 *_travelGuidesDB;
    dispatch_queue_t _dbQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dbQueue = dispatch_queue_create("backup_dbQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)onGpxFileReadWithGpxFile:(OAGPXDocumentAdapter * _Nullable)gpxFile article:(OATravelArticle * _Nonnull)article {
    NSString *travelBook = [article getTravelBook];
    if (!travelBook)
        return;
    
    NSString *dir = OsmAndApp.instance.travelGuidesPath;
    const char *dbpath = [[dir stringByAppendingPathComponent:kTravlGuidesDbName] UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *update_stmt = [[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ? AND %@ = ? %@", BOOKMARKS_TABLE_NAME, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_LANG, BOOKMARKS_COL_TRAVEL_BOOK] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [_articleNew.title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [_articleNew.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [_articleNew.aggregatedPartOf UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [_articleNew.imageTitle UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [[_articleNew getTravelBook] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 6, _articleNew.lat);
            sqlite3_bind_double(statement, 7, _articleNew.lon);
            sqlite3_bind_text(statement, 8, [_articleNew.routeId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 9, [_articleNew.contentsJson UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 10, [_articleNew.content UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 11, _articleNew.lastModified);
            
            sqlite3_bind_text(statement, 12, [_articleOld.title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 13, [_articleOld.routeId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 14, [_articleOld.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 15, [_articleOld.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void)onGpxFileReading {

}

@end



@implementation OATravelLocalDataDbHelper
{
    NSString *_dbFilePath;
    sqlite3 *_travelGuidesDB;
    dispatch_queue_t dbQueue;
    
    NSString *_tmpDir;
    NSString *_tmpFilePath;
    NSString *_tmpArchivePath;
}

+ (NSString *) HISTORY_TABLE_CREATE
{
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT, %@ TEXT, %@ TEXT, %@ long, %@ TEXT);", HISTORY_TABLE_NAME, HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_COL_TRAVEL_BOOK];
}

+ (NSString *) HISTORY_TABLE_SELECT
{
    return [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@ FROM %@", HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_COL_TRAVEL_BOOK, HISTORY_TABLE_NAME];
}

+ (NSString *) BOOKMARKS_TABLE_CREATE
{
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ double, %@ double, %@ TEXT, %@ TEXT, %@ TEXT, %@ long, %@ blob);", BOOKMARKS_TABLE_NAME, BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_GPX_GZ];
}

+ (NSString *) BOOKMARKS_TABLE_SELECT
{
    return [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@ FROM %@", BOOKMARKS_COL_ARTICLE_TITLE, BOOKMARKS_COL_LANG, BOOKMARKS_COL_IS_PART_OF, BOOKMARKS_COL_IMAGE_TITLE, BOOKMARKS_COL_TRAVEL_BOOK, BOOKMARKS_COL_LAT, BOOKMARKS_COL_LON, BOOKMARKS_COL_ROUTE_ID, BOOKMARKS_COL_CONTENT_JSON, BOOKMARKS_COL_CONTENT, BOOKMARKS_COL_LAST_MODIFIED, BOOKMARKS_COL_GPX_GZ, BOOKMARKS_TABLE_NAME];
}


+ (OATravelLocalDataDbHelper *)sharedDatabase
{
    static OATravelLocalDataDbHelper *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OATravelLocalDataDbHelper alloc] init];
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
        
        _tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:TEMP_DIR_NAME];
        _tmpFilePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_FILE_NAME];
        _tmpArchivePath = [_tmpDir stringByAppendingPathComponent:TEMP_GPX_ARCHIVE_NAME];
        isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:_tmpDir isDirectory:&isDir])
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
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (?)", VERSION_TABLE_NAME, VERSION_COL] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL);
            sqlite3_bind_int(statement, 1, DB_VERSION);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
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
            const char *stmt = [[NSString stringWithFormat:@"SELECT * FROM %@", VERSION_TABLE_NAME] UTF8String];
            if (sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL) == SQLITE_OK)
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
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?", VERSION_TABLE_NAME, VERSION_COL] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL);
            sqlite3_bind_int(statement, 1, versionNumber);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (NSDictionary<NSString *, OATravelSearchHistoryItem *> *) getAllHistoryMap
{
    NSMutableDictionary<NSString *, OATravelSearchHistoryItem *> *res = [NSMutableDictionary dictionary];
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[self.class HISTORY_TABLE_SELECT] UTF8String];
            if (sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OATravelSearchHistoryItem *item = [[OATravelSearchHistoryItem alloc] init];
                    item.articleTitle = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    item.lang = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                    item.isPartOf = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
                    item.lastAccessed = sqlite3_column_double(statement, 3);
                    item.articleFile = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
                    res[[item getKey]] = item;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_travelGuidesDB);
        }
    });
    return res;
}

- (void) addHistoryItem:(OATravelSearchHistoryItem *)item
{
    NSString *travelBook = [item getTravelBook];
    if (!travelBook)
        return;
    
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *add_stmt = [[NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?)", HISTORY_TABLE_NAME, HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_COL_TRAVEL_BOOK] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, add_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [item.articleTitle UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [item.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [item.isPartOf UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 4, item.lastAccessed);
            sqlite3_bind_text(statement, 5, [travelBook UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void) updateHistoryItem:(OATravelSearchHistoryItem *)item
{
    NSString *travelBook = [item getTravelBook];
    if (!travelBook)
        return;
    
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ? AND %@ = ?", HISTORY_TABLE_NAME, HISTORY_COL_IS_PART_OF, HISTORY_COL_LAST_ACCESSED, HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_TRAVEL_BOOK] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [item.isPartOf UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 2, item.lastAccessed);
            sqlite3_bind_text(statement, 3, [item.articleTitle UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [item.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [travelBook UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void) removeHistoryItem:(OATravelSearchHistoryItem *)item
{
    NSString *travelBook = [item getTravelBook];
    if (!travelBook)
        return;
    
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ = ? AND %@ = ?", HISTORY_TABLE_NAME, HISTORY_COL_ARTICLE_TITLE, HISTORY_COL_LANG, HISTORY_COL_TRAVEL_BOOK] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [item.articleTitle UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [item.lang UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [travelBook UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}

- (void) clearAllHistory
{
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"DELETE FROM %@", HISTORY_TABLE_NAME] UTF8String];
            sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_travelGuidesDB);
        }
    });
}


- (NSArray<OATravelArticle *> *) readSavedArticles
{
    NSMutableArray<OATravelArticle *> *res = [NSMutableArray array];
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[self.class BOOKMARKS_TABLE_SELECT] UTF8String];
            if (sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OATravelArticle *dbArticle = [[OATravelArticle alloc] init];
                    NSString *lang = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                    if (!lang && lang.length == 0)
                        dbArticle = [[OATravelGpx alloc] init];
                    else
                        dbArticle = [[OATravelArticle alloc] init];
                    
                    dbArticle.title = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    dbArticle.lang = lang;
                    dbArticle.aggregatedPartOf = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
                    dbArticle.imageTitle = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    dbArticle.content = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 9)];
                    dbArticle.lat = sqlite3_column_double(statement, 5);
                    dbArticle.lon = sqlite3_column_double(statement, 6);
                    dbArticle.routeId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];
                    dbArticle.contentsJson = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 8)];
                    NSString *travelBook = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 4)];
                    if (travelBook && travelBook.length > 0)
                    {
                        //res.file = context.getAppPath(IndexConstants.WIKIVOYAGE_INDEX_DIR + travelBook);
                        dbArticle.file = travelBook;
                        dbArticle.lastModified = sqlite3_column_double(statement, 10);
                    }
                     
                    auto blob = QByteArray(
                        static_cast<const char *>(sqlite3_column_blob(statement, 11)),
                        sqlite3_column_bytes(statement, 11));
                    NSData *data = blob.toNSData();
            
                    if (data != nil)
                    {
                        OAArchiveReader *helper = [[OAArchiveReader alloc] init];
                        NSString *gpxContent = [helper getUnarchivedFileContentForData:data];
                        OAGPXDocumentAdapter *adapter = [[OAGPXDocumentAdapter alloc] init];
                        adapter.object = [[OAGPXDocument alloc] initWithGpxFileContent:gpxContent];
                        dbArticle.gpxFile = adapter;
                    }
                
                    OATravelArticle *article = [OATravelObfHelper.shared findSavedArticleWithSavedArticle:dbArticle];
                    if (article && article.lastModified > dbArticle.lastModified)
                    {
                        [self updateSavedArticle:dbArticle newArticle:article];
                        [res addObject:article];
                    }
                    else
                    {
                        [res addObject:dbArticle];
                    }
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_travelGuidesDB);
        }
    });
    return res;
}

- (BOOL) hasSavedArticles
{
    __block int count = 0;
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(dbQueue, ^{
        if (sqlite3_open(dbpath, &_travelGuidesDB) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [[NSString stringWithFormat:@"SELECT COUNT(*) FROM  %@", BOOKMARKS_TABLE_NAME] UTF8String];
            if (sqlite3_prepare_v2(_travelGuidesDB, stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    count = sqlite3_column_int(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
        }
        sqlite3_close(_travelGuidesDB);
    });
    return count > 0;
}

- (void) addSavedArticle:(OATravelArticle *)article
{
    NSString *travelBook = [article getTravelBook];
    if (!travelBook)
        return;
    
    //Write to db in callback
    OAAddArticleGpxReader *gpxReader = [[OAAddArticleGpxReader alloc] init];
    [OATravelObfHelper.shared getArticleByIdWithArticleId:[article generateIdentifier] lang:article.lang readGpx:YES callback:gpxReader];
}

- (void) removeSavedArticle:(OATravelArticle *)article
{
    NSString *travelBook = [article getTravelBook];
    if (!travelBook)
        return;
    
    //Delete in callback
    OARemoveArticleGpxReader *gpxReader = [[OARemoveArticleGpxReader alloc] init];
    [OATravelObfHelper.shared getArticleByIdWithArticleId:[article generateIdentifier] lang:article.lang readGpx:YES callback:gpxReader];
}

- (void) updateSavedArticle:(OATravelArticle *)oldArticle newArticle:(OATravelArticle *)newArticle
{
    NSString *travelBook = [oldArticle getTravelBook];
    if (!travelBook)
        return;

    //Update in callback
    OAUpdateArticleGpxReader *gpxReader = [[OAUpdateArticleGpxReader alloc] init];
    gpxReader.articleOld = oldArticle;
    gpxReader.articleNew = newArticle;
    [OATravelObfHelper.shared getArticleByIdWithArticleId:[oldArticle generateIdentifier] lang:oldArticle.lang readGpx:YES callback:gpxReader];
}

@end
