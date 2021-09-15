//
//  OASearchCoreFactory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchCoreFactory.h"
#import "OASearchPhrase.h"
#import "OASearchResult.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OASearchResultMatcher.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "QuadRect.h"

#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"
#import "OAPOICategory.h"
#import "OAPOIHelper.h"
#import "OACustomSearchPoiFilter.h"
#import "OAPOI.h"
#import "OAAddress.h"
#import "OABuilding.h"
#import "OAStreet.h"
#import "OACity.h"
#import "OAStreetIntersection.h"
#import "OALocationParser.h"
#import "OrderedDictionary.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IObfsCollection.h>
#include <OsmAndCore/Data/Building.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetIntersection.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/QuadTree.h>
#include <OsmAndCore/PointsAndAreas.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Search/AddressesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/ICU.h>
#include <OsmAndCore/Search/CommonWords.h>

#include <GeographicLib/GeoCoords.hpp>

#define OLC_RECALC_DISTANCE_THRESHOLD 100000 // 100 km

#define STD_POI_FILTER_PREFIX  @"std_"

@interface OAPoiAdditionalCustomFilter : OAPOIBaseType

@property (nonatomic) NSMutableArray<OAPOIType *> *additionalPoiTypes;

- (instancetype) initWithType:(OAPOIType *)pt;

@end

@implementation OAPoiAdditionalCustomFilter
{
    OAPOIHelper *_poiHelper;
}

- (instancetype) initWithType:(OAPOIType *)pt
{
    self = [super initWithName:pt.name];
    if (self) {
        _poiHelper = OAPOIHelper.sharedInstance;
        _additionalPoiTypes = [NSMutableArray new];
        [_additionalPoiTypes addObject:pt];
    }
    return self;
}

- (BOOL)isAdditional
{
    return YES;
}

- (NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *) putTypes:(NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *)acceptedTypes
{
    for (OAPOIType *p in _additionalPoiTypes)
    {
        if ([p.parent isEqual:_poiHelper.otherMapCategory])
        {
            for (OAPOICategory *c in [_poiHelper getCategories:NO])
            {
                [c putTypes:acceptedTypes];
            }
        }
        else
        {
            [p.parentType putTypes:acceptedTypes];
        }

    }
    return acceptedTypes;
}

- (UIImage *)icon
{
    return [UIImage imageNamed:@"ic_custom_search"];
}

- (NSString *)iconName
{
    return @"ic_custom_search";
}

@end

@interface OASearchCoreFactory ()

+ (NSString *) stripBraces:(NSString *)localeName;
+ (CLLocation *) getLocation:(const OsmAnd::PointI)position31;
+ (CLLocation *) getLocation:(const std::shared_ptr<const OsmAnd::Building>&)building hno:(const QString&)hno;
+ (NSMutableArray<NSString *> *) getAllNames:(const QHash<QString, QString>&)names nativeName:(const QString&)nativeName;
+ (BOOL) isLastWordCityGroup:(OASearchPhrase *)p;

@end


@interface OASearchBaseAPI ()

- (void) subSearchApiOrPublish:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher res:(OASearchResult *)res api:(OASearchBaseAPI *)api;
- (void) subSearchApiOrPublish:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher res:(OASearchResult *)res api:(OASearchBaseAPI *)api publish:(BOOL)publish;

@end

@implementation OASearchBaseAPI
{
    NSArray<OAObjectType *> *_searchTypes;
}

- (instancetype)initWithSearchTypes:(NSArray<OAObjectType *> *)searchTypes
{
    self = [super init];
    if (self)
    {
        _searchTypes = searchTypes;
    }
    return self;
}

- (BOOL) isSearchAvailable:(OASearchPhrase *)p
{
    NSArray<OAObjectType *> *typesToSearch = [p getSearchTypes];
    OAObjectType *exclusiveSearchType = [p getExclusiveSearchType];
    if (exclusiveSearchType)
    {
        return _searchTypes && _searchTypes.count == 1 && _searchTypes[0].type == exclusiveSearchType.type;
    }
    else if (!typesToSearch)
    {
        return YES;
    }
    else
    {
        for (OAObjectType *type in _searchTypes)
        {
            for (OAObjectType *ts : typesToSearch)
            {
                if (type.type == ts.type)
                    return YES;
            }
        }
        return NO;
    }
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    return YES;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    return 1;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return [phrase getRadiusLevel] < MAX_DEFAULT_SEARCH_RADIUS;
}

- (void)subSearchApiOrPublish:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher res:(OASearchResult *)res api:(OASearchBaseAPI *)api
{
    return [self subSearchApiOrPublish:phrase resultMatcher:resultMatcher res:res api:api publish:YES];
}

- (void) subSearchApiOrPublish:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher res:(OASearchResult *)res api:(OASearchBaseAPI *)api publish:(BOOL)publish
{
    [phrase countUnknownWordsMatchMainResult:res];
    BOOL firstUnknownWordMatches = res.firstUnknownWordMatches;
    NSMutableArray<NSString *> *leftUnknownSearchWords = [NSMutableArray arrayWithArray:[phrase getUnknownSearchWords]];
    if (res.otherWordsMatch)
        [leftUnknownSearchWords removeObjectsInArray:[res.otherWordsMatch allObjects]];
    
    OASearchResult *newParentSearchResult = nil;
    if (res.parentSearchResult == nil && resultMatcher.getParentSearchResult == nil &&
        res.objectType == STREET && [res.object isKindOfClass:OAStreet.class] && ((OAStreet *) res.object).city != nil) {
        OACity *ct = ((OAStreet *) res.object).city;
        OASearchResult *cityResult = [[OASearchResult alloc] initWithPhrase:phrase];
        cityResult.object = ct;
        cityResult.objectType = CITY;
        cityResult.localeName = [ct getName:phrase.getSettings.getLang transliterate:phrase.getSettings.isTransliterate];
        cityResult.otherNames = [NSMutableArray arrayWithArray:ct.localizedNames.allValues];
        cityResult.location = [[CLLocation alloc] initWithLatitude:ct.latitude longitude:ct.longitude];
        QString lang = QString::fromNSString([[phrase getSettings] getLang]);
        const auto& r = OsmAndApp.instance.resourcesManager->getLocalResource(QString::fromNSString(res.resourceId));
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(r->metadata);
        if (obfMetadata)
            cityResult.localeRelatedObjectName = obfMetadata->obfFile->getRegionName().toNSString();
        cityResult.relatedResourceId = res.resourceId;
        [phrase countUnknownWordsMatchMainResult:cityResult];
        __block BOOL match = NO;
        if (firstUnknownWordMatches)
        {
            cityResult.firstUnknownWordMatches = NO; // don't count same name twice
        }
        else if (cityResult.firstUnknownWordMatches)
        {
            firstUnknownWordMatches = YES;
            match = YES;
        }
        if (cityResult.otherWordsMatch != nil)
        {
            NSMutableSet<NSString *> *toDelete = [NSMutableSet new];
            [cityResult.otherWordsMatch enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                BOOL wasPresent = [leftUnknownSearchWords containsObject:obj];
                [leftUnknownSearchWords removeObject:obj];
                if (!wasPresent)
                    [toDelete addObject:obj]; // don't count same name twice
                else
                    match = YES;
            }];
            [cityResult.otherWordsMatch minusSet:toDelete];
        }
        // include parent search result even if it is empty
        if (match)
            newParentSearchResult = cityResult;
    }
    if (!firstUnknownWordMatches)
        [leftUnknownSearchWords insertObject:[phrase getFirstUnknownSearchWord] atIndex:0];
    
    // publish result to set parentSearchResult before search
    if (publish)
    {
        if (newParentSearchResult != nil)
        {
            OASearchResult *prev = [resultMatcher setParentSearchResult:newParentSearchResult];
            [resultMatcher publish:res];
            [resultMatcher setParentSearchResult:prev];
        }
        else
        {
            [resultMatcher publish:res];
        }
    }
    if (leftUnknownSearchWords.count > 0 && api != nil && [api isSearchAvailable:phrase])
    {
        OASearchPhrase *nphrase = [phrase selectWord:res unknownWords:leftUnknownSearchWords lastComplete:phrase.isLastUnknownSearchWordComplete || ![leftUnknownSearchWords containsObject:phrase.getLastUnknownSearchWord]];
        OASearchResult *prev = [resultMatcher setParentSearchResult:publish ? res :
                resultMatcher.getParentSearchResult];
        [api search:nphrase resultMatcher:resultMatcher];
        [resultMatcher setParentSearchResult:prev];
    }
}

@end


@interface OASearchAddressByNameAPI ()

@end

@implementation OASearchAddressByNameAPI
{
    int DEFAULT_ADDRESS_BBOX_RADIUS;
    int LIMIT;

    NSMutableArray<NSString *> *_townCities;
    std::shared_ptr<OsmAnd::QuadTree<std::shared_ptr<const OsmAnd::StreetGroup>, OsmAnd::AreaI::CoordType>> _townCitiesQR;

    QList<std::shared_ptr<const OsmAnd::StreetGroup>> _resArray;
    QHash<std::shared_ptr<const OsmAnd::StreetGroup>, QString> _streetGroupResourceIds;
    OASearchStreetByCityAPI *_cityApi;
    OASearchBuildingAndIntersectionsByStreetAPI *_streetsApi;
}

