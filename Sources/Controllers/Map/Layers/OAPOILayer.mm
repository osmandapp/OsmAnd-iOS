//
//  OAPOILayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPOILayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOILocationType.h"
#import "OAPOIMyLocationType.h"
#import "OAPOIUIFilter.h"
#import "OARenderedObject.h"
#import "OAAmenityExtendedNameFilter.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaPlugin.h"
#import "OARouteKey.h"
#import "OARouteKey+cpp.h"
#import "OANetworkRouteDrawable.h"
#import "OAPluginsHelper.h"
#import "OAAppSettings.h"
#import "OsmAndSharedWrapper.h"
#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"
#import "OAPointDescription.h"
#import "QuadTree.h"
#import "OAMapTopPlace.h"
#import "OANativeUtilities.h"
#import "OAPOILayerTopPlacesProvider.h"
#import "OsmAnd_Maps-Swift.h"

#include "OACoreResourcesAmenityIconProvider.h"
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/NetworkRouteContext.h>
#include <OsmAndCore/NetworkRouteSelector.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/Map/IOnPathMapSymbol.h>
#include <OsmAndCore/Map/IMapTiledSymbolsProvider.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <QMutex>
#include <QWaitCondition>
#include <cmath>
#include <limits>

static const NSInteger kPoiSearchRadius = 50; // AMENITY_SEARCH_RADIUS
static const NSInteger kPoiSearchRadiusForRelation = 500; // AMENITY_SEARCH_RADIUS_FOR_RELATION
static const NSInteger kTrackSearchDelta = 40;
static const NSInteger START_ZOOM = 5;
static const NSTimeInterval kWikiSymbolsCacheWaitInterval = 0.05;
static const unsigned long kWikiOnlineAmenitiesWaitIntervalMs = 50;
static const uint32_t kMinPoiCacheSize = 64;
static const uint32_t kPoiVisibleTilesMargin = 2;

const QString TAG_POI_LAT_LON = QStringLiteral("osmand_poi_lat_lon");

static BOOL OABoundsContainCoordinate(QuadRect *bounds, CLLocationCoordinate2D coordinate)
{
    if (!bounds || !CLLocationCoordinate2DIsValid(coordinate))
        return NO;

    const BOOL latitudeInBounds = coordinate.latitude <= bounds.top && coordinate.latitude >= bounds.bottom;
    if (!latitudeInBounds)
        return NO;

    if (bounds.left <= bounds.right)
        return coordinate.longitude >= bounds.left && coordinate.longitude <= bounds.right;

    return coordinate.longitude >= bounds.left || coordinate.longitude <= bounds.right;
}

static uint32_t OACalculatePoiCacheSize(CGSize viewSize, uint32_t rasterTileSize)
{
    if (rasterTileSize == 0)
        return kMinPoiCacheSize;

    const double diagonal = std::hypot(viewSize.width, viewSize.height);
    const double visibleTilesPerSide = std::ceil(diagonal / rasterTileSize) + kPoiVisibleTilesMargin;
    const uint32_t cacheSize = (uint32_t)(visibleTilesPerSide * visibleTilesPerSide);
    return std::max(kMinPoiCacheSize, cacheSize);
}

static uint64_t OAResolveSyntheticAmenityId(OAPOI *poi)
{
    const uint64_t rawId = poi.obfId;
    const uint64_t invalidId = [OAMapObject getInvalidObfId];
    if (rawId != 0 && rawId != invalidId && static_cast<int64_t>(rawId) > 0)
        return rawId;

    const uint64_t latHash = static_cast<uint64_t>(llround((poi.latitude + 90.0) * 1000000.0));
    const uint64_t lonHash = static_cast<uint64_t>(llround((poi.longitude + 180.0) * 1000000.0));
    const uint64_t nameHash = static_cast<uint64_t>(qHash(QString::fromNSString(poi.name ?: @"")));
    uint64_t syntheticId = (latHash << 21) ^ lonHash ^ nameHash ^ static_cast<uint64_t>([poi getTravelEloNumber]);
    syntheticId &= static_cast<uint64_t>(std::numeric_limits<int64_t>::max());
    return syntheticId != 0 ? syntheticId : 1;
}

static OsmAnd::AreaI OAExpandVisibleBBox31(const OsmAnd::AreaI& visibleBBox31)
{
    if (visibleBBox31.width() <= 0 || visibleBBox31.height() <= 0)
        return OsmAnd::AreaI();

    const auto halfWidth = qMax(1, visibleBBox31.width() / 2);
    const auto halfHeight = qMax(1, visibleBBox31.height() / 2);
    return visibleBBox31.getEnlargedBy(halfHeight, halfWidth, halfHeight, halfWidth);
}

static std::shared_ptr<const OsmAnd::Amenity> OASyntheticAmenityFromPoi(OAPOI *poi)
{
    if (!poi || ![poi hasLocation])
        return nullptr;

    const BOOL hasCanonicalPoiType = poi.type != nil
        && poi.type.category != nil
        && !NSStringIsEmpty(poi.type.category.name)
        && !NSStringIsEmpty(poi.type.name);
    const QString categoryName = QString::fromNSString(
        hasCanonicalPoiType ? poi.type.category.name : (poi.type.category.name ?: @"osmwiki"));
    const QString subTypeName = QString::fromNSString(
        hasCanonicalPoiType ? poi.type.name : (poi.subType.length > 0 ? poi.subType : (poi.type.name ?: @"wikiplace")));

    auto amenity = std::make_shared<OsmAnd::Amenity>(std::shared_ptr<const OsmAnd::ObfPoiSectionInfo>());
    amenity->id.id = OAResolveSyntheticAmenityId(poi);
    amenity->position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(poi.latitude, poi.longitude));
    amenity->nativeName = QString::fromNSString(poi.name ?: @"");
    amenity->type = categoryName;
    amenity->subType = subTypeName;
    amenity->regionName = QString::fromNSString(poi.regionName ?: @"");
    amenity->travelElo = [poi getTravelEloNumber];

    if (poi.localizedNames.count > 0)
    {
        for (NSString *key in poi.localizedNames)
            amenity->localizedNames.insert(QString::fromNSString(key), QString::fromNSString(poi.localizedNames[key]));
    }
    if (!NSStringIsEmpty(poi.enName))
        amenity->localizedNames.insert(QStringLiteral("en"), QString::fromNSString(poi.enName));

    NSString *preferredLang = OAAppSettings.sharedManager.settingPrefMapLanguage.get;
    if (!NSStringIsEmpty(preferredLang) && !NSStringIsEmpty(poi.nameLocalized) && !poi.localizedNames[preferredLang])
        amenity->localizedNames.insert(QString::fromNSString(preferredLang), QString::fromNSString(poi.nameLocalized));

    if (hasCanonicalPoiType)
    {
        OsmAnd::Amenity::DecodedCategory decodedCategory;
        decodedCategory.category = categoryName;
        decodedCategory.subcategory = subTypeName;
        amenity->decodedCategoriesOverride.push_back(decodedCategory);
    }
    else
    {
        const auto subtypes = subTypeName.split(';', Qt::SkipEmptyParts);
        for (const auto& subtype : OsmAnd::constOf(subtypes))
        {
            OsmAnd::Amenity::DecodedCategory decodedCategory;
            decodedCategory.category = categoryName;
            decodedCategory.subcategory = subtype;
            amenity->decodedCategoriesOverride.push_back(decodedCategory);
        }
    }

    NSDictionary<NSString *, NSString *> *additionalInfo = [poi getAdditionalInfo];
    for (NSString *key in additionalInfo)
        amenity->decodedValuesOverride.insert(QString::fromNSString(key), QString::fromNSString(additionalInfo[key]));

    if (poi.type && !NSStringIsEmpty(poi.type.name))
        amenity->decodedValuesOverride.insert(QStringLiteral("osmand_poi_key"), QString::fromNSString(poi.type.name));

    return amenity;
}

