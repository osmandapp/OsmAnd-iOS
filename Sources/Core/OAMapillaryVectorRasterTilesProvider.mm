//
//  OAMapillaryVectorRasterTilesProvider.m
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include "OAMapillaryVectorRasterTilesProvider.h"
#import "OANativeUtilities.h"
#import "OAColors.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Utilities.h>
#include <QStandardPaths>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/IWebClient.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/IAtlasMapRenderer.h>
#include "Logging.h"
#include "OAWebClient.h"
#include <SkImageEncoder.h>
#include <SkBitmapDevice.h>
#include <SkCanvas.h>
#include <SkBitmap.h>
#include <SkData.h>

#define EXTENT 4096.0
#define TILE_ZOOM 14
#define MAX_CACHE_SIZE 10

OAMapillaryVectorRasterTilesProvider::OAMapillaryVectorRasterTilesProvider(const float displayDensityFactor /* = 1.0f*/)
: name(QStringLiteral("mapillary_vect"))
, pathSuffix(QString(name).replace(QRegExp(QLatin1String("\\W+")), QLatin1String("_")))
, urlPattern(QStringLiteral("https://d25uarhxywzl1j.cloudfront.net/v0.1/${osm_zoom}/${osm_x}/${osm_y}.mvt"))
//https://d6a1v2w10ny40.cloudfront.net/v0.1/{0}/{1}/{2}.png
, webClient(std::shared_ptr<const OsmAnd::IWebClient>(new OsmAnd::WebClient()))
, _networkAccessAllowed(true)
, _displayDensityFactor(displayDensityFactor)
, mvtReader(new OsmAnd::MvtReader())
, icon([OANativeUtilities skBitmapFromPngResource:@"map_mapillary_photo_dot"])
{
    _localCachePath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation)).absoluteFilePath(pathSuffix);
    if (_localCachePath.isEmpty())
        _localCachePath = QLatin1String(".");
}

OAMapillaryVectorRasterTilesProvider::~OAMapillaryVectorRasterTilesProvider()
{
}

OsmAnd::AlphaChannelPresence OAMapillaryVectorRasterTilesProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

void OAMapillaryVectorRasterTilesProvider::drawPoints(
                      const OsmAnd::IMapTiledDataProvider::Request &req,
                      const OsmAnd::TileId &tileId,
                      const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &geometry,
                      SkCanvas& canvas)
{
    int dzoom = req.zoom - TILE_ZOOM;
    double mult = (int) pow(2.0, dzoom);
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    const auto& tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    const auto tileSize = getTileSize();
    const auto px31Size = tileSize31 / tileSize;
    const auto bitmapHalfSize = icon->width() / 2;
    const auto& tileBBox31Enlarged = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom).enlargeBy(bitmapHalfSize * px31Size);
    
    for (const auto& point : geometry)
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
            //            if (settings.USE_MAPILLARY_FILTER.get()) {
            //                if (filtered(p.getUserData())) continue;
            //            }
            SkScalar x = ((tileX - tileBBox31.left()) / tileSize31) * tileSize - bitmapHalfSize;
            SkScalar y = ((tileY - tileBBox31.top()) / tileSize31) * tileSize - bitmapHalfSize;
            canvas.drawBitmap(*icon, x, y);
        }
    }
}

void OAMapillaryVectorRasterTilesProvider::drawLine(
                                                    const std::shared_ptr<const OsmAnd::MvtReader::LineString> &line,
                                                    const OsmAnd::IMapTiledDataProvider::Request &req,
                                                    const OsmAnd::TileId &tileId,
                                                    SkCanvas& canvas)
{
    int dzoom = req.zoom - TILE_ZOOM;
    int mult = (int) pow(2.0, dzoom);
    double px, py;
    const auto &linePts = line->getCoordinateSequence();
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    const auto& tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    const auto tileSize = getTileSize();

    SkPaint paint;
    paint.setColor(OsmAnd::ColorARGB(mapillary_color).toSkColor());
    paint.setStrokeWidth(3 * _displayDensityFactor);
    paint.setAntiAlias(true);
    paint.setStrokeJoin(SkPaint::kRound_Join);
    paint.setStrokeCap(SkPaint::kRound_Cap);
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
        if (!first)
            canvas.drawLine(x1, y1, x2, y2, paint);
        else
            first = false;
        
        x1 = x2;
        y1 = y2;
    }
}

