//
//  OAMapillaryVectorTilesProvider.h
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <functional>
#include <array>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QList>
#include <OsmAndCore/restore_internal_warnings.h>
#include <QWaitCondition>
#include <QReadWriteLock>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Nullable.h>
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/Data/ObfPoiSectionReader.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/MvtReader.h>


class OAMapillaryVectorTilesProvider : public OsmAnd::IMapTiledSymbolsProvider
{
public:
private:
    const std::shared_ptr<const OsmAnd::IWebClient> webClient;
    const std::shared_ptr<SkBitmap> icon;
protected:
    mutable QMutex _localCachePathMutex;
    QString _localCachePath;
    bool _networkAccessAllowed;
    
    mutable QMutex _tilesInProcessMutex;
    std::array< QSet< OsmAnd::TileId >, OsmAnd::ZoomLevelsCount > _tilesInProcess;
    QWaitCondition _waitUntilAnyTileIsProcessed;
    
    void lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    void unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    
    std::shared_ptr<const OsmAnd::MvtReader> mvtReader;
    void getPointSymbols(const QFileInfo &localFile,
                         const OsmAnd::IMapTiledSymbolsProvider::Request &req,
                         const OsmAnd::TileId &tileId,
                         QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,
                         const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &list);
    void buildLine(const std::shared_ptr<const OsmAnd::MvtReader::LineString> &line, QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,  const OsmAnd::IMapTiledSymbolsProvider::Request &req, const OsmAnd::TileId &tileId);
    
    void getLines(const QFileInfo &localFile,
                  const OsmAnd::IMapTiledSymbolsProvider::Request &req,
                  const OsmAnd::TileId &tileId,
                  QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups,
                  const QList<std::shared_ptr<const OsmAnd::MvtReader::Geometry> > &list);
public:
    OAMapillaryVectorTilesProvider(
                                   const QString& name,
                                   const QString& urlPattern,
                                   const OsmAnd::ZoomLevel minZoom = OsmAnd::ZoomLevel4,
                                   const OsmAnd::ZoomLevel maxZoom = OsmAnd::ZoomLevel21,
                                   const unsigned int maxConcurrentDownloads = 1,
                                   const unsigned int tileSize = 256,
                                   const float tileDensityFactor = 1.0f,
                                   const std::shared_ptr<const OsmAnd::IWebClient>& webClient = std::shared_ptr<const OsmAnd::IWebClient>(new OsmAnd::WebClient()),
                                   const bool networkAccessAllowed = true);
    virtual ~OAMapillaryVectorTilesProvider();
    
    const QString name;
    const QString pathSuffix;
    QString urlPattern;
    const OsmAnd::ZoomLevel minZoom;
    const OsmAnd::ZoomLevel maxZoom;
    const unsigned int maxConcurrentDownloads;
    const unsigned int tileSize;
    const float tileDensityFactor;
    const QString localCachePath;
        
    mutable QReadWriteLock _lock;
    OsmAnd::ZoomLevel _lastRequestedZoom;
    int _priority;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
    
    virtual bool supportsNaturalObtainData() const override;
    QByteArray extracted(const OsmAnd::Area<int> &tileBBox31);

    virtual bool obtainData(
                            const IMapDataProvider::Request& request,
                            std::shared_ptr<IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr) override;
    
    virtual bool supportsNaturalObtainDataAsync() const override;
    virtual void obtainDataAsync(
                                 const IMapDataProvider::Request& request,
                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                 const bool collectMetric = false) override;
    
    void setLocalCachePath(const QString& localCachePath, const bool appendPathSuffix = true);
};

