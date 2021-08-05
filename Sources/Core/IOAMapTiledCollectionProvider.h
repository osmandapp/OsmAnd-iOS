//
//  OAFavoritesMapLayerProvider.h
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <functional>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QHash>
#include <QList>
#include <OsmAndCore/restore_internal_warnings.h>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/PrivateImplementation.h>
#include <OsmAndCore/Nullable.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/IAmenityIconProvider.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/QuadTree.h>

class IOAMapTiledCollectionProvider
    : public std::enable_shared_from_this<IOAMapTiledCollectionProvider>
    , public OsmAnd::IMapTiledSymbolsProvider
{
public:
    class Data : public IMapTiledSymbolsProvider::Data
    {
    private:
    protected:
    public:
        Data(const OsmAnd::TileId tileId,
             const OsmAnd::ZoomLevel zoom,
             const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups,
             const RetainableCacheMetadata* const pRetainableCacheMetadata = nullptr);
        virtual ~Data();
    };
    
private:
    typedef OsmAnd::QuadTree<OsmAnd::AreaD, OsmAnd::AreaD::CoordType> CollectionQuadTree;
    
    mutable QReadWriteLock _lock;
    uint32_t getTileId(const OsmAnd::AreaI& tileBBox31, const OsmAnd::PointI& point);
    OsmAnd::AreaD calculateRect(double x, double y, double width, double height);
    bool intersects(CollectionQuadTree& boundIntersections, double x, double y, double width, double height);
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> buildMapSymbolsGroups(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
protected:
public:
    IOAMapTiledCollectionProvider(const int baseOrder,
                                  const QList<OsmAnd::PointI>& hiddenPoints,
                                  const bool showCaptions,
                                  const OsmAnd::TextRasterizer::Style captionStyle,
                                  const double captionTopSpace,
                                  const float referenceTileSizeOnScreenInPixels);
    virtual ~IOAMapTiledCollectionProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const = 0;
    virtual int getPointsCount() const = 0;
    virtual std::shared_ptr<SkBitmap> getImageBitmap(const int index, bool isFullSize = true) = 0;
    virtual QString getCaption(const int index) const = 0;
    virtual OsmAnd::MapMarker::PinIconVerticalAlignment getPinIconVerticalAlignment() const;
    virtual OsmAnd::MapMarker::PinIconHorisontalAlignment getPinIconHorisontalAlignment() const;

    const int baseOrder;
    const QList<OsmAnd::PointI> hiddenPoints;
    const bool showCaptions;
    const OsmAnd::TextRasterizer::Style captionStyle;
    const double captionTopSpace;
    const float referenceTileSizeOnScreenInPixels;

    virtual OsmAnd::ZoomLevel getMinZoom() const = 0;
    virtual OsmAnd::ZoomLevel getMaxZoom() const = 0;
    
    virtual bool supportsNaturalObtainData() const override;
    
    virtual bool obtainData(const IMapDataProvider::Request& request,
                            std::shared_ptr<IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr) override;
    
    virtual bool supportsNaturalObtainDataAsync() const override;
    virtual void obtainDataAsync(const IMapDataProvider::Request& request,
                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                 const bool collectMetric = false) override;
    
};

