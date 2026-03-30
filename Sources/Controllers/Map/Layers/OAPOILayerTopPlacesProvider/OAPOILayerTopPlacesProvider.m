#import "OAPOILayerTopPlacesProvider.h"

#import "OAPOI.h"
#import "OAPOIMapLayerData.h"
#import "OAPOIUIFilter.h"
#import "QuadRect.h"
#import "OAPOIFiltersHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAppSettings.h"
#import "QuadTree.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kImageIconSizeDP = 45;

@implementation OAPOILayerTopPlacesProvider
{
    OAPOIMapLayerData *_mapLayerData;
    NSMutableDictionary<NSNumber *, OAPOI *> *_topPlaces;
    NSMutableArray<OAPOI *> *_orderedTopPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    NSMutableArray<OAPOI *> *_visiblePlaces;
    OAPOIUIFilter *_topPlacesFilter;
    NSSet<OAPOIUIFilter *> *_calculatedFilters;
    QuadRect *_topPlacesBox;

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
    BOOL _showTopPlacesPreviews;
    NSSet<NSString *> *_storedWikipediaResourceIds;
}

- (instancetype)initWithTopPlaceBaseOrder:(int)baseOrder
{
    self = [super init];
    if (self)
    {
        _topPlaceBaseOrder = baseOrder;
        [self configure];
    }
    return self;
}

- (void)configure
{
    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _mapView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _textScale = [self textScale];
    _calculatedFilters = [_filtersHelper getSelectedPoiFilters];
    _wikiDataSourceType = [[OAAppSettings sharedManager].wikiDataSourceType get];
    _backgroundQueue = dispatch_queue_create("com.osmand.topplaces.background", DISPATCH_QUEUE_SERIAL);
    [self storeWikipediaResources:[OAResourcesUISwiftHelper findWikiMapRegionsAtCurrentMapLocation]];
    [self updateDisabledState];
}

- (void)setMapLayerData:(OAPOIMapLayerData *)mapLayerData
{
    _mapLayerData = mapLayerData;
    [self updateDisabledState];
}

- (NSDictionary<NSNumber *, OAPOI *> *)topPlaces
{
    return _topPlaces ? [_topPlaces copy] : nil;
}

- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc
{
    dispatch_async(_backgroundQueue, ^{
        [self updatePopularPlacesForce:forceRecalc];
    });
}

- (void)updateLayer
{
    dispatch_async(_backgroundQueue, ^{
        if ([self dataChanged])
        {
            [self resetTopPlacesState];
        }

        if (_isDisabled)
        {
            [self resetTopPlacesState];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<OAResourceSwiftItem *> *items = [OAResourcesUISwiftHelper findWikiMapRegionsAtCurrentMapLocation];
            if ([self hasWikipediaResourcesChanged:items])
            {
                [self storeWikipediaResources:items];
                dispatch_async(_backgroundQueue, ^{
                    [self resetTopPlacesState];
                    [self updatePopularPlacesForce:YES];
                });
                return;
            }

            CGFloat textScale = [self textScale];
            if (_textScale != textScale)
            {
                _textScale = textScale;
                dispatch_async(_backgroundQueue, ^{
                    _topPlacesBox = nil;
                    [self updateTopPlacesCollection];
                });
            }

            dispatch_async(_backgroundQueue, ^{
                [self updatePopularPlacesForce:NO];
            });
        });
    });
}

- (void)resetLayer
{
    dispatch_async(_backgroundQueue, ^{
        [self resetTopPlacesState];
    });
}

- (NSArray<OAPOI *> *)displayedAmenities
{
    return _visiblePlaces ? [_visiblePlaces copy] : @[];
}

- (void)contextMenuDidShow:(id)targetObj
{
    OAPOI *amenity = [self topPlaceAmenityFor:targetObj];
    [self updateSelectedTopPlaceIfNeeded:amenity];
}

- (void)resetSelectedTopPlaceIfNeeded
{
    dispatch_async(_backgroundQueue, ^{
        if (_selectedTopPlace)
        {
            _selectedTopPlace = nil;
            _selectedTopPlaceImage = nil;
            [self updateTopPlacesCollection];
        }
    });
}

