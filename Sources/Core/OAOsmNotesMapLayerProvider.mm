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
#include "Logging.h"
#include "OAWebClient.h"

OAOsmNotesMapLayerProvider::OAOsmNotesMapLayerProvider()
:webClient(std::make_shared<OAWebClient>())
{
}

OAOsmNotesMapLayerProvider::~OAOsmNotesMapLayerProvider()
{
}

OsmAnd::ZoomLevel OAOsmNotesMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel11;
}

OsmAnd::ZoomLevel OAOsmNotesMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

QByteArray OAOsmNotesMapLayerProvider::queryOsmNotes(const OsmAnd::AreaI &tileBBox31)
{
    double bottom = OsmAnd::Utilities::get31LatitudeY(tileBBox31.bottom());
    double top = OsmAnd::Utilities::get31LatitudeY(tileBBox31.top());
    double right = OsmAnd::Utilities::get31LongitudeX(tileBBox31.right());
    double left = OsmAnd::Utilities::get31LongitudeX(tileBBox31.left());
    
    QString url = "https://api.openstreetmap.org/api/0.6/notes?bbox=";
    url.append(QString::number(left)).append(",").append(QString::number(bottom)).append(",").append(QString::number(right)).append(",").append(QString::number(top));
    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult> requestResult;
    return webClient->downloadData(url,
                                   &requestResult);
}

int OAOsmNotesMapLayerProvider::getItemLimitForZoomLevel(const OsmAnd::ZoomLevel &zoom)
{
    int res = 100;
    if (zoom < OsmAnd::ZoomLevel13)
        res = 7;
    else if (zoom < OsmAnd::ZoomLevel16)
        res = 10;
    
    return res;
}

bool OAOsmNotesMapLayerProvider::parseResponse(const QByteArray &buffer, QList<std::shared_ptr<OsmAnd::MapSymbolsGroup> > &mapSymbolsGroups, const OsmAnd::ZoomLevel &zoomLevel)
{
    
    QXmlStreamReader xmlReader(buffer);
    
    std::shared_ptr<OAOnlineOsmNote> currentNote = nullptr;
    int commentIndex = -1;
    
    // Filter out notes on lower zoom levels to prevent clutter
    int elementLimit = getItemLimitForZoomLevel(zoomLevel);
    int elementCount = 0;
    
    while(!xmlReader.atEnd() && !xmlReader.hasError() && elementCount < elementLimit) {
        // Read next element
        QXmlStreamReader::TokenType token = xmlReader.readNext();
        //If token is just StartDocument - go to next
        if(token == QXmlStreamReader::StartDocument)
            continue;
        
        QString tagName = xmlReader.name().toString();
        //If token is StartElement - read it
        if(token == QXmlStreamReader::StartElement)
        {
            if (currentNote == nullptr && tagName == QStringLiteral("note"))
            {
                currentNote = std::make_shared<OAOnlineOsmNote>();
                double lat = -1, lon = -1;
                foreach(const QXmlStreamAttribute &attr, xmlReader.attributes())
                {
                    if (attr.name().toString() == QStringLiteral("lat"))
                        lat = attr.value().toDouble();
                    else if (attr.name().toString() == QStringLiteral("lon"))
                        lon = attr.value().toDouble();
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
            const auto mapSymbolsGroup = std::make_shared<NotesSymbolsGroup>(currentNote);
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = 100000;
            const auto icon = [OANativeUtilities skBitmapFromPngResource:currentNote->isOpened() ? @"map_osm_note_unresolved" : @"map_osm_note_resolved"];
            mapSymbol->bitmap = icon;
            mapSymbol->size = OsmAnd::PointI(
                                             icon->width(),
                                             icon->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(currentNote->getLatitude(), currentNote->getLongitude()));
            mapSymbolsGroup->symbols.push_back(mapSymbol);
            mapSymbolsGroups.push_back(mapSymbolsGroup);
            currentNote = nullptr;
            elementCount++;
        }
    }
    bool success = !xmlReader.hasError();
    xmlReader.clear();
    
    return success;
}

bool OAOsmNotesMapLayerProvider::obtainData(
                                                const IMapDataProvider::Request& request,
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
    
    const auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(req.tileId, req.zoom);
    
    QByteArray buffer = queryOsmNotes(tileBBox31);
    if (buffer.size() == 0)
        return false;
    
    QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> > mapSymbolsGroups;
    
    bool success = parseResponse(buffer, mapSymbolsGroups, req.zoom);
    
    if (success)
    {
        outData.reset(new Data(
                               req.tileId,
                               req.zoom,
                               mapSymbolsGroups));
    }

    return success;
}

bool OAOsmNotesMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAOsmNotesMapLayerProvider::obtainDataAsync(
                                                     const IMapDataProvider::Request& request,
                                                     const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                     const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

OAOsmNotesMapLayerProvider::Data::Data(
                                       const OsmAnd::TileId tileId_,
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

OAOsmNotesMapLayerProvider::NotesSymbolsGroup::NotesSymbolsGroup(
                                                                 const std::shared_ptr<const OAOnlineOsmNote>& note_)
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
    return QString::null;
}

