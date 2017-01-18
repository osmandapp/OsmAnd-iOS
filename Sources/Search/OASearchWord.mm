//
//  OASearchWord.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchWord.h"
#import "OASearchResult.h"
#import "OAUtilities.h"

@implementation OASearchWord

- (instancetype)initWithWord:(NSString *)word res:(OASearchResult *)res
{
    self = [super init];
    if (self)
    {
        _word = [word trim];
        _result = res;
    }
    return self;
}

- (EOAObjectType) getType
{
    return !self.result ? UNKNOWN_NAME_FILTER : self.result.objectType;
}

- (void) syncWordWithResult
{
    _word = self.result.wordsSpan ? self.result.wordsSpan : [self.result.localeName trim];
}

- (CLLocation *) getLocation
{
    return !self.result ? nil : self.result.location;
}

- (NSString  *) toString
{
    return self.word;
}

@end
