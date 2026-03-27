//
//  OAPOILayerTopPlacesProvider.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPOILayerTopPlacesProvider.h"
#import "OAPOI.h"
#import "OAPOIUIFilter.h"
#import "QuadRect.h"
#import "OAPOIFiltersHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAAppSettings.h"
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
static NSString * const kAllTopPlacesKey = @"all";
static NSString * const kDisplayedTopPlacesKey = @"displayed";
static void *kTopPlacesStateQueueKey = &kTopPlacesStateQueueKey;

@implementation OAPOILayerTopPlacesProvider
{
    NSMutableDictionary<NSNumber *, OAPOI *> *_topPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    NSDictionary<NSString *, NSArray<OAPOI *> *> *_topPlaceData;
    NSMutableArray<OAPOI *> *_visiblePlaces;
    BOOL _showTopPlacesPreviews;
    OAPOIUIFilter *_topPlacesFilter;
    QuadRect *_topPlacesBox;
    QuadRect *_lastCalcBounds;
    float _lastCalcZoom;
    NSOperationQueue *_popularPlacesQueue;
    
    POIImageLoader *_imageLoader;
    dispatch_queue_t _backgroundQueue;
    OAMapRendererView *_mapView;
    OAPOIFiltersHelper *_filtersHelper;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _mapMarkersCollection;
    
    int _topPlaceBaseOrder;
    OAMapViewController *_mapViewController;
    EOAWikiDataSourceType _wikiDataSourceType;
    CGFloat _textScale;
    OAPOI *_selectedTopPlace;
    BOOL _isDisabled;
    NSSet<NSString *> *_storedWikipediaResourceIds;
    NSMutableDictionary<NSNumber *, NSString *> *_renderedMarkerStates;
    NSUInteger _stateGeneration;
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
    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _mapView = (OAMapRendererView *)[OARootViewController instance].mapPanel.mapViewController.view;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _textScale = [self textScale];
    _wikiDataSourceType = [[OAAppSettings sharedManager].wikiDataSourceType get];
    NSSet<OAPOIUIFilter *> *poiUIFilters = [_filtersHelper getSelectedPoiFilters];
    for (OAPOIUIFilter *filter in poiUIFilters)
        if (filter.isTopImagesFilter)
            _topPlacesFilter = filter;

    _backgroundQueue = dispatch_queue_create("com.osmand.topplaces.background", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_backgroundQueue, kTopPlacesStateQueueKey, kTopPlacesStateQueueKey, NULL);
    _popularPlacesQueue = [NSOperationQueue new];
    _popularPlacesQueue.maxConcurrentOperationCount = 1;
    _popularPlacesQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    _showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    [self storeWikipediaResources:[OAResourcesUISwiftHelper findWikiMapRegionsAtCurrentMapLocation]];
    [self updateDisabledState];
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
    if (_isDisabled)
        return;

    dispatch_async(_backgroundQueue, ^{
        if (_isDisabled)
            return;
        
        const auto screenBbox = _mapView.getVisibleBBox31;
        float currentZoom = [_mapView zoom];
        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
        
        CLLocationCoordinate2D topLeftCoord = CLLocationCoordinate2DMake(topLeft.latitude, topLeft.longitude);
        CLLocationCoordinate2D bottomRightCoord = CLLocationCoordinate2DMake(bottomRight.latitude, bottomRight.longitude);
        if (!CLLocationCoordinate2DIsValid(topLeftCoord) || !CLLocationCoordinate2DIsValid(bottomRightCoord))
            return;
        
        QuadRect *currentBounds = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
        BOOL shouldRecalc = NO;
        
        if (_lastCalcBounds == nil)
        {
            shouldRecalc = YES;
        }
        else
        {
            BOOL zoomChanged = fabs(currentZoom - _lastCalcZoom) > 0.5;
            
            double halfW = fabs(_lastCalcBounds.width) / 2.0;
            double halfH = fabs(_lastCalcBounds.height) / 2.0;
            
            double prevCx = (_lastCalcBounds.left + _lastCalcBounds.right) / 2.0;
            double prevCy = (_lastCalcBounds.top + _lastCalcBounds.bottom) / 2.0;
            double curCx = (currentBounds.left + currentBounds.right) / 2.0;
            double curCy = (currentBounds.top + currentBounds.bottom) / 2.0;
            
            double dx = fabs(curCx - prevCx);
            double dy = fabs(curCy - prevCy);
            
            BOOL moved = (dx > halfW) || (dy > halfH);
            
            shouldRecalc = zoomChanged || moved;
            
            if (zoomChanged)
            {
                _topPlacesBox = nil;
            }
        }
        
        if (!forceRecalc && !shouldRecalc)
        {
            [self updatePopularPlaces];
            return;
        }
        
        _lastCalcBounds = [[QuadRect alloc] initWithRect:currentBounds];
        _lastCalcZoom = currentZoom;
        
        [_popularPlacesQueue cancelAllOperations];
        NSUInteger generation = ++_stateGeneration;
        
        __weak __typeof(self) weakSelf = self;
        NSBlockOperation *op = [NSBlockOperation new];
        __weak NSBlockOperation *weakOp = op;
        
        QuadRect *screenRect = [[QuadRect alloc] initWithRect:_lastCalcBounds];
        [screenRect inset:-(screenRect.width / 2.0) dy:-(screenRect.height / 2.0)];
        
        [op addExecutionBlock:^{
            if (weakOp.isCancelled)
                return;
            
            OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI * __autoreleasing *object) {
                return YES;
            } cancelledFunc:^BOOL{
                return weakOp.isCancelled;
            }];
            
            NSDictionary *results = [weakSelf calculateResult:screenRect zoom:currentZoom matcher:matcher];
            
            if (weakOp.isCancelled)
                return;
            
            [weakSelf updateTopPlaceData:results generation:generation];
        }];
        
        [_popularPlacesQueue addOperation:op];
    });
}

