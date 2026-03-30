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
#import "OAPOIMapLayerData.h"
#import "OAPOITileProvider.h"
#import "OARenderedObject.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaPlugin.h"
#import "OARouteKey.h"
#import "OARouteKey+cpp.h"
#import "OANetworkRouteDrawable.h"
#import "OAPluginsHelper.h"
#import "OAAppSettings.h"
#import "OAMapStyleSettings.h"
#import "OsmAndSharedWrapper.h"
#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"
#import "OAPointDescription.h"
#import "QuadTree.h"
#import "OAMapTopPlace.h"
#import "OANativeUtilities.h"
#import "OAPOILayerTopPlacesProvider.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
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

static const NSInteger kPoiSearchRadius = 50; // AMENITY_SEARCH_RADIUS
static const NSInteger kPoiSearchRadiusForRelation = 500; // AMENITY_SEARCH_RADIUS_FOR_RELATION
static const NSInteger kTrackSearchDelta = 40;
static const NSInteger START_ZOOM = 5;

const QString TAG_POI_LAT_LON = QStringLiteral("osmand_poi_lat_lon");

@implementation OAPOILayer
{
    BOOL _showPoiOnMap;

    OAPOIUIFilter *_poiUiFilter;
    OAPOIUIFilter *_wikiUiFilter;
    NSString *_filtersSignature;
    NSString *_providerAppearanceSignature;
    
    OAPOIFiltersHelper *_filtersHelper;
    OAPOILayerTopPlacesProvider *_topPlacesProvider;
    OAPOIMapLayerData *_mapLayerData;
    
    std::shared_ptr<OAPOITileProvider> _poiTileProvider;
}

- (void)clearPoiProvider
{
    if (_poiTileProvider)
    {
        [self.mapViewController runWithRenderSync:^{
            [self.mapView removeTiledSymbolsProvider:_poiTileProvider];
            _poiTileProvider.reset();
        }];
    }
    _providerAppearanceSignature = nil;
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
    _mapLayerData = [[OAPOIMapLayerData alloc] initWithMapView:self.mapView mapViewController:self.mapViewController];
    [_topPlacesProvider setMapLayerData:_mapLayerData];

    __weak __typeof(self) weakSelf = self;
    _mapLayerData.layerOnPostExecute = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf)
                return;
            if (strongSelf->_mapLayerData.deferredResults)
                [strongSelf clearPoiProvider];
            [strongSelf.mapViewController refreshMap];
            [strongSelf->_topPlacesProvider updateLayer];
        });
    };
}

- (NSString *) layerId
{
    return kPoiLayerId;
}

- (void) resetLayer
{
    [self clearPoiProvider];
    [_mapLayerData clearCache];
    [_topPlacesProvider resetLayer];
}

- (NSString *)buildFiltersSignature:(NSSet<OAPOIUIFilter *> *)filters wikiFilter:(OAPOIUIFilter *)wikiFilter
{
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSArray<OAPOIUIFilter *> *sortedFilters = [filters.allObjects sortedArrayUsingComparator:^NSComparisonResult(OAPOIUIFilter *left, OAPOIUIFilter *right) {
        return [left.filterId compare:right.filterId];
    }];
    for (OAPOIUIFilter *filter in sortedFilters)
        [parts addObject:[NSString stringWithFormat:@"%@|%@", filter.filterId ?: @"", filter.filterByName ?: @""]];

    if (wikiFilter)
        [parts addObject:[NSString stringWithFormat:@"wiki:%@|%@", wikiFilter.filterId ?: @"", wikiFilter.filterByName ?: @""]];

    return [parts componentsJoinedByString:@";"];
}

- (NSString *)providerAppearanceSignature
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    return [NSString stringWithFormat:@"%@|%@|%.2f",
            settings.mapSettingShowPoiLabel.get ? @"1" : @"0",
            settings.nightMode ? @"1" : @"0",
            settings.textSize.get];
}

- (OsmAnd::TextRasterizer::Style)captionStyle
{
    const auto density = self.mapViewController.displayDensityFactor;
    const auto textSize = [OAAppSettings sharedManager].textSize.get;
    const auto nightMode = [OAAppSettings sharedManager].nightMode;

    OsmAnd::TextRasterizer::Style style;
    style.setWrapWidth(20)
        .setBold(false)
        .setItalic(false)
        .setColor(OsmAnd::ColorARGB(nightMode ? color_widgettext_night_argb : color_widgettext_day_argb))
        .setSize(textSize * 13.0f * density)
        .setHaloColor(OsmAnd::ColorARGB(nightMode ? color_widgettext_shadow_night_argb : color_widgettext_shadow_day_argb))
        .setHaloRadius(5);
    return style;
}

