//
//  OASQLiteTileSource.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASQLiteTileSource.h"
#import <sqlite3.h>
#import "QuadRect.h"

#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <QList>

@implementation OASQLiteTileSource
{
    dispatch_queue_t _dbQueue;
    sqlite3 *_db;
    
    NSString *_filePath;
    int _minZoom;
    int _maxZoom;
    BOOL _inversiveZoom;
    BOOL _timeSupported;
    BOOL _tileSizeSpecified;
    long _expirationTimeMillis;
    BOOL _isEllipsoid;
    BOOL _invertedY;
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    if (self)
    {
        _filePath = [filePath copy];
        _name = [[_filePath lastPathComponent] stringByDeletingPathExtension];
        
        _minZoom = 1;
        _maxZoom = 17;
        _inversiveZoom = YES; // BigPlanet
        _expirationTimeMillis = -1; // never
        _tileFormat = @".png";
        _tileSize = 256;
        
        [self initDatabase];
    }
    return self;
}

- (int)bitDensity
{
    return 16;
}

- (int)maximumZoomSupported
{
    return _maxZoom;
}

- (int)minimumZoomSupported
{
    return _minZoom;
}


-(NSUInteger)hash
{
    return 31 + [_name hash];
}

-(BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[OASQLiteTileSource class]])
          return NO;
    
    OASQLiteTileSource *obj = object;
    
    return [self.name isEqualToString:obj.name];
}

+ (NSString *)getValueOf:(int)fieldIndex statement:(sqlite3_stmt *)statement
{
    if (sqlite3_column_text(statement, fieldIndex) != nil)
        return [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, fieldIndex)];
    else
        return nil;
}

- (void)initDatabase
{
    _dbQueue = dispatch_queue_create("sqliteTileSourceDbQueue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(_dbQueue, ^{
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            NSString *querySQL = @"SELECT * FROM info";
            sqlite3_stmt *statement;
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    int columnCount = sqlite3_column_count(statement);
                    NSMutableDictionary *mapper= [[NSMutableDictionary alloc] init];
                    for(int i = 0; i < columnCount; i++)
                    {
                        const char *_columnName = sqlite3_column_name(statement, i);
                        NSString *columnName = [[NSString alloc] initWithUTF8String:_columnName];
                        [mapper setObject:[NSNumber numberWithInteger:i] forKey:columnName];
                    }
                    
                    NSNumber *ruleId = [mapper objectForKey:@"rule"];
                    if(ruleId)
                        _rule = [self.class getValueOf:[ruleId intValue] statement:statement];
                    
                    NSNumber *refererId = [mapper objectForKey:@"referer"];
                    if (refererId)
                        _referer = [self.class getValueOf:[refererId intValue] statement:statement];
                    
                    NSNumber *urlTemplateId = [mapper objectForKey:@"url"];
                    if (urlTemplateId)
                    {
                        QString urlTemplate = QString::fromNSString([self.class getValueOf:[urlTemplateId intValue] statement:statement]);
                        _urlTemplate = OsmAnd::OnlineTileSources::normalizeUrl(urlTemplate).toNSString();
                    }
                    
                    NSNumber *tnumbering = [mapper objectForKey:@"tilenumbering"];
                    if (tnumbering)
                    {
                        _inversiveZoom = ([@"BigPlanet" caseInsensitiveCompare:[self.class getValueOf:[tnumbering intValue] statement:statement]] == NSOrderedSame);
                    }
                    else
                    {
                        _inversiveZoom = YES;
                        [self addInfoColumn:@"tilenumbering" value:@"BigPlanet"];
                    }
                    
                    NSNumber *timecolumn = [mapper objectForKey:@"timecolumn"];
                    if (timecolumn)
                    {
                        NSLog(@"%@", [self.class getValueOf:[timecolumn intValue] statement:statement]);
                        _timeSupported = ([@"yes" caseInsensitiveCompare:[self.class getValueOf:[timecolumn intValue] statement:statement]] == NSOrderedSame);
                    }
                    else
                    {
                        _timeSupported = [self hasTimeColumn];
                        [self addInfoColumn:@"timecolumn" value:(_timeSupported ? @"yes" : @"no")];
                    }
                    
                    NSNumber *tileSizeColumn = [mapper objectForKey:@"tilesize"];
                    _tileSizeSpecified = tileSizeColumn != nil;
                    if(_tileSizeSpecified)
                        _tileSize = sqlite3_column_int(statement, [tileSizeColumn intValue]);;
                    
                    NSNumber *expireminutes = [mapper objectForKey:@"expireminutes"];
                    _expirationTimeMillis = -1;
                    if (expireminutes)
                    {
                        int minutes = sqlite3_column_int(statement, [expireminutes intValue]);
                        if (minutes > 0)
                            _expirationTimeMillis = (long) minutes * 60 * 1000;
                    }
                    else
                    {
                        [self addInfoColumn:@"expireminutes" value:@"0"];
                    }
                    NSNumber *ellipsoid = [mapper objectForKey:@"ellipsoid"];
                    if (ellipsoid)
                    {
                        int set = sqlite3_column_int(statement, [ellipsoid intValue]);
                        if (set == 1)
                            _isEllipsoid = YES;
                    }
                    NSNumber *invertedY = [mapper objectForKey:@"inverted_y"];
                    if(invertedY)
                    {
                        int set = sqlite3_column_int(statement, [invertedY intValue]);
                        if (set == 1)
                            _invertedY = YES;
                    }
                    
                    NSNumber *randomsId = [mapper objectForKey:@"randoms"];
                    if(randomsId)
                    {
                        _randoms = [self.class getValueOf:[randomsId intValue] statement:statement];
                        _randomsArray = OsmAnd::OnlineTileSources::parseRandoms(QString::fromNSString(_randoms));
                    }

                    BOOL inversiveInfoZoom = _inversiveZoom;
                    NSNumber *mnz = [mapper objectForKey:@"minzoom"];
                    if (mnz)
                        _minZoom = sqlite3_column_int(statement, [mnz intValue]);

                    NSNumber *mxz = [mapper objectForKey:@"maxzoom"];
                    if (mxz)
                        _maxZoom = sqlite3_column_int(statement, [mxz intValue]);

                    if (inversiveInfoZoom)
                    {
                        int minZ = _minZoom;
                        _minZoom = 17 - _maxZoom;
                        _maxZoom = 17 - minZ;
                    }
                    
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_db);
        }
    });
}

