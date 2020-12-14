//
//  OAFavoritesMapLayerProvider.m
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAFavoritesMapLayerProvider.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/SkiaUtilities.h>

OAFavoritesMapLayerProvider::OAFavoritesMapLayerProvider(const QList<std::shared_ptr<OsmAnd::IFavoriteLocation>>& favorites_,
                                                         const int baseOrder_,
                                                         const QList<OsmAnd::PointI>& hiddenPoints_,
                                                         const bool showCaptions_,
                                                         const OsmAnd::TextRasterizer::Style captionStyle_,
                                                         const double captionTopSpace_,
                                                         const float referenceTileSizeOnScreenInPixels_)

: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _favorites(favorites_)
{
}

OAFavoritesMapLayerProvider::~OAFavoritesMapLayerProvider()
{
}

OsmAnd::PointI OAFavoritesMapLayerProvider::getPoint31(const int index) const
{
    return _favorites[index]->getPosition31();
}

int OAFavoritesMapLayerProvider::getPointsCount() const
{
    return _favorites.size();
}

std::shared_ptr<SkBitmap> OAFavoritesMapLayerProvider::getImageBitmap(const int index) const
{
    const auto fav = _favorites[index];
    UIColor* color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:1.0];
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    return [OANativeUtilities skBitmapFromPngResource:favCol.iconName];
}

QString OAFavoritesMapLayerProvider::getCaption(const int index) const
{
    return _favorites[index]->getTitle();
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
