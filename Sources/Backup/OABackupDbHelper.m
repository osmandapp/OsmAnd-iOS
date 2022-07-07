//
//  OABackupDbHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 05.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupDbHelper.h"

#import <sqlite3.h>

#define kCloudDbName @"backup_cloud.db"

#define DB_VERSION 1

#define DB_NAME @"backup_files"
#define UPLOADED_FILES_TABLE_NAME @"uploaded_files"
#define UPLOADED_FILE_COL_TYPE @"type"
#define UPLOADED_FILE_COL_NAME @"name"
#define UPLOADED_FILE_COL_UPLOAD_TIME @"upload_time"
#define UPLOADED_FILE_COL_MD5_DIGEST @"md5_digest"
#define UPLOADED_FILES_INDEX_TYPE_NAME @"indexTypeName"
#define LAST_MODIFIED_TABLE_NAME @"last_modified_items"
#define LAST_MODIFIED_COL_NAME @"name"
#define LAST_MODIFIED_COL_MODIFIED_TIME @"last_modified_time"

@implementation OAUploadedFileInfo

- (instancetype) initWithType:(NSString *)type name:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _uploadTime = 0;
        _md5Digest = @"";
    }
    return self;
}

- (instancetype) initWithType:(NSString *)type name:(NSString *)name uploadTime:(long)uploadTime
{
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _uploadTime = uploadTime;
        _md5Digest = @"";
    }
    return self;
}

- (instancetype) initWithType:(NSString *)type name:(NSString *)name md5Digest:(NSString *)md5Digest
{
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _md5Digest = md5Digest;
    }
    return self;
}

- (instancetype) initWithType:(NSString *)type name:(NSString *)name uploadTime:(long)uploadTime md5Digest:(NSString *)md5Digest
{
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _uploadTime = uploadTime;
        _md5Digest = md5Digest;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (!object || ![object isKindOfClass:self.class])
        return NO;
    
    OAUploadedFileInfo *that = (OAUploadedFileInfo *) object;
    return [self.type isEqualToString:that.type] && [self.name isEqualToString:that.name];
}

- (NSUInteger)hash
{
    return self.type.hash + self.name.hash;
}

@end

@implementation OABackupDbHelper
{
    NSString *_dbFilePath;
    
    sqlite3 *backupFilesDB;
    dispatch_queue_t dbQueue;
}

