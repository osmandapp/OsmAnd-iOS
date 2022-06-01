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
#import "OACompoundIconUtils.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <SkCanvas.h>
#include <SkPaint.h>
#include <SkImageInfo.h>
#include <SkColor.h>
#include <SkColorFilter.h>
#include <SkCGUtils.h>

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

sk_sp<SkImage> OAFavoritesMapLayerProvider::getImageBitmap(const int index, bool isFullSize /*= true*/)
{
    const auto fav = _favorites[index];
    return getBitmapByFavorite(fav, isFullSize);
}

QString OAFavoritesMapLayerProvider::getCaption(const int index) const
{
    return _favorites[index]->getTitle();
}

sk_sp<SkImage> OAFavoritesMapLayerProvider::getBitmapByFavorite(const std::shared_ptr<OsmAnd::IFavoriteLocation> &fav, bool isFullSize)
{
    QString iconName = isFullSize ? fav->getIcon() : QStringLiteral("");
    QString backgroundIconName = backgroundImageNameByType(fav->getBackground());
    QString size = isFullSize ? QStringLiteral("_full") : QStringLiteral("_small");
    QString iconId = QString::number(fav->getColor().r + fav->getColor().g + fav->getColor().b) + QStringLiteral("_") + iconName + QStringLiteral("_") + backgroundIconName + size;
    const auto bitmapIt = _iconsCache.find(iconId);
    sk_sp<SkImage> bitmap;
    if (bitmapIt == _iconsCache.end())
    {
        bitmap = [OACompoundIconUtils createCompositeBitmapFromFavorite:fav isFullSize:isFullSize];
        _iconsCache[iconId] = bitmap;
    }
    else
    {
        bitmap = bitmapIt.value();
    }
    return bitmap;
}

QString OAFavoritesMapLayerProvider::backgroundImageNameByType(const QString& type) const
{
    return QStringLiteral("ic_bg_point_") + type + QStringLiteral("_center");
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
