//
//  OASharedSearchAppAPIsTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import "OASharedSearchAppAPIs.h"
#import "OASharedSearchUICore.h"
#import "OASharedSearchObjects.h"
#import "OAQuickSearchHelper.h"
#import "OASearchResult+cpp.h"
#import "OASearchWord.h"
#import "OAResultMatcher.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteGroup.h"
#import "OAQuickSearchListItem.h"
#import "OAHistoryItem.h"
#import "OAPointDescription.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAResourcesUIHelper.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

@interface OATestSharedFavoritesAPI : OASharedSearchFavoritesAPI
@property (nonatomic) NSArray<OAFavoriteItem *> *items;
@end
@implementation OATestSharedFavoritesAPI
- (NSArray<OAFavoriteItem *> *)favoriteItems { return self.items; }
@end

@interface OATestSharedCategoriesAPI : OASharedSearchFavoritesCategoryAPI
@property (nonatomic) NSArray<OAFavoriteGroup *> *groups;
@end
@implementation OATestSharedCategoriesAPI
- (NSArray<OAFavoriteGroup *> *)favoriteGroups { return self.groups; }
@end

@interface OATestSharedGpxAPI : OASharedSearchGpxAPI
@property (nonatomic) NSArray<OASGpxDataItem *> *items;
@end
@implementation OATestSharedGpxAPI
- (NSArray<OASGpxDataItem *> *)gpxItems { return self.items; }
@end

@interface OATestSharedWptAPI : OASharedSearchWptAPI
@property (nonatomic) NSArray<OASGpxFile *> *files;
@property (nonatomic) NSArray<NSString *> *paths;
@property (atomic) NSInteger reads;
@end
@implementation OATestSharedWptAPI
- (void)readGpxFiles:(void (^)(NSArray<OASGpxFile *> *, NSArray<NSString *> *))reader
{
    NSAssert(NSThread.isMainThread, @"Read the GPX selection on main");
    self.reads++;
    reader(self.files ?: @[], self.paths ?: @[]);
}
@end

// History's display type is normally reconstructed by the app's history store.
@interface OATestSearchHistoryItem : OAHistoryItem
@property (nonatomic) NSString *descriptionType;
@end
@implementation OATestSearchHistoryItem
- (NSString *)getPointDescriptionType { return self.descriptionType; }
@end

@interface OATestSharedHistoryAPI : OASharedSearchHistoryAPI
@property (nonatomic) NSArray<OAHistoryItem *> *items;
@property (nonatomic) OASGpxDataItem *track;
@end
@implementation OATestSharedHistoryAPI
- (NSArray<OAHistoryItem *> *)historyItems { return self.items; }
- (OASGpxDataItem *)gpxItemNamed:(NSString *)name { return self.track; }
@end

@interface OATestSharedIndexAPI : OASharedSearchIndexItemAPI
@property (nonatomic) OAWorldRegion *root;
@property (nonatomic) NSDictionary<NSString *, OARepositoryResourceItem *> *maps;
@property (nonatomic) NSInteger lookups;
@end
@implementation OATestSharedIndexAPI
- (OAWorldRegion *)worldRegion { return self.root; }
- (OARepositoryResourceItem *)uninstalledMapForRegion:(OAWorldRegion *)region
{
    self.lookups++;
    return self.maps[region.regionId];
}
@end

@interface OASharedSearchAppAPIsTest : XCTestCase
@end

@implementation OASharedSearchAppAPIsTest

- (void)setUp
{
    [super setUp];
    XCTNSPredicateExpectation *ready = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"initialized == YES"] object:OsmAndApp.instance];
    [self waitForExpectations:@[ready] timeout:120];
}

- (OASearchResult *)appResult:(OASSearchResult *)result
{
    return [OASearchResult resultOfShared:result phrase:[[OASharedSearchPhrase alloc] initWithShared:result.requiredSearchPhrase]];
}

- (OASSearchPhrase *)phrase:(NSString *)text
{
    OASSearchSettings *settings = [[OASSearchSettings alloc] initWithS:nil];
    settings = [settings setLangLang:@"en" transliterateIfMissing:NO];
    settings = [settings setOriginalLocationL:[[OASKLatLon alloc] initWithLatitude:52.52 longitude:13.405]];
    return [[OASSearchPhrase.companion emptyPhraseSettings:settings] generateNewPhraseText:text settings:settings];
}