- (void)updateSelectedTopPlaceIfNeeded:(OAPOI *)topPlace
{
    dispatch_async(_backgroundQueue, ^{
        OAPOI *selectedTopPlace = topPlace;
        if ((!selectedTopPlace && !_selectedTopPlace)
            || (selectedTopPlace && _selectedTopPlace && [_selectedTopPlace getSignedId] == [selectedTopPlace getSignedId]))
        {
            return;
        }

        if (selectedTopPlace)
        {
            NSNumber *topPlaceId = @([selectedTopPlace getSignedId]);
            if (!_topPlaces[topPlaceId])
                selectedTopPlace = nil;
        }

        _selectedTopPlace = selectedTopPlace;
        _selectedTopPlaceImage = nil;
        [self updateTopPlacesCollection];
    });
}

- (OAPOI *)topPlaceAmenityFor:(id)object
{
    if ([object isKindOfClass:SelectedMapObject.class])
        object = ((SelectedMapObject *) object).object;

    if ([object isKindOfClass:OAPOI.class])
        return (OAPOI *) object;

    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *details = (BaseDetailsObject *) object;
        OAPOI *syntheticAmenity = details.syntheticAmenity;
        if (_topPlaces[@(syntheticAmenity.getSignedId)])
            return syntheticAmenity;

        for (id item in details.objects)
        {
            if ([item isKindOfClass:OAPOI.class])
            {
                OAPOI *poi = (OAPOI *) item;
                if (_topPlaces[@(poi.getSignedId)])
                    return poi;
            }
        }
    }

    return nil;
}

- (void)updateDisabledState
{
    _showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    _isDisabled = _mapLayerData == nil || !_showTopPlacesPreviews || _calculatedFilters.count == 0;
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

    EOAWikiDataSourceType wikiType = [[OAAppSettings sharedManager].wikiDataSourceType get];
    if (_wikiDataSourceType != wikiType)
    {
        _wikiDataSourceType = wikiType;
        return YES;
    }

    BOOL showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    if (_showTopPlacesPreviews != showTopPlacesPreviews)
    {
        _showTopPlacesPreviews = showTopPlacesPreviews;
        [self updateDisabledState];
        return YES;
    }

    return NO;
}

- (void)resetTopPlacesState
{
    [self cancelLoadingImages];
    [self clearMapMarkersCollections];
    _topPlacesBox = nil;
    _selectedTopPlace = nil;
    _selectedTopPlaceImage = nil;
}

- (void)updatePopularPlacesForce:(BOOL)force
{
    if (_isDisabled || !_mapLayerData)
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

    [self updateVisiblePlaces:_mapLayerData.displayedResults latLonBounds:screenRect];

    _topPlacesFilter = _mapLayerData.topPlacesFilter;
    if (!_topPlacesFilter)
    {
        [self cancelLoadingImages];
        [self clearMapMarkersCollections];
        _topPlacesBox = nil;
        return;
    }

    if (!force && _topPlacesBox && [_topPlacesBox contains:screenRect])
        return;

    NSArray<OAPOIMapLayerItem *> *allItems = _mapLayerData.results;
    if (allItems.count == 0)
    {
        [self cancelLoadingImages];
        [self clearMapMarkersCollections];
        _topPlacesBox = nil;
        return;
    }

    QuadRect *extendedBox = [[QuadRect alloc] initWithRect:screenRect];
    [extendedBox inset:-(screenRect.width * 0.1) dy:-(screenRect.height * 0.1)];
    _topPlacesBox = extendedBox;

    [self updateTopPlaces:allItems latLonBounds:screenRect zoom:(int) _mapView.zoom];
}

- (void)updateVisiblePlaces:(NSArray<OAPOIMapLayerItem *> *)places
               latLonBounds:(QuadRect *)latLonBounds
{
    if (!places)
    {
        _visiblePlaces = nil;
        return;
    }

    NSMutableArray<OAPOI *> *res = [NSMutableArray arrayWithCapacity:places.count];
    for (OAPOIMapLayerItem *item in places)
    {
        CLLocationCoordinate2D coordinate = item.coordinate;
        if (!CLLocationCoordinate2DIsValid(coordinate))
            continue;

        double lon = coordinate.longitude;
        double lat = coordinate.latitude;
        if ([latLonBounds contains:lon top:lat right:lon bottom:lat])
        {
            OAPOI *place = [_mapLayerData poiForItem:item];
            if (place)
                [res addObject:place];
        }
    }
    _visiblePlaces = res;
}

- (nullable UIImage *)topPlaceImage:(OAPOI *)place
{
    UIImage *image = _topPlacesImages[@([place getSignedId])];
    if (!image)
        return nil;

    if (_selectedTopPlace && [_selectedTopPlace getSignedId] == [place getSignedId])
    {
        if (!_selectedTopPlaceImage)
            _selectedTopPlaceImage = [POITopPlaceImageDecorator selectedImageFor:image];
        return _selectedTopPlaceImage;
    }

    return image;
}

