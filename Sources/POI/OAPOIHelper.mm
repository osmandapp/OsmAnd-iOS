//
//  OAPOIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIParser.h"
#import "OAPOIUIFilter.h"
#import "OAPhrasesParser.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OASearchPoiTypeFilter.h"
#import "OACollatorStringMatcher.h"

#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/ICU.h>

#define kSearchLimitRaw 5000
#define kRadiusKmToMetersKoef 1200.0

@implementation OAPOIHelper {

    OsmAndAppInstance _app;
    int _limitCounter;
    BOOL _breakSearch;
    NSDictionary *_phrases;
    NSDictionary *_phrasesEN;

    double _radius;
    
    OsmAnd::AreaI _visibleArea;
    OsmAnd::ZoomLevel _zoomLevel;
    
    NSString *_prefLang;
    
    NSArray<OAPOIType *> *_textPoiAdditionals;
    NSDictionary<NSString *, NSString *> *_poiAdditionalCategoryIcons;
    NSMapTable<NSString *, NSString *> *_deprecatedTags;

    BOOL _isInit;
}

+ (OAPOIHelper *)sharedInstance {
    static dispatch_once_t once;
    static OAPOIHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _searchLimit = kSearchLimitRaw;
        _isSearchDone = YES;
        [self readPOI];
        [self findDefaultOtherCategory];
        [self updateReferences];
        [self updatePhrases];
        _isInit = YES;
    }
    return self;
}

- (BOOL) isInit
{
    return _isInit;
}

- (void)readPOI
{
    NSString *poiXmlPath = [[NSBundle mainBundle] pathForResource:@"poi_types" ofType:@"xml"];
    
    OAPOIParser *parser = [[OAPOIParser alloc] init];
    [parser getPOITypesSync:poiXmlPath];
    _poiTypes = parser.poiTypes;
    _poiTypesByName = parser.poiTypesByName;
    _poiCategories = parser.poiCategories;
    _textPoiAdditionals = parser.textPoiAdditionals;
    _poiAdditionalCategoryIcons = parser.poiAdditionalCategoryIcons;
    _otherMapCategory = parser.otherMapCategory;
    _deprecatedTags = parser.deprecatedTags;
    
    NSMutableArray *categories = [_poiCategories mutableCopy];
    for (OAPOICategory *c in categories)
        if ([c.name isEqualToString:@"Other"])
        {
            [categories removeObject:c];
            break;
        }
    _poiCategoriesNoOther = categories;
    
    _poiFilters = parser.poiFilters;
}

- (void) findDefaultOtherCategory
{
    OAPOICategory *pc = [self getPoiCategoryByName:@"user_defined_other"];
    if (!pc)
        NSLog(@"!!! 'user_defined_other' category not found");

    _otherPoiCategory = pc;
}

- (NSString *) replaceDeprecatedSubtype:(NSString *)subtype
{
    NSString *result = [_deprecatedTags objectForKey:subtype];
    return result ? result : subtype;
}

- (BOOL) isRegisteredType:(OAPOICategory *)t
{
    return [self getPoiCategoryByName:t.name] != _otherPoiCategory;
}

- (void)updateReferences
{
    for (OAPOIType *p in _poiTypes)
    {
        if (p.reference)
        {
            OAPOIType *pType = [self getPoiTypeByName:p.name];
            if (pType)
            {
                p.tag = pType.tag;
                p.value = pType.value;
                p.referenceType = pType;
            }
        }
    }
}

