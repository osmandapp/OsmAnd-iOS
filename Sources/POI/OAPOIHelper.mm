//
//  OAPOIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIParser.h"
#import "OAPhrasesParser.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAPOIHelper {

    OsmAndAppInstance _app;
    int _limitCounter;
    BOOL _breakSearch;
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
        _searchLimit = 50;
        _isSearchDone = YES;
        [self readPOI];
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
    
}

- (void)updatePhrases
{
    NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml"];
    
    OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
    [parser getPhrasesSync:phrasesXmlPath];
    
    if (parser.phrases.count > 0) {
        for (OAPOIType *poiType in _poiTypes) {
            poiType.nameLocalized = [self getPhrase:poiType.name parser:parser];
            poiType.categoryLocalized = [self getPhrase:poiType.category parser:parser];
            poiType.filter = [self getPhrase:poiType.filter parser:parser];
        }
        for (OAPOICategory *c in _poiCategories.allKeys) {
            c.nameLocalized = [self getPhrase:c.name parser:parser];
        }
    }
}

-(NSString *)getPhrase:(NSString *)name parser:(OAPhrasesParser *)parser
{
    NSString *phrase = [parser.phrases objectForKey:[NSString stringWithFormat:@"poi_%@", name]];
    if (!phrase)
        return name;
    else
        return phrase;
}

- (NSArray *)poiTypesForCategory:(NSString *)categoryName;
{
    for (OAPOICategory *c in _poiCategories.allKeys)
        if ([c.name isEqualToString:categoryName])
            return [_poiCategories objectForKey:c];

    return nil;
}

-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName
{
    NSLog(@"++++++++++++++++++++++++");

    _isSearchDone = NO;
    _breakSearch = NO;
    
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));
    const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);

    searchCriteria->name = QString::fromNSString(keyword ? keyword : @"");
    QHash<QString, QStringList> *categoriesFilter = new QHash<QString, QStringList>();
    if (categoryName && typeName) {
        categoriesFilter->insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
    } else if (categoryName) {
        categoriesFilter->insert(QString::fromNSString(categoryName), QStringList());
    }

    searchCriteria->categoriesFilter = *categoriesFilter;
    searchCriteria->sourceFilter = ([self]
                                    (const std::shared_ptr<const OsmAnd::ObfInfo>& obfInfo)
                                    {
                                        for (const auto& mapSection : obfInfo->mapSections) {
                                            NSLog(@"obfMapName = %@", mapSection->name.toNSString());
                                        }
                                        
                                        return true;
                                    });
    
    OsmAnd::FunctorQueryController *ctrl = new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                           return _limitCounter < 0 || _breakSearch;
                                       });
    
    _limitCounter = _searchLimit;
    
    search->performSearch(*searchCriteria,
                          [self]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              [self onPOIFound:resultEntry];
                          },
                          ctrl);
    free(ctrl);
    free(categoriesFilter);
    
    _isSearchDone = YES;
    
    if (_delegate)
        [_delegate searchDone:_breakSearch];

    NSLog(@"---------------------------");

}

-(void)breakSearch
{
    _breakSearch = YES;
}

-(void)onPOIFound:(const OsmAnd::ISearch::IResultEntry&)resultEntry
{
    const auto amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(amenity->position31);
    //NSLog(@"amenity.nativeName = %@ lat = %f, lon = %f", amenity->nativeName.toNSString(), latLon.latitude, latLon.longitude);
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latLon.latitude;
    poi.longitude = latLon.longitude;
    poi.name = amenity->nativeName.toNSString();
    poi.nameLocalized = amenity->nativeName.toNSString();
    
    //for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(amenity->localizedNames)))
    //{ NSLog(@"localized %@ = %@", entry.key().toNSString(), entry.value().toNSString()); }

    /*
    if (amenity->categories.isEmpty())
        return;
    const auto catIds = amenity->categories.first();
    NSLog(@"catId main=%d sub=%d", catIds.mainCategoryIndex, catIds.subCategoryIndex);
    
    const auto& values = amenity->getDecodedValues();
    
    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(values)))
    { NSLog(@"getDecodedValues %@ = %@", entry.key().toNSString(), entry.value().toNSString()); }

    const auto& catList = amenity->getDecodedCategories();
    if (catList.isEmpty())
        return;
    NSString *category = catList.keys().first().toNSString();
    NSString *subCategory = catList.value(catList.keys().first()).first().toNSString();
    NSLog(@"cat = %@ subCat = %@", category, subCategory);
    
    OAPOIType *type = [[OAPOIType alloc] init];
    type.name = @"poi_shop_name";
    type.nameLocalized = @"POI Type Name";
    poi.type = type;
     */
    
    _limitCounter--;
    
    if (_delegate)
        [_delegate poiFound:poi];
}

@end
