//
//  OASearchCitiesTest.mm
//  OsmAnd MapsTests
//
//  The cities the download screen finds by name in the world basemap installed in the app.
//

#import <XCTest/XCTest.h>
#import "OAQuickSearchHelper.h"
#import "OASearchResult.h"
#import "OAObfFileList.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASharedSearchUICore.h"
#import "OASearchSettings.h"
#import "OAManageResourcesViewController.h"
#import "OAResourcesUIHelper.h"
#import "OAWorldRegion.h"

#import <CoreLocation/CoreLocation.h>

@interface OAQuickSearchHelper (CitySearchTests)
- (id<OASAmenityIndexRepository>)citySearchRepository;
- (OASSearchRequest<OASAmenity *> *)citySearchRequest:(NSString *)text
                                       allowedTypes:(NSArray<NSString *> *)allowedTypes
                                          cityLimit:(NSInteger)cityLimit
                                        isCancelled:(BOOL (^)(void))isCancelled
                                             cities:(NSMutableArray<OASearchResult *> *)cities;
- (NSMutableArray<OASearchResult *> *)searchCities:(NSString *)text
                                      allowedTypes:(NSArray<NSString *> *)allowedTypes
                                         cityLimit:(NSInteger)cityLimit
                                       isCancelled:(BOOL (^)(void))isCancelled;
@end

// Hold synchronous work in progress while the public async API is cancelled.
@interface OABlockedCitySearchHelper : OAQuickSearchHelper
@property (nonatomic, strong) XCTestExpectation *started;
@property (nonatomic, strong) dispatch_semaphore_t resumeSearch;
@property (nonatomic) BOOL resumed;
@property (nonatomic) BOOL sawCancellation;
@end

@implementation OABlockedCitySearchHelper
- (NSMutableArray<OASearchResult *> *)searchCities:(NSString *)text
                                      allowedTypes:(NSArray<NSString *> *)allowedTypes
                                         cityLimit:(NSInteger)cityLimit
                                       isCancelled:(BOOL (^)(void))isCancelled
{
    [self.started fulfill];
    self.resumed = dispatch_semaphore_wait(self.resumeSearch, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC)) == 0;
    self.sawCancellation = isCancelled();
    return [NSMutableArray arrayWithObject:[[OASearchResult alloc] initWithPhrase:nil]];
}
@end

@interface OAManageResourcesViewController (CitySearchTests)
- (NSArray *)citySearchRows:(NSArray<OASearchResult *> *)cities excludingRows:(NSArray *)matchedRows;
- (NSArray *)createSearchResult:(NSArray<OAWorldRegion *> *)regions byMapRegion:(BOOL)byMapRegion;
@end

// The region lookup, row construction, deduplication and sorting remain production code.
// Only the available downloads are fixed, independent of the user's map catalogue.
@interface OACityResourcesTestController : OAManageResourcesViewController
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *rowsByRegionId;
@end

@implementation OACityResourcesTestController
- (NSArray *)createSearchResult:(NSArray<OAWorldRegion *> *)regions byMapRegion:(BOOL)byMapRegion
{
    NSMutableArray *rows = [NSMutableArray array];
    for (OAWorldRegion *region in regions)
        [rows addObjectsFromArray:self.rowsByRegionId[region.regionId] ?: @[]];
    return rows;
}
@end

@interface OASearchCitiesTest : XCTestCase

@end

// the copy of the world mini basemap installed for the tests of this class
static NSString *installedBasemap;

@implementation OASearchCitiesTest
{
    BOOL _languageSet;
    NSString *_language;
    BOOL _transliterate;
}

- (NSArray<OASearchResult *> *)citiesNamed:(NSString *)text
{
    XCTestExpectation *searched = [self expectationWithDescription:text];
    __block NSArray<OASearchResult *> *cities = nil;
    NSDate *start = [NSDate date];
    [OAQuickSearchHelper.instance searchCitiesAsync:text allowedTypes:@[@"city", @"town"] cityLimit:10000 onComplete:^(NSMutableArray *found) {
        XCTAssertTrue(NSThread.isMainThread);
        cities = found;
        [searched fulfill];
    }];
    [self waitForExpectations:@[searched] timeout:60];
    NSLog(@"OASearchCitiesTest: '%@' %lu cities in %.0f ms", text, (unsigned long) cities.count, [[NSDate date] timeIntervalSinceDate:start] * 1000);
    return cities ?: @[];
}