- (void)updatePhrases
{
    if (!_phrases)
    {
        NSString *lang = [OAUtilities currentLang];

        NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml" inDirectory:[NSString stringWithFormat:@"phrases/%@", lang]];

        if ([[NSFileManager defaultManager] fileExistsAtPath:phrasesXmlPath])
        {
            OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
            [parser getPhrasesSync:phrasesXmlPath];
            _phrases = parser.phrases;
        }
    }
    
    if (!_phrasesEN)
    {
        NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml" inDirectory:@"phrases/en"];
        
        OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
        [parser getPhrasesSync:phrasesXmlPath];
        _phrasesEN = parser.phrases;
    }

    if (_phrases.count > 0)
    {
        for (OAPOIType *poiType in _poiTypes)
        {
            poiType.nameLocalized = [self getPhrase:poiType];
            for (OAPOIType *add in poiType.poiAdditionals)
            {
                add.nameLocalized = [self getPhrase:add];
                if (add.poiAdditionalCategory)
                    add.poiAdditionalCategoryLocalized = [self getPhraseByName:add.poiAdditionalCategory];
            }
        }
        for (OAPOICategory *c in _poiCategories)
        {
            c.nameLocalized = [self getPhrase:c];
            for (OAPOIType *add in c.poiAdditionals)
            {
                add.nameLocalized = [self getPhrase:add];
                if (add.poiAdditionalCategory)
                    add.poiAdditionalCategoryLocalized = [self getPhraseByName:add.poiAdditionalCategory];
            }
        }
        for (OAPOIFilter *f in _poiFilters)
        {
            f.nameLocalized = [self getPhrase:f];
            for (OAPOIType *add in f.poiAdditionals)
            {
                add.nameLocalized = [self getPhrase:add];
                if (add.poiAdditionalCategory)
                    add.poiAdditionalCategoryLocalized = [self getPhraseByName:add.poiAdditionalCategory];
            }
        }
    }
    
    if (_phrasesEN.count > 0)
    {
        for (OAPOIType *poiType in _poiTypes)
        {
            poiType.nameLocalizedEN = [self getPhraseEN:poiType];
            if (_phrases.count == 0)
            {
                poiType.nameLocalized = poiType.nameLocalizedEN;
            }
            for (OAPOIType *add in poiType.poiAdditionals)
            {
                add.nameLocalizedEN = [self getPhraseEN:add];
                if (_phrases.count == 0)
                {
                    add.nameLocalized = add.nameLocalizedEN;
                    if (add.poiAdditionalCategory)
                        add.poiAdditionalCategoryLocalized = [self getPhraseENByName:add.poiAdditionalCategory];
                }
            }
        }
        for (OAPOICategory *c in _poiCategories)
        {
            c.nameLocalizedEN = [self getPhraseEN:c];
            if (_phrases.count == 0)
            {
                c.nameLocalized = c.nameLocalizedEN;
            }
            for (OAPOIType *add in c.poiAdditionals)
            {
                add.nameLocalizedEN = [self getPhraseEN:add];
                if (_phrases.count == 0)
                {
                    add.nameLocalized = add.nameLocalizedEN;
                    if (add.poiAdditionalCategory)
                        add.poiAdditionalCategoryLocalized = [self getPhraseENByName:add.poiAdditionalCategory];
                }
            }
        }
        for (OAPOIFilter *f in _poiFilters)
        {
            f.nameLocalizedEN = [self getPhraseEN:f];
            
            if (_phrases.count == 0)
            {
                f.nameLocalized = f.nameLocalizedEN;
            }
            for (OAPOIType *add in f.poiAdditionals)
            {
                add.nameLocalizedEN = [self getPhraseEN:add];
                if (_phrases.count == 0)
                {
                    add.nameLocalized = add.nameLocalizedEN;
                    if (add.poiAdditionalCategory)
                        add.poiAdditionalCategoryLocalized = [self getPhraseENByName:add.poiAdditionalCategory];
                }
            }
        }
    }
}

