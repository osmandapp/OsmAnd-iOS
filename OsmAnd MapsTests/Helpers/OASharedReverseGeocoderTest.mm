//
//  OASharedReverseGeocoderTest.mm
//  OsmAnd MapsTests
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAReverseGeocoder.h"
#import "OAAppSettings.h"
#import "OAObservable.h"
#import "OsmAndApp.h"
#import "OASharedSearchObjects.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#include <OsmAndCore/ArchiveReader.h>

@interface OAReverseGeocoder (SharedTests)
- (NSString *)performLookupAddressAtLat:(double)lat lon:(double)lon objectId:(uint64_t)objectId;
- (NSString *)geocodeAddressAtLat:(double)lat lon:(double)lon;
- (NSString *)geocodeRequest:(id)request;
- (void)clearCache;
+ (NSString *)formatSharedAddress:(OASGeocodingUtilitiesGeocodingResult *)result language:(NSString *)language transliterate:(BOOL)transliterate;
@end

@interface OAEngineCacheTestGeocoder : OAReverseGeocoder
@property (nonatomic) NSUInteger lookups;
@property (atomic) NSUInteger cacheClears;
@property (nonatomic, copy) NSString *lastLanguage;
@property (nonatomic) BOOL lastTransliterate;
@property (nonatomic, copy) void (^duringLookup)(void);
@end

@implementation OAEngineCacheTestGeocoder
- (void)clearCache
{
    @synchronized (self)
    {
        [super clearCache];
        self.cacheClears++;
    }
}

- (NSString *)geocodeRequest:(id)request
{
    self.lookups++;
    self.lastLanguage = [request valueForKey:@"language"];
    self.lastTransliterate = [[request valueForKey:@"transliterate"] boolValue];
    if (self.duringLookup)
        self.duringLookup();
    return [[request valueForKey:@"useShared"] boolValue] ? @"shared address" : @"cpp address";
}
@end

@interface OASharedReverseGeocoderTest : XCTestCase
@end

static NSString *fixtureDirectory;
static NSString *fixturePath;
static OASKLatLon *fixtureLocation;

@implementation OASharedReverseGeocoderTest
{
    BOOL _shared;
    BOOL _transliterate;
    NSString *_language;
}

- (void)setUp
{
    [super setUp];
    XCTNSPredicateExpectation *initialized = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithFormat:@"initialized == YES"] object:OsmAndApp.instance];
    [self waitForExpectations:@[initialized] timeout:120];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    _shared = settings.useSharedSearch.get;
    _language = settings.settingPrefMapLanguage.get;
    _transliterate = settings.settingMapLanguageTranslit.get;
    [settings.useSharedSearch set:YES];
    [settings.settingPrefMapLanguage set:@"en"];
    [settings.settingMapLanguageTranslit set:NO];

    if (!fixturePath)
    {
        NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        fixtureDirectory = [cache stringByAppendingPathComponent:[NSString stringWithFormat:@"geocoding-tests-%@", NSUUID.UUID.UUIDString.lowercaseString]];
        NSError *error = nil;
        XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtPath:fixtureDirectory withIntermediateDirectories:YES attributes:nil error:&error], @"%@", error);
        fixturePath = [fixtureDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"i5_%@.obf", NSUUID.UUID.UUIDString.lowercaseString]];
        NSString *gz = [[NSBundle bundleForClass:self.class].bundlePath stringByAppendingPathComponent:@"test-resources/search/austria_wien.obf.gz"];
        OsmAnd::ArchiveReader archive(QString::fromNSString(gz));
        bool ok = false;
        const auto items = archive.getItems(&ok, true);
        XCTAssertTrue(ok && !items.isEmpty() && archive.extractItemToFile(items.first().name, QString::fromNSString(fixturePath), true));
        XCTAssertTrue([OsmAndApp.instance installTestResource:fixturePath]);
        [OASharedObfResources.shared refreshFiles];

        OASBinaryMapIndexReader *reader = [[OASBinaryMapIndexReader alloc] initWithFilePath:fixturePath];
        __block OASStreet *street = nil;
        id<OASResultMatcher> matcher = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) {
            if (!street && [object isKindOfClass:OASStreet.class])
                street = object;
            return NO;
        } cancelled:^BOOL { return NO; }];
        [reader searchAddressDataByNameReq:(OASSearchRequest<OASMapObject *> *)[OASSearchRequest.companion buildAddressByNameRequestResultMatcher:matcher
            nameRequest:@"gießaufgasse" matcherMode:OASKStringMatcherMode.checkEqualsFromSpace]];
        XCTAssertNotNil(street);
        if (street)
        {
            [reader preloadBuildingsS:street resultMatcher:nil];
            fixtureLocation = [street.getBuildings.firstObject getLocation] ?: street.getLocation;
        }
        [reader close];
    }
    XCTAssertNotNil(fixtureLocation);
}

