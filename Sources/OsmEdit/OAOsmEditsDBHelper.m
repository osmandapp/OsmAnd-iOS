//
//  OAOsmEditsDBHelper.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsDBHelper.h"
#import "OABackupHelper.h"
#import "OALog.h"
#import "OAOpenStreetMapPoint.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAWay.h"
#import "OARelation.h"
#import "OAOsmPoint.h"
#import "OsmAnd_Maps-Swift.h"

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

#define OPENSTREETMAP_DB_LAST_MODIFIED_NAME @"openstreetmap"

@interface OAOsmEditsDBHelper ()

@property (nonatomic) NSString *dbFilePath;

@end

@implementation OAOsmEditsDBHelper
{
    sqlite3 *osmEditsDB;
    dispatch_queue_t dbQueue;
    
    NSArray<OAOpenStreetMapPoint *> *_cache;
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

- (long)getLastModifiedTime
{
    long lastModifiedTime = [BackupUtils getLastModifiedTime:OPENSTREETMAP_DB_LAST_MODIFIED_NAME];
    if (lastModifiedTime == 0)
    {
        lastModifiedTime = [self getDBLastModifiedTime];
        [BackupUtils setLastModifiedTime:OPENSTREETMAP_DB_LAST_MODIFIED_NAME
                        lastModifiedTime:lastModifiedTime];
    }
    return lastModifiedTime;
}

- (void) setLastModifiedTime:(long)lastModified
{
    [BackupUtils setLastModifiedTime:OPENSTREETMAP_DB_LAST_MODIFIED_NAME
                    lastModifiedTime:lastModified];
}

- (void)updateLastModifiedTime
{
    [BackupUtils setLastModifiedTime:OPENSTREETMAP_DB_LAST_MODIFIED_NAME
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

-(NSArray<OAOpenStreetMapPoint *> *) getOpenstreetmapPoints
{
    if(!_cache)
        return [self checkOpenstreetmapPoints];
    
    return _cache;
}

-(NSArray<OAOpenStreetMapPoint *> *) checkOpenstreetmapPoints
{
    NSMutableArray<OAOpenStreetMapPoint * > *result = [NSMutableArray new];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [self.dbFilePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@, %@, %@, %@, %@ FROM %@",
                                  OPENSTREETMAP_COL_ID,
                                  OPENSTREETMAP_COL_LAT,
                                  OPENSTREETMAP_COL_LON,
                                  OPENSTREETMAP_COL_ACTION,
                                  OPENSTREETMAP_COL_COMMENT,
                                  OPENSTREETMAP_COL_TAGS,
                                  OPENSTREETMAP_COL_CHANGED_TAGS,
                                  OPENSTREETMAP_COL_ENTITY_TYPE,
                                  OPENSTREETMAP_TABLE_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(osmEditsDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    OAOpenStreetMapPoint *p = [[OAOpenStreetMapPoint alloc] init];
                    NSString *entityType = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];
                    OAEntity *entity = nil;
                    if (entityType && [OAEntity typeFromString:entityType] == NODE)
                    {
                        entity = [[OANode alloc] initWithId:sqlite3_column_int64(statement, 0)
                                                   latitude:sqlite3_column_double(statement, 1) longitude:sqlite3_column_double(statement, 2)];
                        
                    } else if (entityType && [OAEntity typeFromString:entityType] == WAY)
                    {
                        entity = [[OAWay alloc] initWithId:sqlite3_column_int64(statement, 0)
                                                  latitude:sqlite3_column_double(statement, 1) longitude:sqlite3_column_double(statement, 2) ids:[NSArray new]];
                    }
                    if (entity)
                    {
                        NSString *tags = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 5)];
                        NSArray *components = [tags componentsSeparatedByString:@"$$$"];
                        for (int i = 0; (components > 0) && (i < components.count - 1); i += 2) {
                            NSString *key = components[i];
                            NSString *value = components[i + 1];
                            [entity putTagNoLC:[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                         value:[value stringByTrimmingCharactersInSet:
                                                [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                        }
                        NSString *changedTags = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 6)];
                        if (changedTags)
                        {
                            NSArray *matches = [changedTags componentsSeparatedByString:@"$$$"];
                            NSMutableSet *changedTagsSet = [NSMutableSet new];
                            for (NSString *component in matches) {
                                [changedTagsSet addObject:component];
                            }
                            [entity setChangedTags:[NSSet setWithSet:changedTagsSet]];
                        }

                        [p setEntity:entity];
                        [p setActionString:[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)]];
                        [p setComment:[[NSString alloc] initWithUTF8String:sqlite3_column_text(statement, 4) ? (const char *) sqlite3_column_text(statement, 4) : ""]];
                        [result addObject:p];
                    }
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(osmEditsDB);
        }
    });
    _cache = result;
    return result;
}

