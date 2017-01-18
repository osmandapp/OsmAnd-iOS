//
//  OASearchResultMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAResultMatcher.h"

@class OASearchResult, OAAtomicInteger, OASearchCoreAPI, OASearchPhrase;

@interface OASearchResultMatcher : OAResultMatcher

- (instancetype)initWithMatcher:(OAResultMatcher<OASearchResult *> *)matcher request:(int)request requestNumber:(OAAtomicInteger *)requestNumber totalLimit:(int)totalLimit;

- (OASearchResult *) setParentSearchResult:(OASearchResult *)parentSearchResult;
- (NSArray<OASearchResult *> *) getRequestResults;
- (int) getCount;
- (void) apiSearchFinished:(OASearchCoreAPI *)api phrase:(OASearchPhrase *)phrase;

-(BOOL)publish:(OASearchResult *)object;

@end
