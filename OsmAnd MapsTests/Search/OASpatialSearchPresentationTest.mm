//
//  OASpatialSearchPresentationTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "OAAmenitySearcher.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIHelper.h"
#import "OAAppSettings.h"
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

- (void)waitForRows:(NSInteger)count table:(OAQuickSearchTableController *)table
{
    XCTNSPredicateExpectation *updated = [[XCTNSPredicateExpectation alloc] initWithPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            NSArray *groups = [table valueForKey:@"dataGroups"];
            id last = [groups.firstObject lastObject];
            return [table tableView:table.tableView numberOfRowsInSection:0] == count
                && ![last isKindOfClass:OAQuickSearchMoreListItem.class];
        }] object:nil];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[updated] timeout:5], XCTWaiterResultCompleted);
}

- (void)testMoreButtonRevealsCachedResultsBeforeStartingAnotherSearch
{
    OAQuickSearchTableController *table;
    OASpatialPresentationTestController *controller = [self controllerWithTable:&table];
    controller.collection = [self spatialCollection:@[[self result:@"first" level:0], [self result:@"second" level:1]]];
    [self.core updateSettings:[self.core.getSearchSettings setRadiusLevel:3]];
    [controller updateSearchResult:controller.collection append:NO];
    [self waitForRows:1 table:table];
    XCTAssertTrue([controller isSearchMoreAvailable:self.phrase], @"hidden levels are available even when the engine cannot expand");
    [controller addMoreButton];
    NSArray *rows = [table valueForKey:@"dataGroups"][0];
    OAQuickSearchMoreListItem *more = rows.lastObject;
    XCTAssertEqualObjects(more.getName, OALocalizedString(@"show_more"));
    more.onClickFunction(more);
    XCTAssertEqual(controller.searchCount, 0);
    XCTAssertEqual([self.core.getSearchSettings getRadiusLevel], 3);
    [self waitForRows:2 table:table];
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
    [self waitForRows:1 table:table];
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

// These tests count full model conversions, independently of wrapper creation.
@interface OASharedSearchUICore (LazyResultTests)
- (id<OASResultMatcher>)sharedMatcherFor:(OAResultMatcher *)matcher cancelledBySearch:(BOOL)cancelled;
@end

static NSMapTable<id, NSNumber *> *lazyConversionCounts;
static NSUInteger lazyMainConversions;
static id (*lazyOriginalConverter)(id, SEL, id);
static void (^lazyBeforeConversion)(id);
static id lazyCountConversion(id cls, SEL selector, id object)
{
    @synchronized (lazyConversionCounts)
    {
        NSNumber *count = object ? [lazyConversionCounts objectForKey:object] : nil;
        if (count)
        {
            [lazyConversionCounts setObject:@(count.unsignedIntegerValue + 1) forKey:object];
            if (NSThread.isMainThread) lazyMainConversions++;
        }
    }
    if (lazyBeforeConversion) lazyBeforeConversion(object);
    return lazyOriginalConverter(cls, selector, object);
}

@interface OASpatialLazyResultTest : XCTestCase
@property (nonatomic) OASharedSearchUICore *core;
@property (nonatomic) OASharedSearchPhrase *phrase;
@end

@implementation OASpatialLazyResultTest
- (void)setUp
{
    [super setUp];
    XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc] initWithPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) { return OsmAndApp.instance.initialized; }] object:nil];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[ready] timeout:60], XCTWaiterResultCompleted);
    self.core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    self.phrase = (OASharedSearchPhrase *)[self.core resetPhrase:@"cafe "];
    lazyConversionCounts = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory];
    lazyMainConversions = 0;
    Method method = class_getClassMethod(OASharedSearchObjects.class, @selector(appObjectFor:));
    lazyOriginalConverter = (id (*)(id, SEL, id))method_getImplementation(method);
    method_setImplementation(method, (IMP)lazyCountConversion);
}

- (void)tearDown
{
    method_setImplementation(class_getClassMethod(OASharedSearchObjects.class, @selector(appObjectFor:)), (IMP)lazyOriginalConverter);
    lazyBeforeConversion = nil;
    lazyConversionCounts = nil;
    [super tearDown];
}

