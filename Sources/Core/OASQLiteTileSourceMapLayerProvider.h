//
//  OASQLiteTileSourceMapLayerProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//
#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>
#include <OsmAndCore/IWebClient.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>
#include <OsmAndCore/TileSqliteDatabase.h>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/stdlib_common.h>

#include <QWaitCondition>
#include <QReadWriteLock>
#include <QList>
#include <QHash>
#include <array>
#include <functional>
#include <QSet>


class OASQLiteTileSourceMapLayerProvider : public OsmAnd::ImageMapLayerProvider
{
private:
    const std::shared_ptr<const OsmAnd::IWebClient> _webClient;
    
    OsmAnd::TileSqliteDatabase *_ts;
    int _tileSize;
    bool _ellipsoid;
    int64_t _expirationTimeMillis;
    QList<QString> _randomsArray;
    
    mutable QMutex _tilesInProcessMutex;
    std::array< QSet< OsmAnd::TileId >, OsmAnd::ZoomLevelsCount > _tilesInProcess;
    QWaitCondition _waitUntilAnyTileIsProcessed;
    
    void lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    void unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);

    QString getUrlToLoad(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    bool expired(const int64_t time);

    QByteArray downloadTile(
        const OsmAnd::TileId tileId,
        const OsmAnd::ZoomLevel zoom,
        const std::shared_ptr<const OsmAnd::IQueryController>& queryController = nullptr);
    
    const sk_sp<SkImage> downloadShiftedTile(const OsmAnd::TileId tileIdNext, const OsmAnd::ZoomLevel zoom, const QByteArray& data, double offsetY);
    const sk_sp<SkImage> createShiftedTileBitmap(const QByteArray& data, const QByteArray& dataNext, double offsetY);
    const sk_sp<SkImage> decodeBitmap(const QByteArray& data);

    virtual void performAdditionalChecks(sk_sp<SkImage> image);

protected:
public:
    OASQLiteTileSourceMapLayerProvider(const QString& fileName);
    virtual ~OASQLiteTileSourceMapLayerProvider();
        
    virtual QByteArray obtainImageData(const OsmAnd::ImageMapLayerProvider::Request& request);
    virtual sk_sp<SkImage> obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual bool supportsObtainImage() const;

    virtual void obtainImageAsync(
        const OsmAnd::IMapTiledDataProvider::Request& request,
        const OsmAnd::ImageMapLayerProvider::AsyncImageData* asyncImageData);
    
    virtual OsmAnd::AlphaChannelPresence getAlphaChannelPresence() const;
    virtual OsmAnd::MapStubStyle getDesiredStubsStyle() const;
    
    virtual float getTileDensityFactor() const;
    virtual uint32_t getTileSize() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool supportsNaturalObtainDataAsync() const;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
};
