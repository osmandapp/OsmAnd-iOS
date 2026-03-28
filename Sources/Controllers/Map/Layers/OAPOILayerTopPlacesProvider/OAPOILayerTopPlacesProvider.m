//
//  OAPOILayerTopPlacesProvider.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPOILayerTopPlacesProvider.h"
#import "OAPOI.h"
#import "QuadRect.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "QuadTree.h"
#import "OANativeUtilities.h"
#import "OATargetPointView.h"
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kTilePointsLimit = 25;
static const NSInteger kStartZoom = 5;
static const NSInteger kStartZoomRouteTrack = 11;
static const NSInteger kImageIconSizeDP = 45;
static void *kTopPlacesStateQueueKey = &kTopPlacesStateQueueKey;

@implementation OAPOILayerTopPlacesProvider
{
    NSMutableDictionary<NSNumber *, OAPOI *> *_topPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    NSArray<OAPOI *> *_allPlaces;
    NSArray<OAPOI *> *_displayedPlaces;
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
    OAPOI *_selectedTopPlace;
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

- (NSDictionary<NSNumber *, OAPOI *> *)topPlaces
{
    __block NSDictionary<NSNumber *, OAPOI *> *snapshot = nil;
    [self performStateSync:^{
        snapshot = _topPlaces ? [_topPlaces copy] : nil;
    }];
    return snapshot;
}

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

            OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI * __autoreleasing *object) {
                return YES;
            } cancelledFunc:^BOOL{
                return weakOp.isCancelled;
            }];

            NSArray<OAPOI *> *amenities = [weakSelf calculateAmenities:searchBounds matcher:matcher];

            if (weakOp.isCancelled || !amenities)
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

- (void)updateSelectedTopPlaceIfNeeded:(OAPOI *)topPlace
{
    dispatch_async(_backgroundQueue, ^{
        if ((!_selectedTopPlace && !topPlace)
            || (_selectedTopPlace
                && topPlace
                && [_selectedTopPlace getSignedId] == [topPlace getSignedId]))
        {
            return;
        }

        if (topPlace && _topPlaces[@([topPlace getSignedId])])
            _selectedTopPlace = topPlace;
        else
            _selectedTopPlace = nil;

        [self updateTopPlacesCollection];
    });
}

- (void)contextMenuDidShow:(id)targetObj
{
    OAPOI *amenity = [self topPlaceAmenityFor:targetObj];
    if (amenity)
        [self updateSelectedTopPlaceIfNeeded:amenity];
    else
        [self resetSelectedTopPlaceIfNeeded];
}

- (OAPOI *)topPlaceAmenityFor:(id)object
{
    NSDictionary<NSNumber *, OAPOI *> *topPlaces = [self topPlaces];

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
        OAPOI *syntheticAmenity = baseDetailsObject.syntheticAmenity;
        
        int64_t obfId = syntheticAmenity.getSignedId;
        if (!topPlaces[@(obfId)]) {
            for (id item in baseDetailsObject.objects)
            {
                if ([item isKindOfClass:[OAPOI class]])
                {
                    OAPOI *poi = (OAPOI *)item;
                    obfId = [poi getSignedId];
                    if (topPlaces[@(obfId)])
                        return poi;
                }
            }
        }
        return syntheticAmenity;
    }
    return nil;
}

- (NSArray<OAPOI *> *)displayedAmenities
{
    __block NSArray<OAPOI *> *displayedPlaces = nil;
    [self performStateSync:^{
        displayedPlaces = _displayedPlaces;
    }];
    return displayedPlaces ?: @[];
}

