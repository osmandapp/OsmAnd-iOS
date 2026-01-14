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
#import "OsmAnd_Maps-Swift.h"

#include "OACoreResourcesAmenityIconProvider.h"
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionReader.h>
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

#define kPoiSearchRadius 50 // AMENITY_SEARCH_RADIUS
#define kPoiSearchRadiusForRelation 500 // AMENITY_SEARCH_RADIUS_FOR_RELATION
#define kTrackSearchDelta 40

static const NSInteger kTopPlacesLimit = 20;
static const NSInteger kTilePointsLimit = 25;
static const NSInteger kStartZoom = 5;
static const NSInteger kStartZoomRouteTrack = 11;
static const NSInteger kEndZoomRouteTrack = 22;
static const NSInteger kImageIconSizeDP = 45;
static const NSInteger kImageIconBorderDP = 2;


const QString TAG_POI_LAT_LON = QStringLiteral("osmand_poi_lat_lon");

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
    /// Popular places [start]
    NSMutableDictionary<NSNumber *, OAPOI *> *_topPlaces;
    NSMutableDictionary<NSNumber *, UIImage *> *_topPlacesImages;
    NSDictionary<NSString *, NSArray<OAPOI *> *> *_topPlaceData;
    NSMutableArray<OAPOI *> *_visiblePlaces;
    DataSourceType _wikiDataSource;
    BOOL _showTopPlacesPreviews;
    OAPOIUIFilter *_topPlacesFilter;
    NSSet<OAPOIUIFilter *> *_calculatedFilters;
    QuadRect *_topPlacesBox;
    
    POIImageLoader *_imageLoader;
    
    /// Popular places [end]
    
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _wikiSymbolsProvider;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _mapMarkersCollection;
}

/// Popular places [start]
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

// updatePopularPlaces -> Android: public void onPrepareBufferImage(Canvas canvas, RotatedTileBox tileBox, DrawSettings settings) {
- (void)updatePopularPlaces
{
    BOOL showTopPlacesPreviews = [[OAAppSettings sharedManager].wikiShowImagePreviews get];
    BOOL showTopPlacesPreviewsChanged = _showTopPlacesPreviews != showTopPlacesPreviews;
    _showTopPlacesPreviews = showTopPlacesPreviews;
    
    if (showTopPlacesPreviewsChanged/* || topPlacesBox == null || !topPlacesBox.containsTileBox(tileBox)*/)
    {
        // FIXME:
        [self calcResultTest];
        
        const auto screenBbox = self.mapView.getVisibleBBox31;
        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
        QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
        
        NSArray<OAPOI *> *allPlaces = _topPlaceData[@"all"];
        [self updateVisiblePlaces:_topPlaceData[@"displayed"] latLonBounds:screenRect];
        
//        BOOL intersects = [QuadRect intersects:_topPlacesBox b:screenRect];
//        if (!intersects) {
//        }
        
        BOOL notContains = (_topPlacesBox == nil) || ![_topPlacesBox contains:screenRect];
        if (notContains) {
            // аналог !topPlacesBox.containsTileBox(tileBox)
        }

        if (showTopPlacesPreviews)
        {
            // TODO: copy
            QuadRect *extendedBox = screenRect;
            int bigIconSize = kImageIconSizeDP * [self textScale];
//                            extendedBox.increasePixelDimensions(bigIconSize * 2, bigIconSize * 2);
            _topPlacesBox = extendedBox;
            [self updateTopPlaces:allPlaces latLonBounds:screenRect zoom:[self.mapView zoom]];
            [self updateTopPlacesCollection];
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

- (void)calcResultTest
{
    _calculatedFilters = [_filtersHelper getSelectedPoiFilters];
    
    const auto screenBbox = self.mapView.getVisibleBBox31;
    const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(screenBbox.topLeft);
    const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(screenBbox.bottomRight);
    QuadRect *screenRect = [[QuadRect alloc] initWithLeft:topLeft.longitude top:topLeft.latitude right:bottomRight.longitude bottom:bottomRight.latitude];
    [screenRect inset:-(screenRect.width / 2.0) dy:-(screenRect.height / 2.0)];
    
    _topPlaceData = [self calculateResult:screenRect zoom:[self.mapView zoom]];
    
    NSLog(@"calcResultTest");
}

- (void)onMapFrameAnimatorsUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePopularPlaces];
    });
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
            [self updateTopPlacesCollection];
        }
    }
}