- (void)tearDown
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    [settings.useSharedSearch set:_shared];
    [settings.settingPrefMapLanguage set:_language];
    [settings.settingMapLanguageTranslit set:_transliterate];
    [super tearDown];
}

+ (void)tearDown
{
    if (fixturePath)
    {
        [OsmAndApp.instance removeTestResource:fixturePath];
        [OASharedObfResources.shared refreshFiles];
        NSError *error = nil;
        XCTAssertTrue([NSFileManager.defaultManager removeItemAtPath:fixtureDirectory error:&error], @"%@", error);
        fixturePath = nil;
        fixtureDirectory = nil;
        fixtureLocation = nil;
    }
    [super tearDown];
}

- (OASGeocodingUtilitiesGeocodingResult *)addressResult
{
    OASCity *city = [[OASCity alloc] initWithType:OASCityType.city];
    [city setNameName:@"Wien"];
    [city setNameLang:@"en" name:@"Vienna"];
    OASStreet *street = [[OASStreet alloc] initWithCity:city];
    [street setNameName:@"Gasse"];
    [street setNameLang:@"en" name:@"Lane"];
    OASBuilding *building = [[OASBuilding alloc] init];
    [building setNameName:@"10"];
    OASGeocodingUtilitiesGeocodingResult *result = [[OASGeocodingUtilitiesGeocodingResult alloc] init];
    result.city = city;
    result.street = street;
    result.building = building;
    result.searchPoint = [[OASKLatLon alloc] initWithLatitude:48.19 longitude:16.35];
    result.connectionPoint = result.searchPoint;
    return result;
}

- (void)testAddressFormattingUsesLocalizedNamesAndInterpolatedHouseNumbers
{
    OASGeocodingUtilitiesGeocodingResult *result = [self addressResult];
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], @"Lane 10, Vienna");
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"" transliterate:NO], @"Gasse 10, Wien");
    result.buildingInterpolation = @"12";
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], @"Lane 12, Vienna");
    result.building = nil;
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], @"Lane, Vienna");
    result.street = nil;
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], @"Vienna");
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:nil language:@"en" transliterate:NO], @"");
}

- (void)testDistantAddressHasNearPrefixAndEmptyResultDoesNot
{
    OASGeocodingUtilitiesGeocodingResult *result = [self addressResult];
    result.connectionPoint = [[OASKLatLon alloc] initWithLatitude:48.192 longitude:16.35];
    XCTAssertGreaterThan(result.getDistance, 100);
    NSString *expected = [NSString stringWithFormat:@"%@ Lane 10, Vienna", OALocalizedString(@"shared_string_near")];
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], expected);
    result.building = nil;
    result.street = nil;
    result.city = nil;
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO], @"");
}

- (void)testRoadFallbackIncludesReferenceAndSupportsReferenceWithoutName
{
    OASRouteRegion *region = [[OASRouteRegion alloc] init];
    [region doInitRouteEncodingRuleId:1 tags:@"name" val:nil];
    [region doInitRouteEncodingRuleId:2 tags:@"ref" val:nil];
    OASRouteDataObject *road = [[OASRouteDataObject alloc] initWithRegion:region];
    road.pointsX = [OASKotlinIntArray arrayWithSize:2];
    road.pointsY = [OASKotlinIntArray arrayWithSize:2];
    road.names = [[OASKTIntObjectMap alloc] initWithInitialCapacity:2];
    [road.names putKey:1 value:@"Hauptstraße"];
    [road.names putKey:2 value:@"B 5"];
    OASGeocodingUtilitiesGeocodingResult *result = [[OASGeocodingUtilitiesGeocodingResult alloc] init];
    result.point = [[OASRouteSegmentPoint alloc] initWithRoad:road segmentStart:0 distToProj:0];
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"" transliterate:NO], @"Hauptstraße, B 5");
    [road.names removeKey:1];
    XCTAssertEqualObjects([OAReverseGeocoder formatSharedAddress:result language:@"" transliterate:NO], @"B 5");
}

