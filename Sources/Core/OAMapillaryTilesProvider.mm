//
//  OAMapillaryTilesProvider.m
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include "OAMapillaryTilesProvider.h"
#import "OANativeUtilities.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "OAWebClient.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Logging.h>
#include <QStandardPaths>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/IWebClient.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/IQueryController.h>
#include "OAWebClient.h"
#include <SkImageEncoder.h>
#include <SkBitmapDevice.h>
#include <SkCanvas.h>
#include <SkBitmap.h>
#include <SkData.h>
#include <SkPaint.h>

#define EXTENT 4096.0
#define LINE_WIDTH 3.0f

OAMapillaryTilesProvider::OAMapillaryTilesProvider(const float displayDensityFactor /* = 1.0f*/, const unsigned long long physicalMemory /*= 0*/)
: _vectorName(QStringLiteral("mapillary_vector"))
, _vectorPathSuffix(QString(_vectorName).replace(QRegExp(QLatin1String("\\W+")), QLatin1String("_")))
, _vectorUrlPattern(QStringLiteral("https://d25uarhxywzl1j.cloudfront.net/v0.1/${osm_zoom}/${osm_x}/${osm_y}.mvt"))
, _rasterZoomLevel(OsmAnd::ZoomLevel16)
, _vectorZoomLevel(OsmAnd::ZoomLevel14)
, _rasterName(QStringLiteral("mapillary_raster"))
, _rasterPathSuffix(QString(_rasterName).replace(QRegExp(QLatin1String("\\W+")), QLatin1String("_")))
, _rasterUrlPattern(QStringLiteral("https://d6a1v2w10ny40.cloudfront.net/v0.1/${osm_zoom}/${osm_x}/${osm_y}.png"))
, _webClient(std::shared_ptr<const OsmAnd::IWebClient>(new OAWebClient()))
, _networkAccessAllowed(true)
, _displayDensityFactor(displayDensityFactor)
, _physicalMemory(physicalMemory)
, _mvtReader(new OsmAnd::MvtReader())
, _image([OANativeUtilities skBitmapFromPngResource:@"map_mapillary_photo_dot"])
, _linePaint(new SkPaint())
{
    if (physicalMemory > (unsigned long long) 2 << 30)
        _maxCacheSize = 5;
    else if (physicalMemory > (unsigned long long) 1 << 30)
        _maxCacheSize = 4;
    else
        _maxCacheSize = 3;

    _vectorLocalCachePath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation)).absoluteFilePath(_vectorPathSuffix);
    if (_vectorLocalCachePath.isEmpty())
        _vectorLocalCachePath = QLatin1String(".");
    
    _rasterLocalCachePath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation)).absoluteFilePath(_rasterPathSuffix);
    if (_rasterLocalCachePath.isEmpty())
        _rasterLocalCachePath = QLatin1String(".");
    
    _linePaint->setColor(OsmAnd::ColorARGB(color_mapillary).toSkColor());
    _linePaint->setStrokeWidth(LINE_WIDTH * _displayDensityFactor);
    _linePaint->setAntiAlias(true);
    _linePaint->setStrokeJoin(SkPaint::kRound_Join);
    _linePaint->setStrokeCap(SkPaint::kRound_Cap);
}

OAMapillaryTilesProvider::~OAMapillaryTilesProvider()
{
}

OsmAnd::AlphaChannelPresence OAMapillaryTilesProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

void OAMapillaryTilesProvider::drawPoints(
                                          const OsmAnd::IMapTiledDataProvider::Request &req,
                                          const OsmAnd::TileId &tileId,
                                          const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                                          SkCanvas& canvas)
{
    int dzoom = req.zoom - _vectorZoomLevel;
    double mult = (int) pow(2.0, dzoom);
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    const auto& tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    const auto tileSize = getTileSize();
    const auto px31Size = tileSize31 / tileSize;
    const auto bitmapHalfSize = _image->width() / 2;
    const auto& tileBBox31Enlarged = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom).enlargeBy(bitmapHalfSize * px31Size);
    
    for (const auto& point : geometryTile->getGeometry())
    {
        if (point == nullptr || point->getType() != OsmAnd::MvtReader::GeomType::POINT)
            continue;
        
        double px, py;
        const auto& p = std::dynamic_pointer_cast<const OsmAnd::MvtReader::Point>(point);
        OsmAnd::PointI coordinate = p->getCoordinate();
        px = coordinate.x / EXTENT;
        py = coordinate.y / EXTENT;
        
        double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
        double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
        
        if (tileBBox31Enlarged.contains(tileX, tileY)) {
            if ([OAAppSettings sharedManager].useMapillaryFilter.get && filtered(p->getUserData(), geometryTile))
                    continue;
            
            SkScalar x = ((tileX - tileBBox31.left()) / tileSize31) * tileSize - bitmapHalfSize;
            SkScalar y = ((tileY - tileBBox31.top()) / tileSize31) * tileSize - bitmapHalfSize;
            canvas.drawBitmap(*_image, x, y);
        }
    }
}

