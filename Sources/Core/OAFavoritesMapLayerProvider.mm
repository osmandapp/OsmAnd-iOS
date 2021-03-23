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

std::shared_ptr<SkBitmap> OAFavoritesMapLayerProvider::getImageBitmap(const int index)
{
    const auto fav = _favorites[index];
    return getBitmapByFavorite(fav);
}

QString OAFavoritesMapLayerProvider::getCaption(const int index) const
{
    return _favorites[index]->getTitle();
}

std::shared_ptr<SkBitmap> OAFavoritesMapLayerProvider::getBitmapByFavorite(const std::shared_ptr<OsmAnd::IFavoriteLocation> &fav)
{
    QString iconName = fav->getIcon();
    QString backgroundIconName = backgroundImageNameByType(fav->getBackground());
    QString iconId = QString::number(fav->getColor().r + fav->getColor().g + fav->getColor().b) + QStringLiteral("_") + iconName + QStringLiteral("_") + backgroundIconName;
    const auto bitmapIt = _iconsCache.find(iconId);
    std::shared_ptr<SkBitmap> bitmap;
    if (bitmapIt == _iconsCache.end())
    {
        bitmap = createCompositeBitmap(fav);
        _iconsCache[iconId] = bitmap;
    }
    else
    {
        bitmap = bitmapIt.value();
    }
    return bitmap;
    
}

std::shared_ptr<SkBitmap> OAFavoritesMapLayerProvider::createCompositeBitmap(const std::shared_ptr<OsmAnd::IFavoriteLocation> &fav) const
{
    QString iconName = fav->getIcon();
    QString backgroundIconName = backgroundImageNameByType(fav->getBackground());
    std::shared_ptr<SkBitmap> result;
    auto backgroundIcon = std::make_shared<SkBitmap>();
    auto icon = std::make_shared<SkBitmap>();
    
    UIColor* color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:1.0];
    UIImage *origImage = [UIImage imageNamed:backgroundIconName.toNSString()];
    UIImage *resizedImage  = [OAUtilities resizeImage:origImage newSize:CGSizeMake(origImage.size.width * 0.8, origImage.size.height * 0.8)];
    UIImage *coloredImage = [OAUtilities tintImageWithColor:resizedImage color:color];
    bool res = SkCreateBitmapFromCGImage(backgroundIcon.get(), coloredImage.CGImage);
    if (!res)
        return result;
    
    origImage = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mm_%@", [iconName.toNSString() stringByReplacingOccurrencesOfString:@"osmand_" withString:@""]]]];
    // xhdpi & xxhdpi do not directly correspond to @2x & @3x therefore a correction is needed to fit the background icon
    CGFloat scale = UIScreen.mainScreen.scale == 3 ? 0.5 : 0.8;
    resizedImage  = [OAUtilities resizeImage:origImage newSize:CGSizeMake(origImage.size.width * scale, origImage.size.height * scale)];
    coloredImage = [OAUtilities tintImageWithColor:resizedImage color:UIColor.whiteColor];
    
    res = SkCreateBitmapFromCGImage(icon.get(), coloredImage.CGImage);
    if (!res)
        return result;
    
    if (backgroundIcon && icon)
    {
        QList<std::shared_ptr<const SkBitmap>> toMerge({backgroundIcon, icon});
        result = OsmAnd::SkiaUtilities::mergeBitmaps(toMerge);
    }
    return result;
}

QString OAFavoritesMapLayerProvider::backgroundImageNameByType(const QString& type) const
{
    return QStringLiteral("bg_point_") + type;
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAFavoritesMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