- (void)setUp
{
    [super setUp];
    // The app loads its maps on a background queue after launch.
    XCTNSPredicateExpectation *initialized = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"initialized == YES"] object:OsmAndApp.instance];
    [self waitForExpectations:@[initialized] timeout:120];
    // kWorldBasemapKey and kWorldMiniBasemapKey are in the prefix header of the app, not of the tests
    if (!installedBasemap && [OAObfFileList pathsByResourceIdFor:@[@"world_basemap.obf", @"worldminibasemap.obf"]].count == 0)
    {
        // under the tests the app leaves out the world mini basemap it ships, so a copy of it is installed
        NSString *shipped = [NSBundle.mainBundle pathForResource:@"WorldMiniBasemap" ofType:@"obf" inDirectory:@"Shipped"];
        XCTSkipIf(!shipped, @"the app has no world basemap");
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]);
        NSString *copy = [directory stringByAppendingPathComponent:shipped.lastPathComponent];
        XCTAssertTrue([NSFileManager.defaultManager copyItemAtPath:shipped toPath:copy error:nil]);
        XCTAssertTrue([OsmAndApp.instance installTestResource:copy]);
        installedBasemap = copy;
    }

    [OASharedObfResources.shared refreshFiles];

    // Compare the original map names regardless of the application's language.
    OAAppSettings *settings = OAAppSettings.sharedManager;
    _language = [settings.settingPrefMapLanguage get];
    _transliterate = [settings.settingMapLanguageTranslit get];
    _languageSet = YES;
    [settings.settingPrefMapLanguage set:@""];
    [settings.settingMapLanguageTranslit set:NO];
}

- (void)tearDown
{
    [OAQuickSearchHelper.instance cancelSearchCities];
    if (_languageSet)
    {
        OAAppSettings *settings = OAAppSettings.sharedManager;
        [settings.settingPrefMapLanguage set:_language];
        [settings.settingMapLanguageTranslit set:_transliterate];
    }
    [super tearDown];
}

+ (void)tearDown
{
    if (installedBasemap)
    {
        // a class method cannot fail a test, so a copy left among the maps of the app goes to the log
        if (![OsmAndApp.instance removeTestResource:installedBasemap])
            NSLog(@"OASearchCitiesTest: %@ is left among the maps of the app", installedBasemap);
        [NSFileManager.defaultManager removeItemAtPath:installedBasemap.stringByDeletingLastPathComponent error:nil];
        installedBasemap = nil;
        [OASharedObfResources.shared refreshFiles];
    }
    [super tearDown];
}

- (void)testACityIsFoundByItsName
{
    CLLocation *rostock = [[CLLocation alloc] initWithLatitude:54.09 longitude:12.13];
    BOOL found = NO;
    for (OASearchResult *city in [self citiesNamed:@"Rostock"])
    {
        XCTAssertNotNil(city.location);
        if ([city.localeName isEqualToString:@"Rostock"] && [city.location distanceFromLocation:rostock] < 20000)
            found = YES;
    }
    XCTAssertTrue(found);
}

// a text of several words: the name index is read for all of them, the name matched against the first one
- (void)testACityOfSeveralWordsIsFoundByItsName
{
    NSArray<OASearchResult *> *cities = [self citiesNamed:@"Frankfurt am Main"];
    BOOL found = NO;
    for (OASearchResult *city in cities)
    {
        XCTAssertTrue([city.localeName containsString:@"Frankfurt"], @"%@", city.localeName);
        found = found || [city.localeName isEqualToString:@"Frankfurt am Main"];
    }
    XCTAssertTrue(found);
}

- (void)testCitySearchWorksWithEitherMainEngine
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    BOOL useShared = [settings.useSharedSearch get];
    @try
    {
        for (NSNumber *enabled in @[@NO, @YES])
        {
            [settings.useSharedSearch set:enabled.boolValue];
            OAQuickSearchHelper *helper = [[OAQuickSearchHelper alloc] init];
            XCTAssertEqual([[helper getCore] isKindOfClass:OASharedSearchUICore.class], enabled.boolValue);
            XCTestExpectation *searched = [self expectationWithDescription:enabled.stringValue];
            [helper searchCitiesAsync:@"Rostock" allowedTypes:@[@"city"] cityLimit:10000 onComplete:^(NSMutableArray *found) {
                XCTAssertTrue(NSThread.isMainThread);
                XCTAssertGreaterThan(found.count, 0);
                for (OASearchResult *city in found)
                    XCTAssertEqualObjects([(OASAmenity *)city.object getSubType], @"city");
                [searched fulfill];
            }];
            [self waitForExpectations:@[searched] timeout:60];
        }
    }
    @finally
    {
        [settings.useSharedSearch set:useShared];
    }
}

