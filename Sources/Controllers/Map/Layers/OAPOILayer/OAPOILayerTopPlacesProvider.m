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

#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kTilePointsLimit = 25;
static const NSInteger kStartZoom = 5;
static const NSInteger kStartZoomRouteTrack = 11;
static const NSInteger kEndZoomRouteTrack = 22;
static const NSInteger kImageIconSizeDP = 45;
/*static const NSInteger kImageIconBorderDP = 2*/;


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
    dispatch_queue_t _markersQueue;
    OAMapRendererView *_mapView;
    OAPOIFiltersHelper *_filtersHelper;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _mapMarkersCollection;
    
    int _topPlaceBaseOrder;
    OAMapViewController *_mapViewController;
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
    _popularPlacesQueue = [NSOperationQueue new];
    _popularPlacesQueue.maxConcurrentOperationCount = 1;
    _popularPlacesQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    _markersQueue = dispatch_queue_create("com.osmand.markers.update", DISPATCH_QUEUE_SERIAL);
}

// MARK: - Public

- (NSDictionary<NSNumber *, OAPOI *> *)topPlaces {
    return _topPlaces ? [_topPlaces copy] : nil;
}

- (void)updateLayer
{
    if (![[OAAppSettings sharedManager].wikiShowImagePreviews get])
    {
        [self clearMapMarkersCollections];
        [self cancelLoadingImages];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePopularPlaces];
        });
    }
}

- (void)drawTopPlacesIfNeeded
{
    //NSLog(@"[test] onMapFrameRendered");
    if (![[OAAppSettings sharedManager].wikiShowImagePreviews get])
    {
        return;
    }
    const auto screenBbox = _mapView.getVisibleBBox31;
    float currentZoom = [_mapView zoom];
    
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
    QuadRect *currentBounds = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
    
    BOOL shouldRecalc = NO;
    
    if (_lastCalcBounds == nil)
    {
        shouldRecalc = YES;
    } else
    {
        BOOL zoomChanged = fabs(currentZoom - _lastCalcZoom) > 0.1;
        
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
    }
    
    if (!shouldRecalc)
    {
        // [self updatePopularPlaces];
        return;
    }
    //    NSLog(@"[test] [BoundsLog] CUR: L:%.6f, T:%.6f, R:%.6f, B:%.6f | W:%.6f, H:%.6f",
    //          currentBounds.left, currentBounds.top, currentBounds.right, currentBounds.bottom,
    //          currentBounds.width, currentBounds.height);
    
    // Update last bounds and cancel previous operations
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
        {
            //  NSLog(@"[test] weakOp.isCancelled 0");
            return;
        }
        
        OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI * __autoreleasing *object) {
            return YES;
        } cancelledFunc:^BOOL{
            if (weakOp.isCancelled)
            {
                //  NSLog(@"[test] weakOp.isCancelled cancelledFunc");
            }
            return weakOp.isCancelled;
        }];
        _calculatedFilters = [_filtersHelper getSelectedPoiFilters];
        NSDictionary *results = [weakSelf calculateResult:screenRect zoom:currentZoom matcher:matcher];
        
        if (weakOp.isCancelled)
        {
            // NSLog(@"[test] weakOp.isCancelled 1");
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakOp.isCancelled)
            {
                // NSLog(@"[test] weakOp.isCancelled 2");
                return;
            }
            [weakSelf updateTopPlaceData:results];
        });
    }];
    
    [_popularPlacesQueue addOperation:op];
}

// MARK: - Private

- (NSArray<OAPOI *> *)visiblePlaces {
    return [_visiblePlaces copy];
}

- (nullable UIImage *)topPlaceImage:(OAPOI *)place {
    return _topPlacesImages != nil ? _topPlacesImages[@(place.obfId)] : nil;
}

- (void)updateVisiblePlaces:(nullable NSArray<OAPOI *> *)places
               latLonBounds:(QuadRect *)latLonBounds
{
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
}

- (void)updateTopPlaceData:(NSDictionary<NSString *, NSArray<OAPOI *> *> *)results
{
    NSLog(@"updateTopPlaceData");
    _topPlaceData = results;
    [self updatePopularPlaces];
}

