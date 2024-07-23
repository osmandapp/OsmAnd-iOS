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
#import "OAMapUtils.h"
#import "OAResultMatcher.h"

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
#define kZoomToSearchPOI 16.0

static NSArray<NSString *> *const kNameTagPrefixes = @[@"name:", @"int_name", @"nat_name", @"reg_name", @"loc_name", @"old_name", @"alt_name", @"short_name", @"official_name"];

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
        [self sortPoiCategories];
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


- (OAPOIType *) getDefaultOtherCategoryType
{
    if (_otherPoiCategory && _otherPoiCategory.poiTypes.count > 0)
        return _otherPoiCategory.poiTypes[0];
    return nil;
}

- (NSArray<OAPOICategory *> *) getCategories:(BOOL)includeMapCategory
{
    NSMutableArray<OAPOICategory *> *lst = [NSMutableArray arrayWithArray:_poiCategories];
    if (!includeMapCategory)
        [lst removeObject:self.otherMapCategory];
    return lst;
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

- (void) updateReferences
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

- (NSDictionary *) loadPhraseFileForLanguage:(NSString *)langguageCode
{
    NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml" inDirectory:[NSString stringWithFormat:@"phrases/%@", langguageCode]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:phrasesXmlPath])
    {
        OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
        [parser getPhrasesSync:phrasesXmlPath];
        return parser.phrases;
    }
    return nil;
}

- (void) updatePhrases
{
    if (!_phrases)
    {
        NSString *fullLanguageCode = [[NSLocale preferredLanguages] firstObject];
        _phrases = [self loadPhraseFileForLanguage:fullLanguageCode];
        
        if (!_phrases)
        {
            NSLog(@"ERROR: Not found phrases translation file at path: %@", [NSString stringWithFormat:@"phrases/%@/phrases.xml", fullLanguageCode]);
            NSString *primaryLanguageCode = [OAUtilities currentLang];
            _phrases = [self loadPhraseFileForLanguage:primaryLanguageCode];
        }
    }
    
    if (!_phrasesEN)
    {
        _phrasesEN = [self loadPhraseFileForLanguage:@"en"];
    }

    if (_phrases.count > 0)
    {
        for (OAPOIType *poiType in _poiTypes)
        {
            poiType.nameLocalized = [self getPhrase:poiType];
            poiType.nameSynonyms = [self getSynonyms:poiType];
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
            c.nameSynonyms = [self getSynonyms:c];
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
            f.nameSynonyms = [self getSynonyms:f];
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

- (NSString *) getPhraseByName:(NSString *)name
{
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", [name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
    if (!phrase)
    {
        return [[name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    else
    {
        int i = [phrase indexOf:@";"];
        if (i > 0) {
            return [phrase substringToIndex:i];
        }
        return phrase;
    }
}

- (NSString *) getPhraseENByName:(NSString *)name
{
    NSString *phrase = [_phrasesEN objectForKey:[NSString stringWithFormat:@"poi_%@", name]];
    if (!phrase)
    {
        return [[name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    else
    {
        int i = [phrase indexOf:@";"];
        if (i > 0) {
            return [phrase substringToIndex:i];
        }
        return phrase;
    }
}

- (NSString *) getSynonymsByName:(NSString *)name
{
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", [name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
    if (phrase)
    {
        int i = [phrase indexOf:@";"];
        if (i > 0 && phrase.length > i) {
            return [phrase substringFromIndex:i + 1];
        }
    }
    return @"";
}

- (NSString *) getPhrase:(OAPOIBaseType *)type
{
    if (type.baseLangType)
        return [NSString stringWithFormat:@"%@ (%@)", [self getPhrase:type.baseLangType], [OAUtilities translatedLangName:type.lang]];

    return [self getPhraseByName:type.name];
}

- (NSString *) getPhraseEN:(OAPOIBaseType *)type
{
    if (type.baseLangType)
        return [self getPhraseEN:type.baseLangType];

    return [self getPhraseENByName:type.name];
}

- (NSString *) getSynonyms:(OAPOIBaseType *)type
{
    if (type.baseLangType)
        return [self getSynonyms:type.baseLangType];
    
    return [self getSynonymsByName:type.name];
}

- (void) sortPoiCategories
{
    _poiCategories = [_poiCategories sortedArrayUsingComparator:^NSComparisonResult(OAPOIBaseType * _Nonnull obj1, OAPOIBaseType * _Nonnull obj2)
    {
        return [obj1.nameLocalized localizedCompare:obj2.nameLocalized];
    }];
}

- (NSArray *)poiFiltersForCategory:(NSString *)categoryName
{
    NSMutableArray *res = [NSMutableArray array];
    for (OAPOIFilter *f in _poiFilters)
        if ([f.category.name isEqualToString:categoryName])
            [res addObject:f];
    
    return [NSArray arrayWithArray:res];
}

- (OAPOIType *) getPoiType:(NSString *)tag value:(NSString *)value
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

- (OAPOIType *) getPoiTypeByKey:(NSString *)name
{
    for (NSInteger i = 0; i < _poiCategories.count; i++)
    {
        OAPOICategory *pc = _poiCategories[i];
        OAPOIType *pt = [pc getPoiTypeByKeyName:name];
        if (pt != nil && !pt.reference)
            return pt;
    }
    return nil;
}

- (OAPOIBaseType *) getAnyPoiTypeByName:(NSString *)name
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

- (OAPOIType *) getPoiTypeByCategory:(NSString *)category name:(NSString *)name
{
    for (OAPOICategory *c in _poiCategories)
    {
        if ([c.name isEqualToString:category])
        {
            return [c getPoiTypeByKeyName:name];
        }
    }
    return nil;
}

- (OAPOIType *) getPoiTypeByKeyInCategory:(OAPOICategory *)category name:(NSString *)name
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
    OAPOICategory *pc = poi.type.category;
    //multivalued amenity
    NSArray<NSString *> * subtypes = [poi.subType componentsSeparatedByString:@";"];
    NSMutableString *typeName = [NSMutableString string];
    for (NSString * subType : subtypes)
    {
        OAPOIType * pt = [pc getPoiTypeByKeyName:subType];
        NSString *tmp = [NSString string];
        if (pt != nil)
        {
            tmp = pt.nameLocalized;
        }
        else
        {
            tmp = [[subType stringByReplacingOccurrencesOfString: @"_" withString:@" "] lowercaseString];
        }
        
        if ([typeName length] > 0)
        {
            [typeName appendFormat:@", %@", [tmp lowercaseString]];
            break;
        }
        else
        {
            typeName = [NSMutableString stringWithString:tmp];
        }
    }
    
    
    NSString *n = poi.nameLocalized;
    if (typeName && [n indexOf:typeName] != -1)
    {
        // type is contained in name e.g.
        // n = "Bakery the Corner"
        // type = "Bakery"
        // no need to repeat this
        return n;
    }
    if (n.length == 0)
        return typeName;

    return [NSString stringWithFormat:@"%@ %@", typeName, n];
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

- (OAPOICategory *) getOsmwiki
{
    for (int i = 0; i < _poiCategories.count; i++)
    {
        OAPOICategory *category = _poiCategories[i];
        if (category.isWiki) {
            return category;
        }
    }
    return nil;
}

- (NSArray<NSString *> *)getAllAvailableWikiLocales
{
    NSMutableArray<NSString *> *availableWikiLocales = [NSMutableArray new];
    for (OAPOIType *type in [[self getOsmwiki] getPoiTypeByKeyName:WIKI_PLACE].poiAdditionals)
    {
        NSString *name = type.name;
        NSString *wikiLang = [WIKI_LANG stringByAppendingString:@":"];
        if (name && [name hasPrefix:wikiLang])
        {
            NSString *locale = [name substringFromIndex:wikiLang.length];
            [availableWikiLocales addObject:locale];
        }
    }
    return availableWikiLocales;
}

- (NSString *) getAllLanguagesTranslationSuffix
{
    // TODO: sync poi code with Android
//    if (poiTranslator != null) {
//        return poiTranslator.getAllLanguagesTranslationSuffix();
//    }
    return @"all languages";
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
        for (OAPOIType *p in pc.poiTypes)
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

- (void) setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom
{
    _visibleArea = area;
    _zoomLevel = zoom;
}

- (void) findPOIsByKeyword:(NSString *)keyword
{
    int radius = -1;
    [self findPOIsByKeyword:keyword categoryName:nil poiTypeName:nil radiusIndex:&radius];
}

- (void) findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radiusIndex:(int *)radiusIndex
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
    
    _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    
    if (_radius == 0.0)
    {
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
    }
    else
    {
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

- (void) findPOIsByFilter:(OAPOIUIFilter *)filter radiusIndex:(int *)radiusIndex
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
        
        _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        
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

+ (OAPOI *)findPOIByName:(NSString *)name lat:(double)lat lon:(double)lon
{
    auto keyword = QString::fromNSString(name);
    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto& searchCriteria = std::make_shared<OsmAnd::AmenitiesInAreaSearch::Criteria>();
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, pointI);
    
    const auto& obfsCollection = [OsmAndApp instance].resourcesManager->obfsCollection;
    const auto search = std::make_shared<const OsmAnd::AmenitiesInAreaSearch>(obfsCollection);

    std::shared_ptr<const OsmAnd::Amenity> amenity;
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &amenity]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return amenity != nullptr;
                                                  }));
    OAAppSettings *settings = [OAAppSettings sharedManager];
    search->performSearch(*searchCriteria,
                          [self, &amenity, &keyword, settings]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              auto a = ((OsmAnd::AmenitiesInAreaSearch::ResultEntry&)resultEntry).amenity;
                              if (![settings isTypeDisabled:a->subType.toNSString()] && (a->nativeName == keyword || a->localizedNames.contains(keyword)))
                                  amenity = qMove(a);
                          }, ctrl);
    if (amenity)
        return [OAPOIHelper parsePOIByAmenity:amenity];

    return nil;
}

+ (OAPOI *) findPOIByOriginName:(NSString *)originName lat:(double)lat lon:(double)lon
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    bool cancel = false;
    ctrl.reset(new OsmAnd::FunctorQueryController([&cancel]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      // should break?
                                                      return cancel;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    

    OsmAnd::LatLon latLon(lat, lon);
    const auto location = OsmAnd::Utilities::convertLatLonTo31(latLon);
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, location);
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    OAPOI *res = nil;
    search->performSearch(*searchCriteria,
                          [&originName, &res, &cancel]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                OAPOI *poi = [OAPOIHelper parsePOI:resultEntry];
                                if (poi && [poi.toStringEn isEqualToString:originName])
                                {
                                    res = poi;
                                    cancel = true;
                                }
                          },
                          ctrl);
    
    return res;
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius
{
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, location);
    return [self findPOIsByTagName:tagName name:name location:location categoryName:categoryName poiTypeName:typeName bbox31:bbox31];
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bboxTopLeft:(CLLocationCoordinate2D)bboxTopLeft bboxBottomRight:(CLLocationCoordinate2D)bboxBottomRight;
{
    OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bboxTopLeft.latitude, bboxTopLeft.longitude));
    OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bboxBottomRight.latitude, bboxBottomRight.longitude));
    OsmAnd::AreaI bbox31 = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
    return [self findPOIsByTagName:tagName name:name location:location categoryName:categoryName poiTypeName:typeName bbox31:bbox31];
}

+ (NSArray<OAPOI *> *) findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName bbox31:(OsmAnd::AreaI)bbox31
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
    searchCriteria->bbox31 = bbox31;
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    NSMutableSet<NSNumber *> *processedPoi = [NSMutableSet set];
    search->performSearch(*searchCriteria,
                          [&arr, &tagName, &name, &location, &processedPoi]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                              if (![processedPoi containsObject:@(am->id.id)])
                              {
                                  [processedPoi addObject:@(am->id.id)];
                                  OAPOI *poi = [OAPOIHelper parsePOI:resultEntry withValues:tagName != nil withContent:NO];
                                  if (poi && (!tagName || [poi.values valueForKey:tagName]) && (!name || [poi.name isEqualToString:name] || [poi.localizedNames.allValues containsObject:name]))
                                  {
                                      poi.distanceMeters = OsmAnd::Utilities::squareDistance31(location, am->position31);
                                      [OAPOIHelper fetchValuesContentPOIByAmenity:am poi:poi];
                                      [arr addObject:poi];
                                  }
                              }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findTravelGuides:(NSArray<NSString *> *)categoryNames location:(OsmAnd::PointI)location bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    BOOL done = false;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&done]
                                                  (const OsmAnd::FunctorQueryController* const controller)
                                                  {
                                                      return done;
                                                  }));
    
    const std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesInAreaSearch::Criteria>(new OsmAnd::AmenitiesInAreaSearch::Criteria);
    
    if (categoryNames)
    {
        auto categoriesFilter = QHash<QString, QStringList>();
        QStringList categories = QStringList();
        for (NSString *categoryName in categoryNames)
            categories.append(QString::fromNSString(categoryName));
        
        categoriesFilter.insert(QString::fromNSString(@"routes"), categories);
        searchCriteria->categoriesFilter = categoriesFilter;
    }
    
    if (bbox31.width() != 0 && bbox31.height() != 0)
    {
        searchCriteria->bbox31 = bbox31;
    }
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    NSMutableSet<NSNumber *> *processedPoi = [NSMutableSet set];
  
    search->performTravelGuidesSearch(QString::fromNSString(reader), *searchCriteria,
                                      [&arr, &location, &processedPoi, &publish, &done](const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
        
                                if (![processedPoi containsObject:@(am->id.id)])
                                {
                                    [processedPoi addObject:@(am->id.id)];
                                    OAPOI *poi = [OAPOIHelper parsePOI:resultEntry withValues:YES withContent:YES];
                                    poi.distanceMeters = OsmAnd::Utilities::squareDistance31(location, am->position31);
                                    if (publish)
                                    {
                                        done = publish(poi);
                                    }
                                    else
                                    {
                                        [arr addObject:poi];
                                    }
                                }
                          },
                          ctrl);
    
    return [NSArray arrayWithArray:arr];
}