- (void)testCacheSeparatesCppAndSharedAddresses
{
    OAEngineCacheTestGeocoder *geocoder = [[OAEngineCacheTestGeocoder alloc] init];
    for (NSNumber *objectId in @[@0, @42])
    {
        [OAAppSettings.sharedManager.useSharedSearch set:NO];
        XCTAssertEqualObjects([geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:objectId.unsignedLongLongValue], @"cpp address");
        [OAAppSettings.sharedManager.useSharedSearch set:YES];
        XCTAssertEqualObjects([geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:objectId.unsignedLongLongValue], @"shared address");
        [OAAppSettings.sharedManager.useSharedSearch set:NO];
        XCTAssertEqualObjects([geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:objectId.unsignedLongLongValue], @"cpp address");
    }
    XCTAssertEqual(geocoder.lookups, 4u);
}

- (void)testQueuedLookupKeepsItsEngineAndLanguageSnapshot
{
    OAEngineCacheTestGeocoder *geocoder = [[OAEngineCacheTestGeocoder alloc] init];
    NSOperationQueue *queue = [geocoder valueForKey:@"lookupQueue"];
    queue.suspended = YES;
    XCTestExpectation *completed = [self expectationWithDescription:@"queued lookup"];
    [geocoder lookupAddressAtLat:48.19 lon:16.35 objectId:0 completion:^(NSString *address) {
        XCTAssertEqualObjects(address, @"shared address");
        XCTAssertEqualObjects(geocoder.lastLanguage, @"en");
        XCTAssertFalse(geocoder.lastTransliterate);
        [completed fulfill];
    }];
    [OAAppSettings.sharedManager.useSharedSearch set:NO];
    [OAAppSettings.sharedManager.settingPrefMapLanguage set:@"de"];
    [OAAppSettings.sharedManager.settingMapLanguageTranslit set:YES];
    queue.suspended = NO;
    [self waitForExpectations:@[completed] timeout:10];
    XCTAssertEqualObjects([geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0], @"cpp address");
    XCTAssertEqualObjects(geocoder.lastLanguage, @"de");
    XCTAssertTrue(geocoder.lastTransliterate);
    XCTAssertEqual(geocoder.lookups, 2u);
}

- (void)testResourceChangesInvalidateCachedAndInFlightAddresses
{
    OAEngineCacheTestGeocoder *geocoder = [[OAEngineCacheTestGeocoder alloc] init];
    __weak OAEngineCacheTestGeocoder *weakGeocoder = geocoder;
    geocoder.duringLookup = ^{ [weakGeocoder clearCache]; };
    [geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0];
    geocoder.duringLookup = nil;
    [geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0];
    XCTAssertEqual(geocoder.lookups, 2u, @"a result finishing after invalidation must not refill the current cache");
    [geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0];
    XCTAssertEqual(geocoder.lookups, 2u);
    NSUInteger before = geocoder.cacheClears;
    [OsmAndApp.instance.localResourcesChangedObservable notifyEvent];
    XCTNSPredicateExpectation *invalidated = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithFormat:@"cacheClears > %lu", (unsigned long)before] object:geocoder];
    [self waitForExpectations:@[invalidated] timeout:10];
    [geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0];
    XCTAssertEqual(geocoder.lookups, 3u);
    [OASharedObfResources.shared refreshFiles];
    [geocoder performLookupAddressAtLat:48.19 lon:16.35 objectId:0];
    XCTAssertEqual(geocoder.lookups, 4u, @"a completed registry refresh invalidates the cache without waiting for another observer");
}