-(NSString *)getPhraseByName:(NSString *)name
{
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", [name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
    if (!phrase)
        return [[name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        return phrase;
}

-(NSString *)getPhraseENByName:(NSString *)name
{
    NSString *phrase = [_phrasesEN objectForKey:[NSString stringWithFormat:@"poi_%@", name]];
    if (!phrase)
        return [[name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        return phrase;
}

-(NSString *)getPhrase:(OAPOIBaseType *)type
{
    if (type.baseLangType)
        return [NSString stringWithFormat:@"%@ (%@)", [self getPhrase:type.baseLangType], [OAUtilities translatedLangName:type.lang]];

    return [self getPhraseByName:type.name];
}

-(NSString *)getPhraseEN:(OAPOIBaseType *)type
{
    if (type.baseLangType)
        return [self getPhraseEN:type.baseLangType];

    return [self getPhraseENByName:type.name];
}

- (NSArray *)poiFiltersForCategory:(NSString *)categoryName
{
    NSMutableArray *res = [NSMutableArray array];
    for (OAPOIFilter *f in _poiFilters)
        if ([f.category.name isEqualToString:categoryName])
            [res addObject:f];
    
    return [NSArray arrayWithArray:res];
}

- (OAPOIType *)getPoiType:(NSString *)tag value:(NSString *)value
{
    for (OAPOIType *t in _poiTypes)
        if ([t.tag isEqualToString:tag] && [t.value isEqualToString:value])
            return t;
    
    return nil;
}

- (OAPOIType *)getPoiTypeByName:(NSString *)name
{
    return [_poiTypesByName objectForKey:name];
}

- (OAPOIBaseType *)getAnyPoiTypeByName:(NSString *)name
{
    for (OAPOICategory *pc in _poiCategories)
    {
        if ([pc.name isEqualToString:name])
            return pc;

        for (OAPOIFilter *pf in pc.poiFilters)
        {
            if ([pf.name isEqualToString:name])
                return pf;
        }
        OAPOIType *pt = [pc getPoiTypeByKeyName:name];
        if (pt && !pt.reference)
            return pt;
    }
    return nil;
}

- (OAPOIType *)getPoiTypeByCategory:(NSString *)category name:(NSString *)name
{
    for (OAPOIType *t in _poiTypes)
        if ([t.category.name isEqualToString:category] && [t.name isEqualToString:name])
            return t;
    
    return nil;
}

- (OAPOIType *)getPoiTypeByKeyInCategory:(OAPOICategory *)category name:(NSString *)name
{
    if (category)
        return [category getPoiTypeByKeyName:name];
    
    return nil;
}

- (OAPOIType *) getPoiAdditionalByKey:(OAPOIBaseType *)p name:(NSString *)name
{
    NSArray<OAPOIType *> *pp = p.poiAdditionals;
    if (pp)
    {
        for (OAPOIType *pt in pp)
        {
            if ([pt.name isEqualToString:name])
            {
                return pt;
            }
        }
    }
    return nil;
}

- (OAPOIBaseType *) getAnyPoiAdditionalTypeByKey:(NSString *)name
{
    OAPOIType *add = nil;
    for (OAPOICategory *pc in _poiCategories)
    {
        add = [self getPoiAdditionalByKey:pc name:name];
        if (add)
        {
            return add;
        }
        for (OAPOIFilter *pf in pc.poiFilters)
        {
            add = [self getPoiAdditionalByKey:pf name:name];
            if (add)
            {
                return add;
            }
        }
        for (OAPOIType *p in pc.poiTypes)
        {
            add = [self getPoiAdditionalByKey:p name:name];
            if (add)
            {
                return add;
            }
        }
    }
    return nil;
}

- (NSString *) getPoiStringWithoutType:(OAPOI *)poi
{
    OAPOIType *pt = poi.type;
    NSString *nm;
    if (pt)
        nm = pt.nameLocalized;

    NSString *n = poi.nameLocalized;
    if (nm && [n indexOf:nm] != -1)
    {
        // type is contained in name e.g.
        // n = "Bakery the Corner"
        // type = "Bakery"
        // no need to repeat this
        return n;
    }
    if (n.length == 0)
        return nm;

    return [NSString stringWithFormat:@"%@ %@", nm, n];
}

- (OAPOIType *) getTextPoiAdditionalByKey:(NSString *)name
{
    for (OAPOIType *pt in _textPoiAdditionals)
    {
        if ([pt.name isEqualToString:name])
            return pt;
    }
    return nil;
}

- (OAPOICategory *) getPoiCategoryByName:(NSString *)name
{
    return [self getPoiCategoryByName:name create:NO];
}

- (OAPOICategory *) getPoiCategoryByName:(NSString *)name create:(BOOL)create
{
    if ([name isEqualToString:@"leisure"] && !create)
        name = @"entertainment";

    if ([name isEqualToString:@"historic"] && !create)
        name = @"tourism";
    
    for (OAPOICategory *p in _poiCategories)
    {
        if ([p.name caseInsensitiveCompare:name] == 0)
            return p;
    }
    if (create)
    {
        OAPOICategory *lastCategory = [[OAPOICategory alloc] initWithName:name];
        _poiCategories = [_poiCategories arrayByAddingObject:lastCategory];
        return lastCategory;
    }
    return self.otherPoiCategory;
}

- (NSString *) getPoiAdditionalCategoryIcon:(NSString *)category
{
    return [_poiAdditionalCategoryIcons objectForKey:category];
}

- (NSArray<OAPOIBaseType *> *) getTopVisibleFilters
{
    NSMutableArray<OAPOIBaseType *> *lf = [NSMutableArray array];
    for (OAPOICategory *pc in _poiCategories)
    {
        if (pc.top)
            [lf addObject:pc];

        for (OAPOIFilter *p in pc.poiFilters)
        {
            if (p.top)
                [lf addObject:p];
        }
    }
    [lf sortUsingComparator:^NSComparisonResult(OAPOIBaseType * _Nonnull obj1, OAPOIBaseType * _Nonnull obj2) {
        return [obj1.nameLocalized localizedCompare:obj2.nameLocalized];
    }];
    return lf;
}

-(void)setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom
{
    _visibleArea = area;
    _zoomLevel = zoom;
}

-(void)findPOIsByKeyword:(NSString *)keyword
{
    int radius = -1;
    [self findPOIsByKeyword:keyword categoryName:nil poiTypeName:nil radiusIndex:&radius];
}

-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radiusIndex:(int *)radiusIndex
{
    _isSearchDone = NO;
    _breakSearch = NO;
    if (*radiusIndex  < 0)
        _radius = 0.0;
    else
        _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
    
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                           return (_radius == 0.0 && _limitCounter < 0) || _breakSearch;
                                       }));
    
    _limitCounter = _searchLimit;
    
    _prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    
    if (_radius == 0.0) {
        
        const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
        
        searchCriteria->name = QString::fromNSString(keyword ? keyword : @"");
        searchCriteria->obfInfoAreaFilter = _visibleArea;
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [self]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  [self onPOIFound:resultEntry];
                              },
                              ctrl);
    } else {
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
                
        auto categoriesFilter = QHash<QString, QStringList>();
        if (categoryName && typeName) {
            categoriesFilter.insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
        } else if (categoryName) {
            categoriesFilter.insert(QString::fromNSString(categoryName), QStringList());
        }
        searchCriteria->categoriesFilter = categoriesFilter;
        
        while (true)
        {
            searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(_radius, _myLocation);
            
            const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
            search->performSearch(*searchCriteria,
                                  [self]
                                  (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                      [self onPOIFound:resultEntry];
                                  },
                                  ctrl);
            
            if (_limitCounter == _searchLimit && _radius < 12000.0)
            {
                *radiusIndex += 1;
                _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
            }
            else
            {
                break;
            }
        }
    }

    _isSearchDone = YES;
    
    if (_delegate)
        [_delegate searchDone:_breakSearch];

}