- (void)testOnlyLatestRequestPublishesResults
{
    OAQuickSearchHelper *helper = OAQuickSearchHelper.instance;
    XCTestExpectation *obsolete = [self expectationWithDescription:@"obsolete request"];
    obsolete.inverted = YES;
    XCTestExpectation *latest = [self expectationWithDescription:@"latest request"];
    [helper searchCitiesAsync:@"Rostock" allowedTypes:@[@"city", @"town"] cityLimit:10000 onComplete:^(NSMutableArray *found) {
        [obsolete fulfill];
    }];
    [helper searchCitiesAsync:@"Frankfurt am Main" allowedTypes:@[@"city", @"town"] cityLimit:10000 onComplete:^(NSMutableArray *found) {
        XCTAssertGreaterThan(found.count, 0);
        [latest fulfill];
    }];
    [self waitForExpectations:@[latest] timeout:60];
    [self waitForExpectations:@[obsolete] timeout:0.2];
}

- (void)testCancelledRequestDoesNotPublishResults
{
    OABlockedCitySearchHelper *helper = [[OABlockedCitySearchHelper alloc] init];
    helper.started = [self expectationWithDescription:@"search started"];
    helper.resumeSearch = dispatch_semaphore_create(0);
    __block BOOL published = NO;
    [helper searchCitiesAsync:@"Rostock" allowedTypes:@[@"city", @"town"] cityLimit:10000 onComplete:^(NSMutableArray *found) {
        published = YES;
    }];
    [self waitForExpectations:@[helper.started] timeout:10];
    [helper cancelSearchCities];
    dispatch_semaphore_signal(helper.resumeSearch);

    // A queue fence observes the callback decision without invalidating the request again.
    XCTestExpectation *drained = [self expectationWithDescription:@"search and main callback drained"];
    dispatch_queue_t queue = [helper valueForKey:@"searchCitiesQueue"];
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    });
    [self waitForExpectations:@[drained] timeout:10];
    XCTAssertTrue(helper.resumed);
    XCTAssertTrue(helper.sawCancellation);
    XCTAssertFalse(published);
}

- (OASAmenity *)amenityNamed:(NSString *)name subtype:(NSString *)subtype latitude:(double)latitude longitude:(double)longitude
{
    OASAmenity *amenity = [[OASAmenity alloc] init];
    [amenity setNameName:name];
    [amenity setSubTypeSubType:subtype];
    [amenity setLocationLatitude:latitude longitude:longitude];
    return amenity;
}

- (NSArray<OASearchResult *> *)matchAmenities:(NSArray<OASAmenity *> *)amenities text:(NSString *)text helper:(OAQuickSearchHelper *)helper
{
    NSMutableArray *cities = [NSMutableArray array];
    OASSearchRequest *request = [helper citySearchRequest:text allowedTypes:@[@"city", @"town"] cityLimit:10000 isCancelled:nil cities:cities];
    XCTAssertEqualObjects(request.nameQuery, text, @"The index must receive the full query.");
    for (OASAmenity *amenity in amenities)
        [request publishObj:amenity];
    return cities;
}

- (void)testLocalizedNameIsDisplayed
{
    OASAmenity *munich = [self amenityNamed:@"München" subtype:@"city" latitude:48.137 longitude:11.575];
    [munich setNameLang:@"en" name:@"Munich"];
    OASAmenity *unrelated = [self amenityNamed:@"Berlin" subtype:@"city" latitude:52.52 longitude:13.405];
    [OAAppSettings.sharedManager.settingPrefMapLanguage set:@"en"];
    NSArray<OASearchResult *> *cities = [self matchAmenities:@[munich, unrelated] text:@"Munich" helper:OAQuickSearchHelper.instance];
    XCTAssertEqual(cities.count, 1u);
    XCTAssertEqual(cities.firstObject.object, munich);
    XCTAssertEqualObjects(cities.firstObject.localeName, @"Munich");
}

