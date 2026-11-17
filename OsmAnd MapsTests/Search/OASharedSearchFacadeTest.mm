//
//  OASharedSearchFacadeTest.mm
//  OsmAnd MapsTests
//
//  What the search of the app hands the shared search and gets back: the kinds of results, the objects
//  of the results the search screens make, the settings, and the results themselves.
//

#import <XCTest/XCTest.h>
#import "OASharedSearchUICore.h"
#import "OASharedSearchObjects.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OAPOIHelper.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAPOI.h"
#import "OASearchCoreFactory.h"
#import "OASearchCoreAPI.h"
#import "QuadRect.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAObfFileList.h"

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/ArchiveReader.h>

@interface OAFailingShallowSearchTestAPI : OASearchCoreAPI
@end

@implementation OAFailingShallowSearchTestAPI
- (BOOL)search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    [NSException raise:@"TestSearchFailure" format:@"Deliberate shallow search failure"];
    return NO;
}
@end

@interface OASharedSearchFacadeTest : XCTestCase

@end

@implementation OASharedSearchFacadeTest

- (NSArray<OASearchResult *> *)search:(Class)api text:(NSString *)text core:(OASharedSearchUICore *)core
{
    XCTestExpectation *finished = [self expectationWithDescription:@"shallow search finished"];
    __block NSArray<OASearchResult *> *results;
    [core shallowSearchAsync:api text:text matcher:nil completion:^(OASearchResultCollection *collection) {
        results = collection.getCurrentSearchResults;
        [finished fulfill];
    }];
    [self waitForExpectations:@[finished] timeout:60];
    return results;
}

// a map of the search tests, unpacked and installed; its resource id is its file name in lower case
- (NSString *)installTestMap:(NSString *)name
{
    NSString *gz = [[NSBundle bundleForClass:self.class].bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"test-resources/search/%@.obf.gz", name]];
    NSString *obf = [NSTemporaryDirectory() stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"obf"]];
    OsmAnd::ArchiveReader archive(QString::fromNSString(gz));
    bool ok = false;
    const auto items = archive.getItems(&ok, true);
    XCTAssertTrue(ok && items.size() > 0 && archive.extractItemToFile(items.first().name, QString::fromNSString(obf), true));
    XCTAssertTrue([OsmAndApp.instance installTestResource:obf]);
    [OASharedObfResources.shared refreshFiles];
    return obf;
}

- (void)testEveryKindOfResultOfTheAppHasTheSameOneInTheSharedSearch
{
    for (NSInteger i = EOAObjectTypeCity; i <= EOAObjectTypeSuggestion; i++)
    {
        EOAObjectType type = (EOAObjectType) i;
        OASObjectType *shared = [OASharedSearchObjects sharedObjectType:type];
        XCTAssertNotNil(shared, @"%ld", (long) type);
        XCTAssertEqual([OASharedSearchObjects appObjectType:shared], type, @"%ld %@", (long) type, shared.name);
    }
    XCTAssertEqual([OASharedSearchObjects appObjectType:nil], EOAObjectTypeUndefined);
    for (OASObjectType *shared in @[OASObjectType.route, OASObjectType.mapMarker, OASObjectType.onlineSearch])
        XCTAssertEqual([OASharedSearchObjects appObjectType:shared], EOAObjectTypeUndefined, @"%@ has no kind of the app: not a city", shared.name);
}

- (void)testThePoiTypesOfTheAppGoToTheSharedSearchAndBack
{
    OAPOIHelper *helper = OAPOIHelper.sharedInstance;
    for (OAPOIBaseType *type in @[[helper getPoiCategoryByName:@"shop"], [helper getPoiTypeByKey:@"cafe"]])
    {
        OASAbstractPoiType *shared = [OASharedSearchObjects sharedObjectFor:type];
        XCTAssertEqualObjects([shared getKeyName], type.name);
        XCTAssertEqual([OASharedSearchObjects appObjectFor:shared], type);
    }
}

- (void)testAFilterOfTheAppIsTheSameOneForTheSharedSearch
{
    OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getShowAllPOIFilter];
    XCTAssertNotNil(filter);
    id<OASCustomSearchPoiFilter> shared = [OASharedSearchObjects sharedObjectFor:filter];
    XCTAssertEqual(shared, [OASharedSearchObjects sharedPoiFilterFor:filter], @"one shared filter for one filter");
    XCTAssertEqualObjects([shared getFilterId], filter.filterId);
    XCTAssertEqual([OASharedSearchObjects appObjectFor:shared], filter);
}