- (NSArray<OAPOI *> *) findTravelGuidesByKeyword:(NSString *)keyword categoryNames:(NSArray<NSString *> *)categoryNames poiTypeName:(NSString *)typeName location:(OsmAnd::PointI)location bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader publish:(BOOL(^)(OAPOI *poi))publish
{
    _isSearchDone = NO;
    _breakSearch = NO;

    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                            return _isSearchDone || _breakSearch || _limitCounter < 0;
                                       }));
    
    _limitCounter = _searchLimit;
    _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    
    const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(keyword ? keyword : @"");
    searchCriteria->obfInfoAreaFilter = _visibleArea;
    searchCriteria->bbox31 = bbox31;
    searchCriteria->xy31 = location;
    
    if (categoryNames)
    {
        auto categoriesFilter = QHash<QString, QStringList>();
        QStringList categories = QStringList();
        for (NSString *categoryName in categoryNames)
            categories.append(QString::fromNSString(categoryName));
        
        categoriesFilter.insert(QString::fromNSString(@"routes"), categories);
        searchCriteria->categoriesFilter = categoriesFilter;
    }
    
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    NSMutableSet<NSNumber *> *processedPoi = [NSMutableSet set];
    
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));
    
    search->performTravelGuidesSearch(QString::fromNSString(reader),
                                      *searchCriteria,
                                      [self, &processedPoi, &arr, &publish]
                                        (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                                        {
                                            const auto &am = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;

                                            OAPOI *poi = [OAPOIHelper parsePOI:resultEntry withValues:YES withContent:YES];
                                            poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, am->position31);
                                            
                                            if (publish)
                                            {
                                                _isSearchDone = publish(poi);
                                            }
                                            
                                            [arr addObject:poi];
                                            _limitCounter--;
                                        },
                                        ctrl);
    
    _isSearchDone = YES;
    
    return [NSArray arrayWithArray:arr];
}

