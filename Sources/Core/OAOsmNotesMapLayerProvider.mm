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
#include <OsmAndCore/FunctorQueryController.h>
#include "OAWebClient.h"

OAOsmNotesMapLayerProvider::OAOsmNotesMapLayerProvider(const float symbolsScaleFactor_)
: webClient(std::make_shared<OAWebClient>())
, _cacheBBox31()
, _cacheZoom(OsmAnd::ZoomLevel::InvalidZoomLevel)
, _symbolsScaleFactor(symbolsScaleFactor_)
, _dataReadyCallback(nullptr)
, _requestingZoom(OsmAnd::ZoomLevel::InvalidZoomLevel)
, _requestingGeneration(0)
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

bool OAOsmNotesMapLayerProvider::waitForLoading() const
{
    return false;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OAOsmNotesMapLayerProvider::queryOsmNotes(
    const OsmAnd::AreaI &bbox31,
    const OsmAnd::ZoomLevel &zoom,
    const uint64_t requestingGeneration,
    const std::shared_ptr<const OsmAnd::IQueryController>& queryController)
{
    if (queryController && queryController->isAborted())
        return false;

    double bottom = OsmAnd::Utilities::get31LatitudeY(bbox31.bottom());
    double top = OsmAnd::Utilities::get31LatitudeY(bbox31.top());
    double right = OsmAnd::Utilities::get31LongitudeX(bbox31.right());
    double left = OsmAnd::Utilities::get31LongitudeX(bbox31.left());
    QString url = "https://api.openstreetmap.org/api/0.6/notes?bbox=";
    url.append(QString::number(left)).append(",").append(QString::number(bottom)).append(",").append(QString::number(right)).append(",").append(QString::number(top));
    OsmAnd::IWebClient::DataRequest dataRequest;
    dataRequest.queryController = queryController;
    const auto data = webClient->downloadData(url, dataRequest);
    if (queryController && queryController->isAborted())
        return false;
    return data.size() > 0 ? parseResponse(data, bbox31, zoom, requestingGeneration) : false;
}

QList<std::shared_ptr<const OAOnlineOsmNote>> OAOsmNotesMapLayerProvider::getNotesCache() const
{
    QReadLocker scopedLocker(&_lock);

    return _notesCache;
}

bool OAOsmNotesMapLayerProvider::parseResponse(const QByteArray &buffer,
                                               const OsmAnd::AreaI &bbox31,
                                               const OsmAnd::ZoomLevel &zoom,
                                               const uint64_t requestingGeneration)
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
    
    if (_requestingGeneration != requestingGeneration || _requestingBBox31 != bbox31 || _requestingZoom != zoom)
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

QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> OAOsmNotesMapLayerProvider::buildMapSymbolsGroups(
    const OsmAnd::AreaI &bbox31,
    const QList<std::shared_ptr<const OAOnlineOsmNote>>& notesCache)
{
    const auto iconOpen = [OANativeUtilities getScaledSkImage:[OANativeUtilities skImageFromPngResource:@"map_osm_note_unresolved"]
                                                  scaleFactor:_symbolsScaleFactor];
    const auto iconClosed = [OANativeUtilities getScaledSkImage:[OANativeUtilities skImageFromPngResource:@"map_osm_note_resolved"]
                                                    scaleFactor:_symbolsScaleFactor];
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> mapSymbolsGroups;
	if (!iconOpen || !iconClosed)
        return mapSymbolsGroups;

    for (const auto note : notesCache)
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
    if (req.queryController && req.queryController->isAborted())
    {
        outData.reset();
        return false;
    }
    
    const auto tileId = req.tileId;
    const auto zoom = req.zoom;
    const auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    OsmAnd::AreaI queryBbox31;
    QList<std::shared_ptr<const OAOnlineOsmNote>> notesCache;
    uint64_t requestingGeneration = 0;
    bool cacheAvailable = false;

    {
        QWriteLocker scopedLocker(&_lock);

        if (_cacheBBox31.contains(tileBBox31) && _cacheZoom == zoom)
        {
            notesCache = _notesCache;
            cacheAvailable = true;
        }
        else if (_requestingZoom == zoom && _requestingBBox31.contains(_requestedBBox31))
        {
            outData.reset();
            return false;
        }
        else
        {
            queryBbox31 = OsmAnd::Utilities::roundBoundingBox31(
                            _requestedBBox31.getEnlargedBy(_requestedBBox31.height() / 2, _requestedBBox31.width() / 2,
                                                           _requestedBBox31.height() / 2, _requestedBBox31.width() / 2), zoom);
            _requestingBBox31 = queryBbox31;
            _requestingZoom = zoom;
            requestingGeneration = ++_requestingGeneration;
        }
    }

    if (cacheAvailable)
    {
        const auto mapSymbolsGroups = buildMapSymbolsGroups(tileBBox31, notesCache);
        if (req.queryController && req.queryController->isAborted())
        {
            outData.reset();
            return false;
        }
        outData.reset(new Data(tileId, zoom, mapSymbolsGroups));
        return true;
    }

    const auto rendererQueryController = req.queryController;
    const auto requestQueryController = std::make_shared<OsmAnd::FunctorQueryController>(
        [this, rendererQueryController, requestingGeneration]
        (const OsmAnd::FunctorQueryController* const) -> bool
        {
            if (rendererQueryController && rendererQueryController->isAborted())
                return true;

            QReadLocker scopedLocker(&_lock);
            return _requestingGeneration != requestingGeneration;
        });

    const bool requestSucceeded = queryOsmNotes(queryBbox31, zoom, requestingGeneration, requestQueryController);
    const bool requestAborted = requestQueryController->isAborted();
    bool currentRequest = false;
    {
        QWriteLocker scopedLocker(&_lock);
        currentRequest = _requestingGeneration == requestingGeneration
            && _requestingBBox31 == queryBbox31
            && _requestingZoom == zoom;
        if (currentRequest && requestSucceeded && !requestAborted)
            notesCache = _notesCache;
        if (currentRequest)
        {
            _requestingBBox31 = OsmAnd::AreaI();
            _requestingZoom = OsmAnd::ZoomLevel::InvalidZoomLevel;
        }
    }

    if (!currentRequest || !requestSucceeded || requestAborted)
    {
        outData.reset();
        return false;
    }

    const auto mapSymbolsGroups = buildMapSymbolsGroups(tileBBox31, notesCache);
    if (req.queryController && req.queryController->isAborted())
    {
        outData.reset();
        return false;
    }
    outData.reset(new Data(tileId, zoom, mapSymbolsGroups));
    if (_dataReadyCallback)
        _dataReadyCallback();
    return true;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return true;
}

void OAOsmNotesMapLayerProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(shared_from_this(), request, callback, collectMetric);
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