bool OAMapillaryTilesProvider::filtered(const QHash<uint8_t, QVariant> &userData, const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile) const
{
    if (userData.count() == 0)
        return true;

    OAAppSettings *settings = [OAAppSettings sharedManager];
    QString keys = QString::fromNSString(settings.mapillaryFilterUserKey.get);
    QStringList userKeys = keys.split(QStringLiteral("$$$"));
    
    double capturedAt = userData[OsmAnd::MvtReader::getUserDataId("captured_at")].toDouble() / 1000;
    double from = settings.mapillaryFilterStartDate.get;
    double to = settings.mapillaryFilterEndDate.get;
    bool pano = settings.mapillaryFilterPano.get;
    
    if (userKeys.count() > 0 && (keys.compare(QStringLiteral("")) != 0))
    {
        const auto keyId = userData[OsmAnd::MvtReader::getUserDataId("userkey")].toInt();
        const auto& key = geometryTile->getUserKey(keyId);
        if (!userKeys.contains(key))
            return true;
    }
    if (from != 0 && to != 0)
    {
        if (capturedAt < from || capturedAt > to)
            return true;
    }
    else if ((from != 0 && capturedAt < from) || (to != 0 && capturedAt > to))
        return true;
    if (pano)
        return userData[OsmAnd::MvtReader::getUserDataId("pano")].toInt() == 0;

    return false;
}

void OAMapillaryTilesProvider::drawLine(
                                        const std::shared_ptr<const OsmAnd::MvtReader::LineString> &line,
                                        const OsmAnd::IMapTiledDataProvider::Request &req,
                                        const OsmAnd::TileId &tileId,
                                        SkCanvas& canvas)
{
    int dzoom = req.zoom - _vectorZoomLevel;
    int mult = (int) pow(2.0, dzoom);
    double px, py;
    const auto &linePts = line->getCoordinateSequence();
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    const auto& tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    const auto tileSize = getTileSize();

    SkScalar x1, y1, x2, y2 = 0;
    bool first = true;
    for (const auto &point : linePts)
    {
        px = point.x / EXTENT;
        py = point.y / EXTENT;
        
        double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
        double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
        
        x2 = ((tileX - tileBBox31.left()) / tileSize31) * tileSize;
        y2 = ((tileY - tileBBox31.top()) / tileSize31) * tileSize;

        if (tileBBox31.contains(tileX, tileY))
        {
            if (!first)
                canvas.drawLine(x1, y1, x2, y2, *_linePaint);
            else
                first = false;
        }
        
        x1 = x2;
        y1 = y2;
    }
}

void OAMapillaryTilesProvider::drawLines(
                                         const OsmAnd::IMapTiledDataProvider::Request &req,
                                         const OsmAnd::TileId &tileId,
                                         const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                                         SkCanvas& canvas)
{
    for (const auto& point : geometryTile->getGeometry())
    {
        if (point == nullptr || (point->getType() != OsmAnd::MvtReader::GeomType::LINE_STRING && point->getType() != OsmAnd::MvtReader::GeomType::MULTI_LINE_STRING))
            continue;
        
        if (point->getType() == OsmAnd::MvtReader::GeomType::LINE_STRING)
        {
            const auto& line = std::dynamic_pointer_cast<const OsmAnd::MvtReader::LineString>(point);
            if (!filtered(line->getUserData(), geometryTile))
                drawLine(line, req, tileId, canvas);
        }
        else
        {
            const auto& multiline = std::dynamic_pointer_cast<const OsmAnd::MvtReader::MultiLineString>(point);
            if (!filtered(multiline->getUserData(), geometryTile))
                for (const auto &lineString : multiline->getLines())
                    drawLine(lineString, req, tileId, canvas);
        }
    }
}