typedef NS_ENUM(NSInteger, OATopWikiOnlineAmenitiesState)
{
    OATopWikiOnlineAmenitiesStateUndefined = -1,
    OATopWikiOnlineAmenitiesStateLoading,
    OATopWikiOnlineAmenitiesStateReady,
    OATopWikiOnlineAmenitiesStateFailed
};

@interface OATopWikiOnlineAmenitiesRequest : NSObject
{
@public
    uint64_t requestId;
    OsmAnd::AreaI visibleBBox31;
    OsmAnd::PointI center31;
    OsmAnd::ZoomLevel zoom;
    OATopWikiOnlineAmenitiesState state;
    QList<std::shared_ptr<const OsmAnd::Amenity>> amenities;
}

- (instancetype)initWithRequestId:(uint64_t)requestId
                    visibleBBox31:(const OsmAnd::AreaI&)visibleBBox31
                         center31:(const OsmAnd::PointI&)center31
                             zoom:(OsmAnd::ZoomLevel)zoom;

@end

static BOOL OAIsValidVisibleState(const OsmAnd::AreaI& visibleBBox31, const OsmAnd::ZoomLevel zoom)
{
    return zoom != OsmAnd::InvalidZoomLevel && visibleBBox31.width() > 0 && visibleBBox31.height() > 0;
}

static BOOL OAIsRequestApplicableToVisibleState(
    OATopWikiOnlineAmenitiesRequest *request,
    const BOOL hasLatestVisibleState,
    const OsmAnd::AreaI& latestVisibleBBox31,
    const OsmAnd::ZoomLevel latestVisibleZoom)
{
    return request
        && hasLatestVisibleState
        && request->zoom == latestVisibleZoom
        && request->visibleBBox31.width() > 0
        && request->visibleBBox31.height() > 0
        && request->visibleBBox31.contains(latestVisibleBBox31);
}

static BOOL OARequestIntersectsTileBBox(
    OATopWikiOnlineAmenitiesRequest *request,
    const OsmAnd::AreaI& tileBBox31,
    const OsmAnd::ZoomLevel zoom)
{
    return request
        && request->zoom == zoom
        && request->visibleBBox31.width() > 0
        && request->visibleBBox31.height() > 0
        && request->visibleBBox31.intersects(tileBBox31);
}

@interface OATopWikiOnlineAmenitiesController : NSObject
{
@private
    PoiUIFilterDataProvider *_dataProvider;
    std::weak_ptr<OsmAnd::AmenitySymbolsProvider> _symbolsProvider;
    QMutex _stateMutex;
    QWaitCondition _stateWaitCondition;
    uint64_t _nextRequestId;
    OsmAnd::AreaI _latestVisibleBBox31;
    OsmAnd::ZoomLevel _latestVisibleZoom;
    BOOL _hasLatestVisibleState;
    OATopWikiOnlineAmenitiesRequest *_activeRequest;
    BOOL _needsNewRequest;
    BOOL _invalidated;
    void (^_dataReadyHandler)(const QList<std::shared_ptr<const OsmAnd::Amenity>>&);
}

- (instancetype)initWithDataProvider:(PoiUIFilterDataProvider *)dataProvider;
- (void)setSymbolsProvider:(const std::shared_ptr<OsmAnd::AmenitySymbolsProvider>&)symbolsProvider;
- (void)setDataReadyHandler:(void (^)(const QList<std::shared_ptr<const OsmAnd::Amenity>>&))dataReadyHandler;
- (void)updateVisibleBBox31:(OsmAnd::AreaI)visibleBBox31 zoom:(OsmAnd::ZoomLevel)zoom;
- (void)invalidate;
- (BOOL)obtainAmenitiesForTileId:(OsmAnd::TileId)tileId
                            zoom:(OsmAnd::ZoomLevel)zoom
                     isCancelled:(const std::function<bool()>&)isCancelled
                        response:(OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesResponse&)outResponse;
- (BOOL)isInvalidated;
- (BOOL)isActiveApplicableRequestId:(uint64_t)requestId;
- (BOOL)waitForRequest:(OATopWikiOnlineAmenitiesRequest * __strong *)request
                tileId:(OsmAnd::TileId)tileId
                  zoom:(OsmAnd::ZoomLevel)zoom
           isCancelled:(const std::function<bool()>&)isCancelled
              response:(OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesResponse&)outResponse;
- (void)dispatchLoadForRequest:(OATopWikiOnlineAmenitiesRequest *)request;
- (void)completeLoadForRequest:(OATopWikiOnlineAmenitiesRequest *)request
                        loaded:(BOOL)loaded
                     amenities:(const QList<std::shared_ptr<const OsmAnd::Amenity>>&)amenities;
- (BOOL)loadAmenitiesForVisibleBBox31:(const OsmAnd::AreaI&)visibleBBox31
                             center31:(const OsmAnd::PointI&)center31
                                 zoom:(OsmAnd::ZoomLevel)zoom
                          isCancelled:(const std::function<bool()>&)isCancelled
                            amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities;
- (void)invalidateCurrentProviderTiles;

@end

@implementation OATopWikiOnlineAmenitiesRequest

- (instancetype)initWithRequestId:(uint64_t)newRequestId
                    visibleBBox31:(const OsmAnd::AreaI&)newVisibleBBox31
                         center31:(const OsmAnd::PointI&)newCenter31
                             zoom:(OsmAnd::ZoomLevel)newZoom
{
    self = [super init];
    if (self)
    {
        requestId = newRequestId;
        visibleBBox31 = newVisibleBBox31;
        center31 = newCenter31;
        zoom = newZoom;
        state = OATopWikiOnlineAmenitiesStateLoading;
        amenities.clear();
    }
    return self;
}

@end

@implementation OATopWikiOnlineAmenitiesController

- (instancetype)initWithDataProvider:(PoiUIFilterDataProvider *)dataProvider
{
    self = [super init];
    if (self)
    {
        _dataProvider = dataProvider;
        _nextRequestId = 1;
        _latestVisibleZoom = OsmAnd::InvalidZoomLevel;
        _hasLatestVisibleState = NO;
        _activeRequest = nil;
        _needsNewRequest = NO;
        _invalidated = NO;
    }
    return self;
}

- (void)setSymbolsProvider:(const std::shared_ptr<OsmAnd::AmenitySymbolsProvider>&)symbolsProvider
{
    QMutexLocker scopedLocker(&_stateMutex);
    _symbolsProvider = symbolsProvider;
}

