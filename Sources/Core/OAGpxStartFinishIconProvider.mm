//
//  OAGpxStartFinishIconProvider.m
//  OsmAnd
//
//  Created by Paul on 13/10/21.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxStartFinishIconProvider.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>
#include "OAWebClient.h"

#import "OAGPXDatabase.h"
#import "OASelectedGPXHelper.h"
#import "OANativeUtilities.h"

#define kIconShadowInset 11.0

OAGpxStartFinishIconProvider::OAGpxStartFinishIconProvider()
: _startIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_start"])
, _finishIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_finish"])
, _startFinishIcon([OANativeUtilities skBitmapFromPngResource:@"map_track_point_start_finish"])
{
    const auto& activeGpx = OASelectedGPXHelper.instance.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *path = it.key().toNSString();
        OAGPXDatabase *gpxDb = OAGPXDatabase.sharedDb;
        path = [[gpxDb getFileDir:path] stringByAppendingPathComponent:path.lastPathComponent];
        OAGPX *gpx = [gpxDb getGPXItem:path];
        if (gpx.showStartFinish)
        {
            const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(it.value());
            if (!doc)
                continue;
            const auto& tracks = doc->tracks;
            for (auto trkIt = tracks.begin(); trkIt != tracks.end(); ++trkIt)
            {
                const auto& trk = *trkIt;
                for (auto segIt = trk->segments.begin(); segIt != trk->segments.end(); ++segIt)
                {
                    const auto& seg = *segIt;
                    _pointLocations.append({OsmAnd::Utilities::convertLatLonTo31(seg->points.first()->position),
                        OsmAnd::Utilities::convertLatLonTo31(seg->points.last()->position)});
                }
            }
        }
    }
}

OAGpxStartFinishIconProvider::~OAGpxStartFinishIconProvider()
{
}

OsmAnd::ZoomLevel OAGpxStartFinishIconProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel5;
}

OsmAnd::ZoomLevel OAGpxStartFinishIconProvider::getMaxZoom() const
{
    return OsmAnd::MaxZoomLevel;
}

bool OAGpxStartFinishIconProvider::supportsNaturalObtainData() const
{
    return true;
}

std::shared_ptr<OsmAnd::MapSymbolsGroup> OAGpxStartFinishIconProvider::buildMapSymbolsGroup(const OsmAnd::AreaI &bbox31, const double metersPerPixel)
{
    QReadLocker scopedLocker(&_lock);

    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> mapSymbolsGroups;
    const auto mapSymbolsGroup = std::make_shared<OsmAnd::MapSymbolsGroup>();

    for (const auto& pair : _pointLocations)
    {
        const auto startPos31 = pair.first;
        const auto finishPos31 = pair.second;
        
        bool containsStart = bbox31.contains(startPos31);
        bool containsFinish = bbox31.contains(finishPos31);
        if (containsStart && containsFinish)
        {
            double distance = ((_startIcon->width() - (kIconShadowInset * 2)) * metersPerPixel) / 2;
            const auto startIconArea = Utilities::boundingBox31FromAreaInMeters(distance, startPos31);
            const auto finishIconArea = Utilities::boundingBox31FromAreaInMeters(distance, finishPos31);
            
            if (startIconArea.intersects(finishIconArea))
            {
                const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
                mapSymbol->order = -120000;
                mapSymbol->bitmap = _startFinishIcon;
                mapSymbol->size = PointI(_startFinishIcon->width(), _startFinishIcon->height());
                mapSymbol->languageId = LanguageId::Invariant;
                mapSymbol->position31 = startPos31;
                mapSymbolsGroup->symbols.push_back(mapSymbol);
                continue;
            }
        }
        
        if (containsStart)
        {
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->bitmap = _startIcon;
            mapSymbol->size = OsmAnd::PointI(_startIcon->width(), _startIcon->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = startPos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
        }
        
        if (containsFinish)
        {
            const auto mapSymbol = std::make_shared<OsmAnd::BillboardRasterMapSymbol>(mapSymbolsGroup);
            mapSymbol->order = -120000;
            mapSymbol->bitmap = _finishIcon;
            mapSymbol->size = OsmAnd::PointI(_finishIcon->width(), _finishIcon->height());
            mapSymbol->languageId = OsmAnd::LanguageId::Invariant;
            mapSymbol->position31 = finishPos31;
            mapSymbolsGroup->symbols.push_back(mapSymbol);
        }
    }
    return mapSymbolsGroup;
}

bool OAGpxStartFinishIconProvider::obtainData(const IMapDataProvider::Request& request,
                                            std::shared_ptr<IMapDataProvider::Data>& outData,
                                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<OAGpxStartFinishIconProvider::Request>(request);
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
    const auto mapSymbolsGroup = buildMapSymbolsGroup(tileBBox31, req.mapState.metersPerPixel);
    outData.reset(new Data(tileId, zoom, {mapSymbolsGroup}));
    
    return true;
}

bool OAGpxStartFinishIconProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void OAGpxStartFinishIconProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

OAGpxStartFinishIconProvider::Data::Data(const OsmAnd::TileId tileId_,
                                       const OsmAnd::ZoomLevel zoom_,
                                       const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups_,
                                       const RetainableCacheMetadata* const pRetainableCacheMetadata_ /*= nullptr*/)
: IMapTiledSymbolsProvider::Data(tileId_, zoom_, symbolsGroups_, pRetainableCacheMetadata_)
{
}

OAGpxStartFinishIconProvider::Data::~Data()
{
    release();
}
