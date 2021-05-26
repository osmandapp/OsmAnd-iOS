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
#include <OsmAndCore/GeoInfoDocument.h>

class OAWaypointsMapLayerProvider
    : public std::enable_shared_from_this<OAWaypointsMapLayerProvider>
    , public IOAMapTiledCollectionProvider
{
public:
private:
    QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> _locationMarks;
    QList<OsmAnd::PointI> _locationMarkPoints;
    QHash<QString, std::shared_ptr<SkBitmap>> _iconsCache;
    std::shared_ptr<SkBitmap> getBitmapByWaypoint(const OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark> &locationMark, bool isFullSize);
    std::shared_ptr<SkBitmap> createCompositeBitmap(const OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark> &locationMark, bool isFullSize) const;
    QString backgroundImageNameByType(const QString& type) const;
    UIImage* getIcon(NSString* iconName, NSString* defaultIconName) const;
protected:
public:
    OAWaypointsMapLayerProvider(const QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>>& locationMarks,
                                const int baseOrder,
                                const QList<OsmAnd::PointI>& hiddenPoints,
                                const bool showCaptions,
                                const OsmAnd::TextRasterizer::Style captionStyle,
                                const double captionTopSpace,
                                const float referenceTileSizeOnScreenInPixels);
    virtual ~OAWaypointsMapLayerProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const override;
    virtual int getPointsCount() const override;
    virtual std::shared_ptr<SkBitmap> getImageBitmap(const int index, bool isFullSize) override;
    virtual QString getCaption(const int index) const override;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
};

