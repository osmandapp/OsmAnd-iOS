//
//  OASearchResultMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/SearchUICore.java
//  git revision 46b2782a7d94c8e4968ef488956dd4d96925be95

#import "OAResultMatcher.h"

@class OASearchResult, OAAtomicInteger, OASearchCoreAPI, OASearchPhrase;

@interface OASearchResultMatcher : OAResultMatcher

- (instancetype)initWithMatcher:(OAResultMatcher<OASearchResult *> *)matcher phrase:(OASearchPhrase *)phrase request:(int)request requestNumber:(OAAtomicInteger *)requestNumber totalLimit:(int)totalLimit;

- (OASearchResult *) setParentSearchResult:(OASearchResult *)parentSearchResult;
- (NSArray<OASearchResult *> *) getRequestResults;
- (OASearchResult *) getParentSearchResult;
- (int) getCount;
- (void) apiSearchFinished:(OASearchCoreAPI *)api phrase:(OASearchPhrase *)phrase;
- (void) apiSearchRegionFinished:(OASearchCoreAPI *)api resourceId:(NSString *)resourceId phrase:(OASearchPhrase *)phrase;
- (void) searchStarted:(OASearchPhrase *)phrase;
- (void) searchFinished:(OASearchPhrase *)phrase;
- (void) filterFinished:(OASearchPhrase *)phrase;

-(BOOL)publish:(OASearchResult *)object;

@end