- (void)addInfoColumn:(NSString *)columnName value:(NSString *)value
{
    dispatch_async(_dbQueue, ^{
    
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            const char *sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE info ADD COLUMN %@ TEXT", columnName] UTF8String];
            sqlite3_exec(_db, sql_stmt, NULL, NULL, NULL);
            
            sqlite3_stmt *statement;
            sql_stmt = [[NSString stringWithFormat:@"UPDATE info SET %@ = ?", columnName] UTF8String];
            sqlite3_prepare_v2(_db, sql_stmt, -1, &statement, NULL);
            
            sqlite3_bind_text(statement, 1, [value UTF8String], -1, 0);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(_db);
        }
    });
}

- (BOOL)hasTimeColumn
{
    BOOL res = NO;
    
    sqlite3 *tilesDb;
    sqlite3_stmt *statement;
    
    if (sqlite3_open([_filePath UTF8String], &tilesDb) == SQLITE_OK)
    {
        NSString *querySQL = @"SELECT * FROM tiles";
        
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(tilesDb, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                int columnCount = sqlite3_column_count(statement);
                for(int i = 0; i < columnCount; i++)
                {
                    const char *_columnName = sqlite3_column_name(statement, i);
                    NSString *columnName = [[NSString alloc] initWithUTF8String:_columnName];
                    if ([columnName caseInsensitiveCompare:@"time"] == NSOrderedSame)
                    {
                        res = YES;
                        break;
                    }
                }
                
                break;
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(tilesDb);
    }
    
    return res;
}

- (BOOL)exists:(int)x y:(int)y zoom:(int)zoom
{
    BOOL __block res = NO;
    //long long time = [[NSDate date] timeIntervalSince1970] * 1000.0;
    
    int z = [self getFileZoom:zoom];
    
    dispatch_sync(_dbQueue, ^{
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT 1 FROM tiles WHERE x = %d AND y = %d AND z = %d", x, y, z];
            sqlite3_stmt *statement;
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    res = YES;
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_db);
        }
    });
    
    //if (!res)
    //    NSLog(@"Checking tile existance x = %d y = %d z = %d for %lld ms", x, y, zoom, (long long)([[NSDate date] timeIntervalSince1970] * 1000.0 - time));
    
    return res;
}