void OAMapillaryTilesProvider::clearDiskCache(bool vectorRasterOnly/* = false*/)
{
    QString rasterLocalCachePath;
    QString vectorLocalCachePath;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        
        rasterLocalCachePath = QString(_rasterLocalCachePath);
        vectorLocalCachePath = QString(_vectorLocalCachePath);
    }
    
    QWriteLocker scopedLocker(&_localCacheLock);

    if (!vectorRasterOnly)
    {
        QDir(rasterLocalCachePath).removeRecursively();
        QDir(vectorLocalCachePath).removeRecursively();
    }
    QDir(vectorLocalCachePath + QDir::separator() + QLatin1String("png")).removeRecursively();
}

void OAMapillaryTilesProvider::clearMemoryCache(const bool clearAll /*= false*/)
{
    QMutexLocker scopedLocker(&_geometryCacheMutex);

    clearMemoryCacheImpl(clearAll);
}

void OAMapillaryTilesProvider::clearMemoryCacheImpl(const bool clearAll /*= false*/)
{
    if (clearAll) {
        _geometryCache.clear();
    }
    else
    {
        auto it = _geometryCache.begin();
        auto i = _geometryCache.size() / 2;
        while (it != _geometryCache.end() && i > 0) {
            it = _geometryCache.erase(it);
            i--;
        }
    }
}

std::shared_ptr<const OsmAnd::MvtReader::Tile> OAMapillaryTilesProvider::readGeometry(
                                                                                      const QFileInfo &localFile,
                                                                                      const OsmAnd::TileId &tileId)
{
    QMutexLocker scopedLocker(&_geometryCacheMutex);
    
    auto it = _geometryCache.constFind(tileId);
    if (it == _geometryCache.cend())
        it = _geometryCache.insert(tileId, _mvtReader->parseTile(localFile.absoluteFilePath()));
    
    const auto list = *it;
    
    if (_geometryCache.size() > _maxCacheSize)
        clearMemoryCacheImpl();
    
    return list;
}

std::shared_ptr<const OsmAnd::MvtReader::Tile> OAMapillaryTilesProvider::readGeometry(const OsmAnd::TileId &tileId)
{
    QReadLocker scopedLocker(&_localCacheLock);

    const auto tileLocalRelativePath =
    QString::number(_vectorZoomLevel) + QDir::separator() +
    QString::number(tileId.x) + QDir::separator() +
    QString::number(tileId.y) + QLatin1String(".mvt");
    
    QFileInfo localFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        localFile.setFile(QDir(_vectorLocalCachePath).absoluteFilePath(tileLocalRelativePath));
    }
    return localFile.exists() ? readGeometry(localFile, tileId) : nullptr;
}

QByteArray OAMapillaryTilesProvider::drawTile(const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                                              const OsmAnd::TileId &tileId,
                                              const OsmAnd::IMapTiledDataProvider::Request &req)
{
    if (req.queryController != nullptr && req.queryController->isAborted())
        return nullptr;

    SkBitmap bitmap;
    const auto tileSize = getTileSize();
    // Create a bitmap that will be hold entire symbol (if target is empty)
    if (bitmap.isNull())
    {
        if (!bitmap.tryAllocPixels(SkImageInfo::MakeN32Premul(tileSize, tileSize)))
        {
            LogPrintf(OsmAnd::LogSeverityLevel::Error,
                      "Failed to allocate bitmap of size %dx%d",
                      tileSize,
                      tileSize);
            return nullptr;
        }
        
        bitmap.eraseColor(SK_ColorTRANSPARENT);
    }
    SkBitmapDevice target(bitmap);
    SkCanvas canvas(&target);
    
    drawLines(req, tileId, geometryTile, canvas);
    if (req.zoom >= getPointsZoom())
        drawPoints(req, tileId, geometryTile, canvas);
    
    canvas.flush();
    
    SkAutoTUnref<SkData> data(SkImageEncoder::EncodeData(bitmap, SkImageEncoder::kPNG_Type, 100));
    if (NULL == data.get())
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
                  "Failed to encode bitmap of size %dx%d",
                  tileSize,
                  tileSize);
        return nullptr;
    }
    return QByteArray(reinterpret_cast<const char *>(data->bytes()), (int) data->size());
}