- (void)updateTopPlacesCollection
{
    NSArray<OAPOI *> *places = _topPlaces ? [_topPlaces allValues] : nil;
    if (!places)
    {
        [self clearMapMarkersCollections];
        return;
    }

    if (!_mapMarkersCollection)
        _mapMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    QList<std::shared_ptr<OsmAnd::MapMarker>> existingMapPoints = _mapMarkersCollection->getMarkers();

    NSMutableArray<NSNumber *> *existingIds = [NSMutableArray arrayWithCapacity:existingMapPoints.size()];

    for (int i = 0; i < existingMapPoints.size(); ++i)
    {
        std::shared_ptr<OsmAnd::MapMarker> marker = existingMapPoints[i];
        [existingIds addObject:@(marker->markerId)];
    }
    
    NSMutableArray<OAMapTopPlace *> *mapPlaces = [NSMutableArray array];

    for (OAPOI *place in places)
    {
        NSInteger placeId = place.obfId ? place.obfId : place.getTravelEloNumber;
        
        OsmAnd::PointI position = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(place.getLocation.coordinate.latitude, place.getLocation.coordinate.longitude)];


        BOOL alreadyExists = NO;
        for (NSInteger i = 0; i < existingIds.count; i++)
        {
            if (placeId == existingIds[i].integerValue)
            {
                existingIds[i] = @0;
                alreadyExists = YES;
                break;
            }
        }

        UIImage *topPlaceImage = [self topPlaceImage:place];
        if (topPlaceImage)
        {
            OAMapTopPlace *mapTopPlace = [[OAMapTopPlace alloc] initWithPlaceId:placeId
                                                                       position:position
                                                                          image:topPlaceImage
                                                                  alreadyExists:alreadyExists];
            [mapPlaces addObject:mapTopPlace];
        }

        if (mapPlaces.count >= kTopPlacesLimit) {
            break;
        }
    }

    for (int i = 0; i < existingIds.count; i++)
    {
        if (existingIds[i].intValue != 0)
            _mapMarkersCollection->removeMarker(existingMapPoints[i]);
    }

    for (OAMapTopPlace *place in mapPlaces)
    {
        if (place.alreadyExists)
            continue;
        
        NSData *data = UIImagePNGRepresentation(place.image);
        if (data) {
            OsmAnd::MapMarkerBuilder builder;
            builder.setIsAccuracyCircleSupported(false)
                .setMarkerId((int)place.placeId)
                .setBaseOrder([self topPlaceBaseOrder])
                .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromNSData:data]))
                .setPosition(place.position)
                .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
                .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
                .buildAndAddToCollection(_mapMarkersCollection);
        } else {
            NSLog(@"UIImageJPEGRepresentation is nil");
        }
    }
    // TOP_PLACES_POI_SECTION
    self.mapView.renderer->addSymbolsProvider(kFavoritesSymbolSection, _mapMarkersCollection);
}

- (int)topPlaceBaseOrder
{
    return self.pointsOrder - 100;;
}


- (void)clearMapMarkersCollections
{
    if (_mapMarkersCollection != nil)
    {
        [self.mapView removeKeyedSymbolsProvider:_mapMarkersCollection];
        _mapMarkersCollection = nil;
    }
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
                NSLog(@"Loaded image for placeId %@", placeId);
                [weakSelf updateTopPlaceImageForId:placeId image:image];
            }];
           // [self fetchImages:[NSSet setWithArray:topPlacesList]];
            
            /*
             {(
                 "https://data.osmand.net/wikimedia/images-1280/6/67/\U0418\U043d\U0441\U0442\U0438\U0442\U0443\U0442_\U0447\U0435\U0440\U043d\U043e\U0439_\U043c\U0435\U0442\U0430\U043b\U043b\U0443\U0440\U0433\U0438\U0438_\U041d\U0410\U041d_\U0423\U043a\U0440\U0430\U0438\U043d\U044b.jpg?width=160",
                 "https://data.osmand.net/wikimedia/images-1280/a/ab/DNU_library.JPG?width=160",
                 "https://data.osmand.net/wikimedia/images-1280/0/05/\U0411\U043e\U0442\U0430\U043d\U0456\U0447\U043d\U0438\U0439_\U0441\U0430\U0434_\U0414\U041d\U0423_17.JPG?width=160",
                 "https://data.osmand.net/wikimedia/images-1280/1/1b/Gagarina_Prospekt10_(Dnepropetrovsk).jpg?width=160"
             )}

             */
            
            NSMutableSet<NSString *> *imagesToLoad = [NSMutableSet set];

            for (OAPOI *place in places) {
                NSString *iconUrl = place.wikiIconUrl; // лениво загрузится, если нужно
                if (iconUrl != nil && iconUrl.length > 0) {
                    [imagesToLoad addObject:iconUrl];
                }
            }
            NSLog(@"%@", imagesToLoad);
        } else {
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
{
//    if (customObjectsDelegate != nil)
//    {
//        NSArray<Amenity *> *mapObjects = [customObjectsDelegate getMapObjects];
//        return @{ @"all": mapObjects, @"displayed": mapObjects };
//    }

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
                                                              matcher:nil] mutableCopy];
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