- (BOOL)isLocked
{
    BOOL __block res;
    
    dispatch_sync(_dbQueue, ^{
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            sqlite3_close(_db);
            res = NO;
        }
        else
        {
            res = YES;
        }
    });
    
    return res;
}

- (NSData* )getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    NSData* __block res;
    //long long ts = [[NSDate date] timeIntervalSince1970] * 1000.0;

    dispatch_sync(_dbQueue, ^{
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            if (zoom <= _maxZoom)
            {
                BOOL queryTime = (timeHolder && _timeSupported);

                NSString *querySQL = [NSString stringWithFormat:@"SELECT image%@ FROM tiles WHERE x = %d AND y = %d AND z = %d", (queryTime ? @", time" : @""), x, y, [self getFileZoom:zoom]];
                sqlite3_stmt *statement;
                
                const char *query_stmt = [querySQL UTF8String];
                if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
                {
                    while (sqlite3_step(statement) == SQLITE_ROW)
                    {
                        const void * bytes = sqlite3_column_blob(statement, 0);
                        int lenght = sqlite3_column_bytes(statement, 0);
                        res = [NSData dataWithBytes:bytes length:lenght];
                        
                        if (queryTime)
                            *timeHolder = [NSNumber numberWithLong:(long)sqlite3_column_int64(statement, 1)];
                        
                        break;
                    }
                    sqlite3_finalize(statement);
                }
            }
            
            sqlite3_close(_db);
        }
    });
    
    //if (!res)
    //    NSLog(@"Load tile %d %d %d for %lld ms", x, y, zoom, (long long)([[NSDate date] timeIntervalSince1970] * 1000.0 - ts));

    return res;
}

- (NSData *)getBytes:(int)x y:(int)y zoom:(int)zoom
{
    return [self getBytes:x y:y zoom:zoom timeHolder:nil];
}

- (UIImage *)getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    NSData *data = [self getBytes:x y:y zoom:zoom timeHolder:timeHolder];
    if (data)
    {
        UIImage *img = [UIImage imageWithData:data];
        if (!img)
        {
            // broken image delete it
            [self deleteImage:x y:y zoom:zoom];
        }
        return img;
    }
    
    return nil;
}

- (QuadRect *) getRectBoundary:(int)coordinatesZoom minZ:(int)minZ
{
    if (coordinatesZoom > 25)
        return nil;
    
    NSString *querySQL;
    if (_inversiveZoom)
    {
        int minZoom = (17 - minZ) + 1;
        // 17 - z = zoom, x << (25 - zoom) = 25th x tile = 8 + z,
        querySQL = [NSString stringWithFormat:@"SELECT max(x << (8+z)), min(x << (8+z)), max(y << (8+z)), min(y << (8+z)) from tiles where z < %d", minZoom];
    }
    else
    {
        querySQL = [NSString stringWithFormat:@"SELECT max(x << (25-z)), min(x << (25-z)), max(y << (25-z)), min(y << (25-z)) from tiles where z > %d", minZ];
    }

    int __block right;
    int __block left;
    int __block top;
    int __block bottom;

    dispatch_sync(_dbQueue, ^{
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    right = (int) (sqlite3_column_int(statement, 0) >> (25 - coordinatesZoom));
                    left = (int) (sqlite3_column_int(statement, 1) >> (25 - coordinatesZoom));
                    top = (int) (sqlite3_column_int(statement, 3) >> (25 - coordinatesZoom));
                    bottom  = (int) (sqlite3_column_int(statement, 2) >> (25 - coordinatesZoom));
                    break;
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_close(_db);
        }
    });
    
    return [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
}

- (void)deleteImage:(int)x y:(int)y zoom:(int)zoom
{
    dispatch_async(_dbQueue, ^{
        
        sqlite3_stmt    *statement;
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat: @"DELETE FROM tiles WHERE x = %d AND y = %d AND z = %d", x, y, [self getFileZoom:zoom]];
            const char *update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(_db, update_stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(_db);
        }
    });
}

