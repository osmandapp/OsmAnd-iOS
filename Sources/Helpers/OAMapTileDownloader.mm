//
//  OAMapTileDownloader.m
//  OsmAnd
//
//  Created by Paul on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapTileDownloader.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesUIHelper.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kDefaultUserAgent @"OsmAndiOS"

#define kMaxRequests 50

@implementation OAMapTileDownloader
{
    OAResourceItem *_item;
    NSURLSession *_urlSession;
    int _minZoom;
    int _maxZoom;
    NSInteger _activeDownloads;
    EOATileRequestType _type;
    
    QVector<OsmAnd::AreaI> _areasByZoomIndex;
    
    int _currZoom;
    int _currX;
    int _currY;
    OsmAnd::AreaI _currArea;
    
    BOOL _cancelled;
    
    OASQLiteTileSource *_sqliteSource;
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> _onlineSource;
    NSString *_downloadPath;
}

- (instancetype) initWithItem:(OAResourceItem *)item minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *backgroundSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        backgroundSessionConfiguration.timeoutIntervalForRequest = 300.0;
        backgroundSessionConfiguration.timeoutIntervalForResource = 600.0;
        backgroundSessionConfiguration.HTTPMaximumConnectionsPerHost = 70;
        _urlSession = [NSURLSession sessionWithConfiguration:backgroundSessionConfiguration
                                                               delegate:nil
                                                          delegateQueue:[NSOperationQueue mainQueue]];
        _item = item;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currZoom = -1;
        
        if (_item)
        {
            if ([_item isKindOfClass:OASqliteDbResourceItem.class])
                _type = EOATileRequestTypeSqlite;
            else if ([_item isKindOfClass:OAOnlineTilesResourceItem.class])
                _type = EOATileRequestTypeFile;
            else
                _type = EOATileRequestTypeUndefined;
        }
        else
        {
            _type = EOATileRequestTypeUndefined;
        }
        _areasByZoomIndex = [self getAreasForZooms];
        
        if (_type == EOATileRequestTypeSqlite)
        {
            OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *) _item;
            _sqliteSource = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
        }
        else if (_type == EOATileRequestTypeFile)
        {
            OAOnlineTilesResourceItem *onlineItem = (OAOnlineTilesResourceItem *) _item;
            _onlineSource = onlineItem.onlineTileSource;
            _downloadPath = [OsmAndApp.instance.cachePath stringByAppendingPathComponent:_onlineSource->name.toNSString()];
        }
    }
    return self;
}

- (BOOL) hasNextTileId
{
    if (_cancelled)
        return NO;
    
    const auto largestArea = _areasByZoomIndex.last();
    return !(_currZoom == _maxZoom && _currY + 1 > largestArea.bottomRight.y && _currX + 1 > largestArea.bottomRight.x);
}

- (OsmAnd::TileId) getNextTileId
{
    if (_currZoom == -1)
    {
        _currZoom = _minZoom;
        _currArea = _areasByZoomIndex[_currZoom - _minZoom];
        _currX = _currArea.topLeft.x;
        _currY = _currArea.topLeft.y - 1;
    }
    
    _currY++;
    if (_currY > _currArea.bottomRight.y)
    {
        _currX++;
        _currY = _currArea.topLeft.y;
    }
    
    if (_currX > _currArea.bottomRight.x)
    {
        _currZoom++;
        _currArea = _areasByZoomIndex[_currZoom - _minZoom];
        _currX = _currArea.topLeft.x;
        _currY = _currArea.topLeft.y;
    }
    
    return OsmAnd::TileId::fromXY(_currX, _currY);
}

- (QVector<OsmAnd::AreaI>) getAreasForZooms
{
    QVector<OsmAnd::AreaI> res;
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    OsmAnd::AreaI bbox = [mapView getVisibleBBox31];
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(bbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(bbox.bottomRight);
    for (NSInteger zoom = _minZoom; zoom <= _maxZoom; zoom++)
    {
        int x1 = OsmAnd::Utilities::getTileNumberX(zoom, topLeft.longitude);
        int x2 = OsmAnd::Utilities::getTileNumberX(zoom, bottomRight.longitude);
        int y1 = OsmAnd::Utilities::getTileNumberY(zoom, topLeft.latitude);
        int y2 = OsmAnd::Utilities::getTileNumberY(zoom, bottomRight.latitude);
        OsmAnd::AreaI area;
        area.topLeft = OsmAnd::PointI(x1, y1);
        area.bottomRight = OsmAnd::PointI(x2, y2);
        res.push_back(area);
    }
    return res;
}

- (void) skipDownload
{
    if (_delegate)
        [_delegate onTileDownloaded:NO];
}

- (void) startDownload
{
    if (_type == EOATileRequestTypeUndefined)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i < kMaxRequests; i++) {
            [self startDownloadIfPossible];
        }
    });
}