- (void)setDataReadyHandler:(void (^)(const QList<std::shared_ptr<const OsmAnd::Amenity>>&))dataReadyHandler
{
    QMutexLocker scopedLocker(&_stateMutex);
    _dataReadyHandler = [dataReadyHandler copy];
}

- (void)updateVisibleBBox31:(OsmAnd::AreaI)visibleBBox31 zoom:(OsmAnd::ZoomLevel)zoom
{
    BOOL shouldInvalidateTiles = NO;
    {
        QMutexLocker scopedLocker(&_stateMutex);
        _latestVisibleBBox31 = visibleBBox31;
        _latestVisibleZoom = zoom;
        _hasLatestVisibleState = OAIsValidVisibleState(visibleBBox31, zoom);
        if (_invalidated)
            return;

        const BOOL wasNeedingNewRequest = _needsNewRequest;
        _needsNewRequest = _activeRequest
            && !OAIsRequestApplicableToVisibleState(_activeRequest, _hasLatestVisibleState, _latestVisibleBBox31, _latestVisibleZoom);
        shouldInvalidateTiles = _needsNewRequest && !wasNeedingNewRequest;
    }

    if (shouldInvalidateTiles)
    {
        _stateWaitCondition.wakeAll();
        [self invalidateCurrentProviderTiles];
    }
}

- (void)invalidate
{
    {
        QMutexLocker scopedLocker(&_stateMutex);
        if (_invalidated)
            return;

        _invalidated = YES;
        _latestVisibleBBox31 = OsmAnd::AreaI();
        _latestVisibleZoom = OsmAnd::InvalidZoomLevel;
        _hasLatestVisibleState = NO;
        _activeRequest = nil;
        _needsNewRequest = NO;
    }

    _stateWaitCondition.wakeAll();
    [self invalidateCurrentProviderTiles];
}

- (BOOL)obtainAmenitiesForTileId:(OsmAnd::TileId)tileId
                            zoom:(OsmAnd::ZoomLevel)zoom
                     isCancelled:(const std::function<bool()>&)isCancelled
                        response:(OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesResponse&)outResponse
{
    outResponse.amenities.clear();
    outResponse.isOutdated = nullptr;

    OATopWikiOnlineAmenitiesRequest *request = nil;
    BOOL shouldStartLoad = NO;
    {
        QMutexLocker scopedLocker(&_stateMutex);
        if (_invalidated)
        {
            outResponse.isOutdated = []() -> bool { return true; };
            return YES;
        }

        if (!_hasLatestVisibleState || _latestVisibleZoom != zoom)
        {
            outResponse.isOutdated = []() -> bool { return true; };
            return YES;
        }

        if (_activeRequest
            && !_needsNewRequest
            && OAIsRequestApplicableToVisibleState(_activeRequest, _hasLatestVisibleState, _latestVisibleBBox31, _latestVisibleZoom))
        {
            request = _activeRequest;
        }
        else
        {
            const auto requestVisibleBBox31 = OAExpandVisibleBBox31(_latestVisibleBBox31);
            if (!OAIsValidVisibleState(requestVisibleBBox31, _latestVisibleZoom))
            {
                outResponse.isOutdated = []() -> bool { return true; };
                return YES;
            }

            request = [[OATopWikiOnlineAmenitiesRequest alloc] initWithRequestId:_nextRequestId++
                                                                   visibleBBox31:requestVisibleBBox31
                                                                        center31:_latestVisibleBBox31.center()
                                                                            zoom:_latestVisibleZoom];
            _activeRequest = request;
            _needsNewRequest = NO;
            shouldStartLoad = YES;
        }
    }

    if (shouldStartLoad)
    {
        _stateWaitCondition.wakeAll();
        [self dispatchLoadForRequest:request];
    }

    if (![self waitForRequest:&request
                       tileId:tileId
                         zoom:zoom
                  isCancelled:isCancelled
                     response:outResponse])
    {
        return NO;
    }

    OATopWikiOnlineAmenitiesController *controller = self;
    const uint64_t requestId = request ? request->requestId : 0;
    outResponse.isOutdated =
        [controller, requestId]() -> bool
        {
            return ![controller isActiveApplicableRequestId:requestId];
        };

    return YES;
}

- (BOOL)isInvalidated
{
    QMutexLocker scopedLocker(&_stateMutex);
    return _invalidated;
}

- (BOOL)isActiveApplicableRequestId:(uint64_t)requestId
{
    QMutexLocker scopedLocker(&_stateMutex);
    return !_invalidated
        && !_needsNewRequest
        && _activeRequest
        && _activeRequest->requestId == requestId
        && OAIsRequestApplicableToVisibleState(_activeRequest, _hasLatestVisibleState, _latestVisibleBBox31, _latestVisibleZoom);
}

- (BOOL)waitForRequest:(OATopWikiOnlineAmenitiesRequest * __strong *)request
                tileId:(OsmAnd::TileId)tileId
                  zoom:(OsmAnd::ZoomLevel)zoom
           isCancelled:(const std::function<bool()>&)isCancelled
              response:(OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesResponse&)outResponse
{
    const auto tileBBox31 = OsmAnd::Utilities::tileBoundingBox31(tileId, zoom);
    QMutexLocker scopedLocker(&_stateMutex);
    while (true)
    {
        if (_invalidated)
        {
            outResponse.amenities.clear();
            outResponse.isOutdated = []() -> bool { return true; };
            return YES;
        }

        OATopWikiOnlineAmenitiesRequest *currentRequest = request ? *request : nil;
        if (!currentRequest)
        {
            outResponse.amenities.clear();
            outResponse.isOutdated = []() -> bool { return true; };
            return YES;
        }

        if (_activeRequest
            && _activeRequest != currentRequest
            && !_needsNewRequest
            && OARequestIntersectsTileBBox(_activeRequest, tileBBox31, zoom))
        {
            currentRequest = _activeRequest;
            if (request)
                *request = currentRequest;
            continue;
        }

        switch (currentRequest->state)
        {
            case OATopWikiOnlineAmenitiesStateReady:
                outResponse.amenities = currentRequest->amenities;
                return YES;
            case OATopWikiOnlineAmenitiesStateFailed:
                outResponse.amenities.clear();
                return YES;
            case OATopWikiOnlineAmenitiesStateLoading:
            case OATopWikiOnlineAmenitiesStateUndefined:
                break;
        }

        if (isCancelled && isCancelled())
            return NO;

        _stateWaitCondition.wait(&_stateMutex, kWikiOnlineAmenitiesWaitIntervalMs);
    }
}

- (void)dispatchLoadForRequest:(OATopWikiOnlineAmenitiesRequest *)request
{
    __weak OATopWikiOnlineAmenitiesController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OATopWikiOnlineAmenitiesController *strongSelf = weakSelf;
        if (!strongSelf || !request)
            return;

        QList<std::shared_ptr<const OsmAnd::Amenity>> amenities;
        const auto requestCancelled =
            [weakSelf]() -> bool
            {
                OATopWikiOnlineAmenitiesController *controller = weakSelf;
                return !controller || [controller isInvalidated];
            };
        const BOOL loaded = [strongSelf loadAmenitiesForVisibleBBox31:request->visibleBBox31
                                                             center31:request->center31
                                                                 zoom:request->zoom
                                                          isCancelled:requestCancelled
                                                            amenities:&amenities];
        [strongSelf completeLoadForRequest:request loaded:loaded amenities:amenities];
    });
}