- (void)testTheTypesOfAFilterOfTheAppGoToTheSharedSearch
{
    OAPOIHelper *helper = OAPOIHelper.sharedInstance;
    OAPOIType *cafe = [helper getPoiTypeByKey:@"cafe"];
    OAPOICategory *shop = [helper getPoiCategoryByName:@"shop"];
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [NSMapTable strongToStrongObjectsMapTable];
    [types setObject:[NSMutableSet setWithObject:@"cafe"] forKey:cafe.category];
    [types setObject:[OAPOIBaseType nullSet] forKey:shop];
    OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:@"cafes and shops" filterId:nil acceptedTypes:types];

    NSDictionary<OASPoiCategory *, id> *accepted = [[OASharedSearchObjects sharedPoiFilterFor:filter] getAcceptedTypes];
    XCTAssertEqual(accepted.count, 2u);
    id subtypes = accepted[[helper.kPoiTypes getPoiCategoryByNameName:cafe.category.name]];
    XCTAssertTrue([subtypes isKindOfClass:OASMutableSet.class], @"a set of Kotlin's own, as the shared search takes it");
    XCTAssertEqualObjects([NSSet setWithArray:[subtypes allObjects]], [NSSet setWithObject:@"cafe"]);
    XCTAssertEqual(accepted[[helper.kPoiTypes getPoiCategoryByNameName:@"shop"]], NSNull.null, @"the whole category");
}

- (void)testAPointGoesToTheSharedSearchAndBack
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:52.52 longitude:13.405];
    OASKLatLon *shared = [OASharedSearchObjects sharedObjectFor:location];
    XCTAssertEqual(shared.latitude, 52.52);
    XCTAssertEqual(shared.longitude, 13.405);
    CLLocation *back = [OASharedSearchObjects appObjectFor:shared];
    XCTAssertEqual(back.coordinate.latitude, 52.52);
}

- (void)testTheSettersOfSettingsMakeCopies
{
    OASharedSearchSettings *settings = [[OASharedSearchSettings alloc] initWithShared:[[OASSearchSettings alloc] initWithS:nil]];
    CLLocation *berlin = [[CLLocation alloc] initWithLatitude:52.52 longitude:13.405];
    OASearchSettings *changed = [[[[[[settings setOriginalLocation:berlin] setLang:@"de" transliterateIfMissing:YES] setRadiusLevel:3]
        setSearchTypes:@[[OAObjectType withType:EOAObjectTypeCity], [OAObjectType withType:EOAObjectTypePoi]]]
        setSortByName:YES] setSearchBBox31:[[QuadRect alloc] initWithLeft:1 top:2 right:3 bottom:4]];

    XCTAssertTrue([changed isKindOfClass:OASharedSearchSettings.class]);
    XCTAssertNil([settings getOriginalLocation], @"the setters leave the settings they are called on");
    XCTAssertEqual([changed getOriginalLocation].coordinate.latitude, 52.52);
    XCTAssertEqualObjects([changed getLang], @"de");
    XCTAssertTrue([changed isTransliterate]);
    XCTAssertEqual([changed getRadiusLevel], 3);
    XCTAssertEqual([changed getSearchTypes].count, 2u);
    XCTAssertEqual([changed getSearchTypes][1].type, EOAObjectTypePoi);
    XCTAssertTrue([changed isSortByName]);
    XCTAssertEqual([changed getSearchBBox31].right, 3);

    OASearchSettings *copy = [[OASearchSettings alloc] initWithSettings:changed];
    XCTAssertTrue([copy isKindOfClass:OASharedSearchSettings.class], @"a copy of shared settings is one too");
    XCTAssertEqualObjects([copy getLang], @"de");
    XCTAssertEqual([[copy setOriginalLocation:nil] getOriginalLocation].coordinate.latitude, 52.52, @"the shared settings keep a location");
}

- (void)testAResultTheAppMakesGoesToTheSharedSearchAndBack
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    OASearchPhrase *phrase = [core resetPhrase];
    XCTAssertTrue([phrase isKindOfClass:OASharedSearchPhrase.class]);

    OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getShowAllPOIFilter];
    OASearchResult *result = [[OASearchResult alloc] initWithPhrase:phrase];
    result.localeName = [filter getName];
    result.object = filter;
    result.objectType = EOAObjectTypePoiType;
    result.priority = 5;

    OASSearchResult *shared = [result toSharedResult];
    XCTAssertEqual([result toSharedResult], shared, @"made once");
    XCTAssertEqual(shared.objectType, OASObjectType.poiType);
    XCTAssertEqual(shared.requiredSearchPhrase, ((OASharedSearchPhrase *) phrase).shared);

    OASearchResult *back = [OASearchResult resultOfShared:shared phrase:phrase];
    XCTAssertEqual(back.object, filter);
    XCTAssertEqual(back.objectType, EOAObjectTypePoiType);
    XCTAssertEqualObjects(back.localeName, [filter getName]);
    XCTAssertEqual(back.priority, 5);

    XCTAssertTrue([core selectSearchResult:result]);
    OASearchWord *word = [[core getPhrase] getLastSelectedWord];
    XCTAssertEqual(word.result.object, filter, @"the screens find the filter they picked in the phrase");
    XCTAssertTrue([[core getPhrase] isLastWord:EOAObjectTypePoiType]);
}

