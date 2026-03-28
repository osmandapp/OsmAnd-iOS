//
//  OAPOILayerTopPlacesProvider.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPOILayerTopPlacesProvider.h"
#import "QuadRect.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "QuadTree.h"
#import "OANativeUtilities.h"
#import "OATargetPointView.h"
#import "OAAmenitySearcher+cpp.h"
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <algorithm>

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kStartZoom = 5;
static const NSInteger kStartZoomRouteTrack = 11;
static const NSInteger kImageIconSizeDP = 45;
static void *kTopPlacesStateQueueKey = &kTopPlacesStateQueueKey;
static NSString * const kWikiPhotoTag = @"wiki_photo";

@implementation OAPOILayerTopPlacesProvider
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> _topPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    QList<std::shared_ptr<const OsmAnd::Amenity>> _allPlaces;
    QList<std::shared_ptr<const OsmAnd::Amenity>> _displayedPlaces;
    NSSet<NSNumber *> *_topPlaceIds;
    NSSet<NSNumber *> *_loadingImagePlaceIds;
    QuadRect *_topPlacesBox;
    QuadRect *_lastCalcBounds;
    float _lastCalcZoom;
    NSOperationQueue *_popularPlacesQueue;
    
    POIImageLoader *_imageLoader;
    dispatch_queue_t _backgroundQueue;
    OAMapRendererView *_mapView;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _mapMarkersCollection;
    
    int _topPlaceBaseOrder;
    OAMapViewController *_mapViewController;
    CGFloat _textScale;
    NSNumber *_selectedTopPlaceId;
    BOOL _enabled;
    NSMutableDictionary<NSNumber *, NSString *> *_renderedMarkerStates;
    NSUInteger _amenitiesGeneration;
    NSUInteger _imagesGeneration;
}

- (instancetype)initWithTopPlaceBaseOrder:(int)baseOrder
{
    self = [super init];
    if (self) {
        [self configure];
        _topPlaceBaseOrder = baseOrder;
    }
    return self;
}

- (void)configure
{
    _mapView = (OAMapRendererView *)[OARootViewController instance].mapPanel.mapViewController.view;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _enabled = NO;
    _textScale = 1.f;
    _backgroundQueue = dispatch_queue_create("com.osmand.topplaces.background", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_backgroundQueue, kTopPlacesStateQueueKey, kTopPlacesStateQueueKey, NULL);
    _popularPlacesQueue = [NSOperationQueue new];
    _popularPlacesQueue.maxConcurrentOperationCount = 1;
    _popularPlacesQueue.qualityOfService = NSQualityOfServiceUserInitiated;
}

// MARK: - Public

- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc
{
    if (!_enabled)
        return;

    dispatch_async(_backgroundQueue, ^{
        if (!_enabled)
            return;

        QuadRect *visibleBounds = nil;
        float zoom = 0.f;
        if (![self captureVisibleBounds:&visibleBounds zoom:&zoom])
            return;

        if (!forceRecalc && ![self shouldRecalculateForBounds:visibleBounds zoom:zoom])
        {
            [self refreshVisiblePlacesOnStateQueue];
            return;
        }

        if (_lastCalcBounds && fabs(zoom - _lastCalcZoom) > 0.5f)
            _topPlacesBox = nil;

        _lastCalcBounds = [[QuadRect alloc] initWithRect:visibleBounds];
        _lastCalcZoom = zoom;

        [_popularPlacesQueue cancelAllOperations];
        NSUInteger generation = ++_amenitiesGeneration;
        __weak __typeof(self) weakSelf = self;
        NSBlockOperation *op = [NSBlockOperation new];
        __weak NSBlockOperation *weakOp = op;
        QuadRect *searchBounds = [self expandedBoundsForVisibleBounds:visibleBounds];

        [op addExecutionBlock:^{
            if (weakOp.isCancelled)
                return;

            OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(id __autoreleasing *object) {
                return YES;
            } cancelledFunc:^BOOL{
                return weakOp.isCancelled;
            }];

            QList<std::shared_ptr<const OsmAnd::Amenity>> amenities = [weakSelf calculateAmenities:searchBounds matcher:matcher];

            if (weakOp.isCancelled)
                return;

            [weakSelf applyAmenities:amenities generation:generation];
        }];

        [_popularPlacesQueue addOperation:op];
    });
}