- (void)testAsyncLookupReturnsSharedAddressOnMainThreadForAllCallers
{
    OASGeocodingUtilitiesGeocodingResult *result = [OASharedObfResources.shared.geocodingService
        lookupAddressLat:fixtureLocation.latitude lon:fixtureLocation.longitude
        defaultRoutingConfig:OsmAndApp.instance.sharedDefaultRoutingConfig cancel:nil];
    XCTAssertNotNil(result);
    NSString *expected = [OAReverseGeocoder formatSharedAddress:result language:@"en" transliterate:NO];
    XCTAssertGreaterThan(expected.length, 0u);
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    XCTestExpectation *completed = [self expectationWithDescription:@"all address callbacks"];
    completed.expectedFulfillmentCount = 12;
    for (NSUInteger i = 0; i < 12; i++)
    {
        [geocoder lookupAddressAtLat:fixtureLocation.latitude lon:fixtureLocation.longitude objectId:0 completion:^(NSString *address) {
            XCTAssertTrue(NSThread.isMainThread);
            XCTAssertEqualObjects(address, expected);
            [completed fulfill];
        }];
    }
    [self waitForExpectations:@[completed] timeout:60];
    fprintf(stderr, "I5 address: %.7f, %.7f -> %s\n", fixtureLocation.latitude, fixtureLocation.longitude, expected.UTF8String);
}

- (void)testStoppedGeocoderAndUncoveredLocationReturnEmptyAddresses
{
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    XCTAssertEqualObjects([geocoder geocodeAddressAtLat:-45 lon:-130], @"");
    [geocoder stop];
    XCTestExpectation *completed = [self expectationWithDescription:@"stopped lookup"];
    [geocoder lookupAddressAtLat:fixtureLocation.latitude lon:fixtureLocation.longitude objectId:0 completion:^(NSString *address) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertEqualObjects(address, @"");
        [completed fulfill];
    }];
    [self waitForExpectations:@[completed] timeout:10];
}

- (void)testCancellationDuringSharedLookupReturnsNoAddress
{
    OASGeocodingService *service = OASharedObfResources.shared.geocodingService;
    __block NSUInteger polls = 0;
    id<OASResultMatcher> count = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) { return NO; }
        cancelled:^BOOL { polls++; return NO; }];
    XCTAssertNotNil([service lookupAddressLat:fixtureLocation.latitude lon:fixtureLocation.longitude
        defaultRoutingConfig:OsmAndApp.instance.sharedDefaultRoutingConfig cancel:count]);
    XCTAssertGreaterThan(polls, 4u);
    NSUInteger fullPolls = polls;
    for (NSNumber *threshold in @[@1, @(fullPolls / 2), @(fullPolls)])
    {
        polls = 0;
        id<OASResultMatcher> cancel = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) { return NO; }
            cancelled:^BOOL { return ++polls >= threshold.unsignedIntegerValue; }];
        XCTAssertNil([service lookupAddressLat:fixtureLocation.latitude lon:fixtureLocation.longitude
            defaultRoutingConfig:OsmAndApp.instance.sharedDefaultRoutingConfig cancel:cancel]);
    }
}

- (void)testLookupResultsAndWarmTimingAgainstCpp
{
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    NSMutableArray<NSNumber *> *cpp = [NSMutableArray array];
    NSMutableArray<NSNumber *> *shared = [NSMutableArray array];
    NSMutableDictionary<NSNumber *, NSString *> *answers = [NSMutableDictionary dictionary];
    for (NSUInteger round = 0; round < 9; round++)
    {
        for (NSNumber *enabled in (round % 2 == 0 ? @[@NO, @YES] : @[@YES, @NO]))
        {
            [OAAppSettings.sharedManager.useSharedSearch set:enabled.boolValue];
            CFAbsoluteTime started = CFAbsoluteTimeGetCurrent();
            NSString *address = [geocoder geocodeAddressAtLat:fixtureLocation.latitude lon:fixtureLocation.longitude];
            double elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000;
            XCTAssertGreaterThan(address.length, 0u);
            if (answers[enabled])
                XCTAssertEqualObjects(address, answers[enabled]);
            answers[enabled] = address;
            if (round >= 2)
                [(enabled.boolValue ? shared : cpp) addObject:@(elapsed)];
        }
    }
    [cpp sortUsingSelector:@selector(compare:)];
    [shared sortUsingSelector:@selector(compare:)];
    fprintf(stderr, "I5 lookup: 2 warmups + 7 rounds, C++ %.3f ms (%s), shared %.3f ms (%s)\n",
        cpp[3].doubleValue, answers[@NO].UTF8String, shared[3].doubleValue, answers[@YES].UTF8String);
}

@end