- (void)testACollectionOfResultsOfTheSharedSearchIsOneToo
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OASearchPhrase *phrase = [core resetPhrase];
    OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
    XCTAssertTrue([collection isKindOfClass:OASharedSearchResultCollection.class]);

    OASearchResult *result = [[OASearchResult alloc] initWithPhrase:phrase];
    result.localeName = @"Berlin";
    result.objectType = EOAObjectTypeLocation;
    result.location = [[CLLocation alloc] initWithLatitude:52.52 longitude:13.405];
    [collection addSearchResults:@[result] resortAll:YES removeDuplicates:YES];
    XCTAssertEqual([collection getCurrentSearchResults].firstObject, result, @"the same result comes back");

    // the same shared result made into another of the app, as the search publishes it
    OASearchResult *again = [OASearchResult resultOfShared:result.sharedResult phrase:phrase];
    [collection addSearchResults:@[again] resortAll:NO removeDuplicates:NO];
    for (OASearchResult *r in [collection getCurrentSearchResults])
        XCTAssertEqual(r, result, @"the one handed out stays");

    // one added after the results were read is there when they are read again
    NSUInteger before = [collection getCurrentSearchResults].count;
    OASearchResult *hamburg = [[OASearchResult alloc] initWithPhrase:phrase];
    hamburg.localeName = @"Hamburg";
    hamburg.objectType = EOAObjectTypeLocation;
    hamburg.location = [[CLLocation alloc] initWithLatitude:53.55 longitude:9.99];
    [collection addSearchResults:@[hamburg] resortAll:YES removeDuplicates:YES];
    NSArray<OASearchResult *> *results = [collection getCurrentSearchResults];
    XCTAssertEqual(results.count, before + 1);
    XCTAssertTrue([results containsObject:hamburg]);
    XCTAssertTrue([results containsObject:result]);
}

- (void)testAResultOfTheSharedSearchHasWhatTheSearchChangesInItLater
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OASearchPhrase *phrase = [core resetPhrase];
    OASSearchResult *shared = [[OASSearchResult alloc] initWithSp:((OASharedSearchPhrase *) phrase).shared];
    shared.objectType = OASObjectType.location;
    shared.object = [[OASKLatLon alloc] initWithLatitude:52.52 longitude:13.405];
    shared.otherNames = [NSMutableArray arrayWithObject:@"Berlin"];
    OASearchResult *result = [OASearchResult resultOfShared:shared phrase:phrase];
    XCTAssertEqual(((CLLocation *) result.object).coordinate.latitude, 52.52);
    XCTAssertEqual(result.object, result.object, @"made once");

    // as uniting the results of one object does
    shared.object = [[OASKLatLon alloc] initWithLatitude:48.85 longitude:2.35];
    shared.otherNames = [NSMutableArray arrayWithObjects:@"Berlin", @"Paris", nil];
    XCTAssertEqual(((CLLocation *) result.object).coordinate.latitude, 48.85);
    XCTAssertEqualObjects(result.otherNames, (@[@"Berlin", @"Paris"]));
    // as the collection does once it has the results
    XCTAssertNil(result.addressName);
    shared.addressName = @"Pariser Platz 1, Berlin";
    XCTAssertEqualObjects(result.addressName, @"Pariser Platz 1, Berlin");
}

- (void)testSettingsHoldingReadersOfMapsChangedSinceGetTheMapsAgain
{
    NSString *obf = [self installTestMap:@"kiev"];
    NSString *resourceId = @"kiev.obf";

    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    OASharedSearchSettings *settings = (OASharedSearchSettings *) [core getSearchSettings];
    [settings setOfflineIndexes:@[resourceId]];
    OASBinaryMapIndexReader *before = [settings.shared getOfflineIndexes].firstObject;
    XCTAssertNotNil(before);
    // settings made of the shared ones, as those of a phrase, have no resource ids of their own
    OASharedSearchSettings *ofPhrase = [[OASharedSearchSettings alloc] initWithShared:[[OASSearchSettings alloc] initWithS:settings.shared]];
    XCTAssertEqual([[ofPhrase sharedWithCurrentReaders] getOfflineIndexes].firstObject, before, @"the readers are current");

    [OASharedObfResources.shared refreshFiles];
    XCTAssertEqual([[ofPhrase sharedWithCurrentReaders] getOfflineIndexes].firstObject, before,
                   @"refreshing unchanged files must retain their handles");
    NSString *installedPath = [[before getFile] path];
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:installedPath error:nil];
    NSDate *changedTime = [attributes[NSFileModificationDate] dateByAddingTimeInterval:5];
    XCTAssertTrue([NSFileManager.defaultManager setAttributes:@{NSFileModificationDate:changedTime} ofItemAtPath:installedPath error:nil]);
    [OASharedObfResources.shared refreshFiles];
    // made after the change, of settings made before it
    OASharedSearchSettings *madeAfter = [[OASharedSearchSettings alloc] initWithShared:[[OASSearchSettings alloc] initWithS:settings.shared]];
    OASBinaryMapIndexReader *after = [[madeAfter sharedWithCurrentReaders] getOfflineIndexes].firstObject;
    XCTAssertNotNil(after);
    XCTAssertNotEqual(after, before, @"a retired reader is not read again");
    XCTAssertEqual([[ofPhrase sharedWithCurrentReaders] getOfflineIndexes].firstObject, after);

    XCTAssertEqualObjects([OASharedObfResources.shared resourceIdsOf:@[before]], @[resourceId]);
    [NSFileManager.defaultManager removeItemAtPath:obf error:nil];
}

