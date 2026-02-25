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
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OANativeUtilities.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/ICU.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/MapObject.h>

static NSArray<NSString *> *const kNameTagPrefixes = @[@"name", @"int_name", @"nat_name", @"reg_name", @"loc_name", @"old_name", @"alt_name", @"short_name", @"official_name", @"lock_name"];

NSString * const OSM_WIKI_CATEGORY = @"osmwiki";
NSString * const SPEED_CAMERA = @"speed_camera";
NSString * const WIKI_LANG = @"wiki_lang";
NSString * const WIKI_PLACE = @"wiki_place";
NSString * const ROUTE_ARTICLE_POINT = @"route_article_point";

@implementation OAPOIHelper {

    OsmAndAppInstance _app;
    NSDictionary *_phrases;
    NSDictionary *_phrasesEN;
    NSArray<OAPOIType *> *_textPoiAdditionals;
    NSDictionary<NSString *, NSString *> *_poiTypeOptionalIcons;
    NSDictionary<NSString *, NSString *> *_poiAdditionalCategoryIcons;
    NSMapTable<NSString *, NSString *> *_deprecatedTags;
    NSMutableArray<NSString *> *_publicTransportTypes;

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
    _poiTypeOptionalIcons = parser.poiTypeOptionalIcons;
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

- (NSMutableArray<NSString *> *) getPublicTransportTypes
{
    if (!_publicTransportTypes && _isInit)
    {
        OAPOICategory *category = [self getPoiCategoryByName:@"transportation"];
        if (category)
        {
            _publicTransportTypes = [NSMutableArray new];
            NSArray<OAPOIFilter *> *filters = category.poiFilters;
            for (OAPOIFilter *poiFilter in filters)
            {
                if ([poiFilter.name isEqualToString:@"public_transport"] ||
                    [poiFilter.name isEqualToString:@"water_transport"] )
                {
                    for (OAPOIType *poiType in poiFilter.poiTypes)
                    {
                        [_publicTransportTypes addObject:poiType.name];
                        for (OAPOIType *poiAdditionalType in poiType.poiAdditionals)
                        {
                            [_publicTransportTypes addObject:poiAdditionalType.name];
                        }
                    }
                }
            }
        }
    }
    return _publicTransportTypes;
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
    return [self getPhraseByName:name withDefatultValue:YES];
}

- (NSString *) getPhraseByName:(NSString *)name withDefatultValue:(BOOL)withDefatultValue
{
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", [name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
    if (!phrase)
    {
        return withDefatultValue ? [[name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "] : nil;
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

- (NSString *) getTranslation:(NSString *)keyName
{
    NSString *val = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", keyName]];
    if (val)
    {
        int i = [val indexOf:@";"];
        if (i > 0) {
            return [val substringToIndex:i];
        }
        return val;
    }
    return nil;
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
    {
        if ([t.tag isEqualToString:tag] && [t.value isEqualToString:value])
            return t;
        if ([t.tag isEqualToString:[tag stringByReplacingOccurrencesOfString:@"osmand_" withString:@""]] && [t.value isEqualToString:value])
            return t;
    }
    
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
    
    
    NSString *localName = poi.nameLocalized;
    if (typeName && [localName indexOf:typeName] != -1)
    {
        // type is contained in name e.g.
        // localName = "Bakery the Corner"
        // type = "Bakery"
        // no need to repeat this
        return localName;
    }
    if (NSStringIsEmpty(localName) && poi.isRouteTrack)
        localName = [poi getAdditionalInfo:ROUTE_ID];
    
    if (localName.length == 0)
        return typeName;

    return [NSString stringWithFormat:@"%@ %@", typeName, localName];
}

- (NSString *) getFormattedOpeningHours:(OAPOI *)poi
{
    const int intervalMinutes = 120;
    const int arrLength = intervalMinutes / 5;
    int minutesArr[arrLength];
    int k = 0;
    for (int i = 0; i < arrLength; i++)
    {
        minutesArr[i] = k;
        k += 5;
    }
    
    auto parser = OpeningHoursParser::parseOpenedHours([poi.openingHours UTF8String]);
    if (!parser)
        return @"";
    BOOL isOpenedNow = parser->isOpened();
    NSDate *newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + intervalMinutes * 60];
    BOOL isOpened = parser->isOpenedForTime([newTime toTm]);
    if (isOpened == isOpenedNow)
        return (isOpenedNow ? OALocalizedString(@"shared_string_is_open") : OALocalizedString(@"time_closed"));
    
    int imax = arrLength - 1;
    int imin = 0;
    int imid;
    while (imax >= imin)
    {
        imid = (imin + imax) / 2;
        newTime = [NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 + minutesArr[imid] * 60];
        BOOL isOpened = parser->isOpenedForTime([newTime toTm]);
        if (isOpened == isOpenedNow)
            imin = imid + 1;
        else
            imax = imid - 1;
    }
    
    int hours, minutes, seconds;
    [OAUtilities getHMS:minutesArr[imid] * 60 hours:&hours minutes:&minutes seconds:&seconds];
    NSMutableString *timeStr = [NSMutableString string];
    if (hours > 0)
        [timeStr appendFormat:@"%d %@", hours, OALocalizedString(@"int_hour")];
    if (minutes > 0)
        [timeStr appendFormat:@"%@%d %@", (timeStr.length > 0 ? @" " : @""), minutes, OALocalizedString(@"int_min")];
    return (isOpenedNow ? [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"will_close_at"), timeStr] : [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"time_will_open"), timeStr]);
}

- (NSString *) getAmenityDistanceFormatted:(OAPOI *)amenity
{
    NSString *distanceTag = amenity.values[OATravelGpx.DISTANCE];
    if (!NSStringIsEmpty(distanceTag))
    {
        float km = [distanceTag floatValue];
        if (km > 0)
        {
            if (![distanceTag containsString:@"."])
            {
                // Before 1 Apr 2025 distance format was MMMMM (meters, no fractional part).
                // Since 1 Apr 2025 format has been fixed to KM.D (km, 1 fractional digit).
                km /= 1000;
            }
        }
        return [OAOsmAndFormatter getFormattedDistance:km * 1000 withParams:[OsmAndFormatterParams noTrailingZeros]];
    }
    return nil;
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

- (NSString *) getPoiTypeOptionalIcon:(NSString *)type
{
    return [_poiTypeOptionalIcons objectForKey:type];
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

+ (void) fetchValuesContentPOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity poi:(OAPOI *)poi
{
    MutableOrderedDictionary *content = [MutableOrderedDictionary new];
    MutableOrderedDictionary *values = [MutableOrderedDictionary new];
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

- (BOOL) isNameTag:(NSString *)tag
{
    for (NSString *prefix in kNameTagPrefixes)
    {
        if ([tag hasPrefix:prefix])
            return YES;
    }
    
    return NO;
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
        QString key = entry.key().trimmed().toLower();
        if (key.startsWith(QStringLiteral("name:")))
            key = key.mid(5);

        if (!lang.isNull() && key == lang)
            nameLocalized = entry.value();
        
        [names setObject:entry.value().toNSString() forKey:key.toNSString()];
        if (!hasEnName && key == QStringLiteral("en"))
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

+ (void) processDecodedValues:(const QList<OsmAnd::Amenity::DecodedValue> &)decodedValues content:(MutableOrderedDictionary *)content values:(MutableOrderedDictionary *)values
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
