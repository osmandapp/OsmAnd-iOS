//
//  OAMapillaryTilesProvider.h
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/stdlib_common.h>
#include <functional>
#include <array>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QList>
#include <QVector>
#include <QVariant>
#include <QHash>
#include <QFileInfo>
#include <OsmAndCore/restore_internal_warnings.h>
#include <QWaitCondition>
#include <QReadWriteLock>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Nullable.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/MvtReader.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>
#include <OsmAndCore/IWebClient.h>

class SkCanvas;
class SkPaint;

class OAMapillaryTilesProvider : public OsmAnd::ImageMapLayerProvider
{
    
private:
    const QString _vectorName;
    const QString _vectorPathSuffix;
    const QString _vectorUrlPattern;
    const OsmAnd::ZoomLevel _vectorZoomLevel;
    QString _vectorLocalCachePath;

    mutable QReadWriteLock _localCacheLock;
    mutable QMutex _localCachePathMutex;
    mutable QMutex _geometryCacheMutex;
    mutable QMutex _vectorTileMutex;

    QHash<OsmAnd::TileId, std::shared_ptr<const OsmAnd::MvtReader::Tile> > _geometryCache;
    const std::shared_ptr<const OsmAnd::IWebClient> _webClient;
    const std::shared_ptr<SkBitmap> _image;
    const std::shared_ptr<SkPaint> _linePaint;

    bool _networkAccessAllowed;
    float _displayDensityFactor;
    unsigned long long _physicalMemory;
    int _maxCacheSize;

    mutable QMutex _tilesInProcessMutex;
    std::array< QSet< OsmAnd::TileId >, OsmAnd::ZoomLevelsCount > _tilesInProcess;
    QWaitCondition _waitUntilAnyTileIsProcessed;
    
    void lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    void unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    
    std::shared_ptr<const OsmAnd::MvtReader> _mvtReader;
    
    void clearMemoryCacheImpl(const bool clearAll = false);

    std::shared_ptr<const OsmAnd::MvtReader::Tile> readGeometry(const QFileInfo &localFile,
                                                                const OsmAnd::TileId &tileId);
    QByteArray drawTile(const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                        const OsmAnd::TileId &tileId,
                        const OsmAnd::IMapTiledDataProvider::Request& req);

    void drawPoints(const OsmAnd::IMapTiledDataProvider::Request &req,
                    const OsmAnd::TileId &tileId,
                    const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                    SkCanvas& canvas);
    
    void drawLine(const std::shared_ptr<const OsmAnd::MvtReader::LineString> &line,
                  const OsmAnd::IMapTiledDataProvider::Request &req,
                  const OsmAnd::TileId &tileId,
                  SkCanvas& canvas);
    
    void drawLines(const OsmAnd::IMapTiledDataProvider::Request &req,
                   const OsmAnd::TileId &tileId,
                   const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile,
                   SkCanvas& canvas);
    
    QByteArray getVectorTileImage(const OsmAnd::IMapTiledDataProvider::Request& req);
    
    virtual void performAdditionalChecks(std::shared_ptr<const SkBitmap> bitmap);
    
    OsmAnd::ZoomLevel getZoomForRequest(const OsmAnd::IMapTiledDataProvider::Request &req);

protected:
public:
    OAMapillaryTilesProvider(const float displayDensityFactor = 1.0f, const unsigned long long physicalMemory = 0);
    virtual ~OAMapillaryTilesProvider();
    
    virtual QByteArray obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual void obtainImageAsync(
                                  const OsmAnd::IMapTiledDataProvider::Request& request,
                                  const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage);
    
    virtual OsmAnd::AlphaChannelPresence getAlphaChannelPresence() const;
    virtual OsmAnd::MapStubStyle getDesiredStubsStyle() const;
    
    virtual float getTileDensityFactor() const;
    virtual uint32_t getTileSize() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool supportsNaturalObtainDataAsync() const;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
    
    void setLocalCachePath(const QString& localCachePath);
    
    OsmAnd::ZoomLevel getVectorTileZoom() const;

    std::shared_ptr<const OsmAnd::MvtReader::Tile> readGeometry(const OsmAnd::TileId &tileId);

    OsmAnd::ZoomLevel getPointsZoom() const;

    void clearMemoryCache(const bool clearAll = false);
    void clearDiskCache(bool vectorRasterOnly = false);
    
    bool filtered(const QHash<uint8_t, QVariant> &userData, const std::shared_ptr<const OsmAnd::MvtReader::Tile>& geometryTile) const;
};
