//
//  OAOsmNotesMapLayerProvider.h
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
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/Data/ObfPoiSectionReader.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/IAmenityIconProvider.h>
#include <OsmAndCore/Map/CoreResourcesAmenityIconProvider.h>
#include "OAOnlineOsmNote.h"

class OAOsmNotesMapLayerProvider
    : public std::enable_shared_from_this<OAOsmNotesMapLayerProvider>
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
    
    class NotesSymbolsGroup : public OsmAnd::MapSymbolsGroup
    {
    public:
    protected:
    public:
        NotesSymbolsGroup(const std::shared_ptr<const OAOnlineOsmNote>& note_);
        virtual ~NotesSymbolsGroup();
        
        const std::shared_ptr<const OAOnlineOsmNote> note;
        
        virtual bool obtainSharingKey(SharingKey& outKey) const;
        virtual bool obtainSortingKey(SortingKey& outKey) const;
        virtual QString toString() const;
        bool operator<(const OAOnlineOsmNote& other) const;
    };
    
    typedef std::function<void()> DataReadyCallback;

private:
    std::shared_ptr<OsmAnd::IWebClient> webClient;
    
    mutable QReadWriteLock _lock;
    QList<std::shared_ptr<const OAOnlineOsmNote>> _notesCache;
    OsmAnd::AreaI _cacheBBox31;
    OsmAnd::ZoomLevel _cacheZoom;
    float _symbolsScaleFactor;

    DataReadyCallback _dataReadyCallback;
    OsmAnd::AreaI _requestedBBox31;
    OsmAnd::AreaI _requestingBBox31;
    OsmAnd::ZoomLevel _requestingZoom;

    bool queryOsmNotes(const OsmAnd::AreaI &bbox31,
                       const OsmAnd::ZoomLevel &zoom);
    bool parseResponse(const QByteArray &buffer,
                       const OsmAnd::AreaI &bbox31,
                       const OsmAnd::ZoomLevel &zoom);
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> buildMapSymbolsGroups(const OsmAnd::AreaI &bbox31);
protected:
public:
    OAOsmNotesMapLayerProvider(const float symbolsScaleFactor);
    virtual ~OAOsmNotesMapLayerProvider();

    virtual OsmAnd::AreaI getRequestedBBox31() const;
    virtual void setRequestedBBox31(const OsmAnd::AreaI &bbox31);

    virtual void setDataReadyCallback(const DataReadyCallback dataReadyCallback);
    
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

