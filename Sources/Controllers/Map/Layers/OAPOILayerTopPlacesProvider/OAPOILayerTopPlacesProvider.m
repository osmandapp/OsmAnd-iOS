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
    OsmAnd::AreaI _topPlacesBox;
    QuadRect *_lastCalcBounds;
    float _lastCalcZoom;
    
    POIImageLoader *_imageLoader;
    dispatch_queue_t _backgroundQueue;
    OAMapRendererView *_mapView;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _mapMarkersCollection;
    
    int _topPlaceBaseOrder;
    OAMapViewController *_mapViewController;
    CGFloat _textScale;
    CGFloat _displayDensityFactor;
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
    _displayDensityFactor = _mapViewController.mapView.displayDensityFactor;
    _backgroundQueue = dispatch_queue_create("com.osmand.topplaces.background", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_backgroundQueue, kTopPlacesStateQueueKey, kTopPlacesStateQueueKey, NULL);
}

// MARK: - Public

- (void)drawTopPlacesIfNeeded:(BOOL)forceRecalc
{
    if (!_enabled)
        return;

    dispatch_async(_backgroundQueue, ^{
        if (!_enabled)
            return;

        [self refreshVisiblePlacesOnStateQueue];
    });
}

- (void)notifyAmenitiesChanged:(const QList<std::shared_ptr<const OsmAnd::Amenity>> &)amenities
{
    const QList<std::shared_ptr<const OsmAnd::Amenity>> amenitiesCopy = amenities;
    dispatch_async(_backgroundQueue, ^{
        self->_amenitiesGeneration++;
        self->_allPlaces = amenitiesCopy;
        [self sortByElo:&self->_allPlaces];
        self->_topPlacesBox = OsmAnd::AreaI();
        [self refreshVisiblePlacesOnStateQueue];
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
        CGFloat displayDensityFactor = _mapViewController.mapView.displayDensityFactor;
        if (fabs(_textScale - textScale) < 0.0001f && fabs(_displayDensityFactor - displayDensityFactor) < 0.0001f)
            return;

        _textScale = textScale;
        _displayDensityFactor = displayDensityFactor;
        if (_enabled)
        {
            _topPlacesBox = OsmAnd::AreaI();
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

- (BOOL)captureVisibleBounds:(OsmAnd::AreaI *)visibleBBox31
                        zoom:(float *)zoom
{
    __block OsmAnd::AreaI bounds;
    __block BOOL hasBounds = NO;
    __block float currentZoom = 0.f;

    [_mapViewController runWithRenderSync:^{
        const auto screenBbox = _mapView.getVisibleBBox31;
        if (screenBbox.width() <= 0 || screenBbox.height() <= 0)
            return;

        bounds = screenBbox;
        hasBounds = YES;
        currentZoom = [_mapView zoom];
    }];

    if (!hasBounds)
        return NO;

    if (visibleBBox31)
        *visibleBBox31 = bounds;
    if (zoom)
        *zoom = currentZoom;
    return YES;
}

- (float)getTopPlaceIconSize31:(int)zoom
{
    long long tileSize31 = (1LL << (31 - zoom));
    double from31toPixelsScale = 256.0 / (double)tileSize31;
    double estimatedIconSize = kImageIconSizeDP * _textScale * _displayDensityFactor;
    return (float)(estimatedIconSize / from31toPixelsScale);
}

- (OsmAnd::AreaI)topPlacesBoxForVisibleBounds:(const OsmAnd::AreaI&)visibleBBox31 zoom:(int)zoom
{
    if (visibleBBox31.width() <= 0 || visibleBBox31.height() <= 0)
        return OsmAnd::AreaI();

    float iconSize31 = [self getTopPlaceIconSize31:zoom];
    return visibleBBox31.getEnlargedBy(iconSize31, iconSize31, iconSize31, iconSize31);
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

    if ([wikiPhoto hasPrefix:@"http://"] || [wikiPhoto hasPrefix:@"https://"])
        return wikiPhoto;

    OASWikiImage *wikiImage = [[OASWikiHelper shared] getImageDataImageFileName:wikiPhoto];
    if (wikiImage.imageIconUrl.length > 0)
        return wikiImage.imageIconUrl;

    return nil;
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
                                   placeholderImageName:[self placeholderIconNameForAmenity:amenity]
                                              textScale:_textScale];
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

    _amenitiesGeneration++;
    _imagesGeneration++;
    _allPlaces.clear();
    _displayedPlaces.clear();
    _topPlaces.clear();
    _topPlaceIds = nil;
    _loadingImagePlaceIds = nil;
    _topPlacesBox = OsmAnd::AreaI();
    _lastCalcBounds = nil;
    _lastCalcZoom = 0.f;
    _selectedTopPlaceId = nil;
    _renderedMarkerStates = nil;
}

- (void)refreshVisiblePlacesOnStateQueue
{
    if (!_enabled)
        return;

    OsmAnd::AreaI visibleBBox31;
    float zoom = 0.f;
    if (![self captureVisibleBounds:&visibleBBox31 zoom:&zoom])
        return;

    if (_allPlaces.isEmpty())
    {
        _displayedPlaces.clear();
        _topPlacesBox = OsmAnd::AreaI();
        [self clearMapMarkersCollections];
        [self cancelLoadingImages];
        return;
    }

    if (_topPlacesBox.width() > 0
        && _topPlacesBox.height() > 0
        && _topPlacesBox.contains(visibleBBox31))
        return;

    _topPlacesBox = [self topPlacesBoxForVisibleBounds:visibleBBox31 zoom:(int)zoom];
    [self updateTopPlaces:_allPlaces visibleBBox31:visibleBBox31 zoom:(int)zoom];
}

- (void)updateTopPlaceImageForId:(NSNumber *)placeId
                           image:(UIImage *)image
{
    dispatch_async(_backgroundQueue, ^{
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
            [self performStateSync:^{
                _displayedPlaces.clear();
            }];
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
        QList<std::shared_ptr<const OsmAnd::Amenity>> actualDisplayedPlaces;

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
                    actualDisplayedPlaces.push_back(place);
                }
                else
                {
                    [_renderedMarkerStates removeObjectForKey:markerKey];
                    [desiredMarkerStates removeObjectForKey:markerKey];
                }
            }
            else
            {
                actualDisplayedPlaces.push_back(place);
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

        [self performStateSync:^{
            _displayedPlaces = actualDisplayedPlaces;
        }];
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
          visibleBBox31:(const OsmAnd::AreaI&)visibleBBox31
                   zoom:(int)zoom
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> newTopPlaces = [self obtainTopPlacesToDisplay:places
                                                                                  visibleBBox31:visibleBBox31
                                                                                           zoom:zoom];
    NSSet<NSNumber *> *previousTopPlaceIds = _topPlaceIds ?: [NSSet set];
    NSMutableSet<NSNumber *> *newTopPlaceIds = [NSMutableSet setWithCapacity:newTopPlaces.size()];
    for (const auto& place : newTopPlaces)
        [newTopPlaceIds addObject:[self placeIdForAmenity:place]];
    BOOL topPlacesChanged = ![previousTopPlaceIds isEqualToSet:newTopPlaceIds];
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

            __weak __typeof(self) weakSelf = self;
            [_imageLoader fetchImages:[missingImagePlaces copy] completion:^(NSNumber *placeId, UIImage *image) {
                [weakSelf updateTopPlaceImageForId:placeId image:image];
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
                                                            visibleBBox31:(const OsmAnd::AreaI&)visibleBBox31
                                                                     zoom:(int)zoom
{
    QList<std::shared_ptr<const OsmAnd::Amenity>> res;
    if (visibleBBox31.width() <= 0 || visibleBBox31.height() <= 0)
        return res;
    
    float iconSize31 = [self getTopPlaceIconSize31:zoom];
    QuadTree *boundIntersections = [[self class] initBoundIntersections:visibleBBox31.left()
                                                                    top:visibleBBox31.top()
                                                                  right:visibleBBox31.right()
                                                                 bottom:visibleBBox31.bottom()];
    int counter = 0;
    for (const auto& place : places)
    {
        if (!visibleBBox31.contains(place->position31)
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