- (OASSearchUICoreSearchResultMatcher *)matcher:(OASSearchPhrase *)phrase outer:(id<OASResultMatcher>)outer
{
    return [[OASSearchUICoreSearchResultMatcher alloc] initWithMatcher:outer phrase:phrase request:0
        requestNumber:[[OASStately_concurrencyAtomicInt alloc] initWithInitialValue:0] totalLimit:-1];
}

- (NSArray<OASSearchResult *> *)search:(OASharedSearchAppAPI *)api text:(NSString *)text
{
    OASSearchPhrase *phrase = [self phrase:text];
    OASSearchUICoreSearchResultMatcher *matcher = [self matcher:phrase outer:nil];
    [api searchPhrase:phrase resultMatcher:matcher];
    return [matcher getRequestResults];
}

- (OAFavoriteItem *)favorite:(NSString *)name group:(NSString *)group
{
    return [[OAFavoriteItem alloc] initWithLat:52.52 lon:13.405 name:name category:group];
}

- (OASGpxDataItem *)track:(NSString *)name
{
    NSString *path = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:name];
    return [[OASGpxDataItem alloc] initWithFile:[[OASKFile alloc] initWithFilePath:path]];
}

- (OASWptPt *)waypoint:(NSString *)name
{
    OASWptPt *point = [[OASWptPt alloc] init];
    point.name = name;
    point.lat = 52.52;
    point.lon = 13.405;
    return point;
}

- (void)testRegistrationAndSearchTypeRestrictions
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    NSArray<Class> *classes = @[SearchIndexItemAPI.class, OASearchFavoritesAPI.class,
        OASearchFavoritesCategoryAPI.class, OASearchWptAPI.class, OASearchHistoryAPI.class, OASearchGpxAPI.class];
    for (Class api in classes)
        [core registerAPI:[[api alloc] init]];
    XCTAssertEqual([core.shared getApis].count, 6u);
    NSArray<OASObjectType *> *types = @[OASObjectType.indexItem, OASObjectType.favorite,
        OASObjectType.favoriteGroup, OASObjectType.wpt, OASObjectType.recentObj, OASObjectType.gpxTrack];
    for (NSUInteger i = 0; i < classes.count; i++)
    {
        id<OASSearchCoreAPI> api = [core.shared getApis][i];
        XCTAssertTrue([(NSObject *)api isKindOfClass:[OASharedSearchAppAPIs sharedClassForAppClass:classes[i]]]);
        XCTAssertFalse([api isSearchMoreAvailablePhrase:[self phrase:@"test"]]);
        for (OASObjectType *type in @[types[i], OASObjectType.city])
        {
            OASSearchSettings *settings = [[self phrase:@"test"] getSettings];
            settings = [settings setSearchTypesSearchTypes:[OASKotlinArray arrayWithSize:1 init:^id(OASInt *index) { return type; }]];
            OASSearchPhrase *phrase = [[OASSearchPhrase.companion emptyPhraseSettings:settings] generateNewPhraseText:@"test" settings:settings];
            XCTAssertEqual([api isSearchAvailableP:phrase], type == types[i]);
        }
    }
}