- (void)deleteCache:(dispatch_block_t)block
{
    dispatch_async(_dbQueue, ^{

        sqlite3_stmt    *deleteStatement;
        sqlite3_stmt    *vacuumStatement;
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            NSString *deleteCacheSQL = @"DELETE FROM tiles";
            const char *update_stmt = [deleteCacheSQL UTF8String];
            sqlite3_prepare_v2(_db, update_stmt, -1, &deleteStatement, NULL);
            sqlite3_step(deleteStatement);
            sqlite3_finalize(deleteStatement);

            NSString *vacuumSQL = @"VACUUM";
            const char *vacuum_stmt = [vacuumSQL UTF8String];
            sqlite3_prepare_v2(_db, vacuum_stmt, -1, &vacuumStatement, NULL);
            sqlite3_step(vacuumStatement);
            sqlite3_finalize(vacuumStatement);
            
            sqlite3_close(_db);
            if (block)
                block();
        }
    });
}

- (void)insertImage:(int)x y:(int)y zoom:(int)zoom filePath:(NSString *)filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    [self insertImage:x y:y zoom:zoom data:data];
}

- (void)insertImage:(int)x y:(int)y zoom:(int)zoom data:(NSData *)data
{
    dispatch_async(_dbQueue, ^{
        
        sqlite3_stmt    *statement;
        
        if (sqlite3_open([_filePath UTF8String], &_db) == SQLITE_OK)
        {
            NSString *query = (_timeSupported ? @"INSERT OR REPLACE INTO tiles(x,y,z,s,image,time) VALUES(?, ?, ?, ?, ?, ?)"
            : @"INSERT OR REPLACE INTO tiles(x,y,z,s,image) VALUES(?, ?, ?, ?, ?)");
            
            const char *update_stmt = [query UTF8String];
            sqlite3_prepare_v2(_db, update_stmt, -1, &statement, NULL);
            
            sqlite3_bind_int(statement, 1, x);
            sqlite3_bind_int(statement, 2, y);
            sqlite3_bind_int(statement, 3, [self getFileZoom:zoom]);
            sqlite3_bind_int(statement, 4, 0);

            sqlite3_bind_blob(statement, 5, [data bytes], data.length, SQLITE_TRANSIENT);
            if (_timeSupported)
                sqlite3_bind_int64(statement, 6, (int64_t)([[NSDate date] timeIntervalSince1970] * 1000.0));
            
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            sqlite3_close(_db);
        }
    });
}

- (void) setTileSize:(int)tileSize
{
    _tileSize = tileSize;
    _tileSizeSpecified = YES;
    [self addInfoColumn:@"tilesize" value:[NSString stringWithFormat:@"%d", _tileSize]];
}

- (int)getFileZoom:(int)zoom
{
    return _inversiveZoom ? 17 - zoom : zoom;
}

- (BOOL)isEllipticYTile
{
    return _isEllipsoid;
}

- (BOOL) isInvertedYTile
{
    return _invertedY;
}

- (long)getExpirationTimeMinutes
{
    if(_expirationTimeMillis  < 0) {
        return -1;
    }
    return _expirationTimeMillis / (60  * 1000);
}

- (long)getExpirationTimeMillis
{
    return _expirationTimeMillis;
}

- (BOOL) expired:(NSNumber *)time
{
    if (_timeSupported && [self getExpirationTimeMillis] > 0 && time)
        return ([[NSDate date] timeIntervalSince1970] * 1000.0) - time.longValue > [self getExpirationTimeMillis];
    
    return NO;
}

- (NSString *) getUrlToLoad:(int) x y:(int) y zoom:(int) zoom
{
    if (zoom > _maxZoom)
        return nil;
    
    if(_urlTemplate == nil)
        return nil;

    if (_invertedY)
        y = (1 << zoom) - 1 - y;
    
    return OsmAnd::OnlineRasterMapLayerProvider::buildUrlToLoad(QString::fromNSString(_urlTemplate), _randomsArray, x, y, OsmAnd::ZoomLevel(zoom)).toNSString();
}

- (int) getTileSize
{
    if (_tileSizeSpecified)
        return _tileSize;
    return 256;
}

- (BOOL) supportsTileDownload
{
    return _urlTemplate != nil && _urlTemplate.length > 0;
}

+ (BOOL) createNewTileSourceDbAtPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path])
        [fileManager removeItemAtPath:path error:nil];
    
    sqlite3 *tmpDatabase;
    sqlite3_stmt *statement;
    if (sqlite3_open([path UTF8String], &tmpDatabase) == SQLITE_OK)
    {
        const char *sqlInfoStatement = "CREATE TABLE info (minzoom TEXT, maxzoom TEXT, url TEXT, ellipsoid INTEGER, rule TEXT, timeSupported TEXT, expireminutes TEXT, timecolumn TEXT, referer TEXT, tilenumbering TEXT)";
        const char *sqlTilesStatement = "CREATE TABLE tiles (x INTEGER NOT NULL, y INTEGER NOT NULL, z INTEGER NOT NULL, s INTEGER, image BLOB, time INTEGER, PRIMARY KEY (x, y, z))";
        const char *sqlSIndexStatement = "CREATE INDEX index_tiles_on_s ON tiles (s)";
        const char *sqlXIndexStatement = "CREATE INDEX index_tiles_on_x ON tiles (x)";
        const char *sqlYIndexStatement = "CREATE INDEX index_tiles_on_y ON tiles (y)";
        const char *sqlZIndexStatement = "CREATE INDEX index_tiles_on_z ON tiles (z)";
        
        char *error;
        sqlite3_exec(tmpDatabase, sqlInfoStatement, NULL, NULL, &error);
        sqlite3_exec(tmpDatabase, sqlTilesStatement, NULL, NULL, &error);
        sqlite3_exec(tmpDatabase, sqlSIndexStatement, NULL, NULL, &error);
        sqlite3_exec(tmpDatabase, sqlXIndexStatement, NULL, NULL, &error);
        sqlite3_exec(tmpDatabase, sqlYIndexStatement, NULL, NULL, &error);
        sqlite3_exec(tmpDatabase, sqlZIndexStatement, NULL, NULL, &error);
        
        BOOL hasRandoms = parameters[@"randoms"] != nil;
        if (hasRandoms)
        {
            const char *sql_stmt = [[NSString stringWithFormat:@"ALTER TABLE info ADD COLUMN randoms TEXT"] UTF8String];
            sqlite3_exec(tmpDatabase, sql_stmt, NULL, NULL, NULL);
        }
        
        NSString *query = hasRandoms ? @"INSERT OR REPLACE INTO info(minzoom, maxzoom, url, ellipsoid, rule, timeSupported, expireminutes, timecolumn, referer, tilenumbering, randoms) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" : @"INSERT OR REPLACE INTO info(minzoom, maxzoom, url, ellipsoid, rule, timeSupported, expireminutes, timecolumn, referer, tilenumbering) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        const char *update_stmt = [query UTF8String];
        sqlite3_prepare_v2(tmpDatabase, update_stmt, -1, &statement, NULL);
        
        int minZoom = [parameters[@"minzoom"] intValue];
        int maxZoom = [parameters[@"maxzoom"] intValue];
        int cachedMax = maxZoom;
        maxZoom = 17 - minZoom;
        minZoom = 17 - cachedMax;
        
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", minZoom] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 2, [[NSString stringWithFormat:@"%d", maxZoom] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 3, [parameters[@"url"] UTF8String], -1, 0);
        sqlite3_bind_int(statement, 4, [parameters[@"ellipsoid"] intValue]);
        sqlite3_bind_text(statement, 5, [parameters[@"rule"] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 6, [parameters[@"timeSupported"] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 7, [parameters[@"expireminutes"] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 8, [parameters[@"timecolumn"] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 9, [parameters[@"referer"] UTF8String], -1, 0);
        sqlite3_bind_text(statement, 10, [parameters[@"tilenumbering"] ? parameters[@"tilenumbering"] : @"BigPlanet" UTF8String], -1, 0);
        
        if (hasRandoms)
            sqlite3_bind_text(statement, 11, [parameters[@"randoms"] UTF8String], -1, 0);
        
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        
        sqlite3_close(tmpDatabase);
        return error == NULL;
    }
    return NO;
}

+ (BOOL) isOnlineTileSource:(NSString *)filePath
{
    sqlite3 *db;
    if (sqlite3_open([filePath UTF8String], &db) == SQLITE_OK)
    {
        NSString *querySQL = @"SELECT url FROM info LIMIT 1";
        sqlite3_stmt *statement;
        
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                int columnCount = sqlite3_column_count(statement);
                if (columnCount == 1)
                {
                    NSString *urlTemplate = [self.class getValueOf:0 statement:statement];
                    return urlTemplate != nil && urlTemplate.length > 0;
                }
            }
        }
        sqlite3_close(db);
    }
    return NO;
}

@end
