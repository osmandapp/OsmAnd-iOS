//
//  OASpatialSearchPresentationTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import "OASharedSearchUICore.h"
#import "OASharedSearchObjects.h"
#import "OAQuickSearchViewController.h"
#import "OAQuickSearchTableController.h"
#import "OAQuickSearchListItem.h"
#import "OAQuickSearchMoreListItem.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAndApp.h"
#import "Localization.h"

@interface OAQuickSearchViewController (SpatialPresentationTests)
@property (nonatomic) OASearchUICore *searchUICore;
@property (nonatomic) BOOL interruptedSearch;
- (OASearchResultCollection *)getResultCollection;
- (void)setResultCollection:(OASearchResultCollection *)collection;
- (void)updateSearchResult:(OASearchResultCollection *)collection append:(BOOL)append;
- (void)showApiResults:(NSArray<OASearchResult *> *)results phrase:(OASearchPhrase *)phrase api:(id)api hasRegionCollection:(BOOL)hasRegionCollection onPublish:(void (^)(OASearchResultCollection *, BOOL))publish;
- (BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase;
- (BOOL)isResultEmpty;
- (void)increaseSearchRadius;
- (void)addMoreButton;
- (void)runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore;
- (void)updateTextField:(NSString *)text;
- (void)didSelectResult:(OASearchResult *)result;
@end

@interface OASpatialPresentationTestCore : OASharedSearchUICore
@property (nonatomic) BOOL canExpandRadius;
@end
@implementation OASpatialPresentationTestCore
- (BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase { return self.canExpandRadius; }
@end

@interface OASpatialPresentationTestController : OAQuickSearchViewController
@property (nonatomic) OASearchResultCollection *collection;
@property (nonatomic) NSInteger searchCount;
@property (nonatomic) BOOL lastSearchMore;
@property (nonatomic) NSString *lastSearchText;
@property (nonatomic) NSString *displayedText;
@end
@implementation OASpatialPresentationTestController
- (OASearchResultCollection *)getResultCollection { return self.collection; }
- (void)setResultCollection:(OASearchResultCollection *)collection { self.collection = collection; }
- (void)updateTextField:(NSString *)text { self.displayedText = text; }
- (void)runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore
{
    self.searchCount++;
    self.lastSearchText = text;
    self.lastSearchMore = searchMore;
}
@end

@interface OASpatialSearchPresentationTest : XCTestCase
@property (nonatomic) OASpatialPresentationTestCore *core;
@property (nonatomic) OASearchPhrase *phrase;
@property (nonatomic) id spatialAPI;
@end

@implementation OASpatialSearchPresentationTest

- (void)setUp
{
    [super setUp];
    XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc] initWithPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) { return OsmAndApp.instance.initialized; }] object:nil];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[ready] timeout:60], XCTWaiterResultCompleted);
    self.core = [[OASpatialPresentationTestCore alloc] initWithLang:@"en" transliterate:NO];
    [self.core initApiUseSpatialSearch:YES searchRulesDir:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"abbr"]];
    self.phrase = [self.core resetPhrase:@"restaurant "];
    for (id api in [self.core.shared getApis])
        if ([api isKindOfClass:OASSpatialTextSearchAPI.class])
            self.spatialAPI = api;
    XCTAssertNotNil(self.spatialAPI);
}

- (OASearchResult *)result:(NSString *)name level:(int)level
{
    OASSearchResult *shared = [[OASSearchResult alloc] initWithSp:((OASharedSearchPhrase *)self.phrase).shared];
    shared.localeName = name;
    shared.objectType = OASObjectType.location;
    shared.location = [[OASKLatLon alloc] initWithLatitude:53.55 longitude:10.0 + level * 0.01];
    shared.spatialSearchVisibleLevel = level;
    return [OASearchResult resultOfShared:shared phrase:self.phrase];
}

- (OASearchResultCollection *)spatialCollection:(NSArray<OASearchResult *> *)results
{
    return [[self.core createResultCollectionForPhrase:self.phrase api:self.spatialAPI]
        addSearchResults:results resortAll:YES removeDuplicates:YES];
}