-(void)findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex
{
    _isSearchDone = NO;
    _breakSearch = NO;
    if (*radiusIndex  < 0)
        _radius = 0.0;
    else
        _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
    
    if (filter && ![filter isEmpty])
    {
        const auto& obfsCollection = _app.resourcesManager->obfsCollection;
        
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                                      (const OsmAnd::FunctorQueryController* const controller)
                                                      {
                                                          // should break?
                                                          return (_radius == 0.0 && _limitCounter < 0) || _breakSearch;
                                                      }));
        
        _limitCounter = _searchLimit;
        
        _prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
        
        auto categoriesFilter = QHash<QString, QStringList>();
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [filter getAcceptedTypes];
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
        searchCriteria->categoriesFilter = categoriesFilter;
        
        OAAmenityNameFilter *nameFilter = nil;
        if (filter.filterByName.length > 0)
            nameFilter = [filter getNameFilter:filter.filterByName];
        
        while (true)
        {
            searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(_radius, _myLocation);
            
            const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
            search->performSearch(*searchCriteria,
                                  [self, &nameFilter]
                                  (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                  {
                                      OAPOI *poi = [self.class parsePOI:resultEntry];
                                      if (!nameFilter || [nameFilter accept:poi])
                                          [self onPOIFound:resultEntry poi:poi];
                                  },
                                  ctrl);
            
            if (_limitCounter == _searchLimit && _radius < 12000.0)
            {
                *radiusIndex += 1;
                _radius = kSearchRadiusKm[*radiusIndex] * kRadiusKmToMetersKoef;
            }
            else
            {
                break;
            }
        }
    }
    
    _isSearchDone = YES;
    
    if (_delegate)
        [_delegate searchDone:_breakSearch];
}