// the search of a filter as the car screen runs it: the filter picked, then the poi of its types
- (NSArray<OASearchResult *> *)poiOf:(OAPOIUIFilter *)filter core:(OASharedSearchUICore *)core
{
    [core resetPhrase];
    OASearchResult *result = [[OASearchResult alloc] initWithPhrase:[core getPhrase]];
    result.localeName = filter.name;
    result.object = filter;
    result.priority = SEARCH_AMENITY_TYPE_PRIORITY;
    result.priorityDistance = 0;
    result.objectType = EOAObjectTypePoiType;
    [core selectSearchResult:result];
    return [self search:OASearchAmenityByTypeAPI.class text:[[core getPhrase] getText:YES] core:core];
}

- (NSArray<NSString *> *)namesOf:(NSArray<OASearchResult *> *)results
{
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (OASearchResult *result in results)
        [names addObject:[NSString stringWithFormat:@"%@ %@", result.localeName, ((OAPOI *) result.object).type.name]];
    return names;
}

// the map has poi types in its name index: the spatial search reads the types of a filter there, and a whole
// category, which takes the types of other categories too, with the filter of types as the classic search
- (void)testTheSpatialSearchFindsThePoiOfAFilterOfTheApp
{
    NSString *searchRulesDir = [NSBundle.mainBundle pathForResource:@"abbr" ofType:nil];
    XCTAssertNotNil(searchRulesDir, @"the app has the search rules");
    NSString *name = @"geo-15km-Union-Turnpike-Queens";
    NSString *obf = [self installTestMap:name];
    NSString *json = [[NSBundle bundleForClass:self.class].bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"test-resources/search/%@.json", name]];
    NSDictionary *settingsJson = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:json] options:0 error:nil][@"settings"];
    NSString *settingsText = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:settingsJson options:0 error:nil] encoding:NSUTF8StringEncoding];
    OASharedSearchUICore *classic = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [classic initApi];
    OASharedSearchUICore *spatial = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [spatial initApiUseSpatialSearch:YES searchRulesDir:searchRulesDir ?: @""];
    for (OASharedSearchUICore *core in @[classic, spatial])
    {
        OASharedSearchSettings *settings = [OASharedSearchSettings settingsOfJSON:settingsText];
        [settings setOfflineIndexes:@[obf.lastPathComponent.lowercaseString]];
        [core updateSettings:settings];
    }

    // the type of the most poi of the map named so, that the lists to compare are not of one
    NSCountedSet<OAPOIType *> *types = [NSCountedSet set];
    for (OASearchResult *result in [self search:OASearchAmenityByNameAPI.class text:@"Union Turnpike" core:classic])
    {
        if ([result.object isKindOfClass:OAPOI.class] && ((OAPOI *) result.object).type)
            [types addObject:((OAPOI *) result.object).type];
    }
    OAPOIType *type = nil;
    for (OAPOIType *t in types)
    {
        NSUInteger count = [types countForObject:t], most = type ? [types countForObject:type] : 0;
        if (count > most || (count == most && [t.name compare:type.name] == NSOrderedAscending))
            type = t;
    }
    XCTAssertNotNil(type, @"the map has a poi");

    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *wholeCategory = [NSMapTable strongToStrongObjectsMapTable];
    [wholeCategory setObject:[OAPOIBaseType nullSet] forKey:type.category];
    OAPOIUIFilter *categoryFilter = [[OAPOIUIFilter alloc] initWithName:type.category.name filterId:nil acceptedTypes:wholeCategory];
    NSArray<NSString *> *ofCategory = [self namesOf:[self poiOf:categoryFilter core:spatial]];
    XCTAssertGreaterThan(ofCategory.count, 0u, @"%@", type.category.name);
    XCTAssertEqualObjects(ofCategory, [self namesOf:[self poiOf:categoryFilter core:classic]], @"%@", type.category.name);

    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *ofType = [NSMapTable strongToStrongObjectsMapTable];
    [ofType setObject:[NSMutableSet setWithObject:type.name] forKey:type.category];
    OAPOIUIFilter *typeFilter = [[OAPOIUIFilter alloc] initWithName:type.name filterId:nil acceptedTypes:ofType];
    NSArray<OASearchResult *> *results = [self poiOf:typeFilter core:spatial];
    XCTAssertGreaterThan(results.count, 0u, @"%@", type.name);
    for (OASearchResult *result in results)
        XCTAssertEqualObjects(((OAPOI *) result.object).type.name, type.name, @"%@", result.localeName);
    NSLog(@"OASharedSearchFacadeTest: %@ %lu poi of the category, %lu of the type %@", type.category.name, (unsigned long) ofCategory.count, (unsigned long) results.count, type.name);
    [NSFileManager.defaultManager removeItemAtPath:obf error:nil];
}

