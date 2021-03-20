//
//  OAWaypointsMapLayerProvider.m
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAWaypointsMapLayerProvider.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/SkiaUtilities.h>

OAWaypointsMapLayerProvider::OAWaypointsMapLayerProvider(const QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>>& locationMarks_,
                                                         const int baseOrder_,
                                                         const QList<OsmAnd::PointI>& hiddenPoints_,
                                                         const bool showCaptions_,
                                                         const OsmAnd::TextRasterizer::Style captionStyle_,
                                                         const double captionTopSpace_,
                                                         const float referenceTileSizeOnScreenInPixels_)

: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _locationMarks(locationMarks_)
{
    for (const auto& locationMark : _locationMarks)
        _locationMarkPoints.push_back(OsmAnd::Utilities::convertLatLonTo31(locationMark->position));
}

OAWaypointsMapLayerProvider::~OAWaypointsMapLayerProvider()
{
}

OsmAnd::PointI OAWaypointsMapLayerProvider::getPoint31(const int index) const
{
    return _locationMarkPoints[index];
}

int OAWaypointsMapLayerProvider::getPointsCount() const
{
    return _locationMarks.size();
}

std::shared_ptr<SkBitmap> OAWaypointsMapLayerProvider::getImageBitmap(const int index)
{
    const auto locationMark = _locationMarks[index];
    UIColor* color = nil;
    if (locationMark->extraData)
    {
        const auto& values = locationMark->extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            color = [OAUtilities colorFromString:it.value().toString().toNSString()];
    }
    
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    return [OANativeUtilities skBitmapFromPngResource:favCol.iconName];
}

QString OAWaypointsMapLayerProvider::getCaption(const int index) const
{
    return _locationMarks[index]->name;
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
