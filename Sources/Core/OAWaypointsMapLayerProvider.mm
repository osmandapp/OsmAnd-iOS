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

OAWaypointsMapLayerProvider::OAWaypointsMapLayerProvider(const QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>>& wptPtPoints_,
                                                         const int baseOrder_,
                                                         const QList<OsmAnd::PointI>& hiddenPoints_,
                                                         const bool showCaptions_,
                                                         const OsmAnd::TextRasterizer::Style captionStyle_,
                                                         const double captionTopSpace_,
                                                         const float referenceTileSizeOnScreenInPixels_)

: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _wptPtPoints(wptPtPoints_)
{
    for (const auto& point : _wptPtPoints)
        _points.push_back(OsmAnd::Utilities::convertLatLonTo31(point->position));
}

OAWaypointsMapLayerProvider::~OAWaypointsMapLayerProvider()
{
}

OsmAnd::PointI OAWaypointsMapLayerProvider::getPoint31(const int index) const
{
    return _points[index];
}

int OAWaypointsMapLayerProvider::getPointsCount() const
{
    return _wptPtPoints.size();
}

sk_sp<SkImage> OAWaypointsMapLayerProvider::getImageBitmap(const int index, bool isFullSize /*= true*/)
{
    const auto wptPt = _wptPtPoints[index];
    return getBitmapByWaypoint(wptPt, isFullSize);
}

sk_sp<SkImage> OAWaypointsMapLayerProvider::getBitmapByWaypoint(const OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> &point, bool isFullSize)
{
    UIColor* color = nil;
    NSString *shapeName = nil;
    NSString *iconName = nil;
    NSString *size = isFullSize ? @"fill" : @"small";
    const auto& values = point->getValues();
    if (!values.isEmpty())
    {
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
    sk_sp<SkImage> bitmap;
    if (bitmapIt == _iconsCache.end())
    {
        bitmap = [OACompoundIconUtils createCompositeBitmapFromWpt:point isFullSize:isFullSize];
        _iconsCache[iconId] = bitmap;
    }
    else
    {
        bitmap = bitmapIt.value();
    }
    return bitmap;
}

QString OAWaypointsMapLayerProvider::backgroundImageNameByType(const QString& type) const
{
    return QStringLiteral("ic_bg_point_") + type + QStringLiteral("_center");
}

QString OAWaypointsMapLayerProvider::getCaption(const int index) const
{
    return _wptPtPoints[index]->name;
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
