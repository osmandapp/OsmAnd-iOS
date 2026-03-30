#import "OAPOIMapLayerData.h"

#import "OAAmenitySearcher+MapLayer.h"
#import "OAAmenitySearcher+cpp.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOIUIFilter.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OAAppSettings.h"
#import "OsmAndSharedWrapper.h"
#import "QuadRect.h"
#import "OsmAnd_Maps-Swift.h"

#include <math.h>

static const NSTimeInterval kOAPOIMapLayerDataRequestTimeout = 10.0;
static const NSInteger kOAPOIMapLayerTopPlacesLimit = 20;
static const NSInteger kOAPOIMapLayerTilePointsLimit = 25;
static const NSInteger kOAPOIMapLayerStartZoom = 5;
static const NSInteger kOAPOIMapLayerStartZoomRouteTrack = 11;
static const NSInteger kOAPOIMapLayerOfflineSearchExtraItems = 64;

static uint32_t OAPOISpreadSignedIdHash(const int64_t signedId)
{
    const uint64_t unsignedId = (uint64_t) signedId;
    uint32_t hash = (uint32_t)(unsignedId ^ (unsignedId >> 32));
    return hash ^ (hash >> 16);
}

static NSUInteger OAPOIDisplayBucketCountForItemCount(NSUInteger count)
{
    if (count <= 12)
        return 16;

    NSUInteger requiredCount = (NSUInteger) ceil((double) count / 0.75);
    NSUInteger bucketCount = 16;
    while (bucketCount < requiredCount)
        bucketCount <<= 1;
    return bucketCount;
}

static NSArray<OAPOIMapLayerItem *> *OAPOINormalizeDisplayOrder(NSArray<OAPOIMapLayerItem *> *items)
{
    if (items.count < 2)
        return items;

    const NSUInteger bucketCount = OAPOIDisplayBucketCountForItemCount(items.count);
    NSMutableArray<NSMutableArray<OAPOIMapLayerItem *> *> *buckets = [NSMutableArray arrayWithCapacity:bucketCount];
    for (NSUInteger i = 0; i < bucketCount; i++)
        [buckets addObject:[NSMutableArray array]];

    for (OAPOIMapLayerItem *item in items)
    {
        NSUInteger bucketIndex = OAPOISpreadSignedIdHash(item.signedId) & (bucketCount - 1);
        [buckets[bucketIndex] addObject:item];
    }

    NSMutableArray<OAPOIMapLayerItem *> *normalizedItems = [NSMutableArray arrayWithCapacity:items.count];
    for (NSMutableArray<OAPOIMapLayerItem *> *bucket in buckets)
        [normalizedItems addObjectsFromArray:bucket];
    return normalizedItems;
}

static NSArray<OAPOIMapLayerItem *> *OAPOIFilterUniqueDisplayItems(NSArray<OAPOIMapLayerItem *> *items)
{
    if (items.count < 2)
        return items;

    NSMutableSet<NSNumber *> *seenIds = [NSMutableSet setWithCapacity:items.count];
    NSMutableSet<NSString *> *seenWikidata = [NSMutableSet setWithCapacity:items.count];
    NSMutableArray<OAPOIMapLayerItem *> *uniqueItems = [NSMutableArray arrayWithCapacity:items.count];

    for (OAPOIMapLayerItem *item in items)
    {
        if (item.isRouteTrack)
        {
            [uniqueItems addObject:item];
            continue;
        }

        NSNumber *signedId = item.signedId >= 0 ? @(item.signedId) : nil;
        NSString *wikidata = item.wikidata.length > 0 ? item.wikidata : nil;

        BOOL duplicateById = signedId && [seenIds containsObject:signedId];
        BOOL duplicateByWikidata = wikidata && [seenWikidata containsObject:wikidata];

        if (signedId)
            [seenIds addObject:signedId];
        if (wikidata)
            [seenWikidata addObject:wikidata];

        if (!duplicateById && !duplicateByWikidata)
            [uniqueItems addObject:item];
    }

    return uniqueItems;
}

@interface OAPOIMapLayerSearchResult : NSObject