QByteArray OAMapillaryTilesProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& req)
{
    // Check provider can supply this zoom level
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
        return nullptr;
    
    return req.zoom > _rasterZoomLevel ? getVectorTileImage(req) : getRasterTileImage(req);
}

QByteArray OAMapillaryTilesProvider::getRasterTileImage(const OsmAnd::IMapTiledDataProvider::Request& req)
{
    QReadLocker scopedLocker(&_localCacheLock);

    // Check if requested tile is already being processed, and wait until that's done
    // to mark that as being processed.
    lockTile(req.tileId, req.zoom);

    const auto rasterTileRelativePath =
    QString::number(req.zoom) + QDir::separator() +
    QString::number(req.tileId.x) + QDir::separator() +
    QString::number(req.tileId.y) + QLatin1String(".png");
    
    QFileInfo rasterFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        rasterFile.setFile(QDir(_rasterLocalCachePath).absoluteFilePath(rasterTileRelativePath));
    }
    if (rasterFile.exists())
    {
        unlockTile(req.tileId, req.zoom);

        // If local file is empty, it means that requested tile does not exist (has no data)
        if (rasterFile.size() == 0)
            return nullptr;
        
        QFile tileFile(rasterFile.absoluteFilePath());
        if (tileFile.open(QIODevice::ReadOnly))
        {
            const auto& data = tileFile.readAll();
            tileFile.close();
            return data;
        }
        return nullptr;
    }
    
    // Perform synchronous download
    const auto tileUrl = QString(_rasterUrlPattern)
    .replace(QLatin1String("${osm_zoom}"), QString::number(req.zoom))
    .replace(QLatin1String("${osm_x}"), QString::number(req.tileId.x))
    .replace(QLatin1String("${osm_y}"), QString::number(req.tileId.y));
    
    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
    const auto& downloadResult = _webClient->downloadData(tileUrl, &requestResult, nullptr, req.queryController);

    // Ensure that all directories are created in path to local tile
    rasterFile.dir().mkpath(QLatin1String("."));
    
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
            
            // 404 means that this tile does not exist, so create a zero file
            if (httpStatus == 404)
            {
                // Save to a file
                QFile tileFile(rasterFile.absoluteFilePath());
                if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                {
                    tileFile.close();
                    
                    // Unlock the tile
                    unlockTile(req.tileId, req.zoom);
                    requestResult.reset();
                    return nullptr;
                }
                else
                {
                    LogPrintf(OsmAnd::LogSeverityLevel::Error,
                              "Failed to mark tile as non-existent with empty file '%s'",
                              qPrintable(rasterFile.absoluteFilePath()));
                    
                    // Unlock the tile
                    unlockTile(req.tileId, req.zoom);
                    requestResult.reset();
                    return nullptr;
                }
            }
        }
        // Unlock the tile
        unlockTile(req.tileId, req.zoom);
        requestResult.reset();
        return nullptr;
    }
    
    // Obtain all data
    LogPrintf(OsmAnd::LogSeverityLevel::Debug,
              "Downloaded tile from %s",
              qPrintable(tileUrl));
    
    // Save to a file
    QFile tileFile(rasterFile.absoluteFilePath());
    if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        tileFile.write(downloadResult);
        tileFile.close();
        
        LogPrintf(OsmAnd::LogSeverityLevel::Debug,
                  "Saved tile from %s to %s",
                  qPrintable(tileUrl),
                  qPrintable(rasterFile.absoluteFilePath()));
    }
    else
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
                  "Failed to save tile to '%s'",
                  qPrintable(rasterFile.absoluteFilePath()));
    }
    
    // Unlock the tile
    unlockTile(req.tileId, req.zoom);
    return downloadResult;
}