- (void)resetLayer
{
    dispatch_async(_backgroundQueue, ^{
        [self resetTopPlacesState];
    });
}

- (void)setEnabled:(BOOL)enabled
{
    dispatch_async(_backgroundQueue, ^{
        if (_enabled == enabled)
            return;

        _enabled = enabled;
        if (!_enabled)
            [self resetTopPlacesState];
    });
}

- (void)setTextScale:(CGFloat)textScale
{
    dispatch_async(_backgroundQueue, ^{
        if (fabs(_textScale - textScale) < 0.0001f)
            return;

        _textScale = textScale;
        if (_enabled)
        {
            _topPlacesBox = nil;
            [self refreshVisiblePlacesOnStateQueue];
        }
    });
}

- (void)refreshVisiblePlaces
{
    dispatch_async(_backgroundQueue, ^{
        if (_enabled)
            [self refreshVisiblePlacesOnStateQueue];
    });
}

- (void)updateSelectedTopPlaceId:(NSNumber *)placeId
{
    dispatch_async(_backgroundQueue, ^{
        if ((!_selectedTopPlaceId && !placeId)
            || (_selectedTopPlaceId && placeId && [_selectedTopPlaceId isEqualToNumber:placeId]))
        {
            return;
        }

        if (placeId && [_topPlaceIds containsObject:placeId])
            _selectedTopPlaceId = placeId;
        else
            _selectedTopPlaceId = nil;

        [self updateTopPlacesCollection];
    });
}

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)topPlaces
{
    __block QList<std::shared_ptr<const OsmAnd::Amenity>> topPlaces;
    [self performStateSync:^{
        topPlaces = _topPlaces;
    }];
    return topPlaces;
}

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)displayedAmenities
{
    __block QList<std::shared_ptr<const OsmAnd::Amenity>> displayedPlaces;
    [self performStateSync:^{
        displayedPlaces = _displayedPlaces;
    }];
    return displayedPlaces;
}

// MARK: - Private

- (BOOL)isOnStateQueue
{
    return dispatch_get_specific(kTopPlacesStateQueueKey) == kTopPlacesStateQueueKey;
}

- (void)performStateSync:(dispatch_block_t)block
{
    if ([self isOnStateQueue])
        block();
    else
        dispatch_sync(_backgroundQueue, block);
}

- (BOOL)captureVisibleBounds:(QuadRect * __autoreleasing *)visibleBounds
                        zoom:(float *)zoom
{
    __block QuadRect *bounds = nil;
    __block float currentZoom = 0.f;

    [_mapViewController runWithRenderSync:^{
        const auto screenBbox = _mapView.getVisibleBBox31;
        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);

        CLLocationCoordinate2D topLeftCoord = CLLocationCoordinate2DMake(topLeft.latitude, topLeft.longitude);
        CLLocationCoordinate2D bottomRightCoord = CLLocationCoordinate2DMake(bottomRight.latitude, bottomRight.longitude);
        if (!CLLocationCoordinate2DIsValid(topLeftCoord) || !CLLocationCoordinate2DIsValid(bottomRightCoord))
            return;

        bounds = [[QuadRect alloc] initWithLeft:topLeft.longitude
                                            top:topLeft.latitude
                                          right:bottomRight.longitude
                                         bottom:bottomRight.latitude];
        currentZoom = [_mapView zoom];
    }];

    if (!bounds)
        return NO;

    if (visibleBounds)
        *visibleBounds = bounds;
    if (zoom)
        *zoom = currentZoom;
    return YES;
}