@property (nonatomic, copy) NSArray<OAPOIMapLayerItem *> *results;
@property (nonatomic, copy) NSArray<OAPOIMapLayerItem *> *displayedResults;
@property (nonatomic, strong, nullable) OAPOIUIFilter *topPlacesFilter;
@property (nonatomic, assign) BOOL deferredResults;

@end

@implementation OAPOIMapLayerSearchResult
@end

@implementation OAPOITileBoxRequest
{
    QuadRect *_latLonBounds;
}

- (instancetype)initWithMapView:(OAMapRendererView *)mapView
{
    const auto visibleBBox31 = mapView.getVisibleBBox31;
    return [self initWithVisibleBBox31:visibleBBox31 zoom:(NSInteger) mapView.zoom];
}

- (instancetype)initWithVisibleBBox31:(const OsmAnd::AreaI &)visibleBBox31 zoom:(NSInteger)zoom
{
    self = [super init];
    if (self)
    {
        _zoom = zoom;

        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(visibleBBox31.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(visibleBBox31.bottomRight);

        _latLonBounds = [[QuadRect alloc] initWithLeft:topLeft.longitude
                                                   top:topLeft.latitude
                                                 right:bottomRight.longitude
                                                bottom:bottomRight.latitude];

        _left = (NSInteger) floor([OASKMapUtils.shared getTileNumberXZoom:zoom longitude:_latLonBounds.left]);
        _top = (NSInteger) floor([OASKMapUtils.shared getTileNumberYZoom:zoom latitude:_latLonBounds.top]);
        _right = (NSInteger) ceil([OASKMapUtils.shared getTileNumberXZoom:zoom longitude:_latLonBounds.right]);
        _bottom = (NSInteger) ceil([OASKMapUtils.shared getTileNumberYZoom:zoom latitude:_latLonBounds.bottom]);
        _width = MAX(_right - _left, 1);
        _height = MAX(_bottom - _top, 1);
    }
    return self;
}

- (QuadRect *)latLonBounds
{
    return _latLonBounds;
}

- (instancetype)extendTileExtentX:(NSInteger)tileExtentX tileExtentY:(NSInteger)tileExtentY
{
    const double maxTile = static_cast<double>(OsmAnd::Utilities::getPowZoom((OsmAnd::ZoomLevel) _zoom));
    const double leftTile = MAX((double)_left - tileExtentX, 0.0);
    const double topTile = MAX((double)_top - tileExtentY, 0.0);
    const double rightTile = MIN((double)_right + tileExtentX, maxTile - 0.000001);
    const double bottomTile = MIN((double)_bottom + tileExtentY, maxTile - 0.000001);

    QuadRect *rect = [[QuadRect alloc] initWithLeft:OsmAnd::Utilities::getLongitudeFromTile((OsmAnd::ZoomLevel) _zoom, leftTile)
                                                top:OsmAnd::Utilities::getLatitudeFromTile((OsmAnd::ZoomLevel) _zoom, topTile)
                                              right:OsmAnd::Utilities::getLongitudeFromTile((OsmAnd::ZoomLevel) _zoom, rightTile)
                                             bottom:OsmAnd::Utilities::getLatitudeFromTile((OsmAnd::ZoomLevel) _zoom, bottomTile)];
    OsmAnd::PointI topLeft31 =
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(rect.top, rect.left));
    OsmAnd::PointI bottomRight31 =
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(rect.bottom, rect.right));
    return [[OAPOITileBoxRequest alloc] initWithVisibleBBox31:OsmAnd::AreaI(topLeft31, bottomRight31) zoom:_zoom];
}

- (BOOL)containsRequest:(OAPOITileBoxRequest *)request
{
    return request && [_latLonBounds contains:request.latLonBounds];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[OAPOITileBoxRequest alloc] initWithVisibleBBox31:OsmAnd::AreaI(
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latLonBounds.top, _latLonBounds.left)),
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latLonBounds.bottom, _latLonBounds.right)))
                                                            zoom:_zoom];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:OAPOITileBoxRequest.class])
        return NO;
    OAPOITileBoxRequest *other = (OAPOITileBoxRequest *) object;
    return _left == other.left
        && _top == other.top
        && _width == other.width
        && _height == other.height
        && _zoom == other.zoom;
}

