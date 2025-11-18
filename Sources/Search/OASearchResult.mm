//
//  OASearchResult.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchResult.java
//  git revision aea6f3ff8842b91fda4b471e24015e4142c52d13

#import "OASearchResult.h"
#import "OASearchPhrase.h"

#import "OAStreet.h"
#import "OACity.h"
#import "OASearchSettings.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"
#import "OAPOICategory.h"
#import "OAMapUtils.h"
#import "OASearchCoreFactory.h"
#import "OAArabicNormalizer.h"

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <OsmAndCore/ICU.h>
#include <OsmAndCore/Utilities.h>

#define MAX_TYPE_WEIGHT 10.0
#define HYPHEN "-"
#define NEAREST_METERS_LIMIT 30000
#define ALLDELIMITERS "\\s|,"
#define ALLDELIMITERS_WITH_HYPHEN "\\s|,|-"

@implementation CheckWordsMatchCount
@end

@implementation OASearchResult
{
    double _unknownPhraseMatchWeight;
    std::shared_ptr<const OsmAnd::Amenity> _amenity;
    std::shared_ptr<const OsmAnd::IFavoriteLocation> _favorite;
}

- (instancetype) initWithPhrase:(OASearchPhrase *)sp
{
    self = [super init];
    if (self)
    {
        self.preferredZoom = PREFERRED_DEFAULT_ZOOM;
        self.requiredSearchPhrase = sp;
        _unknownPhraseMatchWeight = 0;
    }
    return self;
}

// maximum corresponds to the top entry
- (double) unknownPhraseMatchWeight
{
    if (_unknownPhraseMatchWeight != 0)
        return _unknownPhraseMatchWeight;

    // normalize number to get as power, so we get numbers > 1
    _unknownPhraseMatchWeight = [self getSumPhraseMatchWeight:nil];
    return _unknownPhraseMatchWeight;
}

- (double) getSumPhraseMatchWeight:(OASearchResult *)exactResult
{
    double res = [OAObjectType getTypeWeight:_objectType];
    if ([_requiredSearchPhrase getUnselectedPoiType])
    {
        // search phrase matches poi type, then we lower all POI matches and don't check allWordsMatched
    }
    else if (_objectType == EOAObjectTypePoiType)
    {
        // don't overload with poi types
    }
    else
    {
        CheckWordsMatchCount *completeMatchRes = [[CheckWordsMatchCount alloc] init];
        bool matched = _localeName != nil && [self allWordsMatched:_localeName exactResult:exactResult cnt:completeMatchRes];
        if (!matched && _alternateName != nil && ![_alternateName isEqualToString:_cityName])
        {
            matched = [self allWordsMatched:_alternateName exactResult:exactResult cnt:completeMatchRes];
        }
        if (!matched && _otherNames != nil)
        {
            for (NSString *otherName : _otherNames)
            {
                if ([self allWordsMatched:otherName exactResult:exactResult cnt:completeMatchRes])
                {
                    matched = true;
                    break;
                }
            }
        }
        OACity * selectedCity = nil;
        if (exactResult != nil && [exactResult.object isKindOfClass:OAStreet.class])
        {
            selectedCity = [(OAStreet *) exactResult.object city];
        }
        else if (exactResult != nil && exactResult.parentSearchResult != nil && [exactResult.parentSearchResult.object isKindOfClass:OAStreet.class])
        {
            selectedCity =  [(OAStreet *) exactResult.parentSearchResult.object city];
        }
        if (matched && selectedCity != nil && [self.object isKindOfClass:OACity.class])
        {
            OACity * c = (OACity *) self.object;
            // city don't match because of boundary search -> lower priority
            if (![selectedCity.name isEqualToString:c.name])
            {
                matched = false;
                // for unmatched cities calculate how close street is to boundary
                // 1 - very close, 0 - very far
                std::vector<int32_t> bbox31 = selectedCity.city->bbox31;
                double lat = selectedCity.latitude;
                double lon = selectedCity.longitude;
                if (bbox31.size() > 0)
                {
                    // even center is shifted probably best to do combination of bbox & center
                    lon = OsmAnd::Utilities::get31LongitudeX(bbox31.at(0) / 2 + bbox31.at(2) / 2);
                    lat = OsmAnd::Utilities::get31LatitudeY(bbox31.at(1) / 2 + bbox31.at(3) / 2);
                }
                res += 100 / MAX(100, OsmAnd::Utilities::distance(self.location.coordinate.longitude, self.location.coordinate.latitude, lon, lat));
            }
        }
        // if all words from search phrase match (<) the search result words - we prioritize it higher
        if (matched)
            res = [self getPhraseWeightForCompleteMatch:completeMatchRes];
    }
    if (_parentSearchResult)
        // parent search result should not change weight of current result, so we divide by MAX_TYPES_BASE_10^2
        res = res + [_parentSearchResult getSumPhraseMatchWeight:(exactResult == nil ? self : exactResult)] / MAX_PHRASE_WEIGHT_TOTAL;
    
    return res;
}