- (void)testShallowSearchUsesTheSharedSearchQueue
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    XCTestExpectation *entered = [self expectationWithDescription:@"queue entered"];
    XCTestExpectation *finished = [self expectationWithDescription:@"queued searches finished"];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    NSMutableArray<NSString *> *order = [NSMutableArray array];
    [core.shared runAfterSearchTask:^{
        [entered fulfill];
        dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    }];
    [self waitForExpectations:@[entered] timeout:5];
    [core shallowSearchAsync:OASearchAmenityTypesAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
        XCTAssertFalse(NSThread.isMainThread);
        XCTAssertNotNil(result);
        [order addObject:@"first"];
    }];
    [core.shared runAfterSearchTask:^{ [order addObject:@"between"]; }];
    [core shallowSearchAsync:OASearchAmenityTypesAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
        XCTAssertNotNil(result);
        [order addObject:@"second"];
        [finished fulfill];
    }];
    XCTAssertEqual(order.count, 0, @"no shallow search may bypass the occupied queue");
    dispatch_semaphore_signal(gate);
    [self waitForExpectations:@[finished] timeout:30];
    XCTAssertEqualObjects(order, (@[@"first", @"between", @"second"]));
}

- (void)testMissingShallowApiStillCompletes
{
    OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    XCTestExpectation *finished = [self expectationWithDescription:@"missing API completed"];
    [core shallowSearchAsync:NSObject.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
        XCTAssertFalse(NSThread.isMainThread);
        XCTAssertNil(result);
        [finished fulfill];
    }];
    [self waitForExpectations:@[finished] timeout:10];
}

- (void)testCppShallowFailureCompletesAndDoesNotStopTheQueue
{
    OASearchUICore *core = [[OASearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    [core registerAPI:[OAFailingShallowSearchTestAPI new]];
    XCTestExpectation *failed = [self expectationWithDescription:@"failed search completed"];
    XCTestExpectation *next = [self expectationWithDescription:@"next search completed"];
    [core shallowSearchAsync:OAFailingShallowSearchTestAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
        XCTAssertFalse(NSThread.isMainThread);
        XCTAssertNil(result);
        [failed fulfill];
    }];
    [core shallowSearchAsync:OASearchAmenityTypesAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
        XCTAssertNotNil(result);
        [next fulfill];
    }];
    [self waitForExpectations:@[failed, next] timeout:10 enforceOrder:YES];
}

