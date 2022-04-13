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
#include <OsmAndCore/TileSqliteDatabase.h>

#include <QList>

@implementation OASQLiteTileSource
{
    std::shared_ptr<OsmAnd::TileSqliteDatabase> _db;
        
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

- (instancetype) initWithFilePath:(NSString *)filePath
{
    self = [super init];
    if (self)
    {
        _filePath = [filePath copy];
        _name = [[_filePath lastPathComponent] stringByDeletingPathExtension];
        
        _db = std::make_shared<OsmAnd::TileSqliteDatabase>(QString::fromNSString(_filePath));
                
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

- (void) dealloc
{
    if (_db)
        _db->close();
}

- (int) bitDensity
{
    return 16;
}

- (int) maximumZoomSupported
{
    return _maxZoom;
}

- (int) minimumZoomSupported
{
    return _minZoom;
}


- (NSUInteger) hash
{
    return 31 + [_name hash];
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[OASQLiteTileSource class]])
          return NO;
    
    OASQLiteTileSource *obj = object;
    
    return [self.name isEqualToString:obj.name];
}

- (void) initDatabase
{
    if (!_db->open()) {
        return;
    }
    
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (_db->obtainMeta(meta))
    {
        bool ok = false;
        bool metaChanged = NO;

        const auto title = meta.getTitle(&ok);
        if (ok)
        {
            _title = title.toNSString();
        }
        else
        {
            meta.setTitle(QString::fromNSString([_name stringByReplacingOccurrencesOfString:@"_" withString:@" "]));
            metaChanged = YES;
        }
        if (_title.length == 0)
            _title = [_name stringByReplacingOccurrencesOfString:@"_" withString:@" "];

        const auto rule = meta.getRule(&ok);
        if (ok)
            _rule = rule.toNSString();
        
        const auto referer = meta.getReferer(&ok);
        if (ok)
            _referer = referer.toNSString();
        
        auto url = meta.getUrl(&ok);
        if (ok)
            _urlTemplate = OsmAnd::OnlineTileSources::normalizeUrl(url).toNSString();

        const auto tnumbering = meta.getTileNumbering(&ok);
        if (ok)
        {
            _inversiveZoom = QString::compare(QStringLiteral("BigPlanet"), tnumbering, Qt::CaseInsensitive) == 0;
        }
        else
        {
            _inversiveZoom = YES;
            meta.setTileNumbering(QStringLiteral("BigPlanet"));
            metaChanged = YES;
        }
        
        const auto timecolumn = meta.getTimeColumn(&ok);
        if (ok)
        {
            _timeSupported = QString::compare(QStringLiteral("yes"), timecolumn, Qt::CaseInsensitive) == 0;
        }
        else
        {
            _timeSupported = _db->hasTimeColumn();
            meta.setTimeColumn(_timeSupported ? QStringLiteral("yes") : QStringLiteral("no"));
            metaChanged = YES;
        }

        const auto tileSize = meta.getTileSize(&ok);
        _tileSizeSpecified = ok;
        if (ok)
            _tileSize = (int) tileSize;
                
        const auto expireminutes = meta.getExpireMinutes(&ok);
        _expirationTimeMillis = -1;
        if (ok)
        {
            if (expireminutes > -1)
                _expirationTimeMillis = (long) expireminutes * 60 * 1000;
        }
        else
        {
            meta.setExpireMinutes(0);
            metaChanged = YES;
        }

        const auto ellipsoid = meta.getEllipsoid(&ok);
        if (ok)
        {
            _isEllipsoid = ellipsoid > 0;
        }
        else
        {
            _isEllipsoid = NO;
            meta.setEllipsoid(0);
            metaChanged = YES;
        }
        
        const auto invertedY = meta.getInvertedY(&ok);
        if (ok)
            _invertedY = invertedY > 0;
        
        const auto randoms = meta.getRandoms(&ok);
        if (ok)
        {
            _randoms = randoms.toNSString();
            _randomsArray = OsmAnd::OnlineTileSources::parseRandoms(randoms);
        }

        const auto minZoomValue = meta.getMinZoom(&ok);
        if (ok)
            _minZoom = (int) minZoomValue;
        
        const auto maxZoomValue = meta.getMaxZoom(&ok);
        if (ok)
            _maxZoom = (int) maxZoomValue;

        BOOL inversiveInfoZoom = _inversiveZoom;
        if (inversiveInfoZoom)
        {
            int minZ = _minZoom;
            _minZoom = 17 - _maxZoom;
            _maxZoom = 17 - minZ;
        }
    }
}

- (BOOL) exists:(int)x y:(int)y zoom:(int)zoom
{
    return _db->containsTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom);
}

- (NSData *) getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber **)timeHolder
{
    NSData *res;
    if (zoom <= _maxZoom)
    {
        QByteArray data;
        int64_t time;
        if (_db->obtainTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom, data, timeHolder && _timeSupported ? &time : nullptr))
        {
            res = [NSData dataWithBytes:data.constData() length:data.length()];
        }
    }
    return res;
}

- (NSData *) getBytes:(int)x y:(int)y zoom:(int)zoom
{
    return [self getBytes:x y:y zoom:zoom timeHolder:nil];
}

- (UIImage *) getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder
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

- (void) deleteImage:(int)x y:(int)y zoom:(int)zoom
{
    _db->removeTileData(OsmAnd::TileId::fromXY(x, y), (OsmAnd::ZoomLevel) zoom);
}

- (void) deleteCache:(dispatch_block_t)block
{
    _db->removeTilesData();
    _db->compact();
    
    if (block)
        block();
}

- (void) deleteImages:(OsmAnd::AreaI)area zoom:(int)zoom
{
    _db->removeTilesData(area, (OsmAnd::ZoomLevel) zoom);
    _db->compact();
}

