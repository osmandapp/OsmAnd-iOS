//
//  OAVectorLinesSymbolsProvider.h
//  OsmAnd
//
//  Created by Paul on 28/08/2021.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <functional>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QSet>
#include <QList>
#include <OsmAndCore/restore_internal_warnings.h>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/PrivateImplementation.h>
#include <OsmAndCore/Nullable.h>
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>

using namespace OsmAnd;

class OAVectorLinesSymbolsProvider
    : public std::enable_shared_from_this<OAVectorLinesSymbolsProvider>
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
    class SymbolsGroup
        : public MapSymbolsGroup
    {
    private:
    protected:
    public:
        SymbolsGroup();
        virtual ~SymbolsGroup();
        
        virtual bool obtainSharingKey(SharingKey& outKey) const;
        virtual bool obtainSortingKey(SortingKey& outKey) const;
        virtual QString toString() const;
    };

private:
    
    mutable QReadWriteLock _lock;

    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> fullSymbolsGroupByLine;
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> buildMapSymbolsGroups(const OAVectorLinesSymbolsProvider::Request& request);
protected:
public:
    OAVectorLinesSymbolsProvider();
    virtual ~OAVectorLinesSymbolsProvider();

    std::shared_ptr<OsmAnd::VectorLinesCollection> vectorLineCollection;
    
    void generateMapSymbolsByLine();
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
    
    virtual bool supportsNaturalObtainData() const override;
    
    virtual bool obtainData(const IMapDataProvider::Request& request,
                            std::shared_ptr<IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr) override;
    
    virtual bool supportsNaturalObtainDataAsync() const override;
    virtual void obtainDataAsync(const IMapDataProvider::Request& request,
                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                 const bool collectMetric = false) override;
};