- (OASSearchResult *)poi:(int)index level:(int)level
{
    OASAmenity *amenity = [[OASAmenity alloc] init];
    [amenity setIdId:[[OASLong alloc] initWithLongLong:100000 + index]];
    [amenity setTypeType:[OAPOIHelper.sharedInstance.kPoiTypes getPoiCategoryByNameName:@"sustenance"]];
    [amenity setSubTypeSubType:@"cafe"];
    [amenity setNameName:[NSString stringWithFormat:@"Cafe %d", index]];
    [amenity setLocationLatitude:53.55 + index * 0.0001 longitude:10];
    [amenity setAdditionalInfoTag:@"opening_hours" value:@"Mo-Fr 09:00-18:00"];
    [lazyConversionCounts setObject:@0 forKey:amenity];
    OASSearchResult *result = [[OASSearchResult alloc] initWithSp:self.phrase.shared];
    result.object = amenity;
    result.objectType = OASObjectType.poi;
    result.localeName = [amenity getName];
    result.location = [amenity getLocation];
    result.spatialSearchVisibleLevel = level;
    return result;
}

- (NSUInteger)conversions
{
    @synchronized (lazyConversionCounts)
    {
        NSUInteger count = 0;
        for (id object in lazyConversionCounts) count += [lazyConversionCounts objectForKey:object].unsignedIntegerValue;
        return count;
    }
}

- (OASharedSearchResultCollection *)collection:(NSArray<OASSearchResult *> *)results
{
    OASSearchUICoreSearchResultCollection *shared = [[OASSearchUICoreSearchResultCollection alloc] initWithPhrase:self.phrase.shared skipSorting:YES];
    [shared addSearchResultsSr:results resortAll:NO removeDuplicates:NO];
    return [[OASharedSearchResultCollection alloc] initWithShared:shared];
}

- (NSArray<OASearchResult *> *)prepare:(OASharedSearchResultCollection *)collection
{
    XCTestExpectation *ready = [self expectationWithDescription:@"visible models prepared"];
    __block NSArray *results;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        results = [collection prepareVisibleResultsWithCancellation:^BOOL{ return NO; }];
        [ready fulfill];
    });
    [self waitForExpectations:@[ready] timeout:15];
    return results;
}

- (void)testPublicationAndFullEnumerationDoNotConvertHiddenPoi
{
    NSMutableArray *published = [NSMutableArray array];
    OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *result) {
        [published addObject:*result]; return YES;
    } cancelledFunc:^BOOL{ return NO; }];
    id<OASResultMatcher> bridge = [self.core sharedMatcherFor:matcher cancelledBySearch:NO];
    for (int i = 0; i < 1000; i++) XCTAssertTrue([bridge publishObj:[self poi:i level:i / 200]]);
    XCTAssertEqual(self.conversions, 0u);
    OASharedSearchResultCollection *collection = [self collection:@[]];
    [collection addSearchResults:published resortAll:NO removeDuplicates:NO];
    XCTAssertEqual(collection.getCurrentSearchResults.count, 1000u);
    XCTAssertEqual(self.conversions, 0u);
    NSArray *visible = [self prepare:collection];
    XCTAssertEqual(visible.count, 200u);
    XCTAssertEqual(self.conversions, 200u);
    XCTAssertEqual(lazyMainConversions, 0u);
    XCTAssertEqualObjects([self prepare:collection], visible);
    XCTAssertEqual(self.conversions, 200u);
    XCTAssertTrue(collection.showMoreSpatialSearchResults);
    NSArray *more = [self prepare:collection];
    XCTAssertEqual(more.count, 400u);
    XCTAssertEqual(self.conversions, 400u);
    XCTAssertEqual(more.firstObject, visible.firstObject);
    XCTAssertEqual(((OASearchResult *)more.firstObject).object, ((OASearchResult *)visible.firstObject).object);
}

- (void)testCombiningRawCollectionsOnlyConvertsTheVisibleSubset
{
    NSMutableArray *left = [NSMutableArray array];
    NSMutableArray *right = [NSMutableArray array];
    for (int i = 0; i < 1000; i++) [(i < 500 ? left : right) addObject:[self poi:i level:i / 200]];
    OASharedSearchResultCollection *a = [self collection:left];
    OASharedSearchResultCollection *b = [self collection:right];
    OASearchResult *first = a.getVisibleSpatialSearchResults.firstObject;
    OASharedSearchResultCollection *combined = (id)[a combineWithCollection:b resort:NO removeDuplicates:NO];
    XCTAssertEqual(self.conversions, 0u);
    NSArray *visible = [self prepare:combined];
    XCTAssertEqual(visible.count, 200u);
    XCTAssertEqual(visible.firstObject, first);
    XCTAssertEqual(self.conversions, 200u);
    XCTAssertEqual(combined.getCurrentSearchResults.count, 1000u);
    XCTAssertEqual(self.conversions, 200u);
}