- (void)completeLoadForRequest:(OATopWikiOnlineAmenitiesRequest *)request
                        loaded:(BOOL)loaded
                     amenities:(const QList<std::shared_ptr<const OsmAnd::Amenity>>&)amenities
{
    void (^dataReadyHandler)(const QList<std::shared_ptr<const OsmAnd::Amenity>>&) = nil;
    {
        QMutexLocker scopedLocker(&_stateMutex);
        if (!request)
            return;

        if (loaded)
        {
            request->state = OATopWikiOnlineAmenitiesStateReady;
            request->amenities = amenities;
        }
        else
        {
            request->state = OATopWikiOnlineAmenitiesStateFailed;
            request->amenities.clear();
        }

        if (loaded
            && !_invalidated
            && _activeRequest == request
            && !_needsNewRequest
            && OAIsRequestApplicableToVisibleState(request, _hasLatestVisibleState, _latestVisibleBBox31, _latestVisibleZoom))
        {
            dataReadyHandler = [_dataReadyHandler copy];
        }
    }

    _stateWaitCondition.wakeAll();

    if (dataReadyHandler)
        dataReadyHandler(amenities);
}

- (BOOL)loadAmenitiesForVisibleBBox31:(const OsmAnd::AreaI&)visibleBBox31
                             center31:(const OsmAnd::PointI&)center31
                                 zoom:(OsmAnd::ZoomLevel)zoom
                          isCancelled:(const std::function<bool()>&)isCancelled
                            amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
{
    if (amenities)
        amenities->clear();

    if (!_dataProvider)
        return YES;

    OAResultMatcher<OAPOI *> *matcher =
        [[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *poi) {
            Q_UNUSED(poi);
            return !isCancelled || !isCancelled();
        } cancelledFunc:^BOOL{
            return isCancelled && isCancelled();
        }];

    const auto centerLatLon = OsmAnd::Utilities::convert31ToLatLon(center31);
    const double topLatitude = OsmAnd::Utilities::get31LatitudeY(visibleBBox31.top());
    const double bottomLatitude = OsmAnd::Utilities::get31LatitudeY(visibleBBox31.bottom());
    const double leftLongitude = OsmAnd::Utilities::get31LongitudeX(visibleBBox31.left());
    const double rightLongitude = OsmAnd::Utilities::get31LongitudeX(visibleBBox31.right());

    NSArray<OAPOI *> *pois = [_dataProvider searchAmenitiesWithLat:centerLatLon.latitude
                                                               lon:centerLatLon.longitude
                                                       topLatitude:topLatitude
                                                    bottomLatitude:bottomLatitude
                                                     leftLongitude:leftLongitude
                                                    rightLongitude:rightLongitude
                                                              zoom:zoom
                                                           matcher:matcher];
    if (isCancelled && isCancelled())
    {
        if (amenities)
            amenities->clear();
        return NO;
    }

    for (OAPOI *poi in pois)
    {
        if (isCancelled && isCancelled())
        {
            if (amenities)
                amenities->clear();
            return NO;
        }

        const auto amenity = OASyntheticAmenityFromPoi(poi);
        if (amenity && amenities)
            amenities->push_back(amenity);
    }

    return YES;
}

- (void)invalidateCurrentProviderTiles
{
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> symbolsProvider;
    {
        QMutexLocker scopedLocker(&_stateMutex);
        symbolsProvider = _symbolsProvider.lock();
    }

    if (symbolsProvider)
        symbolsProvider->invalidateTiles();
}

@end

@interface OAPOILayer ()

- (void)updateWikiOnlineAmenitiesControllerVisibleState;
- (void)invalidateWikiOnlineAmenitiesController;

@end

@implementation OAPOILayer
{
    BOOL _showPoiOnMap;
    BOOL _showWikiOnMap;

    OAPOIUIFilter *_poiUiFilter;
    OAPOIUIFilter *_wikiUiFilter;
    OAAmenityExtendedNameFilter *_poiUiNameFilter;
    OAAmenityExtendedNameFilter *_wikiUiNameFilter;
    NSString *_poiCategoryName;
    NSString *_poiFilterName;
    NSString *_poiTypeName;
    NSString *_poiKeyword;
    NSString *_prefLang;
    
    OAPOIFiltersHelper *_filtersHelper;
    OAPOILayerTopPlacesProvider *_topPlacesProvider;
    
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _wikiSymbolsProvider;
    OATopWikiOnlineAmenitiesController *_wikiOnlineAmenitiesController;
    BOOL _topPlacesEnabled;
    CGFloat _topPlacesTextScale;
    EOAWikiDataSourceType _topPlacesWikiDataSourceType;
    NSSet<NSString *> *_topPlacesWikipediaResourceIds;
    
    CGSize _screenSize;
}

- (void)onMapFrameRendered
{
    [_topPlacesProvider drawTopPlacesIfNeeded:NO];
}

- (void)onMapFrameAnimatorsUpdated
{
    [self updateWikiOnlineAmenitiesControllerVisibleState];
}

- (void)initLayer
{
    [super initLayer];

    _screenSize = CGSizeMake([OAUtilities calculateScreenWidth], [OAUtilities calculateScreenHeight]);

    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _topPlacesTextScale = 1.f;
    _topPlacesWikipediaResourceIds = [NSSet set];
    _topPlacesProvider = [[OAPOILayerTopPlacesProvider alloc] initWithTopPlaceBaseOrder:(int)[self getTopPlaceBaseOrder]];
}

- (NSString *) layerId
{
    return kPoiLayerId;
}

- (void)updateWikiOnlineAmenitiesControllerVisibleState
{
    if (_wikiOnlineAmenitiesController)
        [_wikiOnlineAmenitiesController updateVisibleBBox31:[self.mapView getVisibleBBox31] zoom:self.mapView.zoomLevel];
}

- (void)invalidateWikiOnlineAmenitiesController
{
    if (_wikiOnlineAmenitiesController)
    {
        [_wikiOnlineAmenitiesController invalidate];
        _wikiOnlineAmenitiesController = nil;
    }
}