- (void)testAlternativeNameMatchesWhileTheRowKeepsItsPreferredName
{
    OASAmenity *munich = [self amenityNamed:@"München" subtype:@"city" latitude:48.137 longitude:11.575];
    [munich setNameLang:@"en" name:@"Munich"];
    [munich setNameLang:@"la" name:@"Monachium"];
    OASAmenity *unrelated = [self amenityNamed:@"Berlin" subtype:@"city" latitude:52.52 longitude:13.405];
    for (NSString *query in @[@"Munich", @"Monachium"])
    {
        NSArray<OASearchResult *> *cities = [self matchAmenities:@[munich, unrelated] text:query helper:OAQuickSearchHelper.instance];
        XCTAssertEqual(cities.count, 1u, @"%@", query);
        XCTAssertEqual(cities.firstObject.object, munich);
        XCTAssertEqualObjects(cities.firstObject.localeName, @"München");
    }
}

- (void)testTransliterationWhenThePreferredTranslationIsMissing
{
    OASAmenity *moscow = [self amenityNamed:@"Москва" subtype:@"city" latitude:55.75 longitude:37.62];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    [settings.settingPrefMapLanguage set:@"en"];
    for (NSNumber *transliterate in @[@NO, @YES])
    {
        [settings.settingMapLanguageTranslit set:transliterate.boolValue];
        NSArray<OASearchResult *> *cities = [self matchAmenities:@[moscow] text:@"Moskva" helper:OAQuickSearchHelper.instance];
        XCTAssertEqual(cities.count, 1u);
        XCTAssertEqualObjects(cities.firstObject.localeName, transliterate.boolValue ? @"Moskva" : @"Москва");
    }
}

- (void)testAbbreviationsFollowTheSearchOrigin
{
    OAQuickSearchHelper *helper = [[OAQuickSearchHelper alloc] init];
    OASAmenity *expanded = [self amenityNamed:@"Southwest Harbor" subtype:@"town" latitude:44.28 longitude:-68.33];
    OASAmenity *literal = [self amenityNamed:@"Sw Harbor" subtype:@"town" latitude:44.28 longitude:-68.33];
    NSArray<CLLocation *> *origins = @[
        [[CLLocation alloc] initWithLatitude:51.5074 longitude:-0.1278],
        [[CLLocation alloc] initWithLatitude:52.52 longitude:13.405]
    ];
    NSArray *expected = @[expanded, literal];
    for (NSUInteger i = 0; i < origins.count; i++)
    {
        OASearchUICore *core = [helper getCore];
        [core updateSettings:[[core getSearchSettings] setOriginalLocation:origins[i]]];
        NSArray<OASearchResult *> *cities = [self matchAmenities:@[expanded, literal] text:@"sw harbor" helper:helper];
        XCTAssertEqual(cities.count, 1u, @"origin %@", origins[i]);
        XCTAssertEqual(cities.firstObject.object, expected[i]);
    }
}

- (void)testCancellationStopsAnExistingMatcher
{
    NSMutableArray *cities = [NSMutableArray array];
    __block BOOL cancelled = NO;
    OASSearchRequest *request = [OAQuickSearchHelper.instance citySearchRequest:@"Rostock" allowedTypes:@[@"city", @"town"] cityLimit:10000 isCancelled:^BOOL{
        return cancelled;
    } cities:cities];
    OASAmenity *first = [self amenityNamed:@"Rostock" subtype:@"city" latitude:54.09 longitude:12.13];
    [request publishObj:first];
    XCTAssertEqual(cities.count, 1u);
    XCTAssertFalse([request isCancelled]);
    cancelled = YES;
    XCTAssertTrue([request isCancelled]);
    [request publishObj:[self amenityNamed:@"Rostock" subtype:@"town" latitude:54.1 longitude:12.1]];
    XCTAssertEqual(cities.count, 1u, @"An in-flight reader must not publish another city after cancellation.");
}