- (BOOL)shouldRecalculateForBounds:(QuadRect *)visibleBounds
                              zoom:(float)zoom
{
    if (_lastCalcBounds == nil)
        return YES;

    BOOL zoomChanged = fabs(zoom - _lastCalcZoom) > 0.5f;
    if (zoomChanged)
        return YES;

    double halfWidth = fabs(_lastCalcBounds.width) / 2.0;
    double halfHeight = fabs(_lastCalcBounds.height) / 2.0;

    double lastCenterX = (_lastCalcBounds.left + _lastCalcBounds.right) / 2.0;
    double lastCenterY = (_lastCalcBounds.top + _lastCalcBounds.bottom) / 2.0;
    double currentCenterX = (visibleBounds.left + visibleBounds.right) / 2.0;
    double currentCenterY = (visibleBounds.top + visibleBounds.bottom) / 2.0;

    return fabs(currentCenterX - lastCenterX) > halfWidth
        || fabs(currentCenterY - lastCenterY) > halfHeight;
}

- (QuadRect *)expandedBoundsForVisibleBounds:(QuadRect *)visibleBounds
{
    QuadRect *expandedBounds = [[QuadRect alloc] initWithRect:visibleBounds];
    [expandedBounds inset:-(expandedBounds.width / 2.0) dy:-(expandedBounds.height / 2.0)];
    return expandedBounds;
}

- (QuadRect *)topPlacesBoxForVisibleBounds:(QuadRect *)visibleBounds
{
    QuadRect *topPlacesBox = [[QuadRect alloc] initWithRect:visibleBounds];
    double lonDelta = visibleBounds.width * 0.1;
    double latDelta = visibleBounds.height * 0.1;
    [topPlacesBox inset:-lonDelta dy:-latDelta];
    return topPlacesBox;
}

- (NSNumber *)placeIdForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    return @((uint64_t)amenity->id);
}

- (BOOL)isSelectedAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    return _selectedTopPlaceId && [[self placeIdForAmenity:amenity] isEqualToNumber:_selectedTopPlaceId];
}

- (NSString *)wikiPhotoForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    const auto wikiPhoto = amenity->getDecodedValue(QString::fromNSString(kWikiPhotoTag));
    return wikiPhoto.isEmpty() ? nil : wikiPhoto.toNSString();
}

- (NSString *)wikiIconUrlForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    NSString *wikiPhoto = [self wikiPhotoForAmenity:amenity];
    if (wikiPhoto.length == 0)
        return nil;

    OASWikiImage *wikiImage = [[OASWikiHelper shared] getImageDataImageFileName:wikiPhoto];
    if (wikiImage.imageIconUrl.length > 0)
        return wikiImage.imageIconUrl;

    return [wikiPhoto hasPrefix:@"http"] ? wikiPhoto : nil;
}

- (NSInteger)travelEloForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    return amenity->travelElo >= 0 ? amenity->travelElo : 0;
}

- (NSString *)placeholderIconNameForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
    return [type iconName];
}

- (POIImageLoadRequest *)imageLoadRequestForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    NSString *wikiIconUrl = [self wikiIconUrlForAmenity:amenity];
    if (wikiIconUrl.length == 0)
        return nil;

    return [[POIImageLoadRequest alloc] initWithPlaceId:[self placeIdForAmenity:amenity]
                                                    url:wikiIconUrl
                                   placeholderImageName:[self placeholderIconNameForAmenity:amenity]];
}

- (nullable UIImage *)markerImageForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    UIImage *baseImage = _topPlacesImages[[self placeIdForAmenity:amenity]];
    if (!baseImage)
        return nil;

    if ([self isSelectedAmenity:amenity])
        return [POITopPlaceImageDecorator selectedImageFor:baseImage];

    return baseImage;
}

- (nullable NSString *)markerStateForAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity image:(UIImage *)image
{
    if (!image)
        return nil;

    NSNumber *placeId = [self placeIdForAmenity:amenity];
    return [NSString stringWithFormat:@"%@:%d:%p", placeId, [self isSelectedAmenity:amenity], image];
}