- (void)testVisibilityFollowsLevelsWithoutChangingTheFullCollectionOrResultIdentity
{
    OASearchResult *level2 = [self result:@"level two" level:2];
    OASearchResult *level0 = [self result:@"level zero" level:0];
    OASearchResult *level1 = [self result:@"level one" level:1];
    OASearchResult *second0 = [self result:@"another zero" level:0];
    NSArray *all = @[level2, level0, level1, second0];
    OASearchResultCollection *collection = [self spatialCollection:all];
    XCTAssertEqualObjects(collection.getCurrentSearchResults, all);
    XCTAssertEqualObjects(collection.getVisibleSpatialSearchResults, (@[level0, second0]));
    XCTAssertTrue(collection.hasMoreSpatialSearchResults);
    XCTAssertTrue(collection.showMoreSpatialSearchResults);
    XCTAssertEqualObjects(collection.getVisibleSpatialSearchResults, (@[level0, second0, level1]));
    XCTAssertTrue(collection.showMoreSpatialSearchResults);
    XCTAssertEqualObjects(collection.getVisibleSpatialSearchResults, (@[level0, second0, level1, level2]));
    XCTAssertFalse(collection.hasMoreSpatialSearchResults);
    XCTAssertFalse(collection.showMoreSpatialSearchResults);
    XCTAssertEqualObjects(collection.getCurrentSearchResults, all);
}

- (void)testCombiningApiCollectionsKeepsSpatialOrderAndTheHighestRevealedLevel
{
    OASearchResult *normal = [self result:@"normal" level:0];
    OASearchResultCollection *classic = [[self.core createResultCollectionForPhrase:self.phrase api:nil]
        addSearchResults:@[normal] resortAll:YES removeDuplicates:YES];
    OASearchResult *hidden = [self result:@"z hidden" level:1];
    OASearchResult *visible = [self result:@"a visible" level:0];
    OASearchResultCollection *spatial = [self spatialCollection:@[hidden, visible]];
    XCTAssertTrue(spatial.showMoreSpatialSearchResults);
    OASearchResultCollection *combined = [classic combineWithCollection:spatial resort:YES removeDuplicates:YES];
    XCTAssertEqualObjects(combined.getCurrentSearchResults, (@[normal, hidden, visible]));
    XCTAssertEqualObjects(combined.getVisibleSpatialSearchResults, (@[normal, visible, hidden]));
    XCTAssertFalse(combined.hasMoreSpatialSearchResults);
    OASearchResult *later = [self result:@"later" level:2];
    OASearchResultCollection *next = [combined combineWithCollection:[self spatialCollection:@[later]] resort:YES removeDuplicates:YES];
    XCTAssertEqualObjects(next.getVisibleSpatialSearchResults, combined.getVisibleSpatialSearchResults);
    XCTAssertTrue(next.hasMoreSpatialSearchResults);
    XCTAssertTrue(next.showMoreSpatialSearchResults);
    XCTAssertEqual(next.getVisibleSpatialSearchResults.lastObject, later);
}

- (void)testClassicSharedAndCppCollectionsExposeAllResults
{
    OASearchResultCollection *classic = [self.core createResultCollectionForPhrase:self.phrase api:nil];
    [classic addSearchResults:@[[self result:@"hidden metadata" level:2]] resortAll:YES removeDuplicates:YES];
    XCTAssertEqualObjects(classic.getVisibleSpatialSearchResults, classic.getCurrentSearchResults);
    XCTAssertFalse(classic.hasMoreSpatialSearchResults);
    XCTAssertFalse(classic.showMoreSpatialSearchResults);

    OASearchUICore *cpp = [[OASearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OASearchResultCollection *native = [cpp createResultCollectionForPhrase:cpp.getPhrase api:nil];
    XCTAssertFalse([native isKindOfClass:OASharedSearchResultCollection.class]);
    OASearchResult *result = [[OASearchResult alloc] initWithPhrase:cpp.getPhrase];
    result.objectType = EOAObjectTypeLocation;
    result.localeName = @"native result";
    [native addSearchResults:@[result] resortAll:NO removeDuplicates:NO];
    XCTAssertEqualObjects(native.getVisibleSpatialSearchResults, (@[result]));
    XCTAssertFalse(native.hasMoreSpatialSearchResults);
    XCTAssertFalse(native.showMoreSpatialSearchResults);
}

- (OASpatialPresentationTestController *)controllerWithTable:(OAQuickSearchTableController **)tableController
{
    OASpatialPresentationTestController *controller = [[OASpatialPresentationTestController alloc] init];
    controller.searchUICore = self.core;
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 402, 600) style:UITableViewStylePlain];
    *tableController = [[OAQuickSearchTableController alloc] initWithTableView:table];
    (*tableController).delegate = (id<OAQuickSearchTableDelegate>)controller;
    [controller setValue:*tableController forKey:@"tableController"];
    return controller;
}

