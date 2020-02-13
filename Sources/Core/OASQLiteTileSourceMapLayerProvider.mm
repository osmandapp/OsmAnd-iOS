//
//  OASQLiteTileSourceMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OASQLiteTileSourceMapLayerProvider.h"
#include <OsmAndCore/WebClient.h>
#include <SKBitmap.h>

#include "Logging.h"

OASQLiteTileSourceMapLayerProvider::OASQLiteTileSourceMapLayerProvider(const QString& fileName)
: _webClient(std::shared_ptr<const OsmAnd::IWebClient>(new OsmAnd::WebClient()))
{
    ts = [[OASQLiteTileSource alloc] initWithFilePath:fileName.toNSString()];
}

OASQLiteTileSourceMapLayerProvider::~OASQLiteTileSourceMapLayerProvider()
{
    this->waitForTasksDone();
    ts = nil;
}

OsmAnd::AlphaChannelPresence OASQLiteTileSourceMapLayerProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

QByteArray OASQLiteTileSourceMapLayerProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    lockTile(request.tileId, request.zoom);
    NSNumber *time = [[NSNumber alloc] init];
    NSData *data = [ts getBytes:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:&time];
    if (data && ![ts expired:time])
    {
        unlockTile(request.tileId, request.zoom);
        return QByteArray::fromNSData(data);
    }
    else
    {
        NSString *url = [ts getUrlToLoad:request.tileId.x y:request.tileId.y zoom:request.zoom];
        if (url != nil)
        {
            QString tileUrl = QString::fromNSString(url);
            std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
            const auto& downloadResult = _webClient->downloadData(tileUrl, &requestResult);
            
            // If there was error, check what the error was
            if (!requestResult->isSuccessful())
            {
                const auto httpStatus = std::dynamic_pointer_cast<const OsmAnd::IWebClient::IHttpRequestResult>(requestResult)->getHttpStatusCode();
                
                LogPrintf(OsmAnd::LogSeverityLevel::Warning,
                          "Failed to download tile from %s (HTTP status %d)",
                          qPrintable(tileUrl),
                          httpStatus);
                
                // 404 means that this tile does not exist, so delete it
                if (httpStatus == 404)
                {
                    [ts deleteImage:request.tileId.x y:request.tileId.y zoom:request.zoom];
                }
                requestResult.reset();
                // Unlock the tile
                unlockTile(request.tileId, request.zoom);
                return nullptr;
            }
            [ts insertImage:request.tileId.x y:request.tileId.y zoom:request.zoom data:downloadResult.toNSData()];
            requestResult.reset();
            unlockTile(request.tileId, request.zoom);
            return downloadResult;
        }
    }
    unlockTile(request.tileId, request.zoom);
    return nullptr;
}

void OASQLiteTileSourceMapLayerProvider::obtainImageAsync(
                                                   const OsmAnd::IMapTiledDataProvider::Request& request,
                                                   const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage)
{
    //
}

void OASQLiteTileSourceMapLayerProvider::lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    while(_tilesInProcess[zoom].contains(tileId))
        _waitUntilAnyTileIsProcessed.wait(&_tilesInProcessMutex);
        
    _tilesInProcess[zoom].insert(tileId);
}

void OASQLiteTileSourceMapLayerProvider::unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].remove(tileId);
    
    _waitUntilAnyTileIsProcessed.wakeAll();
}

OsmAnd::MapStubStyle OASQLiteTileSourceMapLayerProvider::getDesiredStubsStyle() const
{
    return OsmAnd::MapStubStyle::Unspecified;
}

float OASQLiteTileSourceMapLayerProvider::getTileDensityFactor() const
{
    return 1.0f;
}

uint32_t OASQLiteTileSourceMapLayerProvider::getTileSize() const
{
    return [ts getTileSize];
}

bool OASQLiteTileSourceMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OASQLiteTileSourceMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return true;
}

OsmAnd::ZoomLevel OASQLiteTileSourceMapLayerProvider::getMinZoom() const
{
    return (OsmAnd::ZoomLevel)[ts minimumZoomSupported];
}

OsmAnd::ZoomLevel OASQLiteTileSourceMapLayerProvider::getMaxZoom() const
{
    return (OsmAnd::ZoomLevel)[ts maximumZoomSupported];
}

void OASQLiteTileSourceMapLayerProvider::performAdditionalChecks(std::shared_ptr<const SkBitmap> bitmap)
{
    if (ts.tileSize != bitmap->width() && bitmap->width() != 0)
    {
        [ts setTileSize:bitmap->width()];
    }
}
