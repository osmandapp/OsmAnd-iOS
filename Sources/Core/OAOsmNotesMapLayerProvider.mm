//
//  OAOsmNotesMapLayerProvider.m
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmNotesMapLayerProvider.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Utilities.h>
#include <QXmlStreamReader>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/IWebClient.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include "OAWebClient.h"

OAOsmNotesMapLayerProvider::OAOsmNotesMapLayerProvider()
: webClient(std::make_shared<OAWebClient>())
, _dataReadyCallback(nullptr)
, _cacheBBox31()
, _cacheZoom(OsmAnd::ZoomLevel::InvalidZoomLevel)
{
}

OAOsmNotesMapLayerProvider::~OAOsmNotesMapLayerProvider()
{
}

OsmAnd::AreaI OAOsmNotesMapLayerProvider::getRequestedBBox31() const
{
    QReadLocker scopedLocker(&_lock);
    
    return _requestedBBox31;
}

void OAOsmNotesMapLayerProvider::setRequestedBBox31(const OsmAnd::AreaI &bbox31)
{
    QWriteLocker scopedLocker(&_lock);
    
    _requestedBBox31 = bbox31;
}

void OAOsmNotesMapLayerProvider::setDataReadyCallback(const DataReadyCallback dataReadyCallback)
{
    _dataReadyCallback = dataReadyCallback;
}

OsmAnd::ZoomLevel OAOsmNotesMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel13;
}

OsmAnd::ZoomLevel OAOsmNotesMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OAOsmNotesMapLayerProvider::queryOsmNotes(const OsmAnd::AreaI &bbox31, const OsmAnd::ZoomLevel &zoom)
{
    double bottom = OsmAnd::Utilities::get31LatitudeY(bbox31.bottom());
    double top = OsmAnd::Utilities::get31LatitudeY(bbox31.top());
    double right = OsmAnd::Utilities::get31LongitudeX(bbox31.right());
    double left = OsmAnd::Utilities::get31LongitudeX(bbox31.left());
    QString url = "https://api.openstreetmap.org/api/0.6/notes?bbox=";
    url.append(QString::number(left)).append(",").append(QString::number(bottom)).append(",").append(QString::number(right)).append(",").append(QString::number(top));
    const auto data = webClient->downloadData(url);
    return data.size() > 0 ? parseResponse(data, bbox31, zoom) : false;
}

bool OAOsmNotesMapLayerProvider::parseResponse(const QByteArray &buffer,
                                               const OsmAnd::AreaI &bbox31,
                                               const OsmAnd::ZoomLevel &zoom)
{
    QList<std::shared_ptr<const OAOnlineOsmNote>> notesCache;

    QXmlStreamReader xmlReader(buffer);
    
    std::shared_ptr<OAOnlineOsmNote> currentNote = nullptr;
    int commentIndex = -1;
    while (!xmlReader.atEnd() && !xmlReader.hasError())
    {
        // Read next element
        QXmlStreamReader::TokenType token = xmlReader.readNext();
        //If token is just StartDocument - go to next
        if (token == QXmlStreamReader::StartDocument)
            continue;
        
        QString tagName = xmlReader.name().toString();
        //If token is StartElement - read it
        if(token == QXmlStreamReader::StartElement)
        {
            if (currentNote == nullptr && tagName == QStringLiteral("note"))
            {
                currentNote = std::make_shared<OAOnlineOsmNote>();
                double lat = -1, lon = -1;
                const auto& attributes = xmlReader.attributes();
                for(auto it = attributes.begin(); it != attributes.end(); ++it)
                {
                    const auto attr = it;
                    const auto stringRef = attr->name();
                    if (stringRef.isNull() || stringRef.isEmpty())
                        continue;
                    
                    const auto string = stringRef.toString();
                    if (string == QStringLiteral("lat"))
                        lat = attr->value().toDouble();
                    else if (string == QStringLiteral("lon"))
                        lon = attr->value().toDouble();
                    
                    if (lat != -1 && lon != -1)
                        break;
                }
                if (lat != -1 && lon != -1)
                {
                    currentNote->setLatitude(lat);
                    currentNote->setLongitude(lon);
                }
                currentNote->comments() = QList<std::shared_ptr<OAOnlineOsmNote::OAComment>>();
                commentIndex = -1;
            }
            else if (currentNote != nullptr)
            {
                if (tagName == QStringLiteral("status"))
                {
                    currentNote->setOpened(xmlReader.readElementText() == QStringLiteral("open"));
                }
                else if (tagName == QStringLiteral("id"))
                {
                    currentNote->setId(xmlReader.readElementText().toLongLong());
                }
                else if (tagName == QStringLiteral("user"))
                    currentNote->comments()[commentIndex]->_user = xmlReader.readElementText();
                else if (tagName == QStringLiteral("date"))
                    currentNote->comments()[commentIndex]->_date = xmlReader.readElementText();
                else if (tagName == QStringLiteral("text"))
                    currentNote->comments()[commentIndex]->_text = xmlReader.readElementText();
                else if (tagName == QStringLiteral("comment"))
                {
                    commentIndex++;
                    currentNote->comments().insert(commentIndex, std::make_shared<OAOnlineOsmNote::OAComment>());
                }
            }
        }
        else if (token == QXmlStreamReader::EndElement && tagName == QStringLiteral("note"))
        {
            currentNote->acquireDescriptionAndType();
            notesCache.push_back(currentNote);
            currentNote = nullptr;
        }
    }
    bool success = !xmlReader.hasError();
    xmlReader.clear();
    
    QWriteLocker scopedLocker(&_lock);
    
    if (_requestingBBox31 != bbox31 || _requestingZoom != zoom)
        return false;

    if (success)
    {
        _cacheBBox31 = bbox31;
        _cacheZoom = zoom;
        _notesCache = notesCache;
    }
    else
    {
        _cacheBBox31 = OsmAnd::AreaI();
        _cacheZoom = OsmAnd::ZoomLevel::InvalidZoomLevel;
        _notesCache.clear();
    }
    
    return success;
}

QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> OAOsmNotesMapLayerProvider::buildMapSymbolsGroups(const OsmAnd::AreaI &bbox31)
{
    QReadLocker scopedLocker(&_lock);

    const auto iconOpen = [OANativeUtilities skImageFromPngResource:@"map_osm_note_unresolved"];
    const auto iconClosed = [OANativeUtilities skImageFromPngResource:@"map_osm_note_resolved"];
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> mapSymbolsGroups;

    for (const auto note : _notesCache)
    {
        const auto pos31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(note->getLatitude(), note->getLongitude()));
        if (bbox31.contains(pos31))
        {
            const auto mapSymbolsGroup = std::make_shared<NotesSymbolsGroup>(note);
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->image = note->isOpened() ? iconOpen : iconClosed;
            mapSymbol->size = OsmAnd::PointI(iconOpen->width(), iconOpen->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = pos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
            mapSymbolsGroups.push_back(mapSymbolsGroup);
        }
    }
    return mapSymbolsGroups;
}

bool OAOsmNotesMapLayerProvider::obtainData(const IMapDataProvider::Request& request,
                                            std::shared_ptr<IMapDataProvider::Data>& outData,
                                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<OAOsmNotesMapLayerProvider::Request>(request);
    if (pOutMetric)
        pOutMetric->reset();
    
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
    {
        outData.reset();
        return true;
    }
    
    const auto tileId = req.tileId;
    const auto zoom = req.zoom;
    const auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    OsmAnd::AreaI queryBbox31;

    {
        QReadLocker scopedLocker(&_lock);
        
        if (_cacheBBox31.contains(tileBBox31) && _cacheZoom == zoom)
        {
            const auto mapSymbolsGroups = buildMapSymbolsGroups(tileBBox31);
            outData.reset(new Data(tileId, zoom, mapSymbolsGroups));
            return true;
        }
        else if (_requestingBBox31.contains(_requestedBBox31) && _requestingZoom == zoom)
        {
            return false;
        }
        queryBbox31 = OsmAnd::Utilities::roundBoundingBox31(
                        _requestedBBox31.getEnlargedBy(_requestedBBox31.height() / 2, _requestedBBox31.width() / 2,
                                                       _requestedBBox31.height() / 2, _requestedBBox31.width() / 2), zoom);
    }
    {
        QWriteLocker scopedLocker(&_lock);
        _requestingBBox31 = queryBbox31;
        _requestingZoom = zoom;
    }
    
    const auto selfWeak = std::weak_ptr<OAOsmNotesMapLayerProvider>(shared_from_this());
    const auto requestClone = request.clone();
    const OsmAnd::QRunnableFunctor::Callback task =
    [selfWeak, requestClone, zoom, queryBbox31]
    (const OsmAnd::QRunnableFunctor* const runnable)
    {
        const auto self = selfWeak.lock();
        if (self)
        {
            if (self->queryOsmNotes(queryBbox31, zoom))
            {
                if (self->_dataReadyCallback)
                    self->_dataReadyCallback();
            }
        }
    };

    const auto taskRunnable = new OsmAnd::QRunnableFunctor(task);
    taskRunnable->setAutoDelete(true);
    QThreadPool::globalInstance()->start(taskRunnable);
    return false;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAOsmNotesMapLayerProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

OAOsmNotesMapLayerProvider::Data::Data(const OsmAnd::TileId tileId_,
                                       const OsmAnd::ZoomLevel zoom_,
                                       const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups_,
                                       const RetainableCacheMetadata* const pRetainableCacheMetadata_ /*= nullptr*/)
: IMapTiledSymbolsProvider::Data(tileId_, zoom_, symbolsGroups_, pRetainableCacheMetadata_)
{
}

OAOsmNotesMapLayerProvider::Data::~Data()
{
    release();
}

OAOsmNotesMapLayerProvider::NotesSymbolsGroup::NotesSymbolsGroup(const std::shared_ptr<const OAOnlineOsmNote>& note_)
: note(note_)
{
}

OAOsmNotesMapLayerProvider::NotesSymbolsGroup::~NotesSymbolsGroup()
{
}

bool OAOsmNotesMapLayerProvider::NotesSymbolsGroup::obtainSharingKey(SharingKey& outKey) const
{
    return false;
}

bool OAOsmNotesMapLayerProvider::NotesSymbolsGroup::obtainSortingKey(SortingKey& outKey) const
{
    outKey = static_cast<SharingKey>(note->getId());
    return true;
}

QString OAOsmNotesMapLayerProvider::NotesSymbolsGroup::toString() const
{
    return QString();
}