- (instancetype) initWithCityApi:(OASearchStreetByCityAPI *)cityApi streetsApi:(OASearchBuildingAndIntersectionsByStreetAPI *)streetsApi
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:CITY],
                                        [OAObjectType withType:VILLAGE],
                                        [OAObjectType withType:POSTCODE],
                                        [OAObjectType withType:STREET],
                                        [OAObjectType withType:HOUSE],
                                        [OAObjectType withType:STREET_INTERSECTION]]];
    if (self)
    {
        DEFAULT_ADDRESS_BBOX_RADIUS = 100 * 1000;
        LIMIT = 10000;
        
        _townCities = [NSMutableArray array];
        _townCitiesQR = std::make_shared<OsmAnd::QuadTree<std::shared_ptr<const OsmAnd::StreetGroup>, OsmAnd::AreaI::CoordType>>(OsmAnd::AreaI::largestPositive(), static_cast<uintmax_t>(8u));
        
        _cityApi = cityApi;
        _streetsApi = streetsApi;
    }
    return self;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType] && [p getRadiusLevel] == 1)
        return -1;

    if([p isLastWord:POI] || [p isLastWord:POI_TYPE])
        return -1;
    
    if ([p isNoSelectedType])
        return SEARCH_ADDRESS_BY_NAME_API_PRIORITY;
    
    return SEARCH_ADDRESS_BY_NAME_API_PRIORITY_RADIUS2;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    // case when street is not found for given city is covered by SearchStreetByCityAPI
    return [self getSearchPriority:phrase] != -1 && [super isSearchMoreAvailable:phrase];
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getRadiusSearch:DEFAULT_ADDRESS_BBOX_RADIUS];
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getNextRadiusSearch:DEFAULT_ADDRESS_BBOX_RADIUS];
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    if (![phrase isUnknownSearchWordPresent] && ![phrase isEmptyQueryAllowed])
        return NO;
    
    if ([phrase isNoSelectedType] || [phrase getRadiusLevel] >= 2)
    {
        [self initAndSearchCities:phrase resultMatcher:resultMatcher];
        // not publish results (let it sort)
        // resultMatcher.apiSearchFinished(this, phrase);
        [self searchByName:phrase resultMatcher:resultMatcher];
    }
    return YES;
}

- (void) initAndSearchCities:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;

    QuadRect *bbox = [phrase getRadiusBBoxToSearch:DEFAULT_ADDRESS_BBOX_RADIUS * 20];
    NSArray<NSString *> *offlineIndexes = [phrase getOfflineIndexes:bbox dt:P_DATA_TYPE_ADDRESS];
    for (NSString *resId in offlineIndexes)
    {
        if (![_townCities containsObject:resId])
        {
            [_townCities addObject:resId];
            QString rId = QString::fromNSString(resId);
            const auto& r = app.resourcesManager->getLocalResource(rId);
            const auto dataInterface = obfsCollection->obtainDataInterface({r});
            QList< std::shared_ptr<const OsmAnd::StreetGroup> > l;
            dataInterface->loadStreetGroups(&l, nullptr, OsmAnd::ObfAddressStreetGroupTypesMask().set(OsmAnd::ObfAddressStreetGroupType::CityOrTown));
            
            for (const auto& c : l)
            {
                auto city = std::static_pointer_cast<const OsmAnd::StreetGroup>(c);
                _streetGroupResourceIds.insert(city, rId);
                OsmAnd::LatLon cl = OsmAnd::Utilities::convert31ToLatLon(city->position31);
                int y = OsmAnd::Utilities::get31TileNumberY(cl.latitude);
                int x = OsmAnd::Utilities::get31TileNumberX(cl.longitude);
                const OsmAnd::AreaI qr(x, y, x, y);
                _townCitiesQR->insert(city, qr);
            }
        }
    }
    if ([phrase isNoSelectedType] && bbox && ([phrase isUnknownSearchWordPresent] || [phrase isEmptyQueryAllowed]) && [phrase isSearchTypeAllowed:CITY])
    {
        OANameStringMatcher *nm = [phrase getMainUnknownNameStringMatcher];
        _resArray.clear();
        const OsmAnd::AreaI area(bbox.left, bbox.top, bbox.right, bbox.bottom);
        _townCitiesQR->query(area, _resArray);
        LogPrintf(OsmAnd::LogSeverityLevel::Debug,
        "Resulting cities '%d'",
                  _resArray.count());
        int limit = 0;
        for (const auto& c : _resArray)
        {
//            if (phrase.getSettings.isExportObjects)
//                [resultMatcher exportCity:phrase city:c];
            OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
            res.object = [[OACity alloc] initWithCity:c];
            res.resourceId = _streetGroupResourceIds.value(c).toNSString();
            res.localeName = c->getName(QString::fromNSString([[phrase getSettings] getLang]), [[phrase getSettings] isTransliterate]).toNSString();
            if (!c->localizedNames.isEmpty())
            {
                NSMutableArray<NSString *> *names = [NSMutableArray array];
                for (const auto& name : c->localizedNames.values())
                     [names addObject:name.toNSString()];
                res.otherNames = names;
            }
            
            const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(res.resourceId));
            if (r)
            {
                const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(r->metadata);
                if (obfMetadata)
                    res.localeRelatedObjectName = obfMetadata->obfFile->getRegionName().toNSString();
                
                res.relatedResourceId = res.resourceId;
                OsmAnd::LatLon loc = OsmAnd::Utilities::convert31ToLatLon(c->position31);
                res.location = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
                res.priority = SEARCH_ADDRESS_BY_NAME_PRIORITY;
                res.priorityDistance = 0.1;
                res.objectType = CITY;
                if ([phrase isEmptyQueryAllowed] && [phrase isEmpty])
                {
                    [resultMatcher publish:res];
                }
                else if ([nm matches:res.localeName] || [nm matchesMap:res.otherNames])
                {
                    [self subSearchApiOrPublish:phrase resultMatcher:resultMatcher res:res api:_cityApi];
                }
                if (limit++ > LIMIT * [phrase getRadiusLevel])
                    break;
            }
        }
    }
}