// updatePopularPlaces -> Android: public void onPrepareBufferImage(Canvas canvas, RotatedTileBox tileBox, DrawSettings settings) {
- (void)updatePopularPlaces
{
    NSLog(@"[test] updatePopularPlaces");
    BOOL showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    BOOL showTopPlacesPreviewsChanged = _showTopPlacesPreviews != showTopPlacesPreviews;
    _showTopPlacesPreviews = showTopPlacesPreviews;
    
    if (YES/*showTopPlacesPreviewsChanged || topPlacesBox == null || !topPlacesBox.containsTileBox(tileBox)*/)
    {
        const auto screenBbox = _mapView.getVisibleBBox31;
        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
        QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
        
        NSArray<OAPOI *> *allPlaces = _topPlaceData[@"all"];
        [self updateVisiblePlaces:_topPlaceData[@"displayed"] latLonBounds:screenRect];
        
        //        BOOL intersects = [QuadRect intersects:_topPlacesBox b:screenRect];
        //        if (!intersects) {
        //        }
        
        //        BOOL notContains = (_topPlacesBox == nil) || ![_topPlacesBox contains:screenRect];
        //        if (notContains) {
        //            // аналог !topPlacesBox.containsTileBox(tileBox)
        //        }
        
        if (showTopPlacesPreviews)
        {
            // TODO: copy
            QuadRect *extendedBox = screenRect;
            // int bigIconSize = kImageIconSizeDP * [self textScale];
            //                            extendedBox.increasePixelDimensions(bigIconSize * 2, bigIconSize * 2);
            _topPlacesBox = extendedBox;
            [self updateTopPlaces:allPlaces latLonBounds:screenRect zoom:[_mapView zoom]];
            //    [self updateTopPlacesCollection];
        }
        else
        {
            [self clearMapMarkersCollections];
            [self cancelLoadingImages];
        }
    }
    
    //    if (updated || showTopPlacesPreviewsChanged || topPlacesBox == null || !topPlacesBox.containsTileBox(tileBox)) {
    //                List<Amenity> places = data.getResults();
    //                List<Amenity> places1 = data.getDisplayedResults();
    //                updateVisiblePlaces(data.getDisplayedResults(), tileBox.getLatLonBounds());
    //                if (showTopPlacesPreviews && places != null) {
    //                    RotatedTileBox extendedBox = tileBox.copy();
    //                    int bigIconSize = getBigIconSize();
    //                    extendedBox.increasePixelDimensions(bigIconSize * 2, bigIconSize * 2);
    //                    topPlacesBox = extendedBox;
    //                    updateTopPlaces(places, tileBox.getLatLonBounds(), zoom);
    //                    updateTopPlacesCollection();
    //                } else {
    //                    clearMapMarkersCollections();
    //                    cancelLoadingImages();
    //                }
    //            }
}

- (void)updateTopPlaceImageForId:(NSNumber *)placeId
                           image:(UIImage *)image
{
    if (_topPlaces && _topPlacesImages)
    {
        OAPOI *poi = _topPlaces[placeId];
        if (poi)
        {
            _topPlacesImages[placeId] = image;
            //    dispatch_async(_markersQueue, ^{
            [self updateTopPlacesCollection];
            //    });
        }
    }
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
            // Resolve the ID issue: use the lower 32 bits or a hash.
            // If obfId fits into an int, use it; otherwise, hash it.
            long long fullId = place.obfId ?: place.getTravelEloNumber;
            int32_t truncatedId = (int32_t)(fullId ^ (fullId >> 32));
            
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
                OsmAnd::MapMarkerBuilder builder;
                builder.setIsAccuracyCircleSupported(false)
                    .setMarkerId((int)place.placeId)
                    .setBaseOrder(_topPlaceBaseOrder)
                    .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
                    .setPosition(place.position)
                    .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
                    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
                    .buildAndAddToCollection(_mapMarkersCollection);
            }
        }
        // TOP_PLACES_POI_SECTION
        _mapView.renderer->addSymbolsProvider(kFavoritesSymbolSection, _mapMarkersCollection);
    }];

}

- (void)clearMapMarkersCollections
{
    [_mapViewController runWithRenderSync:^{
        if (_mapMarkersCollection != nil)
        {
            NSLog(@"[test] clearMapMarkersCollections");
            [_mapView removeKeyedSymbolsProvider:_mapMarkersCollection];
            _mapMarkersCollection = nullptr;
        }
    }];
}

