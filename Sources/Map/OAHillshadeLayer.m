//
//  OAHillshadeLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHillshadeLayer.h"
#import "QuadTree.h"
#import "QuadRect.h"
#import <sqlite3.h>
#import "OALog.h"
#import "OASQLiteTileSource.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"

const static int ZOOM_BOUNDARY = 15;

@implementation OAHillshadeLayer
{
    NSObject *_sync;
    
    NSDictionary *_resources;
    QuadTree *_indexedResources;
    NSString *_databasePath;
    NSString *_tilesDir;
    
    OAAutoObserverProxy* _hillshadeChangeObserver;
}

+ (OAHillshadeLayer *)sharedInstance
{
    static dispatch_once_t once;
    static OAHillshadeLayer * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _sync = [[NSObject alloc] init];
        
        _hillshadeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onHillshadeResourcesChanged)
                                                              andObserve:[OsmAndApp instance].data.hillshadeResourcesChangeObservable];

        _indexedResources = [[QuadTree alloc] initWithQuadRect:[[QuadRect alloc] initWithLeft:0 top:0 right:1 << (ZOOM_BOUNDARY+1) bottom:1 << (ZOOM_BOUNDARY+1)] depth:8 ratio:0.55f];

        _tilesDir = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources"];
        
        NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/HillshadeDatabase"];
        _databasePath = [dir stringByAppendingString:@"/hillshade.cache"];
        
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];

        [self indexHillshadeFiles];
    }
    return self;
}

- (void)onHillshadeResourcesChanged
{
    [self indexHillshadeFiles];
    [[OsmAndApp instance].data.hillshadeChangeObservable notifyEvent];
}