- (void)testPrioritiesForEmptyTypedAndSelectedPhrases
{
    OASSearchPhrase *empty = [self phrase:@""];
    OASSearchPhrase *typed = [self phrase:@"park"];
    OASSearchResult *selected = [[OASSearchResult alloc] initWithSp:typed];
    selected.objectType = OASObjectType.city;
    selected.localeName = @"Berlin";
    OASSearchPhrase *withCity = [typed selectWordRes:selected settings:nil];
    for (OASharedSearchAppAPI *api in @[[[OASharedSearchFavoritesAPI alloc] init], [[OASharedSearchFavoritesCategoryAPI alloc] init],
                                      [[OASharedSearchGpxAPI alloc] init]])
    {
        XCTAssertEqual([api getSearchPriorityP:empty], -1);
        XCTAssertEqual([api getSearchPriorityP:typed], 150);
        XCTAssertEqual([api getSearchPriorityP:withCity], -1);
    }
    OASharedSearchHistoryAPI *history = [[OASharedSearchHistoryAPI alloc] init];
    XCTAssertEqual([history getSearchPriorityP:empty], 150);
    XCTAssertEqual([history getSearchPriorityP:typed], -1);
    XCTAssertEqual([history getSearchPriorityP:withCity], -1);
    for (OASharedSearchAppAPI *api in @[[[OASharedSearchWptAPI alloc] init], [[OASharedSearchIndexItemAPI alloc] init]])
    {
        XCTAssertEqual([api getSearchPriorityP:typed], 150);
        XCTAssertEqual([api getSearchPriorityP:withCity], -1);
    }
}

- (void)testFavoritesKeepVisibilityNamesAndTheObjectNeededByTheScreen
{
    OATestSharedFavoritesAPI *api = [[OATestSharedFavoritesAPI alloc] init];
    OAFavoriteItem *visible = [self favorite:@"Riverside Park" group:@"Walks"];
    OAFavoriteItem *hidden = [self favorite:@"Hidden Park" group:@"Walks"];
    [hidden setVisible:NO];
    api.items = @[visible, hidden, [self favorite:@"Museum" group:@"Walks"]];
    NSArray *results = [self search:api text:@" park "];
    XCTAssertEqual(results.count, 1u);
    OASearchResult *result = [self appResult:results.firstObject];
    XCTAssertEqual(result.object, visible);
    XCTAssertEqual(result.favorite.get(), visible.favorite.get());
    XCTAssertEqualObjects(result.localeName, @"Riverside Park");
    XCTAssertEqual(result.location.coordinate.latitude, 52.52);
    XCTAssertEqual(result.preferredZoom, PREFERRED_FAVORITE_ZOOM);
    XCTAssertEqual([self search:api text:@"p"].count, 2u);
}

- (OAFavoriteGroup *)group:(NSString *)name count:(NSInteger)count
{
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++)
        [points addObject:[self favorite:[NSString stringWithFormat:@"Stop %ld", (long)i] group:name]];
    return [[OAFavoriteGroup alloc] initWithPoints:points name:name isVisible:YES color:UIColor.redColor];
}

- (void)testGroupsPublishPointsBelowFiveAndAGroupFromFive
{
    OATestSharedCategoriesAPI *api = [[OATestSharedCategoriesAPI alloc] init];
    OAFavoriteGroup *small = [self group:@"Weekend Small" count:4];
    OAFavoriteGroup *large = [self group:@"Weekend Large" count:5];
    OAFavoriteGroup *hidden = [self group:@"Weekend Hidden" count:5];
    hidden.isVisible = NO;
    api.groups = @[small, large, hidden, [self group:@"Museums" count:5]];
    NSArray<OASSearchResult *> *results = [self search:api text:@"Week"];
    XCTAssertEqual(results.count, 5u);
    for (NSUInteger i = 0; i < 4; i++)
    {
        XCTAssertEqual(results[i].objectType, OASObjectType.favorite);
        XCTAssertEqual(results[i].object, small.points[i]);
        XCTAssertEqual(results[i].priority, 150);
        XCTAssertEqual(results[i].preferredZoom, PREFERRED_FAVORITE_ZOOM);
    }
    OASSearchResult *group = results.lastObject;
    XCTAssertEqual(group.objectType, OASObjectType.favoriteGroup);
    XCTAssertEqual(group.object, large);
    XCTAssertEqual(group.priority, 151);
    XCTAssertEqual(group.preferredZoom, PREFERRED_FAVORITES_GROUP_ZOOM);
    OASearchResult *appResult = [self appResult:group];
    XCTAssertEqual(appResult.objectType, EOAObjectTypeFavoriteGroup);
    XCTAssertEqual(appResult.object, large);
    XCTAssertEqual(appResult.toSharedResult.object, large);
    XCTAssertTrue([OAQuickSearchListItem getTypeName:appResult].length > 0);

    OAFavoriteGroup *unnamed = [self group:@"" count:5];
    api.groups = @[unnamed];
    results = [self search:api text:[OAFavoriteGroup getDisplayName:@""]];
    XCTAssertEqual(results.count, 1u);
    XCTAssertEqual(results.firstObject.object, unnamed);
}

