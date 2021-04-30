//
//  OASearchResult.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchResult.h"
#import "OASearchPhrase.h"

#import "OAStreet.h"
#import "OACity.h"
#import "OASearchSettings.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"
#import "OAPOICategory.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <OsmAndCore/ICU.h>

#define MAX_TYPE_WEIGHT 10.0

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
    // if result is a complete match in the search we prioritize it higher
    return [self getSumPhraseMatchWeight] / pow(MAX_TYPE_WEIGHT, [self getDepth] - 1);
}

- (double) getSumPhraseMatchWeight
{
    // if result is a complete match in the search we prioritize it higher
    NSString *name = _alternateName ? _alternateName : _localeName;
    NSMutableArray<NSString *> *localResultNames = [NSMutableArray array];
    NSMutableArray<NSString *> *searchPhraseNames = [NSMutableArray array];
    [_requiredSearchPhrase splitWords:name ws:localResultNames];
    
    NSString *fw = [_requiredSearchPhrase getFirstUnknownSearchWord];
    NSMutableArray<NSString *> *ow = [_requiredSearchPhrase getUnknownSearchWords];
    
    if (fw)
        [searchPhraseNames addObject:fw];
    if (ow)
        [searchPhraseNames addObjectsFromArray:ow];
    
    int idxMatchedWord = -1;
    BOOL allWordsMatched = YES;
    
    for (NSString *searchPhraseName : searchPhraseNames)
    {
        BOOL wordMatched = NO;
        for (int i = idxMatchedWord + 1; i < [localResultNames count]; i++)
        {
            int r = OsmAnd::ICU::ccompare(QString::fromNSString(searchPhraseName), QString::fromNSString([localResultNames objectAtIndex: i]));
            if (r == 0)
            {
                wordMatched = YES;
                idxMatchedWord = i;
                break;
            }
        }
        if (!wordMatched)
        {
            allWordsMatched = NO;
            break;
        }
    }
    if (_objectType == POI_TYPE)
        allWordsMatched = NO;
    
    double res = allWordsMatched ? [OAObjectType getTypeWeight:_objectType]*10 : [OAObjectType getTypeWeight: UNDEFINED];
    
    if ([_requiredSearchPhrase getUnselectedPoiType])
        // search phrase matches poi type, then we lower all POI matches and don't check allWordsMatched
        res = [OAObjectType getTypeWeight:_objectType];
    
    if (_parentSearchResult)
        res = res + [_parentSearchResult getSumPhraseMatchWeight] / MAX_TYPE_WEIGHT;
    
    return res;
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
