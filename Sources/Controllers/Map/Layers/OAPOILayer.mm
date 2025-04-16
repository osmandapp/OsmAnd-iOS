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
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaPlugin.h"
#import "OARouteKey.h"
#import "OANetworkRouteDrawable.h"
#import "OAPluginsHelper.h"
#import "OAAppSettings.h"
#import "OsmAndSharedWrapper.h"
#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"
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

#define kPoiSearchRadius 50
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
    
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _wikiSymbolsProvider;
}

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

                        OAPOIType *type = [OAPOIHelper parsePOITypeByAmenity:amenity];
                        QHash<QString, QString> decodedValues = amenity->getDecodedValuesHash();
                        
                        BOOL check = !wikiUiNameFilter && !wikiUiFilter && poiUiNameFilter
                                && poiUiFilter && poiUiFilter.filterByName && poiUiFilter.filterByName.length > 0;
                        BOOL accepted = poiUiNameFilter && [poiUiNameFilter acceptAmenity:amenity values:decodedValues type:type];

                        if (!isWiki && [type.tag isEqualToString:OSM_WIKI_CATEGORY])
                            return check ? accepted : false;
                        
                        if ((check && accepted) || (isWiki ? wikiUiNameFilter && [wikiUiNameFilter acceptAmenity:amenity values:decodedValues type:type] : accepted))
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
            if (categoriesFilter.count() > 0)
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, &categoriesFilter, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), displayDensityFactor, 1.0, textSize, nightMode, showLabels, QString::fromNSString(lang), transliterate), self.pointsOrder));
            }
            else
            {
                (isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider).reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, displayDensityFactor, rasterTileSize, nullptr, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), displayDensityFactor, 1.0, textSize, nightMode, showLabels, QString::fromNSString(lang), transliterate), self.pointsOrder));
            }

            [self.mapView addTiledSymbolsProvider:isWiki ? _wikiSymbolsProvider : _amenitySymbolsProvider];
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

- (void) processAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity mapObject:(std::shared_ptr<const OsmAnd::MapObject>)mapObject poi:(OAPOI *)poi
{
    const auto& decodedCategories = amenity->getDecodedCategories();
    if (!decodedCategories.isEmpty())
    {
        const auto& entry = decodedCategories.first();
        poi.type = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:entry.category.toNSString() name:entry.subcategory.toNSString()];
    }
    
    poi.obfId = amenity->id;
    poi.name = amenity->nativeName.toNSString();
    poi.subType = amenity->subType.toNSString();

    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSString *nameLocalized = [OAPOIHelper processLocalizedNames:amenity->localizedNames nativeName:amenity->nativeName names:names];
    if (nameLocalized.length > 0)
        poi.name = nameLocalized;
    poi.nameLocalized = poi.name;
    poi.localizedNames = names;
    
    if (poi.name.length == 0 && poi.type)
        poi.name = poi.type.name;
    if (poi.nameLocalized.length == 0 && poi.type)
        poi.nameLocalized = poi.type.nameLocalized;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = poi.name;
    
    const auto decodedValues = amenity->getDecodedValues();
    [self processAmenityFields:poi decodedValues:decodedValues];
    
    if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(mapObject))
    {
        for (const OsmAnd::PointI pointI : obfMapObject->points31)
        {
            [poi addLocation:pointI.x y:pointI.y];
        }
    }
}

- (void) processAmenityFields:(OAPOI *)poi decodedValues:(const QList<OsmAnd::Amenity::DecodedValue>)decodedValues
{
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    
    for (const auto& entry : decodedValues)
    {
        if (entry.declaration->tagName.startsWith(QString("content")))
        {
            NSString *key = entry.declaration->tagName.toNSString();
            NSString *loc;
            if (key.length > 8)
                loc = [[key substringFromIndex:8] lowercaseString];
            else
                loc = @"";
            
            [content setObject:entry.value.toNSString() forKey:loc];
        }
        else
        {
            [values setObject:entry.value.toNSString() forKey:entry.declaration->tagName.toNSString()];
        }
    }
    
    poi.values = values;
    poi.localizedContent = content;
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
    if ([routeKey.routeKey.getTag().toNSString() isEqualToString:@"hiking"])
    {
        OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
        OAMapStyleParameter *routesParameter = [styleSettings getParameter:HIKING_ROUTES_OSMC_ATTR];
        return routesParameter.storedValue.length > 0 && ![routesParameter.storedValue isEqualToString:@"disabled"];
    }
    return YES;
}

- (void) putRouteToSelected:(OARouteKey *)key location:(CLLocationCoordinate2D)location mapObj:(const std::shared_ptr<const OsmAnd::MapObject> &)mapObj points:(NSMutableArray<OATargetPoint *> *)points area:(OsmAnd::AreaI)area
{
    OATargetPoint *point = [[OATargetPoint alloc] init];
    point.location = location;
    point.type = OATargetNetworkGPX;
    point.targetObj = key;
    OANetworkRouteDrawable *drawable = [[OANetworkRouteDrawable alloc] initWithRouteKey:key];
    point.icon = drawable.getIcon;
    point.title = key.routeKey.getRouteName().toNSString();
    NSArray *areaPoints = @[@(area.topLeft.x), @(area.topLeft.y), @(area.bottomRight.x), @(area.bottomRight.y)];
    point.values = @{ @"area": areaPoints };

    point.sortIndex = (NSInteger)point.type;

    if (![points containsObject:point])
        [points addObject:point];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:OAPOI.class])
        return [self getTargetPoint:obj renderedObject:nil];
    else
        return [self getTargetPoint:nil renderedObject:obj];
}