- (NSArray<OASearchResult *> *)fullSearch:(OASharedSearchUICore *)core text:(NSString *)text
{
    XCTestExpectation *done = [self expectationWithDescription:@"full search finished"];
    NSMutableArray *results = [NSMutableArray array];
    OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *value) {
        if ((*value).objectType == EOAObjectTypeFavorite || (*value).objectType == EOAObjectTypeFavoriteGroup)
            [results addObject:*value];
        if ((*value).objectType == EOAObjectTypeSearchFinished)
            [done fulfill];
        return YES;
    } cancelledFunc:^BOOL { return NO; }];
    [core search:text delayedExecution:NO matcher:matcher];
    [self waitForExpectations:@[done] timeout:20];
    XCTestExpectation *idle = [self expectationWithDescription:@"search queue idle"];
    [core.shared runAfterSearchTask:^{ [idle fulfill]; }];
    [self waitForExpectations:@[idle] timeout:10];
    return results;
}

- (void)testSelectingAGroupShowsOnlyItsVisiblePointsAndFiltersTheRemainingQuery
{
    for (NSNumber *spatial in @[@NO, @YES])
    {
        OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
        [core initApiUseSpatialSearch:spatial.boolValue searchRulesDir:[NSBundle.mainBundle pathForResource:@"abbr" ofType:nil] ?: @""];
        OAFavoriteGroup *group = [self group:@"Weekend Walks" count:5];
        [group.points.lastObject setVisible:NO];
        OATestSharedCategoriesAPI *categories = [[OATestSharedCategoriesAPI alloc] init];
        categories.groups = @[group];
        OATestSharedFavoritesAPI *favorites = [[OATestSharedFavoritesAPI alloc] init];
        favorites.items = [group.points arrayByAddingObject:[self favorite:@"Stop 1" group:@"Other"]];
        [core.shared registerAPIApi:favorites];
        [core.shared registerAPIApi:categories];
        NSArray<OASearchResult *> *results = [self fullSearch:core text:@"Weekend"];
        XCTAssertEqual(results.count, 1u);
        OASearchResult *selected = results.firstObject;
        XCTAssertEqual(selected.objectType, EOAObjectTypeFavoriteGroup);
        [core selectSearchResult:selected];
        NSString *prefix = [core.getPhrase getText:YES];
        results = [self fullSearch:core text:prefix];
        XCTAssertEqual(results.count, 4u, @"spatial=%@", spatial);
        for (OASearchResult *result in results)
            XCTAssertEqualObjects(((OAFavoriteItem *)result.object).getCategory, group.name);
        results = [self fullSearch:core text:[prefix stringByAppendingString:@"Stop 1"]];
        XCTAssertEqual(results.count, 1u, @"spatial=%@", spatial);
        XCTAssertEqual(results.firstObject.object, group.points[1]);
        [core cancelSearch:NO];
    }
}

- (void)testGpxResultsHavePerTypeAndCombinedLimits
{
    OATestSharedWptAPI *waypoints = [[OATestSharedWptAPI alloc] init];
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:[self waypoint:@"  "]];
    [file addPointPoint:[self waypoint:@"Unrelated"]];
    NSMutableArray *items = [NSMutableArray arrayWithObject:[self track:@"Temp/Match.gpx"]];
    for (int i = 0; i < 6; i++)
    {
        [file addPointPoint:[self waypoint:[NSString stringWithFormat:@"Match point %d", i]]];
        [items addObject:[self track:[NSString stringWithFormat:@"Match track %d.gpx", i]]];
    }
    waypoints.files = @[file];
    waypoints.paths = @[@"selected.gpx"];
    OATestSharedGpxAPI *tracks = [[OATestSharedGpxAPI alloc] init];
    tracks.items = items;
    XCTAssertEqual([self search:tracks text:@"Match"].count, 4u);
    XCTAssertEqual([self search:waypoints text:@"Match"].count, 4u);
    OASSearchPhrase *phrase = [self phrase:@"Match"];
    OASSearchUICoreSearchResultMatcher *matcher = [self matcher:phrase outer:nil];
    [waypoints searchPhrase:phrase resultMatcher:matcher];
    [tracks searchPhrase:phrase resultMatcher:matcher];
    NSArray<OASSearchResult *> *results = [matcher getRequestResults];
    XCTAssertEqual(results.count, 7u);
    XCTAssertEqual([results filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OASSearchResult *result, NSDictionary *bindings) {
        return result.objectType == OASObjectType.wpt;
    }]].count, 4u);
    XCTAssertEqual(results.lastObject.objectType, OASObjectType.gpxTrack);
}