- (BOOL)removeMarkerWithId:(int32_t)markerId
       fromCollectionLocked:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
{
    if (!markersCollection)
        return NO;

    const auto markers = markersCollection->getMarkers();
    for (const auto &marker : markers)
    {
        if (marker->markerId != markerId)
            continue;

        BOOL removed = markersCollection->removeMarker(marker);
        if (removed)
            marker->setUpdateAfterCreated(true);
        return removed;
    }

    return NO;
}

- (BOOL)addTopPlaceMarker:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
                 markerId:(int32_t)markerId
                    image:(UIImage *)image
       toCollectionLocked:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
{
    if (!image)
        return NO;

    NSData *data = UIImagePNGRepresentation(image);
    if (!data)
        return NO;

    OsmAnd::MapMarkerBuilder builder;
    builder.setIsAccuracyCircleSupported(false)
        .setMarkerId(markerId)
        .setBaseOrder(_topPlaceBaseOrder)
        .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
        .setPosition(amenity->position31)
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);

    std::shared_ptr<OsmAnd::MapMarker> marker =
        builder.buildAndAddToCollection(markersCollection);
    marker->setUpdateAfterCreated(true);
    return YES;
}

- (void)resetTopPlacesState
{
    [self clearMapMarkersCollections];
    [self cancelLoadingImages];
    [_popularPlacesQueue cancelAllOperations];

    _amenitiesGeneration++;
    _imagesGeneration++;
    _allPlaces.clear();
    _displayedPlaces.clear();
    _topPlaces.clear();
    _topPlaceIds = nil;
    _loadingImagePlaceIds = nil;
    _topPlacesBox = nil;
    _lastCalcBounds = nil;
    _lastCalcZoom = 0.f;
    _selectedTopPlaceId = nil;
    _renderedMarkerStates = nil;
}

- (void)applyAmenities:(const QList<std::shared_ptr<const OsmAnd::Amenity>> &)amenities
            generation:(NSUInteger)generation
{
    const QList<std::shared_ptr<const OsmAnd::Amenity>> amenitiesCopy = amenities;
    dispatch_async(_backgroundQueue, ^{
        if (_amenitiesGeneration != generation)
            return;

        _allPlaces = amenitiesCopy;
        _topPlacesBox = nil;
        [self refreshVisiblePlacesOnStateQueue];
    });
}

- (void)refreshVisiblePlacesOnStateQueue
{
    if (!_enabled)
        return;

    QuadRect *visibleBounds = nil;
    float zoom = 0.f;
    if (![self captureVisibleBounds:&visibleBounds zoom:&zoom])
        return;

    if (_allPlaces.isEmpty())
    {
        _displayedPlaces.clear();
        _topPlacesBox = nil;
        [self clearMapMarkersCollections];
        [self cancelLoadingImages];
        return;
    }

    _displayedPlaces = [self collectDisplayedPoints:visibleBounds zoom:zoom amenities:_allPlaces];
    if (_topPlacesBox && [_topPlacesBox contains:visibleBounds])
        return;

    _topPlacesBox = [self topPlacesBoxForVisibleBounds:visibleBounds];
    [self updateTopPlaces:_allPlaces latLonBounds:visibleBounds zoom:(int)zoom];
}

- (void)updateTopPlaceImageForId:(NSNumber *)placeId
                           image:(UIImage *)image
                      generation:(NSUInteger)generation
{
    dispatch_async(_backgroundQueue, ^{
        if (_imagesGeneration != generation)
            return;

        if (_topPlaceIds && _topPlacesImages)
        {
            if ([_topPlaceIds containsObject:placeId])
            {
                _topPlacesImages[placeId] = image;
                [self updateTopPlacesCollection];
            }
        }
    });
}

