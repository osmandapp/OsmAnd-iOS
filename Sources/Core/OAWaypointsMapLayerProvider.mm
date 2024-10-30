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
#import "OsmAndSharedWrapper.h"

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

OAWaypointsMapLayerProvider::OAWaypointsMapLayerProvider(NSArray<OASWptPt *> *wptPoints_,
                                                         const int baseOrder_,
                                                         const QList<OsmAnd::PointI>& hiddenPoints_,
                                                         const bool showCaptions_,
                                                         const OsmAnd::TextRasterizer::Style captionStyle_,
                                                         const double captionTopSpace_,
                                                         const float referenceTileSizeOnScreenInPixels_,
                                                         const float symbolsScaleFactor_)

: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _wptPoints(wptPoints_)
, _symbolsScaleFactor(symbolsScaleFactor_)
{
    for (OASWptPt *point in _wptPoints)
        _points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.lat, point.lon)));
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
    return (int)_wptPoints.count;
}

sk_sp<SkImage> OAWaypointsMapLayerProvider::getImageBitmap(const int index, bool isFullSize /*= true*/)
{
    OASWptPt *wptPt = _wptPoints[index];
    return getBitmapByWaypoint(wptPt, isFullSize);
}

sk_sp<SkImage> OAWaypointsMapLayerProvider::getBitmapByWaypoint(OASWptPt *point, bool isFullSize)
{
    NSString *size = isFullSize ? @"fill" : @"small";

    int32_t pointColor = point.getColor;
    NSString *pointBackground = point.getBackgroundType;
    NSString *pointIcon = point.getIconName;
    UIColor* color = pointColor != 0 ? UIColorFromARGB(pointColor) : nil;
    NSString *shapeName = pointBackground;
    NSString *iconName = isFullSize ? pointIcon : @"";

    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    if (!shapeName)
        shapeName = @"circle";
    if (!iconName)
        iconName = @"mx_special_star";
    
    QString iconId = QString([NSString stringWithFormat:@"%@_%@_%@_%@_%.2f", [color toHexString], iconName, shapeName, size, _symbolsScaleFactor].UTF8String);

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
        bitmap = [OACompoundIconUtils createCompositeBitmapFromWpt:point isFullSize:isFullSize scale:_symbolsScaleFactor];
        QWriteLocker scopedLocker(&_iconsCacheLock);
        _iconsCache[iconId] = bitmap;
    }

    return bitmap;
}

QString OAWaypointsMapLayerProvider::backgroundImageNameByType(const QString& type) const
{
    return QStringLiteral("ic_bg_point_") + type + QStringLiteral("_center");
}

QString OAWaypointsMapLayerProvider::getCaption(const int index) const
{
    return QString::fromNSString(_wptPoints[index].name);
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel6;
}

OsmAnd::ZoomLevel OAWaypointsMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
