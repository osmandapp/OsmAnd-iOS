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
    OAPOILayerTopPlacesProvider *_topPlacesProvider;
    
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _wikiSymbolsProvider;
}

- (void)onMapFrameRendered
{
    [_topPlacesProvider drawTopPlacesIfNeeded:NO];
}

- (void)initLayer
{
    [super initLayer];

    _filtersHelper = [OAPOIFiltersHelper sharedInstance];
    _topPlacesProvider = [[OAPOILayerTopPlacesProvider alloc] initWithTopPlaceBaseOrder:(int)[self getTopPlaceBaseOrder]];
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
    });
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    [self updateVisiblePoiFilter];
    [_topPlacesProvider updateLayer];
    
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

- (void)collectObjectsFromPoint:(MapSelectionResult *)result
                unknownLocation:(BOOL)unknownLocation
      excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    NSMutableArray<OAPOI *> *allAmenities = [NSMutableArray array];

      NSArray<OAPOI *> *amenities =
          [self getDisplayedResults:result.pointLatLon.coordinate.latitude
                                lon:result.pointLatLon.coordinate.longitude];

      if (amenities.count > 0)
      {
          [allAmenities addObjectsFromArray:amenities];
      }
      else
      {
          CGPoint point = result.point;
          int radius = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * (TOUCH_RADIUS_MULTIPLIER * 2);
          QList<OsmAnd::PointI> touchPolygon31 = [OANativeUtilities getPolygon31FromPixelAndRadius:point radius:radius];
          if (!touchPolygon31.isEmpty())
          {
              NSArray<OAPOI *> *topPlaces = [_topPlacesProvider getDisplayedResultsFor:touchPolygon31];

              if (topPlaces.count > 0)
                  [allAmenities addObjectsFromArray:topPlaces];
          }
      }

      for (OAPOI *amenity in allAmenities)
      {
          [result collect:amenity provider:self];
      }
}

- (void)contextMenuDidShow:(id)targetObj
{
    OAPOI *amenity = [self getAmenity:targetObj];
    if (amenity)
    {
        [_topPlacesProvider updateSelectedTopPlaceIfNeeded:amenity];
    }
    else
    {
        [_topPlacesProvider resetSelectedTopPlaceIfNeeded];
    }
}

- (void)contextMenuDidHide
{
    [_topPlacesProvider resetSelectedTopPlaceIfNeeded];
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
    if ([self isTopPlace:selectedObject]) {
        return [self getTopPlaceBaseOrder];
    } else {
        return 0;
    }
}

- (BOOL)isTopPlace:(id)object
{
    NSDictionary<NSNumber *, OAPOI *> *topPlaces = [_topPlacesProvider topPlaces];
    if (!topPlaces || !object)
        return NO;
    
    if ([object isKindOfClass:OAPOI.class])
    {
        int64_t obfId = ((OAPOI *)object).obfId;
        return topPlaces[@(obfId)] != nil;
    }
    
    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *details = (BaseDetailsObject *)object;
        
        int64_t obfId = details.syntheticAmenity.obfId;
        if (topPlaces[@(obfId)])
            return YES;
        
        for (OAPOI *poi in details.objects)
        {
            if (topPlaces[@(poi.obfId)])
                return YES;
        }
    }
    
    return NO;
}

- (int64_t) getTopPlaceBaseOrder
{
    return [self pointsOrder] - 100;
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