- (void)testReplacedObjectAndAddressAreReadFromTheSharedResult
{
    OASSearchResult *shared = [self poi:1 level:0];
    OASearchResult *result = [OASearchResult resultOfShared:shared phrase:self.phrase];
    OAPOI *before = (OAPOI *)result.object;
    shared.object = [self poi:2 level:0].object;
    shared.addressName = @"Updated street 2";
    OAPOI *after = (OAPOI *)result.object;
    XCTAssertNotEqual(before, after);
    XCTAssertEqualObjects(after.name, @"Cafe 2");
    XCTAssertEqualObjects(result.addressName, @"Updated street 2");
    XCTAssertEqual(result.object, after);
    XCTAssertEqual(self.conversions, 2u);
}

- (void)testRelatedAndParentObjectsStayLazyAndTrackReplacement
{
    OASSearchResult *shared = [self poi:1 level:0];
    shared.relatedObject = [self poi:2 level:0].object;
    shared.parentSearchResult = [self poi:3 level:0];
    OASearchResult *result = [OASearchResult resultOfShared:shared phrase:self.phrase];
    XCTAssertEqual(self.conversions, 0u);
    OASearchResult *parent = result.parentSearchResult;
    XCTAssertEqual(parent, result.parentSearchResult);
    XCTAssertEqual(self.conversions, 0u);
    XCTAssertEqualObjects(((OAPOI *)parent.object).name, @"Cafe 3");
    XCTAssertEqualObjects(((OAPOI *)result.relatedObject).name, @"Cafe 2");
    shared.relatedObject = [self poi:4 level:0].object;
    shared.parentSearchResult = [self poi:5 level:0];
    XCTAssertNotEqual(result.parentSearchResult, parent);
    XCTAssertEqualObjects(((OAPOI *)result.parentSearchResult.object).name, @"Cafe 5");
    XCTAssertEqualObjects(((OAPOI *)result.relatedObject).name, @"Cafe 4");
    XCTAssertEqual(self.conversions, 4u);
}

- (void)testCancelledPreparationDoesNotConvertAnyPoi
{
    OASharedSearchResultCollection *collection = [self collection:@[[self poi:1 level:0]]];
    XCTAssertNil([collection prepareVisibleResultsWithCancellation:^BOOL{ return YES; }]);
    XCTAssertEqual(self.conversions, 0u);
}

- (void)testCancellationDuringPreparationStopsBeforeTheNextPoi
{
    NSMutableArray *results = [NSMutableArray array];
    for (int i = 0; i < 100; i++) [results addObject:[self poi:i level:0]];
    OASharedSearchResultCollection *collection = [self collection:results];
    XCTAssertNil([collection prepareVisibleResultsWithCancellation:^BOOL{ return self.conversions >= 3; }]);
    XCTAssertEqual(self.conversions, 3u);
}

- (void)testParentAndRelatedAccessorsPreserveTheMutableResultContract
{
    OASSearchResult *shared = [self poi:1 level:0];
    shared.parentSearchResult = [self poi:2 level:0];
    OASearchResult *result = [OASearchResult resultOfShared:shared phrase:self.phrase];
    OASearchResult *original = result.parentSearchResult;
    XCTAssertEqual([result getDepth], 2);
    XCTAssertEqual([result setNewParentSearchResult:nil], original);
    XCTAssertNil(result.parentSearchResult);
    XCTAssertEqual([result getDepth], 1);
    OASearchResult *appParent = [[OASearchResult alloc] initWithPhrase:self.phrase];
    appParent.firstUnknownWordMatches = YES;
    result.parentSearchResult = appParent;
    XCTAssertEqual([result getDepth], 2);
    XCTAssertEqual([result getFoundWordCount], 1);
    result.relatedObject = @"platform object";
    XCTAssertEqualObjects(result.relatedObject, @"platform object");
    XCTAssertEqual(self.conversions, 0u);
    OASearchResult *native = [[OASearchResult alloc] initWithPhrase:self.phrase];
    native.parentSearchResult = appParent;
    XCTAssertEqual([native getDepth], 2);
    XCTAssertEqual([native getFoundWordCount], 1);
    XCTAssertEqual([native setNewParentSearchResult:nil], appParent);
    XCTAssertEqual([native getDepth], 1);
}

