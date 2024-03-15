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

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <OsmAndCore/ICU.h>

#define MAX_TYPE_WEIGHT 10.0
#define HYPHEN "-"
#define NEAREST_METERS_LIMIT 30000
#define ALLDELIMITERS "\\s|,"
#define ALLDELIMITERS_WITH_HYPHEN "\\s|,|-"

@implementation CheckWordsMatchCount
@end

@implementation OASearchResult

- (instancetype) initWithPhrase:(OASearchPhrase *)sp
{
    self = [super init];
    if (self)
    {
        self.preferredZoom = 15;
        self.requiredSearchPhrase = sp;
    }
    return self;
}

// maximum corresponds to the top entry
- (double) unknownPhraseMatchWeight
{
    // normalize number to get as power, so we get numbers > 1
    return [self getSumPhraseMatchWeight] / pow(MAX_PHRASE_WEIGHT_TOTAL, [self getDepth] - 1);
}

- (double) getSumPhraseMatchWeight
{
    double res = [OAObjectType getTypeWeight:_objectType];
    if ([_requiredSearchPhrase getUnselectedPoiType])
    {
        // search phrase matches poi type, then we lower all POI matches and don't check allWordsMatched
    }
    else if (_objectType == POI_TYPE)
    {
        
    }
    else
    {
        CheckWordsMatchCount *completeMatchRes = [[CheckWordsMatchCount alloc] init];
        if ([self allWordsMatched:_localeName cnt:completeMatchRes])
        {
            // ignore other names
        }
        else if (_otherNames != nil)
        {
            for (NSString *otherName : _otherNames) {
                if ([self allWordsMatched:otherName cnt:completeMatchRes])
                    break;
            }
        }
        // if all words from search phrase match (<) the search result words - we prioritize it higher
        if (completeMatchRes.allWordsInPhraseAreInResult)
            res = [self getPhraseWeightForCompleteMatch:completeMatchRes];
    }
    if (_parentSearchResult)
        // parent search result should not change weight of current result, so we divide by MAX_TYPES_BASE_10^2
        res = res + [_parentSearchResult getSumPhraseMatchWeight] / MAX_PHRASE_WEIGHT_TOTAL;
    
    return res;
}

- (double) getPhraseWeightForCompleteMatch:(CheckWordsMatchCount *)completeMatchRes
    {
        double res = [OAObjectType getTypeWeight:_objectType] * MAX_TYPES_BASE_10;
        // if all words from search phrase == the search result words - we prioritize it even higher
        if (completeMatchRes.allWordsEqual)
        {
            BOOL closeDistance = [OAMapUtils getDistance:([_requiredSearchPhrase getLastTokenLocation]).coordinate second:_location.coordinate] <= NEAREST_METERS_LIMIT;
            if (_objectType == CITY || _objectType == VILLAGE || closeDistance)
                res = [OAObjectType getTypeWeight:_objectType] * MAX_TYPES_BASE_10 + MAX_PHRASE_WEIGHT_TOTAL / 2;
        }
        return res;
    }

- (BOOL)allWordsMatched:(NSString *)name cnt:(CheckWordsMatchCount *)cnt
{
    NSMutableArray<NSString *> * searchPhraseNames = [self getSearchPhraseNames];
    NSMutableArray<NSString *> * localResultNames;
    if (![[_requiredSearchPhrase getFullSearchPhrase] containsString:@HYPHEN])
    {
        // we split '-' words in result, so user can input same without '-'
        localResultNames = [OASearchPhrase splitWords:name ws:[NSMutableArray array] delimiters:@ALLDELIMITERS_WITH_HYPHEN];
    }
    else
        localResultNames = [OASearchPhrase splitWords:name ws:[NSMutableArray array] delimiters:@ALLDELIMITERS];

    BOOL wordMatched;
    if ([searchPhraseNames count] == 0)
        return NO;
    int idxMatchedWord = -1;
    for (NSString *searchPhraseName : searchPhraseNames)
    {
        wordMatched = NO;
        for (int i = idxMatchedWord + 1; i < [localResultNames count]; i++)
        {
            if ([searchPhraseName compare:localResultNames[i] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch] == NSOrderedSame)
            {
                wordMatched = YES;
                idxMatchedWord = i;
                break;
            }
        }
        if (!wordMatched)
            return NO;
    }
    if (searchPhraseNames.count == localResultNames.count)
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

@end
