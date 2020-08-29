//
//  OASearchResult.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchResult.h"
#import "OASearchPhrase.h"

#define MAX_TYPE_WEIGHT 10

@implementation OASearchResult

- (instancetype) initWithPhrase:(OASearchPhrase *)sp
{
    self = [super init];
    if (self)
    {
        self.firstUnknownWordMatches = YES;
        self.unknownPhraseMatches = NO;
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
    BOOL match = [_requiredSearchPhrase countWords:_localeName] <= [self getSelfWordCount];
    double res = [OAObjectType getTypeWeight:match ? _objectType : CITY];
    if (_parentSearchResult != nil)
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

- (double) getSearchDistance:(CLLocation *)location
{
    double distance = 0;
    if (location && self.location)
        distance = [location distanceFromLocation:self.location];
    
    return self.priority - 1 / (1 + self.priorityDistance * distance);
}

- (double) getSearchDistance:(CLLocation *)location pd:(double)pd
{
    double distance = 0;
    if (location && self.location)
        distance = [location distanceFromLocation:self.location];
    
    return self.priority - 1 / (1 + pd * distance);
}

- (OASearchResult *)setNewParentSearchResult:(OASearchResult *)parentSearchResult
{
    OASearchResult *prev = _parentSearchResult;
    _parentSearchResult = parentSearchResult;
    return prev;
}

@end