- (void)testReaderReuseAcrossConsumersBenchmark
{
    NSString *path = [self installTestMap:@"kiev"];
    NSArray<OASBinaryMapReaderResourceType *> *types = @[OASBinaryMapReaderResourceType.quickSearch,
        OASBinaryMapReaderResourceType.poi, OASBinaryMapReaderResourceType.routing];
    NSMutableArray<NSNumber *> *separateTimes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *registryTimes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *reuseTimes = [NSMutableArray array];
    for (NSInteger round = 0; round < 8; round++)
    {
        for (NSInteger phase = 0; phase < 2; phase++)
        {
            @autoreleasepool {
                BOOL useRegistry = (round + phase) % 2 == 0;
                CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                if (useRegistry)
                {
                    OASObfReaderRegistry *registry = [[OASObfReaderRegistry alloc] init];
                    @try {
                        [registry setFilesFiles:@[[[OASObfReaderRegistryObfFile alloc] initWithPath:path useForRouting:YES useForPublicTransport:NO]]];
                        OASBinaryMapReaderResource *resource = [registry getFileReaderPath:path];
                        NSMutableArray<OASBinaryMapIndexReader *> *readers = [NSMutableArray array];
                        for (OASBinaryMapReaderResourceType *type in types)
                        {
                            OASBinaryMapIndexReader *reader = [resource getReaderType:type];
                            XCTAssertNotNil(reader);
                            if (reader)
                                [readers addObject:reader];
                        }
                        if (readers.count != types.count)
                            return;
                        CFAbsoluteTime opened = CFAbsoluteTimeGetCurrent();
                        for (NSInteger i = 0; i < types.count; i++)
                            XCTAssertEqual([resource getReaderType:types[i]], readers[i]);
                        CFAbsoluteTime reused = CFAbsoluteTimeGetCurrent();
                        XCTAssertNotEqual(readers[0], readers[1]);
                        XCTAssertNotEqual(readers[0], readers[2]);
                        if (round > 0)
                        {
                            [registryTimes addObject:@((opened - start) * 1000)];
                            [reuseTimes addObject:@((reused - opened) * 1000)];
                        }
                    } @finally {
                        [registry close];
                    }
                }
                else
                {
                    NSMutableArray<OASBinaryMapIndexReader *> *readers = [NSMutableArray array];
                    @try {
                        for (NSInteger i = 0; i < types.count; i++)
                            [readers addObject:[[OASBinaryMapIndexReader alloc] initWithFilePath:path]];
                        if (round > 0)
                            [separateTimes addObject:@((CFAbsoluteTimeGetCurrent() - start) * 1000)];
                    } @finally {
                        for (OASBinaryMapIndexReader *reader in readers)
                            [reader close];
                    }
                }
            }
        }
    }
    NSNumber *(^median)(NSArray<NSNumber *> *) = ^NSNumber *(NSArray<NSNumber *> *times) {
        return [times sortedArrayUsingSelector:@selector(compare:)][times.count / 2];
    };
    NSString *measurement = [NSString stringWithFormat:@"OBF three-consumer benchmark, 7 rounds after warm-up, median ms: separate=%@ registry=%@ reuse=%@",
        median(separateTimes), median(registryTimes), median(reuseTimes)];
    printf("%s\n", measurement.UTF8String);
    XCTAttachment *attachment = [XCTAttachment attachmentWithString:measurement];
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
    [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    [OASharedObfResources.shared refreshFiles];
}

@end

@interface OASharedSearchUICore (ResourcePreparationTest)
- (void)prepareSearchResourcesIncludingTravel:(BOOL)includeTravel
                                  completion:(void (^)(NSArray<NSString *> *, NSArray<OASBinaryMapIndexReader *> *, uint64_t))completion;
@end

@interface OAResourcePreparationTestCore : OASharedSearchUICore
@property (nonatomic, copy) NSArray<NSString *> *(^prepare)(BOOL);
@property (nonatomic, copy) void (^didPrepare)(double);
@end

@implementation OAResourcePreparationTestCore
- (void)prepareSearchResourcesIncludingTravel:(BOOL)includeTravel
                                  completion:(void (^)(NSArray<NSString *> *, NSArray<OASBinaryMapIndexReader *> *, uint64_t))completion
{
    NSAssert(!NSThread.isMainThread, @"Resource preparation must not run on the main thread");
    if (!self.prepare)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        [super prepareSearchResourcesIncludingTravel:includeTravel completion:^(NSArray *ids, NSArray *readers, uint64_t generation) {
            if (self.didPrepare)
                self.didPrepare((CFAbsoluteTimeGetCurrent() - start) * 1000);
            completion(ids, readers, generation);
        }];
        return;
    }
    uint64_t generation = [OASharedObfResources.shared currentGeneration];
    completion(self.prepare(includeTravel), @[], generation);
}
@end

@interface OASharedSearchResourcePreparationTest : XCTestCase
@end

@implementation OASharedSearchResourcePreparationTest