- (void) insertImage:(int)x y:(int)y zoom:(int)zoom filePath:(NSString *)filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    [self insertImage:x y:y zoom:zoom data:data];
}

- (void) insertImage:(int)x y:(int)y zoom:(int)zoom data:(NSData *)data
{
    _db->storeTileData(OsmAnd::TileId::fromXY(x, y),
                       (OsmAnd::ZoomLevel) zoom,
                       qMove(QByteArray::fromNSData(data)),
                       (int64_t) (_timeSupported ? [[NSDate date] timeIntervalSince1970] * 1000.0 : 0));
}

- (void) updateInfo:(long)expireTimeMillis url:(NSString *)url minZoom:(int)minZoom maxZoom:(int)maxZoom isEllipticYTile:(BOOL)isEllipticYTile title:(NSString *)title
{
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (_db->obtainMeta(meta))
    {
        auto timeSupported = expireTimeMillis != -1 ? QStringLiteral("yes") : QStringLiteral("no");
        auto timeInMinutes = expireTimeMillis != -1 ? QString::number((long)(expireTimeMillis / 60000)) : QString();
        int minZ = minZoom;
        int maxZ = maxZoom;
        if (_inversiveZoom)
        {
            int cachedMax = maxZ;
            maxZ = 17 - minZ;
            minZ = 17 - cachedMax;
        }
        
        BOOL isOnlineSqlite = [self supportsTileDownload];
        if (isOnlineSqlite)
        {
            meta.setTimeColumn(expireTimeMillis != -1 ? QStringLiteral("yes") : QStringLiteral("no"));
            meta.setExpireMinutes(expireTimeMillis != -1 ? (long)(expireTimeMillis / 60000) : 0);
            meta.setUrl(QString::fromNSString(url));
            meta.setTitle(QString::fromNSString(title));
            meta.setEllipsoid(isEllipticYTile ? 1 : 0);
            meta.setMinZoom(minZ);
            meta.setMaxZoom(maxZ);
        }
        else
        {
            meta.setEllipsoid(isEllipticYTile ? 1 : 0);
            meta.setMinZoom(minZ);
            meta.setMaxZoom(maxZ);
        }
        _db->storeMeta(meta);
    }
}

- (void) setTileSize:(int)tileSize
{
    _tileSize = tileSize;
    _tileSizeSpecified = YES;
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (_db->obtainMeta(meta))
    {
        meta.setTileSize(tileSize);
        _db->storeMeta(meta);
    }
}

- (int) getFileZoom:(int)zoom
{
    return _inversiveZoom ? 17 - zoom : zoom;
}

- (BOOL) isEllipticYTile
{
    return _isEllipsoid;
}

- (BOOL) isInvertedYTile
{
    return _invertedY;
}

- (BOOL) isInversiveZoom
{
    return _inversiveZoom;
}

- (long) getExpirationTimeMinutes
{
    return _expirationTimeMillis < 0 ? -1 : _expirationTimeMillis / (60  * 1000);
}

- (long) getExpirationTimeMillis
{
    return _expirationTimeMillis;
}

- (BOOL) isTimeSupported
{
    return _timeSupported;
}

- (BOOL) expired:(NSNumber *)time
{
    if (_timeSupported && [self getExpirationTimeMillis] > -1 && time)
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
    return _tileSizeSpecified ? _tileSize : 256;
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
    
    BOOL res = NO;
    auto db = new OsmAnd::TileSqliteDatabase(QString::fromNSString(path));
    if (db->open())
    {
        OsmAnd::TileSqliteDatabase::Meta meta;

        int minZoom = [parameters[@"minzoom"] intValue];
        int maxZoom = [parameters[@"maxzoom"] intValue];
        int cachedMax = maxZoom;
        maxZoom = 17 - minZoom;
        minZoom = 17 - cachedMax;
        
        meta.setMinZoom(minZoom);
        meta.setMaxZoom(maxZoom);
        meta.setUrl(QString::fromNSString(parameters[@"url"]));
        meta.setTitle(QString::fromNSString(parameters[@"title"]));
        meta.setEllipsoid([parameters[@"ellipsoid"] intValue]);
        meta.setRule(QString::fromNSString(parameters[@"rule"]));
        meta.setExpireMinutes([parameters[@"expireminutes"] intValue]);
        meta.setTimeColumn(QString::fromNSString(parameters[@"timecolumn"]));
        meta.setReferer(QString::fromNSString(parameters[@"referer"]));
        meta.setTileNumbering(QString::fromNSString(parameters[@"tilenumbering"] ? parameters[@"tilenumbering"] : @"BigPlanet"));
        meta.setRandoms(QString::fromNSString(parameters[@"randoms"]));
        meta.setInvertedY([parameters[@"inverted_y"] intValue]);
        
        res = db->storeMeta(meta);
        db->close();
    }
    delete db;
    
    return res;
}

+ (BOOL) isOnlineTileSource:(NSString *)filePath
{
    BOOL res = NO;

    auto *db = new OsmAnd::TileSqliteDatabase(QString::fromNSString(filePath));
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (db->obtainMeta(meta))
        res = !meta.getUrl().isEmpty();
    
    delete db;
    
    return res;
}

+ (NSString *) getTitleOf:(NSString *)filePath
{
    NSString *title = nil;

    auto *db = new OsmAnd::TileSqliteDatabase(QString::fromNSString(filePath));
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (db->obtainMeta(meta))
        title = meta.getTitle().toNSString();

    delete db;

    return title.length > 0 ? title : [[[filePath lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (NSString *) getFilePath
{
    return _filePath;
}

- (void) enableTileTimeSupportIfNeeded
{
    _db->enableTileTimeSupportIfNeeded();
}

@end
