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
#import "OsmAndApp.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/SkiaUtilities.h>
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
    
    QVector<QPair<OsmAnd::ZoomLevel, OsmAnd::AreaI>> _tileAreas;
    int _areaIndex;
    
    int _currZoom;
    int _currX;
    int _currY;
    OsmAnd::AreaI _currArea;
    
    std::atomic_bool _cancelled;
    
    OASQLiteTileSource *_sqliteSource;
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> _onlineSource;
    NSString *_downloadPath;
}

- (instancetype) initWithItem:(OAResourceItem *)item minZoom:(int)minZoom maxZoom:(int)maxZoom
{
    self = [super init];
    if (self) {
        _cancelled = false;
        NSURLSessionConfiguration *backgroundSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        backgroundSessionConfiguration.timeoutIntervalForRequest = 300.0;
        backgroundSessionConfiguration.timeoutIntervalForResource = 600.0;
        backgroundSessionConfiguration.HTTPMaximumConnectionsPerHost = 70;
        _urlSession = [NSURLSession sessionWithConfiguration:backgroundSessionConfiguration
                                                               delegate:nil
                                                          delegateQueue:nil];
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
        _tileAreas = [self tileAreasForZooms];
    }
    return self;
}

- (OAMapTileDownloader *)downloaderForRetry
{
    OAMapTileDownloader *downloader = [[OAMapTileDownloader alloc] initWithItem:_item minZoom:_minZoom maxZoom:_maxZoom];
    downloader->_tileAreas = _tileAreas;
    return downloader;
}

- (BOOL)hasNextTileId
{
    if (_cancelled || _tileAreas.isEmpty())
        return NO;
    return _currZoom == -1 || _areaIndex + 1 < _tileAreas.size()
        || _currX < _currArea.right() || _currY < _currArea.bottom();
}

- (OsmAnd::TileId)getNextTileId
{
    if (_currZoom == -1)
    {
        _areaIndex = 0;
        _currZoom = _tileAreas.first().first;
        _currArea = _tileAreas.first().second;
        _currX = _currArea.left();
        _currY = _currArea.top();
    }
    else if (_currY < _currArea.bottom())
        _currY++;
    else if (_currX < _currArea.right())
    {
        _currX++;
        _currY = _currArea.top();
    }
    else
    {
        _areaIndex++;
        _currZoom = _tileAreas[_areaIndex].first;
        _currArea = _tileAreas[_areaIndex].second;
        _currX = _currArea.left();
        _currY = _currArea.top();
    }
    return OsmAnd::TileId::fromXY(_currX, _currY);
}

- (QVector<QPair<OsmAnd::ZoomLevel, OsmAnd::AreaI>>)tileAreasForZooms
{
    QVector<QPair<OsmAnd::ZoomLevel, OsmAnd::AreaI>> result;
    OAMapRendererView *mapView = OARootViewController.instance.mapPanel.mapViewController.mapView;
    const auto visibleArea = mapView.renderer->getMapState().visibleBBoxShifted;
    for (int zoom = _minZoom; zoom <= _maxZoom; zoom++)
    {
        const auto tileZoom = static_cast<OsmAnd::ZoomLevel>(zoom);
        for (const auto& area : [OAResourcesUIHelper tileAreasFor:_item visibleArea:visibleArea zoom:tileZoom])
            result.push_back(qMakePair(tileZoom, area));
    }
    return result;
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
    
    [_urlSession.delegateQueue addOperationWithBlock:^{
        for (NSInteger i = 0; i < kMaxRequests; i++) {
            [self startDownloadIfPossible];
        }
    }];
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
        if ([_sqliteSource getBytes:tileId.x y:tileId.y zoom:_currZoom].length > 0)
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

- (BOOL)isSuccessfulResponse:(NSURLResponse *)response location:(NSURL *)location error:(NSError *)error
{
    if (error || !location)
        return NO;

    if ([response isKindOfClass:NSHTTPURLResponse.class])
    {
        NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
        if (statusCode < 200 || statusCode >= 300)
            return NO;
    }

    return OsmAnd::SkiaUtilities::createImageFromFile(QFileInfo(QString::fromNSString(location.path))) != nullptr;
}

- (void)onTileFailed
{
    if (_cancelled)
        return;

    if (_delegate)
        [_delegate onTileFailed];

    _activeDownloads--;
    [self startDownloadIfPossible];
}

- (void) downloadTile:(NSURL *)url toPath:(NSString *)path
{
    _activeDownloads++;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *userAgent = _onlineSource->userAgent.toNSString();
    [request addValue:userAgent.length > 0 ? userAgent : kDefaultUserAgent forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (_cancelled)
            return;

        if (![self isSuccessfulResponse:response location:location error:error])
        {
            [self onTileFailed];
            return;
        }

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dir = [path stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSURL *targetURLDir = [NSURL fileURLWithPath:path];
        
        if ([fileManager moveItemAtURL:location toURL:targetURLDir error:nil] || [fileManager fileExistsAtPath:path])
        {
            if (_delegate)
                [_delegate onTileDownloaded:YES];
            
            _activeDownloads--;
            [self startDownloadIfPossible];
        }
        else
        {
            [self onTileFailed];
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
        if (_cancelled)
            return;

        if (![self isSuccessfulResponse:response location:location error:error])
        {
            [self onTileFailed];
            return;
        }

        NSData *data = [NSData dataWithContentsOfFile:location.path];
        if (data && [tileSource insertImage:x y:y zoom:zoom data:data])
        {
            [NSFileManager.defaultManager removeItemAtURL:location error:nil];
            if (_delegate)
                [_delegate onTileDownloaded:YES];
            
            _activeDownloads--;
            [self startDownloadIfPossible];
        }
        else
        {
            [self onTileFailed];
        }
    }];
    [task resume];
}

- (void) cancellAllRequests
{
    _cancelled = YES;
    [_urlSession.delegateQueue addOperationWithBlock:^{
        [_urlSession invalidateAndCancel];
    }];
}

@end