- (void)testTracksKeepTheirDataItemsAndExcludeTemporaryFiles
{
    OATestSharedGpxAPI *api = [[OATestSharedGpxAPI alloc] init];
    OASGpxDataItem *track = [self track:@"Walks/Riverside.gpx"];
    api.items = @[track, [self track:@"Temp/Riverside.gpx"], [self track:@"Other.gpx"]];
    NSArray<OASSearchResult *> *results = [self search:api text:@"riverside"];
    XCTAssertEqual(results.count, 1u);
    OASearchResult *app = [self appResult:results.firstObject];
    XCTAssertEqual(app.relatedObject, track);
    XCTAssertEqual(app.objectType, EOAObjectTypeGpxTrack);
    XCTAssertEqual(app.priority, 153);
    XCTAssertEqual([self search:api text:@"r"].count, 2u);
}

- (void)testWaypointsKeepTheirFileAndRecordingTrackAndSkipEmptyNames
{
    OATestSharedWptAPI *api = [[OATestSharedWptAPI alloc] init];
    OASGpxFile *selected = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASWptPt *point = [self waypoint:@"  Riverside stop  "];
    [selected addPointPoint:point];
    [selected addPointPoint:[self waypoint:@"   "]];
    OASGpxFile *recording = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [recording addPointPoint:[self waypoint:@"Riverside recording"]];
    api.files = @[selected, recording];
    api.paths = @[@"Walks/River.gpx"];
    NSArray<OASSearchResult *> *results = [self search:api text:@"riverside"];
    XCTAssertEqual(results.count, 2u);
    OASearchResult *app = [self appResult:results.firstObject];
    XCTAssertEqual(app.wpt, point);
    XCTAssertEqual(app.object, point);
    XCTAssertEqual(app.relatedGpx, selected);
    XCTAssertEqual(app.relatedObject, selected);
    XCTAssertEqualObjects(app.localeName, @"Riverside stop");
    XCTAssertEqualObjects(app.localeRelatedObjectName, @"River.gpx");
    XCTAssertEqual(results.lastObject.relatedObject, recording);
    XCTAssertTrue(results.lastObject.localeRelatedObjectName.length > 0);
    XCTAssertEqual([self search:api text:@""].count, 0u);
}

- (OATestSearchHistoryItem *)history:(NSString *)name type:(NSString *)type
{
    OATestSearchHistoryItem *item = [OATestSearchHistoryItem new];
    item.name = name;
    item.typeName = @"test";
    item.descriptionType = type;
    item.latitude = 52.52;
    item.longitude = 13.405;
    return item;
}

