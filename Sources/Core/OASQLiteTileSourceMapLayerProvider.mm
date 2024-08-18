//
//  OASQLiteTileSourceMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASQLiteTileSourceMapLayerProvider.h"
#import "OANativeUtilities.h"
#import "OAWebClient.h"
#import "OAMapCreatorDbHelper.h"

#include <SkImageEncoder.h>
#include <SkStream.h>
#include <SkData.h>
#include <SkImage.h>
#include <OsmAndCore/WebClient.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/OnlineRasterMapLayerProvider.h>
#include <OsmAndCore/Logging.h>

OASQLiteTileSourceMapLayerProvider::OASQLiteTileSourceMapLayerProvider(const QString& fileName)
: _webClient(std::shared_ptr<const OsmAnd::IWebClient>(new OAWebClient()))
, _fileName(fileName)
, _tileSize(256)
{
    auto db = [OAMapCreatorDbHelper.sharedInstance getTileSqliteDatabase:fileName.toNSString()];
    if (!db)
    {
        db = std::make_shared<OsmAnd::TileSqliteDatabase>(fileName);
        _ts = db;
    }
    
    if (db->open())
    {
        OsmAnd::TileSqliteDatabase::Meta meta;
        if (db->obtainMeta(meta))
        {
            bool ok = false;
            
            auto tileSize = meta.getTileSize(&ok);
            if (ok)
                _tileSize = (int) tileSize;
            
            ok = true;
            auto userAgent = meta.getUserAgent(&ok);
            if (ok)
                _userAgent = userAgent;
                        
            _randomsArray = OsmAnd::OnlineTileSources::parseRandoms(meta.getRandoms());
        }
    }
}

OASQLiteTileSourceMapLayerProvider::~OASQLiteTileSourceMapLayerProvider()
{
}

std::shared_ptr<OsmAnd::TileSqliteDatabase> OASQLiteTileSourceMapLayerProvider::getDatabase() const
{
    return _ts ? _ts : [OAMapCreatorDbHelper.sharedInstance getTileSqliteDatabase:_fileName.toNSString()];
}

bool OASQLiteTileSourceMapLayerProvider::isEllipsoid()
{
    const auto& db = getDatabase();
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (db && db->open() && db->obtainMeta(meta))
    {
        bool ok = false;
        auto ellipsoid = meta.getEllipsoid(&ok);
        if (ok)
            return ellipsoid > 0;
    }
    return 0;
}

int64_t OASQLiteTileSourceMapLayerProvider::getExpirationTimeMillis()
{
    const auto& db = getDatabase();
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (db && db->open() && db->obtainMeta(meta))
    {
        bool ok = false;
        auto expireMinutes = meta.getExpireMinutes(&ok);
        if (ok)
             return expireMinutes * 60 * 1000;
    }
    return -1;
}

OsmAnd::AlphaChannelPresence OASQLiteTileSourceMapLayerProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

QString OASQLiteTileSourceMapLayerProvider::getUrlToLoad(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    int32_t x = tileId.x;
    int32_t y = tileId.y;
        
    const auto& db = getDatabase();
    OsmAnd::TileSqliteDatabase::Meta meta;
    if (!db || !db->open() || !db->obtainMeta(meta))
        return QString();

    auto maxZoom = db->getMaxZoom();
    if (zoom > maxZoom)
        return QString();
    
    auto url = meta.getUrl();
    if (url.isEmpty())
        return QString();

    bool ok = false;
    auto invertedY = meta.getInvertedY(&ok);
    if (ok && invertedY > 0)
        y = (1 << zoom) - 1 - y;
        
    return OsmAnd::OnlineRasterMapLayerProvider::buildUrlToLoad(url, _randomsArray, x, y, zoom);
}

bool OASQLiteTileSourceMapLayerProvider::expired(const int64_t time)
{
    const auto& db = getDatabase();
    if (db && db->open() && db->isTileTimeSupported())
    {
        auto expirationTimeMillis = getExpirationTimeMillis();
        if (expirationTimeMillis > 0)
            return QDateTime::currentMSecsSinceEpoch() - time > expirationTimeMillis;
    }
    
    return false;
}

QByteArray OASQLiteTileSourceMapLayerProvider::downloadTile(
    const OsmAnd::TileId tileId,
    const OsmAnd::ZoomLevel zoom,
    const std::shared_ptr<const OsmAnd::IQueryController>& queryController/* = nullptr*/)
{
    const auto& db = getDatabase();
    if (!db || !db->open())
        return nullptr;

    const auto& tileUrl = getUrlToLoad(tileId, zoom);
    if (!tileUrl.isEmpty())
    {
        OsmAnd::IWebClient::DataRequest dataRequest;
        dataRequest.queryController = queryController;
        const auto& downloadResult = _webClient->downloadData(tileUrl, dataRequest, _userAgent);
        
        // If there was error, check what the error was
        if (!dataRequest.requestResult || !dataRequest.requestResult->isSuccessful() || downloadResult.isEmpty())
        {
            if (dataRequest.requestResult)
            {
                const auto httpStatus = std::dynamic_pointer_cast<const OsmAnd::IWebClient::IHttpRequestResult>(dataRequest.requestResult)->getHttpStatusCode();
                
                LogPrintf(OsmAnd::LogSeverityLevel::Warning,
                          "Failed to download tile from %s (HTTP status %d)",
                          qPrintable(tileUrl),
                          httpStatus);
                
                // 404 means that this tile does not exist, so delete it
                if (httpStatus == 404)
                    db->removeTileData(tileId, zoom);
            }
            return nullptr;
        }
        db->storeTileData(tileId, zoom, downloadResult, QDateTime::currentMSecsSinceEpoch());
        return downloadResult;
    }
    return nullptr;
}