- (void)updateTopPlacesCollection
{
    [_mapViewController runWithRenderSync:^{
        QList<std::shared_ptr<const OsmAnd::Amenity>> places = _topPlaces;
        [self sortByElo:&places];
        if (places.isEmpty())
        {
            [self clearMapMarkersCollectionLocked];
            return;
        }

        if (!_mapMarkersCollection)
        {
            _mapMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
            _renderedMarkerStates = [NSMutableDictionary dictionary];
            _mapView.renderer->addSymbolsProvider(kFavoritesSymbolSection, _mapMarkersCollection);
        }
        else if (!_renderedMarkerStates)
        {
            _renderedMarkerStates = [NSMutableDictionary dictionary];
        }

        NSMutableDictionary<NSNumber *, NSString *> *desiredMarkerStates = [NSMutableDictionary dictionary];
        NSInteger markerCount = 0;
        for (const auto& place : places)
        {
            UIImage *topPlaceImage = [self markerImageForAmenity:place];
            if (!topPlaceImage)
                continue;

            int32_t markerId = [self truncatedTopPlaceId:place];
            NSNumber *markerKey = @(markerId);
            NSString *markerState = [self markerStateForAmenity:place image:topPlaceImage];
            if (!markerState)
                continue;

            desiredMarkerStates[markerKey] = markerState;
            NSString *currentMarkerState = _renderedMarkerStates[markerKey];
            if (![currentMarkerState isEqualToString:markerState])
            {
                [self removeMarkerWithId:markerId fromCollectionLocked:_mapMarkersCollection];
                if ([self addTopPlaceMarker:place
                                   markerId:markerId
                                      image:topPlaceImage
                         toCollectionLocked:_mapMarkersCollection])
                {
                    _renderedMarkerStates[markerKey] = markerState;
                }
                else
                {
                    [_renderedMarkerStates removeObjectForKey:markerKey];
                    [desiredMarkerStates removeObjectForKey:markerKey];
                }
            }

            markerCount++;
            if (markerCount >= kTopPlacesLimit)
                break;
        }

        for (NSNumber *markerKey in [_renderedMarkerStates allKeys])
        {
            if (desiredMarkerStates[markerKey])
                continue;

            [self removeMarkerWithId:markerKey.intValue fromCollectionLocked:_mapMarkersCollection];
            [_renderedMarkerStates removeObjectForKey:markerKey];
        }

        if (_renderedMarkerStates.count == 0)
            [self clearMapMarkersCollectionLocked];
    }];
}

- (int32_t)truncatedTopPlaceId:(const std::shared_ptr<const OsmAnd::Amenity> &)topPlace
{
    long long fullId = (uint64_t)topPlace->id;
    if (fullId == 0)
        fullId = [self travelEloForAmenity:topPlace];
    return (int32_t)(fullId ^ (fullId >> 32));
}

- (void)clearMapMarkersCollections
{
    [_mapViewController runWithRenderSync:^{
        [self clearMapMarkersCollectionLocked];
    }];
}

- (void)clearMapMarkersCollectionLocked
{
    if (_mapMarkersCollection != nil)
    {
        [_mapView removeKeyedSymbolsProvider:_mapMarkersCollection];
        _mapMarkersCollection.reset();
    }
    _renderedMarkerStates = nil;
}