- (void) resetLayer
{
    if (_amenitySymbolsProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
        _amenitySymbolsProvider.reset();
        _showPoiOnMap = NO;
    }
    if (_wikiSymbolsProvider)
    {
        [self invalidateWikiOnlineAmenitiesController];
        [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
        _wikiSymbolsProvider.reset();
        _showWikiOnMap = NO;
    }
    else
    {
        [self invalidateWikiOnlineAmenitiesController];
    }
    [_topPlacesProvider resetLayer];
}

- (void) updateVisiblePoiFilter
{
    if (_showPoiOnMap && _amenitySymbolsProvider)
    {
        [self.mapViewController runWithRenderSync:^{
            [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
            _amenitySymbolsProvider.reset();
        }];
        _showPoiOnMap = NO;
    }

    if (_showWikiOnMap && _wikiSymbolsProvider)
    {
        [self.mapViewController runWithRenderSync:^{
            [self invalidateWikiOnlineAmenitiesController];
            [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
            _wikiSymbolsProvider.reset();
        }];
        _showWikiOnMap = NO;
    }
    else
    {
        [self invalidateWikiOnlineAmenitiesController];
    }

    OAPOIUIFilter *wikiFilter = [_filtersHelper getTopWikiPoiFilter];
    NSMutableArray<OAPOIUIFilter *> *filtersToExclude = [NSMutableArray array];
    if (wikiFilter)
        [filtersToExclude addObject:wikiFilter];

    BOOL isWikiEnabled = [[OAPluginsHelper getPlugin:OAWikipediaPlugin.class] isEnabled];
    NSMutableSet<OAPOIUIFilter *> *filters = [NSMutableSet setWithSet:[_filtersHelper getSelectedPoiFilters:filtersToExclude]];
    if (wikiFilter && (!isWikiEnabled || ![_filtersHelper isPoiFilterSelectedByFilterId:[OAPOIFiltersHelper getTopWikiPoiFilterId]]))
    {
        [filters removeObject:wikiFilter];
        wikiFilter = nil;
    }
    [OAPOIUIFilter combineStandardPoiFilters:filters];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showPoiOnMap:filters wikiOnMap:wikiFilter];
        [self syncTopPlacesProviderStateWithWikiFilter:wikiFilter];
    });
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    [self updateVisiblePoiFilter];
    
    return YES;
}

- (void) showPoiOnMap:(NSMutableSet<OAPOIUIFilter *> *)filters wikiOnMap:(OAPOIUIFilter *)wikiOnMap
{
    _showPoiOnMap = YES;
    _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;

    _wikiUiFilter = wikiOnMap;
    _showWikiOnMap = wikiOnMap != nil;

    BOOL noValidByName = filters.count == 1
            && [filters.allObjects.firstObject.name isEqualToString:OALocalizedString(@"poi_filter_by_name")]
            && !filters.allObjects.firstObject.filterByName;

    _poiUiFilter = noValidByName ? nil : [_filtersHelper combineSelectedFilters:filters];
    if (noValidByName)
        [_filtersHelper removeSelectedPoiFilter:filters.allObjects.firstObject];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowPoiUiFilterOnMap];
    });
}

- (void) doShowPoiUiFilterOnMap
{
    if (!_poiUiFilter && !_wikiUiFilter)
        return;

    [self.mapViewController runWithRenderSync:^{

        void (^_generate)(OAPOIUIFilter *) = ^(OAPOIUIFilter *f) {
            BOOL isWiki = [f isWikiFilter];

            auto categoriesFilter = QHash<QString, QStringList>();
            NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [f getAcceptedTypes];
            for (OAPOICategory *category in types.keyEnumerator)
            {
                QStringList list = QStringList();
                NSSet<NSString *> *subcategories = [types objectForKey:category];
                if (subcategories != [OAPOIBaseType nullSet])
                {
                    for (NSString *sub in subcategories)
                        list << QString::fromNSString(sub);
                }
                categoriesFilter.insert(QString::fromNSString(category.name), list);
            }

            if (isWiki)
                _wikiUiNameFilter = [f getNameAmenityFilter:f.filterByName];
            else
                _poiUiNameFilter = [f getNameAmenityFilter:f.filterByName];

            __weak OAAmenityExtendedNameFilter *weakWikiUiNameFilter = _wikiUiNameFilter;
            __weak OAPOIUIFilter *weakWikiUiFilter = _wikiUiFilter;
            __weak OAAmenityExtendedNameFilter *weakPoiUiNameFilter = _poiUiNameFilter;
            __weak OAPOIUIFilter *weakPoiUiFilter = _poiUiFilter;
            OsmAnd::ObfPoiSectionReader::VisitorFunction amenityFilter =
                    [=](const std::shared_ptr<const OsmAnd::Amenity> &amenity)
                    {
                        OAAmenityExtendedNameFilter *wikiUiNameFilter = weakWikiUiNameFilter;
                        OAPOIUIFilter *wikiUiFilter = weakWikiUiFilter;
                        OAAmenityExtendedNameFilter *poiUiNameFilter = weakPoiUiNameFilter;
                        OAPOIUIFilter *poiUiFilter = weakPoiUiFilter;

                        OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
                        QHash<QString, QString> decodedValues;
                        bool decodedValuesResolved = false;
                        const auto obtainDecodedValues =
                                [&amenity, &decodedValues, &decodedValuesResolved]() -> const QHash<QString, QString>&
                                {
                                    if (!decodedValuesResolved)
                                    {
                                        decodedValues = amenity->getDecodedValuesHash();
                                        decodedValuesResolved = true;
                                    }
                                    return decodedValues;
                                };
                        
                        BOOL check = !wikiUiNameFilter && !wikiUiFilter && poiUiNameFilter
                                && poiUiFilter && poiUiFilter.filterByName && poiUiFilter.filterByName.length > 0;
                        BOOL accepted = poiUiNameFilter
                                && [poiUiNameFilter acceptAmenity:amenity values:obtainDecodedValues() type:type];

                        if (!isWiki && [type.tag isEqualToString:OSM_WIKI_CATEGORY])
                            return check ? accepted : false;
                        
                        if ((check && accepted)
                            || (isWiki
                                ? wikiUiNameFilter && [wikiUiNameFilter acceptAmenity:amenity values:obtainDecodedValues() type:type]
                                : accepted))
                        {
                            const auto& amenityDecodedValues = obtainDecodedValues();
                            BOOL isClosed = amenityDecodedValues[QString::fromNSString(OSM_DELETE_TAG)] == QString::fromNSString(OSM_DELETE_VALUE);
                            return !isClosed;
                        }

                        return false;
                    };

            if (isWiki)
                [self invalidateWikiOnlineAmenitiesController];

            if (isWiki && _wikiSymbolsProvider)
            {
                [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
                _wikiSymbolsProvider.reset();
            }
            else if (!isWiki && _amenitySymbolsProvider)
            {
                [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
                _amenitySymbolsProvider.reset();
            }

            OAAppSettings *settings = OAAppSettings.sharedManager;
            BOOL nightMode = settings.nightMode;
            BOOL showLabels = settings.mapSettingShowPoiLabel.get;
            NSString *lang = settings.settingPrefMapLanguage.get;
            BOOL transliterate = settings.settingMapLanguageTranslit.get;
            float textSize = settings.textSize.get;
            OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesProvider externalAmenitiesProvider = nullptr;
            if (isWiki && [f isTopWikiFilter] && settings.wikiDataSourceType.get == EOAWikiDataSourceTypeOnline)
            {
                PoiUIFilterDataProvider *wikiDataProvider = [[PoiUIFilterDataProvider alloc] initWithFilter:f];
                OATopWikiOnlineAmenitiesController *wikiOnlineAmenitiesController =
                    [[OATopWikiOnlineAmenitiesController alloc] initWithDataProvider:wikiDataProvider];
                __weak __typeof(self) weakSelf = self;
                [wikiOnlineAmenitiesController setDataReadyHandler:^(const QList<std::shared_ptr<const OsmAnd::Amenity>>& amenities) {
                    __typeof(self) strongSelf = weakSelf;
                    if (!strongSelf)
                        return;

                    [strongSelf->_topPlacesProvider notifyAmenitiesChanged:amenities];
                }];
                [wikiOnlineAmenitiesController updateVisibleBBox31:[self.mapView getVisibleBBox31]
                                                             zoom:self.mapView.zoomLevel];
                externalAmenitiesProvider =
                    [wikiOnlineAmenitiesController]
                    (const OsmAnd::TileId tileId,
                     const OsmAnd::ZoomLevel tileZoom,
                     const std::function<bool()>& isCancelled,
                     OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesResponse& outResponse) -> bool
                    {
                        return [wikiOnlineAmenitiesController obtainAmenitiesForTileId:tileId
                                                                                  zoom:tileZoom
                                                                           isCancelled:isCancelled
                                                                              response:outResponse];
                    };
                _wikiOnlineAmenitiesController = wikiOnlineAmenitiesController;
            }
            else if (isWiki)
            {
                _wikiOnlineAmenitiesController = nil;
            }

            const auto displayDensityFactor = self.mapViewController.displayDensityFactor;
            const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
            const uint32_t cacheSize = OACalculatePoiCacheSize(_screenSize, rasterTileSize);
            if (categoriesFilter.count() > 0)
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, &categoriesFilter, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), displayDensityFactor, 1.0, textSize, nightMode, showLabels, QString::fromNSString(lang), transliterate), self.pointsOrder, cacheSize, externalAmenitiesProvider));
            }
            else
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, nullptr, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), displayDensityFactor, 1.0, textSize, nightMode, showLabels, QString::fromNSString(lang), transliterate), self.pointsOrder, cacheSize, externalAmenitiesProvider));
            }

            if (isWiki && _wikiOnlineAmenitiesController && _wikiSymbolsProvider)
                [_wikiOnlineAmenitiesController setSymbolsProvider:_wikiSymbolsProvider];

            if (isWiki && _wikiSymbolsProvider)
            {
                __weak __typeof(self) weakSelf = self;
                _wikiSymbolsProvider->cache->setDataChangedHandler([weakSelf]() {
                    __typeof(self) strongSelf = weakSelf;
                    if (strongSelf)
                        [strongSelf notifyTopPlacesProviderIfWikiTilesCached];
                });
            }

            [self.mapView addTiledSymbolsProvider:kPOISymbolSection provider:isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider];
            if (isWiki)
            {
                [_topPlacesProvider drawTopPlacesIfNeeded:YES];
                [self notifyTopPlacesProviderIfWikiTilesCached];
            }
        };

        if (_poiUiFilter)
            _generate(_poiUiFilter);
        else
            _poiUiNameFilter = nil;

        if (_wikiUiFilter)
            _generate(_wikiUiFilter);
        else
            _wikiUiNameFilter = nil;

    }];
}