- (OATargetPoint *) getTargetPoint:(OAPOI *)poi renderedObject:(OARenderedObject *)renderedObject
{
    if (!renderedObject)
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
        targetPoint.title = poi.nameLocalized;
        targetPoint.icon = [poi.type icon];
        
        targetPoint.values = poi.values;
        targetPoint.localizedNames = poi.localizedNames;
        targetPoint.localizedContent = poi.localizedContent;
        targetPoint.obfId = poi.obfId;
        
        targetPoint.targetObj = poi;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    else
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetLocation;
        targetPoint.location = CLLocationCoordinate2DMake(renderedObject.labelLatLon.latitude, renderedObject.labelLatLon.longitude);
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

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    auto onPathSymbol = std::dynamic_pointer_cast<const OsmAnd::IOnPathMapSymbol>(symbolInfo->mapSymbol);
    if (onPathSymbol != nullptr)
        return;
    
    OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup* objSymbolGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup* amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    const std::shared_ptr<const OsmAnd::MapObject> mapObject = objSymbolGroup != nullptr ? objSymbolGroup->mapObject : nullptr;
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    
    OARenderedObject *renderedObject;
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = point.latitude;
    poi.longitude = point.longitude;
    if (amenitySymbolGroup != nullptr)
    {
        const auto amenity = amenitySymbolGroup->amenity;
        [self processAmenity:amenity mapObject:mapObject poi:poi];
    }
    else if (objSymbolGroup != nullptr && objSymbolGroup->mapObject != nullptr)
    {
        if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(objSymbolGroup->mapObject))
        {
            std::shared_ptr<const OsmAnd::Amenity> amenity;
            const auto& obfsDataInterface = self.app.resourcesManager->obfsCollection->obtainDataInterface();
            
            auto point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.latitude, point.longitude));
            const auto tags = obfMapObject->getResolvedAttributes();
            if (tags.contains(TAG_POI_LAT_LON))
            {
                const LatLon l = [self parsePoiLatLon:tags[TAG_POI_LAT_LON]];
                point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(l.lat, l.lon));
            }
            auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(kPoiSearchRadius, point31);
            BOOL amenityFound = obfsDataInterface->findAmenityByObfMapObject(obfMapObject, &amenity, &bbox31);

            bool isRoute = !OsmAnd::NetworkRouteKey::getRouteKeys(tags).isEmpty();

            if (isRoute)
                [self addRoute:found touchPoint:touchPoint mapObj:mapObject];

            bool allowRenderedObjects = !isRoute && !OsmAnd::NetworkRouteKey::containsUnsupportedRouteTags(tags);

            if (amenityFound)
            {
                [self processAmenity:amenity mapObject:objSymbolGroup->mapObject poi:poi];
            }
            else if (allowRenderedObjects)
            {
                renderedObject = [OARenderedObject parse:mapObject symbolInfo:symbolInfo];
                if (renderedObject.name && renderedObject.name.length > 0)
                    poi.name = renderedObject.name;
                if (renderedObject.nameLocalized && renderedObject.nameLocalized.length > 0)
                    poi.nameLocalized = renderedObject.nameLocalized;
            }
            else if (!unknownLocation)
            {
                return;
            }

            if (!poi.type)
            {
                for (const auto& ruleId : mapObject->attributeIds)
                {
                    const auto& rule = *mapObject->attributeMapping->decodeMap.getRef(ruleId);
                    if (rule.tag == QString("contour") /*|| (rule.tag == QString("highway") && rule.value != QString("bus_stop"))*/)
                        return;
                    
                    if (rule.tag == QString("place"))
                        poi.isPlace = YES;
                    
                    if (rule.tag == QString("addr:housenumber"))
                    {
                        poi.buildingNumber = mapObject->captions.value(ruleId).toNSString();
                        continue;
                    }
                    
                    if (!poi.type)
                    {
                        OAPOIType *poiType = [poiHelper getPoiType:rule.tag.toNSString() value:rule.value.toNSString()];
                        if (poiType)
                        {
                            poi.latitude = point.latitude;
                            poi.longitude = point.longitude;
                            poi.type = poiType;
                            if (poi.name.length == 0 && poi.type)
                                poi.name = poiType.name;
                            if (poi.nameLocalized.length == 0 && poi.type)
                                poi.nameLocalized = poiType.nameLocalized;
                            if (poi.nameLocalized.length == 0)
                                poi.nameLocalized = poi.name;
                        }
                    }
                }
            }
        }
    }

    OATargetPoint *targetPoint = [self getTargetPoint:poi renderedObject:renderedObject];
    if (![found containsObject:targetPoint])
        [found addObject:targetPoint];
}

- (LatLon) parsePoiLatLon:(QString)value
{
    OASKGeoParsedPoint * p = [OASKMapUtils.shared decodeShortLinkStringS:value.toNSString()];
    return LatLon(p.getLatitude, p.getLongitude);
}

@end