- (double) getPhraseWeightForCompleteMatch:(CheckWordsMatchCount *)completeMatchRes
    {
        double res = [OAObjectType getTypeWeight:_objectType] * MAX_TYPES_BASE_10;
        // if all words from search phrase == the search result words - we prioritize it even higher
        if (completeMatchRes.allWordsEqual)
        {
            BOOL closeDistance = [_requiredSearchPhrase getLastTokenLocation] != nil && self.location != nil
                                && [OAMapUtils getDistance:([_requiredSearchPhrase getLastTokenLocation]).coordinate second:self.location.coordinate] <= NEAREST_METERS_LIMIT;
            if (_objectType != EOAObjectTypePoi || closeDistance)
                res = [OAObjectType getTypeWeight:_objectType] * MAX_TYPES_BASE_10 + MAX_PHRASE_WEIGHT_TOTAL / 2;
        }
        return res;
    }

- (BOOL)allWordsMatched:(NSString *)name exactResult:(OASearchResult *)exactResult cnt:(CheckWordsMatchCount *)cnt
{
    NSMutableArray<NSString *> *searchPhraseNamesArray = [self getSearchPhraseNames];
    QStringList searchPhraseNames;
    if ([name rangeOfString:@"("].location != NSNotFound) {
        name = [OASearchPhrase stripBraces:name];
    }
    for (NSString *searchPhraseName : searchPhraseNamesArray)
    {
        if ([OAArabicNormalizer isSpecialArabic:searchPhraseName]) {
            searchPhraseName = [OAArabicNormalizer normalize:searchPhraseName] ?: searchPhraseName;
        }
        searchPhraseNames.append(QString::fromNSString(searchPhraseName));
    }

    NSMutableArray<NSString *> *localResultNamesArray;
    if (![[_requiredSearchPhrase getFullSearchPhrase] containsString:@HYPHEN])
    {
        // we split '-' words in result, so user can input same without '-'
        localResultNamesArray = [OASearchPhrase splitWords:name ws:[NSMutableArray array] delimiters:@ALLDELIMITERS_WITH_HYPHEN];
    }
    else
    {
        localResultNamesArray = [OASearchPhrase splitWords:name ws:[NSMutableArray array] delimiters:@ALLDELIMITERS];
    }
    QStringList localResultNames;
    for (NSString *localResultName : localResultNamesArray)
        localResultNames.append(QString::fromNSString(localResultName));

    BOOL wordMatched;
    if (searchPhraseNames.isEmpty())
        return NO;
    while (exactResult != nil && exactResult != self) {
        NSMutableArray<NSString *> *lst = [exactResult getSearchPhraseNames];
        for (NSString *l in lst) {
            int i = searchPhraseNames.indexOf(QString::fromNSString(l));
            if (i != -1) {
                searchPhraseNames.removeAt(i);
            }
        }
        exactResult = exactResult.parentSearchResult;
    }
    
    int idxMatchedWord = -1;
    for (const auto& searchPhraseName : searchPhraseNames)
    {
        wordMatched = NO;
        for (int i = idxMatchedWord + 1; i < localResultNames.size(); i++)
        {
            QString localQString = localResultNames.at(i);
            NSString * localString = localQString.toNSString();
            if ([OAArabicNormalizer isSpecialArabic:localString]) {
                localString = [OAArabicNormalizer normalize:localString] ?: localString;
                localQString = QString::fromNSString(localString);
            }
            int r = OsmAnd::ICU::ccompare(searchPhraseName, localQString);
            if (r == 0)
            {
                wordMatched = YES;
                idxMatchedWord = i;
                break;
            }
        }
        if (!wordMatched)
            return NO;
    }
    if (searchPhraseNames.size() == localResultNames.size())
        cnt.allWordsEqual = YES;
    
    cnt.allWordsInPhraseAreInResult = YES;
    return YES;
}