QByteArray OAMapillaryTilesProvider::getVectorTileImage(const OsmAnd::IMapTiledDataProvider::Request& req)
{
    QReadLocker scopedLocker(&_localCacheLock);

    const unsigned int absZoomShift = req.zoom - _vectorZoomLevel;
    const auto tileId = OsmAnd::Utilities::getTileIdOverscaledByZoomShift(req.tileId, absZoomShift);
    //const auto tileIds = OsmAnd::Utilities::getTileIdsUnderscaledByZoomShift(req.tileId, absZoomShift);
    // Check if requested tile is already being processed, and wait until that's done
    // to mark that as being processed.
    lockTile(req.tileId, req.zoom);

    const auto rasterTileRelativePath =
    QLatin1String("png") +  QDir::separator() +
    QString::number(req.zoom) + QDir::separator() +
    QString::number(req.tileId.x) + QDir::separator() +
    QString::number(req.tileId.y) + QLatin1String(".png");
    
    QFileInfo rasterFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        rasterFile.setFile(QDir(_vectorLocalCachePath).absoluteFilePath(rasterTileRelativePath));
    }
    if (rasterFile.exists())
    {
        unlockTile(req.tileId, req.zoom);

        if (rasterFile.size() == 0)
            return nullptr;

        QFile tileFile(rasterFile.absoluteFilePath());
        if (tileFile.open(QIODevice::ReadOnly))
        {
            const auto& data = tileFile.readAll();
            tileFile.close();
            return data;
        }
        return nullptr;
    }
    
    QMutexLocker vectorTileLocker(&_vectorTileMutex);

    if (req.queryController->isAborted()) {
        unlockTile(req.tileId, req.zoom);
        return nullptr;
    }
    if (rasterFile.exists())
    {
        unlockTile(req.tileId, req.zoom);

        if (rasterFile.size() == 0)
            return nullptr;

        QFile tileFile(rasterFile.absoluteFilePath());
        if (tileFile.open(QIODevice::ReadOnly))
        {
            const auto& data = tileFile.readAll();
            tileFile.close();
            return data;
        }
        return nullptr;
    }
    
    // Check if requested tile is already in local storage.
    const auto tileLocalRelativePath =
    QString::number(_vectorZoomLevel) + QDir::separator() +
    QString::number(tileId.x) + QDir::separator() +
    QString::number(tileId.y) + QLatin1String(".mvt");
    
    QFileInfo localFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        localFile.setFile(QDir(_vectorLocalCachePath).absoluteFilePath(tileLocalRelativePath));
    }
    if (localFile.exists())
    {
        // If local file is empty, it means that requested tile does not exist (has no data)
        if (localFile.size() == 0)
        {
            unlockTile(req.tileId, req.zoom);
            return nullptr;
        }
        
        const auto& geometryTile = readGeometry(localFile, tileId);

        const auto& data = !geometryTile->empty() ? drawTile(geometryTile, tileId, req) : nullptr;
        if (data != nullptr)
        {
            QFile tileFile(rasterFile.absoluteFilePath());
            // Ensure that all directories are created in path to local tile
            rasterFile.dir().mkpath(QLatin1String("."));
            if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
            {
                tileFile.write(data);
                tileFile.close();
                
                LogPrintf(OsmAnd::LogSeverityLevel::Debug,
                          "Saved mapillary png tile to %s",
                          qPrintable(rasterFile.absoluteFilePath()));
            }
            else
            {
                LogPrintf(OsmAnd::LogSeverityLevel::Error,
                          "Failed to save mapillary png tile to '%s'",
                          qPrintable(rasterFile.absoluteFilePath()));
            }
        }
        // Unlock tile, since local storage work is done
        unlockTile(req.tileId, req.zoom);
        
        return data;
    }
    
    // Since tile is not in local cache (or cache is disabled, which is the same),
    // the tile must be downloaded from network:
    
    // If network access is disallowed, return failure
    if (!_networkAccessAllowed)
    {
        // Before returning, unlock tile
        unlockTile(req.tileId, req.zoom);
        return nullptr;
    }
    
    // Perform synchronous download
    const auto tileUrl = QString(_vectorUrlPattern)
    .replace(QLatin1String("${osm_zoom}"), QString::number(_vectorZoomLevel))
    .replace(QLatin1String("${osm_x}"), QString::number(tileId.x))
    .replace(QLatin1String("${osm_y}"), QString::number(tileId.y));
    
    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
    const auto& downloadResult = _webClient->downloadData(tileUrl, &requestResult, nullptr, req.queryController);
    
    // Ensure that all directories are created in path to local tile
    localFile.dir().mkpath(QLatin1String("."));
    
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
            
            // 404 means that this tile does not exist, so create a zero file
            if (httpStatus == 404)
            {
                // Save to a file
                QFile tileFile(localFile.absoluteFilePath());
                if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                {
                    tileFile.close();
                    
                    // Unlock the tile
                    unlockTile(req.tileId, req.zoom);
                    requestResult.reset();
                    return nullptr;
                }
                else
                {
                    LogPrintf(OsmAnd::LogSeverityLevel::Error,
                              "Failed to mark tile as non-existent with empty file '%s'",
                              qPrintable(localFile.absoluteFilePath()));
                    
                    // Unlock the tile
                    unlockTile(req.tileId, req.zoom);
                    requestResult.reset();
                    return nullptr;
                }
            }
        }
        // Unlock the tile
        unlockTile(req.tileId, req.zoom);
        requestResult.reset();
        return nullptr;
    }
    
    // Obtain all data
    LogPrintf(OsmAnd::LogSeverityLevel::Debug,
              "Downloaded tile from %s",
              qPrintable(tileUrl));
    
    // Save to a file
    QFile tileFile(localFile.absoluteFilePath());
    if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        tileFile.write(downloadResult);
        tileFile.close();
        
        LogPrintf(OsmAnd::LogSeverityLevel::Debug,
                  "Saved tile from %s to %s",
                  qPrintable(tileUrl),
                  qPrintable(localFile.absoluteFilePath()));
    }
    else
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
                  "Failed to save tile to '%s'",
                  qPrintable(localFile.absoluteFilePath()));
    }
        
    requestResult.reset();

    const auto& geometryTile = readGeometry(localFile, tileId);
    const auto& data = drawTile(geometryTile, tileId, req);
    if (data != nullptr)
    {
        QFile tileFile(rasterFile.absoluteFilePath());
        // Ensure that all directories are created in path to local tile
        rasterFile.dir().mkpath(QLatin1String("."));
        if (tileFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
        {
            tileFile.write(data);
            tileFile.close();
            
            LogPrintf(OsmAnd::LogSeverityLevel::Debug,
                      "Saved mapillary png tile to %s",
                      qPrintable(rasterFile.absoluteFilePath()));
        }
        else
        {
            LogPrintf(OsmAnd::LogSeverityLevel::Error,
                      "Failed to save mapillary png tile to '%s'",
                      qPrintable(rasterFile.absoluteFilePath()));
        }
    }
    // Unlock tile, since local storage work is done
    unlockTile(req.tileId, req.zoom);

    return data;
}