+ (OAPOIRoutePoint *) distFromLat:(double)latitude longitude:(double)longitude locations:(NSArray<CLLocation *> *)locations radius:(double)radius
{
    double dist = radius + 0.1;
    CLLocation *l = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    OAPOIRoutePoint *rp = nil;
    // Special iterations because points stored by pairs!
    for (int i = 1; i < locations.count; i += 2)
    {
        double d = [OAMapUtils getOrthogonalDistance:l fromLocation:locations[i - 1] toLocation:locations[i]];
        if (d < dist)
        {
            rp = [[OAPOIRoutePoint alloc] init];
            dist = d;
            rp.deviateDistance = dist;
            rp.pointA = locations[i - 1];
            rp.pointB = locations[i];
        }
    }
    if (rp && rp.deviateDistance != 0 && rp.pointA && rp.pointB)
    {
        rp.deviationDirectionRight = [OAMapUtils rightSide:latitude lon:longitude aLat:rp.pointA.coordinate.latitude aLon:rp.pointA.coordinate.longitude bLat:rp.pointB.coordinate.latitude bLon:rp.pointB.coordinate.longitude];
    }
    return rp;
}

+ (NSArray<OAPOI *> *) searchPOIsOnThePath:(NSArray<CLLocation *> *)locations radius:(double)radius filter:(OASearchPoiTypeFilter *)filter matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    NSMutableArray<OAPOI *> *arr = [NSMutableArray array];
    if (locations && locations.count > 0 && filter && ![filter isEmpty])
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
        
        CLLocationDegrees topLatitude = locations[0].coordinate.latitude;
        CLLocationDegrees bottomLatitude = locations[0].coordinate.latitude;
        CLLocationDegrees leftLongitude = locations[0].coordinate.longitude;
        CLLocationDegrees rightLongitude = locations[0].coordinate.longitude;
        for (CLLocation *l in locations)
        {
            topLatitude = MAX(topLatitude, l.coordinate.latitude);
            bottomLatitude = MIN(bottomLatitude, l.coordinate.latitude);
            leftLongitude = MIN(leftLongitude, l.coordinate.longitude);
            rightLongitude = MAX(rightLongitude, l.coordinate.longitude);
        }        
        OsmAnd::PointI topLeftPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
        OsmAnd::PointI bottomRightPoint31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
        searchCriteria->obfInfoAreaFilter = OsmAnd::AreaI(topLeftPoint31, bottomRightPoint31);
        
        double coeff = (double) (radius / OsmAnd::Utilities::getTileDistanceWidth(kZoomToSearchPOI));

        NSMapTable<NSNumber *, NSMutableArray<CLLocation *> *> *zooms = [NSMapTable strongToStrongObjectsMapTable];
        for (NSInteger i = 1; i < locations.count; i++)
        {
            CLLocation *cr = locations[i];
            CLLocation *pr = locations[i - 1];
            double tx = OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, cr.coordinate.longitude);
            double ty = OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, cr.coordinate.latitude);
            double px = OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, pr.coordinate.longitude);
            double py = OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, pr.coordinate.latitude);
            double topLeftX = MIN(tx, px) - coeff;
            double topLeftY = MIN(ty, py) - coeff;
            double bottomRightX = MAX(tx, px) + coeff;
            double bottomRightY = MAX(ty, py) + coeff;
            for (int x = (int) topLeftX; x <= bottomRightX; x++)
            {
                for (int y = (int) topLeftY; y <= bottomRightY; y++)
                {
                    NSNumber *hash = [NSNumber numberWithLongLong:((((long long) x) << (long)kZoomToSearchPOI) + y)];
                    NSMutableArray<CLLocation *> *ll = [zooms objectForKey:hash];
                    if (!ll)
                    {
                        ll = [NSMutableArray array];
                        [zooms setObject:ll forKey:hash];
                    }
                    [ll addObject:pr];
                    [ll addObject:cr];
                }
            }
            
        }
        int sleft = INT_MAX;
        int sright = 0;
        int stop = INT_MAX;
        int sbottom = 0;
        for (NSNumber *n in zooms.keyEnumerator)
        {
            long long vl = n.longLongValue;
            long long x = (vl >> (long)kZoomToSearchPOI) << (31 - (long)kZoomToSearchPOI);
            long long y = (vl & ((1 << (long)kZoomToSearchPOI) - 1)) << (31 - (long)kZoomToSearchPOI);
            sleft = (int) MIN(x, sleft);
            stop = (int) MIN(y, stop);
            sbottom = (int) MAX(y, sbottom);
            sright = (int) MAX(x, sright);
        }
        searchCriteria->bbox31 = OsmAnd::AreaI(OsmAnd::PointI(sleft, stop), OsmAnd::PointI(sright, sbottom));

        searchCriteria->tileFilter = [&zooms] (const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoomLevel)
        {
            long long zx = (long)tileId.x << ((long)kZoomToSearchPOI - zoomLevel);
            long long zy = (long)tileId.y << ((long)kZoomToSearchPOI - zoomLevel);
            NSNumber *hash = [NSNumber numberWithLongLong:((zx << (long)kZoomToSearchPOI) + zy)];
            return [zooms objectForKey:hash] != nil;
        };
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [&arr, &filter, &matcher, &radius, &zooms]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  OAPOIType *type = [OAPOIHelper parsePOITypeByAmenity:amenity];
                                  if (type && [filter accept:type.category subcategory:type.name])
                                  {
                                      OAPOI *poi = [OAPOIHelper parsePOIByAmenity:amenity type:type];
                                      if (poi)
                                      {
                                          if (radius > 0)
                                          {
                                              double lat = poi.latitude;
                                              double lon = poi.longitude;
                                              long long x = (long long) OsmAnd::Utilities::getTileNumberX(kZoomToSearchPOI, lon);
                                              long long y = (long long) OsmAnd::Utilities::getTileNumberY(kZoomToSearchPOI, lat);
                                              NSNumber *hash = [NSNumber numberWithLongLong:(x << (long)kZoomToSearchPOI) | y];
                                              NSMutableArray<CLLocation *> *locs = [zooms objectForKey:hash];
                                              if (!locs)
                                                  return;
                                              
                                              OAPOIRoutePoint *routePoint = [OAPOIHelper distFromLat:lat longitude:lon locations:locs radius:radius];
                                              if (!routePoint)
                                                  return;
                                              else
                                                  poi.routePoint = routePoint;
                                          }
                                          
                                          if (matcher)
                                              [matcher publish:poi];
                                          
                                          [arr addObject:poi];
                                      }
                                  }
                              },
                              ctrl);
    }
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findPOIsByFilter:(OASearchPoiTypeFilter *)filter topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
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
        NSMutableSet<NSNumber *> *processedPoi = [NSMutableSet set];
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [&arr, &filter, &matcher, &processedPoi]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  const auto& amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
                                  if (![processedPoi containsObject:@(amenity->id.id)])
                                  {
                                      [processedPoi addObject:@(amenity->id.id)];
                                      OAPOIType *type = [OAPOIHelper parsePOITypeByAmenity:amenity];
                                      if (type && [filter accept:type.category subcategory:type.name])
                                      {
                                          OAPOI *poi = [OAPOIHelper parsePOIByAmenity:amenity type:type];
                                          if (poi)
                                          {
                                              if (matcher)
                                                  [matcher publish:poi];
                                              
                                              [arr addObject:poi];
                                          }
                                      }
                                  }
                              },
                              ctrl);
    }
    return [NSArray arrayWithArray:arr];
}