- (void)updatePoiProvider
{
    BOOL hasFilters = _poiUiFilter != nil || _wikiUiFilter != nil;
    NSString *appearanceSignature = [self providerAppearanceSignature];

    if (!hasFilters)
    {
        [self clearPoiProvider];
        _showPoiOnMap = NO;
        return;
    }

    BOOL needsRebuild = !_poiTileProvider || ![_providerAppearanceSignature isEqualToString:appearanceSignature];
    if (!needsRebuild)
        return;

    _providerAppearanceSignature = appearanceSignature;
    const auto textVisible = [OAAppSettings sharedManager].mapSettingShowPoiLabel.get;
    const auto density = self.mapViewController.displayDensityFactor;
    const auto captionTopSpace = -4.0 * density;
    const auto referenceTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
    const auto textScale = [OAAppSettings sharedManager].textSize.get;
    const auto style = [self captionStyle];

    [self.mapViewController runWithRenderSync:^{
        if (_poiTileProvider)
            [self.mapView removeTiledSymbolsProvider:_poiTileProvider];

        _poiTileProvider = std::make_shared<OAPOITileProvider>(self.mapView,
                                                               _mapLayerData,
                                                               [self pointsOrder],
                                                               textVisible,
                                                               style,
                                                               captionTopSpace,
                                                               referenceTileSize,
                                                               textScale);
        [self.mapView addTiledSymbolsProvider:kPOISymbolSection provider:_poiTileProvider];
    }];
}

- (void) updateVisiblePoiFilter
{
    
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

    BOOL noValidByName = filters.count == 1
            && [filters.allObjects.firstObject.name isEqualToString:OALocalizedString(@"poi_filter_by_name")]
            && !filters.allObjects.firstObject.filterByName;

    _wikiUiFilter = wikiFilter;
    _poiUiFilter = noValidByName ? nil : [_filtersHelper combineSelectedFilters:filters];
    if (noValidByName)
        [_filtersHelper removeSelectedPoiFilter:filters.allObjects.firstObject];

    NSString *signature = [self buildFiltersSignature:filters wikiFilter:wikiFilter];
    if (![_filtersSignature isEqualToString:signature])
    {
        _filtersSignature = signature;
        [_mapLayerData setPoiFilter:_poiUiFilter wikiFilter:_wikiUiFilter];
        [_mapLayerData clearCache];
        _providerAppearanceSignature = nil;
    }
    _showPoiOnMap = _poiUiFilter != nil || _wikiUiFilter != nil;
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    [self updateVisiblePoiFilter];
    [self updatePoiProvider];
    [_topPlacesProvider updateLayer];
    return YES;
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

- (OATargetPoint *)getTargetPoint:(id)obj touchLocation:(CLLocation *)touchLocation
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
    NSArray<OAPOIMapLayerItem *> *objects = _mapLayerData.displayedResults;
    if (objects.count == 0)
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
    
    NSDictionary<NSNumber *, OAPOI *> *topPlaces = _topPlacesProvider.topPlaces;
    
    for (OAPOIMapLayerItem *item in objects)
    {
        CLLocationCoordinate2D coord = item.coordinate;
        if (![OANativeUtilities isPointInsidePolygonLat:coord.latitude
                                                    lon:coord.longitude
                                              polygon31:touchPolygon31])
            continue;

        OAPOI *amenity = [_mapLayerData poiForItem:item];
        if (!amenity)
            continue;

        if (topPlaces[@(item.signedId)])
        {
            [result collect:amenity provider:self];
            break;
        }
        
        [result collect:amenity provider:self];
    }
}

- (void)contextMenuDidShow:(id)targetObj
{
    [_topPlacesProvider contextMenuDidShow:targetObj];
}

- (void)contextMenuDidHide
{
    [_topPlacesProvider resetSelectedTopPlaceIfNeeded];
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

- (BOOL)isTopPlace:(id)object
{
    NSDictionary<NSNumber *, OAPOI *> *topPlaces = [_topPlacesProvider topPlaces];
    if (!topPlaces || !object)
        return NO;
    
    if ([object isKindOfClass:OAPOI.class])
    {
        int64_t obfId = ((OAPOI *)object).getSignedId;
        return topPlaces[@(obfId)] != nil;
    }
    
    if ([object isKindOfClass:BaseDetailsObject.class])
    {
        BaseDetailsObject *details = (BaseDetailsObject *)object;
        for (id item in details.objects)
        {
            if ([item isKindOfClass:[OAMapObject class]])
            {
                OAMapObject *mapObject = (OAMapObject *)item;
                int64_t obfId = [mapObject getSignedId];
                if (topPlaces[@(obfId)])
                {
                    return YES;
                }
            }
        }
    }
    
    return NO;
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