- (void) searchByName:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    if ([phrase getRadiusLevel] > 1 || [phrase getUnknownWordToSearch].length > 3 || [phrase hasMoreThanOneUnknownSearchWord] || [phrase isSearchTypeAllowed:POSTCODE exclusive:YES])
    {
        NSString *wordToSearch = [phrase getUnknownWordToSearch];
        if (wordToSearch.length == 0)
            return;

        OsmAndAppInstance app = [OsmAndApp instance];

        QString lang = QString::fromNSString([[phrase getSettings] getLang]);
        bool transliterate = [[phrase getSettings] isTransliterate];
        
        BOOL locSpecified = [phrase getLastTokenLocation] != nil;
        CLLocation *loc = [phrase getLastTokenLocation];
        NSMutableArray<OASearchResult *> *immediateResults = [NSMutableArray array];
        QuadRect *streetBbox = [phrase getRadiusBBoxToSearch:DEFAULT_ADDRESS_BBOX_RADIUS];
        QuadRect *postcodeBbox = [phrase getRadiusBBoxToSearch:DEFAULT_ADDRESS_BBOX_RADIUS * 5];
        QuadRect *villagesBbox = [phrase getRadiusBBoxToSearch:DEFAULT_ADDRESS_BBOX_RADIUS * 3];
        QuadRect *cityBbox = [phrase getRadiusBBoxToSearch:DEFAULT_ADDRESS_BBOX_RADIUS * 5]; // covered by separate search before
        int priority = [phrase isNoSelectedType] ? SEARCH_ADDRESS_BY_NAME_PRIORITY : SEARCH_ADDRESS_BY_NAME_PRIORITY_RADIUS2;
        
        NSString *currentResId;
        NSString *currentRegionName;
        NSArray<NSString *> *offlineIndexes = [phrase getRadiusOfflineIndexes:DEFAULT_ADDRESS_BBOX_RADIUS * 5 dt:P_DATA_TYPE_ADDRESS];
        
        const auto& obfsCollection = app.resourcesManager->obfsCollection;
        const auto search = std::shared_ptr<const OsmAnd::AddressesByNameSearch>(new OsmAnd::AddressesByNameSearch(obfsCollection));
        
        int limit = 0;
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([self, limit, &phrase, &resultMatcher]
                                                      (const OsmAnd::IQueryController* const controller)
                                                      {
                                                          return limit > LIMIT * [phrase getRadiusLevel] || [resultMatcher isCancelled];
                                                      }));

        const std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AddressesByNameSearch::Criteria>(new OsmAnd::AddressesByNameSearch::Criteria);
        
        searchCriteria->name = QString::fromNSString([wordToSearch lowerCase]);
        searchCriteria->includeStreets = true;
        searchCriteria->matcherMode = [phrase isMainUnknownSearchWordComplete] ? OsmAnd::StringMatcherMode::CHECK_EQUALS_FROM_SPACE : OsmAnd::StringMatcherMode::CHECK_STARTS_FROM_SPACE;
        
        if (locSpecified)
        {
            searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters([phrase getRadiusSearch:DEFAULT_ADDRESS_BBOX_RADIUS * 5], OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(loc.coordinate.latitude, loc.coordinate.longitude)));
        }
        
        for (NSString *resId in offlineIndexes)
        {
            currentResId = resId;
            [immediateResults removeAllObjects];
            
            const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(resId));
            const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(r->metadata);
            if (obfMetadata)
                currentRegionName = obfMetadata->obfFile->getRegionName().toNSString();
            
            searchCriteria->localResources = {r};

            search->performSearch(*searchCriteria,
                                  [self, &limit, &ctrl, &phrase, &currentResId, priority, &lang, transliterate, currentRegionName, locSpecified, &streetBbox, &postcodeBbox, &villagesBbox, &cityBbox, &immediateResults]
                                  (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                      if (ctrl->isAborted())
                                          return NO;
                                      
                                      const auto& address = ((OsmAnd::AddressesByNameSearch::ResultEntry&)resultEntry).address;
                                      
                                      OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
                                      sr.resourceId = currentResId;
                                      sr.localeName = address->getName(lang, transliterate).toNSString();
                                      sr.otherNames = [OASearchCoreFactory getAllNames:address->localizedNames nativeName:address->nativeName];
                                      sr.localeRelatedObjectName = currentRegionName;
                                      sr.relatedResourceId = sr.resourceId;
                                      sr.location = [OASearchCoreFactory getLocation:address->position31];
                                      sr.priorityDistance = 1;
                                      sr.priority = priority;
                                      int y = address->position31.y;
                                      int x = address->position31.x;
                                      QList<std::shared_ptr<const OsmAnd::StreetGroup>> closestCities;
                                      BOOL closestCitiesRequested = NO;
                                      if (address->addressType == OsmAnd::AddressType::Street)
                                      {
                                          // remove limitation by location
                                          if (//(locSpecified && ![streetBbox contains:x top:y right:x bottom:y]) ||
                                              ![phrase isSearchTypeAllowed:STREET])
                                              return NO;
                                          
                                          if (address->nativeName.startsWith("<"))
                                              return NO;
                                          
                                          if (![[phrase getUnknownWordToSearchBuildingNameMatcher] matches:[OASearchCoreFactory stripBraces:sr.localeName]])
                                              sr.priorityDistance = 5;
                                          
                                          const auto& street = std::dynamic_pointer_cast<const OsmAnd::Street>(address);
                                          sr.object = [[OAStreet alloc] initWithStreet:street];
                                          sr.objectType = STREET;
                                          sr.localeRelatedObjectName = street->streetGroup->getName(lang, transliterate).toNSString();
                                          sr.relatedObject = [[OACity alloc] initWithCity:street->streetGroup];
                                      }
                                      else if (address->addressType == OsmAnd::AddressType::StreetGroup)
                                      {
                                          const auto& city = std::dynamic_pointer_cast<const OsmAnd::StreetGroup>(address);
                                          sr.object = [[OACity alloc] initWithCity:city];
                                          if (city->type == OsmAnd::ObfAddressStreetGroupType::CityOrTown)
                                          {
                                              if ([phrase isNoSelectedType])
                                                  return NO; // ignore city/town
                                              
                                              if ((locSpecified && ![cityBbox contains:x top:y right:x bottom:y]) || ![phrase isSearchTypeAllowed:CITY])
                                                  return NO;
                                              
                                              sr.objectType = CITY;
                                              sr.priorityDistance = 0.1;
                                          }
                                          else if (city->type == OsmAnd::ObfAddressStreetGroupType::Postcode)
                                          {
                                              if ((locSpecified && ![postcodeBbox contains:x top:y right:x bottom:y]) || ![phrase isSearchTypeAllowed:POSTCODE])
                                                  return NO;
                                              
                                              sr.objectType = POSTCODE;
                                              sr.priorityDistance = 0.0;
                                          }
                                          else
                                          {
                                              if ((locSpecified && ![villagesBbox contains:x top:y right:x bottom:y]) || ![phrase isSearchTypeAllowed:VILLAGE])
                                                  return NO;
                                              
                                              std::shared_ptr<const OsmAnd::StreetGroup> c;
                                              if (!closestCitiesRequested)
                                              {
                                                  const OsmAnd::AreaI villagesArea(villagesBbox.left, villagesBbox.top, villagesBbox.right, villagesBbox.bottom);
                                                  _townCitiesQR->query(villagesArea, closestCities);
                                                  closestCitiesRequested = YES;
                                              }
                                              double minDist = -1;
                                              double pDist = -1;
                                              for(auto& s : closestCities)
                                              {
                                                  double ll = OsmAnd::Utilities::distance31(s->position31, address->position31);
                                                  double pd = s->subtype == OsmAnd::ObfAddressStreetGroupSubtype::City ? ll : ll * 10;
                                                  if (minDist == -1 || pd < pDist)
                                                  {
                                                      c = s;
                                                      minDist = ll;
                                                      pDist = pd ;
                                                  }
                                              }
                                              if (c)
                                              {
                                                  sr.localeRelatedObjectName = c->getName(lang, transliterate).toNSString();
                                                  sr.relatedObject = [[OACity alloc] initWithCity:c];
                                                  sr.distRelatedObjectName = minDist;
                                              }
                                              sr.objectType = VILLAGE;
                                          }
                                      }
                                      else
                                      {
                                          return NO;
                                      }
                                      limit++;
                                      [immediateResults addObject:sr];
                                      return NO;
                                  },
                                  ctrl);
            
            for (OASearchResult *res in immediateResults)
            {
                if ([resultMatcher isCancelled])
                    break;
                
                if (res.objectType == STREET)
                {
                    [self subSearchApiOrPublish:phrase resultMatcher:resultMatcher res:res api:_streetsApi];
                } else {
                    [self subSearchApiOrPublish:phrase resultMatcher:resultMatcher res:res api:_cityApi];
                }
            }
            
            if (![resultMatcher isCancelled])
                [resultMatcher apiSearchRegionFinished:self resourceId:resId phrase:phrase];
        }
    }
}

@end


@interface OASearchAmenityByNameAPI ()

@end

@implementation OASearchAmenityByNameAPI
{
    int LIMIT;
    int BBOX_RADIUS;
    int BBOX_RADIUS_INSIDE; // to support city search for basemap
    int FIRST_WORD_MIN_LENGTH;
    OAPOIHelper *_types;
}

- (instancetype) init
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:POI]]];
    if (self)
    {
        LIMIT = 10000;
        BBOX_RADIUS = 500 * 1000;
        BBOX_RADIUS_INSIDE = 10000 * 1000;
        FIRST_WORD_MIN_LENGTH = 3;
        _types = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getRadiusSearch:BBOX_RADIUS];
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getNextRadiusSearch:BBOX_RADIUS];
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    if (![phrase isUnknownSearchWordPresent])
        return NO;
    
    // don't search by name when type is selected or poi type is part of name
    if (![phrase isNoSelectedType])
        return NO;
    // Take into account POI [bar] - 'Hospital 512'
    // BEFORE: it was searching exact match of whole phrase.getUnknownSearchPhrase() [ Check feedback ]
    
    OsmAndAppInstance app = [OsmAndApp instance];
    QString lang = QString::fromNSString([[phrase getSettings] getLang]);
    bool transliterate = [[phrase getSettings] isTransliterate];

    NSString *currentResId;
    NSArray<NSString *> *offlineIndexes = [phrase getRadiusOfflineIndexes:BBOX_RADIUS dt:P_DATA_TYPE_POI];
    NSMutableSet<NSString *> *ids = [NSMutableSet new];

    NSString *searchWord = [phrase getUnknownWordToSearch];
    OANameStringMatcher *nm = [phrase getMainUnknownNameStringMatcher];
    
    QuadRect *bbox = [phrase getRadiusBBoxToSearch:BBOX_RADIUS_INSIDE];
    
    int limit = 0;
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, limit, &phrase, &resultMatcher]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return [resultMatcher isCancelled] && (limit < LIMIT);
                                                  }));

    const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(searchWord);
    searchCriteria->bbox31 = OsmAnd::AreaI(bbox.top, bbox.left, bbox.bottom, bbox.right);
    searchCriteria->xy31 = OsmAnd::PointI(bbox.centerX, bbox.centerY);
    
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));

    for (NSString *resId in offlineIndexes)
    {
        currentResId = resId;
        
        const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(resId));
        searchCriteria->localResources = {r};

        search->performSearch(*searchCriteria,
                              [self, &limit, &phrase, &lang, transliterate, &nm, &currentResId, &resultMatcher, &ids]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  if (limit++ > LIMIT)
                                      return false;
                                  
                                  const auto& amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  
                                  NSString *poiID = [NSString stringWithFormat:@"%@_%lld", amenity->type.toNSString(), amenity->id.id];
                                  if ([ids containsObject:poiID])
                                      return false;
                                  
                                  OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
                                  OAPOI *object = [OAPOIHelper parsePOIByAmenity:amenity];
                                  sr.object = object;
                                  sr.otherNames = [OASearchCoreFactory getAllNames:amenity->localizedNames nativeName:amenity->nativeName];
                                  sr.localeName = amenity->getName(lang, transliterate).toNSString();
                                  if (![nm matches:sr.localeName] && ![nm matchesMap:sr.otherNames]
                                      && ![nm matchesMap:object.getAdditionalInfo.allValues]) {
                                      return false;
                                  }
            /*
                                  if (sr.localeName.length == 0)
                                  {
                                      OAPOIBaseType *st = [_types getAnyPoiTypeByName:amenity->subType.toNSString()];
                                      if (st)
                                          sr.localeName = st.nameLocalized;
                                      else
                                          sr.localeName = amenity->subType.toNSString();
                                  }
             */
                                  sr.amenity = amenity;
                                  sr.preferredZoom = 17;
                                  sr.resourceId = currentResId;
                                  sr.location = [OASearchCoreFactory getLocation:amenity->position31];
                                  
                                  if (amenity->subType == QStringLiteral("city") ||
                                      amenity->subType == QStringLiteral("country"))
                                  {
                                      sr.priorityDistance = SEARCH_AMENITY_BY_NAME_CITY_PRIORITY_DISTANCE;
                                      sr.preferredZoom = amenity->subType == QStringLiteral("country") ? 7 : 13;
                                  }
                                  else if (amenity->subType == QStringLiteral("town"))
                                  {
                                      sr.priorityDistance = SEARCH_AMENITY_BY_NAME_TOWN_PRIORITY_DISTANCE;
                                  }
                                  else
                                  {
                                      sr.priorityDistance = 1;
                                  }
                                  sr.priority = SEARCH_AMENITY_BY_NAME_PRIORITY;
                                  [phrase countUnknownWordsMatchMainResult:sr];
                                  
                                  sr.objectType = POI;
                                  [resultMatcher publish:sr];
                                  [ids addObject:poiID];
                                  return false;
                              },
                              ctrl);

        if (![resultMatcher isCancelled])
            [resultMatcher apiSearchRegionFinished:self resourceId:resId phrase:phrase];
    }

    return true;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if ([p hasObjectType:POI] || ![p isUnknownSearchWordPresent])
        return -1;
    
    if ([p hasObjectType:POI_TYPE])
        return -1;
    
    if ([p getUnknownWordToSearch].length >= FIRST_WORD_MIN_LENGTH || [p isFirstUnknownSearchWordComplete])
        return SEARCH_AMENITY_BY_NAME_API_PRIORITY_IF_3_CHAR;
    
    return -1;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return [super isSearchMoreAvailable:phrase] && [self getSearchPriority:phrase] != -1;
}

