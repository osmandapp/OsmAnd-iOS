//
//  OAPOITileProvider.m
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 05.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPOITileProvider.h"
#import "OAPOI.h"
#import "OANativeUtilities.h"
#import "OACompoundIconUtils.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

OAPOITileProvider::OAPOITileProvider(NSArray<OAPOI *> *pois,
                                     const int baseOrder_,
                                     const QList<OsmAnd::PointI>& hiddenPoints_,
                                     const bool showCaptions_,
                                     const OsmAnd::TextRasterizer::Style captionStyle_,
                                     const double captionTopSpace_,
                                     const float referenceTileSizeOnScreenInPixels_,
                                     const float symbolsScaleFactor_)
: IOAMapTiledCollectionProvider(baseOrder_, hiddenPoints_, showCaptions_, captionStyle_, captionTopSpace_, referenceTileSizeOnScreenInPixels_)
, _pois(pois)
, _symbolsScaleFactor(symbolsScaleFactor_)
{
    for (OAPOI *poi in _pois)
    {
        _points31.push_back(OsmAnd::Utilities::convertLatLonTo31(
            OsmAnd::LatLon(poi.latitude, poi.longitude)));
    }
}

OAPOITileProvider::~OAPOITileProvider()
{
}

OsmAnd::PointI OAPOITileProvider::getPoint31(const int index) const
{
    return _points31[index];
}

int OAPOITileProvider::getPointsCount() const
{
    return (int)_pois.count;
}

sk_sp<SkImage> OAPOITileProvider::getImageBitmap(const int index, bool isFullSize)
{
    return getBitmapByPoi(_pois[index], isFullSize);
}

QString OAPOITileProvider::getCaption(const int index) const
{
    OAPOI *poi = _pois[index];
    NSString *name = poi.nameLocalized.length > 0 ? poi.nameLocalized : poi.name;
    return QString::fromNSString(name ?: @"");
}

sk_sp<SkImage> OAPOITileProvider::getBitmapByPoi(OAPOI *poi, bool isFullSize) const
{
    NSString *iconName = poi.iconName ?: @"mx_special_star";
    QString cacheKey = QString::fromNSString([NSString stringWithFormat:@"%@_%d_%.2f",
                                              iconName, isFullSize ? 1 : 0, _symbolsScaleFactor]);

    {
        QReadLocker lock(&_iconsCacheLock);
        const auto it = _iconsCache.constFind(cacheKey);
        if (it != _iconsCache.cend())
            return *it;
    }

    sk_sp<SkImage> bitmap = [OACompoundIconUtils createCompositeIconWithcolor:UIColorFromARGB(color_poi_orange)
                                                                    shapeName:@"circle"
                                                                     iconName:iconName
                                                                   isFullSize:isFullSize
                                                                         icon:nil
                                                                        scale:_symbolsScaleFactor];
    if (bitmap)
    {
        QWriteLocker lock(&_iconsCacheLock);
        _iconsCache[cacheKey] = bitmap;
    }
    return bitmap;
}

OsmAnd::ZoomLevel OAPOITileProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel5;
}

OsmAnd::ZoomLevel OAPOITileProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