void OAMapillaryVectorRasterTilesProvider::drawLines(
                                                     const OsmAnd::IMapTiledDataProvider::Request &req,
                                                     const OsmAnd::TileId &tileId,
                                                     const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &geometry,
                                                     SkCanvas& canvas)
{
    for (const auto& point : geometry)
    {
        if (point == nullptr || (point->getType() != OsmAnd::MvtReader::GeomType::LINE_STRING && point->getType() != OsmAnd::MvtReader::GeomType::MULTI_LINE_STRING))
            continue;
        
        if (point->getType() == OsmAnd::MvtReader::GeomType::LINE_STRING)
        {
            const auto& line = std::dynamic_pointer_cast<const OsmAnd::MvtReader::LineString>(point);
            drawLine(line, req, tileId, canvas);
        }
        else
        {
            const auto& multiline = std::dynamic_pointer_cast<const OsmAnd::MvtReader::MultiLineString>(point);
            for (const auto &lineString : multiline->getLines())
                drawLine(lineString, req, tileId, canvas);
        }
    }
}

void OAMapillaryVectorRasterTilesProvider::clearCache()
{
    QMutexLocker scopedLocker(&_geometryCacheMutex);

    clearCacheImpl();
}

void OAMapillaryVectorRasterTilesProvider::clearCacheImpl()
{
    auto it = geometryCache.begin();
    auto i = geometryCache.size() / 2;
    while (it != geometryCache.end() && i > 0) {
        it = geometryCache.erase(it);
        i--;
    }
}

QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > OAMapillaryVectorRasterTilesProvider::readGeometry(
                                                                                                          const QFileInfo &localFile,
                                                                                                          const OsmAnd::TileId &tileId)
{
    return mvtReader->parseTile(localFile.absoluteFilePath());
    
    QMutexLocker scopedLocker(&_geometryCacheMutex);

    auto it = geometryCache.constFind(tileId);
    if (it == geometryCache.cend())
        it = geometryCache.insert(tileId, mvtReader->parseTile(localFile.absoluteFilePath()));
    
    auto list = *it;
    
    if (geometryCache.size() > MAX_CACHE_SIZE)
        clearCacheImpl();
    
    return list;
}

QByteArray OAMapillaryVectorRasterTilesProvider::drawTile(const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &geometry,
                                                          const OsmAnd::TileId &tileId,
                                                          const OsmAnd::IMapTiledDataProvider::Request &req)
{
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
    
    drawLines(req, tileId, geometry, canvas);
    if (req.zoom > OsmAnd::ZoomLevel15)
        drawPoints(req, tileId, geometry, canvas);

    canvas.flush();
    
    SkImageEncoder* enc = SkImageEncoder::Create(SkImageEncoder::kPNG_Type);
    SkData* data = enc->encodeData(bitmap, 100);
    if (data == NULL)
    {
        LogPrintf(OsmAnd::LogSeverityLevel::Error,
                  "Failed to encode bitmap of size %dx%d",
                  tileSize,
                  tileSize);
        return nullptr;
    }
    
    return QByteArray::fromRawData(reinterpret_cast<const char*>(data->bytes()), (int) data->size());
}