-(void)addOpenstreetmap:(OAOpenStreetMapPoint *)point
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
        {
            NSMutableString *tags = [NSMutableString new];
            OAEntity *entity = [point getEntity];
            __block NSInteger count = 0;
            NSUInteger size = [[entity getTags] count];
            [[entity getTags] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull val, BOOL * _Nonnull stop) {
                if ([key length] == 0 || [val length] == 0)
                    return;
                [tags appendString:[NSString stringWithFormat:@"%@$$$%@", key, val]];
                if (++count < size)
                    [tags appendString:@"$$$"];
                
            }];
            NSSet<NSString *> *chTags = [[point getEntity] getChangedTags];
            NSMutableString *changedTags = [NSMutableString new];
            if (chTags)
            {
                NSUInteger count = 0;
                for (NSString *str in chTags)
                {
                    [changedTags appendString:str];
                    if (++count < [chTags count])
                        [changedTags appendString:@"$$$"];
                }
            }
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                                    OPENSTREETMAP_TABLE_NAME,
                                    OPENSTREETMAP_COL_ID];
            
            NSString *insertStmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                    OPENSTREETMAP_TABLE_NAME,
                                    OPENSTREETMAP_COL_ID,
                                    OPENSTREETMAP_COL_LAT,
                                    OPENSTREETMAP_COL_LON,
                                    OPENSTREETMAP_COL_TAGS,
                                    OPENSTREETMAP_COL_ACTION,
                                    OPENSTREETMAP_COL_COMMENT,
                                    OPENSTREETMAP_COL_CHANGED_TAGS,
                                    OPENSTREETMAP_COL_ENTITY_TYPE];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_prepare_v2(osmEditsDB, delete_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, [point getId]);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            const char *insert_stmt = [insertStmt UTF8String];
            
            sqlite3_prepare_v2(osmEditsDB, insert_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, [point getId]);
            sqlite3_bind_double(statement, 2, [point getLatitude]);
            sqlite3_bind_double(statement, 3, [point getLongitude]);
            sqlite3_bind_text(statement, 4, [[NSString stringWithString:tags] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [[point getActionString] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [[point getComment] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, !chTags ? nil : [[NSString stringWithString:changedTags] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, [[OAEntity stringTypeOf:entity] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(osmEditsDB);

            [self updateLastModifiedTime];
        }
    });
    [self checkOpenstreetmapPoints];
}

-(void)deletePOI:(OAOpenStreetMapPoint *) point
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
        {
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                                    OPENSTREETMAP_TABLE_NAME,
                                    OPENSTREETMAP_COL_ID];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_prepare_v2(osmEditsDB, delete_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, [point getId]);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmEditsDB);

            [self updateLastModifiedTime];
        }
    });
    [self checkOpenstreetmapPoints];
}

- (void) updateEditLocation:(long long) editId newPosition:(CLLocationCoordinate2D)newPosition
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
        {
            NSString *updateStmt = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ? WHERE %@ = ?",
                                    OPENSTREETMAP_TABLE_NAME,
                                    OPENSTREETMAP_COL_LAT,
                                    OPENSTREETMAP_COL_LON,
                                    OPENSTREETMAP_COL_ID];
            
            const char *update_stmt = [updateStmt UTF8String];
            
            sqlite3_prepare_v2(osmEditsDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_double(statement, 1, newPosition.latitude);
            sqlite3_bind_double(statement, 2, newPosition.longitude);
            sqlite3_bind_int64(statement, 3, editId);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(osmEditsDB);

            [self updateLastModifiedTime];
        }
    });
    [self checkOpenstreetmapPoints];
}

-(long long) getMinID
{
    __block long long minId = -1;
    dispatch_sync(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [self.dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &osmEditsDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT MIN(%@) FROM %@",
                                  OPENSTREETMAP_COL_ID,
                                  OPENSTREETMAP_TABLE_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(osmEditsDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    minId = sqlite3_column_int64(statement, 0);
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(osmEditsDB);
        }
    });
    return minId;
}

- (BOOL)rangeExists:(NSRange)range inString:(NSString *)str
{
    return range.location != NSNotFound && range.location + range.length <= str.length;
}

@end
