//
//  OAWaypointsMapLayerProvider.h
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
#include <OsmAndCore/GpxDocument.h>

class OAWaypointsMapLayerProvider
    : public std::enable_shared_from_this<OAWaypointsMapLayerProvider>
    , public IOAMapTiledCollectionProvider
{
public:
private:
    QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>> _wptPtPoints;
    QList<OsmAnd::PointI> _points;
    QHash<QString, sk_sp<SkImage>> _iconsCache;
    sk_sp<SkImage> getBitmapByWaypoint(const OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> &point, bool isFullSize);
    QString backgroundImageNameByType(const QString& type) const;
protected:
public:
    OAWaypointsMapLayerProvider(const QList<OsmAnd::Ref<OsmAnd::GpxDocument::WptPt>>& wptPtPoints_,
                                const int baseOrder,
                                const QList<OsmAnd::PointI>& hiddenPoints,
                                const bool showCaptions,
                                const OsmAnd::TextRasterizer::Style captionStyle,
                                const double captionTopSpace,
                                const float referenceTileSizeOnScreenInPixels);
    virtual ~OAWaypointsMapLayerProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const override;
    virtual int getPointsCount() const override;
    virtual sk_sp<SkImage> getImageBitmap(const int index, bool isFullSize) override;
    virtual QString getCaption(const int index) const override;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
};

