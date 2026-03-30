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
#include <cmath>
#include <limits>

static const NSInteger kPoiSearchRadius = 50; // AMENITY_SEARCH_RADIUS
static const NSInteger kPoiSearchRadiusForRelation = 500; // AMENITY_SEARCH_RADIUS_FOR_RELATION
static const NSInteger kTrackSearchDelta = 40;
static const NSInteger START_ZOOM = 5;
static const NSTimeInterval kWikiSymbolsCacheWaitInterval = 0.05;
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

static std::shared_ptr<void> OARetainObjCObject(id object)
{
    return std::shared_ptr<void>(
        (__bridge_retained void *)object,
        [](void *retainedObject)
        {
            if (retainedObject)
                CFRelease(retainedObject);
        });
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

static std::shared_ptr<const OsmAnd::Amenity> OASyntheticAmenityFromPoi(OAPOI *poi)
{
    if (!poi || ![poi hasLocation])
        return nullptr;

    const QString categoryName = QString::fromNSString(poi.type.category.name ?: @"osmwiki");
    const QString subTypeName = QString::fromNSString(
        poi.subType.length > 0 ? poi.subType : (poi.type.name ?: @"wikiplace"));

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

    const auto subtypes = subTypeName.split(';', Qt::SkipEmptyParts);
    for (const auto& subtype : OsmAnd::constOf(subtypes))
    {
        OsmAnd::Amenity::DecodedCategory decodedCategory;
        decodedCategory.category = categoryName;
        decodedCategory.subcategory = subtype;
        amenity->decodedCategoriesOverride.push_back(decodedCategory);
    }

    NSDictionary<NSString *, NSString *> *additionalInfo = [poi getAdditionalInfo];
    for (NSString *key in additionalInfo)
        amenity->decodedValuesOverride.insert(QString::fromNSString(key), QString::fromNSString(additionalInfo[key]));

    if (poi.type)
        amenity->decodedValuesOverride.insert(QStringLiteral("osmand_poi_key"), QString::fromNSString([poi.type iconKeyName]));

    return amenity;
}

@interface OAPOILayer ()

- (BOOL)loadExternalWikiAmenitiesWithDataProvider:(PoiUIFilterDataProvider *)dataProvider
                                          request:(const OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesRequest &)request
                                        amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities;

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

- (void)initLayer
{
    [super initLayer];

    _screenSize = CGSizeMake([OAUtilities calculateScreenWidth], [OAUtilities calculateScreenHeight]);

    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _topPlacesTextScale = 1.f;
    _topPlacesWikipediaResourceIds = [NSSet set];
    _topPlacesProvider = [[OAPOILayerTopPlacesProvider alloc] initWithTopPlaceBaseOrder:(int)[self getTopPlaceBaseOrder]];
    __weak __typeof(self) weakSelf = self;
    _topPlacesProvider.cachedAmenitiesProvider = ^BOOL(QuadRect *latLonBounds, id matcher, QList<std::shared_ptr<const OsmAnd::Amenity>> *amenities) {
        if (!weakSelf)
        {
            if (amenities)
                amenities->clear();
            return YES;
        }

        return [weakSelf cachedVisibleWikiAmenities:latLonBounds matcher:matcher amenities:amenities];
    };
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
            OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesProvider externalAmenitiesProvider = nullptr;
            if (isWiki && [f isTopWikiFilter] && settings.wikiDataSourceType.get == EOAWikiDataSourceTypeOnline)
            {
                PoiUIFilterDataProvider *wikiDataProvider = [[PoiUIFilterDataProvider alloc] initWithFilter:f];
                __weak __typeof(self) weakSelf = self;
                const auto retainedWikiDataProvider = OARetainObjCObject(wikiDataProvider);
                externalAmenitiesProvider =
                    [weakSelf, retainedWikiDataProvider]
                    (const OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesRequest& externalRequest,
                     QList<std::shared_ptr<const OsmAnd::Amenity>>& outAmenities) -> bool
                    {
                        OAPOILayer *strongSelf = weakSelf;
                        PoiUIFilterDataProvider *strongDataProvider =
                            (__bridge PoiUIFilterDataProvider *)retainedWikiDataProvider.get();
                        if (!strongSelf)
                        {
                            outAmenities.clear();
                            return YES;
                        }

                        return [strongSelf loadExternalWikiAmenitiesWithDataProvider:strongDataProvider
                                                                              request:externalRequest
                                                                            amenities:&outAmenities];
                    };
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

            [self.mapView addTiledSymbolsProvider:kPOISymbolSection provider:isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider];
            if (isWiki)
                [_topPlacesProvider drawTopPlacesIfNeeded:YES];
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

- (BOOL)loadExternalWikiAmenitiesWithDataProvider:(PoiUIFilterDataProvider *)dataProvider
                                          request:(const OsmAnd::AmenitySymbolsProvider::ExternalAmenitiesRequest &)request
                                        amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
{
    if (amenities)
        amenities->clear();

    if (!dataProvider)
        return YES;

    const auto isCancelled = request.isCancelled;
    OAResultMatcher<OAPOI *> *matcher =
        [[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *poi) {
            Q_UNUSED(poi);
            return !isCancelled || !isCancelled();
        } cancelledFunc:^BOOL{
            return isCancelled && isCancelled();
        }];

    const auto centerLatLon = OsmAnd::Utilities::convert31ToLatLon(request.center31);
    const double topLatitude = OsmAnd::Utilities::get31LatitudeY(request.visibleBBox31.top());
    const double bottomLatitude = OsmAnd::Utilities::get31LatitudeY(request.visibleBBox31.bottom());
    const double leftLongitude = OsmAnd::Utilities::get31LongitudeX(request.visibleBBox31.left());
    const double rightLongitude = OsmAnd::Utilities::get31LongitudeX(request.visibleBBox31.right());

    NSArray<OAPOI *> *pois = [dataProvider searchAmenitiesWithLat:centerLatLon.latitude
                                                             lon:centerLatLon.longitude
                                                     topLatitude:topLatitude
                                                  bottomLatitude:bottomLatitude
                                                   leftLongitude:leftLongitude
                                                  rightLongitude:rightLongitude
                                                            zoom:request.zoom
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

- (BOOL)cachedVisibleWikiAmenities:(QuadRect *)latLonBounds
                           matcher:(id)matcherObj
                         amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
{
    OAResultMatcher<OAPOI *> *matcher = (OAResultMatcher<OAPOI *> *)matcherObj;
    while (![matcher isCancelled])
    {
        __block BOOL showWikiOnMap = NO;
        std::shared_ptr<OsmAnd::AmenitySymbolsProvider> wikiSymbolsProvider;
        QVector<OsmAnd::TileId> visibleTiles;
        OsmAnd::ZoomLevel visibleZoom = OsmAnd::InvalidZoomLevel;
        [self readVisibleWikiCacheStateShowWikiOnMap:&showWikiOnMap
                                 wikiSymbolsProvider:&wikiSymbolsProvider
                                        visibleTiles:&visibleTiles
                                         visibleZoom:&visibleZoom];

        if (!showWikiOnMap)
        {
            if (amenities)
                amenities->clear();
            return YES;
        }

        if (!wikiSymbolsProvider || visibleTiles.isEmpty() || visibleZoom == OsmAnd::InvalidZoomLevel)
        {
            [NSThread sleepForTimeInterval:kWikiSymbolsCacheWaitInterval];
            continue;
        }

        if (visibleZoom < wikiSymbolsProvider->getMinZoom()
            || visibleZoom > wikiSymbolsProvider->getMaxZoom())
        {
            if (amenities)
                amenities->clear();
            return YES;
        }

        if ([self areVisibleWikiTilesCached:visibleTiles zoom:visibleZoom wikiSymbolsProvider:wikiSymbolsProvider])
            return [self cachedAmenitiesFromWikiSymbolsProvider:wikiSymbolsProvider
                                                   visibleTiles:visibleTiles
                                                           zoom:visibleZoom
                                                  latLonBounds:latLonBounds
                                                      amenities:amenities
                                                       matcher:matcher];

        [NSThread sleepForTimeInterval:kWikiSymbolsCacheWaitInterval];
    }

    if (amenities)
        amenities->clear();
    return NO;
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

- (BOOL)cachedAmenitiesFromWikiSymbolsProvider:(const std::shared_ptr<OsmAnd::AmenitySymbolsProvider> &)wikiSymbolsProvider
                                  visibleTiles:(const QVector<OsmAnd::TileId> &)visibleTiles
                                          zoom:(OsmAnd::ZoomLevel)visibleZoom
                                 latLonBounds:(QuadRect *)latLonBounds
                                    amenities:(QList<std::shared_ptr<const OsmAnd::Amenity>> *)amenities
                                      matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableSet<NSNumber *> *seenAmenityIds = [NSMutableSet set];
    if (amenities)
        amenities->clear();

    for (const auto& tileId : visibleTiles)
    {
        QList<std::shared_ptr<const OsmAnd::Amenity>> cachedAmenities;
        if (!wikiSymbolsProvider->cache->obtainAmenities(tileId, visibleZoom, cachedAmenities))
            continue;

        for (const auto& amenity : cachedAmenities)
        {
            if ([matcher isCancelled])
            {
                if (amenities)
                    amenities->clear();
                return NO;
            }

            const auto latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
            if (!OABoundsContainCoordinate(latLonBounds, coordinate))
                continue;

            NSNumber *amenityId = @((uint64_t)amenity->id);
            if ([seenAmenityIds containsObject:amenityId])
                continue;

            [seenAmenityIds addObject:amenityId];
            if (amenities)
                amenities->push_back(amenity);
        }
    }

    return YES;
}

- (CGFloat)topPlacesTextScale
{
    return OAAppSettings.sharedManager.textSize.get * self.mapViewController.displayDensityFactor;
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
    CGFloat textScale = [self topPlacesTextScale];
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
            break;
        }
        
        [result collect:poi provider:self];
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
        NSNumber *placeId = @(poi.obfId);
        return [topPlaceIds containsObject:placeId] ? placeId : nil;
    }

    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *baseDetailsObject = object;
        NSNumber *syntheticPlaceId = @(baseDetailsObject.syntheticAmenity.obfId);
        if ([topPlaceIds containsObject:syntheticPlaceId])
            return syntheticPlaceId;

        for (id item in baseDetailsObject.objects)
        {
            if (![item isKindOfClass:OAPOI.class])
                continue;

            OAPOI *poi = (OAPOI *)item;
            NSNumber *placeId = @(poi.obfId);
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
