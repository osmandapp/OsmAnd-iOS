#import "OAPOITileProvider.h"

#import "OAPOIMapLayerData.h"
#import "OAPOIType.h"
#import "OACompoundIconUtils.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QReadWriteLock>
#include <QHash>
#include <OsmAndCore/restore_internal_warnings.h>

OAPOITileProvider::OAPOITileProvider(OAMapRendererView *mapView,
                                     OAPOIMapLayerData *layerData,
                                     int baseOrder,
                                     bool showCaptions,
                                     const OsmAnd::TextRasterizer::Style &captionStyle,
                                     double captionTopSpace,
                                     float referenceTileSizeOnScreenInPixels,
                                     float textScale)
    : IOAMapTiledCollectionProvider(baseOrder,
                                    QList<OsmAnd::PointI>(),
                                    showCaptions,
                                    captionStyle,
                                    captionTopSpace,
                                    referenceTileSizeOnScreenInPixels)
    , _mapView(mapView)
    , _layerData(layerData)
    , _items([NSMutableArray array])
    , _textScale(textScale)
{
}

OAPOITileProvider::~OAPOITileProvider()
{
}

OsmAnd::PointI OAPOITileProvider::getPoint31(const int index) const
{
    QReadLocker scopedLocker(&_itemsLock);
    return [[_items objectAtIndex:index] position31];
}

int OAPOITileProvider::getPointsCount() const
{
    QReadLocker scopedLocker(&_itemsLock);
    return (int) _items.count;
}

sk_sp<SkImage> OAPOITileProvider::getImageBitmap(const int index, bool isFullSize)
{
    OAPOIMapLayerItem *item = nil;
    {
        QReadLocker scopedLocker(&_itemsLock);
        item = [_items objectAtIndex:index];
    }

    OAPOIType *type = [item type];
    NSString *iconName = [type iconName];
    if (!iconName || iconName.length == 0)
        iconName = @"special_information";

    const QString iconId = QString::fromNSString([NSString stringWithFormat:@"%@_%@_%.2f",
                                                  iconName,
                                                  isFullSize ? @"full" : @"small",
                                                  _textScale]);

    sk_sp<SkImage> bitmap;
    bool isNew = false;
    {
        QReadLocker scopedLocker(&_iconsCacheLock);
        const auto bitmapIt = _iconsCache.find(iconId);
        isNew = bitmapIt == _iconsCache.end();
        if (!isNew)
            bitmap = bitmapIt.value();
    }

    if (isNew)
    {
        bitmap = [OACompoundIconUtils createCompositeIconWithcolor:UIColorFromARGB(color_poi_orange)
                                                         shapeName:@"circle"
                                                          iconName:iconName
                                                        isFullSize:isFullSize
                                                              icon:nil
                                                             scale:_textScale];
        QWriteLocker scopedLocker(&_iconsCacheLock);
        _iconsCache[iconId] = bitmap;
    }

    return bitmap;
}

QString OAPOITileProvider::getCaption(const int index) const
{
    OAPOIMapLayerItem *item = nil;
    {
        QReadLocker scopedLocker(&_itemsLock);
        item = [_items objectAtIndex:index];
    }

    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *language = settings.settingPrefMapLanguage.get;
    BOOL transliterate = settings.settingMapLanguageTranslit.get;
    return QString::fromNSString([item captionWithLanguage:language transliterate:transliterate]);
}

OsmAnd::ZoomLevel OAPOITileProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel5;
}

OsmAnd::ZoomLevel OAPOITileProvider::getMaxZoom() const
{
    return OsmAnd::MaxZoomLevel;
}

bool OAPOITileProvider::obtainData(const IMapDataProvider::Request& request,
                                   std::shared_ptr<IMapDataProvider::Data>& outData,
                                   std::shared_ptr<OsmAnd::Metric>* const pOutMetric)
{
    OAPOIMapLayerData *layerData = _layerData;
    OAMapRendererView *mapView = _mapView;
    if (layerData && mapView)
    {
        OAPOITileBoxRequest *tileRequest = [[OAPOITileBoxRequest alloc] initWithMapView:mapView];
        OAPOIMapLayerDataReadyCallback *callback = [layerData getDataReadyCallback:tileRequest];
        [layerData addDataReadyCallback:callback];
        [layerData queryNewData:tileRequest];
        [callback waitUntilReadyForTimeout:[layerData dataRequestTimeout]];
        [layerData removeDataReadyCallback:callback];

        NSArray<OAPOIMapLayerItem *> *items = callback.displayedResults ?: layerData.displayedResults;
        if (!items)
            items = @[];

        QWriteLocker scopedLocker(&_itemsLock);
        _items = [items mutableCopy];
    }

    return IOAMapTiledCollectionProvider::obtainData(request, outData, pOutMetric);
}