- (void)readVisibleWikiCacheStateShowWikiOnMap:(BOOL *)showWikiOnMap
                           wikiSymbolsProvider:(std::shared_ptr<OsmAnd::AmenitySymbolsProvider> *)wikiSymbolsProvider
                                  visibleTiles:(QVector<OsmAnd::TileId> *)visibleTiles
                                   visibleZoom:(OsmAnd::ZoomLevel *)visibleZoom
{
    __block BOOL localShowWikiOnMap = NO;
    __block std::shared_ptr<OsmAnd::AmenitySymbolsProvider> localWikiSymbolsProvider;
    __block QVector<OsmAnd::TileId> localVisibleTiles;
    __block OsmAnd::ZoomLevel localVisibleZoom = OsmAnd::InvalidZoomLevel;
    [self.mapViewController runWithRenderSync:^{
        localShowWikiOnMap = _showWikiOnMap;
        localWikiSymbolsProvider = _wikiSymbolsProvider;
        if (localWikiSymbolsProvider)
        {
            localVisibleTiles = self.mapView.visibleTiles;
            localVisibleZoom = self.mapView.zoomLevel;
        }
    }];

    if (showWikiOnMap)
        *showWikiOnMap = localShowWikiOnMap;
    if (wikiSymbolsProvider)
        *wikiSymbolsProvider = localWikiSymbolsProvider;
    if (visibleTiles)
        *visibleTiles = localVisibleTiles;
    if (visibleZoom)
        *visibleZoom = localVisibleZoom;
}

- (BOOL)areVisibleWikiTilesCached:(const QVector<OsmAnd::TileId> &)visibleTiles
                             zoom:(OsmAnd::ZoomLevel)visibleZoom
              wikiSymbolsProvider:(const std::shared_ptr<OsmAnd::AmenitySymbolsProvider> &)wikiSymbolsProvider
{
    for (const auto& tileId : visibleTiles)
    {
        if (!wikiSymbolsProvider->cache->contains(tileId, visibleZoom))
            return NO;
    }
    return YES;
}

- (void)notifyTopPlacesProviderIfWikiTilesCached
{
    BOOL showWikiOnMap = NO;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> wikiSymbolsProvider;
    QVector<OsmAnd::TileId> visibleTiles;
    OsmAnd::ZoomLevel visibleZoom = OsmAnd::InvalidZoomLevel;
    [self readVisibleWikiCacheStateShowWikiOnMap:&showWikiOnMap
                                   wikiSymbolsProvider:&wikiSymbolsProvider
                                          visibleTiles:&visibleTiles
                                           visibleZoom:&visibleZoom];

    if (!showWikiOnMap)
        return;

    if (!wikiSymbolsProvider || visibleTiles.isEmpty() || visibleZoom == OsmAnd::InvalidZoomLevel)
        return;

    if (visibleZoom < wikiSymbolsProvider->getMinZoom()
        || visibleZoom > wikiSymbolsProvider->getMaxZoom())
        return;

    if ([self areVisibleWikiTilesCached:visibleTiles zoom:visibleZoom wikiSymbolsProvider:wikiSymbolsProvider])
    {
        QList<std::shared_ptr<const OsmAnd::Amenity>> amenities;
        NSMutableSet<NSNumber *> *seenAmenityIds = [NSMutableSet set];

        for (const auto& tileId : visibleTiles)
        {
            QList<std::shared_ptr<const OsmAnd::Amenity>> cachedAmenities;
            if (!wikiSymbolsProvider->cache->obtainAmenities(tileId, visibleZoom, cachedAmenities))
                continue;

            for (const auto& amenity : cachedAmenities)
            {
                NSNumber *amenityId = @((uint64_t)amenity->id);
                if ([seenAmenityIds containsObject:amenityId])
                    continue;

                [seenAmenityIds addObject:amenityId];
                amenities.push_back(amenity);
            }
        }

        [_topPlacesProvider notifyAmenitiesChanged:amenities];
    }
}

- (NSSet<NSString *> *)currentWikipediaResourceIds
{
    NSArray<OAResourceSwiftItem *> *items = [OAResourcesUISwiftHelper findWikiMapRegionsAtCurrentMapLocation];
    NSArray<NSString *> *resourceIds = [items valueForKey:@"resourceId"];
    return [NSSet setWithArray:resourceIds ?: @[]];
}

