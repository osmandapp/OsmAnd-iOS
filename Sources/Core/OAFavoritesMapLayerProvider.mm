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
        bitmap = createCompositeBitmap(fav, isFullSize);
        _iconsCache[iconId] = bitmap;
    }
    else
    {
        bitmap = bitmapIt.value();
    }
    return bitmap;
}

sk_sp<SkImage> OAFavoritesMapLayerProvider::createCompositeBitmap(const std::shared_ptr<OsmAnd::IFavoriteLocation> &fav, bool isFullSize) const
{
    sk_sp<SkImage> result;
    
    UIColor *color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:1.0];
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    NSString *shapeName = fav->getBackground().toNSString();
    if (!shapeName || shapeName.length == 0)
        shapeName = @"circle";
    NSString *iconName = fav->getIcon().toNSString();
    if (!iconName || iconName.length == 0)
        iconName = @"mm_special_star";
    
    NSString *sizeName = isFullSize ? @"" : @"_small";
    
    // shadow icon
    NSString *shadowIconName = [NSString stringWithFormat:@"ic_bg_point_%@_bottom%@", shapeName, sizeName];
    auto shadowIcon = [OANativeUtilities skImageFromPngResource:shadowIconName];
    if (!shadowIcon)
        return result;
    
    // color filled background icon
    NSString *backgroundIconName = [NSString stringWithFormat:@"ic_bg_point_%@_center%@", shapeName, sizeName];
    UIImage *img = getIcon(backgroundIconName, @"ic_bg_point_circle_center");
    img = [OAUtilities tintImageWithColor:img color:color];
    auto backgroundIcon = [OANativeUtilities skImageFromCGImage:img.CGImage];
    if (!backgroundIcon)
        return result;
    
    // poi image icon
    sk_sp<SkImage> poiIcon;
    if (isFullSize)
    {
        UIImage *origImage;
        origImage = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mm_%@", [iconName stringByReplacingOccurrencesOfString:@"osmand_" withString:@""]]]];
        if (!origImage)
            origImage = [UIImage imageNamed:[OAUtilities drawablePath:@"mm_special_star"]];

        // xhdpi & xxhdpi do not directly correspond to @2x & @3x therefore a correction is needed to fit the background icon
        UIImage *resizedImage  = [OAUtilities resizeImage:origImage newSize:CGSizeMake(14, 14)];
        UIImage *coloredImage = [OAUtilities tintImageWithColor:resizedImage color:UIColor.whiteColor];
        poiIcon = [OANativeUtilities skImageFromCGImage:coloredImage.CGImage];
        if (!poiIcon)
            return result;
    }
    
    // highlight icon
    NSString *highlightIconName = [NSString stringWithFormat:@"ic_bg_point_%@_top%@", shapeName, sizeName];
    auto highlightIcon = [OANativeUtilities skImageFromPngResource:highlightIconName];
    if (!highlightIcon)
        return result;
    
    if (isFullSize && shadowIcon && backgroundIcon && poiIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({shadowIcon, backgroundIcon, poiIcon, highlightIcon});
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    else if (! isFullSize && shadowIcon && backgroundIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({shadowIcon, backgroundIcon, highlightIcon});
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    return result;
}

UIImage* OAFavoritesMapLayerProvider::getIcon(NSString* iconName, NSString* defaultIconName) const
{
    UIImage *iconImage = [UIImage imageNamed:iconName];
    if (!iconImage)
        iconImage = [UIImage imageNamed:defaultIconName];
    return iconImage;
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
