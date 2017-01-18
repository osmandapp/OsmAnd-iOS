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

- (instancetype)initWithPhrase:(OASearchPhrase *)sp
{
    self = [super init];
    if (self)
    {
        self.preferredZoom = 15;
        self.requiredSearchPhrase = sp;
    }
    return self;
}

- (int) getFoundWordCount
{
    if (self.otherWordsMatch)
        return (int)self.otherWordsMatch.count + 1;

    return 1;
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