- (void)indexHillshadeFiles
{
    @synchronized(_sync)
    {
        sqlite3 *db;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: _databasePath ] == NO)
        {
            if (sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
            {
                char *errMsg;
                const char *sql_stmt = "CREATE TABLE IF NOT EXISTS TILE_SOURCES(filename text, date_modified int, left int, right int, top int, bottom int)";
                
                if (sqlite3_exec(db, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                {
                    OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
                }
                if (errMsg != NULL) sqlite3_free(errMsg);
            }
        }
        
        NSMutableDictionary *fileModified = [NSMutableDictionary dictionary];
        NSMutableDictionary *rs = [self readFiles:fileModified];
        [self indexCachedResources:fileModified rs:rs];
        [self indexNonCachedResources:fileModified rs:rs];
        _resources = [NSDictionary dictionaryWithDictionary:rs];
    }
}

- (void)indexNonCachedResources:(NSMutableDictionary *)fileModified rs:(NSMutableDictionary *)rs
{
    for (NSString *filename in fileModified.allKeys)
    {
        OALog(@"Indexing hillshade file %@", filename);
        @try
        {
            OASQLiteTileSource *ts = [rs objectForKey:filename];
            QuadRect *rt = [ts getRectBoundary:ZOOM_BOUNDARY minZ:1];
            if (rt)
            {
                [_indexedResources insert:filename box:rt];
                
                sqlite3 *db;
                sqlite3_stmt    *statement;
                
                const char *dbpath = [_databasePath UTF8String];
                
                if (sqlite3_open(dbpath, &db) == SQLITE_OK)
                {
                    NSString *query = @"INSERT INTO TILE_SOURCES (filename, date_modified, left, right, top, bottom) VALUES (?, ?, ?, ?, ?, ?)";
                    
                    const char *update_stmt = [query UTF8String];
                    
                    sqlite3_prepare_v2(db, update_stmt, -1, &statement, NULL);
                    sqlite3_bind_text(statement, 1, [filename UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(statement, 2, [[fileModified objectForKey:filename] intValue]);
                    sqlite3_bind_int(statement, 3, (int)rt.left);
                    sqlite3_bind_int(statement, 4, (int) rt.right);
                    sqlite3_bind_int(statement, 5, (int)rt.top);
                    sqlite3_bind_int(statement, 6, (int) rt.bottom);
                    
                    sqlite3_step(statement);
                    sqlite3_finalize(statement);
                    
                    sqlite3_close(db);
                }
            }
        }
        @catch(NSException *e)
        {
            OALog(@"Error: %@", e.description);
        }
    }
}

- (void)indexCachedResources:(NSMutableDictionary *)fileModified rs:(NSMutableDictionary *)rs
{
    sqlite3 *db;
    sqlite3_stmt    *statement;
    
    if (sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
    {
        NSString *querySQL = @"SELECT filename, date_modified, left, right, top, bottom FROM TILE_SOURCES";
        
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *filename;
                if (sqlite3_column_text(statement, 0) != nil)
                    filename = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                long lastModified = (long)sqlite3_column_int(statement, 1);
                NSNumber *read = [fileModified objectForKey:filename];
                
                if([rs objectForKey:filename] && read && lastModified == [read longValue])
                {
                    int left = sqlite3_column_int(statement, 2);
                    int right = sqlite3_column_int(statement, 3);
                    int top = sqlite3_column_int(statement, 4);
                    float bottom = sqlite3_column_int(statement, 5);
                    [_indexedResources insert:filename box:[[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom]];
                    [fileModified removeObjectForKey:filename];
                }
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }
}

- (NSMutableDictionary *)readFiles:(NSMutableDictionary *)fileModified
{
    NSMutableDictionary *rs = [NSMutableDictionary dictionary];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_tilesDir error:nil];
    if (files)
    {
        for (NSString *file in files)
        {
            NSString *f = [_tilesDir stringByAppendingPathComponent:file];
            NSError *error;
            NSURL *fileUrl = [NSURL fileURLWithPath:f];
            NSDate *fileDate;
            [fileUrl getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:&error];
            if (!error)
            {
                NSString *fileName = [f lastPathComponent];
                NSString *ext = [f pathExtension];
                if([ext isEqualToString:@"sqlitedb"] &&
                   [[[fileName substringToIndex:9] lowercaseString] isEqualToString:@"hillshade"])
                {
                    OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:f];
                    [rs setObject:ts forKey:fileName];
                    [fileModified setObject:[NSNumber numberWithInt:[fileDate timeIntervalSince1970] * 1000] forKey:fileName];
                }
            }
        }
    }
    return rs;
}


- (NSArray *)getTileSource:(int)x y:(int)y zoom:(int)zoom
{
    NSMutableArray *ls = [NSMutableArray array];
    int z = (zoom - ZOOM_BOUNDARY);
    if (z > 0)
        [_indexedResources queryInBox:[[QuadRect alloc] initWithLeft:(x >> z) top:(y >> z) right:(x >> z) bottom:(y >> z)] result:ls];
    else
        [_indexedResources queryInBox:[[QuadRect alloc] initWithLeft:(x << -z) top:(y << -z) right:((x + 1) << -z) bottom:((y + 1) << -z)] result:ls];
    
    return [NSArray arrayWithArray:ls];
}

- (BOOL)exists:(int)x y:(int)y zoom:(int)zoom
{
    @synchronized(_sync)
    {
        NSArray *ts = [self getTileSource:x y:y zoom:zoom];
        for (NSString *t in ts)
        {
            OASQLiteTileSource *sqLiteTileSource = [_resources objectForKey:t];
            if(sqLiteTileSource && [sqLiteTileSource exists:x y:y zoom:zoom])
                return YES;
        }
        return NO;
    }
}

- (NSData *)getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    @synchronized(_sync)
    {
        NSArray *ts = [self getTileSource:x y:y zoom:zoom];
        for (NSString *t in ts)
        {
            OASQLiteTileSource *sqLiteTileSource = [_resources objectForKey:t];
            if (sqLiteTileSource)
                return [sqLiteTileSource getBytes:x y:y zoom:zoom timeHolder:timeHolder];
        }
        return nil;
    }
}

- (UIImage *)getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    @synchronized(_sync)
    {
        NSArray *ts = [self getTileSource:x y:y zoom:zoom];
        for (NSString *t in ts)
        {
            OASQLiteTileSource *sqLiteTileSource = [_resources objectForKey:t];
            if (sqLiteTileSource)
                return [sqLiteTileSource getImage:x y:y zoom:zoom timeHolder:timeHolder];
        }
        return nil;
    }
}


@end