-(NSMutableArray<NSString *> *) getSearchPhraseNames
{
    NSMutableArray<NSString *> *searchPhraseNames = [NSMutableArray array];
    
    NSString *fw = [_requiredSearchPhrase getFirstUnknownSearchWord];
    NSMutableArray<NSString *> *ow = [_requiredSearchPhrase getUnknownSearchWords];
    
    if (fw && [fw length] > 0)
        [searchPhraseNames addObject:fw];
    if (ow)
        [searchPhraseNames addObjectsFromArray:ow];
    // when parent result was recreated with same phrase (it doesn't have preselected word)
    // SearchCoreFactory.subSearchApiOrPublish
    if (self.parentSearchResult != nil
        && self.requiredSearchPhrase == self.parentSearchResult.requiredSearchPhrase
        && self.parentSearchResult.otherWordsMatch != nil)
    {
        for (NSString * s in self.parentSearchResult.otherWordsMatch)
        {
            NSUInteger i = [searchPhraseNames indexOfObject:s];
            if (i != NSNotFound)
            {
                [searchPhraseNames removeObjectAtIndex:i];
            }
        }
    }
    
    return searchPhraseNames;
}

- (int) getDepth
{
    if (_parentSearchResult != nil)
        return 1 + [_parentSearchResult getDepth];
    return 1;
}

- (int) getFoundWordCount
{
    int inc = [self getSelfWordCount];
    if (_parentSearchResult != nil)
        inc += [_parentSearchResult getFoundWordCount];
    return inc;
}

- (int) getSelfWordCount
{
    int inc = 0;
    if (_firstUnknownWordMatches)
        inc = 1;
    if (_otherWordsMatch != nil)
        inc += _otherWordsMatch.count;
    return inc;
}

- (double) getSearchDistanceRound:(CLLocation *)location
{
    double distance = 0;
    if (location && self.location)
    {
        // round to 5 decimal places
        CLLocationDegrees lat1 = (round(self.location.coordinate.latitude * 100000)) / 100000.0;
        CLLocationDegrees lon1 = (round(self.location.coordinate.longitude * 100000)) / 100000.0;
        CLLocationDegrees lat2 = location.coordinate.latitude;
        CLLocationDegrees lon2 = location.coordinate.longitude;
        distance = getDistance(lat1, lon1, lat2, lon2);
    }
    
    return self.priority - 1 / (1 + self.priorityDistance * distance);
}

- (double) getSearchDistanceRound:(CLLocation *)location pd:(double)pd
{
    double distance = 0.0;
    if (location && self.location)
    {
        CLLocationDegrees lat1 = (round(self.location.coordinate.latitude * 100000)) / 100000.0;
        CLLocationDegrees lon1 = (round(self.location.coordinate.longitude * 100000)) / 100000.0;
        CLLocationDegrees lat2 = location.coordinate.latitude;
        CLLocationDegrees lon2 = location.coordinate.longitude;
        distance = getDistance(lat1, lon1, lat2, lon2);
    }
    
    return self.priority - 1.0 / (1.0 + pd * distance);
}

- (double) getSearchDistanceFloored:(CLLocation *)location
{
    double distance = 0;
    if (location && self.location)
    {
        // floor to 5 decimal places
        CLLocationDegrees lat1 = (floor(self.location.coordinate.latitude * 100000)) / 100000.0;
        CLLocationDegrees lon1 = (floor(self.location.coordinate.longitude * 100000)) / 100000.0;
        CLLocationDegrees lat2 = location.coordinate.latitude;
        CLLocationDegrees lon2 = location.coordinate.longitude;
        distance = getDistance(lat1, lon1, lat2, lon2);
    }
    
    return self.priority - 1 / (1 + self.priorityDistance * distance);
}

- (double) getSearchDistanceFloored:(CLLocation *)location pd:(double)pd
{
    double distance = 0.0;
    if (location && self.location)
    {
        CLLocationDegrees lat1 = (floor(self.location.coordinate.latitude * 100000)) / 100000.0;
        CLLocationDegrees lon1 = (floor(self.location.coordinate.longitude * 100000)) / 100000.0;
        CLLocationDegrees lat2 = location.coordinate.latitude;
        CLLocationDegrees lon2 = location.coordinate.longitude;
        distance = getDistance(lat1, lon1, lat2, lon2);
    }
    
    return self.priority - 1.0 / (1.0 + pd * distance);
}

- (OASearchResult *)setNewParentSearchResult:(OASearchResult *)parentSearchResult
{
    OASearchResult *prev = _parentSearchResult;
    _parentSearchResult = parentSearchResult;
    return prev;
}