- (NSUInteger)hash
{
    return (((((_left * 31u) + _top) * 31u) + _width) * 31u + _height) * 31u + _zoom;
}

@end

@implementation OAPOIMapLayerItem
{
    std::shared_ptr<const OsmAnd::Amenity> _amenity;
    OAPOI *_fallbackPoi;
    OAPOI *_cachedPoi;
    OAPOIType *_cachedType;
}

- (instancetype)initWithAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    self = [super init];
    if (self)
        _amenity = amenity;
    return self;
}

- (instancetype)initWithPoi:(OAPOI *)poi
{
    self = [super init];
    if (self)
        _fallbackPoi = poi;
    return self;
}

- (BOOL)usesFallbackPoi
{
    return _amenity == nullptr;
}

- (std::shared_ptr<const OsmAnd::Amenity>)amenity
{
    return _amenity;
}

- (OAPOI *)cachedPoi
{
    return _cachedPoi ?: _fallbackPoi;
}

- (OAPOIType *)type
{
    if (_cachedType)
        return _cachedType;
    if (_amenity != nullptr)
        _cachedType = [OAAmenitySearcher parsePOITypeByAmenity:_amenity];
    else
        _cachedType = _fallbackPoi.type;
    return _cachedType;
}

- (OAPOI *)poi
{
    if (_cachedPoi)
        return _cachedPoi;
    if (_fallbackPoi)
    {
        _cachedPoi = _fallbackPoi;
    }
    else if (_amenity != nullptr)
    {
        _cachedPoi = [OAAmenitySearcher parsePOIByAmenity:_amenity type:self.type];
    }
    return _cachedPoi;
}

- (OAPOI *)poiIfLoaded
{
    return _cachedPoi ?: _fallbackPoi;
}

- (int64_t)signedId
{
    return _amenity != nullptr ? static_cast<int64_t>(_amenity->id.id) : _fallbackPoi.getSignedId;
}

- (OsmAnd::PointI)position31
{
    if (_amenity != nullptr)
        return _amenity->position31;

    return OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_fallbackPoi.latitude, _fallbackPoi.longitude));
}

- (CLLocationCoordinate2D)coordinate
{
    if (_amenity != nullptr)
    {
        const auto latLon = OsmAnd::Utilities::convert31ToLatLon(_amenity->position31);
        return CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    }
    return CLLocationCoordinate2DMake(_fallbackPoi.latitude, _fallbackPoi.longitude);
}

- (NSString *)captionWithLanguage:(NSString *)language
                    transliterate:(BOOL)transliterate
{
    if (_amenity != nullptr)
        return _amenity->getName(QString::fromNSString(language ?: @""), transliterate).toNSString();
    return [_fallbackPoi getName:language transliterate:transliterate];
}

- (NSString *)routeId
{
    if (_amenity != nullptr)
    {
        const auto values = _amenity->getDecodedValuesHash();
        const QString routeId = values[QString::fromNSString(ROUTE_ID)];
        return routeId.isNull() ? nil : routeId.toNSString();
    }
    return [_fallbackPoi getRouteId];
}

- (NSString *)wikidata
{
    if (_amenity != nullptr)
    {
        const auto values = _amenity->getDecodedValuesHash();
        const QString wikidata = values[QStringLiteral("wikidata")];
        return wikidata.isNull() ? nil : wikidata.toNSString();
    }
    return [_fallbackPoi getWikidata];
}

- (int)travelEloNumber
{
    if (_amenity != nullptr)
    {
        const auto values = _amenity->getDecodedValuesHash();
        const QString value = values[QString::fromNSString(TRAVEL_EVO_TAG)];
        return value.isNull() ? DEFAULT_ELO : [OASKAlgorithms.shared parseIntSilentlyInput:value.toNSString() def:DEFAULT_ELO];
    }
    return [_fallbackPoi getTravelEloNumber];
}

- (BOOL)isRouteTrack
{
    if (_amenity != nullptr)
    {
        const auto values = _amenity->getDecodedValuesHash();
        NSString *subType = _amenity->subType.toNSString();
        BOOL hasRouteTrackSubtype = [subType hasPrefix:ROUTES_PREFIX] || [subType isEqualToString:ROUTE_TRACK];
        return hasRouteTrackSubtype
            && !values[QString::fromNSString(ROUTE_BBOX_RADIUS)].isNull()
            && self.routeId.length > 0;
    }
    return [_fallbackPoi isRouteTrack];
}