@end

@interface OAPoiTypeResult : NSObject

@property (nonatomic) OAPOIBaseType *pt;
@property (nonatomic) NSMutableOrderedSet<NSString *> *foundWords;

@end

@implementation OAPoiTypeResult

- (instancetype) init
{
    self = [super init];
    if (self) {
        _foundWords = [NSMutableOrderedSet new];
    }
    return self;
}

@end


@interface OASearchAmenityTypesAPI ()

@end

@implementation OASearchAmenityTypesAPI
{
    NSArray<OAPOIBaseType *> *_topVisibleFilters;
    NSArray<OAPOICategory *> *_categories;
    NSMutableArray<OACustomSearchPoiFilter *> *_customPoiFilters;
    NSMutableDictionary<NSString *, NSNumber *> *_activePoiFilters;
    NSDictionary<NSString *, OAPOIType *> *_translatedNames;
    OAPOIHelper *_types;
}

- (instancetype) init
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:POI_TYPE]]];
    if (self)
    {
        _types = [OAPOIHelper sharedInstance];
        _customPoiFilters = [NSMutableArray array];
        _activePoiFilters = [NSMutableDictionary new];
        _topVisibleFilters = [_types getTopVisibleFilters];
        _categories = _types.poiCategoriesNoOther;
        _translatedNames = [NSDictionary new];
    }
    return self;
}

- (void) initPoiTypes
{
    if (_translatedNames.count == 0)
    {
        _translatedNames = [_types getAllTranslatedNames:NO];
        NSMutableArray<OAPOIBaseType *> *topVisibleFilters = [NSMutableArray arrayWithArray:_types.getTopVisibleFilters];
        [topVisibleFilters removeObject:_types.getOsmwiki];
        _topVisibleFilters = topVisibleFilters;
        _categories = [_types getCategories:NO];
    }
}

- (void) clearCustomFilters
{
    [_customPoiFilters removeAllObjects];
    [_activePoiFilters removeAllObjects];
}

- (void) addCustomFilter:(OACustomSearchPoiFilter *)poiFilter priority:(int)priority
{
    [_customPoiFilters addObject:poiFilter];
    if (priority > 0)
        [_activePoiFilters setObject:[NSNumber numberWithInt:priority] forKey:poiFilter.getFilterId];
}

- (void) setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrder
{
    for (int i = 0; i < filterOrder.count; i++)
    {
        [_activePoiFilters setObject:[NSNumber numberWithInt:i] forKey:filterOrder[i]];
    }
}

- (NSDictionary<NSString *, OAPoiTypeResult *> *) getPoiTypeResults:(OANameStringMatcher *)nm additionalMatcher:(OANameStringMatcher *)nmAdditional
{
    MutableOrderedDictionary<NSString *, OAPoiTypeResult *> *results = [MutableOrderedDictionary new];
    for (OAPOIBaseType *pf in _topVisibleFilters)
    {
        OAPoiTypeResult *res = [self checkPoiType:nm type:pf];
        if(res)
            results[res.pt.name] = res;
    }
    // don't spam results with unsearchable additionals like 'description', 'email', ...
    //if (nmAdditional)
    //    [self addAditonals:nmAdditional results:results type:_types.otherMapCategory];
    
    for (OAPOICategory *c in _categories)
    {
        OAPoiTypeResult *res = [self checkPoiType:nm type:c];
        if(res)
            results[res.pt.name] = res;
        if (nmAdditional != nil)
            [self addAditonals:nmAdditional results:results type:c];
    }
    [_translatedNames enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, OAPOIType * _Nonnull pt, BOOL * _Nonnull stop) {
        if (![pt.category isEqual:_types.otherMapCategory] && !pt.isReference)
        {
            OAPoiTypeResult *res = [self checkPoiType:nm type:pt];
            if(res != nil)
                results[res.pt.name] = res;
            if (nmAdditional != nil)
                [self addAditonals:nmAdditional results:results type:pt];
        }
    }];
    return results;
}

- (void) addAditonals:(OANameStringMatcher *) nm results:(MutableOrderedDictionary *)results type:(OAPOIBaseType *)pt
{
    NSArray<OAPOIType *> *additionals = pt.poiAdditionals;
    if (additionals != nil)
    {
        for (OAPOIType *a in additionals)
        {
            OAPoiTypeResult *existingResult = results[a.name];
            if (existingResult != nil) {
                OAPoiAdditionalCustomFilter *f;
                if ([existingResult.pt isKindOfClass:OAPoiAdditionalCustomFilter.class])
                    f = (OAPoiAdditionalCustomFilter *) existingResult.pt;
                else
                    f = [[OAPoiAdditionalCustomFilter alloc] initWithType:(OAPOIType *)existingResult.pt];
                
                [f.additionalPoiTypes addObject:a];
                existingResult.pt = f;
            }
            else
            {
                NSString *enTranslation = [a.nameLocalizedEN lowerCase];
                if (![@"no" isEqualToString:enTranslation]) // && !"yes".equals(enTranslation))
                {
                    OAPoiTypeResult *ptr = [self checkPoiType:nm type:a];
                    if (ptr != nil)
                        results[a.name] = ptr;
                }
            }
        }
    }
}

- (OAPoiTypeResult *) checkPoiType:(OANameStringMatcher *)nm type:(OAPOIBaseType *)pf
{
    OAPoiTypeResult *res = nil;
    if ([nm matches:pf.nameLocalized])
        res = [self addIfMatch:nm name:pf.nameLocalized type:pf res:res];
    
    if ([nm matches:pf.nameLocalizedEN])
        res = [self addIfMatch:nm name:pf.nameLocalizedEN type:pf res:res];
    
    if ([nm matches:pf.name])
        res = [self addIfMatch:nm name:[pf.name stringByReplacingOccurrencesOfString:@"_" withString:@" "] type:pf res:res];

    if ([nm matches:pf.nameSynonyms])
    {
        NSArray<NSString *> *synonyms = [pf.nameSynonyms componentsSeparatedByString:@";"];
        for (NSString *synonym in synonyms)
        {
            res = [self addIfMatch:nm name:synonym type:pf res:res];
        }
    }
    return res;
}