- (void)updateLayer
{
    dispatch_async(_backgroundQueue, ^{
        if ([self dataChanged])
        {
            [self resetTopPlacesState];
            [self drawTopPlacesIfNeeded:YES];
            return;
        }
        
        if (_isDisabled)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<OAResourceSwiftItem *> *items = [OAResourcesUISwiftHelper findWikiMapRegionsAtCurrentMapLocation];
            
            BOOL resourcesChanged = [self hasWikipediaResourcesChanged:items];
            
            if (resourcesChanged)
            {
                [self storeWikipediaResources:items];
                
                dispatch_async(_backgroundQueue, ^{
                    [self resetTopPlacesState];
                    [self drawTopPlacesIfNeeded:YES];
                });
            }
            else
            {
                [self handleTextScaleChangeIfNeeded];
            }
        });
    });
}

- (void)resetLayer
{
    dispatch_async(_backgroundQueue, ^{
        [self resetTopPlacesState];
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
    __block NSDictionary<NSString *, NSArray<OAPOI *> *> *topPlaceData = nil;
    [self performStateSync:^{
        topPlaceData = _topPlaceData;
    }];
    return topPlaceData ? topPlaceData[kDisplayedTopPlacesKey] : @[];
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

- (void)updateDisabledState
{
    _isDisabled = !_topPlacesFilter || ![[OAAppSettings sharedManager].wikiShowImagePreviews get];
}

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

- (BOOL)dataChanged
{
    OAPOIUIFilter *topPlacesFilter = nil;
    NSSet<OAPOIUIFilter *> *poiUIFilters = [_filtersHelper getSelectedPoiFilters];
    for (OAPOIUIFilter *filter in poiUIFilters)
        if (filter.isTopImagesFilter)
            topPlacesFilter = filter;

    if (_topPlacesFilter != topPlacesFilter)
    {
        _topPlacesFilter = topPlacesFilter;
        [self updateDisabledState];
        return YES;
    }
    
    BOOL showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    if (_showTopPlacesPreviews != showTopPlacesPreviews)
    {
        _showTopPlacesPreviews = showTopPlacesPreviews;
        [self updateDisabledState];
        return YES;
    }
    
    EOAWikiDataSourceType wikiType = [[OAAppSettings sharedManager].wikiDataSourceType get];
    if (_wikiDataSourceType != wikiType)
    {
        _wikiDataSourceType = wikiType;
        return YES;
    }
    
    return NO;
}

- (void)resetTopPlacesState
{
    [self clearMapMarkersCollections];
    [self cancelLoadingImages];
    [_popularPlacesQueue cancelAllOperations];

    _stateGeneration++;
    _topPlaceData = nil;
    _topPlacesBox = nil;
    _lastCalcBounds = nil;
    _lastCalcZoom = 0.f;
    _selectedTopPlace = nil;
    _renderedMarkerStates = nil;
}

- (void)handleTextScaleChangeIfNeeded
{
    CGFloat textScale = [self textScale];
    if (_textScale != textScale)
    {
        _textScale = textScale;
        [self updatePopularPlaces];
    }
}

- (NSArray<OAPOI *> *)visiblePlaces {
    __block NSArray<OAPOI *> *snapshot = nil;
    [self performStateSync:^{
        snapshot = [_visiblePlaces copy];
    }];
    return snapshot;
}

- (void)updateVisiblePlaces:(nullable NSArray<OAPOI *> *)places
               latLonBounds:(QuadRect *)latLonBounds
{
    dispatch_async(_backgroundQueue, ^{
        if (!places)
        {
            _visiblePlaces = nil;
            return;
        }
        
        NSMutableArray<OAPOI *> *res = [NSMutableArray arrayWithCapacity:places.count];
        
        for (OAPOI *place in places)
        {
            CLLocation *location = [place getLocation];
            double lon = location.coordinate.longitude;
            double lat = location.coordinate.latitude;
            
            if ([latLonBounds contains:lon top:lat right:lon bottom:lat])
                [res addObject:place];
        }
        
        _visiblePlaces = res;
    });
}

- (void)updateTopPlaceData:(NSDictionary<NSString *, NSArray<OAPOI *> *> *)results
                 generation:(NSUInteger)generation
{
    dispatch_async(_backgroundQueue, ^{
        if (_stateGeneration != generation)
            return;

        _topPlaceData = [results copy];
        [self updatePopularPlaces];
    });
}

- (void)updatePopularPlaces
{
    dispatch_async(_backgroundQueue, ^{
        if (_isDisabled)
            return;
        
        NSSet<OAPOIUIFilter *> *calculatedFilters = [_filtersHelper getSelectedPoiFilters];
        if (calculatedFilters.count == 0)
            return;

        const auto screenBbox = _mapView.getVisibleBBox31;
        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
        
        CLLocationCoordinate2D topLeftCoord = CLLocationCoordinate2DMake(topLeft.latitude, topLeft.longitude);
        CLLocationCoordinate2D bottomRightCoord = CLLocationCoordinate2DMake(bottomRight.latitude, bottomRight.longitude);
        if (!CLLocationCoordinate2DIsValid(topLeftCoord) || !CLLocationCoordinate2DIsValid(bottomRightCoord))
            return;
        
        QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude
                                                          top:topLeft.latitude
                                                        right:bottomRight.longitude
                                                       bottom:bottomRight.latitude];
        
        if (_topPlacesBox == nil || ![_topPlacesBox contains:screenRect])
        {
            NSArray<OAPOI *> *allPlaces = _topPlaceData[kAllTopPlacesKey];
            [self updateVisiblePlaces:_topPlaceData[kDisplayedTopPlacesKey] latLonBounds:screenRect];
            
            if (allPlaces != nil)
            {
                QuadRect *extendedBox = [[QuadRect alloc] initWithRect:screenRect];
                double lonDelta = [screenRect width] * 0.1;
                double latDelta = [screenRect height] * 0.1;
                [extendedBox inset:-lonDelta dy:-latDelta];
                
                _topPlacesBox = extendedBox;
                
                [self updateTopPlaces:allPlaces latLonBounds:screenRect zoom:[_mapView zoom]];
            }
            else
            {
                [self clearMapMarkersCollections];
                [self cancelLoadingImages];
                _topPlacesBox = nil;
            }
        }
    });
}

- (void)updateTopPlaceImageForId:(NSNumber *)placeId
                           image:(UIImage *)image
                      generation:(NSUInteger)generation
{
    dispatch_async(_backgroundQueue, ^{
        if (_stateGeneration != generation)
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
            [self clearMapMarkersCollections];
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
    dispatch_async(_backgroundQueue, ^{
        NSUInteger generation = ++_stateGeneration;
        NSArray<OAPOI *> *topPlacesToLoad = nil;

        if (_topPlacesFilter != nil)
        {
            NSDictionary<NSNumber *, UIImage *> *cachedImages = [_topPlacesImages copy] ?: @{};
            _topPlaces = [[self obtainTopPlacesToDisplay:places
                                            latLonBounds:latLonBounds
                                                    zoom:zoom] mutableCopy];

            NSMutableDictionary<NSNumber *, UIImage *> *preservedImages = [NSMutableDictionary dictionary];
            NSMutableArray<OAPOI *> *missingImagePlaces = [NSMutableArray array];
            for (OAPOI *place in _topPlaces.allValues)
            {
                NSNumber *placeId = @([place getSignedId]);
                UIImage *cachedImage = cachedImages[placeId];
                if (cachedImage)
                    preservedImages[placeId] = cachedImage;
                else
                    [missingImagePlaces addObject:place];
            }
            _topPlacesImages = preservedImages;
            topPlacesToLoad = [missingImagePlaces copy];
            [self updateTopPlacesCollection];
        }

        if (topPlacesToLoad != nil)
        {
            if (topPlacesToLoad.count > 0)
            {
                if (!_imageLoader)
                    _imageLoader = [POIImageLoader new];
                else
                    [_imageLoader cancelAll];

                __weak __typeof(self) weakSelf = self;
                [_imageLoader fetchImages:topPlacesToLoad completion:^(NSNumber *placeId, UIImage *image) {
                    [weakSelf updateTopPlaceImageForId:placeId image:image generation:generation];
                }];
            }
            else if (_imageLoader)
            {
                [_imageLoader cancelAll];
            }
        }
    });
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
    
    int left   = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.left];
    int top    = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.top];
    int right  = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.right];
    int bottom = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.bottom];
    
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
            || place.wikiIconUrl == nil
            || place.wikiIconUrl.length == 0)
        {
            continue;
        }
        
        int x31 = [OASKMapUtils.shared get31TileNumberXLongitude:lon];
        int y31 = [OASKMapUtils.shared get31TileNumberYLatitude:lat];
        
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
    {
        if ([QuadRect intersects:rect b:visibleRect])
        {
            return YES;
        }
    }
    
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

