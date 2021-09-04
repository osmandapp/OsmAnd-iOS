//
//  OAVectorLinesSymbolsProvider.m
//  OsmAnd
//
//  Created by Paul on 28/08/2021.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAVectorLinesSymbolsProvider.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/OnSurfaceRasterMapSymbol.h>

#include <SkBitmap.h>
#include <SkPathMeasure.h>


OAVectorLinesSymbolsProvider::OAVectorLinesSymbolsProvider()
{
}

OAVectorLinesSymbolsProvider::~OAVectorLinesSymbolsProvider()
{
}

OsmAnd::ZoomLevel OAVectorLinesSymbolsProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel9;
}

OsmAnd::ZoomLevel OAVectorLinesSymbolsProvider::getMaxZoom() const
{
    return OsmAnd::MaxZoomLevel;
}

bool OAVectorLinesSymbolsProvider::supportsNaturalObtainData() const
{
    return true;
}

void OAVectorLinesSymbolsProvider::generateMapSymbolsByLine()
{
    QReadLocker scopedLocker(&_lock);
    fullSymbolsGroupByLine.clear();
    
    if (vectorLineCollection)
    {
        for (const auto& line : vectorLineCollection->getLines())
        {
            //            const auto line = *lineIt;
            const auto symbolsGroup = std::make_shared<OsmAnd::MapSymbolsGroup>();
            line->generateArrowsOnPath(symbolsGroup);
            fullSymbolsGroupByLine.append(symbolsGroup);
        }
    }
}

QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> OAVectorLinesSymbolsProvider::buildMapSymbolsGroups(const OAVectorLinesSymbolsProvider::Request& request)
{
    QReadLocker scopedLocker(&_lock);
    const auto tileId = request.tileId;
    const auto zoom = request.zoom;
    const auto bbox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    const auto symbolsGroup = std::make_shared<SymbolsGroup>();
    for (const auto& generatedGroup : fullSymbolsGroupByLine)
    {
        for (const auto& sym : generatedGroup->symbols)
        {
            const auto symbol = std::dynamic_pointer_cast<OsmAnd::OnSurfaceRasterMapSymbol>(sym);
            if (symbol && bbox31.contains(symbol->position31))
            {
                const auto arrowSymbol = std::make_shared<OnSurfaceRasterMapSymbol>(symbolsGroup);
                arrowSymbol->order = symbol->order;
                
                arrowSymbol->bitmap = symbol->bitmap;
                arrowSymbol->size = symbol->size;
                arrowSymbol->content = symbol->content;
                arrowSymbol->languageId = symbol->languageId;
                arrowSymbol->position31 = symbol->position31;
                arrowSymbol->direction = symbol->direction;
                arrowSymbol->isHidden = symbol->isHidden;
                symbolsGroup->symbols.push_back(arrowSymbol);
            }
        }
    }
    return {symbolsGroup};
}

bool OAVectorLinesSymbolsProvider::obtainData(const IMapDataProvider::Request& request,
                                            std::shared_ptr<IMapDataProvider::Data>& outData,
                                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<OAVectorLinesSymbolsProvider::Request>(request);
    if (pOutMetric)
        pOutMetric->reset();
    
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
    {
        outData.reset();
        return false;
    }
    const auto symbolGroups = buildMapSymbolsGroups(req);
    if (!symbolGroups.empty() && !symbolGroups.back()->symbols.empty())
    {
        outData.reset(new OAVectorLinesSymbolsProvider::Data(req.tileId, req.zoom, symbolGroups));
        return true;
    }
    else
    {
        outData.reset();
    }
    
    return true;
}

bool OAVectorLinesSymbolsProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAVectorLinesSymbolsProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

OAVectorLinesSymbolsProvider::Data::Data(const OsmAnd::TileId tileId_,
                                       const OsmAnd::ZoomLevel zoom_,
                                       const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups_,
                                       const RetainableCacheMetadata* const pRetainableCacheMetadata_ /*= nullptr*/)
: IMapTiledSymbolsProvider::Data(tileId_, zoom_, symbolsGroups_, pRetainableCacheMetadata_)
{
}

OAVectorLinesSymbolsProvider::Data::~Data()
{
    release();
}

OAVectorLinesSymbolsProvider::SymbolsGroup::SymbolsGroup()
{
}

OAVectorLinesSymbolsProvider::SymbolsGroup::~SymbolsGroup()
{
}

bool OAVectorLinesSymbolsProvider::SymbolsGroup::obtainSharingKey(SharingKey &outKey) const
{
    return false;
}

bool OAVectorLinesSymbolsProvider::SymbolsGroup::obtainSortingKey(SortingKey& outKey) const
{
    outKey = static_cast<SharingKey>(std::dynamic_pointer_cast<OnSurfaceRasterMapSymbol>(this->symbols.back())->position31.x);
    return true;
}

QString OAVectorLinesSymbolsProvider::SymbolsGroup::toString() const
{
    return QString();
}