const sk_sp<SkImage> OASQLiteTileSourceMapLayerProvider::createShiftedTileBitmap(const QByteArray& data, const QByteArray& dataNext, double offsetY)
{
    if (data.isEmpty() && dataNext.isEmpty())
        return nullptr;
    
    sk_sp<SkImage> firstImage = nullptr;
    sk_sp<SkImage> secondImage = nullptr;
    if (!data.isEmpty())
        firstImage = OsmAnd::SkiaUtilities::createImageFromData(data);

    if (!dataNext.isEmpty())
        secondImage = OsmAnd::SkiaUtilities::createImageFromData(dataNext);

    if (!firstImage && !secondImage)
        return nullptr;
    
    return OsmAnd::SkiaUtilities::createTileImage(firstImage, secondImage, offsetY);
}

const sk_sp<SkImage> OASQLiteTileSourceMapLayerProvider::downloadShiftedTile(const OsmAnd::TileId tileIdNext, const OsmAnd::ZoomLevel zoom, const QByteArray& data, double offsetY)
{
    const auto& db = getDatabase();
    QByteArray dataNext;
    int64_t timeNext;
    bool ok = db && db->open() && db->retrieveTileData(tileIdNext, zoom, dataNext, &timeNext);
    if (ok && !expired(timeNext))
    {
        const auto shiftedTile = createShiftedTileBitmap(data, dataNext, offsetY);
        return shiftedTile;
    }
    else
    {
        // download next tile
        const auto& downloadResult = downloadTile(tileIdNext, zoom);
        return createShiftedTileBitmap(data, downloadResult, offsetY);
    }
    return nullptr;
}

const sk_sp<SkImage> OASQLiteTileSourceMapLayerProvider::decodeBitmap(const QByteArray& data)
{
    // Decode image data
    const sk_sp<SkImage> image = OsmAnd::SkiaUtilities::createImageFromData(data);
    if (!image)
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
            "Failed to decode image tile");

        return nullptr;
    }
    return image;
}

long long OASQLiteTileSourceMapLayerProvider::obtainImageData(const OsmAnd::ImageMapLayerProvider::Request& request, QByteArray& byteArray)
{
    return 0;
}

sk_sp<const SkImage> OASQLiteTileSourceMapLayerProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    auto tileId = request.tileId;
    auto zoom = request.zoom;
    double offsetY = 0;
    if (isEllipsoid())
    {
        double latitude = OsmAnd::Utilities::getLatitudeFromTile(zoom, tileId.y);
        auto numberOffset = OsmAnd::Utilities::getTileEllipsoidNumberAndOffsetY(zoom, latitude, _tileSize);
        tileId.y = numberOffset.x;
        offsetY = numberOffset.y;
    }

    lockTile(tileId, zoom);
    auto tileIdNext = tileId;
    tileIdNext.y += 1;
    bool shiftedTile = offsetY > 0;
    if (shiftedTile)
        lockTile(tileIdNext, zoom);

    const auto& db = getDatabase();
    QByteArray data;
    int64_t time;
    bool ok = db && db->open() && db->retrieveTileData(tileId, zoom, data, &time);
    if (ok && !data.isEmpty() && !expired(time))
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
                const auto shiftedTile = downloadShiftedTile(tileIdNext, zoom, downloadResult, offsetY);
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

            return OsmAnd::SkiaUtilities::createImageFromData(downloadResult);
        }
    }
    unlockTile(tileId, zoom);
    if (shiftedTile)
        unlockTile(tileIdNext, zoom);
    return nullptr;
}

bool OASQLiteTileSourceMapLayerProvider::supportsObtainImage() const
{
    return true;
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
    return _tileSize;
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
    const auto& db = getDatabase();
    return db ? db->getMinZoom() : OsmAnd::MinZoomLevel;
}

OsmAnd::ZoomLevel OASQLiteTileSourceMapLayerProvider::getMaxZoom() const
{
    const auto& db = getDatabase();
    return db ? db->getMaxZoom() : OsmAnd::MaxZoomLevel;
}

void OASQLiteTileSourceMapLayerProvider::performAdditionalChecks(sk_sp<SkImage> image)
{
    if (_tileSize != image->width() && image->width() != 0)
    {
        const auto& db = getDatabase();
        OsmAnd::TileSqliteDatabase::Meta meta;
        if (db && db->open() && db->obtainMeta(meta))
        {
            _tileSize = image->width();
            meta.setTileSize(_tileSize);
            db->storeMeta(meta);
        }
    }
}