- (OAPoiTypeResult *) addIfMatch:(OANameStringMatcher *) nm name:(NSString *) s type:(OAPOIBaseType *)pf res:(OAPoiTypeResult *) res
{
    if ([nm matches:s])
    {
        if (res == nil) {
            res = [[OAPoiTypeResult alloc] init];
            res.pt = pf;
        }
        [res.foundWords addObject:s];
    }
    return res;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    BOOL showTopFiltersOnly = !phrase.isUnknownSearchWordPresent;
    OANameStringMatcher *nm = phrase.getFirstUnknownNameStringMatcher;
    
    [self initPoiTypes];
    if (showTopFiltersOnly)
    {
        for (OAPOIBaseType *pt in _topVisibleFilters)
        {
            OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
            res.localeName = pt.nameLocalized;
            res.object = pt;
            [self addPoiTypeResult:phrase resultMatcher:resultMatcher topFiltersOnly:showTopFiltersOnly stdFilterId:[self getStandardFilterId:pt] searchResult:res];
        }
    }
    else
    {
        BOOL includeAdditional = ![phrase hasMoreThanOneUnknownSearchWord];
        OANameStringMatcher *nmAdditional = includeAdditional ? [[OANameStringMatcher alloc] initWithNamePart:phrase.getFirstUnknownSearchWord mode:CHECK_EQUALS_FROM_SPACE] : nil;
        NSDictionary<NSString *, OAPoiTypeResult *> *poiTypes = [self getPoiTypeResults:nm additionalMatcher:nmAdditional];
        for (OAPoiTypeResult *ptr in poiTypes.allValues)
        {
            BOOL match = ![phrase isFirstUnknownSearchWordComplete];
            if (!match)
            {
                for (NSString *foundName in ptr.foundWords)
                {
                    OACollatorStringMatcher *csm = [[OACollatorStringMatcher alloc] initWithPart:foundName mode:CHECK_ONLY_STARTS_WITH];
                    match = [csm matches:phrase.getUnknownSearchPhrase];
                    if (match)
                        break;
                }
            }
            if (match)
            {
                OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
                res.localeName = ptr.pt.nameLocalized;
                res.object = ptr.pt;
                [self addPoiTypeResult:phrase resultMatcher:resultMatcher topFiltersOnly:showTopFiltersOnly stdFilterId:[self getStandardFilterId:ptr.pt] searchResult:res];
            }
        }
    }
    for (NSInteger i = 0; i < _customPoiFilters.count; i++)
    {
        OACustomSearchPoiFilter *csf = _customPoiFilters[i];
        if (showTopFiltersOnly || [nm matches:csf.getName])
        {
            OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
            res.localeName = csf.getName;
            res.object = csf;
            [self addPoiTypeResult:phrase resultMatcher:resultMatcher topFiltersOnly:showTopFiltersOnly stdFilterId:csf.getFilterId searchResult:res];
        }
    }
    return YES;
}

- (void) addPoiTypeResult:(OASearchPhrase *) phrase resultMatcher:(OASearchResultMatcher *)resultMatcher topFiltersOnly:(BOOL)showTopFiltersOnly
                              stdFilterId:(NSString *)stdFilterId searchResult:(OASearchResult *)res
{
    res.priorityDistance = 0;
    res.objectType = POI_TYPE;
    res.firstUnknownWordMatches = YES;
    if (showTopFiltersOnly)
    {
        if ([_activePoiFilters.allKeys containsObject:stdFilterId])
        {
            res.priority = [self getPoiTypePriority:stdFilterId];
            [resultMatcher publish:res];
        }
    }
    else
    {
        [phrase countUnknownWordsMatchMainResult:res];
        res.priority = SEARCH_AMENITY_TYPE_PRIORITY;
        [resultMatcher publish:res];
    }
}

- (int) getPoiTypePriority:(NSString *) stdFilterId
{
    NSNumber *i = _activePoiFilters[stdFilterId];
    if (i == nil)
        return SEARCH_AMENITY_TYPE_PRIORITY;
    return SEARCH_AMENITY_TYPE_PRIORITY + i.intValue;
}

- (NSString *) getStandardFilterId:(OAPOIBaseType *)poi
{
    return [STD_POI_FILTER_PREFIX stringByAppendingString:poi.name];
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if ([p hasObjectType:POI] || [p hasObjectType:POI_TYPE])
        return -1;
    
    if (![p isNoSelectedType] && ![p isUnknownSearchWordPresent])
        return -1;
    
    OASearchWord *lastSelectedWord = [p getLastSelectedWord];
    if (lastSelectedWord && [OAObjectType isAddress:[lastSelectedWord getType]])
        return -1;
    
    return SEARCH_AMENITY_TYPE_API_PRIORITY;
}

@end


@interface OASearchAmenityByTypeAPI ()

@end

@implementation OASearchAmenityByTypeAPI
{
    int BBOX_RADIUS;
    int BBOX_RADIUS_NEAREST;
    OASearchAmenityTypesAPI *_typesAPI;
    OAPOIHelper *_types;
    NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *_acceptedTypes;

    std::shared_ptr<const OsmAnd::Amenity> _currentAmenity;
    QString _lang;
    bool _transliterate;
    
    OAPOIBaseType *_unselectedPoiType;
    NSString *_nameFilter;
}

- (instancetype) initWithTypesAPI:(OASearchAmenityTypesAPI *)typesAPI
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:POI]]];
    if (self)
    {
        BBOX_RADIUS = 10000;
        BBOX_RADIUS_NEAREST = 1000;
        _types = [OAPOIHelper sharedInstance];
        _acceptedTypes = [NSMapTable strongToStrongObjectsMapTable];
        _typesAPI = typesAPI;
    }
    return self;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return [self getSearchPriority:phrase] != -1 && [super isSearchMoreAvailable:phrase];
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getRadiusSearch:BBOX_RADIUS];
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getNextRadiusSearch:BBOX_RADIUS];
}

- (void) updateTypesToAccept:(OAPOIBaseType *)pt
{
    [pt putTypes:_acceptedTypes];
    if ([pt isKindOfClass:[OAPOIType class]] && [((OAPOIType *)pt) isAdditional] && ((OAPOIType *)pt).parentType)
        [self fillPoiAdditionals:((OAPOIType *)pt).parentType];
    else
        [self fillPoiAdditionals:pt];
}

- (void) fillPoiAdditionals:(OAPOIBaseType *)pt
{
    if ([pt isKindOfClass:[OAPOIFilter class]])
    {
        for (OAPOIType *ps in ((OAPOIFilter *)pt).poiTypes)
            [self fillPoiAdditionals:ps];
    }
}

- (OAPOIBaseType *) getUnselectedPoiType
{
    return _unselectedPoiType;
}

- (NSString *) getNameFilter
{
    return _nameFilter;
}

