//
//  OASQLiteTileSourceMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OASQLiteTileSourceMapLayerProvider.h"

#include <SkImageDecoder.h>
#include <SkImageEncoder.h>
#include <SkStream.h>
#include <SkData.h>
#include <SkBitmap.h>

#include <OsmAndCore/WebClient.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/Logging.h>

#import "OAWebClient.h"

OASQLiteTileSourceMapLayerProvider::OASQLiteTileSourceMapLayerProvider(const QString& fileName)
: _webClient(std::shared_ptr<const OsmAnd::IWebClient>(new OAWebClient()))
{
    ts = [[OASQLiteTileSource alloc] initWithFilePath:fileName.toNSString()];
}

OASQLiteTileSourceMapLayerProvider::~OASQLiteTileSourceMapLayerProvider()
{
    ts = nil;
}

OsmAnd::AlphaChannelPresence OASQLiteTileSourceMapLayerProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

QByteArray OASQLiteTileSourceMapLayerProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    return nullptr;
}

QByteArray OASQLiteTileSourceMapLayerProvider::downloadTile(
    const OsmAnd::TileId tileId,
    const OsmAnd::ZoomLevel zoom,
    const std::shared_ptr<const OsmAnd::IQueryController>& queryController/* = nullptr*/)
{
    NSString *url = [ts getUrlToLoad:tileId.x y:tileId.y zoom:zoom];
    if (url != nil)
    {
        QString tileUrl = QString::fromNSString(url);
        std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
        const auto& downloadResult = _webClient->downloadData(tileUrl, &requestResult, nullptr, queryController);
        
        // If there was error, check what the error was
        if (!requestResult || !requestResult->isSuccessful() || downloadResult.isEmpty())
        {
            if (requestResult)
            {
                const auto httpStatus = std::dynamic_pointer_cast<const OsmAnd::IWebClient::IHttpRequestResult>(requestResult)->getHttpStatusCode();
                
                LogPrintf(OsmAnd::LogSeverityLevel::Warning,
                          "Failed to download tile from %s (HTTP status %d)",
                          qPrintable(tileUrl),
                          httpStatus);
                
                // 404 means that this tile does not exist, so delete it
                if (httpStatus == 404)
                {
                    [ts deleteImage:tileId.x y:tileId.y zoom:zoom];
                }
            }
            requestResult.reset();
            return nullptr;
        }
        [ts insertImage:tileId.x y:tileId.y zoom:zoom data:downloadResult.toNSData()];
        requestResult.reset();
        return downloadResult;
    }
    return nullptr;
}

const std::shared_ptr<const SkBitmap> OASQLiteTileSourceMapLayerProvider::createShiftedTileBitmap(const NSData *data, const NSData* dataNext, double offsetY)
{
    if (data.length == 0 && dataNext.length == 0)
        return nullptr;

    std::shared_ptr<SkBitmap> firstBitmap;
    std::shared_ptr<SkBitmap> secondBitmap;
    if (data.length > 0)
    {
        firstBitmap.reset(new SkBitmap());
        if (!SkImageDecoder::DecodeMemory(
             data.bytes, data.length,
             firstBitmap.get(),
             SkColorType::kUnknown_SkColorType,
             SkImageDecoder::kDecodePixels_Mode))
        {
            firstBitmap.reset();
        }
    }
    if (dataNext.length > 0)
    {
        secondBitmap.reset(new SkBitmap());
        if (!SkImageDecoder::DecodeMemory(
             dataNext.bytes, dataNext.length,
             secondBitmap.get(),
             SkColorType::kUnknown_SkColorType,
             SkImageDecoder::kDecodePixels_Mode))
        {
            secondBitmap.reset();
        }
    }
    if (!firstBitmap && !secondBitmap)
        return nullptr;
    
    return OsmAnd::SkiaUtilities::createTileBitmap(firstBitmap, secondBitmap, offsetY);
}

