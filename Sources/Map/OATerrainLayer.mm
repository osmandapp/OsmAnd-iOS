//
//  OAHillshadeLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATerrainLayer.h"
#import "QuadTree.h"
#import "QuadRect.h"
#import "OALog.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"

#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/TileSqliteDatabase.h>
#include <OsmAndCore/TileSqliteDatabasesCollection.h>


typedef NS_ENUM(NSInteger, EOATerrainLayerType)
{
    EOATerrainLayerTypeHillshade,
    EOATerrainLayerTypeSlope
};

@implementation OATerrainLayer
{
    EOATerrainLayerType _terrainType;

    NSString *_tilesDir;
    std::shared_ptr<const OsmAnd::ITileSqliteDatabasesCollection> _sqliteDbCollection;

    NSObject *_sync;
    OAAutoObserverProxy* _terrainChangeObserver;
}

+ (OATerrainLayer *) sharedInstanceHillshade
{
    static dispatch_once_t once;
    static OATerrainLayer * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init:EOATerrainLayerTypeHillshade];
    });
    return sharedInstance;
}

+ (OATerrainLayer *) sharedInstanceSlope
{
    static dispatch_once_t once;
    static OATerrainLayer * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init:EOATerrainLayerTypeSlope];
    });
    return sharedInstance;
}

- (instancetype) init:(EOATerrainLayerType)terrainType
{
    self = [super init];
    if (self)
    {
        _sync = [[NSObject alloc] init];
        _terrainType = terrainType;
        _tilesDir = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources"];
        
        [self initCollection];
        
        _terrainChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onTerrainResourcesChanged)
                                                              andObserve:[OsmAndApp instance].data.terrainResourcesChangeObservable];
    }
    return self;
}

- (void) onTerrainResourcesChanged
{
    [self initCollection];
    [[OsmAndApp instance].data.terrainChangeObservable notifyEvent];
}

- (void) initCollection
{
    @synchronized(_sync)
    {
        const auto sqliteDbCollection = new OsmAnd::TileSqliteDatabasesCollection();
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
                    NSString *ext = [[f pathExtension] lowercaseString];
                    NSString *type = [[[f stringByDeletingPathExtension] pathExtension] lowercaseString];
                    if ([ext isEqualToString:@"sqlitedb"] &&
                        (([type isEqualToString:@"hillshade"] && _terrainType == EOATerrainLayerTypeHillshade)
                         || ([type isEqualToString:@"slope"] && _terrainType == EOATerrainLayerTypeSlope)))
                    {
                        sqliteDbCollection->addFile(QString::fromNSString(f));
                    }
                }
            }
        }
        _sqliteDbCollection.reset(sqliteDbCollection);
    }
}


- (QList<std::shared_ptr<const OsmAnd::TileSqliteDatabase>>) getTileSources:(int)x y:(int)y zoom:(int)zoom
{
    return _sqliteDbCollection->getTileSqliteDatabases(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom);
}

- (BOOL) exists:(int)x y:(int)y zoom:(int)zoom
{
    @synchronized(_sync)
    {
        auto ts = [self getTileSources:x y:y zoom:zoom];
        for (const auto t : ts)
            if (t->containsTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom))
                return YES;

        return NO;
    }
}

- (NSData *) getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    @synchronized(_sync)
    {
        auto ts = [self getTileSources:x y:y zoom:zoom];
        for (const auto t : ts)
        {
            QByteArray data;
            int64_t time;
            if (t->obtainTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom, data, timeHolder ? &time : nullptr))
            {
                if (timeHolder)
                    *timeHolder = [NSNumber numberWithLongLong:(long long)time];
                
                return [NSData dataWithBytes:data.constData() length:data.length()];
            }
        }
        return nil;
    }
}

- (UIImage *) getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
{
    @synchronized(_sync)
    {
        auto ts = [self getTileSources:x y:y zoom:zoom];
        for (const auto t : ts)
        {
            QByteArray data;
            int64_t time;
            if (t->obtainTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom, data, timeHolder ? &time : nullptr))
            {
                if (!data.isEmpty())
                {
                    if (timeHolder)
                        *timeHolder = [NSNumber numberWithLongLong:(long long)time];

                    return [UIImage imageWithData:[NSData dataWithBytes:data.constData() length:data.length()]];
                }
            }
        }
        return nil;
    }
}

@end