+(NSArray<OAPOI *> *)findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return false;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    
    auto categoriesFilter = QHash<QString, QStringList>();
    if (categoryName && typeName) {
        categoriesFilter.insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
    } else if (categoryName) {
        categoriesFilter.insert(QString::fromNSString(categoryName), QStringList());
    }
    searchCriteria->categoriesFilter = categoriesFilter;
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, location);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    search->performSearch(*searchCriteria,
                          [&arr, &tagName, &name, &location]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              OAPOI *poi = [OAPOIHelper parsePOI:resultEntry];
                              if (poi && (!tagName || [poi.values valueForKey:tagName]) && (!name || [poi.nameLocalized isEqualToString:name]))
                              {
                                  const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  poi.distanceMeters = OsmAnd::Utilities::squareDistance31(location, amenity->position31);
                                  [arr addObject:poi];
                              }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

+(NSArray<OAPOI *> *)findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    if (filter && ![filter isEmpty])
    {
        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto& obfsCollection = _app.resourcesManager->obfsCollection;
        
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([&matcher]
                                                      (const OsmAnd::FunctorQueryController* const controller)
                                                      {
                                                          // should break?
                                                          return matcher && [matcher isCancelled];
                                                      }));
        
        const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
        OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
        OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
        searchCriteria->bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [&arr, &filter, &matcher]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  OAPOI *poi = [OAPOIHelper parsePOI:resultEntry];
                                  if (poi && [filter accept:poi.type.category subcategory:poi.type.name])
                                  {
                                      if (matcher)
                                          [matcher publish:poi];
                                      
                                      [arr addObject:poi];
                                  }
                              },
                              ctrl);
    }
    return [NSArray arrayWithArray:arr];
}

+(NSArray<OAPOI *> *)findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    OACollatorStringMatcher *mt = [[OACollatorStringMatcher alloc] initWithPart:query mode:CHECK_STARTS_FROM_SPACE];
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&matcher]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return matcher && [matcher isCancelled];
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
    OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
    searchCriteria->bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    search->performSearch(*searchCriteria,
                          [&arr, &mt, &matcher]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              OAPOI *poi = [OAPOIHelper parsePOI:resultEntry];
                              if (poi)
                              {
                                  BOOL __block matches = [mt matches:[poi.name lowerCase]] || [mt matches:[poi.nameLocalized lowerCase]];
                                  if (!matches)
                                  {
                                      for (NSString *s in poi.localizedNames)
                                      {
                                          matches = [mt matches:[s lowerCase]];
                                          if (matches)
                                              break;
                                      }
                                      if (!matches)
                                      {
                                          [poi.values enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
                                              if ([key indexOf:@"_name"] != -1)
                                              {
                                                  matches = [mt matches:value];
                                                  if (matches)
                                                      *stop = YES;
                                              }
                                          }];
                                      }
                                  }
                                  if (matches)
                                  {
                                      if (matcher)
                                          [matcher publish:poi];
                                      
                                      [arr addObject:poi];
                                  }
                              }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