- (void)testInstalledResourcesPrepareOffMainThreadBenchmark
{
    NSArray<NSString *> *resourceIds = [OAObfFileList searchResourceIdsIncludingTravel:YES];
    XCTSkipIf(resourceIds.count == 0, @"The app has no installed maps");
    OASharedSearchSettings *before = [[OASharedSearchSettings alloc] initWithShared:[[OASSearchSettings alloc] initWithS:nil]];
    OAResourcePreparationTestCore *after = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    [after initApi];
    NSMutableArray<NSNumber *> *beforeMain = [NSMutableArray array], *afterMain = [NSMutableArray array], *afterWorker = [NSMutableArray array];
    for (NSInteger round = 0; round < 8; round++)
    {
        // The former helper path, with the same installed maps and warmed registry.
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        [OASharedObfResources.shared refreshFiles];
        [before setOfflineIndexes:[OAObfFileList searchResourceIdsIncludingTravel:YES]];
        [before setRegions:OsmAndApp.instance.worldRegion];
        double beforeMs = (CFAbsoluteTimeGetCurrent() - start) * 1000;
        XCTestExpectation *applied = [self expectationWithDescription:@"real resources prepared and applied"];
        __block double workerMs = 0;
        after.didPrepare = ^(double milliseconds) {
            workerMs += milliseconds;
        };
        start = CFAbsoluteTimeGetCurrent();
        [after updateSearchResourcesIncludingTravel:YES regions:OsmAndApp.instance.worldRegion];
        double afterMs = (CFAbsoluteTimeGetCurrent() - start) * 1000;
        [after shallowSearchAsync:OASearchLocationAndUrlAPI.class text:@"52.52, 13.405" matcher:nil completion:^(OASearchResultCollection *result) {
            XCTAssertNotNil(result);
            [applied fulfill];
        }];
        [self waitForExpectations:@[applied] timeout:30];
        XCTAssertEqualObjects([[after getSearchSettings] getOfflineIndexes], resourceIds);
        XCTAssertEqualObjects([((OASharedSearchSettings *)[after getSearchSettings]).shared getOfflineIndexes], [before.shared getOfflineIndexes]);
        if (round > 0)
        {
            [beforeMain addObject:@(beforeMs)];
            [afterMain addObject:@(afterMs)];
            [afterWorker addObject:@(workerMs)];
        }
    }
    NSNumber *(^median)(NSArray<NSNumber *> *) = ^NSNumber *(NSArray<NSNumber *> *times) {
        return [times sortedArrayUsingSelector:@selector(compare:)][times.count / 2];
    };
    NSString *measurement = [NSString stringWithFormat:@"Warm resource refresh, %lu IDs, 7 rounds after warm-up, median ms: before main=%@, after main dispatch=%@, after worker=%@",
        (unsigned long)resourceIds.count, median(beforeMain), median(afterMain), median(afterWorker)];
    NSLog(@"%@", measurement);
    XCTAttachment *attachment = [XCTAttachment attachmentWithString:measurement];
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

- (void)waitForResources:(NSArray<NSString *> *)ids core:(OASharedSearchUICore *)core
{
    NSPredicate *applied = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [[[core getSearchSettings] getOfflineIndexes] isEqualToArray:ids];
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:applied object:nil]] timeout:10];
}

- (void)testPreparationLeavesMainThreadFreeAndPreservesNewSettings
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    XCTestExpectation *entered = [self expectationWithDescription:@"preparation entered"];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    core.prepare = ^NSArray *(BOOL includeTravel) {
        XCTAssertTrue(includeTravel);
        [entered fulfill];
        XCTAssertEqual(dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)), 0);
        return @[@"prepared.obf"];
    };
    XCTAssertTrue(NSThread.isMainThread);
    [core updateSearchResourcesIncludingTravel:YES regions:OsmAndApp.instance.worldRegion];
    [self waitForExpectations:@[entered] timeout:5];
    XCTestExpectation *responsive = [self expectationWithDescription:@"main queue responsive while readers open"];
    dispatch_async(dispatch_get_main_queue(), ^{ [responsive fulfill]; });
    [self waitForExpectations:@[responsive] timeout:2];
    [core updateSettings:[[[[core getSearchSettings] setLang:@"de" transliterateIfMissing:YES] setRadiusLevel:4] setTotalLimit:17]];
    dispatch_semaphore_signal(gate);
    [self waitForResources:@[@"prepared.obf"] core:core];
    XCTAssertEqualObjects([[core getSearchSettings] getLang], @"de");
    XCTAssertTrue([[core getSearchSettings] isTransliterate]);
    XCTAssertEqual([[core getSearchSettings] getRadiusLevel], 4);
    XCTAssertEqual([[core getSearchSettings] getTotalLimit], 17);
    XCTAssertEqual([[core getSearchSettings] getRegions], OsmAndApp.instance.worldRegion);
}

- (void)testNewResourceUpdateDiscardsTheInFlightSnapshot
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    XCTestExpectation *first = [self expectationWithDescription:@"first preparation entered"];
    XCTestExpectation *second = [self expectationWithDescription:@"second preparation entered"];
    dispatch_semaphore_t firstGate = dispatch_semaphore_create(0), secondGate = dispatch_semaphore_create(0);
    core.prepare = ^NSArray *(BOOL includeTravel) {
        if (includeTravel)
        {
            [first fulfill];
            dispatch_semaphore_wait(firstGate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
            return @[@"obsolete.travel.obf"];
        }
        [second fulfill];
        dispatch_semaphore_wait(secondGate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        return @[@"current.obf"];
    };
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [self waitForExpectations:@[first] timeout:5];
    [core updateSearchResourcesIncludingTravel:NO regions:nil];
    dispatch_semaphore_signal(firstGate);
    [self waitForExpectations:@[second] timeout:5];
    XCTAssertEqual([[core getSearchSettings] getOfflineIndexes].count, 0u);
    dispatch_semaphore_signal(secondGate);
    [self waitForResources:@[@"current.obf"] core:core];
}

- (void)testRegistryChangeDuringPreparationRetriesBeforeApplying
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    XCTestExpectation *entered = [self expectationWithDescription:@"preparation entered"];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    __block NSUInteger attempts = 0;
    core.prepare = ^NSArray *(BOOL includeTravel) {
        if (++attempts == 1)
        {
            [entered fulfill];
            dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
            return @[@"stale.obf"];
        }
        return @[@"current.obf"];
    };
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [self waitForExpectations:@[entered] timeout:5];
    [OASharedObfResources.shared refreshFiles];
    dispatch_semaphore_signal(gate);
    [self waitForResources:@[@"current.obf"] core:core];
    XCTAssertEqual(attempts, 2u);
}