+ (NSArray<OAPOI *> *) findPOIsByName:(NSString *)query topLatitude:(double)topLatitude leftLongitude:(double)leftLongitude bottomLatitude:(double)bottomLatitude rightLongitude:(double)rightLongitude matcher:(OAResultMatcher<OAPOI *> *)matcher
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

+ (OAPOI *) parsePOI:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    return [self.class parsePOI:resultEntry withValues:YES withContent:YES];
}

+ (OAPOI *) parsePOI:(const OsmAnd::ISearch::IResultEntry&)resultEntry withValues:(BOOL)withValues withContent:(BOOL)withContent
{
    const auto& amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
    OAPOIType *type = [self.class parsePOITypeByAmenity:amenity];
    return [self.class parsePOIByAmenity:amenity type:type withValues:withValues withContent:withContent];
}

+ (OAPOIType *) parsePOITypeByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIHelper *helper = [OAPOIHelper sharedInstance];
    OAPOIType *type = nil;
    if (!amenity->categories.isEmpty() && ![[OAAppSettings sharedManager] isTypeDisabled:amenity->subType.toNSString()])
    {
        const auto& catList = amenity->getDecodedCategories();
        if (!catList.isEmpty())
        {
            NSString *category = catList.first().category.toNSString();
            NSString *subCategory = catList.first().subcategory.toNSString();
            
            type = [helper getPoiTypeByCategory:category name:subCategory];
            if (!type)
            {
                OAPOICategory *c = [[OAPOICategory alloc] initWithName:category];
                type = [[OAPOIType alloc] initWithName:subCategory category:c];
                type.nameLocalized = [helper getPhrase:type];
                type.nameLocalizedEN = [helper getPhraseEN:type];
            }
        }
    }
    return type;
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity
{
    OAPOIType *type = [self.class parsePOITypeByAmenity:amenity];
    return [self.class parsePOIByAmenity:amenity type:type];
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity type:(OAPOIType *)type
{
    return [self.class parsePOIByAmenity:amenity type:type withValues:YES withContent:YES];
}

+ (OAPOI *) parsePOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity type:(OAPOIType *)type withValues:(BOOL)withValues withContent:(BOOL)withContent
{
    if (!type || type.mapOnly || [[OAAppSettings sharedManager] isTypeDisabled:amenity->subType.toNSString()])
        return nil;
    
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
    
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    [OAPOIHelper processDecodedValues:amenity->getDecodedValues() content:(withContent ? content : nil) values:(withValues ? values : nil)];
    poi.values = values;
    poi.localizedContent = content;
    
    if (!poi.nameLocalized)
        poi.nameLocalized = poi.name;
    
    poi.type = type;
    poi.subType = amenity->subType.toNSString();

    if (poi.name.length == 0)
        poi.name = type.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = type.nameLocalized;

    if (names.count == 0)
    {
        NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        NSString *transliterated = type.nameLocalized && type.nameLocalized.length > 0 ? OsmAnd::ICU::transliterateToLatin(QString::fromNSString(type.nameLocalized)).toNSString() : @"";
        [names setObject:transliterated forKey:@""];
        [names setObject:type.nameLocalized forKey:lang ? lang : @""];
        [names setObject:type.nameLocalizedEN forKey:@"en"];
    }
    poi.localizedNames = names;
    
    return poi;
}

+ (void) fetchValuesContentPOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity poi:(OAPOI *)poi
{
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    [OAPOIHelper processDecodedValues:amenity->getDecodedValues() content:content values:values];
    poi.values = values;
    poi.localizedContent = content;
}

+ (UIImage *)getCustomFilterIcon:(OAPOIUIFilter *) filter
{
    UIImage *customFilterIcon = nil;
    if (filter != nil)
    {
        NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *acceptedTypes = [filter getAcceptedTypes];
        NSArray<OAPOICategory *> *categories = [NSArray arrayWithArray:acceptedTypes.keyEnumerator.allObjects];
        if (categories.count == 1)
        {
            OAPOICategory *category = categories[0];
            NSMutableSet<NSString *> *filters = [acceptedTypes objectForKey:category];
            if (filters != nil && filters.count == 1)
            {
                NSString *filterName = filters.allObjects[0];
                OAPOIBaseType *customFilter = [[OAPOIHelper sharedInstance] getAnyPoiTypeByName:filterName];
                customFilterIcon = customFilter.icon;
            }
            else
            {
                customFilterIcon = category.icon;
            }
        }
        else
        {
            customFilterIcon = [UIImage templateImageNamed:@"ic_custom_search_categories"];
        }
    }
    return customFilterIcon;
}

- (BOOL) breakSearch
{
    _breakSearch = !_isSearchDone;
    return _breakSearch;
}

- (BOOL) isNameTag:(NSString *)tag
{
    for (NSString *prefix in kNameTagPrefixes)
    {
        if ([tag hasPrefix:prefix])
            return YES;
    }
    
    return NO;
}

- (void) onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry
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

- (void) onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry poi:(OAPOI *)poi
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

-(NSDictionary<NSString *, OAPOIType *> *)getAllTranslatedNames:(BOOL)skipNonEditable
{
    NSMutableDictionary<NSString *, OAPOIType *> *result = [NSMutableDictionary new];
    for (int i = 0; i < [_poiCategories count]; i++) {
        OAPOICategory *pc = _poiCategories[i];
        if (skipNonEditable && pc.nonEditableOsm)
            continue;
        [self addPoiTypesTranslation:skipNonEditable translation:result poiCategory:pc];
    }
    return result;
}

-(void)addPoiTypesTranslation:(BOOL)skipNonEditable translation:(NSMutableDictionary<NSString *, OAPOIType *> *)translation poiCategory:(OAPOICategory *)category
{
    for (OAPOIType *pt in category.poiTypes) {
        if (pt.reference)
            continue;
        if (pt.baseLangType) {
            continue;
        }
        if (skipNonEditable && pt.nonEditableOsm)
            continue;
        
        [translation setObject:pt forKey:[[pt.name stringByReplacingOccurrencesOfString:@"_" withString:@" "] lowerCase]];
        [translation setObject:pt forKey:[pt.nameLocalized lowerCase]];
//        
//        translation.put(pt.getKeyName().replace('_', ' ').toLowerCase(), pt);
//        translation.put(pt.getTranslation().toLowerCase(), pt);
    }
}

+ (NSString *)processLocalizedNames:(const QHash<QString, QString> &)localizedNames nativeName:(const QString &)nativeName names:(NSMutableDictionary *)names
{
    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;

    const QString lang = (prefLang ? QString::fromNSString(prefLang) : QString());
    QString nameLocalized;
    BOOL hasEnName = NO;
    QString enName;
    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(localizedNames)))
    {
        if (!lang.isNull() && entry.key() == lang)
            nameLocalized = entry.value();
        
        [names setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
        if (!hasEnName && entry.key().toLower() == QStringLiteral("en"))
        {
            hasEnName = YES;
            enName = entry.value();
        }
    }
    
    if (!hasEnName && !nativeName.isEmpty())
        [names setObject:OsmAnd::ICU::transliterateToLatin(nativeName).toNSString() forKey:@"en"];
    
    if (nameLocalized.isNull())
        nameLocalized = nativeName;
    
    if (![names objectForKey:@""] && !nativeName.isEmpty())
        [names setObject:nativeName.toNSString() forKey:@""];
    
    if (transliterate && hasEnName)
        nameLocalized = enName;
    else if (transliterate && !nameLocalized.isNull() )
        nameLocalized = OsmAnd::ICU::transliterateToLatin(nameLocalized);
    
    return nameLocalized.isNull() ? @"" : nameLocalized.toNSString();
}

+ (void) processDecodedValues:(const QList<OsmAnd::Amenity::DecodedValue> &)decodedValues content:(NSMutableDictionary *)content values:(NSMutableDictionary *)values
{
    for (const auto& entry : OsmAnd::constOf(decodedValues))
    {
        if (entry.declaration->tagName.startsWith(QStringLiteral("content")))
        {
            if (content)
            {
                NSString *loc;
                if (entry.declaration->tagName.length() > 8)
                {
                    NSString *key = entry.declaration->tagName.toNSString();
                    loc = [[key substringFromIndex:8] lowercaseString];
                }
                else
                {
                    loc = @"";
                }
                [content setObject:entry.value.toNSString() forKey:loc];
            }
        }
        else if (values)
        {
            [values setObject:entry.value.toNSString() forKey:entry.declaration->tagName.toNSString()];
        }
    }
}

@end
