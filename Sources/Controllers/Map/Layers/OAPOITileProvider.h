#import "IOAMapTiledCollectionProvider.h"

#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QReadWriteLock>
#include <QHash>
#include <OsmAndCore/restore_internal_warnings.h>

@class NSMutableArray;
@class OAMapRendererView;
@class OAPOIMapLayerData;
@class OAPOIMapLayerItem;

class OAPOITileProvider
    : public std::enable_shared_from_this<OAPOITileProvider>
    , public IOAMapTiledCollectionProvider
{
public:
    OAPOITileProvider(OAMapRendererView *mapView,
                      OAPOIMapLayerData *layerData,
                      int baseOrder,
                      bool showCaptions,
                      const OsmAnd::TextRasterizer::Style &captionStyle,
                      double captionTopSpace,
                      float referenceTileSizeOnScreenInPixels,
                      float textScale);
    virtual ~OAPOITileProvider();

    virtual OsmAnd::PointI getPoint31(const int index) const override;
    virtual int getPointsCount() const override;
    virtual sk_sp<SkImage> getImageBitmap(const int index, bool isFullSize = true) override;
    virtual QString getCaption(const int index) const override;
    virtual OsmAnd::ZoomLevel getMinZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxZoom() const override;
    virtual bool obtainData(const IMapDataProvider::Request& request,
                            std::shared_ptr<IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr) override;

private:
    __weak OAMapRendererView *_mapView;
    __weak OAPOIMapLayerData *_layerData;
    NSMutableArray<OAPOIMapLayerItem *> *_items;
    mutable QReadWriteLock _itemsLock;
    mutable QReadWriteLock _iconsCacheLock;
    QHash<QString, sk_sp<SkImage>> _iconsCache;
    float _textScale;
};