- (void)testHistoryRestoresLocationsPoiTypesFiltersAndTracks
{
    OATestSharedHistoryAPI *api = [[OATestSharedHistoryAPI alloc] init];
    OAPOIUIFilter *filter = [OAPOIFiltersHelper.sharedInstance getShowAllPOIFilter];
    api.track = [self track:@"History.gpx"];
    api.items = @[[self history:@"Berlin" type:POINT_TYPE_LOCATION],
                  [self history:@"cafe" type:POINT_TYPE_POI_TYPE],
                  [self history:filter.filterId type:POINT_TYPE_CUSTOM_POI_FILTER],
                  [self history:@"History.gpx" type:POINT_TYPE_GPX_FILE],
                  [self history:@"nonexistent_test_type" type:POINT_TYPE_POI_TYPE]];
    NSArray<OASSearchResult *> *results = [self search:api text:@""];
    XCTAssertEqual(results.count, 4u);
    if (results.count != 4)
        return;
    for (NSUInteger i = 0; i < results.count; i++)
        XCTAssertEqual(results[i].priority, 154 + i);
    XCTAssertEqual(results[0].objectType, OASObjectType.recentObj);
    XCTAssertEqual(results[0].object, api.items[0]);
    XCTAssertEqual(results[1].objectType, OASObjectType.poiType);
    XCTAssertTrue([results[1].object isKindOfClass:OASAbstractPoiType.class]);
    XCTAssertEqual([self appResult:results[2]].object, filter);
    XCTAssertEqual(results[3].objectType, OASObjectType.gpxTrack);
    XCTAssertEqual(results[3].relatedObject, api.track);
    XCTAssertEqual([self search:api text:@"Berl"].count, 1u);
}

- (void)testRegionSearchMatchesNamesAndPreservesDownloadResource
{
    OATestSharedIndexAPI *api = [[OATestSharedIndexAPI alloc] init];
    OAWorldRegion *root = [[OAWorldRegion alloc] initWithId:@"test" andLocalizedName:@"World"];
    OAWorldRegion *continent = [[OAWorldRegion alloc] initWithId:@"europe" andLocalizedName:@"Europe"];
    OAWorldRegion *region = [[OAWorldRegion alloc] initWithId:@"berlin" andLocalizedName:@"Berlin"];
    root.resourceTypes = @[];
    [root addSubregion:continent];
    [continent addSubregion:region];
    region.resourceTypes = @[@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)];
    OARepositoryResourceItem *map = [OARepositoryResourceItem new];
    map.resourceId = QStringLiteral("test_berlin.obf");
    map.title = @"Berlin, Germany";
    api.root = root;
    api.maps = @{@"berlin":map};
    NSArray<OASSearchResult *> *results = [self search:api text:@"Berlin"];
    XCTAssertEqual(results.count, 1u);
    OASearchResult *app = [self appResult:results.firstObject];
    XCTAssertEqual(app.relatedObject, map);
    XCTAssertEqualObjects(app.resourceId, @"test_berlin.obf");
    XCTAssertEqual(app.objectType, EOAObjectTypeIndexItem);
    XCTAssertEqual(app.unknownPhraseMatchWeight, -1);
    XCTAssertEqual([self search:api text:@"Berl"].count, 0u);
    api.maps = @{};
    XCTAssertEqual([self search:api text:@"Berlin"].count, 0u);
}

- (void)testCancellationStopsAnActiveSourceAfterItsFirstResult
{
    OATestSharedFavoritesAPI *api = [[OATestSharedFavoritesAPI alloc] init];
    api.items = @[[self favorite:@"Park one" group:@""], [self favorite:@"Park two" group:@""]];
    __block BOOL cancelled = NO;
    id<OASResultMatcher> outer = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id result) {
        cancelled = YES;
        return YES;
    } cancelled:^BOOL { return cancelled; }];
    OASSearchPhrase *phrase = [self phrase:@"park"];
    OASSearchUICoreSearchResultMatcher *matcher = [self matcher:phrase outer:outer];
    XCTAssertFalse([api searchPhrase:phrase resultMatcher:matcher]);
    XCTAssertEqual([matcher getRequestResults].count, 1u);
}

- (void)testNativeFavoriteAndWaypointFieldsSurviveConversionAndSelection
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OAFavoriteItem *favorite = [self favorite:@"Park" group:@"Walks"];
    OASearchResult *native = [[OASearchResult alloc] initWithPhrase:core.getPhrase];
    native.objectType = EOAObjectTypeFavorite;
    native.localeName = favorite.getDisplayName;
    native.favorite = favorite.favorite;
    OASearchResult *back = [self appResult:[native toSharedResult]];
    XCTAssertEqual(back.favorite.get(), favorite.favorite.get());
    XCTAssertEqualObjects(back.object, favorite);

    OASWptPt *point = [self waypoint:@"Stop"];
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:point];
    OASearchResult *waypoint = [[OASearchResult alloc] initWithPhrase:core.getPhrase];
    waypoint.objectType = EOAObjectTypeWpt;
    waypoint.localeName = point.name;
    waypoint.wpt = point;
    waypoint.relatedGpx = file;
    back = [self appResult:[waypoint toSharedResult]];
    XCTAssertEqual(back.wpt, point);
    XCTAssertEqual(back.relatedGpx, file);
    XCTAssertTrue([core selectSearchResult:back]);
    back = [core.getPhrase getLastSelectedWord].result;
    XCTAssertEqual(back.wpt, point);
    XCTAssertEqual(back.relatedGpx, file);
}

