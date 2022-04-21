//
//  OAFavoritesMapLayerProvider.h
//  OsmAnd
//
//  Created by Paul on 4/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "IOAMapTiledCollectionProvider.h"

#include <OsmAndCore/stdlib_common.h>
#include <functional>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QHash>
#include <QList>
#include <OsmAndCore/restore_internal_warnings.h>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/IFavoriteLocation.h>

class OAFavoritesMapLayerProvider
    : public std::enable_shared_from_this<OAFavoritesMapLayerProvider>
    , public IOAMapTiledCollectionProvider
{
public:
private:
    QList<std::shared_ptr<OsmAnd::IFavoriteLocation>> _favorites;
    QHash<QString, sk_sp<SkImage>> _iconsCache;
    
    sk_sp<SkImage> getBitmapByFavorite(const std::shared_ptr<OsmAnd::IFavoriteLocation> &fav, bool isFullSize);
    QString backgroundImageNameByType(const QString& type) const;
protected:
public:
    OAFavoritesMapLayerProvider(const QList<std::shared_ptr<OsmAnd::IFavoriteLocation>>& favorites,
                                const int baseOrder,
                                const QList<OsmAnd::PointI>& hiddenPoints,
                                const bool showCaptions,
                                const OsmAnd::TextRasterizer::Style captionStyle,
                                const double captionTopSpace,
                                const float referenceTileSizeOnScreenInPixels);
    virtual ~OAFavoritesMapLayerProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const override;
    virtual int getPointsCount() const override;
    virtual sk_sp<SkImage> getImageBitmap(const int index, bool isFullSize) override;
    virtual QString getCaption(const int index) const override;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
};

