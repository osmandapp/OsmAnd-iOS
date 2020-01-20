//
//  OASearchResult.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchResult.h"
#import "OASearchPhrase.h"

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

- (double) unknownPhraseMatchWeight
{
    double res = 0;
    BOOL isHouse = _objectType == HOUSE;
    if (_unknownPhraseMatches)
        res = [OAObjectType getTypeWeight:_objectType];
    
    if (res == 0 && _parentSearchResult && _parentSearchResult.unknownPhraseMatches)
    {
        if (isHouse && _parentSearchResult.objectType == STREET)
            res = [OAObjectType getTypeWeight:HOUSE];
        else
            res = [OAObjectType getTypeWeight:_parentSearchResult.objectType];
    }
    return res;
}

- (int) getFoundWordCount
{
    int inc = 0;
    if (self.firstUnknownWordMatches)
        inc = 1;
    
    if (self.otherWordsMatch)
        inc += self.otherWordsMatch.count;
    
    if (self.parentSearchResult)
        inc += [self.parentSearchResult getFoundWordCount];
    
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

@end
