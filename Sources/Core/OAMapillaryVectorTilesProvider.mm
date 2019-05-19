//
//  OAMapillaryVectorTilesProvider.m
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryVectorTilesProvider.h"
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
#include "Logging.h"
#include "OAWebClient.h"

#define EXTENT 4096.0
#define TILE_ZOOM 14

OAMapillaryVectorTilesProvider::OAMapillaryVectorTilesProvider(
                                                               const QString& name_,
                                                               const QString& urlPattern_,
                                                               const OsmAnd::ZoomLevel minZoom_ /*= MinZoomLevel*/,
                                                               const OsmAnd::ZoomLevel maxZoom_ /*= MaxZoomLevel*/,
                                                               const uint32_t maxConcurrentDownloads_ /*= 1*/,
                                                               const uint32_t tileSize_ /*= 256*/,
                                                               const float tileDensityFactor_ /*= 1.0f*/,
                                                               const std::shared_ptr<const OsmAnd::IWebClient>& webClient /*= std::shared_ptr<const IWebClient>(new WebClient())*/,
                                                               const bool networkAccessAllowed /*true*/)
: _lastRequestedZoom(OsmAnd::ZoomLevel0)
, _priority(0)
, name(name_)
, pathSuffix(QString(name).replace(QRegExp(QLatin1String("\\W+")), QLatin1String("_")))
, urlPattern(urlPattern_)
, minZoom(minZoom_)
, maxZoom(maxZoom_)
, maxConcurrentDownloads(maxConcurrentDownloads_)
, tileSize(tileSize_)
, tileDensityFactor(tileDensityFactor_)
, webClient(webClient)
, _networkAccessAllowed(true)
, mvtReader(new OsmAnd::MvtReader())
, icon([OANativeUtilities skBitmapFromPngResource:@"map_mapillary_photo_dot"])
{
    _localCachePath = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation)).absoluteFilePath(pathSuffix);
    if (_localCachePath.isEmpty())
        _localCachePath = QLatin1String(".");
}

OAMapillaryVectorTilesProvider::~OAMapillaryVectorTilesProvider()
{
}

OsmAnd::ZoomLevel OAMapillaryVectorTilesProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel14;
}

OsmAnd::ZoomLevel OAMapillaryVectorTilesProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel21;
}

bool OAMapillaryVectorTilesProvider::supportsNaturalObtainData() const
{
    return true;
}

void OAMapillaryVectorTilesProvider::getPointSymbols(const QFileInfo &localFile,
                                                     const OsmAnd::IMapTiledSymbolsProvider::Request &req,
                                                     const OsmAnd::TileId &tileId,
                                                     QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,
                                                     const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &list) {
    
    int dzoom = req.zoom - TILE_ZOOM;
    int mult = (int) pow(2.0, dzoom);
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    const auto& tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    const auto px31Size = (uint32_t)(tileSize31 / (tileSize * tileDensityFactor));
    
    const auto bitmapSize31 = icon->width() * px31Size;
    QList<OsmAnd::AreaI> bitmapBBoxes;
    bitmapBBoxes << OsmAnd::AreaI(0, -bitmapSize31, tileBBox31.bottom(), 0);
    bitmapBBoxes << OsmAnd::AreaI(-bitmapSize31, 0, 0, tileBBox31.right());
    bitmapBBoxes << OsmAnd::AreaI(0, tileBBox31.right(), tileBBox31.bottom(), tileBBox31.right() + bitmapSize31);
    bitmapBBoxes << OsmAnd::AreaI(tileBBox31.bottom(), 0, tileBBox31.bottom() + bitmapSize31, tileBBox31.right());

    const auto mapSymbolsGroup = std::make_shared<OsmAnd::MapSymbolsGroup>();
    for (const auto& point : list)
    {
        if (point == nullptr || point->getType() != OsmAnd::MvtReader::GeomType::POINT)
            continue;
        const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
        mapSymbol->order = -120000;
        mapSymbol->bitmap = icon;
        mapSymbol->size = OsmAnd::PointI(
                                         icon->width(),
                                         icon->height());
        mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
        double px, py;
        const auto& p = std::dynamic_pointer_cast<const OsmAnd::MvtReader::Point>(point);
        OsmAnd::PointI coordinate = p->getCoordinate();
        px = coordinate.x / EXTENT;
        py = coordinate.y / EXTENT;
        
        double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
        double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
        
        if (tileBBox31.contains(tileX, tileY)) {
            //            if (settings.USE_MAPILLARY_FILTER.get()) {
            //                if (filtered(p.getUserData())) continue;
            //            }
            OsmAnd::PointI coord(tileX, tileY);
            const auto bitmapBBox31 = OsmAnd::AreaI::fromCenterAndSize(coord.x, coord.y, bitmapSize31, bitmapSize31);
            bool intersects = false;
            for (const auto& bbox31 : bitmapBBoxes)
            {
                if (bbox31.intersects(bitmapBBox31))
                {
                    intersects = true;
                    break;
                }
            }
            //if (!intersects)
            //{
                mapSymbol->position31 = coord;
                mapSymbolsGroup->symbols.push_back(mapSymbol);
                bitmapBBoxes << bitmapBBox31;
            //}
        }
    }
    mapSymbolsGroups.push_back(mapSymbolsGroup);
}