- (void)updateTopPlaces:(NSArray<OAPOIMapLayerItem *> *)places
           latLonBounds:(QuadRect *)latLonBounds
                   zoom:(int)zoom
{
    NSMutableArray<OAPOIMapLayerItem *> *orderedItems = [NSMutableArray array];
    NSDictionary<NSNumber *, OAPOI *> *selected = [self obtainTopPlacesToDisplay:places
                                                                     latLonBounds:latLonBounds
                                                                             zoom:zoom
                                                                     orderedItems:orderedItems];
    _topPlaces = [selected mutableCopy];
    _orderedTopPlaces = [NSMutableArray arrayWithCapacity:orderedItems.count];
    for (OAPOIMapLayerItem *item in orderedItems)
    {
        NSNumber *placeId = @([item signedId]);
        OAPOI *place = selected[placeId];
        if (!place)
            continue;
        [_orderedTopPlaces addObject:place];
    }

    NSMutableDictionary<NSNumber *, UIImage *> *existingImages = [NSMutableDictionary dictionary];
    for (NSNumber *placeId in _topPlacesImages.allKeys)
    {
        UIImage *image = _topPlacesImages[placeId];
        if (selected[placeId] && image)
            existingImages[placeId] = image;
    }
    _topPlacesImages = existingImages;

    if (_orderedTopPlaces.count == 0)
    {
        [self cancelLoadingImages];
        [self clearMapMarkersCollections];
        return;
    }

    if (!_imageLoader)
        _imageLoader = [POIImageLoader new];

    __weak __typeof(self) weakSelf = self;
    [_imageLoader fetchImages:_orderedTopPlaces completion:^(NSNumber *placeId, UIImage *image) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        dispatch_async(strongSelf->_backgroundQueue, ^{
            if (!strongSelf->_topPlaces[placeId])
                return;

            strongSelf->_topPlacesImages[placeId] = image;
            [strongSelf updateTopPlacesCollection];
        });
    }];

    [self updateTopPlacesCollection];
}

- (NSDictionary<NSNumber *, OAPOI *> *)obtainTopPlacesToDisplay:(NSArray<OAPOIMapLayerItem *> *)places
                                                   latLonBounds:(QuadRect *)latLonBounds
                                                           zoom:(int)zoom
                                                   orderedItems:(NSMutableArray<OAPOIMapLayerItem *> *)orderedItems
{
    NSMutableDictionary<NSNumber *, OAPOI *> *res = [NSMutableDictionary dictionary];

    long long tileSize31 = (1LL << (31 - zoom));
    double from31toPixelsScale = 256.0 / (double) tileSize31;
    double estimatedIconSize = kImageIconSizeDP * _textScale;
    float iconSize31 = (float) (estimatedIconSize / from31toPixelsScale);

    int left = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.left];
    int top = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.top];
    int right = [OASKMapUtils.shared get31TileNumberXLongitude:latLonBounds.right];
    int bottom = [OASKMapUtils.shared get31TileNumberYLatitude:latLonBounds.bottom];
    QuadTree *boundIntersections = [self.class initBoundIntersections:left top:top right:right bottom:bottom];

    NSInteger counter = 0;
    for (OAPOIMapLayerItem *item in places)
    {
        if (counter >= kTopPlacesLimit)
            break;

        if (item.wikiIconUrl.length == 0)
            continue;

        CLLocationCoordinate2D coordinate = item.coordinate;
        if (!CLLocationCoordinate2DIsValid(coordinate))
            continue;

        double lon = coordinate.longitude;
        double lat = coordinate.latitude;
        if (![latLonBounds contains:lon top:lat right:lon bottom:lat])
            continue;

        int x31 = [OASKMapUtils.shared get31TileNumberXLongitude:lon];
        int y31 = [OASKMapUtils.shared get31TileNumberYLatitude:lat];
        if ([self.class intersectsD:boundIntersections x:x31 y:y31 width:iconSize31 height:iconSize31])
            continue;

        OAPOI *place = [_mapLayerData poiForItem:item];
        if (!place)
            continue;

        NSNumber *placeId = @([place getSignedId]);
        res[placeId] = place;
        [orderedItems addObject:item];
        counter++;
    }

    return res;
}