- (BOOL)isRouteArticlePoint
{
    if (_amenity != nullptr)
    {
        NSString *subType = _amenity->subType.toNSString();
        return [subType isEqualToString:ROUTE_TRACK_POINT] || [subType isEqualToString:ROUTE_ARTICLE_POINT];
    }
    return [_fallbackPoi isRoutePoint];
}

- (BOOL)isWiki
{
    OAPOIType *type = self.type;
    return type.category.isWiki;
}

- (BOOL)isClosed
{
    if (_amenity != nullptr)
    {
        const auto values = _amenity->getDecodedValuesHash();
        return values[QString::fromNSString(OSM_DELETE_TAG)] == QString::fromNSString(OSM_DELETE_VALUE);
    }
    return [_fallbackPoi isClosed];
}

- (NSString *)wikiIconUrl
{
    if (_fallbackPoi)
        return _fallbackPoi.wikiIconUrl;
    return self.poiIfLoaded.wikiIconUrl;
}

@end

@implementation OAPOIMapLayerDataReadyCallback
{
    NSCondition *_condition;
    NSArray<OAPOIMapLayerItem *> *_results;
    NSArray<OAPOIMapLayerItem *> *_displayedResults;
    BOOL _ready;
}

- (instancetype)initWithRequest:(OAPOITileBoxRequest *)request
{
    self = [super init];
    if (self)
    {
        _request = request;
        _condition = [[NSCondition alloc] init];
    }
    return self;
}

- (NSArray<OAPOIMapLayerItem *> *)results
{
    return _results;
}

- (NSArray<OAPOIMapLayerItem *> *)displayedResults
{
    return _displayedResults;
}

- (BOOL)ready
{
    return _ready;
}

- (void)onDataReadyWithResults:(NSArray<OAPOIMapLayerItem *> *)results
              displayedResults:(NSArray<OAPOIMapLayerItem *> *)displayedResults
{
    [_condition lock];
    _results = results;
    _displayedResults = displayedResults;
    _ready = YES;
    [_condition signal];
    [_condition unlock];
}

- (BOOL)waitUntilReadyForTimeout:(NSTimeInterval)timeout
{
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [_condition lock];
    while (!_ready)
    {
        if (![_condition waitUntilDate:deadline])
            break;
    }
    BOOL ready = _ready;
    [_condition unlock];
    return ready;
}

@end

@interface OAPOIMapLayerData ()

@property (nonatomic, weak) OAMapRendererView *mapView;
@property (nonatomic, weak) OAMapViewController *mapViewController;
@property (nonatomic, strong, nullable) OAPOITileBoxRequest *queriedRequest;
@property (nonatomic, copy, nullable) NSArray<OAPOIMapLayerItem *> *results;
@property (nonatomic, copy, nullable) NSArray<OAPOIMapLayerItem *> *displayedResults;
@property (nonatomic, strong, nullable) OAPOIUIFilter *topPlacesFilter;
@property (nonatomic, assign) BOOL deferredResults;

@end

@implementation OAPOIMapLayerData
{
    dispatch_queue_t _taskQueue;
    NSMutableArray<OAPOIMapLayerDataReadyCallback *> *_callbacks;
    OAPOIUIFilter *_poiFilter;
    OAPOIUIFilter *_wikiFilter;
    OAPOITileBoxRequest *_runningExtendedRequest;
    OAPOITileBoxRequest *_pendingRequest;
    BOOL _runningTask;
    NSUInteger _generation;
}

- (instancetype)initWithMapView:(OAMapRendererView *)mapView
              mapViewController:(OAMapViewController *)mapViewController
{
    self = [super init];
    if (self)
    {
        _mapView = mapView;
        _mapViewController = mapViewController;
        _taskQueue = dispatch_queue_create("com.osmand.poi.maplayer.data", DISPATCH_QUEUE_SERIAL);
        _callbacks = [NSMutableArray array];
        _dataRequestTimeout = kOAPOIMapLayerDataRequestTimeout;
    }
    return self;
}