- (void) startDownloadIfPossible
{
    if (_activeDownloads < kMaxRequests && [self hasNextTileId] && !_cancelled)
    {
        OsmAnd::TileId tileId;
        NSString *urlToLoad;
        do
        {
            if ([self hasNextTileId])
            {
                tileId = [self getNextTileId];
                urlToLoad = [self getUrlToLoad:tileId];
                if (!urlToLoad)
                    [self skipDownload];
            }
            else
            {
                break;
            }
        } while (!urlToLoad && !_cancelled);
        
        if (!_cancelled && urlToLoad)
            [self startDownload:urlToLoad tileId:tileId];
    }
}

- (NSString *) getUrlToLoad:(OsmAnd::TileId)tileId
{
    BOOL isSqlite = _type == EOATileRequestTypeSqlite;
    if (isSqlite && _sqliteSource)
    {
        if ([_sqliteSource getBytes:tileId.x y:tileId.y zoom:_currZoom])
        {
            return nil;
        }
        else
        {
            return [_sqliteSource getUrlToLoad:tileId.x y:tileId.y zoom:_currZoom];
        }
    }
    else if (!isSqlite && _onlineSource != nullptr && _downloadPath)
    {
        NSString *tilePath = [NSString stringWithFormat:@"%@/%@/%@/%@.tile", _downloadPath, @(_currZoom).stringValue, @(tileId.x).stringValue, @(tileId.y).stringValue];
        if ([NSFileManager.defaultManager fileExistsAtPath:tilePath])
        {
            return nil;
        }
        else
        {
            NSString *urlToLoad = _onlineSource->urlToLoad.toNSString();
            QList<QString> randomsArray = OsmAnd::OnlineTileSources::parseRandoms(_onlineSource->randoms);
            NSString *url = OsmAnd::OnlineRasterMapLayerProvider::buildUrlToLoad(QString::fromNSString(urlToLoad), randomsArray, tileId.x, tileId.y, OsmAnd::ZoomLevel(_currZoom)).toNSString();
            return url;
        }
    }
    return nil;
}

- (void) startDownload:(NSString *)url tileId:(OsmAnd::TileId)tileId
{
    BOOL isSqlite = _type == EOATileRequestTypeSqlite;
    if (isSqlite && _sqliteSource)
    {
        [self downloadTile:[NSURL URLWithString:url] x:tileId.x y:tileId.y zoom:_currZoom tileSource:_sqliteSource];
    }
    else if (!isSqlite && _onlineSource != nullptr && _downloadPath)
    {
        NSString *tilePath = [NSString stringWithFormat:@"%@/%@/%@/%@.tile", _downloadPath, @(_currZoom).stringValue, @(tileId.x).stringValue, @(tileId.y).stringValue];
        [self downloadTile:[NSURL URLWithString:url] toPath:tilePath];
    }
}

- (void) downloadTile:(NSURL *)url toPath:(NSString *)path
{
    _activeDownloads++;
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *err = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dir = [path stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSURL *targetURLDir = [NSURL fileURLWithPath:path];
        
        if (targetURLDir && location)
        {
            [fileManager moveItemAtURL:location
                                 toURL:targetURLDir
                                 error:&err];
            if (_delegate)
                [_delegate onTileDownloaded:YES];
             _activeDownloads--;
            [self startDownloadIfPossible];
        }
    }];
    [task resume];
}

- (void) downloadTile:(NSURL *)url x:(int)x y:(int)y zoom:(int)zoom tileSource:(OASQLiteTileSource *)tileSource
{
    _activeDownloads++;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request addValue:tileSource.userAgent.length > 0 ? tileSource.userAgent : kDefaultUserAgent forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSData *data = [NSData dataWithContentsOfFile:location.path];
        if (data)
        {
            [tileSource insertImage:x y:y zoom:zoom data:data];
            [NSFileManager.defaultManager removeItemAtURL:url error:nil];
            if (_delegate)
                [_delegate onTileDownloaded:YES];
            _activeDownloads--;
            [self startDownloadIfPossible];
        }
    }];
    [task resume];
}

- (void) cancellAllRequests
{
    [_urlSession invalidateAndCancel];
    _cancelled = YES;
}

@end