- (void)updateTopPlacesCollection
{
    [_mapViewController runWithRenderSync:^{
        [self clearMapMarkersCollectionsLocked];

        if (_orderedTopPlaces.count == 0)
            return;

        _mapMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
        NSInteger count = 0;
        for (OAPOI *place in _orderedTopPlaces)
        {
            UIImage *image = [self topPlaceImage:place];
            if (!image)
                continue;

            NSData *data = UIImagePNGRepresentation(image);
            if (!data)
                continue;

            CLLocationCoordinate2D coordinate = place.getLocation.coordinate;
            OsmAnd::MapMarkerBuilder builder;
            builder.setIsAccuracyCircleSupported(false)
                .setMarkerId([self truncatedTopPlaceId:place])
                .setBaseOrder(_topPlaceBaseOrder)
                .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
                .setPosition([OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(coordinate.latitude, coordinate.longitude)])
                .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
                .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
            std::shared_ptr<OsmAnd::MapMarker> marker = builder.buildAndAddToCollection(_mapMarkersCollection);
            marker->setUpdateAfterCreated(true);

            count++;
            if (count >= kTopPlacesLimit)
                break;
        }

        if (_mapMarkersCollection && _mapMarkersCollection->getMarkers().size() > 0)
            _mapView.renderer->addSymbolsProvider(kFavoritesSymbolSection, _mapMarkersCollection);
    }];
}

- (int32_t)truncatedTopPlaceId:(OAPOI *)topPlace
{
    uint64_t obfId = topPlace.obfId;
    long long fullId = obfId != 0 ? (long long) obfId : (long long) [topPlace getTravelEloNumber];
    return (int32_t) (fullId ^ (fullId >> 32));
}

- (void)cancelLoadingImages
{
    [_imageLoader cancelAll];
    _imageLoader = nil;
    _topPlaces = nil;
    _orderedTopPlaces = nil;
    _topPlacesImages = nil;
    _visiblePlaces = nil;
}

- (void)clearMapMarkersCollections
{
    [_mapViewController runWithRenderSync:^{
        [self clearMapMarkersCollectionsLocked];
    }];
}

- (void)clearMapMarkersCollectionsLocked
{
    if (_mapMarkersCollection != nullptr)
    {
        [_mapView removeKeyedSymbolsProvider:_mapMarkersCollection];
        _mapMarkersCollection.reset();
    }
}

+ (QuadTree *)initBoundIntersections:(double)left
                                 top:(double)top
                               right:(double)right
                              bottom:(double)bottom
{
    QuadRect *bounds = [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
    [bounds inset:-bounds.width / 4.0 dy:-bounds.height / 4.0];
    return [[QuadTree alloc] initWithQuadRect:bounds depth:4 ratio:0.6f];
}

+ (BOOL)intersectsD:(QuadTree *)boundIntersections
                  x:(double)x
                  y:(double)y
              width:(double)width
             height:(double)height
{
    QuadRect *visibleRect = [self calculateRectDWithX:x y:y width:width height:height];
    NSMutableArray<QuadRect *> *result = [NSMutableArray array];
    QuadRect *rectCopy = [[QuadRect alloc] initWithRect:visibleRect];
    [boundIntersections queryInBox:rectCopy result:result];
    for (QuadRect *rect in result)
    {
        if ([QuadRect intersects:rect b:visibleRect])
            return YES;
    }

    [boundIntersections insert:rectCopy box:[[QuadRect alloc] initWithRect:visibleRect]];
    return NO;
}

+ (QuadRect *)calculateRectDWithX:(double)x
                                y:(double)y
                            width:(double)width
                           height:(double)height
{
    double left = x - width / 2.0;
    double top = y - height / 2.0;
    return [[QuadRect alloc] initWithLeft:left top:top right:left + width bottom:top + height];
}

- (CGFloat)textScale
{
    return [[OAAppSettings sharedManager].textSize get] * [OARootViewController.instance.mapPanel.mapViewController displayDensityFactor];
}

- (void)storeWikipediaResources:(NSArray<OAResourceSwiftItem *> *)items
{
    _storedWikipediaResourceIds = [NSSet setWithArray:[items valueForKey:@"resourceId"]];
}

- (BOOL)hasWikipediaResourcesChanged:(NSArray<OAResourceSwiftItem *> *)items
{
    return ![_storedWikipediaResourceIds isEqualToSet:[NSSet setWithArray:[items valueForKey:@"resourceId"]]];
}

@end