- (void)testMatchersMayReadHiddenObjectsAndStillRejectThem
{
    __block OAPOI *received;
    OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *result) {
        received = (OAPOI *)(*result).object; return NO;
    } cancelledFunc:^BOOL{ return NO; }];
    id<OASResultMatcher> bridge = [self.core sharedMatcherFor:matcher cancelledBySearch:NO];
    XCTAssertFalse([bridge publishObj:[self poi:1 level:4]]);
    XCTAssertEqualObjects(received.name, @"Cafe 1");
    XCTAssertEqual(self.conversions, 1u);
}

- (void)testTypeValidationMatchesConversionWithoutCreatingRejectedPoi
{
    OASSearchResult *shared = [self poi:1 level:0];
    OASAmenity *amenity = shared.object;
    NSSet *disabled = OAAppSettings.sharedManager.getDisabledTypes;
    @try
    {
        [OAAppSettings.sharedManager setDisabledTypes:[(disabled ?: [NSSet set]) setByAddingObject:@"cafe"]];
        XCTAssertFalse([OASharedSearchObjects canConvertSharedObject:amenity]);
        XCTAssertNil([OASearchResult resultOfShared:shared phrase:self.phrase]);
        XCTAssertNil([OAAmenitySearcher parsePOIBySharedAmenity:amenity]);
        XCTAssertEqual(self.conversions, 0u);
    }
    @finally { [OAAppSettings.sharedManager setDisabledTypes:disabled]; }
    [amenity setSubTypeSubType:@""];
    XCTAssertFalse([OASharedSearchObjects canConvertSharedObject:amenity]);
    XCTAssertNil([OASearchResult resultOfShared:shared phrase:self.phrase]);
    XCTAssertNil([OAAmenitySearcher parsePOIBySharedAmenity:amenity]);
    [amenity setSubTypeSubType:@"cafe"];
    OAPOIType *type = [OAPOIHelper.sharedInstance getPoiTypeByCategory:@"sustenance" name:@"cafe"];
    BOOL mapOnly = type.mapOnly;
    @try
    {
        type.mapOnly = YES;
        XCTAssertNil([OASearchResult resultOfShared:shared phrase:self.phrase]);
        XCTAssertNil([OAAmenitySearcher parsePOIBySharedAmenity:amenity]);
        XCTAssertNotNil([OAAmenitySearcher parsePOIBySharedAmenity:amenity filterTypes:NO], @"details retain the unfiltered conversion path");
    }
    @finally { type.mapOnly = mapOnly; }
}
- (void)testActualDuplicateMergeRefreshesAnAlreadyMaterializedResult
{
    OASSearchResult *shared = [self poi:1 level:0];
    OASearchResult *result = [OASearchResult resultOfShared:shared phrase:self.phrase];
    OAPOI *before = (OAPOI *)result.object;
    OASSearchResult *duplicate = [self poi:1 level:0];
    [(OASAmenity *)duplicate.object setAdditionalInfoTag:@"phone" value:@"12345"];
    OASearchResult *other = [OASearchResult resultOfShared:duplicate phrase:self.phrase];
    OASharedSearchResultCollection *collection = [[OASharedSearchResultCollection alloc] initWithPhrase:self.phrase];
    [collection addSearchResults:@[result, other] resortAll:YES removeDuplicates:YES];
    XCTAssertEqual(collection.getCurrentSearchResults.count, 1u);
    OASearchResult *merged = collection.getCurrentSearchResults.firstObject;
    XCTAssertEqual(merged, result);
    XCTAssertNotEqual(merged.sharedResult.object, before.sharedAmenity);
    OAPOI *after = (OAPOI *)merged.object;
    XCTAssertEqualObjects(after.values[@"phone"], @"12345");
    XCTAssertEqualObjects(after.values[@"opening_hours"], @"Mo-Fr 09:00-18:00");
    XCTAssertNotEqual(after, before);
}

@end