QByteArray OAMapillaryVectorRasterTilesProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& req)
{
    // Check provider can supply this zoom level
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
        return nullptr;
    
    // Check if requested tile is already being processed, and wait until that's done
    // to mark that as being processed.
    lockTile(req.tileId, req.zoom);
    
    const unsigned int absZoomShift = req.zoom - TILE_ZOOM;
    OsmAnd::TileId tileId = OsmAnd::Utilities::getTileIdOverscaledByZoomShift(req.tileId, absZoomShift);
    
    const auto rasterTileRelativePath =
        QLatin1String("png") +  QDir::separator() +
        QString::number(req.zoom) + QDir::separator() +
        QString::number(req.tileId.x) + QDir::separator() +
        QString::number(req.tileId.y) + QLatin1String(".png");
    
    QFileInfo rasterFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        rasterFile.setFile(QDir(_localCachePath).absoluteFilePath(rasterTileRelativePath));
    }
    if (rasterFile.exists())
    {
        QFile tileFile(rasterFile.absoluteFilePath());
        if (tileFile.open(QIODevice::ReadOnly))
        {
            unlockTile(req.tileId, req.zoom);

            auto data = tileFile.readAll();
            tileFile.close();
            return data;
        }
    }

    // Check if requested tile is already in local storage.
    const auto tileLocalRelativePath =
        QString::number(TILE_ZOOM) + QDir::separator() +
        QString::number(tileId.x) + QDir::separator() +
        QString::number(tileId.y) + QLatin1String(".mvt");
    
    QFileInfo localFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        localFile.setFile(QDir(_localCachePath).absoluteFilePath(tileLocalRelativePath));
    }
    if (localFile.exists())
    {
        // If local file is empty, it means that requested tile does not exist (has no data)
        if (localFile.size() == 0)
        {
            unlockTile(req.tileId, req.zoom);
            return nullptr;
        }
        
        auto geometry = readGeometry(localFile, tileId);
        auto data = !geometry.empty() ? drawTile(geometry, tileId, req) : nullptr;
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
    const auto tileUrl = QString(urlPattern)
        .replace(QLatin1String("${osm_zoom}"), QString::number(TILE_ZOOM))
        .replace(QLatin1String("${osm_x}"), QString::number(tileId.x))
        .replace(QLatin1String("${osm_y}"), QString::number(tileId.y));
    
    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
    const auto& downloadResult = webClient->downloadData(tileUrl, &requestResult);
    
    // Ensure that all directories are created in path to local tile
    localFile.dir().mkpath(QLatin1String("."));
    
    // If there was error, check what the error was
    if (!requestResult->isSuccessful())
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
                return nullptr;
            }
            else
            {
                LogPrintf(OsmAnd::LogSeverityLevel::Error,
                          "Failed to mark tile as non-existent with empty file '%s'",
                          qPrintable(localFile.absoluteFilePath()));
                
                // Unlock the tile
                unlockTile(req.tileId, req.zoom);
                return nullptr;
            }
        }
        
        // Unlock the tile
        unlockTile(req.tileId, req.zoom);
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
    
    auto geometry = readGeometry(localFile, tileId);
    auto data = !geometry.empty() ? drawTile(geometry, tileId, req) : nullptr;
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

void OAMapillaryVectorRasterTilesProvider::obtainImageAsync(
                                                   const OsmAnd::IMapTiledDataProvider::Request& request,
                                                   const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage)
{
    //
}

OsmAnd::MapStubStyle OAMapillaryVectorRasterTilesProvider::getDesiredStubsStyle() const
{
    return OsmAnd::MapStubStyle::Unspecified;
}

float OAMapillaryVectorRasterTilesProvider::getTileDensityFactor() const
{
    return 1.0f;
}

uint32_t OAMapillaryVectorRasterTilesProvider::getTileSize() const
{
    return 256 * _displayDensityFactor;
}

bool OAMapillaryVectorRasterTilesProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OAMapillaryVectorRasterTilesProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

OsmAnd::ZoomLevel OAMapillaryVectorRasterTilesProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel14;
}

OsmAnd::ZoomLevel OAMapillaryVectorRasterTilesProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel21;
}

void OAMapillaryVectorRasterTilesProvider::lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    while(_tilesInProcess[zoom].contains(tileId))
        _waitUntilAnyTileIsProcessed.wait(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].insert(tileId);
}

void OAMapillaryVectorRasterTilesProvider::unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].remove(tileId);
    
    _waitUntilAnyTileIsProcessed.wakeAll();
}

void OAMapillaryVectorRasterTilesProvider::setLocalCachePath(
                                                       const QString& localCachePath,
                                                       const bool appendPathSuffix /*= true*/)
{
    QMutexLocker scopedLocker(&_localCachePathMutex);
    _localCachePath = appendPathSuffix ? QDir(localCachePath).absoluteFilePath(pathSuffix) : localCachePath;
}
