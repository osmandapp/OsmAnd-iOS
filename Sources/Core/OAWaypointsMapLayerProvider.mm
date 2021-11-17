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
#include <SkCanvas.h>
#include <SkPaint.h>
#include <SkImageInfo.h>
#include <SkColor.h>
#include <SkColorFilter.h>
#include <SkCGUtils.h>

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

std::shared_ptr<SkBitmap> OAWaypointsMapLayerProvider::getImageBitmap(const int index, bool isFullSize /*= true*/)
{
    const auto locationMark = _locationMarks[index];
    return getBitmapByWaypoint(locationMark, isFullSize);
}

std::shared_ptr<SkBitmap> OAWaypointsMapLayerProvider::getBitmapByWaypoint(const OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark> &locationMark, bool isFullSize)
{
    UIColor* color = nil;
    NSString *shapeName = nil;
    NSString *iconName = nil;
    NSString *size = isFullSize ? @"fill" : @"small";
    if (locationMark->extraData)
    {
        const auto& values = locationMark->extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            color = [UIColor colorFromString:it.value().toString().toNSString()];
        
        const auto& shapeIt = values.find(QStringLiteral("background"));
        if (shapeIt != values.end())
            shapeName = shapeIt.value().toString().toNSString();
        
        if (isFullSize)
        {
            const auto& iconIt = values.find(QStringLiteral("icon"));
            if (iconIt != values.end())
                iconName = iconIt.value().toString().toNSString();
        }
        else
        {
            iconName = @"";
        }
    }
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    if (!shapeName)
        shapeName = @"circle";
    if (!iconName)
        iconName = @"mm_special_star";
    
    QString iconId = QString([[NSString stringWithFormat:@"%@_%@_%@_%@", [OAUtilities colorToString:color], iconName, shapeName, size]UTF8String]);

    const auto bitmapIt = _iconsCache.find(iconId);
    std::shared_ptr<SkBitmap> bitmap;
    if (bitmapIt == _iconsCache.end())
    {
        bitmap = createCompositeBitmap(locationMark, isFullSize);
        _iconsCache[iconId] = bitmap;
    }
    else
    {
        bitmap = bitmapIt.value();
    }
    return bitmap;
}

std::shared_ptr<SkBitmap> OAWaypointsMapLayerProvider::createCompositeBitmap(const OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark> &locationMark, bool isFullSize) const
{
    UIColor* color = nil;
    NSString *shapeName = nil;
    NSString *iconName = nil;
    if (locationMark->extraData)
    {
        const auto& values = locationMark->extraData->getValues();
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            color = [UIColor colorFromString:it.value().toString().toNSString()];
        const auto& shapeIt = values.find(QStringLiteral("background"));
        if (shapeIt != values.end())
            shapeName = shapeIt.value().toString().toNSString();
        const auto& iconIt = values.find(QStringLiteral("icon"));
        if (iconIt != values.end())
            iconName = iconIt.value().toString().toNSString();
    }
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    if (!shapeName)
        shapeName = @"circle";
    if (!iconName)
        iconName = @"mm_special_star";
    
    NSString *sizeName = isFullSize ? @"" : @"_small";

    std::shared_ptr<SkBitmap> result;

    // shadow icon
    NSString *shadowIconName = [NSString stringWithFormat:@"ic_bg_point_%@_bottom%@", shapeName, sizeName];
    auto shadowIcon = [OANativeUtilities skBitmapFromPngResource:shadowIconName];
    if (!shadowIcon)
        return result;

    // color filled background icon
    NSString *backgroundIconName = [NSString stringWithFormat:@"ic_bg_point_%@_center%@", shapeName, sizeName];
    UIImage *img = getIcon(backgroundIconName, @"ic_bg_point_circle_center");
    img = [OAUtilities tintImageWithColor:img color:color];
    auto backgroundIcon = [OANativeUtilities skBitmapFromCGImage:img.CGImage];
    if (!backgroundIcon)
        return result;

    // poi image icon
    std::shared_ptr<SkBitmap> poiIcon;
    if (isFullSize)
    {
        UIImage *origImage;
        origImage = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mm_%@", [iconName stringByReplacingOccurrencesOfString:@"osmand_" withString:@""]]]];
        if (!origImage)
            origImage = [UIImage imageNamed:[OAUtilities drawablePath:@"mm_special_star"]];

        // xhdpi & xxhdpi do not directly correspond to @2x & @3x therefore a correction is needed to fit the background icon
        UIImage *resizedImage  = [OAUtilities resizeImage:origImage newSize:CGSizeMake(14, 14)];
        UIImage *coloredImage = [OAUtilities tintImageWithColor:resizedImage color:UIColor.whiteColor];
        poiIcon = [OANativeUtilities skBitmapFromCGImage:coloredImage.CGImage];
        if (!poiIcon)
            return result;
    }

    // highlight icon
    NSString *highlightIconName = [NSString stringWithFormat:@"ic_bg_point_%@_top%@", shapeName, sizeName];
    auto highlightIcon = [OANativeUtilities skBitmapFromPngResource:highlightIconName];
    if (!highlightIcon)
        return result;

    
    if (isFullSize && shadowIcon && backgroundIcon && poiIcon && highlightIcon)
    {
        QList<std::shared_ptr<const SkBitmap>> toMerge({shadowIcon, backgroundIcon, poiIcon, highlightIcon});
        result = OsmAnd::SkiaUtilities::mergeBitmaps(toMerge);
    }
    else if (! isFullSize && shadowIcon && backgroundIcon && highlightIcon)
    {
        QList<std::shared_ptr<const SkBitmap>> toMerge({shadowIcon, backgroundIcon, highlightIcon});
        result = OsmAnd::SkiaUtilities::mergeBitmaps(toMerge);
    }
    return result;
}

UIImage* OAWaypointsMapLayerProvider::getIcon(NSString* iconName, NSString* defaultIconName) const
{
    UIImage *iconImage = [UIImage imageNamed:iconName];
    if (!iconImage)
        iconImage = [UIImage imageNamed:defaultIconName];
    return iconImage;
}

QString OAWaypointsMapLayerProvider::backgroundImageNameByType(const QString& type) const
{
    return QStringLiteral("ic_bg_point_") + type + QStringLiteral("_center");
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