- (void)updateTopPlaces:(const QList<std::shared_ptr<const OsmAnd::Amenity>> &)places
           latLonBounds:(QuadRect *)latLonBounds
                   zoom:(int)zoom
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> newTopPlaces = [self obtainTopPlacesToDisplay:places
                                                                                   latLonBounds:latLonBounds
                                                                                           zoom:zoom];
    NSSet<NSNumber *> *previousTopPlaceIds = _topPlaceIds ?: [NSSet set];
    NSMutableSet<NSNumber *> *newTopPlaceIds = [NSMutableSet setWithCapacity:newTopPlaces.size()];
    for (const auto& place : newTopPlaces)
        [newTopPlaceIds addObject:[self placeIdForAmenity:place]];
    BOOL topPlacesChanged = ![previousTopPlaceIds isEqualToSet:newTopPlaceIds];
    NSUInteger generation = topPlacesChanged ? ++_imagesGeneration : _imagesGeneration;
    NSDictionary<NSNumber *, UIImage *> *cachedImages = [_topPlacesImages copy] ?: @{};
    _topPlaces = newTopPlaces;
    _topPlaceIds = [newTopPlaceIds copy];

    NSMutableDictionary<NSNumber *, UIImage *> *preservedImages = [NSMutableDictionary dictionary];
    NSMutableArray<POIImageLoadRequest *> *missingImagePlaces = [NSMutableArray array];
    NSMutableSet<NSNumber *> *missingImagePlaceIds = [NSMutableSet set];
    for (const auto& place : _topPlaces)
    {
        NSNumber *placeId = [self placeIdForAmenity:place];
        UIImage *cachedImage = cachedImages[placeId];
        if (cachedImage)
            preservedImages[placeId] = cachedImage;
        else
        {
            POIImageLoadRequest *request = [self imageLoadRequestForAmenity:place];
            if (request)
                [missingImagePlaces addObject:request];
            [missingImagePlaceIds addObject:placeId];
        }
    }

    _topPlacesImages = preservedImages;
    [self updateTopPlacesCollection];

    if (missingImagePlaces.count > 0)
    {
        if (topPlacesChanged || ![_loadingImagePlaceIds isEqualToSet:missingImagePlaceIds])
        {
            _loadingImagePlaceIds = [missingImagePlaceIds copy];

            if (!_imageLoader)
                _imageLoader = [POIImageLoader new];
            else
                [_imageLoader cancelAll];

            __weak __typeof(self) weakSelf = self;
            [_imageLoader fetchImages:[missingImagePlaces copy] completion:^(NSNumber *placeId, UIImage *image) {
                [weakSelf updateTopPlaceImageForId:placeId image:image generation:generation];
            }];
        }
    }
    else if (_imageLoader)
    {
        _loadingImagePlaceIds = nil;
        [_imageLoader cancelAll];
    }
}

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)obtainTopPlacesToDisplay:(const QList<std::shared_ptr<const OsmAnd::Amenity>> &)places
                                                             latLonBounds:(nonnull QuadRect *)latLonBounds
                                                                     zoom:(int)zoom
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> res;
    
    long long tileSize31 = (1LL << (31 - zoom));
    double from31toPixelsScale = 256.0 / (double)tileSize31;
    double estimatedIconSize = kImageIconSizeDP * _textScale;
    float iconSize31 = (float)(estimatedIconSize / from31toPixelsScale);
    
    int left   = OsmAnd::Utilities::get31TileNumberX(latLonBounds.left);
    int top    = OsmAnd::Utilities::get31TileNumberY(latLonBounds.top);
    int right  = OsmAnd::Utilities::get31TileNumberX(latLonBounds.right);
    int bottom = OsmAnd::Utilities::get31TileNumberY(latLonBounds.bottom);
    
    QuadTree *boundIntersections = [[self class] initBoundIntersections:left
                                                                    top:top
                                                                  right:right
                                                                 bottom:bottom];
    
    int counter = 0;
    for (const auto& place : places)
    {
        const auto latLon = OsmAnd::Utilities::convert31ToLatLon(place->position31);
        double lat = latLon.latitude;
        double lon = latLon.longitude;
        
        if (![latLonBounds contains:lon top:lat right:lon bottom:lat]
            || [self wikiPhotoForAmenity:place].length == 0)
            continue;
        
        int x31 = place->position31.x;
        int y31 = place->position31.y;
        
        if (![[self class] intersectsD:boundIntersections
                                     x:x31
                                     y:y31
                                 width:iconSize31
                                height:iconSize31])
        {
            res.push_back(place);
            counter++;
        }
        
        if (counter >= kTopPlacesLimit)
            break;
    }
    
    return res;
}

+ (nonnull QuadTree *)initBoundIntersections:(double)left
                                         top:(double)top
                                       right:(double)right
                                      bottom:(double)bottom
{
    QuadRect *bounds = [[QuadRect alloc] initWithLeft:left
                                                  top:top
                                                right:right
                                               bottom:bottom];
    
    [bounds inset:-bounds.width / 4.0 dy:-bounds.height / 4.0];
    
    return [[QuadTree alloc] initWithQuadRect:bounds
                                        depth:4
                                        ratio:0.6f];
}

