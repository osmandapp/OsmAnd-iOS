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
#import "OAPOILocationType.h"
#import "OAPOIMyLocationType.h"
#import "OAPOIUIFilter.h"
#import "OAPOIHelper.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "Localization.h"

#include "OACoreResourcesAmenityIconProvider.h"
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>

@implementation OAPOILayer
{
    BOOL _showPoiOnMap;
    
    OAPOIUIFilter *_poiUiFilter;
    OAAmenityNameFilter *_poiUiNameFilter;
    NSString *_poiCategoryName;
    NSString *_poiFilterName;
    NSString *_poiTypeName;
    NSString *_poiKeyword;
    NSString *_prefLang;
    
    std::shared_ptr<OsmAnd::AmenitySymbolsProvider> _amenitySymbolsProvider;
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
    }
}

- (BOOL) updateLayer
{
    if (_showPoiOnMap)
    {
        if (_poiUiFilter)
            [self doShowPoiUiFilterOnMap];
        else
            [self doShowPoiOnMap];
    }
    
    return YES;
}

- (void) showPoiOnMap:(NSString *)category type:(NSString *)type filter:(NSString *)filter keyword:(NSString *)keyword
{
    _showPoiOnMap = YES;
    _poiCategoryName = category;
    _poiFilterName = filter;
    _poiTypeName = type;
    _poiKeyword = keyword;
    _prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowPoiOnMap];
    });
}

- (void) showPoiOnMap:(OAPOIUIFilter *)uiFilter keyword:(NSString *)keyword
{
    _showPoiOnMap = YES;
    _poiUiFilter = uiFilter;
    _poiKeyword = keyword;
    _prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowPoiUiFilterOnMap];
    });
}

- (void) doShowPoiOnMap
{
    [self.mapViewController runWithRenderSync:^{
        auto categoriesFilter = QHash<QString, QStringList>();
        if (_poiCategoryName && _poiTypeName) {
            categoriesFilter.insert(QString::fromNSString(_poiCategoryName), QStringList(QString::fromNSString(_poiTypeName)));
        } else if (_poiCategoryName) {
            categoriesFilter.insert(QString::fromNSString(_poiCategoryName), QStringList());
        }
        
        OsmAnd::ObfPoiSectionReader::VisitorFunction amenityFilter =
        ([self]
         (const std::shared_ptr<const OsmAnd::Amenity>& amenity)
         {
             bool res = false;
             
             if (_poiFilterName)
             {
                 NSString *category;
                 NSString *type;
                 const auto& decodedCategories = amenity->getDecodedCategories();
                 if (!decodedCategories.isEmpty())
                 {
                     const auto& entry = decodedCategories.first();
                     category = entry.category.toNSString();
                     type = entry.subcategory.toNSString();
                 }
                 
                 if (category && type)
                 {
                     OAPOIType *poiType = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:category name:type];
                     if (poiType && [poiType.filter.name isEqualToString:_poiFilterName])
                         res = true;
                 }
             }
             else
             {
                 res = true;
             }
             
             if (res && _poiKeyword)
             {
                 NSString *name = amenity->nativeName.toNSString();
                 
                 NSString *nameLocalized;
                 const QString lang = (_prefLang ? QString::fromNSString(_prefLang) : QString::null);
                 for(const auto& entry : OsmAnd::rangeOf(amenity->localizedNames))
                 {
                     if (lang != QString::null && entry.key() == lang)
                         nameLocalized = entry.value().toNSString();
                 }
                 
                 if (_poiKeyword.length == 0 || [self beginWith:_poiKeyword text:nameLocalized] || [self beginWithAfterSpace:_poiKeyword text:nameLocalized] || [self beginWith:_poiKeyword text:name] || [self beginWithAfterSpace:_poiKeyword text:name])
                 {
                     res = true;
                 }
                 else
                 {
                     res = false;
                 }
                 
             }
             
             return res;
         });
        
        
        if (categoriesFilter.count() > 0)
        {
            _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, &categoriesFilter, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        }
        else
        {
            _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, nullptr, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        }
        
        [self.mapView addTiledSymbolsProvider:_amenitySymbolsProvider];
    }];
}