- (void)updateTopPlaces:(NSArray<OAPOI *> *)places
           latLonBounds:(QuadRect *)latLonBounds
                   zoom:(int)zoom
{
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
            [_imageLoader fetchImages:places completion:^(NSNumber *placeId, UIImage *image) {
                //  NSLog(@"Loaded image for placeId %@", placeId);
                [weakSelf updateTopPlaceImageForId:placeId image:image];
            }];
            
            /*
             {(
             "https://data.osmand.net/wikimedia/images-1280/6/67/\U0418\U043d\U0441\U0442\U0438\U0442\U0443\U0442_\U0447\U0435\U0440\U043d\U043e\U0439_\U043c\U0435\U0442\U0430\U043b\U043b\U0443\U0440\U0433\U0438\U0438_\U041d\U0410\U041d_\U0423\U043a\U0440\U0430\U0438\U043d\U044b.jpg?width=160",
             "https://data.osmand.net/wikimedia/images-1280/a/ab/DNU_library.JPG?width=160",
             "https://data.osmand.net/wikimedia/images-1280/0/05/\U0411\U043e\U0442\U0430\U043d\U0456\U0447\U043d\U0438\U0439_\U0441\U0430\U0434_\U0414\U041d\U0423_17.JPG?width=160",
             "https://data.osmand.net/wikimedia/images-1280/1/1b/Gagarina_Prospekt10_(Dnepropetrovsk).jpg?width=160"
             )}
             
             */
            
            //            NSMutableSet<NSString *> *imagesToLoad = [NSMutableSet set];
            //
            //            for (OAPOI *place in places) {
            //                NSString *iconUrl = place.wikiIconUrl; // лениво загрузится, если нужно
            //                if (iconUrl != nil && iconUrl.length > 0) {
            //                    [imagesToLoad addObject:iconUrl];
            //                }
            //            }
            //            NSLog(@"%@", imagesToLoad);
        }
        else
        {
            [self cancelLoadingImages];
        }
    }
}

- (nonnull NSDictionary<NSNumber *, OAPOI *> *)obtainTopPlacesToDisplay:(nonnull NSArray<OAPOI *> *)places
                                                           latLonBounds:(nonnull QuadRect *)latLonBounds
                                                                   zoom:(int)zoom
{
    NSMutableDictionary<NSNumber *, OAPOI *> *res = [NSMutableDictionary dictionary];
    
    long long tileSize31 = (1LL << (31 - zoom));
    double from31toPixelsScale = 256.0 / (double)tileSize31;
    double estimatedIconSize = kImageIconSizeDP * [self textScale];
    float iconSize31 = (float)(estimatedIconSize / from31toPixelsScale);
    
    int left   = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.left];
    int top    = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.top];
    int right  = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.right];
    int bottom = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.bottom];
    
    QuadTree *boundIntersections =
    [[self class] initBoundIntersections:left
                                     top:top
                                   right:right
                                  bottom:bottom];
    
    int i = 0;
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
        }
        
        //        if (res.count > kTopPlacesLimit)
        //        {
        //            break;
        //        }
        //        i++;
        
        // NOTE: android
        if (i++ > kTopPlacesLimit)
        {
            break;
        }
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
    
    return displayedPoints;
}

- (NSDictionary<NSString *, NSArray<OAPOI *> *> *)calculateResult:(QuadRect *)latLonBounds
                                                             zoom:(NSInteger)zoom
                                                          matcher:(OAResultMatcher<OAPOI *> *)matcher
{
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
    
    for (OAPOIUIFilter *filter in poiUIFilters)
    {
        NSMutableArray<OAPOI *> *amenities = [[filter searchAmenities:latLonBounds.top
                                                                 left:latLonBounds.left
                                                               bottom:latLonBounds.bottom
                                                                right:latLonBounds.right
                                                                 zoom:(int)z
                                                              matcher:matcher] mutableCopy];
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
    
    NSSet<OAPOI *> *displayedPoints = [self collectDisplayedPoints:latLonBounds zoom:zoom res:res];
    
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
        //        if ([travelRendererHelper.routeTracksProperty get])
        //        {
        //            return zoom >= kStartZoom && zoom <= kEndZoomRouteTrack;
        //        }
        //        else
        //        {
        return zoom >= kStartZoomRouteTrack;
        //     }
    }
    else
    {
        return zoom >= kStartZoom;
    }
}

@end