const std::shared_ptr<const SkBitmap> OASQLiteTileSourceMapLayerProvider::downloadShiftedTile(const OsmAnd::TileId tileIdNext, const OsmAnd::ZoomLevel zoom, const NSData *data, double offsetY)
{
    NSNumber *timeNext = [[NSNumber alloc] init];
    NSData *dataNext = [ts getBytes:tileIdNext.x y:tileIdNext.y zoom:zoom timeHolder:&timeNext];
    if (dataNext && ![ts expired:timeNext])
    {
        const auto shiftedTile = createShiftedTileBitmap(data, dataNext, offsetY);
        return shiftedTile;
    }
    else
    {
        // download next tile
        const auto& downloadResult = downloadTile(tileIdNext, zoom);
        return createShiftedTileBitmap(data, downloadResult.toNSData(), offsetY);
    }
    return nullptr;
}

const std::shared_ptr<const SkBitmap> OASQLiteTileSourceMapLayerProvider::decodeBitmap(const NSData *data)
{
    // Decode image data
    const std::shared_ptr<SkBitmap> bitmap(new SkBitmap());
    if (!SkImageDecoder::DecodeMemory(
            data.bytes, data.length,
            bitmap.get(),
            SkColorType::kUnknown_SkColorType,
            SkImageDecoder::kDecodePixels_Mode))
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
            "Failed to decode image tile");

        return nullptr;
    }
    return bitmap;
}

const std::shared_ptr<const SkBitmap> OASQLiteTileSourceMapLayerProvider::obtainImageBitmap(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    auto tileId = request.tileId;
    auto zoom = request.zoom;
    double offsetY = 0;
    if (ts.isEllipticYTile)
    {
        double latitude = OsmAnd::Utilities::getLatitudeFromTile(zoom, tileId.y);
        auto numberOffset = OsmAnd::Utilities::getTileEllipsoidNumberAndOffsetY(zoom, latitude, ts.tileSize);
        tileId.y = numberOffset.x;
        offsetY = numberOffset.y;
    }

    lockTile(tileId, zoom);
    auto tileIdNext = tileId;
    tileIdNext.y += 1;
    bool shiftedTile = offsetY > 0;
    if (shiftedTile)
        lockTile(tileIdNext, zoom);

    NSNumber *time = [[NSNumber alloc] init];
    NSData *data = [ts getBytes:tileId.x y:tileId.y zoom:zoom timeHolder:&time];
    if (data && ![ts expired:time])
    {
        if (shiftedTile)
        {
            const auto shiftedTile = downloadShiftedTile(tileIdNext, zoom, data, offsetY);
            if (shiftedTile)
            {
                unlockTile(tileId, zoom);
                unlockTile(tileIdNext, zoom);
                return shiftedTile;
            }
        }
        unlockTile(tileId, zoom);
        if (shiftedTile)
            unlockTile(tileIdNext, zoom);
        
        return decodeBitmap(data);
    }
    else
    {
        // download tile
        const auto& downloadResult = downloadTile(tileId, zoom, request.queryController);
        if (!downloadResult.isNull())
        {
            if (shiftedTile)
            {
                const auto shiftedTile = downloadShiftedTile(tileIdNext, zoom, downloadResult.toNSData(), offsetY);
                if (shiftedTile)
                {
                    unlockTile(tileId, zoom);
                    unlockTile(tileIdNext, zoom);
                    return shiftedTile;
                }
            }
            unlockTile(tileId, zoom);
            if (shiftedTile)
                unlockTile(tileIdNext, zoom);

            return OsmAnd::ImageMapLayerProvider::decodeBitmap(downloadResult);
        }
    }
    unlockTile(tileId, zoom);
    if (shiftedTile)
        unlockTile(tileIdNext, zoom);
    return nullptr;
}

bool OASQLiteTileSourceMapLayerProvider::supportsObtainImageBitmap() const
{
    return true;
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