- (CGFloat)textScale
{
    return [[OAAppSettings sharedManager].textSize get] * [OARootViewController.instance.mapPanel.mapViewController displayDensityFactor];
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
    _visiblePlaces = nil;
}

- (NSSet<OAPOI *> *)collectDisplayedPoints:(QuadRect *)latLonBounds
                                      zoom:(NSInteger)zoom
                                       res:(NSArray<OAPOI *> *)res
{
    NSMutableSet<OAPOI *> *displayedPoints = [NSMutableSet set];

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
        {
            [tileCounts addObject:@(0)];
        }
    }

    NSInteger topPlacesCounter = 0;
    for (OAPOI *amenity in res)
    {
        if (![self shouldDraw:amenity zoom:zoom])
            continue;

        if (topPlacesCounter < kTopPlacesLimit)
        {
            [displayedPoints addObject:amenity];
            topPlacesCounter++;
        }

        if (tileCounts)
        {
            CLLocation *location = [amenity getLocation];
            if (!location)
                continue;

            double lon = location.coordinate.longitude;
            double lat = location.coordinate.latitude;

            NSInteger tileX = (NSInteger)[OASKMapUtils.shared getTileNumberXZoom:zoom longitude:lon];
            NSInteger tileY = (NSInteger)[OASKMapUtils.shared getTileNumberYZoom:zoom latitude:lat];

            if (tileX < minTileX || tileX > maxTileX || tileY < minTileY || tileY > maxTileY)
                continue;

            NSInteger index = (tileX - minTileX) + (tileY - minTileY) * width;
            NSInteger currentCount = tileCounts[index].integerValue;
            if (currentCount < kTilePointsLimit)
            {
                [displayedPoints addObject:amenity];
                tileCounts[index] = @(currentCount + 1);
            }
        }
    }

    return displayedPoints;
}