- (void) doShowPoiUiFilterOnMap
{
    if (!_poiUiFilter)
        return;
    
    [self.mapViewController runWithRenderSync:^{
        auto categoriesFilter = QHash<QString, QStringList>();
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [_poiUiFilter getAcceptedTypes];
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
        
        if (_poiUiFilter.filterByName.length > 0)
            _poiUiNameFilter = [_poiUiFilter getNameFilter:_poiUiFilter.filterByName];
        else
            _poiUiNameFilter = nil;
        
        OsmAnd::ObfPoiSectionReader::VisitorFunction amenityFilter =
        ([self]
         (const std::shared_ptr<const OsmAnd::Amenity>& amenity)
         {
             bool res = true;
             OAPOI *poi = [OAPOIHelper parsePOIByAmenity:amenity];
             if (_poiUiNameFilter)
                 res = [_poiUiNameFilter accept:poi];
             
             return res;
         });
        
        if (_amenitySymbolsProvider)
            [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
        
        if (categoriesFilter.count() > 0)
        {
            _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, &categoriesFilter, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        }
        else
        {
            _amenitySymbolsProvider.reset(new OsmAnd::AmenitySymbolsProvider(self.app.resourcesManager->obfsCollection, nullptr, amenityFilter, std::make_shared<OACoreResourcesAmenityIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        }
        
        [self.mapView addTiledSymbolsProvider:_amenitySymbolsProvider];
    }];
}

- (void) hidePoi
{
    if (!_showPoiOnMap)
        return;
    
    _showPoiOnMap = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.mapViewController runWithRenderSync:^{
            if (_amenitySymbolsProvider)
            {
                [self.mapView removeTiledSymbolsProvider:_amenitySymbolsProvider];
                _amenitySymbolsProvider.reset();
            }
        }];
    });
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

- (void) processAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity poi:(OAPOI *)poi
{
    const auto& decodedCategories = amenity->getDecodedCategories();
    if (!decodedCategories.isEmpty())
    {
        const auto& entry = decodedCategories.first();
        poi.type = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:entry.category.toNSString() name:entry.subcategory.toNSString()];
    }
    
    poi.obfId = amenity->id;
    poi.name = amenity->nativeName.toNSString();

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

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAPOI class]])
    {
        OAPOI *poi = (OAPOI *)obj;
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        if (poi.type)
        {
            if ([poi.type.name isEqualToString:@"wiki_place"])
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
        
        targetPoint.targetObj = poi;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
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
    OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup* objSymbolGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup* amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = point.latitude;
    poi.longitude = point.longitude;
    if (amenitySymbolGroup != nullptr)
    {
        const auto amenity = amenitySymbolGroup->amenity;
        [self processAmenity:amenity poi:poi];
    }
    else if (objSymbolGroup != nullptr && objSymbolGroup->mapObject != nullptr)
    {
        const std::shared_ptr<const OsmAnd::MapObject> mapObject = objSymbolGroup->mapObject;
        if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(objSymbolGroup->mapObject))
        {
            std::shared_ptr<const OsmAnd::Amenity> amenity;
            const auto& obfsDataInterface = self.app.resourcesManager->obfsCollection->obtainDataInterface();
            BOOL amenityFound = obfsDataInterface->findAmenityForObfMapObject(obfMapObject, &amenity);
            if (amenityFound)
            {
                [self processAmenity:amenity poi:poi];
            }
            if (!poi.type)
            {
                for (const auto& ruleId : mapObject->attributeIds)
                {
                    const auto& rule = *mapObject->attributeMapping->decodeMap.getRef(ruleId);
                    if (rule.tag == QString("contour") || (rule.tag == QString("highway") && rule.value != QString("bus_stop")))
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
    if (poi.type || poi.buildingNumber || unknownLocation)
    {
        OATargetPoint *targetPoint = [self getTargetPoint:poi];
        if (![found containsObject:targetPoint])
            [found addObject:targetPoint];
    }
}

@end
