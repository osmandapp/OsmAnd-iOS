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
#import "OAMapTopPlace.h"
#import "OATargetPointView.h"
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kTilePointsLimit = 25;
static const NSInteger kStartZoom = 5;
static const NSInteger kStartZoomRouteTrack = 11;
static const NSInteger kEndZoomRouteTrack = 22;
static const NSInteger kImageIconSizeDP = 45;
static const CLLocationDistance kPoiSearchRadius = 50.0; // meters

@implementation OAPOILayerTopPlacesProvider
{
    NSMutableDictionary<NSNumber *, OAPOI *> *_topPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    NSDictionary<NSString *, NSArray<OAPOI *> *> *_topPlaceData;
    NSMutableArray<OAPOI *> *_visiblePlaces;
    DataSourceType _wikiDataSource;
    BOOL _showTopPlacesPreviews;
    OAPOIUIFilter *_topPlacesFilter;
    NSSet<OAPOIUIFilter *> *_calculatedFilters;
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
    UIImage *_selectedTopPlaceImage;
    BOOL _isDisabled;
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
    _calculatedFilters = [_filtersHelper getSelectedPoiFilters];
    _wikiDataSourceType = [[OAAppSettings sharedManager].wikiDataSourceType get];
    _backgroundQueue = dispatch_queue_create("com.osmand.topplaces.background", DISPATCH_QUEUE_SERIAL);
    _popularPlacesQueue = [NSOperationQueue new];
    _popularPlacesQueue.maxConcurrentOperationCount = 1;
    _popularPlacesQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    [self updateDisabledState];
}

// MARK: - Public

- (NSDictionary<NSNumber *, OAPOI *> *)topPlaces
{
    return _topPlaces ? [_topPlaces copy] : nil;
}

- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc
{
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
            
            [weakSelf updateTopPlaceData:results];
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
        } else {
            if (!_isDisabled)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleTextScaleChangeIfNeeded];
                });
            }
        }
    });
}

- (void)resetLayer
{
    dispatch_async(_backgroundQueue, ^{
        [self clearMapMarkersCollections];
        _topPlacesBox = nil;
    });
}

- (void)updateSelectedTopPlaceIfNeeded:(OAPOI *)topPlace
{
    [_mapViewController runWithRenderSync:^{
        if (_mapMarkersCollection == nullptr)
            return;

        if (_selectedTopPlace
            && topPlace != nil
            && _selectedTopPlace.obfId == topPlace.obfId)
            return;

        if (_selectedTopPlace)
        {
            int32_t previousMarkerId = [self truncatedTopPlaceId:_selectedTopPlace];
            [self removeMarkerWithId:previousMarkerId];
            [self addTopPlaceMarker:_selectedTopPlace markerId:previousMarkerId isSelected:NO];
            _selectedTopPlaceImage = nil;
        }
        
        if (topPlace == nil || !_topPlaces[@(topPlace.obfId)])
            return;

        _selectedTopPlace = topPlace;

        int32_t markerId = [self truncatedTopPlaceId:topPlace];
        [self removeMarkerWithId:markerId];
        [self addTopPlaceMarker:topPlace markerId:markerId isSelected:YES];
    }];
}