- (void)searchPoi:(int)countExtraWords nameFilter:(NSString *)nameFilter phrase:(OASearchPhrase *)phrase poiAdditionals:(NSMutableOrderedSet<NSString *> *)poiAdditionals poiTypeFilter:(OASearchPoiTypeFilter *)poiTypeFilter resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    NSMutableSet<NSString *> *searchedPois = [NSMutableSet new];
    OsmAndAppInstance app = [OsmAndApp instance];
    _lang = QString::fromNSString([[phrase getSettings] getLang]);
    _transliterate = [[phrase getSettings] isTransliterate];
    
    int radius = BBOX_RADIUS;
    if (phrase.getRadiusLevel == 1 && [poiTypeFilter isKindOfClass:OACustomSearchPoiFilter.class])
    {
        NSString *name = ((OACustomSearchPoiFilter *) poiTypeFilter).getFilterId;
        if ([@"std_" isEqualToString:name])
            radius = BBOX_RADIUS_NEAREST;
    }
    QuadRect *bbox = [phrase getRadiusBBoxToSearch:radius];
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &resultMatcher]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
        return [resultMatcher isCancelled];
    }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    
    NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *acceptedTypes = [poiTypeFilter getAcceptedTypes];
    NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *acceptedTypesOrigin = [poiTypeFilter getAcceptedTypesOrigin];

    for (OAPOICategory *category in acceptedTypesOrigin)
    {
        NSMutableSet<NSString *> *typesOrigin = [acceptedTypesOrigin objectForKey:category];
        if (![typesOrigin isEqualToSet:[acceptedTypes objectForKey:category]])
            [acceptedTypes setObject:typesOrigin forKey:category];
    }

    if (acceptedTypes.count > 0)
    {
        auto categoriesFilter = QHash<QString, QStringList>();
        for (OAPOICategory *category in acceptedTypes.keyEnumerator)
        {
            NSMutableSet<NSString *> *subcategories = [acceptedTypes objectForKey:category];
            QString categoryName = QString::fromNSString(category.name);
            if (subcategories != [OAPOIBaseType nullSet] && subcategories.count > 0)
            {
                QStringList subcatList;
                for (NSString *subcategory in subcategories)
                    subcatList.push_back(QString::fromNSString(subcategory));
                
                categoriesFilter.insert(categoryName, subcatList);
            }
            else
            {
                categoriesFilter.insert(categoryName, QStringList());
            }
        }
        searchCriteria->categoriesFilter = categoriesFilter;
    }
    searchCriteria->bbox31 = OsmAnd::AreaI(bbox.top, bbox.left, bbox.bottom, bbox.right);
    
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    
    NSArray<NSString *> *offlineIndexes = [phrase getOfflineIndexes];
    for (NSString *resId in offlineIndexes)
    {
        OAResultMatcher<OAPOI *> *rm = [self getResultMatcher:phrase resultMatcher:resultMatcher nameFilter:nameFilter resourceId:resId searchedPois:searchedPois poiAdditionals:poiAdditionals countExtraWords:countExtraWords];
        if([poiTypeFilter isKindOfClass:[OACustomSearchPoiFilter class]])
            rm = [((OACustomSearchPoiFilter *)poiTypeFilter) wrapResultMatcher:rm];
        
        const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(resId));
        searchCriteria->localResources = {r};
        
        search->performSearch(*searchCriteria,
                              [self, &rm]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
            const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
            OAPOI *poi = [OAPOIHelper parsePOIByAmenity:amenity];
            if (poi)
            {
                _currentAmenity = amenity;
                [rm publish:poi];
            }
        },
                              ctrl);
        
        if (![resultMatcher isCancelled])
            [resultMatcher apiSearchRegionFinished:self resourceId:resId phrase:phrase];
        
    }
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    _unselectedPoiType = nil;
    OASearchPoiTypeFilter *poiTypeFilter = nil;
    NSString *nameFilter = nil;
    int countExtraWords = 0;
    NSMutableOrderedSet<NSString *> *poiAdditionals = [NSMutableOrderedSet new];
    if ([phrase isLastWord:POI_TYPE])
    {
        NSObject *obj = phrase.getLastSelectedWord.result.object;
        if ([obj isKindOfClass:OAPOIBaseType.class])
            poiTypeFilter = [self getPoiTypeFilter:(OAPOIBaseType *)obj poiAdditionals:poiAdditionals];
        else if ([obj isKindOfClass:OASearchPoiTypeFilter.class])
            poiTypeFilter = (OASearchPoiTypeFilter *) obj;
        else
            @throw [NSException exceptionWithName:@"UnsupportedOperationException" reason:@"Incorrect last result" userInfo:nil];
        
        nameFilter = phrase.getUnknownSearchPhrase;
    }
    else if (_typesAPI != nil && phrase.isFirstUnknownSearchWordComplete)
    {
        OANameStringMatcher *nm = phrase.getFirstUnknownNameStringMatcher;
        OANameStringMatcher *nmAdditional = [[OANameStringMatcher alloc] initWithNamePart:phrase.getFirstUnknownSearchWord mode:CHECK_EQUALS_FROM_SPACE];
        
        [_typesAPI initPoiTypes];
        NSDictionary<NSString *, OAPoiTypeResult *> *poiTypeResults = [_typesAPI getPoiTypeResults:nm additionalMatcher:nmAdditional];
        // find first full match only
        for (OAPoiTypeResult *poiTypeResult in poiTypeResults.allValues)
        {
            for (NSString *foundName in poiTypeResult.foundWords)
            {
                OACollatorStringMatcher *csm = [[OACollatorStringMatcher alloc] initWithPart:foundName mode:CHECK_ONLY_STARTS_WITH];
                // matches only completely
                int mwords = [phrase countWords:foundName];
                if ([csm matches:phrase.getUnknownSearchPhrase] && countExtraWords < mwords)
                {
                    countExtraWords = [phrase countWords:foundName];
                    NSArray<NSString *> *otherSearchWords = phrase.getUnknownSearchWords;
                    nameFilter = nil;
                    if (countExtraWords - 1 < otherSearchWords.count)
                    {
                        nameFilter = @"";
                        for(NSInteger k = countExtraWords - 1; k < otherSearchWords.count; k++)
                        {
                            if (nameFilter.length > 0)
                                nameFilter = [nameFilter stringByAppendingString:@" "];
                            
                            nameFilter = [nameFilter stringByAppendingString:otherSearchWords[k]];
                        }
                    }
                    poiTypeFilter = [self getPoiTypeFilter:poiTypeResult.pt poiAdditionals:poiAdditionals];
                    _unselectedPoiType = poiTypeResult.pt;
                    int wordsInPoiType = [phrase countWords:foundName];
                    int wordsInUnknownPart = [phrase countWords:phrase.getUnknownSearchPhrase];
                    if (wordsInPoiType == wordsInUnknownPart)
                    {
                        // store only perfect match
                        [phrase setUnselectedPoiType:_unselectedPoiType];
                    }
                }
            }
        }
    }
    _nameFilter = nameFilter;
    if (poiTypeFilter != nil)
    {
        [self searchPoi:countExtraWords nameFilter:nameFilter phrase:phrase poiAdditionals:poiAdditionals poiTypeFilter:poiTypeFilter resultMatcher:resultMatcher];
    }
    return YES;
}

- (OAResultMatcher<OAPOI *> *) getResultMatcher:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher nameFilter:(NSString *)nameFilter resourceId:(NSString *)selected searchedPois:(NSMutableSet<NSString *> *)searchedPois poiAdditionals:(NSOrderedSet<NSString *> *)poiAdditionals countExtraWords:(const int)countExtraWords
{
    OANameStringMatcher *ns = nameFilter == nil ? nil : [[OANameStringMatcher alloc] initWithNamePart:nameFilter mode:CHECK_STARTS_FROM_SPACE];
    
    return [[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *poi) {
//        if (phrase.getSettings.isExportObjects)
//            [resultMatcher exportObject:phrase object:poi];
        OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
        NSString *poiID = [NSString stringWithFormat:@"%@_%llu", (*poi).type.name, (*poi).obfId];
        if ([searchedPois containsObject:poiID])
            return NO;
        [searchedPois addObject:poiID];
        if ([*poi isClosed])
            return NO;
        
        if (poiAdditionals.count > 0)
        {
            BOOL found = NO;
            for (NSString *add in poiAdditionals)
            {
                if ((*poi).values[add] != nil)
                {
                    found = YES;
                    break;
                }
            }
            if (!found)
                return NO;
        }
        
        res.localeName = _currentAmenity->getName(_lang, _transliterate).toNSString();
        res.otherNames = [OASearchCoreFactory getAllNames:_currentAmenity->localizedNames nativeName:_currentAmenity->nativeName];
        if (res.localeName.length == 0)
        {
            OAPOIBaseType *st = [_types getAnyPoiTypeByName:_currentAmenity->subType.toNSString()];
            if (st)
                res.localeName = st.nameLocalized;
            else
                res.localeName = _currentAmenity->subType.toNSString();
        }
        if (ns)
        {
            if ([ns matches:res.localeName] || [ns matchesMap:res.otherNames])
            {
                [phrase countUnknownWordsMatchMainResult:res matchingWordsCount:countExtraWords];
            }
            else
            {
                NSString *ref = [*poi getTagContent:OSM_REF_TAG lang:nil];
                if (!ref || ![ns matches:ref])
                {
                    return NO;
                }
                else
                {
                    [phrase countUnknownWordsMatch:res localeName:ref otherNames:nil matchingWordsCount:countExtraWords];
                    res.localeName = [NSString stringWithFormat:@"%@ %@", res.localeName, ref];
                }
            }
        }
        else
        {
            [phrase countUnknownWordsMatch:res localeName:@"" otherNames:nil matchingWordsCount:countExtraWords];
        }
        
        res.object = *poi;
        res.preferredZoom = 17;
        res.resourceId = selected;
        res.location = [OASearchCoreFactory getLocation:_currentAmenity->position31];
        res.priority = SEARCH_AMENITY_BY_TYPE_PRIORITY;
        res.priorityDistance = 1;
        res.objectType = POI;
        res.amenity = qMove(_currentAmenity);
        
        [resultMatcher publish:res];
        return false;
    
    } cancelledFunc:^BOOL{
        
        return [resultMatcher isCancelled];
    }];
}

- (OASearchPoiTypeFilter *) getPoiTypeFilter:(OAPOIBaseType *)pt poiAdditionals:(NSMutableOrderedSet<NSString *> *)poiAdditionals
{
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypes = [NSMapTable strongToStrongObjectsMapTable];
    [pt putTypes:acceptedTypes];
    [poiAdditionals removeAllObjects];
    if (pt.isAdditional)
        [poiAdditionals addObject:pt.name];
    
    return [[OASearchPoiTypeFilter alloc] initWithAcceptFunc:^BOOL(OAPOICategory *type, NSString *subcategory) {

        if (!type)
            return YES;
        
        if (![_types isRegisteredType:type])
            type = _types.otherPoiCategory;
        
        NSSet<NSString *> *set = [acceptedTypes objectForKey:type];
        if (!set)
            return NO;
        
        if (set == [OAPOIBaseType nullSet])
            return YES;
        
        return [set containsObject:subcategory];
    
    } emptyFunction:^BOOL{
        
        return NO;
        
    } getTypesFunction:^NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *{
        return acceptedTypes;
    }];
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (([p isLastWord:POI_TYPE] && [p getLastTokenLocation]) || [p isNoSelectedType])
        return SEARCH_AMENITY_BY_TYPE_PRIORITY;
    
    return -1;
}

@end


@interface OASearchBuildingAndIntersectionsByStreetAPI ()

@end

@implementation OASearchBuildingAndIntersectionsByStreetAPI
{
    std::shared_ptr<const OsmAnd::Street> _cacheBuilding;
}