- (void)testMoreButtonRevealsCachedResultsBeforeStartingAnotherSearch
{
    OAQuickSearchTableController *table;
    OASpatialPresentationTestController *controller = [self controllerWithTable:&table];
    controller.collection = [self spatialCollection:@[[self result:@"first" level:0], [self result:@"second" level:1]]];
    [self.core updateSettings:[self.core.getSearchSettings setRadiusLevel:3]];
    [controller updateSearchResult:controller.collection append:NO];
    XCTAssertEqual([table tableView:table.tableView numberOfRowsInSection:0], 1);
    XCTAssertTrue([controller isSearchMoreAvailable:self.phrase], @"hidden levels are available even when the engine cannot expand");
    [controller addMoreButton];
    NSArray *rows = [table valueForKey:@"dataGroups"][0];
    OAQuickSearchMoreListItem *more = rows.lastObject;
    XCTAssertEqualObjects(more.getName, OALocalizedString(@"show_more"));
    more.onClickFunction(more);
    XCTAssertEqual(controller.searchCount, 0);
    XCTAssertEqual([self.core.getSearchSettings getRadiusLevel], 3);
    XCTAssertEqual([table tableView:table.tableView numberOfRowsInSection:0], 2);
    XCTAssertFalse([controller isSearchMoreAvailable:self.phrase]);

    self.core.canExpandRadius = YES;
    [controller addMoreButton];
    rows = [table valueForKey:@"dataGroups"][0];
    more = rows.lastObject;
    XCTAssertEqualObjects(more.getName, OALocalizedString(@"search_POI_level_btn"));
    more.onClickFunction(more);
    XCTAssertEqual(controller.searchCount, 1);
    XCTAssertTrue(controller.lastSearchMore);
    XCTAssertEqual([self.core.getSearchSettings getRadiusLevel], 4);
    controller.interruptedSearch = YES;
    [controller increaseSearchRadius];
    XCTAssertEqual(controller.searchCount, 2);
    XCTAssertEqual([self.core.getSearchSettings getRadiusLevel], 4, @"resuming an interrupted search keeps its radius");
}

- (void)testApiPublicationKeepsLevelsWhenAppResultsArriveFirst
{
    OAQuickSearchTableController *table;
    OASpatialPresentationTestController *controller = [self controllerWithTable:&table];
    OASearchResult *normal = [self result:@"normal" level:0];
    OASearchResult *hidden = [self result:@"hidden" level:1];
    XCTestExpectation *published = [self expectationWithDescription:@"both APIs published"];
    published.expectedFulfillmentCount = 2;
    void (^publish)(OASearchResultCollection *, BOOL) = ^(OASearchResultCollection *collection, BOOL append) {
        [controller updateSearchResult:collection append:append];
        [published fulfill];
    };
    [controller showApiResults:@[normal] phrase:self.phrase api:nil hasRegionCollection:NO onPublish:publish];
    [controller showApiResults:@[hidden] phrase:self.phrase api:self.spatialAPI hasRegionCollection:NO onPublish:publish];
    [self waitForExpectations:@[published] timeout:5];
    XCTAssertEqualObjects(controller.collection.getVisibleSpatialSearchResults, (@[normal]));
    XCTAssertTrue(controller.collection.hasMoreSpatialSearchResults);
    [controller increaseSearchRadius];
    XCTAssertEqualObjects(controller.collection.getVisibleSpatialSearchResults, (@[normal, hidden]));
    XCTAssertEqual(controller.searchCount, 0);
    OASearchResultCollection *fresh = [self spatialCollection:@[normal, hidden]];
    XCTAssertEqual(fresh.getVisibleSpatialSearchResults.count, 1, @"a new query starts at level zero");
}