@interface OAQuickSearchViewController (LazyPresentationTests)
- (void)displayPreparedResults:(NSArray<OASearchResult *> *)results append:(BOOL)append;
- (void)cancelResultPreparation;
@end
@interface OALazyPresentationController : OASpatialPresentationTestController
@property (nonatomic) NSArray<OASearchResult *> *displayedResults;
@property (nonatomic, copy) void (^didDisplay)(void);
@end
@implementation OALazyPresentationController
- (void)displayPreparedResults:(NSArray<OASearchResult *> *)results append:(BOOL)append
{
    [super displayPreparedResults:results append:append];
    self.displayedResults = results;
    if (self.didDisplay) self.didDisplay();
}
@end
@interface OABlockedSpatialCollection : OASharedSearchResultCollection
@property (nonatomic) dispatch_semaphore_t releasePreparation;
@property (nonatomic, copy) void (^didStart)(void);
@end
@implementation OABlockedSpatialCollection
- (NSArray<OASearchResult *> *)prepareVisibleResultsWithCancellation:(BOOL (^)(void))cancelled
{
    self.didStart();
    dispatch_semaphore_wait(self.releasePreparation, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    // Emulates a completed snapshot whose delivery races with a new query or closing the screen.
    return self.getVisibleSpatialSearchResults;
}
@end

@implementation OASpatialLazyResultTest (Presentation)
- (OALazyPresentationController *)presentationController
{
    OALazyPresentationController *controller = [[OALazyPresentationController alloc] init];
    controller.searchUICore = self.core;
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 402, 600) style:UITableViewStylePlain];
    OAQuickSearchTableController *tableController = [[OAQuickSearchTableController alloc] initWithTableView:table];
    tableController.delegate = (id<OAQuickSearchTableDelegate>)controller;
    [controller setValue:tableController forKey:@"tableController"];
    return controller;
}

