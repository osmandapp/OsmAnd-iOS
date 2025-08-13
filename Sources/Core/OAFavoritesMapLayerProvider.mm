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
                                                         const float referenceTileSizeOnScreenInPixels_,
                                                         const float symbolsScaleFactor_)

: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _favorites(favorites_)
, _symbolsScaleFactor(symbolsScaleFactor_)
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
    
    auto color = fav->getColor();
    if (color.argb == 0)
    {
        CGFloat r,g,b,a;
        [[OADefaultFavorite getDefaultColor] getRed:&r green:&g blue:&b alpha:&a];
        color = OsmAnd::FColorARGB(a,r,g,b);
    }
    
    QString iconId = QString("%1_%2_%3%4_%5")
        .arg(QString::number(color.argb), iconName, backgroundIconName, size)
        .arg(_symbolsScaleFactor, 0, 'f', 2);

    sk_sp<SkImage> bitmap;
    bool isNew = false;
    {
        QReadLocker scopedLocker(&_iconsCacheLock);
        const auto bitmapIt = _iconsCache.find(iconId);
        isNew = bitmapIt == _iconsCache.end();
        if (!isNew)
        {
            bitmap = bitmapIt.value();
        }
    }
    if (isNew)
    {
        bitmap = [OACompoundIconUtils createCompositeBitmapFromFavorite:fav isFullSize:isFullSize scale:_symbolsScaleFactor];
        QWriteLocker scopedLocker(&_iconsCacheLock);
        _iconsCache[iconId] = bitmap;
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