- (void)syncTopPlacesProviderStateWithWikiFilter:(OAPOIUIFilter *)wikiFilter
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    BOOL enabled = wikiFilter != nil && settings.wikiShowImagePreviews.get;
    CGFloat textScale = OAAppSettings.sharedManager.textSize.get;// * self.mapViewController.displayDensityFactor;
    EOAWikiDataSourceType wikiType = settings.wikiDataSourceType.get;
    NSSet<NSString *> *resourceIds = [self currentWikipediaResourceIds];

    BOOL shouldReset = _topPlacesEnabled != enabled
        || _topPlacesWikiDataSourceType != wikiType
        || ![_topPlacesWikipediaResourceIds isEqualToSet:resourceIds];
    BOOL shouldRefreshVisiblePlaces = fabs(_topPlacesTextScale - textScale) >= 0.0001f;

    _topPlacesEnabled = enabled;
    _topPlacesTextScale = textScale;
    _topPlacesWikiDataSourceType = wikiType;
    _topPlacesWikipediaResourceIds = resourceIds;

    [_topPlacesProvider setTextScale:textScale];
    [_topPlacesProvider setEnabled:enabled];

    if (!enabled)
        return;

    if (shouldReset)
    {
        [_topPlacesProvider resetLayer];
        [_topPlacesProvider drawTopPlacesIfNeeded:YES];
        [self notifyTopPlacesProviderIfWikiTilesCached];
    }
    else if (shouldRefreshVisiblePlaces)
    {
        [_topPlacesProvider refreshVisiblePlaces];
    }
}

- (BOOL) beginWithOrAfterSpace:(NSString *)str text:(NSString *)text
{
    return [self beginWith:str text:text] || [self beginWithAfterSpace:str text:text];
}

- (BOOL) beginWith:(NSString *)str text:(NSString *)text
{
    return [[text lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
}

- (BOOL) beginWithAfterSpace:(NSString *)str text:(NSString *)text
{
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0 || r.location + 1 >= text.length)
        return NO;
    
    NSString *s = [text substringFromIndex:r.location + 1];
    return [[s lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
}

- (void) addRoute:(NSMutableArray<OATargetPoint *> *)points touchPoint:(CGPoint)touchPoint mapObj:(const std::shared_ptr<const OsmAnd::MapObject> &)mapObj
{
    CGPoint topLeft;
    topLeft.x = touchPoint.x - kTrackSearchDelta;
    topLeft.y = touchPoint.y - kTrackSearchDelta;
    CGPoint bottomRight;
    bottomRight.x = touchPoint.x + kTrackSearchDelta;
    bottomRight.y = touchPoint.y + kTrackSearchDelta;
    OsmAnd::PointI topLeft31;
    OsmAnd::PointI bottomRight31;
    [self.mapView convert:topLeft toLocation:&topLeft31];
    [self.mapView convert:bottomRight toLocation:&bottomRight31];
    
    OsmAnd::AreaI area31(topLeft31, bottomRight31);
    const auto center31 = area31.center();
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(center31);
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    auto networkRouteSelector = std::make_shared<OsmAnd::NetworkRouteSelector>(self.app.resourcesManager->obfsCollection);
    auto routes = networkRouteSelector->getRoutes(area31, false, nullptr);
    NSMutableSet<OARouteKey *> *routeKeys = [NSMutableSet set];
    for (auto it = routes.begin(); it != routes.end(); ++it)
    {
        OARouteKey *routeKey = [[OARouteKey alloc] initWithKey:it.key()];
        if (![routeKeys containsObject:routeKey] && [self isRouteEnabledForKey:routeKey])
        {
            [routeKeys addObject:routeKey];
            [self putRouteToSelected:routeKey location:coord mapObj:mapObj points:points area:area31];
        }
    }
}

- (BOOL)isRouteEnabledForKey:(OARouteKey *)routeKey
{
    QString renderingPropertyAttr = routeKey.routeKey.type->renderingPropertyAttr;
    if (!renderingPropertyAttr.isEmpty())
    {
        OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
        OAMapStyleParameter *routesParameter = [styleSettings getParameter:renderingPropertyAttr.toNSString()];
        return routesParameter
            && routesParameter.storedValue.length > 0
            && ![routesParameter.storedValue isEqualToString:@"false"]
            && ![routesParameter.storedValue isEqualToString:@"disabled"];
    }
    return NO;
}

- (void) putRouteToSelected:(OARouteKey *)key location:(CLLocationCoordinate2D)location mapObj:(const std::shared_ptr<const OsmAnd::MapObject> &)mapObj points:(NSMutableArray<OATargetPoint *> *)points area:(OsmAnd::AreaI)area
{
    OATargetPoint *point = [[OATargetPoint alloc] init];
    point.location = location;
    point.type = OATargetNetworkGPX;
    point.targetObj = key;
    OANetworkRouteDrawable *drawable = [[OANetworkRouteDrawable alloc] initWithRouteKey:key];
    point.icon = drawable.getIcon;
    point.title = [key getRouteName];
    NSArray *areaPoints = @[@(area.topLeft.x), @(area.topLeft.y), @(area.bottomRight.x), @(area.bottomRight.y)];
    point.values = @{ @"area": areaPoints };

    point.sortIndex = (NSInteger)point.type;

    if (![points containsObject:point])
        [points addObject:point];
}

- (OAPOI *) getAmenity:(id)object
{
    if ([object isKindOfClass:SelectedMapObject.class])
    {
        SelectedMapObject *obj = object;
        object = obj.object;
    }
    if ([object isKindOfClass:OAPOI.class])
    {
        return (OAPOI *)object;
    }
    else if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *baseDetailsObject = object;
        return (baseDetailsObject).syntheticAmenity;
    }
    return nil;
}

- (NSString *) getAmenityName:(OAPOI *)amemity
{
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if ([amemity.type.category isWiki])
    {
        if (!locale || NSStringIsEmpty(locale))
            locale = @"";
        
        locale = [OAPluginsHelper onGetMapObjectsLocale:amemity preferredLocale:locale];
    }
    
    return [amemity getName:locale transliterate:[OAAppSettings sharedManager].settingMapLanguageTranslit.get];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:OAPOI.class])
        return [self getTargetPoint:obj renderedObject:nil placeDetailsObject:nil];
    else if ([obj isKindOfClass:OARenderedObject.class])
        return [self getTargetPoint:nil renderedObject:obj placeDetailsObject:nil];
    else if ([obj isKindOfClass:BaseDetailsObject.class])
        return [self getTargetPoint:nil renderedObject:nil placeDetailsObject:obj];
    return nil;
}