- (void)testTrackAndWaypointCancellationStopsAfterTheFirstMatch
{
    OATestSharedGpxAPI *tracks = [[OATestSharedGpxAPI alloc] init];
    tracks.items = @[[self track:@"Park one.gpx"], [self track:@"Park two.gpx"]];
    OATestSharedWptAPI *points = [[OATestSharedWptAPI alloc] init];
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [file addPointPoint:[self waypoint:@"Park one"]];
    [file addPointPoint:[self waypoint:@"Park two"]];
    points.files = @[file];
    points.paths = @[@"Park.gpx"];
    for (OASharedSearchAppAPI *api in @[tracks, points])
    {
        __block BOOL cancelled = NO;
        id<OASResultMatcher> outer = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id result) {
            cancelled = YES;
            return YES;
        } cancelled:^BOOL { return cancelled; }];
        OASSearchPhrase *phrase = [self phrase:@"park"];
        OASSearchUICoreSearchResultMatcher *matcher = [self matcher:phrase outer:outer];
        XCTAssertFalse([api searchPhrase:phrase resultMatcher:matcher]);
        XCTAssertEqual([matcher getRequestResults].count, 1u);
    }
}

- (void)testCancelledWaypointSearchDoesNotWaitForTheMainQueue
{
    OATestSharedWptAPI *api = [[OATestSharedWptAPI alloc] init];
    OASStately_concurrencyAtomicInt *cancelled = [[OASStately_concurrencyAtomicInt alloc] initWithInitialValue:0];
    dispatch_semaphore_t waiting = dispatch_semaphore_create(0);
    dispatch_semaphore_t finished = dispatch_semaphore_create(0);
    __block int checks = 0;
    id<OASResultMatcher> outer = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id result) {
        XCTFail(@"Cancelled waypoint search published a result");
        return YES;
    } cancelled:^BOOL {
        if (++checks == 2)
            dispatch_semaphore_signal(waiting);
        return [cancelled get] != 0;
    }];
    OASSearchPhrase *phrase = [self phrase:@"stop"];
    OASSearchUICoreSearchResultMatcher *matcher = [self matcher:phrase outer:outer];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [api searchPhrase:phrase resultMatcher:matcher];
        dispatch_semaphore_signal(finished);
    });
    // Keep main occupied until the search has actually begun waiting for it.
    XCTAssertEqual(dispatch_semaphore_wait(waiting, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);
    [cancelled setNewValue:1];
    XCTAssertEqual(dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);
    XCTestExpectation *drained = [self expectationWithDescription:@"main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:3];
    XCTAssertEqual(api.reads, 0);
}

- (void)testShallowLookupAndSelectionKeepFavoriteIdentity
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OATestSharedFavoritesAPI *api = [[OATestSharedFavoritesAPI alloc] init];
    OAFavoriteItem *favorite = [self favorite:@"Riverside Park" group:@"Walks"];
    api.items = @[favorite];
    [core.shared registerAPIApi:api];
    XCTestExpectation *done = [self expectationWithDescription:@"shallow search"];
    __block OASearchResult *found;
    [core shallowSearchAsync:OASearchFavoritesAPI.class text:@"park" matcher:nil completion:^(OASearchResultCollection *collection) {
        found = [collection getCurrentSearchResults].firstObject;
        [done fulfill];
    }];
    [self waitForExpectations:@[done] timeout:10];
    XCTAssertNotNil(found);
    XCTAssertEqual(found.favorite.get(), favorite.favorite.get());
    [core selectSearchResult:found];
    OASearchResult *selected = [core.getPhrase getLastSelectedWord].result;
    XCTAssertEqual(selected.object, favorite);
    XCTAssertEqual(selected.favorite.get(), favorite.favorite.get());
}

