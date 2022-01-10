//
//  OAMapMarkersCollection.cpp
//  OsmAnd
//
//  Created by Alexey Kulish on 31/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OAMapMarkersCollection.h"
#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/Map/MapSymbolsGroup.h>
#include <OsmAndCore/Map/SymbolRasterizer.h>

#include <OsmAndCore/Utilities.h>

#include "OANativeUtilities.h"

OAMapMarkersCollection::OAMapMarkersCollection(
                                               const OsmAnd::ZoomLevel minZoom_ /*= MinZoomLevel*/,
                                               const OsmAnd::ZoomLevel maxZoom_ /*= MaxZoomLevel*/)
: minZoom(minZoom_)
, maxZoom(maxZoom_)
{
    tmpStr.reset(new QString("123"));
}

OAMapMarkersCollection::~OAMapMarkersCollection()
{
}

QList< std::shared_ptr<OAMapMarker> > OAMapMarkersCollection::getMarkers() const
{
    QReadLocker scopedLocker(&_markersLock);
    
    return _markers.values();
}

bool OAMapMarkersCollection::addMarker(const std::shared_ptr<OAMapMarker>& marker)
{
    QWriteLocker scopedLocker(&_markersLock);
    
    const auto key = reinterpret_cast<OsmAnd::IMapKeyedSymbolsProvider::Key>(marker.get());
    if (_markers.contains(key))
        return false;
    
    _markers.insert(key, marker);
    
    return true;
}

bool OAMapMarkersCollection::removeMarker(const std::shared_ptr<OAMapMarker>& marker)
{
    QWriteLocker scopedLocker(&_markersLock);
    
    const bool removed = (_markers.remove(reinterpret_cast<OsmAnd::IMapKeyedSymbolsProvider::Key>(marker.get())) > 0);
    return removed;
}

void OAMapMarkersCollection::removeAllMarkers()
{
    QWriteLocker scopedLocker(&_markersLock);
    
    _markers.clear();
}


OsmAnd::ZoomLevel OAMapMarkersCollection::getMinZoom() const
{
    return minZoom;
}

OsmAnd::ZoomLevel OAMapMarkersCollection::getMaxZoom() const
{
    return maxZoom;
}

bool OAMapMarkersCollection::supportsNaturalObtainData() const
{
    return true;
}

QList<OsmAnd::IMapKeyedSymbolsProvider::Key> OAMapMarkersCollection::getProvidedDataKeys() const
{
    QReadLocker scopedLocker(&_markersLock);
    
    //return _markers.keys();
    QList<OsmAnd::IMapKeyedSymbolsProvider::Key> tempList;
    tempList << tmpStr.get();
    return tempList;
}

bool OAMapMarkersCollection::obtainData(
                const OsmAnd::IMapDataProvider::Request& request_,
                std::shared_ptr<OsmAnd::IMapDataProvider::Data>& outData,
                std::shared_ptr<OsmAnd::Metric>* const pOutMetric)
{
    /*
    const auto& request = OsmAnd::MapDataProviderHelpers::castRequest<OAMapMarkersCollection::Request>(request_);
    
    QReadLocker scopedLocker(&_markersLock);
    
    const auto citMarker = _markers.constFind(request.key);
    if (citMarker == _markers.cend())
        return false;
    auto& marker = *citMarker;
    
    outData.reset(new OsmAnd::IMapKeyedSymbolsProvider::Data(request.key, marker->createSymbolsGroup()));
    */

    if (symbolsGroup == nullptr)
    {
        // Construct new map symbols group for this marker
        symbolsGroup.reset(new OsmAnd::MapSymbolsGroup());
        symbolsGroup->presentationMode |= OsmAnd::MapSymbolsGroup::PresentationModeFlag::ShowAllOrNothing;
        
        int order = INT_MAX - 10;
        
        // SpriteMapSymbol with pinIconBitmap as an icon
        
        sk_sp<SkImage> pinIcon([OANativeUtilities skImageFromPngResource:@"icon_star_fill"]);
        
        const std::shared_ptr<OsmAnd::BillboardRasterMapSymbol> pinIconSymbol(new OsmAnd::BillboardRasterMapSymbol(
                                                                                                   symbolsGroup));
        pinIconSymbol->order = order++;
        pinIconSymbol->image = pinIcon;
        pinIconSymbol->size = OsmAnd::PointI(pinIcon->width(), pinIcon->height());
        pinIconSymbol->contentClass = OsmAnd::RasterMapSymbol::ContentClass::Icon;
        pinIconSymbol->content = QString().sprintf(
                                                   "markerGroup(%p:%p)->pinIconBitmap:%p",
                                                   this,
                                                   symbolsGroup.get(),
                                                   pinIcon.get());
        pinIconSymbol->languageId = OsmAnd::LanguageId::Invariant;
        
        pinIconSymbol->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(50.4486, 30.51348));
        //pinIconSymbol->offset = OsmAnd::PointI(0, 0);
        pinIconSymbol->isHidden = false;
        //pinIconSymbol->modulationColor = OsmAnd::FColorARGB();
        
        /*
        std::shared_ptr<const OsmAnd::MapPrimitiviser::TextSymbol> textSymbol(new OsmAnd::MapPrimitiviser::TextSymbol());
        
        const std::shared_ptr<OsmAnd::SymbolRasterizer::RasterizedSpriteSymbol> pinCaptionSymbol(new OsmAnd::SymbolRasterizer::RasterizedSpriteSymbol(symbolsGroup));
        
        pinCaptionSymbol->order = order++;
        pinCaptionSymbol->contentClass = OsmAnd::RasterMapSymbol::ContentClass::Caption;
        pinCaptionSymbol->content = QString("Test Тест Надпись");
        pinCaptionSymbol->languageId = OsmAnd::LanguageId::Invariant;
        
        pinCaptionSymbol->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(50.4486, 30.51348));
        //pinCaptionSymbol->offset = OsmAnd::PointI(0, 0);
        pinCaptionSymbol->isHidden = false;
        //pinCaptionSymbol->modulationColor = OsmAnd::FColorARGB();
        */
        
        
        symbolsGroup->symbols.push_back(pinIconSymbol);
        //symbolsGroup->symbols.push_back(pinCaptionSymbol);
    }
    
    outData.reset(new OsmAnd::IMapKeyedSymbolsProvider::Data(tmpStr.get(), symbolsGroup));

    return true;
}

bool OAMapMarkersCollection::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAMapMarkersCollection::obtainDataAsync(
                                                   const IMapDataProvider::Request& request,
                                                   const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                   const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}