- (OATargetPoint *) getTargetPoint:(OAPOI *)poi renderedObject:(OARenderedObject *)renderedObject placeDetailsObject:(BaseDetailsObject *)placeDetailsObject
{
    if (placeDetailsObject)
        poi = placeDetailsObject.syntheticAmenity;
    
    if (poi)
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        if (poi.type)
        {
            if ([poi.type.name isEqualToString:WIKI_PLACE])
                targetPoint.type = OATargetWiki;
            else
                targetPoint.type = OATargetPOI;
        }
        else
        {
            targetPoint.type = OATargetLocation;
        }
        
        if (!poi.type)
        {
            poi.type = [[OAPOILocationType alloc] init];

            if (poi.name.length == 0)
                poi.name = poi.type.name;
            if (poi.nameLocalized.length == 0)
                poi.nameLocalized = poi.type.nameLocalized;
            
            if (targetPoint.type != OATargetWiki)
                targetPoint.type = OATargetPOI;
        }
        
        targetPoint.location = CLLocationCoordinate2DMake(poi.latitude, poi.longitude);
        targetPoint.title = poi.nameLocalized ? poi.nameLocalized : poi.name;
        targetPoint.icon = [poi.type icon];
        
        targetPoint.values = poi.values;
        targetPoint.localizedNames = poi.localizedNames;
        targetPoint.localizedContent = poi.localizedContent;
        targetPoint.obfId = poi.obfId;
        
        targetPoint.targetObj = poi;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    else if (renderedObject)
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetRenderedObject;
        targetPoint.location = CLLocationCoordinate2DMake(renderedObject.labelLatLon.coordinate.latitude, renderedObject.labelLatLon.coordinate.longitude);
        targetPoint.values = renderedObject.tags;
        targetPoint.obfId = renderedObject.obfId;
        targetPoint.targetObj = renderedObject;
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        
        if (!poi)
            poi = [BaseDetailsObject convertRenderedObjectToAmenity:renderedObject];
        if (poi)
        {
            if (!targetPoint || targetPoint.title.length == 0)
                targetPoint.title = [RenderedObjectHelper getFirstNonEmptyNameFor:poi withRenderedObject:renderedObject];
            
            targetPoint.localizedNames = targetPoint.localizedNames.count > 0 ? targetPoint.localizedNames : poi.localizedNames;
            
            targetPoint.icon = [RenderedObjectHelper getIconWithRenderedObject:renderedObject];
            
        }
        return targetPoint;
    }
    
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (BOOL) showMenuAction:(id)object
{
    OAPOI *amenity = [self getAmenity:object];
    if (amenity && ([amenity.type.name isEqualToString:ROUTES] || [amenity.type.name hasPrefix:ROUTES]))
    {
        if ([amenity.subType isEqualToString:ROUTE_ARTICLE])
        {
            NSString *lang = [OAPluginsHelper onGetMapObjectsLocale:amenity preferredLocale:[OAUtilities preferredLang]];
            lang = [amenity getContentLanguage:DESCRIPTION_TAG lang:lang defLang:@"en"];
            NSString *name = [amenity getGpxFileName:lang];
            OATravelArticle *article = [OATravelObfHelper.shared getArticleByTitleWithTitle:name lang:lang readGpx:YES callback:nil];
            if (!article)
                return YES;
            [OATravelObfHelper.shared openTrackMenuWithArticle:article gpxFileName:name latLon:[amenity getLocation] adjustMapPosition:NO];
            return YES;
        }
        else if ([amenity isRouteTrack])
        {
            OATravelGpx *travelGpx = [[OATravelGpx alloc] initWithAmenity:amenity];
            [OATravelObfHelper.shared openTrackMenuWithArticle:travelGpx gpxFileName:[amenity getGpxFileName:nil] latLon:[amenity getLocation] adjustMapPosition:NO];
            return YES;
        }
    }
    
    return NO;
}

- (void)collectObjectsFromPoint:(MapSelectionResult *)result
                unknownLocation:(BOOL)unknownLocation
      excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    const auto objects = [_topPlacesProvider displayedAmenities];
    if (objects.isEmpty())
        return;
    
    OAMapRendererView *mapView =
    (OAMapRendererView *)[OARootViewController instance]
        .mapPanel.mapViewController.view;
    
    if ([mapView zoom] < START_ZOOM)
        return;
    
    int radius = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
    
    QList<OsmAnd::PointI> touchPolygon31 =
    [OANativeUtilities getPolygon31FromPixelAndRadius:result.point radius:radius];
    
    if (touchPolygon31.isEmpty())
        return;
    
    const auto topPlaces = [_topPlacesProvider topPlaces];
    NSMutableSet<NSNumber *> *topPlaceIds = [NSMutableSet setWithCapacity:topPlaces.size()];
    for (const auto& topPlace : topPlaces)
        [topPlaceIds addObject:@((uint64_t)topPlace->id)];
    
    for (const auto& amenity : objects)
    {
        const auto latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        
        if (![OANativeUtilities isPointInsidePolygonLat:coord.latitude
                                                    lon:coord.longitude
                                              polygon31:touchPolygon31])
            continue;

        OAPOI *poi = [OAAmenitySearcher parsePOIByAmenity:amenity];
        if (!poi)
            continue;
        
        if ([topPlaceIds containsObject:@((uint64_t)amenity->id)])
        {
            [result collect:poi provider:self];
        }
    }
}

- (void)contextMenuDidShow:(id)targetObj
{
    [_topPlacesProvider updateSelectedTopPlaceId:[self topPlaceIdFromObject:targetObj]];
}

- (void)contextMenuDidHide
{
    [_topPlacesProvider updateSelectedTopPlaceId:nil];
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (NSNumber *)topPlaceIdFromObject:(id)object
{
    const auto topPlaces = [_topPlacesProvider topPlaces];
    NSMutableSet<NSNumber *> *topPlaceIds = [NSMutableSet setWithCapacity:topPlaces.size()];
    for (const auto& topPlace : topPlaces)
        [topPlaceIds addObject:@((uint64_t)topPlace->id)];

    if ([object isKindOfClass:SelectedMapObject.class])
        object = ((SelectedMapObject *)object).object;

    if ([object isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = (OAPOI *)object;
        NSNumber *placeId = @(OAResolveSyntheticAmenityId(poi));
        return [topPlaceIds containsObject:placeId] ? placeId : nil;
    }

    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *baseDetailsObject = object;
        NSNumber *syntheticPlaceId = @(OAResolveSyntheticAmenityId(baseDetailsObject.syntheticAmenity));
        if ([topPlaceIds containsObject:syntheticPlaceId])
            return syntheticPlaceId;

        for (id item in baseDetailsObject.objects)
        {
            if (![item isKindOfClass:OAPOI.class])
                continue;

            OAPOI *poi = (OAPOI *)item;
            NSNumber *placeId = @(OAResolveSyntheticAmenityId(poi));
            if ([topPlaceIds containsObject:placeId])
                return placeId;
        }
    }

    return nil;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    if ([self isTopPlace:selectedObject])
        return [self getTopPlaceBaseOrder];
    else
        return 0;
}

- (BOOL)isTopPlace:(id)object
{
    return [self topPlaceIdFromObject:object] != nil;
}

- (int)getTopPlaceBaseOrder
{
    return [self pointsOrder] - 100;
}

- (int)pointsOrder:(id)object
{
    return [self isTopPlace:object]
    ? [self getTopPlaceBaseOrder]
    : [self pointsOrder];
}

- (LatLon) parsePoiLatLon:(QString)value
{
    OASKGeoParsedPoint *p = [OASKMapUtils.shared decodeShortLinkStringS:value.toNSString()];
    return LatLon(p.getLatitude, p.getLongitude);
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    OAPOI *amenity = [self getAmenity:obj];
    return amenity ? [amenity getLocation] : nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    OAPOI *amenity = [self getAmenity:obj];
    if (amenity)
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_POI name:[self getAmenityName:amenity]];
    return nil;
}

@end
