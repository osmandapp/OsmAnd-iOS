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
#import "OAPhrasesParser.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"

#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>

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
        [self updateReferences];
        [self updatePhrases];
    }
    return self;
}

- (void)readPOI
{
    NSString *poiXmlPath = [[NSBundle mainBundle] pathForResource:@"poi_types" ofType:@"xml"];
    
    OAPOIParser *parser = [[OAPOIParser alloc] init];
    [parser getPOITypesSync:poiXmlPath];
    _poiTypes = parser.poiTypes;
    _poiCategories = parser.poiCategories;
    _poiFilters = parser.poiFilters;
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
            }
        }
    }
}

- (OAPOIType *)getPoiTypeByName:(NSString *)name
{
    for (OAPOIType *p in _poiTypes)
        if ([p.name isEqualToString:name] && !p.reference)
            return p;

    return nil;
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
            }
        }
        for (OAPOICategory *c in _poiCategories)
        {
            c.nameLocalized = [self getPhrase:c];
            for (OAPOIType *add in c.poiAdditionals)
            {
                add.nameLocalized = [self getPhrase:add];
            }
        }
        for (OAPOIFilter *f in _poiFilters)
        {
            f.nameLocalized = [self getPhrase:f];
            for (OAPOIType *add in f.poiAdditionals)
            {
                add.nameLocalized = [self getPhrase:add];
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
                }
            }
        }
    }
}

-(NSString *)getPhrase:(OAPOIBaseType *)type
{
    if (type.baseLangType)
    {
        return [NSString stringWithFormat:@"%@ (%@)", [self getPhrase:type.baseLangType], [OAUtilities translatedLangName:type.lang]];
    }
    
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", type.name]];
    if (!phrase)
    {
        return [[type.name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    else
    {
        return phrase;
    }
}

-(NSString *)getPhraseEN:(OAPOIBaseType *)type
{
    if (type.baseLangType)
    {
        return [self getPhraseEN:type.baseLangType];
    }

    NSString *phrase = [_phrasesEN objectForKey:[NSString stringWithFormat:@"poi_%@", type.name]];
    if (!phrase)
    {
        return [[type.name capitalizedString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    else
    {
        return phrase;
    }
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

- (OAPOIType *)getPoiTypeByCategory:(NSString *)category name:(NSString *)name
{
    for (OAPOIType *t in _poiTypes)
        if ([t.category.name isEqualToString:category] && [t.name isEqualToString:name])
            return t;
    
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
        searchCriteria->sourceFilter = ([self]
                                        (const std::shared_ptr<const OsmAnd::ObfInfo>& obfInfo)
                                        {
                                            return obfInfo->containsDataFor(&_visibleArea, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI));
                                            
                                        });
        
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
        
        searchCriteria->sourceFilter = ([self]
                                        (const std::shared_ptr<const OsmAnd::ObfInfo>& obfInfo)
                                        {
                                            return true;
                                            //return obfInfo->containsDataFor(&_visibleArea, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI));
                                            
                                        });
        
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

-(BOOL)breakSearch
{
    _breakSearch = !_isSearchDone;
    return _breakSearch;
}

-(void)onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latLon.latitude;
    poi.longitude = latLon.longitude;
    poi.name = amenity->nativeName.toNSString();
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];

    const QString lang = (_prefLang ? QString::fromNSString(_prefLang) : QString::null);
    for(const auto& entry : OsmAnd::rangeOf(amenity->localizedNames))
    {
        if (lang != QString::null && entry.key() == lang)
            poi.nameLocalized = entry.value().toNSString();

        [names setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
    }
    
    if (![names objectForKey:@""])
        [names setObject:poi.name forKey:@""];
    
    poi.localizedNames = [NSDictionary dictionaryWithDictionary:names];
    poi.distanceMeters = OsmAnd::Utilities::squareDistance31(_myLocation, amenity->position31);
    
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    const auto& decodedValues = amenity->getDecodedValues();
    for (const auto& entry : decodedValues)
    {
        [values setObject:entry.value.toString().toNSString() forKey:entry.declaration->tagName.toNSString()];
    }
    poi.values = values;
    
    if (!poi.nameLocalized)
        poi.nameLocalized = amenity->nativeName.toNSString();

    if (amenity->categories.isEmpty())
        return;
        
    const auto& catList = amenity->getDecodedCategories();
    if (catList.isEmpty())
        return;
    
    NSString *category = catList.first().category.toNSString();
    NSString *subCategory = catList.first().subcategory.toNSString();
    
    OAPOIType *type = [self getPoiTypeByCategory:category name:subCategory];
    if (!type)
    {
        OAPOICategory *c = [[OAPOICategory alloc] initWithName:category];
        type = [[OAPOIType alloc] initWithName:subCategory category:c];
        type.nameLocalized = [self getPhrase:type];
        type.nameLocalizedEN = [self getPhraseEN:type];
    }
    poi.type = type;
    
    if (type.mapOnly)
        return;
    
    if (poi.name.length == 0)
        poi.name = type.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = type.nameLocalized;
    
    _limitCounter--;
    
    if (_delegate)
        [_delegate poiFound:poi];
}

@end