- (void)testSuggestionRendersAndStartsTheCorrectedQueryInsteadOfSelectingAnObject
{
    OASSearchResult *shared = [[OASSearchResult alloc] initWithSp:((OASharedSearchPhrase *)self.phrase).shared];
    shared.objectType = OASObjectType.suggestion;
    shared.localeName = @"  restaurant Hamburg  ";
    shared.object = shared.localeName;
    OASearchResult *suggestion = [OASearchResult resultOfShared:shared phrase:self.phrase];
    XCTAssertEqualObjects(suggestion.object, shared.localeName);
    XCTAssertEqual(suggestion.objectType, EOAObjectTypeSuggestion);
    XCTAssertEqualObjects([OAObjectType toString:suggestion.objectType], @"SUGGESTION");
    XCTAssertEqual([OAObjectType valueOf:@"SUGGESTION"].type, EOAObjectTypeSuggestion);
    XCTAssertTrue([OAObjectType isTopVisible:suggestion.objectType]);
    XCTAssertFalse([OAObjectType hasLocation:suggestion.objectType]);
    XCTAssertEqual([suggestion toSharedResult].objectType, OASObjectType.suggestion);
    XCTAssertEqualObjects([OAQuickSearchListItem getTypeName:suggestion], @"");

    OAQuickSearchTableController *table;
    OASpatialPresentationTestController *controller = [self controllerWithTable:&table];
    controller.collection = [self spatialCollection:@[suggestion]];
    [controller updateSearchResult:controller.collection append:NO];
    NSIndexPath *index = [NSIndexPath indexPathForRow:0 inSection:0];
    OASimpleTableViewCell *cell = (OASimpleTableViewCell *)[table tableView:table.tableView cellForRowAtIndexPath:index];
    XCTAssertNotNil(cell, @"every displayed suggestion must have a cell");
    XCTAssertEqualObjects(cell.titleLabel.text, shared.localeName);
    XCTAssertNotNil(cell.leftIconView.image);
    [self.core updateSettings:[self.core.getSearchSettings setRadiusLevel:4]];
    [table tableView:table.tableView didSelectRowAtIndexPath:index];
    XCTAssertEqualObjects(controller.displayedText, @"restaurant Hamburg ");
    XCTAssertEqualObjects(controller.lastSearchText, @"restaurant Hamburg ");
    XCTAssertEqual(controller.searchCount, 1);
    XCTAssertFalse(controller.lastSearchMore);
    XCTAssertEqual([self.core.getSearchSettings getRadiusLevel], 1);
    XCTAssertNil([self.core.getPhrase getLastSelectedWord]);
}

- (void)testEmptyVisibleLevelCanRevealLaterResults
{
    OAQuickSearchTableController *table;
    OASpatialPresentationTestController *controller = [self controllerWithTable:&table];
    controller.collection = [self spatialCollection:@[[self result:@"later" level:2]]];
    XCTAssertTrue(controller.isResultEmpty);
    [controller increaseSearchRadius];
    XCTAssertTrue(controller.isResultEmpty);
    [controller increaseSearchRadius];
    XCTAssertFalse(controller.isResultEmpty);
    XCTAssertEqual(controller.searchCount, 0);
}

- (void)testPresentationBenchmark
{
    NSMutableArray *results = [NSMutableArray array];
    for (int i = 0; i < 1000; i++)
        [results addObject:[self result:[NSString stringWithFormat:@"result %d", i] level:i % 5]];
    OASearchResultCollection *collection = [self spatialCollection:results];
    NSMutableArray<NSNumber *> *fullTimes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *visibleTimes = [NSMutableArray array];
    for (int sample = -2; sample < 7; sample++)
    {
        for (BOOL visible : {NO, YES})
        {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            NSMutableArray *rows = [NSMutableArray array];
            for (OASearchResult *result in visible ? collection.getVisibleSpatialSearchResults : collection.getCurrentSearchResults)
                [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:result]];
            double milliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000;
            XCTAssertEqual(rows.count, visible ? 200 : 1000);
            if (sample >= 0)
                [(visible ? visibleTimes : fullTimes) addObject:@(milliseconds)];
        }
    }
    [fullTimes sortUsingSelector:@selector(compare:)];
    [visibleTimes sortUsingSelector:@selector(compare:)];
    fprintf(stderr, "Spatial presentation: 1000 results, 2 warmups + 7 rounds, full list %.3f ms, visible 200 rows %.3f ms\n", fullTimes[3].doubleValue, visibleTimes[3].doubleValue);
}

@end