+ (OABackupDbHelper *)sharedDatabase
{
    static OABackupDbHelper *_sharedDb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDb = [[OABackupDbHelper alloc] init];
    });
    return _sharedDb;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/BackupDatabase/"];
        _dbFilePath = [dir stringByAppendingString:kCloudDbName];
        
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
    dispatch_sync(dbQueue, ^{
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        const char *dbpath = [_dbFilePath UTF8String];
        
        if ([filemgr fileExistsAtPath:_dbFilePath] == NO)
        {
            if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text, %@ text, %@ bigint, %@ text)", UPLOADED_FILES_TABLE_NAME, UPLOADED_FILE_COL_TYPE, UPLOADED_FILE_COL_NAME, UPLOADED_FILE_COL_UPLOAD_TIME, UPLOADED_FILE_COL_MD5_DIGEST] UTF8String];
                
                if (sqlite3_exec(backupFilesDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
                
                char *idxErrMsg;
                const char *create_index = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS %@ ON %@ (%@, %@)", UPLOADED_FILES_INDEX_TYPE_NAME, UPLOADED_FILES_TABLE_NAME, UPLOADED_FILE_COL_TYPE, UPLOADED_FILE_COL_NAME].UTF8String;
                if (sqlite3_exec(backupFilesDB, create_index, NULL, NULL, &idxErrMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to create index: %@", [NSString stringWithCString:idxErrMsg encoding:NSUTF8StringEncoding]);
                }
                if (idxErrMsg != NULL) sqlite3_free(idxErrMsg);
                
                char *modifiederrMsg;
                const char *modified_sql_stmt = [[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text, %@ bigint)", LAST_MODIFIED_TABLE_NAME, LAST_MODIFIED_COL_NAME, LAST_MODIFIED_COL_MODIFIED_TIME] UTF8String];
                
                if (sqlite3_exec(backupFilesDB, modified_sql_stmt, NULL, NULL, &modifiederrMsg) != SQLITE_OK)
                {
                    NSLog(@"Failed to create table: %@", [NSString stringWithCString:modifiederrMsg encoding:NSUTF8StringEncoding]);
                }
                if (modifiederrMsg != NULL) sqlite3_free(modifiederrMsg);
                
                sqlite3_close(backupFilesDB);
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

- (void) removeUploadedFileInfo:(OAUploadedFileInfo *)info
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [_dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ = ?",
                                    UPLOADED_FILES_TABLE_NAME,
                                    UPLOADED_FILE_COL_TYPE,
                                    UPLOADED_FILE_COL_NAME];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_prepare_v2(backupFilesDB, delete_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [info.type UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [info.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(backupFilesDB);
        }
    });
}

- (void) removeUploadedFileInfos
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [_dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@",
                                    UPLOADED_FILES_TABLE_NAME];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_prepare_v2(backupFilesDB, delete_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(backupFilesDB);
        }
    });
}

- (void) updateUploadedFileInfo:(OAUploadedFileInfo *)info
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [_dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *updateStmt = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ?",
                                    UPLOADED_FILES_TABLE_NAME,
                                    UPLOADED_FILE_COL_UPLOAD_TIME,
                                    UPLOADED_FILE_COL_MD5_DIGEST,
                                    UPLOADED_FILE_COL_TYPE,
                                    UPLOADED_FILE_COL_NAME];
            
            const char *update_stmt = [updateStmt UTF8String];
            
            sqlite3_prepare_v2(backupFilesDB, update_stmt, -1, &statement, NULL);
            sqlite3_bind_int64(statement, 1, info.uploadTime);
            sqlite3_bind_text(statement, 2, [info.md5Digest UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [info.type UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [info.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(backupFilesDB);
        }
    });
}

- (void) addUploadedFileInfo:(OAUploadedFileInfo *)info
{
    dispatch_async(dbQueue, ^{
        sqlite3_stmt *statement;
        
        const char *dbpath = [_dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *addStmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@) VALUES (?, ?, ?, ?)",
                                    UPLOADED_FILES_TABLE_NAME,
                                    UPLOADED_FILE_COL_TYPE,
                                    UPLOADED_FILE_COL_NAME,
                                    UPLOADED_FILE_COL_UPLOAD_TIME,
                                    UPLOADED_FILE_COL_MD5_DIGEST];
            
            const char *add_stmt = [addStmt UTF8String];
            
            sqlite3_prepare_v2(backupFilesDB, add_stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [info.type UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [info.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(statement, 3, info.uploadTime);
            sqlite3_bind_text(statement, 4, [info.md5Digest UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(backupFilesDB);
        }
    });
}

- (NSDictionary<NSString *, OAUploadedFileInfo *> *) getUploadedFileInfoMap
{
    NSMutableDictionary<NSString *, OAUploadedFileInfo *> *res = [NSMutableDictionary dictionary];
    
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [_dbFilePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@ FROM %@",
                                  UPLOADED_FILE_COL_TYPE,
                                  UPLOADED_FILE_COL_NAME,
                                  UPLOADED_FILE_COL_UPLOAD_TIME,
                                  UPLOADED_FILE_COL_MD5_DIGEST,
                                  UPLOADED_FILES_TABLE_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(backupFilesDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    NSString *type = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    NSString *name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                    long uploadTime = sqlite3_column_int64(statement, 2);
                    NSString *md5Digest = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    OAUploadedFileInfo *info = [[OAUploadedFileInfo alloc] initWithType:type name:name uploadTime:uploadTime md5Digest:md5Digest];
                    res[[NSString stringWithFormat:@"%@___%@", info.type, info.name]] = info;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(backupFilesDB);
        }
    });
    return res;
}

- (OAUploadedFileInfo *) getUploadedFileInfo:(NSString *)type name:(NSString *)name
{
    __block OAUploadedFileInfo *info = nil;
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [_dbFilePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@, %@, %@, %@ FROM %@ WHERE %@ = ? AND %@ = ?",
                                  UPLOADED_FILE_COL_TYPE,
                                  UPLOADED_FILE_COL_NAME,
                                  UPLOADED_FILE_COL_UPLOAD_TIME,
                                  UPLOADED_FILE_COL_MD5_DIGEST,
                                  UPLOADED_FILES_TABLE_NAME,
                                  UPLOADED_FILE_COL_TYPE,
                                  UPLOADED_FILE_COL_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(backupFilesDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_text(statement, 1, [type UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 2, [name UTF8String], -1, SQLITE_TRANSIENT);
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    NSString *type = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    NSString *name = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                    long uploadTime = sqlite3_column_int64(statement, 2);
                    NSString *md5Digest = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
                    info = [[OAUploadedFileInfo alloc] initWithType:type name:name uploadTime:uploadTime md5Digest:md5Digest];
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(backupFilesDB);
        }
    });
    return info;
}

- (void) updateFileUploadTime:(NSString *)type name:(NSString *)name updateTime:(long)updateTime
{
    OAUploadedFileInfo *info = [self getUploadedFileInfo:type name:name];
    if (info)
    {
        info.uploadTime = updateTime;
        [self updateUploadedFileInfo:info];
    }
    else
    {
        info = [[OAUploadedFileInfo alloc] initWithType:type name:name uploadTime:updateTime];
        [self addUploadedFileInfo:info];
    }
}

- (void) updateFileMd5Digest:(NSString *)type name:(NSString *)name md5Digest:(NSString *)md5Digest
{
    OAUploadedFileInfo *info = [self getUploadedFileInfo:type name:name];
    if (info)
    {
        info.md5Digest = md5Digest;
        [self updateUploadedFileInfo:info];
    }
    else
    {
        info = [[OAUploadedFileInfo alloc] initWithType:type name:name md5Digest:md5Digest];
        [self addUploadedFileInfo:info];
    }
}

- (void) setLastModifiedTime:(NSString *)name lastModifiedTime:(long)lastModifiedTime
{
    dispatch_async(dbQueue, ^{
        
        const char *dbpath = [_dbFilePath UTF8String];
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *deleteStmt = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",
                                    LAST_MODIFIED_TABLE_NAME,
                                    LAST_MODIFIED_COL_NAME];
            
            const char *delete_stmt = [deleteStmt UTF8String];
            
            sqlite3_stmt *delStatement;
            sqlite3_prepare_v2(backupFilesDB, delete_stmt, -1, &delStatement, NULL);
            sqlite3_bind_text(delStatement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(delStatement);
            sqlite3_finalize(delStatement);
            
            sqlite3_stmt *insertStatement;
            NSString *addStmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (?, ?)",
                                 LAST_MODIFIED_TABLE_NAME,
                                 LAST_MODIFIED_COL_NAME,
                                 LAST_MODIFIED_COL_MODIFIED_TIME];
            
            const char *add_stmt = [addStmt UTF8String];
            
            sqlite3_prepare_v2(backupFilesDB, add_stmt, -1, &insertStatement, NULL);
            sqlite3_bind_text(insertStatement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(insertStatement, 2, lastModifiedTime);
            sqlite3_step(insertStatement);
            sqlite3_finalize(insertStatement);
            
            sqlite3_close(backupFilesDB);
        }
    });
}

- (long) getLastModifiedTime:(NSString *)name
{
    __block long lastModifiedTime = -1;
    dispatch_sync(dbQueue, ^{
        
        const char *dbpath = [_dbFilePath UTF8String];
        sqlite3_stmt *statement;
        
        if (sqlite3_open(dbpath, &backupFilesDB) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?",
                                  LAST_MODIFIED_COL_MODIFIED_TIME,
                                  LAST_MODIFIED_TABLE_NAME,
                                  LAST_MODIFIED_COL_NAME];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(backupFilesDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    lastModifiedTime = sqlite3_column_int64(statement, 0);
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(backupFilesDB);
        }
    });
    return lastModifiedTime;
}

@end
