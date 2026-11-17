//
//  OASearchUICore.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/SearchUICore.java
//  git revision 9ea32a8fb553ba22e188f6a7896b4868593ca808

#import <Foundation/Foundation.h>
#import "OAResultMatcher.h"

@class OASearchPhrase, OASearchCoreAPI, OACustomSearchPoiFilter, OASearchSettings, OAPOIBaseType, OASearchResultMatcher, OASearchResult;

@interface OASearchResultCollection : NSObject

@property (nonatomic) OASearchPhrase *phrase;

- (instancetype)initWithPhrase:(OASearchPhrase *)phrase;

- (OASearchResultCollection *) combineWithCollection:(OASearchResultCollection *)collection resort:(BOOL)resort removeDuplicates:(BOOL)removeDuplicates;
- (OASearchResultCollection *) addSearchResults:(NSArray<OASearchResult *> *)sr resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates;
- (NSArray<OASearchResult *> *) getCurrentSearchResults;
/** Results currently visible in the search list. Classic search exposes its complete collection. */
- (NSArray<OASearchResult *> *)getVisibleSpatialSearchResults;
/** Whether the collection preserves spatial ordering and visibility levels. */
- (BOOL)isSkipSorting;
- (BOOL)hasMoreSpatialSearchResults;
- (BOOL)showMoreSpatialSearchResults;
- (void) sortSearchResults;
- (void) calculateAddressString;
- (void) filterSearchDuplicateResults;
- (BOOL) sameSearchResult:(OASearchResult *)r1 r2:(OASearchResult *)r2;

@end


@interface OASearchResultComparator : NSObject

- (instancetype) initWithPhrase:(OASearchPhrase *)phrase;

@end


@interface OASearchUICore : NSObject

typedef void (^OASearchUICoreRunnable)();

@property (nonatomic) OASearchUICoreRunnable onSearchStart;
@property (nonatomic) OASearchUICoreRunnable onResultsComplete;

- (instancetype) initWithLang:(NSString *)lang transliterate:(BOOL)transliterate;

- (OASearchCoreAPI *) getApiByClass:(Class)cl;

/** Runs on the engine's serial search queue. Completion is called on that queue, including when no API matches. */
- (void)shallowSearchAsync:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher completion:(void (^)(OASearchResultCollection *))completion;
- (void)shallowSearchAsync:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates completion:(void (^)(OASearchResultCollection *))completion;
- (void)shallowSearchAsync:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates searchSettings:(OASearchSettings *)searchSettings completion:(void (^)(OASearchResultCollection *))completion;

- (void) initApi;

- (void) clearCustomSearchPoiFilters;
- (void) addCustomSearchPoiFilter:(OACustomSearchPoiFilter *)poiFilter  priority:(int)priority;
- (void) registerAPI:(OASearchCoreAPI *)api;
- (void) setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrders;

- (OASearchResultCollection *) getCurrentSearchResult;
/** Creates a collection with the ordering policy of the API that published these results. */
- (OASearchResultCollection *)createResultCollectionForPhrase:(OASearchPhrase *)phrase api:(id)api;
- (OASearchPhrase *) getPhrase;
- (OASearchSettings *) getSearchSettings;

- (void) updateSettings:(OASearchSettings *)settings;
- (BOOL) selectSearchResult:(OASearchResult *)r;

- (OASearchPhrase *) resetPhrase;
- (OASearchPhrase *) resetPhrase:(NSString *)text;

- (void) search:(NSString *)text delayedExecution:(BOOL)delayedExecution matcher:(OAResultMatcher<OASearchResult *> *)matcher;
- (void) cancelSearch:(BOOL)sync;

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase;
- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase;
- (int) getNextSearchRadius:(OASearchPhrase *)phrase;

- (OAPOIBaseType *) getUnselectedPoiType;
- (NSString *) getCustomNameFilter;

// Public for testing only
- (void) searchInBackground:(OASearchPhrase *)phrase matcher:(OASearchResultMatcher *)matcher;

@end
