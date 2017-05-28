//
//  OASearchResultMatcher.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchResultMatcher.h"
#import "OASearchResult.h"
#import "OAAtomicInteger.h"
#import "OASearchPhrase.h"
#import "OASearchCoreAPI.h"

@implementation OASearchResultMatcher
{
    NSMutableArray<OASearchResult *> *_requestResults;
    OAResultMatcher<OASearchResult *> *_matcher;
    int _request;
    int _totalLimit;
    OASearchResult *_parentSearchResult;
    OAAtomicInteger *_requestNumber;
    int _count;
    OASearchPhrase *_phrase;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _requestResults = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithMatcher:(OAResultMatcher<OASearchResult *> *)matcher phrase:(OASearchPhrase *)phrase request:(int)request requestNumber:(OAAtomicInteger *)requestNumber totalLimit:(int)totalLimit
{
    self = [self init];
    if (self)
    {
        _matcher = matcher;
        _phrase = phrase;
        _request = request;
        _requestNumber = requestNumber;
        _totalLimit = totalLimit;
    }
    return self;
}

- (OASearchResult *) setParentSearchResult:(OASearchResult *)parentSearchResult
{
    OASearchResult *prev = _parentSearchResult;
    _parentSearchResult = parentSearchResult;
    return prev;
}

- (NSArray<OASearchResult *> *) getRequestResults
{
    return _requestResults;
}

- (int) getCount
{
    return (int)_requestResults.count;
}

- (void) searchStarted:(OASearchPhrase *)phrase
{
    if (_matcher)
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = SEARCH_STARTED;
        [_matcher publish:sr];
    }
}

- (void) searchFinished:(OASearchPhrase *)phrase
{
    if (_matcher)
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = SEARCH_FINISHED;
        [_matcher publish:sr];
    }
}

- (void) apiSearchFinished:(OASearchCoreAPI *)api phrase:(OASearchPhrase *)phrase
{
    if (_matcher)
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = SEARCH_API_FINISHED;
        sr.object = api;
        sr.parentSearchResult = _parentSearchResult;
        [_matcher publish:sr];
    }
}

- (void) apiSearchRegionFinished:(OASearchCoreAPI *)api resourceId:(NSString *)resourceId phrase:(OASearchPhrase *)phrase
{
    if (_matcher)
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = SEARCH_API_REGION_FINISHED;
        sr.object = api;
        sr.parentSearchResult = _parentSearchResult;
        sr.resourceId = resourceId;
        [_matcher publish:sr];
    }
}

-(BOOL)publish:(OASearchResult *)object
{
    if (_phrase && object.otherNames && ![[_phrase getNameStringMatcher] matches:object.localeName])
    {
        for (NSString *s in object.otherNames)
        {
            if ([[_phrase getNameStringMatcher] matches:s])
            {
                object.alternateName = s;
                break;
            }
        }
    }
    if (!_matcher || [_matcher publish:object])
    {
        _count++;
        object.parentSearchResult = _parentSearchResult;
        if (_totalLimit == -1 || _count < _totalLimit) {
            [_requestResults addObject:object];
        }
        return YES;
    }
    return NO;
}

-(BOOL)isCancelled
{
    BOOL cancelled = _request != [_requestNumber get];
    return cancelled || (_matcher && [_matcher isCancelled]);
}


@end