- (NSArray<OAPOI *> *)getDisplayedResults:(double)lat lon:(double)lon
{
    NSMutableArray<OAPOI *> *result = [NSMutableArray new];
    if (!_topPlaces || _topPlaces.count == 0)
        return result;
    
    CLLocation *tapLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    
    // Collect candidates within radius with their distances
    NSMutableArray<NSDictionary *> *candidates = [NSMutableArray array];
    for (OAPOI *poi in _topPlaces.allValues)
    {
        CLLocation *poiLoc = [poi getLocation];
        if (!poiLoc)
            continue;
        CLLocationDistance distance = [tapLocation distanceFromLocation:poiLoc];
        if (distance <= kPoiSearchRadius)
            [candidates addObject:@{ @"poi": poi, @"distance": @(distance) }];
    }
    
    // Sort by distance ascending
    [candidates sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        double da = [a[@"distance"] doubleValue];
        double db = [b[@"distance"] doubleValue];
        if (da < db) return NSOrderedAscending;
        if (da > db) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    for (NSDictionary *entry in candidates)
        [result addObject:entry[@"poi"]];
    
    return [result copy];
}

- (void)resetSelectedTopPlaceIfNeeded
{
    [_mapViewController runWithRenderSync:^{
        if (_selectedTopPlace)
        {
            int32_t markerId = [self truncatedTopPlaceId:_selectedTopPlace];
            [self removeMarkerWithId:markerId];
            [self addTopPlaceMarker:_selectedTopPlace markerId:markerId isSelected:NO];
            _selectedTopPlace = nil;
            _selectedTopPlaceImage = nil;
        }
    }];
}

// MARK: - Private

- (void)updateDisabledState
{
    _isDisabled = _calculatedFilters.count == 0 || ![[OAAppSettings sharedManager].wikiShowImagePreviews get];
}

- (void)removeMarkerWithId:(int32_t)markerId
{
    if (!_mapMarkersCollection)
        return;
    
    QList<std::shared_ptr<OsmAnd::MapMarker>> markers = _mapMarkersCollection->getMarkers();
    
    for (const std::shared_ptr<OsmAnd::MapMarker> &marker : markers)
    {
        if (marker->markerId == markerId)
        {
            _mapMarkersCollection->removeMarker(marker);
        }
    }
}

- (void)addTopPlaceMarker:(OAPOI *)place
                 markerId:(int32_t)markerId
               isSelected:(BOOL)isSelected
{
    UIImage *image = nil;
    if (isSelected)
    {
        image = [self topPlaceImage:place];
        if (!image)
            return;
    }
    else
    {
        image = _topPlacesImages[@(place.obfId)];
        if (!image)
            return;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    if (!data)
        return;

    OsmAnd::MapMarkerBuilder builder;
    builder.setIsAccuracyCircleSupported(false)
        .setMarkerId(markerId)
        .setBaseOrder(_topPlaceBaseOrder)
        .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
        .setPosition([OANativeUtilities getPoint31FromLatLon:
            OsmAnd::LatLon(place.getLocation.coordinate.latitude,
                           place.getLocation.coordinate.longitude)])
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);

    std::shared_ptr<OsmAnd::MapMarker> marker =
        builder.buildAndAddToCollection(_mapMarkersCollection);
    marker->setUpdateAfterCreated(true);
}

- (BOOL)dataChanged
{
    NSSet<OAPOIUIFilter *> *calculatedFilters = [_filtersHelper getSelectedPoiFilters];
    if (![_calculatedFilters isEqualToSet:calculatedFilters])
    {
        _calculatedFilters = calculatedFilters;
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

    _topPlaceData = nil;
    _topPlacesBox = nil;
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
    return [_visiblePlaces copy];
}

- (nullable UIImage *)topPlaceImage:(OAPOI *)place
{
    if (_topPlacesImages == nil)
        return nil;
    
    UIImage *baseImage = _topPlacesImages[@(place.obfId)];
    if (baseImage == nil)
        return nil;
    
    if (_selectedTopPlace.obfId == place.obfId)
    {
        if (_selectedTopPlaceImage) {
            return _selectedTopPlaceImage;
        }
        _selectedTopPlaceImage = [POITopPlaceImageDecorator selectedImageFor:baseImage];
        return _selectedTopPlaceImage;
    }
    
    return baseImage;
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
{
    NSLog(@"[test] updateTopPlaceData");
    _topPlaceData = results;
    [self updatePopularPlaces];
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
            NSArray<OAPOI *> *allPlaces = _topPlaceData[@"all"];
            [self updateVisiblePlaces:_topPlaceData[@"displayed"] latLonBounds:screenRect];
            
            if (allPlaces != nil)
            {
                QuadRect *extendedBox = [[QuadRect alloc] initWithRect:screenRect];
                double lonDelta = [screenRect width] * 0.1;
                double latDelta = [screenRect height] * 0.1;
                [extendedBox inset:-lonDelta dy:-latDelta];
                
                _topPlacesBox = extendedBox;
                NSLog(@"[test] updatePopularPlaces changed 1");
                
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

//- (nullable OAPOI *)getSelectedTopPlace:(BaseDetailsObject *)detailsObject
//{
//    if (self.topPlaces.count > 0)
//    {
//        OAPOI *poi = (OAPOI *)detailsObject;
//        if (poi)
//        {
//            return self.topPlaces[@(poi.obfId)];
//        }
//        else
//        {
//            for (OAPOI *amenity in [detailsObject getAmenities])
//            {
//                OAPOI *topPlace = self.topPlaces[@(amenity.obfId)];
//                if (topPlace)
//                {
//                    return topPlace;
//                }
//            }
//        }
//    }
//    
//    return nil;
//}

- (void)updateTopPlaceImageForId:(NSNumber *)placeId
                           image:(UIImage *)image
{
    dispatch_async(_backgroundQueue, ^{
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
        NSArray<OAPOI *> *places = _topPlaces ? [_topPlaces allValues] : nil;
        if (!places || places.count == 0)
        {
            [self clearMapMarkersCollections];
            return;
        }
        
        if (!_mapMarkersCollection)
            _mapMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        
        QList<std::shared_ptr<OsmAnd::MapMarker>> existingMarkers = _mapMarkersCollection->getMarkers();
        
        NSMutableDictionary<NSNumber *, NSValue *> *markersMap = [NSMutableDictionary dictionary];
        for (const auto& marker : existingMarkers)
        {
            markersMap[@(marker->markerId)] = [NSValue valueWithPointer:new std::shared_ptr<OsmAnd::MapMarker>(marker)];
        }
        
        NSMutableArray<OAMapTopPlace *> *mapPlacesToUpdate = [NSMutableArray array];
        
        for (OAPOI *place in places)
        {
            // NOTE:
            // Resolve the ID issue: use the lower 32 bits or a hash.
            // If obfId fits into an int, use it; otherwise, hash it.
            int32_t truncatedId = [self truncatedTopPlaceId:place];
            
            BOOL alreadyExists = NO;
            NSNumber *idKey = @(truncatedId);
            
            if (markersMap[idKey])
            {
                alreadyExists = YES;
                [markersMap removeObjectForKey:idKey];
            }
            
            UIImage *topPlaceImage = [self topPlaceImage:place];
            if (topPlaceImage)
            {
                OAMapTopPlace *mapTopPlace = [[OAMapTopPlace alloc] initWithPlaceId:truncatedId
                                                                           position:[OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(place.getLocation.coordinate.latitude, place.getLocation.coordinate.longitude)]
                                                                              image:topPlaceImage
                                                                      alreadyExists:alreadyExists];
                [mapPlacesToUpdate addObject:mapTopPlace];
            }
            
            if (mapPlacesToUpdate.count >= kTopPlacesLimit)
                break;
        }
        
        for (NSNumber *key in markersMap)
        {
            std::shared_ptr<OsmAnd::MapMarker>* markerPtr = (std::shared_ptr<OsmAnd::MapMarker>*)[markersMap[key] pointerValue];
            _mapMarkersCollection->removeMarker(*markerPtr);
            delete markerPtr;
        }
        
        for (OAMapTopPlace *place in mapPlacesToUpdate)
        {
            if (place.alreadyExists)
                continue;
            
            NSData *data = UIImagePNGRepresentation(place.image);
            if (data)
            {
                NSLog(@"[test] mapPlacesToUpdate");
                OsmAnd::MapMarkerBuilder builder;
                builder.setIsAccuracyCircleSupported(false)
                    .setMarkerId(place.placeId)
                    .setBaseOrder(_topPlaceBaseOrder)
                    .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
                    .setPosition(place.position)
                    .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
                    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
                std::shared_ptr<OsmAnd::MapMarker> marker =
                    builder.buildAndAddToCollection(_mapMarkersCollection);
                marker->setUpdateAfterCreated(true);
            }
            else
            {
                NSLog(@"[test] UIImagePNGRepresentation is nil");
            }
        }
        // TOP_PLACES_POI_SECTION
        _mapView.renderer->addSymbolsProvider(kFavoritesSymbolSection, _mapMarkersCollection);
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
        if (_mapMarkersCollection != nil)
        {
            NSLog(@"[test] clearMapMarkersCollections");
            [_mapView removeKeyedSymbolsProvider:_mapMarkersCollection];
            _mapMarkersCollection.reset();
        }
    }];
}

- (void)updateTopPlaces:(NSArray<OAPOI *> *)places
           latLonBounds:(QuadRect *)latLonBounds
                   zoom:(int)zoom
{
    dispatch_async(_backgroundQueue, ^{
        NSArray<OAPOI *> *topPlacesList = nil;
        
        if (_topPlacesFilter != nil)
        {
            _topPlaces = [[self obtainTopPlacesToDisplay:places
                                            latLonBounds:latLonBounds
                                                    zoom:zoom] mutableCopy];
            _topPlacesImages = [NSMutableDictionary dictionary];
            topPlacesList = [_topPlaces allValues];
        }
        
        if (topPlacesList != nil)
        {
            if (topPlacesList.count > 0)
            {
                if (!_imageLoader)
                    _imageLoader = [POIImageLoader new];
                
                __weak __typeof(self) weakSelf = self;
                [_imageLoader fetchImages:topPlacesList completion:^(NSNumber *placeId, UIImage *image) {
                    [weakSelf updateTopPlaceImageForId:placeId image:image];
                }];
            }
            else
            {
                [self cancelLoadingImages];
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
            res[@(place.obfId)] = place;
            counter++;
        }
        
        if (counter++ >= kTopPlacesLimit)
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
        NSLog(@"[test] cancelLoadingImages");
        [_imageLoader cancelAll];
        _imageLoader = nil;
        _topPlaces = nil;
        _topPlacesImages = nil;
        _visiblePlaces = nil;
    }
}

- (NSSet<OAPOI *> *)collectDisplayedPoints:(QuadRect *)latLonBounds
                                      zoom:(NSInteger)zoom
                                       res:(NSArray<OAPOI *> *)res
{
    NSMutableSet<OAPOI *> *displayedPoints = [NSMutableSet set];
    
    NSInteger i = 0;
    for (OAPOI *amenity in res)
    {
        if ([self shouldDraw:amenity zoom:zoom])
        {
            [displayedPoints addObject:amenity];
            if (i++ > kTopPlacesLimit)
                break;
        }
    }
    
    float minTileX = [OASKMapUtils.shared getTileNumberXZoom:zoom longitude:latLonBounds.left];
    float maxTileX = [OASKMapUtils.shared getTileNumberXZoom:zoom longitude:latLonBounds.right];
    float minTileY = [OASKMapUtils.shared getTileNumberYZoom:zoom latitude:latLonBounds.top];
    float maxTileY = [OASKMapUtils.shared getTileNumberYZoom:zoom latitude:latLonBounds.bottom];
    
    for (NSInteger tileX = (NSInteger)minTileX; tileX <= (NSInteger)maxTileX; tileX++)
    {
        for (NSInteger tileY = (NSInteger)minTileY; tileY <= (NSInteger)maxTileY; tileY++)
        {
            @autoreleasepool
            {
                double alignedTileX = [self alignTileWithZoom:zoom tile:tileX];
                double alignedTileY = [self alignTileWithZoom:zoom tile:tileY];
                
                QuadRect *tileLatLonBounds = [[QuadRect alloc] initWithLeft:[OASKMapUtils.shared getLongitudeFromTileZoom:zoom x:alignedTileX]
                                                                        top:[OASKMapUtils.shared getLatitudeFromTileZoom:zoom y:alignedTileY]
                                                                      right:[OASKMapUtils.shared getLongitudeFromTileZoom:zoom x:(alignedTileX + 1.0)]
                                                                     bottom:[OASKMapUtils.shared getLatitudeFromTileZoom:zoom y:(alignedTileY + 1.0)]];
                
                double alignedTileXMin = [self alignTileWithZoom:zoom tile:(tileX - 0.5)];
                double alignedTileYMin = [self alignTileWithZoom:zoom tile:(tileY - 0.5)];
                double alignedTileXMax = [self alignTileWithZoom:zoom tile:(tileX + 1.5)];
                double alignedTileYMax = [self alignTileWithZoom:zoom tile:(tileY + 1.5)];
                
                QuadRect *extTileLatLonBounds = [[QuadRect alloc] initWithLeft:[OASKMapUtils.shared getLongitudeFromTileZoom:zoom x:alignedTileXMin]
                                                                           top:[OASKMapUtils.shared getLatitudeFromTileZoom:zoom y:alignedTileYMin]
                                                                         right:[OASKMapUtils.shared getLongitudeFromTileZoom:zoom x:alignedTileXMax]
                                                                        bottom:[OASKMapUtils.shared getLatitudeFromTileZoom:zoom y:alignedTileYMax]];
                i = 0;
                for (OAPOI *amenity in res)
                {
                    if (![self shouldDraw:amenity zoom:zoom])
                        continue;
                    
                    CLLocation *location = [amenity getLocation];
                    double lon = location.coordinate.longitude;
                    double lat = location.coordinate.latitude;
                    
                    if ([extTileLatLonBounds contains:lon top:lat right:lon bottom:lat])
                    {
                        if ([tileLatLonBounds contains:lon top:lat right:lon bottom:lat])
                        {
                            [displayedPoints addObject:amenity];
                            
                            if (++i == kTilePointsLimit)
                                break;
                        }
                    }
                }
            }
        }
    }
    
    return displayedPoints;
}

- (NSDictionary<NSString *, NSArray<OAPOI *> *> *)calculateResult:(QuadRect *)latLonBounds
                                                             zoom:(NSInteger)zoom
                                                          matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSLog(@"[test] calculateResult");
    NSMutableSet<OAPOIUIFilter *> *poiUIFilters = [_calculatedFilters mutableCopy];
    if (poiUIFilters.count == 0)
    {
        _topPlacesFilter = nil;
        return @{ @"all": @[], @"displayed": @[] };
    }
    
    NSInteger z = (NSInteger)floor(zoom + log([[OAAppSettings sharedManager].mapDensity get]) / log(2.0));
    
    NSMutableArray<OAPOI *> *res = [NSMutableArray array];
    NSMutableSet<NSString *> *uniqueRouteIds = [NSMutableSet set];
    _topPlacesFilter = nil;
    
    for (OAPOIUIFilter *filter in poiUIFilters)
    {
        if (filter.isTopImagesFilter)
            _topPlacesFilter = filter;
    }
    
    [OAPOIUIFilter combineStandardPoiFilters:poiUIFilters];
    
    //    double top = 48.57478991092886;
    //    double left = 34.9365234375;
    //    double bottom = 48.341646172374595;
    //    double right = 35.15625;
    //    int zoomTest = 13;
    
    for (OAPOIUIFilter *filter in poiUIFilters)
    {
        NSMutableArray<OAPOI *> *amenities = [[filter searchAmenities:latLonBounds.top
                                                                 left:latLonBounds.left
                                                               bottom:latLonBounds.bottom
                                                                right:latLonBounds.right
                                                                 zoom:(int)z
                                                              matcher:matcher
                                                         filterUnique:YES] mutableCopy];
        if ([matcher isCancelled])
        {
            NSLog(@"[test] calculateResult [matcher isCancelled] || _isDisabled");
            return @{ @"all": @[], @"displayed": @[] };
        }
        
        if (filter.isTopWikiFilter)
        {
            [self sortByElo:amenities];
            [res insertObjects:amenities atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, amenities.count)]];
        }
        else
        {
            for (OAPOI *amenity in amenities)
            {
                if (amenity.isRouteTrack)
                {
                    NSString *routeId = [amenity getRouteId];
                    if (routeId != nil && [uniqueRouteIds containsObject:routeId])
                        continue;
                    
                    if (routeId != nil)
                        [uniqueRouteIds addObject:routeId];
                }
                [res addObject:amenity];
            }
        }
    }
    NSLog(@"[test] calculateResult displayedPoints 0");
    NSSet<OAPOI *> *displayedPoints = [self collectDisplayedPoints:latLonBounds zoom:zoom res:res];
    NSLog(@"[test] calculateResult displayedPoints 1");
    if ([matcher isCancelled])
    {
        NSLog(@"[test] calculateResult displayedPoints 2");
        return @{ @"all": @[], @"displayed": @[] };
    }
    
    return @{ @"all": res, @"displayed": displayedPoints.allObjects };
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
        if (a1.obfId < a2.obfId)
            return NSOrderedAscending;
        if (a1.obfId > a2.obfId)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
}

- (double)alignTileWithZoom:(double)zoom tile:(double)tile
{
    if (tile < 0)
        return 0.0;
    
    double powZoom = [OASKMapUtils.shared getPowZoomZoom:zoom];
    if (tile >= powZoom)
        return powZoom - 0.000001;
    
    return tile;
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

@end