- (void)setPoiFilter:(OAPOIUIFilter *)poiFilter
          wikiFilter:(OAPOIUIFilter *)wikiFilter
{
    @synchronized (self)
    {
        _poiFilter = poiFilter;
        _wikiFilter = wikiFilter;
        _generation++;
    }
}

- (OAPOIUIFilter *)poiFilter
{
    @synchronized (self)
    {
        return _poiFilter;
    }
}

- (OAPOIUIFilter *)wikiFilter
{
    @synchronized (self)
    {
        return _wikiFilter;
    }
}

- (OAPOIMapLayerDataReadyCallback *)getDataReadyCallback:(OAPOITileBoxRequest *)request
{
    return [[OAPOIMapLayerDataReadyCallback alloc] initWithRequest:request];
}

- (void)addDataReadyCallback:(OAPOIMapLayerDataReadyCallback *)callback
{
    @synchronized (self)
    {
        [_callbacks addObject:callback];
    }
}

- (void)removeDataReadyCallback:(OAPOIMapLayerDataReadyCallback *)callback
{
    @synchronized (self)
    {
        [_callbacks removeObject:callback];
    }
}

- (void)fireCallbacksWithResults:(NSArray<OAPOIMapLayerItem *> *)results
                displayedResults:(NSArray<OAPOIMapLayerItem *> *)displayedResults
{
    NSArray<OAPOIMapLayerDataReadyCallback *> *callbacks = nil;
    @synchronized (self)
    {
        callbacks = [_callbacks copy];
    }
    for (OAPOIMapLayerDataReadyCallback *callback in callbacks)
        [callback onDataReadyWithResults:results displayedResults:displayedResults];
}

- (BOOL)queriedRequestContains:(OAPOITileBoxRequest *)queriedRequest
                    newRequest:(OAPOITileBoxRequest *)newRequest
{
    return [queriedRequest containsRequest:newRequest]
        && llabs((long long) queriedRequest.zoom - newRequest.zoom) <= 0;
}

- (void)queryNewData:(OAPOITileBoxRequest *)request
{
    if (!request)
        return;

    OAPOITileBoxRequest *extendedRequest = [request extendTileExtentX:request.width / 2 tileExtentY:request.height / 2];
    dispatch_block_t preExecute = nil;
    BOOL startTask = NO;

    @synchronized (self)
    {
        if ([self queriedRequestContains:_queriedRequest newRequest:request])
        {
            [self fireCallbacksWithResults:_results displayedResults:_displayedResults];
            return;
        }

        if (_runningTask && [self queriedRequestContains:_runningExtendedRequest newRequest:request])
            return;

        _pendingRequest = extendedRequest;
        if (!_runningTask)
        {
            _runningTask = YES;
            _runningExtendedRequest = _pendingRequest;
            _pendingRequest = nil;
            preExecute = self.layerOnPreExecute;
            startTask = YES;
        }
    }

    if (preExecute)
        preExecute();

    if (startTask)
        [self startTaskForRequest:_runningExtendedRequest];
}

- (void)startTaskForRequest:(OAPOITileBoxRequest *)request
{
    NSUInteger generation = 0;
    @synchronized (self)
    {
        generation = _generation;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_async(_taskQueue, ^{
        __typeof(self) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        OAPOIMapLayerSearchResult *result = [strongSelf calculateResultForRequest:request];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf finishTaskForRequest:request result:result generation:generation];
        });
    });
}

- (void)finishTaskForRequest:(OAPOITileBoxRequest *)request
                      result:(OAPOIMapLayerSearchResult *)result
                  generation:(NSUInteger)generation
{
    dispatch_block_t callback = nil;
    OAPOITileBoxRequest *nextRequest = nil;
    @synchronized (self)
    {
        if (generation != _generation)
        {
            _runningTask = NO;
            _runningExtendedRequest = nil;
            return;
        }

        if (result)
        {
            _queriedRequest = request;
            _results = result.results;
            _displayedResults = result.displayedResults;
            _topPlacesFilter = result.topPlacesFilter;
            _deferredResults = result.deferredResults;
        }

        _runningTask = NO;
        _runningExtendedRequest = nil;

        if (_pendingRequest)
        {
            _runningTask = YES;
            _runningExtendedRequest = _pendingRequest;
            nextRequest = _pendingRequest;
            _pendingRequest = nil;
            callback = self.layerOnPreExecute;
        }
        else
        {
            [self fireCallbacksWithResults:_results displayedResults:_displayedResults];
            callback = self.layerOnPostExecute;
        }
    }

    if (nextRequest)
    {
        if (callback)
            callback();
        [self startTaskForRequest:nextRequest];
    }
    else if (callback)
    {
        callback();
    }
}

