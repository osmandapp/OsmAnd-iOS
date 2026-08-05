//
//  OAPOITileProvider.h
//  OsmAnd
//
//  Created by Vitaliy Sova on 05.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "IOAMapTiledCollectionProvider.h"

@class OAPOI;

#include <QHash>
#include <QList>
#include <QReadWriteLock>

class OAPOITileProvider
    : public std::enable_shared_from_this<OAPOITileProvider>
    , public IOAMapTiledCollectionProvider
{
private:
    NSArray<OAPOI *> *_pois;
    QList<OsmAnd::PointI> _points31;
    float _symbolsScaleFactor;
    mutable QReadWriteLock _iconsCacheLock;
    mutable QHash<QString, sk_sp<SkImage>> _iconsCache;

    sk_sp<SkImage> getBitmapByPoi(OAPOI *poi, bool isFullSize) const;

public:
    OAPOITileProvider(NSArray<OAPOI *> *pois,
                      const int baseOrder,
                      const QList<OsmAnd::PointI>& hiddenPoints,
                      const bool showCaptions,
                      const OsmAnd::TextRasterizer::Style captionStyle,
                      const double captionTopSpace,
                      const float referenceTileSizeOnScreenInPixels,
                      const float symbolsScaleFactor);
    virtual ~OAPOITileProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const override;
    virtual int getPointsCount() const override;
    virtual sk_sp<SkImage> getImageBitmap(const int index, bool isFullSize = true) override;
    virtual QString getCaption(const int index) const override;

    virtual OsmAnd::ZoomLevel getMinZoom() const override; // Android: ZoomLevel5
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
};
