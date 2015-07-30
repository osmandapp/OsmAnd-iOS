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

const static int ZOOM_BOUNDARY = 15;

@implementation OAHillshadeLayer
{
    NSDictionary *_resources;
    QuadTree *_indexedResources;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _indexedResources = [[QuadTree alloc] initWithQuadRect:[[QuadRect alloc] initWithLeft:0 top:0 right:1 << (ZOOM_BOUNDARY+1) bottom:1 << (ZOOM_BOUNDARY+1)] depth:8 ratio:0.55f];

        //[self indexHillshadeFiles];
        //[self createTileSource];
    }
    return self;
}
/*
- (void)indexHillshadeFiles
{
    sqlite3 *db;
    sqlite3_stmt *statement;

    NSString *tilesDir = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources"];

    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Library/HillshadeDatabase"];
    NSString *databasePath = [dir stringByAppendingString:@"hillshade.cache"];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: databasePath ] == NO)
    {
        if (sqlite3_open([databasePath UTF8String], &db) == SQLITE_OK)
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
    NSMutableDictionary *rs = [self readFiles:tilesDir fileModified:fileModified];
    [self indexCachedResources:fileModified rs:rs];
    [self indexNonCachedResources:fileModified rs:rs];
    _resources = [NSDictionary dictionaryWithDictionary:rs];
}

- (void)indexNonCachedResources:(NSMutableDictionary *)fileModified rs:(NSMutableDictionary *)rs
{
    for(NSString *filename in fileModified.allKeys)
    {
        @try
        {
            OALog(@"Indexing hillshade file %@", filename);
            ContentValues cv = new ContentValues();
            cv.put("filename", filename);
            cv.put("date_modified", fileModified.get(filename));
            SQLiteTileSource ts = rs.get(filename);
            QuadRect rt = ts.getRectBoundary(ZOOM_BOUNDARY, 1);
            if (rt != null) {
                indexedResources.insert(filename, rt);
                cv.put("left", (int)rt.left);
                cv.put("right",(int) rt.right);
                cv.put("top", (int)rt.top);
                cv.put("bottom",(int) rt.bottom);
                sqliteDb.insert("TILE_SOURCES", null, cv);
            }
        }
        @catch(NSException *e)
        {
            OALog(@"Error: %@", e.description);
        }
    }
}

        private void indexCachedResources(Map<String, Long> fileModified, Map<String, SQLiteTileSource> rs) {
            Cursor cursor = sqliteDb.rawQuery("SELECT filename, date_modified, left, right, top, bottom FROM TILE_SOURCES",
                                              new String[0]);
            if(cursor.moveToFirst()) {
                do {
                    String filename = cursor.getString(0);
                    long lastModified = cursor.getLong(1);
                    Long read = fileModified.get(filename);
                    if(rs.containsKey(filename) && read != null && lastModified == read) {
                        int left = cursor.getInt(2);
                        int right = cursor.getInt(3);
                        int top = cursor.getInt(4);
                        float bottom = cursor.getInt(5);
                        indexedResources.insert(filename, new QuadRect(left, top, right, bottom));
                        fileModified.remove(filename);
                    }
                    
                } while(cursor.moveToNext());
            }
            cursor.close();
        }
        
        private Map<String, SQLiteTileSource> readFiles(final OsmandApplication app, File tilesDir, Map<String, Long> fileModified) {
            Map<String, SQLiteTileSource> rs = new LinkedHashMap<String, SQLiteTileSource>();
            File[] files = tilesDir.listFiles();
            if(files != null) {
                for(File f : files) {
                    if(f != null && f.getName().endsWith(IndexConstants.SQLITE_EXT) && 
                       f.getName().toLowerCase().startsWith("hillshade")) {
                        SQLiteTileSource ts = new SQLiteTileSource(app, f, new ArrayList<TileSourceTemplate>());
                        rs.put(f.getName(), ts);
                        fileModified.put(f.getName(), f.lastModified());
                    }
                }
            }
            return rs;
        }
        
    };
    executeTaskInBackground(task);
}


List<String> getTileSource(int x, int y, int zoom) {
				ArrayList<String> ls = new ArrayList<String>();
				int z = (zoom - ZOOM_BOUNDARY);
				if (z > 0) {
                    indexedResources.queryInBox(new QuadRect(x >> z, y >> z, (x >> z), (y >> z)), ls);
                } else {
                    indexedResources.queryInBox(new QuadRect(x << -z, y << -z, (x + 1) << -z, (y + 1) << -z), ls);
                }
				return ls;
}

@Override
public boolean exists(int x, int y, int zoom) {
				List<String> ts = getTileSource(x, y, zoom);
				for (String t : ts) {
                    SQLiteTileSource sqLiteTileSource = resources.get(t);
                    if(sqLiteTileSource != null && sqLiteTileSource.exists(x, y, zoom)) {
                        return true;
                    }
                }
				return false;
}

@Override
public Bitmap getImage(int x, int y, int zoom, long[] timeHolder) {
				List<String> ts = getTileSource(x, y, zoom);
				for (String t : ts) {
                    SQLiteTileSource sqLiteTileSource = resources.get(t);
                    if (sqLiteTileSource != null) {
                        Bitmap bmp = sqLiteTileSource.getImage(x, y, zoom, timeHolder);
                        if (bmp != null) {
                            return sqLiteTileSource.getImage(x, y, zoom, timeHolder);
                        }
                    }
                }
				return null;
}
*/

@end