- (BOOL)isInterrupted
{
    @synchronized (self)
    {
        return _pendingRequest != nil;
    }
}

- (NSArray<OAPOIUIFilter *> *)collectFilters
{
    OAPOIUIFilter *poiFilter = nil;
    OAPOIUIFilter *wikiFilter = nil;
    @synchronized (self)
    {
        poiFilter = _poiFilter;
        wikiFilter = _wikiFilter;
    }

    NSMutableArray<OAPOIUIFilter *> *filters = [NSMutableArray array];
    if (poiFilter)
        [filters addObject:poiFilter];
    if (wikiFilter)
        [filters addObject:wikiFilter];
    return filters;
}

- (NSArray<OAPOIMapLayerItem *> *)offlineItemsForFilter:(OAPOIUIFilter *)filter
                                            latLonBounds:(QuadRect *)latLonBounds
                                                  zoom:(NSInteger)zoom
                                       maxAcceptedCount:(NSUInteger)maxAcceptedCount
{
    return [OAAmenitySearcher searchMapLayerOfflineItems:filter
                                             topLatitude:latLonBounds.top
                                          bottomLatitude:latLonBounds.bottom
                                           leftLongitude:latLonBounds.left
                                          rightLongitude:latLonBounds.right
                                                    zoom:zoom
                                        maxAcceptedCount:maxAcceptedCount
                                           includeTravel:YES
                                             interrupted:^BOOL{
        return [self isInterrupted];
    }];
}

- (NSUInteger)offlineItemLimitForRequest:(OAPOITileBoxRequest *)request filter:(OAPOIUIFilter *)filter
{
    if (!request || !filter || filter.isTopWikiFilter)
        return 0;

    const NSInteger tileCount = MAX(request.width, 1) * MAX(request.height, 1);
    const NSInteger displayLimit = kOAPOIMapLayerTopPlacesLimit + tileCount * kOAPOIMapLayerTilePointsLimit;
    const NSInteger paddedLimit = MAX(displayLimit + kOAPOIMapLayerOfflineSearchExtraItems,
                                      (displayLimit * 5) / 4);
    return (NSUInteger) MAX(paddedLimit, kOAPOIMapLayerTilePointsLimit);
}

- (NSArray<OAPOIMapLayerItem *> *)normalizeOfflineItems:(NSArray<OAPOIMapLayerItem *> *)items
{
    NSArray<OAPOIMapLayerItem *> *normalizedOrder = OAPOINormalizeDisplayOrder(items);
    return OAPOIFilterUniqueDisplayItems(normalizedOrder);
}

- (NSArray<OAPOIMapLayerItem *> *)onlineItemsForWikiFilter:(OAPOIUIFilter *)filter
                                              latLonBounds:(QuadRect *)latLonBounds
                                                  deferred:(BOOL *)deferred
{
    PoiUIFilterDataProvider *provider = [[PoiUIFilterDataProvider alloc] initWithFilter:filter];
    NSArray<OAPOI *> *pois = [provider searchAmenitiesWithLat:(latLonBounds.top + latLonBounds.bottom) / 2.0
                                                          lon:(latLonBounds.left + latLonBounds.right) / 2.0
                                                  topLatitude:latLonBounds.top
                                               bottomLatitude:latLonBounds.bottom
                                                leftLongitude:latLonBounds.left
                                               rightLongitude:latLonBounds.right
                                                         zoom:-1
                                                      matcher:nil];
    if (deferred)
        *deferred = NO;

    NSMutableArray<OAPOIMapLayerItem *> *items = [NSMutableArray arrayWithCapacity:pois.count];
    OAAmenityNameFilter *nameFilter = [filter getNameFilter:filter.filterByName];
    for (OAPOI *poi in pois)
    {
        if ([self isInterrupted])
            break;
        if (!poi.type || ![filter accept:poi.type.category subcategory:poi.type.name])
            continue;
        if (nameFilter && ![nameFilter accept:poi])
            continue;
        [items addObject:[[OAPOIMapLayerItem alloc] initWithPoi:poi]];
    }
    return [items copy];
}