void OAMapillaryTilesProvider::obtainImageAsync(
                                                const OsmAnd::IMapTiledDataProvider::Request& request,
                                                const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage)
{
    //
}

OsmAnd::MapStubStyle OAMapillaryTilesProvider::getDesiredStubsStyle() const
{
    return OsmAnd::MapStubStyle::Unspecified;
}

float OAMapillaryTilesProvider::getTileDensityFactor() const
{
    return 1.0f;
}

uint32_t OAMapillaryTilesProvider::getTileSize() const
{
    return 256 * _displayDensityFactor;
}

bool OAMapillaryTilesProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OAMapillaryTilesProvider::supportsNaturalObtainDataAsync() const
{
    return true;
}

OsmAnd::ZoomLevel OAMapillaryTilesProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel0;
}

OsmAnd::ZoomLevel OAMapillaryTilesProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel21;
}

void OAMapillaryTilesProvider::lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    while(_tilesInProcess[zoom].contains(tileId))
        _waitUntilAnyTileIsProcessed.wait(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].insert(tileId);
}

void OAMapillaryTilesProvider::unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].remove(tileId);
    
    _waitUntilAnyTileIsProcessed.wakeAll();
}

void OAMapillaryTilesProvider::setLocalCachePath(
                                                 const QString& localCachePath)
{
    QMutexLocker scopedLocker(&_localCachePathMutex);
    _vectorLocalCachePath = QDir(localCachePath).absoluteFilePath(_vectorPathSuffix);
    _rasterLocalCachePath = QDir(localCachePath).absoluteFilePath(_rasterPathSuffix);
}

OsmAnd::ZoomLevel OAMapillaryTilesProvider::getPointsZoom() const
{
    return OsmAnd::ZoomLevel16;
}

OsmAnd::ZoomLevel OAMapillaryTilesProvider::getRasterTileZoom() const
{
    return _rasterZoomLevel;
}

OsmAnd::ZoomLevel OAMapillaryTilesProvider::getVectorTileZoom() const
{
    return _vectorZoomLevel;
}

void OAMapillaryTilesProvider::performAdditionalChecks(std::shared_ptr<const SkBitmap> bitmap)
{
}