- (void)testFullBasemapTakesPriorityAndRemovalRestoresMini
{
    NSDictionary *paths = [OAObfFileList pathsByResourceIdFor:@[@"world_basemap.obf", @"worldminibasemap.obf"]];
    XCTSkipIf(paths[@"world_basemap.obf"] != nil, @"Preserve an existing downloaded world basemap.");
    NSString *miniPath = paths[@"worldminibasemap.obf"];
    XCTAssertNotNil(miniPath);
    if (!miniPath)
        return;

    OAQuickSearchHelper *helper = OAQuickSearchHelper.instance;
    id<OASAmenityIndexRepository> mini = [helper citySearchRepository];
    XCTAssertEqualObjects([[mini getFile] path], miniPath);
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSString *fullPath = [directory stringByAppendingPathComponent:@"World_basemap.obf"];
    BOOL installed = NO;
    @try
    {
        XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]);
        // Use a valid OBF under the full-basemap resource ID, without downloading or replacing user maps.
        XCTAssertTrue([NSFileManager.defaultManager copyItemAtPath:miniPath toPath:fullPath error:nil]);
        installed = [OsmAndApp.instance installTestResource:fullPath];
        XCTAssertTrue(installed);
        [OASharedObfResources.shared refreshFiles];
        id<OASAmenityIndexRepository> full = [helper citySearchRepository];
        XCTAssertNotEqual(full, mini);
        XCTAssertEqualObjects([[full getFile] path], fullPath);
        XCTAssertEqual([helper citySearchRepository], full, @"Repeated queries reuse the selected repository.");
        XCTAssertGreaterThan([self citiesNamed:@"Rostock"].count, 0);
        if (installed)
        {
            BOOL removed = [OsmAndApp.instance removeTestResource:fullPath];
            XCTAssertTrue(removed);
            if (removed)
                installed = NO;
        }
        [OASharedObfResources.shared refreshFiles];
        XCTAssertEqual([helper citySearchRepository], mini);
        XCTAssertEqualObjects([OAObfFileList pathsByResourceIdFor:@[@"worldminibasemap.obf"]][@"worldminibasemap.obf"], miniPath);
        XCTAssertGreaterThan([self citiesNamed:@"Rostock"].count, 0);
    }
    @finally
    {
        if (installed)
            XCTAssertTrue([OsmAndApp.instance removeTestResource:fullPath]);
        [OASharedObfResources.shared refreshFiles];
        [NSFileManager.defaultManager removeItemAtPath:directory error:nil];
    }
}

- (OARepositoryResourceItem *)mapWithId:(NSString *)resourceId title:(NSString *)title
{
    OARepositoryResourceItem *map = [[OARepositoryResourceItem alloc] init];
    map.resourceId = QString::fromNSString(resourceId);
    map.title = title;
    return map;
}

- (OASearchResult *)cityRow:(NSString *)name subtype:(NSString *)subtype latitude:(double)latitude longitude:(double)longitude
{
    OASearchResult *city = [[OASearchResult alloc] initWithPhrase:nil];
    city.localeName = name;
    city.object = [self amenityNamed:name subtype:subtype latitude:latitude longitude:longitude];
    city.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    return city;
}