- (void)resetSelectedTopPlaceIfNeeded
{
    dispatch_async(_backgroundQueue, ^{
        if (_selectedTopPlace)
        {
            _selectedTopPlace = nil;
            [self updateTopPlacesCollection];
        }
    });
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

- (nullable UIImage *)markerImageForPlace:(OAPOI *)place
{
    UIImage *baseImage = _topPlacesImages[@([place getSignedId])];
    if (!baseImage)
        return nil;

    if (_selectedTopPlace && [_selectedTopPlace getSignedId] == [place getSignedId])
        return [POITopPlaceImageDecorator selectedImageFor:baseImage];

    return baseImage;
}

- (nullable NSString *)markerStateForPlace:(OAPOI *)place image:(UIImage *)image
{
    if (!image)
        return nil;

    BOOL isSelected = _selectedTopPlace && [_selectedTopPlace getSignedId] == [place getSignedId];
    return [NSString stringWithFormat:@"%lld:%d:%p", [place getSignedId], isSelected, image];
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

- (BOOL)addTopPlaceMarker:(OAPOI *)place
                 markerId:(int32_t)markerId
                    image:(UIImage *)image
       toCollectionLocked:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
{
    if (!image)
        return NO;

    NSData *data = UIImagePNGRepresentation(image);
    if (!data)
        return NO;

    CLLocationCoordinate2D coordinate = place.getLocation.coordinate;
    OsmAnd::MapMarkerBuilder builder;
    builder.setIsAccuracyCircleSupported(false)
        .setMarkerId(markerId)
        .setBaseOrder(_topPlaceBaseOrder)
        .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
        .setPosition([OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(coordinate.latitude, coordinate.longitude)])
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
    _allPlaces = nil;
    _displayedPlaces = nil;
    _loadingImagePlaceIds = nil;
    _topPlacesBox = nil;
    _lastCalcBounds = nil;
    _lastCalcZoom = 0.f;
    _selectedTopPlace = nil;
    _renderedMarkerStates = nil;
}

- (void)applyAmenities:(NSArray<OAPOI *> *)amenities
            generation:(NSUInteger)generation
{
    dispatch_async(_backgroundQueue, ^{
        if (_amenitiesGeneration != generation)
            return;

        _allPlaces = [amenities copy];
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

    if (_allPlaces == nil)
    {
        _displayedPlaces = nil;
        _topPlacesBox = nil;
        [self clearMapMarkersCollections];
        [self cancelLoadingImages];
        return;
    }

    _displayedPlaces = [[self collectDisplayedPoints:visibleBounds zoom:zoom amenities:_allPlaces] copy];
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

        if (_topPlaces && _topPlacesImages)
        {
            OAPOI *poi = _topPlaces[placeId];
            if (poi)
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
        NSMutableArray<OAPOI *> *places = _topPlaces ? [[_topPlaces allValues] mutableCopy] : nil;
        [self sortByElo:places];
        if (!places || places.count == 0)
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
        for (OAPOI *place in places)
        {
            UIImage *topPlaceImage = [self markerImageForPlace:place];
            if (!topPlaceImage)
                continue;

            int32_t markerId = [self truncatedTopPlaceId:place];
            NSNumber *markerKey = @(markerId);
            NSString *markerState = [self markerStateForPlace:place image:topPlaceImage];
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

- (int32_t)truncatedTopPlaceId:(OAPOI *)topPlace
{
    long long fullId = topPlace.obfId ?: topPlace.getTravelEloNumber;
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

- (void)updateTopPlaces:(NSArray<OAPOI *> *)places
           latLonBounds:(QuadRect *)latLonBounds
                   zoom:(int)zoom
{
    NSMutableDictionary<NSNumber *, OAPOI *> *newTopPlaces = [[self obtainTopPlacesToDisplay:places
                                                                                latLonBounds:latLonBounds
                                                                                        zoom:zoom] mutableCopy];
    NSSet<NSNumber *> *previousTopPlaceIds = _topPlaces ? [NSSet setWithArray:_topPlaces.allKeys] : [NSSet set];
    NSSet<NSNumber *> *newTopPlaceIds = [NSSet setWithArray:newTopPlaces.allKeys];
    BOOL topPlacesChanged = ![previousTopPlaceIds isEqualToSet:newTopPlaceIds];
    NSUInteger generation = topPlacesChanged ? ++_imagesGeneration : _imagesGeneration;
    NSDictionary<NSNumber *, UIImage *> *cachedImages = [_topPlacesImages copy] ?: @{};
    _topPlaces = newTopPlaces;

    NSMutableDictionary<NSNumber *, UIImage *> *preservedImages = [NSMutableDictionary dictionary];
    NSMutableArray<OAPOI *> *missingImagePlaces = [NSMutableArray array];
    NSMutableSet<NSNumber *> *missingImagePlaceIds = [NSMutableSet set];
    for (OAPOI *place in _topPlaces.allValues)
    {
        NSNumber *placeId = @([place getSignedId]);
        UIImage *cachedImage = cachedImages[placeId];
        if (cachedImage)
            preservedImages[placeId] = cachedImage;
        else
        {
            [missingImagePlaces addObject:place];
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

- (nonnull NSDictionary<NSNumber *, OAPOI *> *)obtainTopPlacesToDisplay:(nonnull NSArray<OAPOI *> *)places
                                                           latLonBounds:(nonnull QuadRect *)latLonBounds
                                                                   zoom:(int)zoom
{
    NSMutableDictionary<NSNumber *, OAPOI *> *res = [NSMutableDictionary dictionary];
    
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
    for (OAPOI *place in places)
    {
        double lat = place.latitude;
        double lon = place.longitude;
        
        if (![latLonBounds contains:lon top:lat right:lon bottom:lat]
            || place.wikiIconUrl == nil || place.wikiIconUrl.length == 0)
            continue;
        
        int x31 = OsmAnd::Utilities::get31TileNumberX(lon);
        int y31 = OsmAnd::Utilities::get31TileNumberY(lat);
        
        if (![[self class] intersectsD:boundIntersections
                                     x:x31
                                     y:y31
                                 width:iconSize31
                                height:iconSize31])
        {
            res[@([place getSignedId])] = place;
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

    _topPlaces = nil;
    _topPlacesImages = nil;
    _loadingImagePlaceIds = nil;
}

- (NSArray<OAPOI *> *)collectDisplayedPoints:(QuadRect *)latLonBounds
                                        zoom:(NSInteger)zoom
                                   amenities:(NSArray<OAPOI *> *)amenities
{
    NSMutableOrderedSet<OAPOI *> *displayedPoints = [NSMutableOrderedSet orderedSet];
    NSInteger topPlacesCounter = 0;
    for (OAPOI *amenity in amenities)
        if (topPlacesCounter < kTopPlacesLimit)
        {
            [displayedPoints addObject:amenity];
            topPlacesCounter++;
        }

    return displayedPoints.array;
}

- (NSArray<OAPOI *> *)calculateAmenities:(QuadRect *)latLonBounds
                                 matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSArray<OAPOI *> *cachedAmenities = self.cachedAmenitiesProvider ? self.cachedAmenitiesProvider(latLonBounds, matcher) : @[];
    if (self.cachedAmenitiesProvider && !cachedAmenities)
        return nil;

    NSMutableArray<OAPOI *> *amenities = cachedAmenities ? [cachedAmenities mutableCopy] : [NSMutableArray array];
    if ([matcher isCancelled])
        return @[];

    [self sortByElo:amenities];
    if ([matcher isCancelled])
        return @[];

    return amenities;
}

- (void)sortByElo:(NSMutableArray<OAPOI *> *)amenities {
    [amenities sortUsingComparator:^NSComparisonResult(OAPOI *a1, OAPOI *a2) {
        
        NSInteger elo1 = a1.getTravelEloNumber;
        NSInteger elo2 = a2.getTravelEloNumber;
        
        // 1. Elo DESC
        if (elo1 < elo2)
            return NSOrderedDescending;
        if (elo1 > elo2)
            return NSOrderedAscending;
        
        // 2. ID ASC
        if ([a1 getSignedId] < [a2 getSignedId])
            return NSOrderedAscending;
        if ([a1 getSignedId] > [a2 getSignedId])
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
}

@end