- (std::shared_ptr<const OsmAnd::Amenity>) amenity
{
    return _amenity;
}

- (void) setAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity
{
    _amenity = amenity;
}

- (std::shared_ptr<const OsmAnd::IFavoriteLocation>) favorite
{
    return _favorite;
}
- (void) setFavorite:(std::shared_ptr<const OsmAnd::IFavoriteLocation>)favorite
{
    _favorite = favorite;
}

- (NSString *) toString
{
    NSMutableString *b = [NSMutableString new];
    if (_localeName.length > 0)
        [b appendString:_localeName];
    if (_localeRelatedObjectName.length > 0)
    {
        if (b.length > 0)
            [b appendString:@", "];
        
        [b appendString:_localeRelatedObjectName];
        if ([_relatedObject isKindOfClass:OAStreet.class])
        {
            OAStreet *street = (OAStreet *) _relatedObject;
            OACity *city = street.city;
            if (city != nil)
            {
                [b appendFormat:@", %@",
                 [city getName:_requiredSearchPhrase.getSettings.getLang transliterate:_requiredSearchPhrase.getSettings.isTransliterate]];
            }
        }
    }
    else if ([_object isKindOfClass:OAPOIBaseType.class])
    {
        if (b.length > 0)
            [b appendString:@" "];
        OAPOIBaseType *poiType = (OAPOIBaseType *) _object;
        if ([poiType isKindOfClass:OAPOICategory.class])
        {
            [b appendString:@"(Category)"];
        }
        else if ([poiType isKindOfClass:OAPOIFilter.class])
        {
            [b appendString:@"(Filter)"];
        }
        else if ([poiType isKindOfClass:OAPOIType.class])
        {
            OAPOIType *p = (OAPOIType *) poiType;
            OAPOIBaseType *parentType = p.parentType;
            if (parentType != nil)
            {
                NSString *translation = parentType.nameLocalized;
                [b appendFormat:@"(%@", translation];
                if ([parentType isKindOfClass:OAPOICategory.class]) {
                    [b appendString:@" / Category)"];
                }
                else if ([parentType isKindOfClass:OAPOIFilter.class])
                {
                    [b appendString:@" / Filter)"];
                }
                else if ([parentType isKindOfClass:OAPOIType.class])
                {
                    OAPOIType *pp = (OAPOIType *) poiType;
                    OAPOIFilter *filter = pp.filter;
                    OAPOICategory *category = pp.category;
                    if (filter != nil && ![filter.nameLocalized isEqualToString:translation])
                    {
                        [b appendFormat:@" / %@)", filter.nameLocalized];
                    }
                    else if (category != nil && ![category.nameLocalized isEqualToString:translation])
                    {
                       [b appendFormat:@" / %@)", category.nameLocalized];
                    }
                    else
                    {
                        [b appendString:@")"];
                    }
                }
            }
            else if (p.filter != nil)
            {
                [b appendFormat:@"(%@)", p.filter.nameLocalized];
            }
            else if (p.category != nil)
            {
                [b appendFormat:@"(%@)", p.category.nameLocalized];
            }
        }
    }
    return b;
}

- (NSMutableArray<NSString *> *)filterUnknownSearchWord:(NSMutableArray<NSString *> *)leftUnknownSearchWords {
    if (leftUnknownSearchWords == nil) {
        leftUnknownSearchWords = [NSMutableArray arrayWithArray:self.requiredSearchPhrase.getUnknownSearchWords];
        [leftUnknownSearchWords insertObject:self.requiredSearchPhrase.getFirstUnknownSearchWord atIndex:0];
    }
    
    if (self.firstUnknownWordMatches) {
        [leftUnknownSearchWords removeObject:self.requiredSearchPhrase.getFirstUnknownSearchWord];
    }
    
    if (self.otherWordsMatch != nil) {
        for (NSString *otherWord in self.otherWordsMatch)
        {
            NSInteger ind = NSNotFound;
            if (self.firstUnknownWordMatches)
            {
                ind = [leftUnknownSearchWords indexOfObject:otherWord];
            }
            else
            {
                // lastIndexOf
                ind = [leftUnknownSearchWords indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                {
                    if ([obj isEqual:otherWord])
                    {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
            }
            if (ind != NSNotFound) {
                [leftUnknownSearchWords removeObjectAtIndex:ind];
            }
        }
    }
    
    return leftUnknownSearchWords;
}

@end