- (void)testMixedCityAndTownRowsAreDeduplicatedAndSorted
{
    OACityResourcesTestController *controller = [[OACityResourcesTestController alloc] init];
    [controller setValue:OsmAndApp.instance forKey:@"app"];
    OASearchResult *town = [self cityRow:@"Alpha Town" subtype:@"town" latitude:48.137 longitude:11.575];
    OASearchResult *city = [self cityRow:@"Zulu City" subtype:@"city" latitude:52.52 longitude:13.405];
    OASearchResult *duplicateMap = [self cityRow:@"Duplicate Town" subtype:@"town" latitude:53.55 longitude:10.0];
    OASearchResult *betaZulu = [self cityRow:@"Beta City" subtype:@"city" latitude:48.8566 longitude:2.3522];
    OASearchResult *betaAlpha = [self cityRow:@"Beta City" subtype:@"city" latitude:51.5074 longitude:-0.1278];
    OASearchResult *alreadyListed = [self cityRow:@"Already Listed" subtype:@"city" latitude:41.9028 longitude:12.4964];
    OASearchResult *regionCity = [self cityRow:@"Region City" subtype:@"city" latitude:40.4168 longitude:-3.7038];
    OASearchResult *duplicateRegion = [self cityRow:@"Region Town" subtype:@"town" latitude:41.3874 longitude:2.1686];
    NSArray *cities = @[town, city, duplicateMap, betaZulu, betaAlpha, alreadyListed, regionCity, duplicateRegion];
    OARepositoryResourceItem *shownMap = [self mapWithId:@"shown.obf" title:@"Already listed map"];
    OAWorldRegion *region = [[OAWorldRegion alloc] initWithId:@"test-region" andLocalizedName:@"Epsilon Region"];
    NSArray *destinations = @[
        [self mapWithId:@"town.obf" title:@"Town map"],
        [self mapWithId:@"city.obf" title:@"City map"],
        [self mapWithId:@"city.obf" title:@"Another object for the same map"],
        [self mapWithId:@"beta-z.obf" title:@"Zulu map"],
        [self mapWithId:@"beta-a.obf" title:@"Alpha map"],
        [self mapWithId:@"shown.obf" title:@"Another object for the listed map"],
        region,
        [[OAWorldRegion alloc] initWithId:@"test-region" andLocalizedName:@"Another object for the same region"]
    ];
    NSMutableDictionary *downloads = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < cities.count; i++)
    {
        CLLocation *location = ((OASearchResult *)cities[i]).location;
        OAWorldRegion *covering = [OsmAndApp.instance.worldRegion findAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
        XCTAssertNotNil(covering);
        if (!covering)
            return;
        XCTAssertNil(downloads[covering.regionId], @"Fixture locations must belong to distinct regions.");
        downloads[covering.regionId] = @[destinations[i]];
    }
    controller.rowsByRegionId = downloads;
    NSArray *rows = [controller citySearchRows:cities excludingRows:@[shownMap]];
    XCTAssertEqualObjects(rows, (@[betaAlpha, betaZulu, city, town, region]));
    XCTAssertEqual(betaAlpha.relatedObject, destinations[4]);
    XCTAssertEqual(city.relatedObject, destinations[1]);

    OAWorldRegion *shownRegion = [[OAWorldRegion alloc] initWithId:@"test-region" andLocalizedName:@"Already listed region"];
    NSArray *withoutListedRegion = [controller citySearchRows:cities excludingRows:@[shownMap, shownRegion]];
    XCTAssertEqualObjects(withoutListedRegion, (@[betaAlpha, betaZulu, city, town]));
}

- (void)testWorldBasemapRepositoryBenchmark
{
    id<OASAmenityIndexRepository> repository = [OASharedObfResources.shared amenityRepositoryForResourceId:@"world_basemap.obf"];
    if (!repository || ![[repository getFile] exists])
        repository = [OASharedObfResources.shared amenityRepositoryForResourceId:@"worldminibasemap.obf"];
    XCTAssertNotNil(repository);
    if (!repository)
        return;
    NSString *path = [[repository getFile] path];
    NSMutableArray<NSNumber *> *freshTimes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *reuseTimes = [NSMutableArray array];
    for (NSInteger round = 0; round < 8; round++)
    {
        NSMutableArray<NSNumber *> *counts = [NSMutableArray array];
        for (NSInteger phase = 0; phase < 2; phase++)
        {
            BOOL reuse = (round + phase) % 2 == 0;
            OASSearchRequest *request = [OASSearchRequest.companion buildSearchPoiRequestX:0 y:0 nameFilter:@"Rostock"
                sleft:INT_MIN sright:INT_MAX stop:INT_MIN sbottom:INT_MAX poiTypeFilter:nil resultMatcher:nil rawDataCollector:nil];
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            NSArray *found;
            if (reuse)
                found = [repository searchPoiByNameSearchRequest:request];
            else
            {
                OASBinaryMapIndexReader *reader = [[OASBinaryMapIndexReader alloc] initWithFilePath:path];
                found = [reader searchPoiByNameReq:request];
                [reader close];
            }
            double milliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000;
            [counts addObject:@(found.count)];
            if (round > 0)
                [(reuse ? reuseTimes : freshTimes) addObject:@(milliseconds)];
        }
        XCTAssertEqualObjects(counts.firstObject, counts.lastObject);
        XCTAssertGreaterThan(counts.firstObject.integerValue, 0);
    }
    [freshTimes sortUsingSelector:@selector(compare:)];
    [reuseTimes sortUsingSelector:@selector(compare:)];
    NSString *summary = [NSString stringWithFormat:@"World basemap name search: fresh reader %.3f ms; persistent repository %.3f ms; median of 7 rounds after warm-up; %@",
        freshTimes[3].doubleValue, reuseTimes[3].doubleValue, path.lastPathComponent];
    printf("%s\n", summary.UTF8String);
    XCTAttachment *attachment = [XCTAttachment attachmentWithString:summary];
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end
