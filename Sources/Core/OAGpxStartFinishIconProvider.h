//
//  OAGpxStartFinishIconProvider.h
//  OsmAnd
//
//  Created by Paul on 13/10/21.
//  Copyright © 2021 OsmAnd. All rights reserved.
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
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/Data/ObfPoiSectionReader.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/IAmenityIconProvider.h>
#include <OsmAndCore/Map/CoreResourcesAmenityIconProvider.h>
#include <SkBitmap.h>

using namespace OsmAnd;

class OAGpxStartFinishIconProvider
    : public std::enable_shared_from_this<OAGpxStartFinishIconProvider>
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
    QReadWriteLock _lock;
    std::shared_ptr<OsmAnd::MapSymbolsGroup> buildMapSymbolsGroup(const OsmAnd::AreaI &bbox31, const double metersPerPixel);
    
    QList<QPair<OsmAnd::PointI, OsmAnd::PointI>> _pointLocations;
    
    const std::shared_ptr<SkBitmap> _startIcon;
    const std::shared_ptr<SkBitmap> _finishIcon;
    const std::shared_ptr<SkBitmap> _startFinishIcon;
protected:
public:
    OAGpxStartFinishIconProvider();
    virtual ~OAGpxStartFinishIconProvider();
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
    
    virtual bool supportsNaturalObtainData() const override;
    QByteArray extracted(const OsmAnd::Area<int> &tileBBox31);
    
    virtual bool obtainData(const IMapDataProvider::Request& request,
                            std::shared_ptr<IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr) override;
    
    virtual bool supportsNaturalObtainDataAsync() const override;
    virtual void obtainDataAsync(const IMapDataProvider::Request& request,
                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                 const bool collectMetric = false) override;
};