void OAMapillaryVectorTilesProvider::buildLine(const std::shared_ptr<const OsmAnd::MvtReader::LineString> &line, QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,  const OsmAnd::IMapTiledSymbolsProvider::Request &req, const OsmAnd::TileId &tileId) {
    int dzoom = req.zoom - TILE_ZOOM;
    int mult = (int) pow(2.0, dzoom);
    double px, py;
    const auto &linePts = line->getCoordinateSequence();
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom));
    const auto zoomShift = OsmAnd::ZoomLevel::MaxZoomLevel - req.zoom;
    QVector<OsmAnd::PointI> points;
    for (const auto &point : linePts)
    {
        px = point.x / EXTENT;
        py = point.y / EXTENT;
        
        double tileX = ((tileId.x << zoomShift) + (tileSize31 * px)) * mult;
        double tileY = ((tileId.y << zoomShift) + (tileSize31 * py)) * mult;
        
        points << OsmAnd::PointI(tileX, tileY);
    }
    OsmAnd::VectorLineBuilder builder;
    builder.setBaseOrder(-110000)
    .setIsHidden(false)
    .setLineWidth(15)
    .setPoints(points)
    .setFillColor(OsmAnd::ColorARGB(mapillary_color));

    const auto vectorLine = builder.build();
    mapSymbolsGroups.push_back(vectorLine->createSymbolsGroup(req.mapState));
}

void OAMapillaryVectorTilesProvider::getLines(const QFileInfo &localFile,
                                              const OsmAnd::IMapTiledSymbolsProvider::Request &req,
                                              const OsmAnd::TileId &tileId,
                                              QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,
                                              const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &list)
{
    for (const auto& point : list)
    {
        if (point == nullptr || (point->getType() != OsmAnd::MvtReader::GeomType::LINE_STRING && point->getType() != OsmAnd::MvtReader::GeomType::MULTI_LINE_STRING))
            continue;
        
        if (point->getType() == OsmAnd::MvtReader::GeomType::LINE_STRING)
        {
            const auto& line = std::dynamic_pointer_cast<const OsmAnd::MvtReader::LineString>(point);
            buildLine(line, mapSymbolsGroups, req, tileId);
        }
        else
        {
            const auto& multiline = std::dynamic_pointer_cast<const OsmAnd::MvtReader::MultiLineString>(point);
            for (const auto &lineString : multiline->getLines())
            {
                buildLine(lineString, mapSymbolsGroups, req, tileId);
            }
        }
    }
}