+ (BOOL)intersectsD:(QuadTree *)boundIntersections
                  x:(double)x
                  y:(double)y
              width:(double)width
             height:(double)height
{
    QuadRect *visibleRect = [self calculateRectDWithX:x y:y width:width height:height];
    return [self intersects:boundIntersections visibleRect:visibleRect insert:YES];
}

+ (BOOL)intersects:(QuadTree *)boundIntersections
       visibleRect:(QuadRect *)visibleRect
            insert:(BOOL)insert
{
    NSMutableArray<QuadRect *> *result = [NSMutableArray array];

    QuadRect *rectCopy = [[QuadRect alloc] initWithRect:visibleRect];
    [boundIntersections queryInBox:rectCopy result:result];
    
    for (QuadRect *rect in result)
        if ([QuadRect intersects:rect b:visibleRect])
            return YES;
    
    if (insert)
        [boundIntersections insert:rectCopy box:[[QuadRect alloc] initWithRect:visibleRect]];
    
    return NO;
}

+ (QuadRect *)calculateRectDWithX:(double)x
                                y:(double)y
                            width:(double)width
                           height:(double)height
{
    double left   = x - width / 2.0;
    double top    = y - height / 2.0;
    double right  = left + width;
    double bottom = top + height;
    
    QuadRect *rect = [[QuadRect alloc] initWithLeft:left
                                                top:top
                                              right:right
                                             bottom:bottom];
    return rect;
}

- (void)cancelLoadingImages
{
    if (_imageLoader)
    {
        [_imageLoader cancelAll];
        _imageLoader = nil;
    }

    _topPlacesImages = nil;
    _loadingImagePlaceIds = nil;
}

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)collectDisplayedPoints:(QuadRect *)latLonBounds
                                                                   zoom:(NSInteger)zoom
                                                              amenities:(const QList<std::shared_ptr<const OsmAnd::Amenity>> &)amenities
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> displayedPoints;
    NSInteger topPlacesCounter = 0;
    for (const auto& amenity : amenities)
        if (topPlacesCounter < kTopPlacesLimit)
        {
            displayedPoints.push_back(amenity);
            topPlacesCounter++;
        }

    return displayedPoints;
}

- (QList<std::shared_ptr<const OsmAnd::Amenity>>)calculateAmenities:(QuadRect *)latLonBounds
                                                            matcher:(OAResultMatcher *)matcher
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> cachedAmenities;
    if (![self cachedAmenitiesForBounds:latLonBounds matcher:matcher amenities:&cachedAmenities])
        return QList<std::shared_ptr<const OsmAnd::Amenity>>();

    if ([self isMatcherCancelled:matcher])
        return QList<std::shared_ptr<const OsmAnd::Amenity>>();

    [self sortByElo:&cachedAmenities];
    if ([self isMatcherCancelled:matcher])
        return QList<std::shared_ptr<const OsmAnd::Amenity>>();

    return cachedAmenities;
}

- (BOOL)cachedAmenitiesForBounds:(QuadRect *)latLonBounds
                         matcher:(OAResultMatcher *)matcher
                       amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
{
    if (!self.cachedAmenitiesProvider)
    {
        if (amenities)
            amenities->clear();
        return YES;
    }

    return self.cachedAmenitiesProvider(latLonBounds, matcher, amenities);
}

- (BOOL)isMatcherCancelled:(OAResultMatcher *)matcher
{
    return [matcher isCancelled];
}

- (void)sortByElo:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
{
    if (!amenities)
        return;

    std::sort(amenities->begin(), amenities->end(), [self](const auto& a1, const auto& a2) {
        NSInteger elo1 = [self travelEloForAmenity:a1];
        NSInteger elo2 = [self travelEloForAmenity:a2];
        if (elo1 != elo2)
            return elo1 > elo2;
        return (uint64_t)a1->id < (uint64_t)a2->id;
    });
}

@end
