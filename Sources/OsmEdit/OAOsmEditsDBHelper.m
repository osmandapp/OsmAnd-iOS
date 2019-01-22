//
//  OAOsmEditsDBHelper.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsDBHelper.h"
#import "OALog.h"
#import <sqlite3.h>

#define kEditsDbName @"osmEdits.db"

#define DATABASE_VERSION 1
#define OPENSTREETMAP_DB_NAME @"openstreetmap"
#define OPENSTREETMAP_TABLE_NAME @"openstreetmaptable"
#define OPENSTREETMAP_COL_ID @"id"
#define OPENSTREETMAP_COL_LAT @"lat"
#define OPENSTREETMAP_COL_LON @"lon"
#define OPENSTREETMAP_COL_TAGS @"tags"
#define OPENSTREETMAP_COL_ACTION @"action"
#define OPENSTREETMAP_COL_COMMENT @"comment"
#define OPENSTREETMAP_COL_CHANGED_TAGS @"changed_tags"
#define OPENSTREETMAP_COL_ENTITY_TYPE @"entity_type"

@interface OAOsmEditsDBHelper ()

@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAOsmEditsDBHelper
{
    sqlite3 *osmEditsDB;
    dispatch_queue_t dbQueue;
}

+ (OAOsmEditsDBHelper *)sharedDatabase
{
    static OAOsmEditsDBHelper *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OAOsmEditsDBHelper alloc] init];
    });
    return _sharedDb;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/OsmEditsData/"];
        self.dbFilePath = [dir stringByAppendingString:kEditsDbName];
        
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        dbQueue = dispatch_queue_create("osmEdits_dbQueue", DISPATCH_QUEUE_SERIAL);
        
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
            if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ bigint, %@ double, %@ double, %@ VARCHAR(2048), %@ text, %@ text, %@ text, %@ text)",
                                         OPENSTREETMAP_TABLE_NAME, OPENSTREETMAP_COL_ID, OPENSTREETMAP_COL_LAT,
                                         OPENSTREETMAP_COL_LON, OPENSTREETMAP_COL_TAGS, OPENSTREETMAP_COL_ACTION,
                                         OPENSTREETMAP_COL_COMMENT, OPENSTREETMAP_COL_CHANGED_TAGS,
                                         OPENSTREETMAP_COL_ENTITY_TYPE] UTF8String];
                
                if (sqlite3_exec(osmEditsDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                sqlite3_close(osmEditsDB);
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

@end