bool OAMapillaryVectorTilesProvider::obtainData(
                                                const IMapDataProvider::Request& request,
                                                std::shared_ptr<IMapDataProvider::Data>& outData,
                                                std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<OAMapillaryVectorTilesProvider::Request>(request);
    
    if (pOutMetric)
        pOutMetric->reset();
    
    // Check provider can supply this zoom level
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
    {
        outData.reset();
        return true;
    }
    
    // Check if requested tile is already being processed, and wait until that's done
    // to mark that as being processed.
    lockTile(req.tileId, req.zoom);

    const unsigned int absZoomShift = req.zoom - TILE_ZOOM;
    OsmAnd::TileId id = OsmAnd::Utilities::getTileIdOverscaledByZoomShift(req.tileId, absZoomShift);
    
    // Check if requested tile is already in local storage.
    const auto tileLocalRelativePath =
    QString::number(TILE_ZOOM) + QDir::separator() +
    QString::number(id.x) + QDir::separator() +
    QString::number(id.y) + QLatin1String(".mvt");
    QFileInfo localFile;
    {
        QMutexLocker scopedLocker(&_localCachePathMutex);
        localFile.setFile(QDir(_localCachePath).absoluteFilePath(tileLocalRelativePath));
    }
    if (localFile.exists())
    {
        // Since tile is in local storage, it's safe to unmark it as being processed
        unlockTile(req.tileId, req.zoom);

        // If local file is empty, it means that requested tile does not exist (has no data)
        if (localFile.size() == 0)
        {
            outData.reset();
            return true;
        }

        // Return tile
        QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > mapSymbolsGroups;
        QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > list = mvtReader->parseTile(localFile.absoluteFilePath());
        if (req.zoom > OsmAnd::ZoomLevel15)
            getPointSymbols(localFile, req, id, mapSymbolsGroups, list);
        getLines(localFile, req, id, mapSymbolsGroups, list);
        
        outData.reset(new OAMapillaryVectorTilesProvider::Data(
                                                               req.tileId,
                                                               req.zoom,
                                                               mapSymbolsGroups));

        return true;
    }

    // Since tile is not in local cache (or cache is disabled, which is the same),
    // the tile must be downloaded from network:

    // If network access is disallowed, return failure
    if (!_networkAccessAllowed)
    {
        // Before returning, unlock tile
        unlockTile(req.tileId, req.zoom);

        return false;
    }

    // Perform synchronous download
    const auto tileUrl = QString(urlPattern)
    .replace(QLatin1String("${osm_zoom}"), QString::number(TILE_ZOOM))
    .replace(QLatin1String("${osm_x}"), QString::number(id.x))
    .replace(QLatin1String("${osm_y}"), QString::number(id.y));
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
                return true;
            }
            else
            {
                LogPrintf(OsmAnd::LogSeverityLevel::Error,
                          "Failed to mark tile as non-existent with empty file '%s'",
                          qPrintable(localFile.absoluteFilePath()));

                // Unlock the tile
                unlockTile(req.tileId, req.zoom);
                return false;
            }
        }

        // Unlock the tile
        unlockTile(req.tileId, req.zoom);
        return false;
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
    
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > mapSymbolsGroups;
    QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > list = mvtReader->parseTile(localFile.absoluteFilePath());
    if (req.zoom > OsmAnd::ZoomLevel15)
        getPointSymbols(localFile, req, id, mapSymbolsGroups, list);
    getLines(localFile, req, id, mapSymbolsGroups, list);
    
    // Unlock tile, since local storage work is done
    unlockTile(req.tileId, req.zoom);
    
    // Return tile
    
    outData.reset(new OAMapillaryVectorTilesProvider::Data(
                                                           req.tileId,
                                                           req.zoom,
                                                           mapSymbolsGroups));
    return true;
    
}

bool OAMapillaryVectorTilesProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAMapillaryVectorTilesProvider::obtainDataAsync(
                                                     const IMapDataProvider::Request& request,
                                                     const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                     const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

void OAMapillaryVectorTilesProvider::lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    while(_tilesInProcess[zoom].contains(tileId))
        _waitUntilAnyTileIsProcessed.wait(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].insert(tileId);
}

void OAMapillaryVectorTilesProvider::unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QMutexLocker scopedLocker(&_tilesInProcessMutex);
    
    _tilesInProcess[zoom].remove(tileId);
    
    _waitUntilAnyTileIsProcessed.wakeAll();
}

void OAMapillaryVectorTilesProvider::setLocalCachePath(
                                                             const QString& localCachePath,
                                                             const bool appendPathSuffix /*= true*/)
{
    QMutexLocker scopedLocker(&_localCachePathMutex);
    _localCachePath = appendPathSuffix
    ? QDir(localCachePath).absoluteFilePath(pathSuffix)
    : localCachePath;
}