- (BOOL)shouldDrawItem:(OAPOIMapLayerItem *)item zoom:(NSInteger)zoom
{
    if (item.isRouteTrack)
        return zoom >= kOAPOIMapLayerStartZoomRouteTrack;
    return zoom >= kOAPOIMapLayerStartZoom;
}

- (NSArray<OAPOIMapLayerItem *> *)collectDisplayedPointsForBounds:(QuadRect *)latLonBounds
                                                             zoom:(NSInteger)zoom
                                                           items:(NSArray<OAPOIMapLayerItem *> *)items
{
    // Android uses HashSet here, so preserving insertion order biases the first accepted
    // POIs in each dense tile. Keep the set unordered to stay closer to Java behavior.
    NSMutableSet<OAPOIMapLayerItem *> *displayedPoints = [NSMutableSet set];

    NSInteger minTileX = (NSInteger)[OASKMapUtils.shared getTileNumberXZoom:zoom longitude:latLonBounds.left];
    NSInteger maxTileX = (NSInteger)[OASKMapUtils.shared getTileNumberXZoom:zoom longitude:latLonBounds.right];
    NSInteger minTileY = (NSInteger)[OASKMapUtils.shared getTileNumberYZoom:zoom latitude:latLonBounds.top];
    NSInteger maxTileY = (NSInteger)[OASKMapUtils.shared getTileNumberYZoom:zoom latitude:latLonBounds.bottom];

    NSInteger width = maxTileX - minTileX + 1;
    NSInteger height = maxTileY - minTileY + 1;
    NSMutableArray<NSNumber *> *tileCounts = nil;
    if (width > 0 && height > 0)
    {
        tileCounts = [NSMutableArray arrayWithCapacity:(NSUInteger)(width * height)];
        for (NSInteger i = 0; i < width * height; i++)
            [tileCounts addObject:@(0)];
    }

    NSInteger topPlacesCounter = 0;
    for (OAPOIMapLayerItem *item in items)
    {
        if (![self shouldDrawItem:item zoom:zoom])
            continue;

        if (topPlacesCounter < kOAPOIMapLayerTopPlacesLimit)
        {
            [displayedPoints addObject:item];
            topPlacesCounter++;
        }

        if (!tileCounts)
            continue;

        CLLocationCoordinate2D coord = item.coordinate;
        NSInteger tileX = (NSInteger)[OASKMapUtils.shared getTileNumberXZoom:zoom longitude:coord.longitude];
        NSInteger tileY = (NSInteger)[OASKMapUtils.shared getTileNumberYZoom:zoom latitude:coord.latitude];
        if (tileX < minTileX || tileX > maxTileX || tileY < minTileY || tileY > maxTileY)
            continue;

        NSInteger index = (tileX - minTileX) + (tileY - minTileY) * width;
        NSInteger count = tileCounts[index].integerValue;
        if (count < kOAPOIMapLayerTilePointsLimit)
        {
            [displayedPoints addObject:item];
            tileCounts[index] = @(count + 1);
        }
    }

    return displayedPoints.allObjects;
}

- (NSComparisonResult)compareItemByElo:(OAPOIMapLayerItem *)left right:(OAPOIMapLayerItem *)right
{
    int elo1 = left.travelEloNumber;
    int elo2 = right.travelEloNumber;
    if (elo1 < elo2)
        return NSOrderedDescending;
    if (elo1 > elo2)
        return NSOrderedAscending;
    if (left.signedId < right.signedId)
        return NSOrderedAscending;
    if (left.signedId > right.signedId)
        return NSOrderedDescending;
    return NSOrderedSame;
}