/// Popular places [end]

- (void)initLayer
{
    [super initLayer];

    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
}

- (NSString *) layerId
{
    return kPoiLayerId;
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
        [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
        _wikiSymbolsProvider.reset();
        _showWikiOnMap = NO;
    }
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
            [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
            _wikiSymbolsProvider.reset();
        }];
        _showWikiOnMap = NO;
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
    });
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    [self updateVisiblePoiFilter];
//    [self calcResultTest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePopularPlaces];
    });
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

    OAPOIUIFilter *poiFilter = _poiUiFilter;
    OAPOIUIFilter *wikiFilter = _wikiUiFilter;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowPoiUiFilterOnMapWithPoiFilter:poiFilter wikiFilter:wikiFilter];
    });
}

- (void) doShowPoiUiFilterOnMapWithPoiFilter:(OAPOIUIFilter *)poiFilter wikiFilter:(OAPOIUIFilter *)wikiFilter
{
    if (!poiFilter && !wikiFilter)
        return;

    [self.mapViewController runWithRenderSync:^{

        OAAmenityExtendedNameFilter *poiNameFilter = [poiFilter getNameAmenityFilter:poiFilter.filterByName];
        OAAmenityExtendedNameFilter *wikiNameFilter = [wikiFilter getNameAmenityFilter:wikiFilter.filterByName];

        void (^_generate)(OAPOIUIFilter *, OAAmenityExtendedNameFilter *) = ^(OAPOIUIFilter *f, OAAmenityExtendedNameFilter *nameFilter) {
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

            OsmAnd::ObfPoiSectionReader::VisitorFunction amenityFilter =
                    [=](const std::shared_ptr<const OsmAnd::Amenity> &amenity)
                    {
                        OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
                        QHash<QString, QString> decodedValues = amenity->getDecodedValuesHash();
                        
                        BOOL check = !wikiNameFilter && !wikiFilter && poiNameFilter
                                && poiFilter && poiFilter.filterByName && poiFilter.filterByName.length > 0;
                        BOOL accepted = poiNameFilter && [poiNameFilter acceptAmenity:amenity values:decodedValues type:type];

                        if (!isWiki && [type.tag isEqualToString:OSM_WIKI_CATEGORY])
                            return check ? accepted : false;
                        
                        if ((check && accepted) || (isWiki ? wikiNameFilter && [wikiNameFilter acceptAmenity:amenity values:decodedValues type:type] : accepted))
                        {
                            BOOL isClosed = decodedValues[QString::fromNSString(OSM_DELETE_TAG)] == QString::fromNSString(OSM_DELETE_VALUE);
                            return !isClosed;
                        }

                        return false;
                    };

            if (isWiki && _wikiSymbolsProvider)
                [self.mapView removeTiledSymbolsProvider:_wikiSymbolsProvider];
            else if (!isWiki && _amenitySymbolsProvider)
                [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];

            OAAppSettings *settings = OAAppSettings.sharedManager;
            BOOL nightMode = settings.nightMode;
            BOOL showLabels = settings.mapSettingShowPoiLabel.get;
            NSString *lang = settings.settingPrefMapLanguage.get;
            BOOL transliterate = settings.settingMapLanguageTranslit.get;
            float textSize = settings.textSize.get;

            const auto displayDensityFactor = self.mapViewController.displayDensityFactor;
            const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;

            auto iconProvider = std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), displayDensityFactor, 1.0, textSize, nightMode, showLabels, QString::fromNSString(lang), transliterate);

            if (categoriesFilter.count() > 0)
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, &categoriesFilter, amenityFilter, iconProvider, self.pointsOrder));
            }
            else
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, nullptr, amenityFilter, iconProvider, self.pointsOrder));
            }

            [self.mapView addTiledSymbolsProvider:kPOISymbolSection provider:isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider];
        };

        _poiUiNameFilter = poiNameFilter;
        _wikiUiNameFilter = wikiNameFilter;

        if (poiFilter)
            _generate(poiFilter, poiNameFilter);

        if (wikiFilter)
            _generate(wikiFilter, wikiNameFilter);
    }];
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
        targetPoint.type = OATargetLocation;
        targetPoint.location = CLLocationCoordinate2DMake(renderedObject.labelLatLon.coordinate.latitude, renderedObject.labelLatLon.coordinate.longitude);
        targetPoint.values = renderedObject.tags;
        targetPoint.obfId = renderedObject.obfId;
        targetPoint.targetObj = renderedObject;
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        
        if (!poi)
            poi = [RenderedObjectHelper getSyntheticAmenityWithRenderedObject:renderedObject];
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

- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    NSArray<OAPOI *> *amenities = [self getDisplayedResults:result.pointLatLon.coordinate.latitude lon:result.pointLatLon.coordinate.longitude];
    for (OAPOI *amenity in amenities)
    {
        [result collect:amenity provider:self];
    }
}

- (NSArray<OAPOI *> *)getDisplayedResults:(double)lat lon:(double)lon
{
    NSMutableArray<OAPOI *> *result = [NSMutableArray new];
    if (!_amenitySymbolsProvider)
        return result;
    
    const auto point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    OsmAnd::AreaI area31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(kPoiSearchRadius, point31);
    const auto tileId = OsmAnd::Utilities::getTileId(point31, self.mapView.zoomLevel);
    
    OsmAnd::IMapTiledSymbolsProvider::Request request;
    request.tileId = tileId;
    request.zoom = self.mapView.zoomLevel;
    const auto& mapState = [self.mapView getMapState];
    request.mapState = mapState;
    request.visibleArea31 = area31;
    
    std::shared_ptr<OsmAnd::IMapDataProvider::Data> data;
    _amenitySymbolsProvider->obtainData(request, data, nullptr);
    
    std::shared_ptr<OsmAnd::IMapTiledSymbolsProvider::Data> tiledData =
        std::static_pointer_cast<OsmAnd::IMapTiledSymbolsProvider::Data>(data);
    if (tiledData && !tiledData->symbolsGroups.isEmpty())
    {
        for (const auto group : tiledData->symbolsGroups)
        {
            if (!group->symbols.isEmpty())
            {
                for (const auto symbol : group->symbols)
                {
                    if (const auto amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbol->groupPtr))
                    {
                        if (const auto cppAmenity = amenitySymbolGroup->amenity)
                        {
                            if (area31.contains(cppAmenity->position31))
                            {
                                OAPOI *poi = [OAAmenitySearcher parsePOIByAmenity:cppAmenity];
                                if (poi)
                                    [result addObject:poi];
                            }
                        }
                    }
                }
            }
        }
    }
    return [result copy];
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    if ([self isTopPlace:selectedObject])
        return [self getTopPlaceBaseOrder];
    else
        return 0;
}

- (BOOL) isTopPlace:(id)object
{
    if (_topPlaces)
    {
        int64_t placeId = -1;
        if ([object isKindOfClass:OAPOI.class])
            placeId = ((OAPOI *)object).obfId;
        else if ([object isKindOfClass:BaseDetailsObject.class])
            placeId = ((BaseDetailsObject *)object).syntheticAmenity.obfId;
        
        return placeId != -1 && _topPlaces[@(placeId)];
    }
    
    return NO;
}

- (int64_t) getTopPlaceBaseOrder
{
    return [self pointsOrder] - 100;
}

- (LatLon) parsePoiLatLon:(QString)value
{
    OASKGeoParsedPoint * p = [OASKMapUtils.shared decodeShortLinkStringS:value.toNSString()];
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
