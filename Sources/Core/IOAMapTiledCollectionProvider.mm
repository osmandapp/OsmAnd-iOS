//
//  IOAMapTiledCollectionProvider.m
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "IOAMapTiledCollectionProvider.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/Map/MapDataProviderHelpers.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>

static const int kSkipTilesZoom = 13;
static const int kSkipTileDivider = 16;

IOAMapTiledCollectionProvider::IOAMapTiledCollectionProvider(const int baseOrder_,
                                                             const QList<OsmAnd::PointI>& hiddenPoints_,
                                                             const bool showCaptions_,
                                                             const OsmAnd::TextRasterizer::Style captionStyle_,
                                                             const double captionTopSpace_,
                                                             const float referenceTileSizeOnScreenInPixels_)

: baseOrder(baseOrder_)
, hiddenPoints(hiddenPoints_)
, showCaptions(showCaptions_)
, captionStyle(captionStyle_)
, captionTopSpace(captionTopSpace_)
, referenceTileSizeOnScreenInPixels(referenceTileSizeOnScreenInPixels_)
{
}

IOAMapTiledCollectionProvider::~IOAMapTiledCollectionProvider()
{
}

OsmAnd::MapMarker::PinIconVerticalAlignment IOAMapTiledCollectionProvider::getPinIconVerticalAlignment() const
{
    return OsmAnd::MapMarker::PinIconVerticalAlignment::CenterVertical;
}

OsmAnd::MapMarker::PinIconHorisontalAlignment IOAMapTiledCollectionProvider::getPinIconHorisontalAlignment() const
{
    return OsmAnd::MapMarker::PinIconHorisontalAlignment::CenterHorizontal;
}

bool IOAMapTiledCollectionProvider::supportsNaturalObtainData() const
{
    return true;
}

uint32_t IOAMapTiledCollectionProvider::getTileId(const OsmAnd::AreaI& bbox31, const OsmAnd::PointI& point)
{
    const auto divX = bbox31.width() / kSkipTileDivider;
    const auto divY = bbox31.height() / kSkipTileDivider;
    const auto tx = static_cast<uint32_t>(floor((point.x - bbox31.left()) / divX));
    const auto ty = static_cast<uint32_t>(floor((point.y - bbox31.top()) / divY));
    return tx + ty * kSkipTileDivider;
}

OsmAnd::AreaD IOAMapTiledCollectionProvider::calculateRect(double x, double y, double width, double height)
{
    double left = x - width / 2.0;
    double top = y - height / 2.0;
    double right = left + width;
    double bottom = top + height;
    return OsmAnd::AreaD(top, left, bottom, right);
}

bool IOAMapTiledCollectionProvider::intersects(CollectionQuadTree& boundIntersections, double x, double y, double width, double height)
{
    QList<OsmAnd::AreaD> result;
    const auto visibleRect = calculateRect(x, y, width, height);
    boundIntersections.query(visibleRect, result);
    for (const auto &r : result)
        if (r.intersects(visibleRect))
            return true;

    boundIntersections.insert(visibleRect, visibleRect);
    return false;
}

QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> IOAMapTiledCollectionProvider::buildMapSymbolsGroups(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom)
{
    QReadLocker scopedLocker(&_lock);
    
    const auto collection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    const auto stepX = tileBBox31.width() / kSkipTileDivider * 4;
    const auto stepY = tileBBox31.height() / kSkipTileDivider * 4;
    auto extendedTileBBox31 = tileBBox31.getEnlargedBy(stepY, stepX, stepY, stepX);

    QSet<uint32_t> skippedTiles;
    bool zoomFilter = zoom <= kSkipTilesZoom;
    const auto tileSize31 = (1u << (OsmAnd::ZoomLevel::MaxZoomLevel - zoom));
    const auto from31toPixelsScale = static_cast<double>(referenceTileSizeOnScreenInPixels) / tileSize31;
    CollectionQuadTree boundIntersections(OsmAnd::AreaD(tileBBox31).getEnlargedBy(tileBBox31.width() / 2), 4);
        
    for (int i = 0; i < getPointsCount(); i++)
    {
        const auto pos31 = getPoint31(i);
        if (extendedTileBBox31.contains(pos31) && !hiddenPoints.contains(pos31))
        {
            if (zoomFilter)
            {
                const auto tileId = getTileId(extendedTileBBox31, pos31);
                if (!skippedTiles.contains(tileId))
                    skippedTiles.insert(tileId);
                else
                    continue;
            }
            
            // TODO: Would be better to get just bitmap size here
            double estimatedIconSize = 48. * UIScreen.mainScreen.scale;
            const double iconSize31 = estimatedIconSize / from31toPixelsScale;
            bool intr = intersects(boundIntersections, pos31.x, pos31.y, iconSize31, iconSize31);
            
            if (!tileBBox31.contains(pos31))
                continue;
            
            OsmAnd::MapMarkerBuilder builder;
            builder.setIsAccuracyCircleSupported(false)
            .setBaseOrder(baseOrder)
            .setIsHidden(false)
            .setPosition(pos31)
            .setPinIconVerticalAlignment(getPinIconVerticalAlignment())
            .setPinIconHorisontalAlignment(getPinIconHorisontalAlignment());

            sk_sp<SkImage> img;
            
            if (intr)
            {
                img = getImageBitmap(i, false);
                builder.setBaseOrder(builder.getBaseOrder() + 1);
            }
            else if (showCaptions && !getCaption(i).isEmpty())
            {
                img = getImageBitmap(i);
                builder.setCaption(getCaption(i));
                builder.setCaptionStyle(captionStyle);
                builder.setCaptionTopSpace(captionTopSpace);
            }
            else
            {
                img = getImageBitmap(i);
            }
            builder.setPinIcon(img);
            builder.buildAndAddToCollection(collection);
        }
    }
    
    QList<std::shared_ptr<OsmAnd::MapSymbolsGroup>> mapSymbolsGroups;
    for (const auto& marker : collection->getMarkers())
    {
        const auto mapSymbolGroup = marker->createSymbolsGroup();
        mapSymbolsGroups.push_back(qMove(mapSymbolGroup));
    }
    return mapSymbolsGroups;
}

bool IOAMapTiledCollectionProvider::obtainData(const IMapDataProvider::Request& request,
                                            std::shared_ptr<IMapDataProvider::Data>& outData,
                                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric /*= nullptr*/)
{
    const auto& req = OsmAnd::MapDataProviderHelpers::castRequest<IOAMapTiledCollectionProvider::Request>(request);
    if (pOutMetric)
        pOutMetric->reset();
    
    if (req.zoom > getMaxZoom() || req.zoom < getMinZoom())
    {
        outData.reset();
        return true;
    }
    
    const auto tileId = req.tileId;
    const auto zoom = req.zoom;

    QReadLocker scopedLocker(&_lock);
    
    const auto mapSymbolsGroups = buildMapSymbolsGroups(tileId, zoom);
    outData.reset(new Data(tileId, zoom, mapSymbolsGroups));
    return true;
}

bool IOAMapTiledCollectionProvider::supportsNaturalObtainDataAsync() const
{
    return false;
}

void IOAMapTiledCollectionProvider::obtainDataAsync(const IMapDataProvider::Request& request,
                                                 const IMapDataProvider::ObtainDataAsyncCallback callback,
                                                 const bool collectMetric /*= false*/)
{
    OsmAnd::MapDataProviderHelpers::nonNaturalObtainDataAsync(this, request, callback, collectMetric);
}

IOAMapTiledCollectionProvider::Data::Data(const OsmAnd::TileId tileId_,
                                       const OsmAnd::ZoomLevel zoom_,
                                       const QList< std::shared_ptr<OsmAnd::MapSymbolsGroup> >& symbolsGroups_,
                                       const RetainableCacheMetadata* const pRetainableCacheMetadata_ /*= nullptr*/)
: IMapTiledSymbolsProvider::Data(tileId_, zoom_, symbolsGroups_, pRetainableCacheMetadata_)
{
}

IOAMapTiledCollectionProvider::Data::~Data()
{
    release();
}
