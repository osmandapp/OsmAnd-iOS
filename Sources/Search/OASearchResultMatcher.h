//
//  OASearchResultMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/SearchUICore.java
//  git revision 688d1938030f7efc7c37cc5cb842934e66994ec0

#import "OAResultMatcher.h"

@class OASearchResult, OAAtomicInteger, OASearchCoreAPI, OASearchPhrase;

@interface OASearchResultMatcher : OAResultMatcher

- (instancetype)initWithMatcher:(OAResultMatcher<OASearchResult *> *)matcher phrase:(OASearchPhrase *)phrase request:(int)request requestNumber:(OAAtomicInteger *)requestNumber totalLimit:(int)totalLimit;

- (OASearchResult *) setParentSearchResult:(OASearchResult *)parentSearchResult;
- (NSArray<OASearchResult *> *) getRequestResults;
- (int) getCount;
- (void) apiSearchFinished:(OASearchCoreAPI *)api phrase:(OASearchPhrase *)phrase;
- (void) apiSearchRegionFinished:(OASearchCoreAPI *)api resourceId:(NSString *)resourceId phrase:(OASearchPhrase *)phrase;
- (void) searchStarted:(OASearchPhrase *)phrase;
- (void) searchFinished:(OASearchPhrase *)phrase;
- (void) filterFinished:(OASearchPhrase *)phrase;

-(BOOL)publish:(OASearchResult *)object;

@end