- (NSDictionary<NSString *, NSArray<OAPOI *> *> *)calculateResult:(QuadRect *)latLonBounds
                                                             zoom:(NSInteger)zoom
                                                          matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    OAPOIUIFilter *filter = _topPlacesFilter;
    if (!filter)
        return @{ kAllTopPlacesKey: @[], kDisplayedTopPlacesKey: @[] };
    
    NSInteger z = (NSInteger)floor(zoom + log([[OAAppSettings sharedManager].mapDensity get]) / log(2.0));

    NSMutableArray<OAPOI *> *amenities = [NSMutableArray array];
    amenities = [[filter searchAmenities:latLonBounds.top
                                    left:latLonBounds.left
                                  bottom:latLonBounds.bottom
                                   right:latLonBounds.right
                                    zoom:(int)z
                                 matcher:matcher
                            filterUnique:YES] mutableCopy];
    if ([matcher isCancelled])
        return @{ kAllTopPlacesKey: @[], kDisplayedTopPlacesKey: @[] };
    
    [self sortByElo:amenities];

    NSSet<OAPOI *> *displayedPoints = [self collectDisplayedPoints:latLonBounds zoom:zoom res:amenities];

    if ([matcher isCancelled])
        return @{ kAllTopPlacesKey: @[], kDisplayedTopPlacesKey: @[] };
    
    return @{ kAllTopPlacesKey: amenities, kDisplayedTopPlacesKey: displayedPoints.allObjects };
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

- (BOOL)shouldDraw:(OAPOI *)amenity
              zoom:(NSInteger)zoom
{
    BOOL routeArticle =
    [ROUTE_ARTICLE_POINT isEqualToString:amenity.subType] ||
    [ROUTE_ARTICLE isEqualToString:amenity.subType];
    
    BOOL routeTrack = amenity.isRouteTrack;
    
    if (routeArticle)
    {
        return zoom >= kStartZoom;
        
    }
    else if (routeTrack)
    {
        return zoom >= kStartZoomRouteTrack;
    }
    else
    {
        return zoom >= kStartZoom;
    }
}

- (void)storeWikipediaResources:(NSArray<OAResourceSwiftItem *> *)items
{
    _storedWikipediaResourceIds = [NSSet setWithArray:[items valueForKey:@"resourceId"]];
}

- (BOOL)hasWikipediaResourcesChanged:(NSArray<OAResourceSwiftItem *> *)newItems
{
    NSSet *newIds = [NSSet setWithArray:[newItems valueForKey:@"resourceId"]];
    return ![_storedWikipediaResourceIds isEqualToSet:newIds];
}

@end