- (void)testVisibleModelsArePreparedOffMainBeforeRendering
{
    OALazyPresentationController *controller = [self presentationController];
    controller.collection = [self collection:@[[self poi:1 level:0], [self poi:2 level:1]]];
    XCTestExpectation *displayed = [self expectationWithDescription:@"visible snapshot rendered"];
    controller.didDisplay = ^{ [displayed fulfill]; };
    [controller updateSearchResult:controller.collection append:NO];
    [controller addMoreButton];
    [self waitForExpectations:@[displayed] timeout:5];
    XCTAssertEqual(controller.displayedResults.count, 1u);
    XCTAssertEqual(self.conversions, 1u);
    XCTAssertEqual(lazyMainConversions, 0u);
    OAQuickSearchTableController *table = [controller valueForKey:@"tableController"];
    [table tableView:table.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertEqual(lazyMainConversions, 0u, @"rendering reuses the prepared object");
    XCTAssertEqual([table tableView:table.tableView numberOfRowsInSection:0], 2, @"Show more survives asynchronous preparation");
}

- (void)testNewSnapshotSupersedesAnInFlightPreparation
{
    OALazyPresentationController *controller = [self presentationController];
    OABlockedSpatialCollection *old = [[OABlockedSpatialCollection alloc] initWithShared:[self collection:@[[self poi:1 level:0]]].shared];
    old.releasePreparation = dispatch_semaphore_create(0);
    XCTestExpectation *started = [self expectationWithDescription:@"old preparation started"];
    old.didStart = ^{ [started fulfill]; };
    controller.collection = old;
    [controller updateSearchResult:old append:NO];
    [self waitForExpectations:@[started] timeout:5];
    XCTestExpectation *displayed = [self expectationWithDescription:@"only replacement rendered"];
    displayed.assertForOverFulfill = YES;
    controller.didDisplay = ^{ [displayed fulfill]; };
    controller.collection = [self collection:@[[self poi:2 level:0]]];
    [controller updateSearchResult:controller.collection append:NO];
    dispatch_semaphore_signal(old.releasePreparation);
    [self waitForExpectations:@[displayed] timeout:5];
    XCTAssertEqualObjects(controller.displayedResults.firstObject.localeName, @"Cafe 2");
    XCTAssertEqual(self.conversions, 1u);
}

- (void)testDuplicatePublicationReplacesTheObjectDuringBackgroundPreparation
{
    OASSearchResult *shared = [self poi:1 level:0];
    OASAmenity *original = shared.object;
    OASSearchResult *duplicate = [self poi:1 level:0];
    [(OASAmenity *)duplicate.object setAdditionalInfoTag:@"phone" value:@"12345"];
    OASearchResult *other = [OASearchResult resultOfShared:duplicate phrase:self.phrase];
    OALazyPresentationController *controller = [self presentationController];
    // The sorted API collection merges duplicate amenities during publication.
    controller.collection = [[OASharedSearchResultCollection alloc] initWithPhrase:self.phrase];
    [controller.collection addSearchResults:@[[OASearchResult resultOfShared:shared phrase:self.phrase]] resortAll:YES removeDuplicates:YES];
    OASearchResult *wrapper = controller.collection.getVisibleSpatialSearchResults.firstObject;

    dispatch_semaphore_t resumeConversion = dispatch_semaphore_create(0);
    XCTestExpectation *started = [self expectationWithDescription:@"original conversion in flight"];
    lazyBeforeConversion = ^(id object) {
        if (object == original)
        {
            XCTAssertFalse(NSThread.isMainThread);
            [started fulfill];
            XCTAssertEqual(dispatch_semaphore_wait(resumeConversion, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)), 0);
        }
    };
    XCTestExpectation *displayed = [self expectationWithDescription:@"only merged result displayed"];
    displayed.assertForOverFulfill = YES;
    controller.didDisplay = ^{ [displayed fulfill]; };
    [controller updateSearchResult:controller.collection append:NO];
    @try
    {
        [self waitForExpectations:@[started] timeout:5];
        XCTestExpectation *published = [self expectationWithDescription:@"duplicate published during conversion"];
        [controller showApiResults:@[other] phrase:self.phrase api:nil hasRegionCollection:NO
            onPublish:^(OASearchResultCollection *collection, BOOL append) {
                XCTAssertNotEqual(shared.object, original);
                @synchronized (lazyConversionCounts)
                {
                    [lazyConversionCounts setObject:@0 forKey:shared.object];
                }
                [controller updateSearchResult:collection append:append];
                [published fulfill];
            }];
        [self waitForExpectations:@[published] timeout:5];
        XCTAssertNil(controller.displayedResults);
    }
    @finally { dispatch_semaphore_signal(resumeConversion); }

    [self waitForExpectations:@[displayed] timeout:5];
    XCTAssertEqual(controller.displayedResults.count, 1u);
    XCTAssertEqual(controller.displayedResults.firstObject, wrapper);
    XCTAssertEqual(controller.collection.getVisibleSpatialSearchResults.firstObject, wrapper);
    OAPOI *merged = (OAPOI *)wrapper.object;
    XCTAssertEqual(merged.sharedAmenity, shared.object);
    XCTAssertNotEqual(merged.sharedAmenity, original);
    XCTAssertEqualObjects(merged.name, @"Cafe 1");
    XCTAssertEqualObjects(merged.values[@"phone"], @"12345");
    XCTAssertEqualObjects(merged.values[@"opening_hours"], @"Mo-Fr 09:00-18:00");
    XCTAssertEqual(wrapper.object, merged);
    XCTAssertEqual(self.conversions, 2u);
    XCTAssertEqual(lazyMainConversions, 0u);
}

- (void)testLeavingTheScreenDiscardsPreparedResults
{
    OALazyPresentationController *controller = [self presentationController];
    OABlockedSpatialCollection *old = [[OABlockedSpatialCollection alloc] initWithShared:[self collection:@[[self poi:1 level:0]]].shared];
    old.releasePreparation = dispatch_semaphore_create(0);
    XCTestExpectation *started = [self expectationWithDescription:@"preparation started"];
    old.didStart = ^{ [started fulfill]; };
    XCTestExpectation *displayed = [self expectationWithDescription:@"closed screen must not render"];
    displayed.inverted = YES;
    controller.didDisplay = ^{ [displayed fulfill]; };
    [controller updateSearchResult:old append:NO];
    [self waitForExpectations:@[started] timeout:5];
    [controller viewWillDisappear:NO];
    dispatch_semaphore_signal(old.releasePreparation);
    [self waitForExpectations:@[displayed] timeout:0.3];
    XCTAssertNil(controller.displayedResults);
    XCTAssertEqual(self.conversions, 0u);
}
@end