- (void)testFavoriteResultsArePublishedInClassicAndSpatialSearch
{
    for (NSNumber *spatial in @[@NO, @YES])
    {
        OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
        NSString *rules = [NSBundle.mainBundle pathForResource:@"abbr" ofType:nil];
        [core initApiUseSpatialSearch:spatial.boolValue searchRulesDir:rules ?: @""];
        OATestSharedFavoritesAPI *api = [[OATestSharedFavoritesAPI alloc] init];
        api.items = @[[self favorite:@"I3b test favorite" group:@"Tests"]];
        [core.shared registerAPIApi:api];
        XCTestExpectation *done = [self expectationWithDescription:@"full search"];
        __block BOOL found = NO;
        OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *value) {
            if ((*value).objectType == EOAObjectTypeFavorite)
            {
                found = YES;
                XCTAssertTrue((bool)(*value).favorite);
            }
            if ((*value).objectType == EOAObjectTypeSearchFinished)
                [done fulfill];
            return YES;
        } cancelledFunc:^BOOL { return NO; }];
        [core search:@"I3b test favorite" delayedExecution:NO matcher:matcher];
        [self waitForExpectations:@[done] timeout:20];
        XCTAssertTrue(found, @"spatial=%@", spatial);
        [core cancelSearch:NO];
        XCTestExpectation *idle = [self expectationWithDescription:@"search queue idle"];
        [core.shared runAfterSearchTask:^{ [idle fulfill]; }];
        [self waitForExpectations:@[idle] timeout:10];
    }
}

- (void)testFavoriteSearchBenchmark
{
    OATestSharedFavoritesAPI *api = [[OATestSharedFavoritesAPI alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    for (int i = 0; i < 1000; i++)
        [items addObject:[self favorite:[NSString stringWithFormat:@"Park %d", i] group:@"Walks"]];
    api.items = items;
    NSMutableArray<NSNumber *> *times = [NSMutableArray array];
    for (int run = 0; run < 8; run++)
    {
        CFTimeInterval start = CACurrentMediaTime();
        NSArray *results = [self search:api text:@"park"];
        double ms = (CACurrentMediaTime() - start) * 1000;
        XCTAssertEqual(results.count, 1000u);
        if (run > 0)
            [times addObject:@(ms)];
    }
    [times sortUsingSelector:@selector(compare:)];
    printf("OASharedSearchAppAPIsTest: 1000 favorites, 7 warm runs, median %.3f ms\n", times[3].doubleValue);
}

- (void)testGpxSearchBenchmarks
{
    OATestSharedGpxAPI *tracks = [[OATestSharedGpxAPI alloc] init];
    OATestSharedWptAPI *waypoints = [[OATestSharedWptAPI alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    for (int i = 0; i < 1000; i++)
    {
        NSString *name = i == 999 ? @"Target" : [NSString stringWithFormat:@"Walk %d", i];
        [items addObject:[self track:[name stringByAppendingString:@".gpx"]]];
        [file addPointPoint:[self waypoint:name]];
    }
    tracks.items = items;
    waypoints.files = @[file];
    waypoints.paths = @[@"test.gpx"];
    for (OASharedSearchAppAPI *api in @[tracks, waypoints])
    {
        NSMutableArray<NSNumber *> *times = [NSMutableArray array];
        for (int run = 0; run < 8; run++)
        {
            CFTimeInterval start = CACurrentMediaTime();
            NSArray *results = [self search:api text:@"Target"];
            double ms = (CACurrentMediaTime() - start) * 1000;
            XCTAssertEqual(results.count, 1u);
            if (run > 0)
                [times addObject:@(ms)];
        }
        [times sortUsingSelector:@selector(compare:)];
        printf("OASharedSearchAppAPIsTest: 1000 %s, last item matches, 7 warm runs, median %.3f ms\n",
               api == tracks ? "tracks" : "waypoints", times[3].doubleValue);
    }
}

@end