+(OAPOI *)parsePOI:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
    return [self.class parsePOIByAmenity:amenity];
}

+(OAPOI *)parsePOIByAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity
{
    OAPOIHelper *helper = [OAPOIHelper sharedInstance];
    
    if (amenity->categories.isEmpty())
        return nil;
    
    const auto& catList = amenity->getDecodedCategories();
    if (catList.isEmpty())
        return nil;
    
    NSString *category = catList.first().category.toNSString();
    NSString *subCategory = catList.first().subcategory.toNSString();
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.obfId = amenity->id;
    poi.latitude = latLon.latitude;
    poi.longitude = latLon.longitude;
    poi.name = amenity->nativeName.toNSString();
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSString *nameLocalized = [OAPOIHelper processLocalizedNames:amenity->localizedNames nativeName:amenity->nativeName names:names];
    if (nameLocalized.length > 0)
        poi.nameLocalized = nameLocalized;
    poi.localizedNames = names;
    
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    [OAPOIHelper processDecodedValues:amenity->getDecodedValues() content:content values:values];
    poi.values = values;
    poi.localizedContent = content;
    
    if (!poi.nameLocalized)
        poi.nameLocalized = poi.name;
    
    OAPOIType *type = [helper getPoiTypeByCategory:category name:subCategory];
    if (!type)
    {
        OAPOICategory *c = [[OAPOICategory alloc] initWithName:category];
        type = [[OAPOIType alloc] initWithName:subCategory category:c];
        type.nameLocalized = [helper getPhrase:type];
        type.nameLocalizedEN = [helper getPhraseEN:type];
    }
    poi.type = type;
    
    if (type.mapOnly)
        return nil;
    
    if (poi.name.length == 0)
        poi.name = type.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = type.nameLocalized;
    
    return poi;
}

-(BOOL)breakSearch
{
    _breakSearch = !_isSearchDone;
    return _breakSearch;
}

-(void)onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    OAPOI *poi = [self.class parsePOI:resultEntry];
    if (poi)
    {
        const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
        poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, amenity->position31);
        
        _limitCounter--;
        
        if (_delegate)
            [_delegate poiFound:poi];
    }
}

-(void)onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry poi:(OAPOI *)poi
{
    if (poi)
    {
        const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
        poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, amenity->position31);
        
        _limitCounter--;
        
        if (_delegate)
            [_delegate poiFound:poi];
    }
}

+ (NSString *)processLocalizedNames:(QHash<QString, QString>)localizedNames nativeName:(QString)nativeName names:(NSMutableDictionary *)names
{
    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;

    const QString lang = (prefLang ? QString::fromNSString(prefLang) : QString::null);
    QString nameLocalized;
    for(const auto& entry : OsmAnd::rangeOf(localizedNames))
    {
        if (lang != QString::null && entry.key() == lang)
            nameLocalized = entry.value();
        
        [names setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
    }
    
    if (nameLocalized.isNull())
        nameLocalized = nativeName;
    
    if (![names objectForKey:@""])
        [names setObject:nativeName.toNSString() forKey:@""];
    
    if (!nameLocalized.isNull() && transliterate)
        nameLocalized = OsmAnd::ICU::transliterateToLatin(nameLocalized);
    
    return nameLocalized.isNull() ? @"" : nameLocalized.toNSString();
}

+ (void)processDecodedValues:(QList<OsmAnd::Amenity::DecodedValue>)decodedValues content:(NSMutableDictionary *)content values:(NSMutableDictionary *)values
{
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
}

@end