- (OAPOIMapLayerSearchResult *)calculateResultForRequest:(OAPOITileBoxRequest *)request
{
    NSArray<OAPOIUIFilter *> *filters = [self collectFilters];
    OAPOIMapLayerSearchResult *result = [[OAPOIMapLayerSearchResult alloc] init];
    result.results = @[];
    result.displayedResults = @[];

    if (filters.count == 0)
        return result;

    NSInteger effectiveZoom = (NSInteger) floor(request.zoom + log([OAAppSettings sharedManager].mapDensity.get) / log(2.0));
    NSMutableArray<OAPOIMapLayerItem *> *allItems = [NSMutableArray array];
    NSMutableSet<NSString *> *uniqueRouteIds = [NSMutableSet set];
    BOOL deferred = NO;

    for (OAPOIUIFilter *filter in filters)
    {
        if (filter.isTopImagesFilter)
            result.topPlacesFilter = filter;

        NSArray<OAPOIMapLayerItem *> *filterItems = nil;
        BOOL useOnlineWiki = filter.isTopWikiFilter && [OAAppSettings sharedManager].wikiDataSourceType.get == EOAWikiDataSourceTypeOnline;
        if (useOnlineWiki)
            filterItems = [self onlineItemsForWikiFilter:filter latLonBounds:request.latLonBounds deferred:&deferred];
        else
            filterItems = [self normalizeOfflineItems:[self offlineItemsForFilter:filter
                                                                     latLonBounds:request.latLonBounds
                                                                           zoom:effectiveZoom
                                                               maxAcceptedCount:[self offlineItemLimitForRequest:request filter:filter]]];

        if (filter.isTopWikiFilter)
        {
            NSArray<OAPOIMapLayerItem *> *sorted = [filterItems sortedArrayUsingComparator:^NSComparisonResult(OAPOIMapLayerItem *left, OAPOIMapLayerItem *right) {
                return [self compareItemByElo:left right:right];
            }];
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sorted.count)];
            [allItems insertObjects:sorted atIndexes:indexes];
        }
        else
        {
            for (OAPOIMapLayerItem *item in filterItems)
            {
                if (item.isRouteTrack)
                {
                    NSString *routeId = item.routeId;
                    if (routeId.length > 0 && [uniqueRouteIds containsObject:routeId])
                        continue;
                    if (routeId.length > 0)
                        [uniqueRouteIds addObject:routeId];
                }
                [allItems addObject:item];
            }
        }
    }

    result.results = [allItems copy];
    result.displayedResults = [self collectDisplayedPointsForBounds:request.latLonBounds zoom:request.zoom items:allItems];
    result.deferredResults = deferred;
    return result;
}

- (void)clearCache
{
    @synchronized (self)
    {
        _queriedRequest = nil;
        _results = nil;
        _displayedResults = nil;
        _topPlacesFilter = nil;
        _deferredResults = NO;
        _pendingRequest = nil;
        _runningExtendedRequest = nil;
        _runningTask = NO;
        _generation++;
    }
}

- (OAPOITileBoxRequest *)queriedRequest
{
    @synchronized (self)
    {
        return _queriedRequest;
    }
}

- (NSArray<OAPOIMapLayerItem *> *)results
{
    @synchronized (self)
    {
        return _results;
    }
}

- (NSArray<OAPOIMapLayerItem *> *)displayedResults
{
    @synchronized (self)
    {
        return _displayedResults;
    }
}

- (OAPOIUIFilter *)topPlacesFilter
{
    @synchronized (self)
    {
        return _topPlacesFilter;
    }
}

- (BOOL)deferredResults
{
    @synchronized (self)
    {
        return _deferredResults;
    }
}

- (OAPOI *)poiForItem:(OAPOIMapLayerItem *)item
{
    return [item poi];
}

- (NSArray<OAPOI *> *)displayedResultsAsPoi
{
    NSMutableArray<OAPOI *> *pois = [NSMutableArray array];
    for (OAPOIMapLayerItem *item in self.displayedResults ?: @[])
    {
        OAPOI *poi = [item poi];
        if (poi)
            [pois addObject:poi];
    }
    return [pois copy];
}

- (NSArray<OAPOI *> *)resultsAsPoi
{
    NSMutableArray<OAPOI *> *pois = [NSMutableArray array];
    for (OAPOIMapLayerItem *item in self.results ?: @[])
    {
        OAPOI *poi = [item poi];
        if (poi)
            [pois addObject:poi];
    }
    return [pois copy];
}

@end