- (instancetype) init
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:HOUSE],
                                        [OAObjectType withType:STREET_INTERSECTION]]];
    if (self)
    {
    }
    return self;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OsmAndAppInstance app = [OsmAndApp instance];
    QString lang = QString::fromNSString([[phrase getSettings] getLang]);
    bool transliterate = [[phrase getSettings] isTransliterate];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::Street> s;
    int priority = SEARCH_BUILDING_BY_STREET_PRIORITY;
    if ([phrase isLastWord:STREET])
        s = ((OAStreet *)phrase.getLastSelectedWord.result.object).street;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &resultMatcher]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return [resultMatcher isCancelled];
                                                  }));

    if ([OASearchCoreFactory isLastWordCityGroup:phrase])
    {
        const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(phrase.getLastSelectedWord.result.resourceId));
        const auto& dataInterface = obfsCollection->obtainDataInterface({r});
        
        priority = SEARCH_BUILDING_BY_CITY_PRIORITY;
        const auto& city = ((OACity *)phrase.getLastSelectedWord.result.object).city;
        bool res = dataInterface->preloadStreets({std::const_pointer_cast<OsmAnd::StreetGroup>(city)}, ctrl);
        if (res)
        {
            const auto& streets = city->streets;
            if (streets.size() == 1)
            {
                s = streets[0];
            }
            else
            {
                for (const auto& st : streets)
                {
                    if (st->nativeName == city->nativeName || st->nativeName == (QStringLiteral("<") + city->nativeName + QStringLiteral(">")))
                    {
                        s = st;
                        break;
                    }
                }
            }
        }
    }
    
    if (s)
    {
        NSString *resId = phrase.getLastSelectedWord.result.resourceId;
        const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(resId));
        const auto& dataInterface = obfsCollection->obtainDataInterface({r});
        
        if (_cacheBuilding != s)
        {
            _cacheBuilding = s;
            
            bool res = dataInterface->preloadBuildings({std::const_pointer_cast<OsmAnd::Street>(s)}, ctrl);
            if (res)
            {
                const auto& ms = std::const_pointer_cast<OsmAnd::Street>(s);
                std::sort(ms->buildings, [](const std::shared_ptr<const OsmAnd::Building>& o1, const std::shared_ptr<const OsmAnd::Building>& o2)
                {
                    int i1 = OsmAnd::Utilities::extractFirstInteger(o1->nativeName);
                    int i2 = OsmAnd::Utilities::extractFirstInteger(o2->nativeName);
                    return i1 < i2;
                });
            }
        }
        QString lw = QString::fromNSString([phrase getUnknownWordToSearchBuilding]);
        OANameStringMatcher *buildingMatch = [phrase getUnknownWordToSearchBuildingNameMatcher];
        OANameStringMatcher *startMatch = [[OANameStringMatcher alloc] initWithNamePart:lw.toNSString() mode:CHECK_ONLY_STARTS_WITH];
        for (const auto& b : s->buildings)
        {
            if ([resultMatcher isCancelled])
                break;
            
            OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
            bool interpolation = b->belongsToInterpolation(lw);
            if ((![buildingMatch matches:b->nativeName.toNSString()] && !interpolation) || ![phrase isSearchTypeAllowed:HOUSE])
                continue;
            if (interpolation)
            {
                res.localeName = lw.toNSString();
                res.location = [OASearchCoreFactory getLocation:b hno:lw];
            }
            else
            {
                res.localeName = b->getName(lang, transliterate).toNSString();
                res.location = [OASearchCoreFactory getLocation:b->position31];
            }
            res.otherNames = [OASearchCoreFactory getAllNames:b->localizedNames nativeName:b->nativeName];
            res.object = [[OABuilding alloc] initWithBuilding:b];
            res.resourceId = resId;
            res.priority = priority;
            res.priorityDistance = 0;
            res.firstUnknownWordMatches = [startMatch matches:res.localeName];
            res.relatedObject = [[OAStreet alloc] initWithStreet:s];
            res.localeRelatedObjectName = s->getName(lang, transliterate).toNSString();
            res.objectType = HOUSE;
            res.preferredZoom = 17;
            
            [resultMatcher publish:res];
        }
        QString streetIntersection = QString::fromNSString([phrase getUnknownWordToSearch]);
        OANameStringMatcher *streetMatch = [phrase getMainUnknownNameStringMatcher];
        if (streetIntersection.isEmpty() || (!streetIntersection[0].isDigit() && OsmAnd::CommonWords::getCommonSearch(streetIntersection) == -1))
        {
            for (const auto& streetInter : s->intersectedStreets)
            {
                if ([resultMatcher isCancelled])
                    break;
                
                const auto& street = streetInter->street;
                OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
                if ((![streetMatch matches:street->nativeName.toNSString()] && ![streetMatch matchesMap:[OASearchCoreFactory getAllNames:street->localizedNames nativeName:street->nativeName]]) || ![phrase isSearchTypeAllowed:STREET_INTERSECTION])
                    continue;
                
                res.otherNames = [OASearchCoreFactory getAllNames:street->localizedNames nativeName:street->nativeName];
                res.localeName = street->getName(lang, transliterate).toNSString();
                res.object = [[OAStreet alloc] initWithStreet:street];
                res.resourceId = resId;
                res.relatedObject = [[OAStreet alloc] initWithStreet:s];
                res.priority = priority + 1;
                res.localeRelatedObjectName = s->getName(lang, transliterate).toNSString();
                res.priorityDistance = 0;
                res.objectType = STREET_INTERSECTION;
                res.location = [OASearchCoreFactory getLocation:street->position31];
                res.preferredZoom = 16;
                [phrase countUnknownWordsMatchMainResult:res];
                [resultMatcher publish:res];
            }
        }
    }
    return true;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if ([OASearchCoreFactory isLastWordCityGroup:p])
        return SEARCH_BUILDING_BY_CITY_PRIORITY;
    
    if (![p isLastWord:STREET])
        return -1;
    
    return SEARCH_BUILDING_BY_STREET_PRIORITY;
}

@end

@interface OASearchStreetByCityAPI ()

@end

@implementation OASearchStreetByCityAPI
{
    int DEFAULT_ADDRESS_BBOX_RADIUS;
    int LIMIT;
    OASearchBaseAPI *_streetsAPI;
}

- (instancetype) initWithAPI:(OASearchBuildingAndIntersectionsByStreetAPI *)streetsAPI
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:HOUSE],
                                        [OAObjectType withType:STREET],
                                        [OAObjectType withType:STREET_INTERSECTION]]];
    if (self)
    {
        DEFAULT_ADDRESS_BBOX_RADIUS = 100 * 1000;
        LIMIT = 10000;
        _streetsAPI = streetsAPI;
    }
    return self;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return [phrase getRadiusLevel] == 1 && [self getSearchPriority:phrase] != -1;
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getRadiusSearch:DEFAULT_ADDRESS_BBOX_RADIUS];
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    return [phrase getNextRadiusSearch:DEFAULT_ADDRESS_BBOX_RADIUS];
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OASearchWord *sw = [phrase getLastSelectedWord];
    if ([OASearchCoreFactory isLastWordCityGroup:phrase] && sw.result && sw.result.resourceId)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        QString lang = QString::fromNSString([[phrase getSettings] getLang]);
        bool transliterate = [[phrase getSettings] isTransliterate];

        const auto& c = ((OACity *)sw.result.object).city;
        if (c->streets.isEmpty())
        {
            const auto& obfsCollection = app.resourcesManager->obfsCollection;
            const auto& r = app.resourcesManager->getLocalResource(QString::fromNSString(sw.result.resourceId));
            const auto& dataInterface = obfsCollection->obtainDataInterface({r});
            dataInterface->preloadStreets({std::const_pointer_cast<OsmAnd::StreetGroup>(c)});
        }
        
        int limit = 0;
        OANameStringMatcher *nm = [phrase getMainUnknownNameStringMatcher];
        for (const auto& object : c->streets)
        {
            OASearchResult *res = [[OASearchResult alloc] initWithPhrase:phrase];
            res.localeName = object->getName(lang, transliterate).toNSString();
            res.otherNames = [OASearchCoreFactory getAllNames:object->localizedNames nativeName:object->nativeName];
            BOOL pub = YES;
            if (object->nativeName.startsWith('<'))
                pub = NO; // streets related to city
            else if ([phrase isUnknownSearchWordPresent] && !([nm matches:res.localeName] || [nm matchesMap:res.otherNames]))
                continue;
            
            res.localeRelatedObjectName = c->getName(lang, transliterate).toNSString();
            res.object = [[OAStreet alloc] initWithStreet:object];
            res.preferredZoom = 17;
            res.resourceId = sw.result.resourceId;
            res.location = [OASearchCoreFactory getLocation:object->position31];
            res.priority = SEARCH_STREET_BY_CITY_PRIORITY;
            //res.priorityDistance = 1;
            res.objectType = STREET;
            [self subSearchApiOrPublish:phrase resultMatcher:resultMatcher res:res api:_streetsAPI publish:pub];
            if (limit++ > LIMIT)
                break;
        }
        return true;
    }
    return true;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if ([OASearchCoreFactory isLastWordCityGroup:p])
        return SEARCH_STREET_BY_CITY_PRIORITY;
    
    return -1;
}

@end


@interface OASearchLocationAndUrlAPI ()

@end

@implementation OASearchLocationAndUrlAPI
{
    NSUInteger _olcPhraseHash;
    CLLocation *_olcPhraseLocation;
    OAParsedOpenLocationCode *_cachedParsedCode;
    NSArray<NSString *> *_citySubTypes;
}