- (void)testOnlyLatestSearchRunsAfterPreparation
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    core.prepare = ^NSArray *(BOOL includeTravel) {
        dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        return @[@"prepared.obf"];
    };
    XCTestExpectation *searched = [self expectationWithDescription:@"latest search started"];
    __block NSUInteger searches = 0;
    __weak OASharedSearchUICore *weakCore = core;
    [core setOnSearchStart:^{
        searches++;
        XCTAssertEqualObjects([[weakCore getPhrase] getText:YES], @"52.52, 13.405");
        XCTAssertEqualObjects([[weakCore getSearchSettings] getOfflineIndexes], @[@"prepared.obf"]);
        [searched fulfill];
    }];
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [[core.shared getPhrase] setAcceptPrivateAcceptPrivate:YES];
    [core search:@"obsolete" delayedExecution:NO matcher:nil];
    [core search:@"52.52, 13.405" delayedExecution:NO matcher:nil];
    XCTAssertEqualObjects([[core getPhrase] getText:YES], @"52.52, 13.405");
    XCTAssertTrue([[core.shared getPhrase] isAcceptPrivate]);
    XCTAssertEqual(searches, 0u);
    dispatch_semaphore_signal(gate);
    [self waitForExpectations:@[searched] timeout:10];
    [core cancelSearch:YES];
    XCTAssertEqual(searches, 1u);
}

- (void)testCancelledSearchDoesNotResumeAfterPreparation
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    core.prepare = ^NSArray *(BOOL includeTravel) {
        dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        return @[@"prepared.obf"];
    };
    XCTestExpectation *searched = [self expectationWithDescription:@"cancelled search must not start"];
    searched.inverted = YES;
    [core setOnSearchStart:^{ [searched fulfill]; }];
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [core search:@"52.52, 13.405" delayedExecution:NO matcher:nil];
    [core cancelSearch:NO];
    dispatch_semaphore_signal(gate);
    [self waitForResources:@[@"prepared.obf"] core:core];
    [self waitForExpectations:@[searched] timeout:0.2];
}

- (void)testShallowSearchKeepsItsSettingsAndCompletesAfterPreparation
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    core.prepare = ^NSArray *(BOOL includeTravel) {
        dispatch_semaphore_wait(gate, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        return @[@"prepared.obf"];
    };
    XCTestExpectation *searched = [self expectationWithDescription:@"shallow searches completed"];
    searched.expectedFulfillmentCount = 2;
    NSMutableArray *order = [NSMutableArray array];
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [core updateSettings:[[core getSearchSettings] setLang:@"de" transliterateIfMissing:NO]];
    for (NSString *label in @[@"first", @"second"])
    {
        [core shallowSearchAsync:OASearchAmenityTypesAPI.class text:@"" matcher:nil completion:^(OASearchResultCollection *result) {
            XCTAssertFalse(NSThread.isMainThread);
            XCTAssertNotNil(result);
            XCTAssertEqualObjects([result.phrase.getSettings getLang], @"de");
            [order addObject:label];
            [searched fulfill];
        }];
    }
    [core updateSettings:[[core getSearchSettings] setLang:@"fr" transliterateIfMissing:NO]];
    XCTAssertEqual(order.count, 0u);
    dispatch_semaphore_signal(gate);
    [self waitForExpectations:@[searched] timeout:10];
    XCTAssertEqualObjects(order, (@[@"first", @"second"]));
    XCTAssertEqualObjects([[core getSearchSettings] getLang], @"fr");
}

- (void)testEmptyResourceUpdateRemovesPreviousMaps
{
    OAResourcePreparationTestCore *core = [[OAResourcePreparationTestCore alloc] initWithLang:@"en" transliterate:NO];
    core.prepare = ^NSArray *(BOOL includeTravel) { return includeTravel ? @[@"previous.obf"] : @[]; };
    [core updateSearchResourcesIncludingTravel:YES regions:nil];
    [self waitForResources:@[@"previous.obf"] core:core];
    [core updateSearchResourcesIncludingTravel:NO regions:nil];
    [self waitForResources:@[] core:core];
    XCTAssertEqual([((OASharedSearchSettings *)[core getSearchSettings]).shared getOfflineIndexes].count, 0u);
}

@end
