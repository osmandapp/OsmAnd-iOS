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

#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/Data/DataCommonTypes.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Search/ISearch.h>
#include <OsmAndCore/Search/BaseSearch.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAPOIHelper {

    OsmAndAppInstance _app;
    int _limitCounter;
    BOOL _breakSearch;
    NSDictionary *_phrases;

    OsmAnd::AreaI _visibleArea;
    OsmAnd::ZoomLevel _zoomLevel;
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
    if (!_phrases) {
        
        NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml"];
        
        OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
        [parser getPhrasesSync:phrasesXmlPath];
        _phrases = parser.phrases;
    }
    
    if (_phrases.count > 0) {
        for (OAPOIType *poiType in _poiTypes) {
            poiType.nameLocalized = [self getPhrase:poiType.name];
            poiType.categoryLocalized = [self getPhrase:poiType.category];
            poiType.filter = [self getPhrase:poiType.filter];
        }
        for (OAPOICategory *c in _poiCategories.allKeys) {
            c.nameLocalized = [self getPhrase:c.name];
        }
    }
}

-(NSString *)getPhrase:(NSString *)name 
{
    NSString *phrase = [_phrases objectForKey:[NSString stringWithFormat:@"poi_%@", name]];
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

-(void)setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom
{
    _visibleArea = area;
    _zoomLevel = zoom;
}

-(void)findPOIsByKeyword:(NSString *)keyword
{
    [self findPOIsByKeyword:keyword categoryName:nil poiTypeName:nil radiusMeters:0.0];
}

-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radiusMeters:(double)radius
{
    _isSearchDone = NO;
    _breakSearch = NO;
    
    const auto& obfsCollection = _app.resourcesManager->obfsCollection;
    
    OsmAnd::FunctorQueryController *ctrl = new OsmAnd::FunctorQueryController([self]
                                       (const OsmAnd::FunctorQueryController* const controller)
                                       {
                                           // should break?
                                           return _limitCounter < 0 || _breakSearch;
                                       });
    
    _limitCounter = _searchLimit;
    
    
    if (radius == 0.0) {
        
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
        
        QHash<QString, QStringList> *categoriesFilter = new QHash<QString, QStringList>();
        if (categoryName && typeName) {
            categoriesFilter->insert(QString::fromNSString(categoryName), QStringList(QString::fromNSString(typeName)));
        } else if (categoryName) {
            categoriesFilter->insert(QString::fromNSString(categoryName), QStringList());
        }
        searchCriteria->categoriesFilter = *categoriesFilter;
        searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, _myLocation);
        
        const auto search = std::shared_ptr<const OsmAnd::AmenitiesInAreaSearch>(new OsmAnd::AmenitiesInAreaSearch(obfsCollection));
        search->performSearch(*searchCriteria,
                              [self]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  [self onPOIFound:resultEntry];
                              },
                              ctrl);
        free(categoriesFilter);
    }
    
    free(ctrl);
    
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
    poi.nameLocalized = amenity->nativeName.toNSString();
    
    if (amenity->categories.isEmpty())
        return;
    
    //for (const auto catIds : amenity->categories)
    //    NSLog(@"catId (%d) main=%d sub=%d", amenity->categories.count(), catIds.getMainCategoryIndex(), catIds.getSubCategoryIndex());
    
    const auto& catList = amenity->getDecodedCategories();
    if (catList.isEmpty())
        return;
    NSString *category = catList.keys().first().toNSString();
    NSString *subCategory = catList.value(catList.keys().first()).first().toNSString();
    
    OAPOIType *type = [[OAPOIType alloc] init];
    type.category = category;
    type.name = subCategory;
    type.nameLocalized = [self getPhrase:subCategory];
    poi.type = type;
    
    _limitCounter--;
    
    if (_delegate)
        [_delegate poiFound:poi];
}

@end