- (instancetype)init
{
    self = [super initWithSearchTypes:@[[OAObjectType withType:LOCATION],
                                        [OAObjectType withType:PARTIAL_LOCATION]]];
    if (self)
    {
        _citySubTypes = @[@"city", @"town", @"village"];
    }
    return self;
}

-(BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

-(BOOL)search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    if (![phrase isUnknownSearchWordPresent])
        return NO;
    
    BOOL parseUrl = [self parseUrl:phrase resultMatcher:resultMatcher];
    if (!parseUrl)
        [self parseLocation:phrase resultMatcher:resultMatcher];
    
    return [super search:phrase resultMatcher:resultMatcher];
}

- (BOOL) isKindOfNumber:(NSString *)s
{
    for (int i = 0; i < s.length; i ++)
    {
        unichar c = [s characterAtIndex:i];
        if (c >= '0' && c <= '9')
        {
        }
        else if (c == ':' || c == '.' || c == '#' || c == ',' || c == '-' || c == '\'' || c == '"')
        {
        }
        else
        {
            return NO;
        }
    }
    return YES;
}

- (CLLocation *) parsePartialLocation:(NSString *)s
{
    s = [s trim];
    if (s.length == 0
             || !([s characterAtIndex:0] == '-'
             || [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[s characterAtIndex:0]]
             || [s characterAtIndex:0] == 'S' || [s characterAtIndex:0] == 's'
             || [s characterAtIndex:0] == 'N' || [s characterAtIndex:0] == 'n'
             || [s indexOf:@"://"] != -1))
    {
        return nil;
    }
    
    NSMutableArray<NSNumber *> *d = [NSMutableArray array];
    NSMutableArray *all = [NSMutableArray array];
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    [OALocationParser splitObjects:s d:d all:all strings:strings];
    if (d.count == 0)
        return nil;
    
    double lat = [OALocationParser parse1Coordinate:all begin:0 end:(int)all.count];
    return [[CLLocation alloc] initWithLatitude:lat longitude:0];
}

- (void) parseLocation:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    NSString *lw = [phrase getUnknownSearchPhrase];
    // Detect OLC
    OAParsedOpenLocationCode *parsedCode = _cachedParsedCode;
    CLLocation *l;
    if (parsedCode != nil)
    {
        CLLocation *latLon = parsedCode.latLon;
        // do we have local code with locality
        if (latLon == nil && !parsedCode.full && parsedCode.placeName.length > 0)
        {
            NSArray<OASearchResult *> *requestResults = resultMatcher.getRequestResults;
            if (requestResults.count > 0)
            {
                CLLocation *searchLocation = nil;
                for (OASearchResult *sr in requestResults)
                {
                    switch (sr.objectType) {
                        case POI:
                        {
                            OAPOI *a = (OAPOI *) sr.object;
                            if ([_citySubTypes containsObject:[a.type getOsmValue]])
                            {
                                searchLocation = sr.location;
                            }
                            break;
                        }
                        default:
                        {
                            searchLocation = sr.location;
                            break;
                        }
                    }
                    if (searchLocation != nil)
                    {
                        break;
                    }
                }
                if (searchLocation != nil)
                {
                    latLon = [parsedCode recover:searchLocation];
                }
            }
        }
        if (latLon == nil && !parsedCode.full)
        {
            latLon = [parsedCode recover:phrase.getSettings.getOriginalLocation];
        }
        l = latLon;
    }
    else
    {
        l = [OALocationParser parseLocation:lw];
    }
    if (l)
    {
        if ([phrase isSearchTypeAllowed:LOCATION])
        {
            OASearchResult *sp = [[OASearchResult alloc] initWithPhrase:phrase];
            sp.priority = SEARCH_LOCATION_PRIORITY;
            sp.object = sp.location = l;
            sp.localeName = [NSString stringWithFormat:@"%.5f, %.5f", (float) sp.location.coordinate.latitude, (float) sp.location.coordinate.longitude];
            sp.objectType = LOCATION;
            sp.wordsSpan = lw;
            [resultMatcher publish:sp];
        }
    }
    else if ([phrase isNoSelectedType])
    {
        CLLocation *ll = [self parsePartialLocation:lw];
        if (ll && [phrase isSearchTypeAllowed:PARTIAL_LOCATION])
        {
            OASearchResult *sp = [[OASearchResult alloc] initWithPhrase:phrase];
            sp.priority = SEARCH_LOCATION_PRIORITY;
            sp.object = sp.location = ll;
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            formatter.minimumIntegerDigits = 1;
            formatter.minimumFractionDigits = 1;
            formatter.maximumFractionDigits = 2;
            formatter.decimalSeparator = @".";
            sp.localeName = [NSString stringWithFormat:@"%@, <input>", [formatter stringFromNumber:@((float) sp.location.coordinate.latitude)]];
            sp.objectType = PARTIAL_LOCATION;
            [resultMatcher publish:sp];
        }
    }
}

- (BOOL) parseUrl:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    /*
    NSString *text = [phrase getUnknownSearchPhrase];
    GeoParsedPoint pnt = GeoPointParserUtil.parse(text);
    if (pnt && pnt.isGeoPoint() && [phrase isSearchTypeAllowed:LOCATION])
    {
        OASearchResult *sp = [[OASearchResult alloc] initWithPhrase:phrase];
        sp.priority = 0;
        sp.object = pnt;
        sp.wordsSpan = text;
        sp.location = new LatLon(pnt.getLatitude(), pnt.getLongitude());
        sp.localeName = ((float)pnt.getLatitude()) +", " + ((float) pnt.getLongitude());
        if(pnt.getZoom() > 0)
            sp.preferredZoom = pnt.getZoom();
        
        sp.objectType = ObjectType.LOCATION;
        [resultMatcher publish:sp];
        return true;
    }
    */
    return false;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType] || ![p isUnknownSearchWordPresent])
        return -1;
    
    NSUInteger olcPhraseHash = [p.getUnknownSearchPhrase hash];
    if (_olcPhraseHash == olcPhraseHash && _olcPhraseLocation != nil)
    {
        CLLocationCoordinate2D originalCoord = p.getSettings.getOriginalLocation.coordinate;
        double distance = OsmAnd::Utilities::distance(originalCoord.longitude, originalCoord.latitude, _olcPhraseLocation.coordinate.longitude, _olcPhraseLocation.coordinate.latitude);
        if (distance > OLC_RECALC_DISTANCE_THRESHOLD)
        {
            olcPhraseHash++;
        }
    }
    if (_olcPhraseHash != olcPhraseHash)
    {
        _olcPhraseHash = olcPhraseHash;
        _olcPhraseLocation = p.getSettings.getOriginalLocation;
        _cachedParsedCode = [OALocationParser parseOpenLocationCode:p.getUnknownSearchPhrase];
    }
    return _cachedParsedCode == nil ? SEARCH_LOCATION_PRIORITY : SEARCH_MAX_PRIORITY;
}

@end


@implementation OASearchCoreFactory

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        //
    }
    return self;
}

+ (NSString *) stripBraces:(NSString *)localeName
{
    int i = [localeName indexOf:@"("];
    NSString *retName;
    if (i > -1)
    {
        retName = [[localeName substringToIndex:i] trim];
        int j = [localeName indexOf:@")" start:i];
        if (j > -1 && j + 2 < localeName.length)
            retName = [NSString stringWithFormat:@"%@ %@", retName, [localeName substringFromIndex:j + 1]];
    }
    else
    {
        retName = localeName;
    }
    return retName;
}

+ (CLLocation *) getLocation:(const OsmAnd::PointI)position31
{
    const OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(position31);
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

+ (CLLocation *) getLocation:(const std::shared_ptr<const OsmAnd::Building>&)building hno:(const QString&)hno
{
    float interpolation = building->evaluateInterpolation(hno);
    CLLocation *loc = [self.class getLocation:building->position31];
    CLLocation *latLon2 = [self.class getLocation:building->interpolationPosition31];

    double lat1 = loc.coordinate.latitude;
    double lat2 = latLon2.coordinate.longitude;
    double lon1 = loc.coordinate.longitude;
    double lon2 = latLon2.coordinate.longitude;
    return [[CLLocation alloc] initWithLatitude:interpolation * (lat2 - lat1) + lat1 longitude:interpolation * (lon2 - lon1) + lon1];
}

+ (NSMutableArray<NSString *> *) getAllNames:(const QHash<QString, QString>&)names nativeName:(const QString&)nativeName
{
    NSMutableArray<NSString *> *otherNames = [NSMutableArray array];
    BOOL hasEnName = NO;
    if (!names.isEmpty())
    {
        for (const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(names)))
        {
            if (!hasEnName && entry.key().toLower() == QStringLiteral("en"))
                hasEnName = YES;
            
            [otherNames addObject:entry.value().toNSString()];
        }
    }
    if (!hasEnName && !nativeName.isNull())
        [otherNames addObject:OsmAnd::ICU::transliterateToLatin(nativeName).toNSString()];
    return otherNames;
}

+ (BOOL) isLastWordCityGroup:(OASearchPhrase *)p
{
    return [p isLastWord:CITY] || [p isLastWord:POSTCODE] || [p isLastWord:VILLAGE];
}

@end
