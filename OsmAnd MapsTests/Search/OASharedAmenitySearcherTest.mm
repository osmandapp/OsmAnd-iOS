//
//  OASharedAmenitySearcherTest.mm
//  OsmAnd MapsTests
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAAmenitySearcher.h"
#import "OASharedAmenitySearcher.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIHelper.h"
#import "OASearchPoiTypeFilter.h"
#import "OATopIndexFilter.h"
#import "OAResultMatcher.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"
#include <OsmAndCore/ArchiveReader.h>

@interface OASharedAmenitySearcherTest : XCTestCase
@end

static NSString *fixturePath;
static NSString *fixtureDirectory;
static OAPOI *fixturePoi;

@implementation OASharedAmenitySearcherTest
{
    BOOL _useShared;
    NSString *_language;
    BOOL _transliterate;
}

- (void)setUp
{
    [super setUp];
    XCTNSPredicateExpectation *initialized = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithFormat:@"initialized == YES"] object:OsmAndApp.instance];
    [self waitForExpectations:@[initialized] timeout:120];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    _useShared = settings.useSharedSearch.get;
    _language = settings.settingPrefMapLanguage.get;
    _transliterate = settings.settingMapLanguageTranslit.get;
    [settings.useSharedSearch set:YES];
    [settings.settingPrefMapLanguage set:@""];
    [settings.settingMapLanguageTranslit set:NO];
    if (!fixturePath)
    {
        NSString *gz = [[NSBundle bundleForClass:self.class].bundlePath stringByAppendingPathComponent:@"test-resources/search/kiev.obf.gz"];
        // Startup clears NSTemporaryDirectory after app.initialized becomes true.
        NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        fixtureDirectory = [cache stringByAppendingPathComponent:[NSString stringWithFormat:@"amenity-tests-%@", NSUUID.UUID.UUIDString.lowercaseString]];
        NSError *error = nil;
        XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtPath:fixtureDirectory withIntermediateDirectories:YES attributes:nil error:&error], @"%@", error);
        fixturePath = [fixtureDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"i4_%@.obf", NSUUID.UUID.UUIDString.lowercaseString]];
        OsmAnd::ArchiveReader archive(QString::fromNSString(gz));
        bool ok = false;
        const auto items = archive.getItems(&ok, true);
        XCTAssertTrue(ok && items.size() > 0 && archive.extractItemToFile(items.first().name, QString::fromNSString(fixturePath), true));
        XCTAssertTrue([OsmAndApp.instance installTestResource:fixturePath]);
        [OASharedObfResources.shared refreshFiles];
        id<OASAmenityIndexRepository> repo = [OASharedObfResources.shared amenityRepositoryForResourceId:fixturePath.lastPathComponent];
        XCTAssertNotNil(repo);
        OASSearchRequest *request = [OASSearchRequest.companion buildSearchPoiRequestSleft:0 sright:INT_MAX stop:0 sbottom:INT_MAX
            zoom:-1 poiTypeFilter:nil poiTopIndexAdditionalFilter:nil matcher:nil];
        [repo searchPoiSearchRequest:request];
        for (OASAmenity *amenity in request.getSearchResults)
        {
            OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
            if (poi && [amenity getName].length > 3 && [poi isValidOsmId])
            {
                fixturePoi = poi;
                break;
            }
        }
    }
    XCTAssertNotNil(fixturePoi);
}

- (void)tearDown
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    [settings.useSharedSearch set:_useShared];
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
        fixturePoi = nil;
    }
    [super tearDown];
}

- (NSArray<OAPOI *> *)area:(OAResultMatcher *)matcher
{
    return [OAAmenitySearcher findPOI:OASearchPoiTypeFilter.acceptAllPoiTypeFilter additionalFilter:nil
        lat:fixturePoi.latitude lon:fixturePoi.longitude radius:500 includeTravel:YES matcher:matcher publish:nil];
}

- (OASAmenity *)amenity:(long long)osmId subtype:(NSString *)subtype
{
    OASAmenity *amenity = [[OASAmenity alloc] init];
    [amenity setIdId:[[OASLong alloc] initWithLongLong:osmId << 1]];
    [amenity setTypeType:[OAPOIHelper.sharedInstance.kPoiTypes getPoiCategoryByNameName:@"sustenance"]];
    [amenity setSubTypeSubType:subtype];
    [amenity setNameName:@"Cafe"];
    [amenity setLocationLatitude:52 longitude:13];
    return amenity;
}

- (void)testPoiConversionPreservesGeometryRouteAndContent
{
    OASAmenity *amenity = [self amenity:123 subtype:@"cafe"];
    [amenity setNameLang:@"de" name:@"Kaffeehaus"];
    [amenity setAdditionalInfoTag:@"wikidata" value:@"Q123"];
    [amenity setAdditionalInfoTag:@"content:en" value:@"An article"];
    [amenity setMapIconNameMapIconName:@"custom_icon"];
    [amenity setRegionNameRegionName:@"test_region"];
    for (int i = 0; i < 3; i++)
    {
        [[amenity getX] addValue:100 + i];
        [[amenity getY] addValue:200 + i];
    }
    OASAmenityRoutePoint *route = [[OASAmenityRoutePoint alloc] init];
    route.deviateDistance = 37;
    route.deviationDirectionRight = YES;
    route.pointA = [[OASKLocation alloc] initWithProvider:nil latitude:52 longitude:13];
    route.pointB = [[OASKLocation alloc] initWithProvider:nil latitude:52.1 longitude:13.1];
    [amenity setRoutePointRoutePoint:route];
    OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:amenity];
    XCTAssertEqualObjects(poi.x, (@[@100, @101, @102]));
    XCTAssertEqualObjects(poi.y, (@[@200, @201, @202]));
    XCTAssertEqualObjects(poi.mapIconName, @"custom_icon");
    XCTAssertEqualObjects(poi.regionName, @"test_region");
    XCTAssertEqualObjects(poi.localizedContent[@"en"], @"An article");
    XCTAssertEqual(poi.routePoint.deviateDistance, 37);
    XCTAssertTrue(poi.routePoint.deviationDirectionRight);
    XCTAssertEqual(poi.routePoint.pointB.coordinate.latitude, 52.1);
    poi.name = @"Edited name";
    poi.values[@"phone"] = @"123456";
    OASAmenity *back = [OASharedAmenitySearcher sharedAmenity:poi];
    XCTAssertEqualObjects([back getName], @"Edited name");
    XCTAssertEqualObjects([back getAdditionalInfoKey:@"phone"], @"123456");
    XCTAssertEqualObjects([back getAdditionalInfoKey:@"content:en"], @"An article");
    XCTAssertEqual([[back getY] getIndex:2], 202);
    XCTAssertEqual([back getRoutePoint].pointB.latitude, 52.1);
}

- (void)testAreaMatcherRejectsResultsAndKeepsAcceptedObjectIdentity
{
    __block NSUInteger rejected = 0;
    OAResultMatcher *reject = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
        rejected++;
        return NO;
    } cancelledFunc:^BOOL { return NO; }];
    XCTAssertEqual([self area:reject].count, 0u);
    XCTAssertGreaterThan(rejected, 0u);
    NSMutableSet *published = [NSMutableSet set];
    OAResultMatcher *accept = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
        OAPOI *poi = *object;
        [published addObject:[NSValue valueWithNonretainedObject:poi]];
        poi.desc = @"set by matcher";
        return YES;
    } cancelledFunc:^BOOL { return NO; }];
    NSArray *results = [self area:accept];
    XCTAssertGreaterThan(results.count, 0u);
    for (OAPOI *poi in results)
    {
        XCTAssertTrue([published containsObject:[NSValue valueWithNonretainedObject:poi]]);
        XCTAssertEqualObjects(poi.desc, @"set by matcher");
    }
}

- (void)testAreaCancellationBeforeAndDuringSearch
{
    __block BOOL cancelled = YES;
    __block NSUInteger calls = 0;
    OAResultMatcher *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
        calls++;
        cancelled = YES;
        return YES;
    } cancelledFunc:^BOOL { return cancelled; }];
    XCTAssertEqual([self area:matcher].count, 0u);
    XCTAssertEqual(calls, 0u);
    cancelled = NO;
    NSArray *results = [self area:matcher];
    XCTAssertEqual(calls, 1u);
    XCTAssertLessThanOrEqual(results.count, 1u);
}

- (void)testPublishStopsAreaSearchAfterOneObject
{
    __block NSUInteger calls = 0;
    NSArray *results = [OAAmenitySearcher findPOI:OASearchPoiTypeFilter.acceptAllPoiTypeFilter additionalFilter:nil
        lat:fixturePoi.latitude lon:fixturePoi.longitude radius:500 includeTravel:YES matcher:nil publish:^BOOL(OAPOI *poi) {
            calls++;
            return YES;
        }];
    XCTAssertEqual(calls, 1u);
    XCTAssertEqual(results.count, 0u);
}

- (void)testAdditionalFilterIncludesMatchingIndexedValuesAndRejectsUnknownValues
{
    id<OASAmenityIndexRepository> repository = [OASharedObfResources.shared amenityRepositoryForResourceId:fixturePath.lastPathComponent];
    OASPoiSubType *indexedType = nil;
    for (OASPoiRegion *region in repository.getReaderPoiIndexes)
    {
        for (OASPoiSubType *type in region.getSubTypes)
        {
            if (type.possibleValues.count > 0)
            {
                indexedType = type;
                break;
            }
        }
        if (indexedType)
            break;
    }
    XCTAssertNotNil(indexedType);
    if (!indexedType)
        return;
    OATopIndexFilter *filter = [[OATopIndexFilter alloc] initWithPoiSubType:indexedType.name value:indexedType.possibleValues.firstObject];
    NSArray *(^search)(OATopIndexFilter *) = ^NSArray *(OATopIndexFilter *additional) {
        return [OASharedAmenitySearcher searchAmenities:nil additionalFilter:additional topLatitude:85 leftLongitude:-180
            bottomLatitude:-85 rightLongitude:180 includeTravel:NO matcher:nil publish:nil];
    };
    NSArray *matches = search(filter);
    XCTAssertGreaterThan(matches.count, 0u);
    for (OAPOI *poi in matches)
    {
        NSString *value = poi.values[filter.poiSubType];
        XCTAssertNotNil(value);
        XCTAssertEqual([value caseInsensitiveCompare:filter.value], NSOrderedSame);
    }
    OATopIndexFilter *missing = [[OATopIndexFilter alloc] initWithPoiSubType:indexedType.name value:@"missing-i4-indexed-value"];
    XCTAssertEqual(search(missing).count, 0u);
}

- (void)testNameSearchHonorsMatcherAndResourceScope
{
    __block NSUInteger calls = 0;
    OAResultMatcher *reject = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
        calls++;
        return NO;
    } cancelledFunc:^BOOL { return NO; }];
    NSArray *results = [OAAmenitySearcher findPOIsByName:fixturePoi.sharedAmenity.getName
        topLatitude:fixturePoi.latitude + .01 leftLongitude:fixturePoi.longitude - .01
        bottomLatitude:fixturePoi.latitude - .01 rightLongitude:fixturePoi.longitude + .01 matcher:reject];
    XCTAssertEqual(results.count, 0u);
    XCTAssertGreaterThan(calls, 0u);
    NSArray *scoped = [OAAmenitySearcher searchAmenitiesByName:fixturePoi.sharedAmenity.getName
        resourceId:fixturePath.lastPathComponent location:fixturePoi.getLocation matcher:nil];
    XCTAssertGreaterThan(scoped.count, 0u);
    XCTAssertEqual([OAAmenitySearcher searchAmenitiesByName:fixturePoi.sharedAmenity.getName
        resourceId:@"missing-i4-resource.obf" location:nil matcher:nil].count, 0u);
}

- (void)testPathSearchReturnsRouteMetadataAndHonorsMatcher
{
    NSArray *path = @[[[CLLocation alloc] initWithLatitude:fixturePoi.latitude - .001 longitude:fixturePoi.longitude],
                     [[CLLocation alloc] initWithLatitude:fixturePoi.latitude + .001 longitude:fixturePoi.longitude]];
    NSArray<OAPOI *> *results = [OAAmenitySearcher searchPOIsOnThePath:path radius:100
        filter:OASearchPoiTypeFilter.acceptAllPoiTypeFilter matcher:nil];
    XCTAssertGreaterThan(results.count, 0u);
    for (OAPOI *poi in results)
    {
        XCTAssertNotNil(poi.routePoint);
        XCTAssertNotNil(poi.routePoint.pointA);
        XCTAssertNotNil(poi.routePoint.pointB);
        XCTAssertLessThanOrEqual(poi.routePoint.deviateDistance, 100);
    }
    __block NSUInteger calls = 0;
    OAResultMatcher *reject = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {
        calls++;
        return NO;
    } cancelledFunc:^BOOL { return NO; }];
    XCTAssertEqual([OAAmenitySearcher searchPOIsOnThePath:path radius:100
        filter:OASearchPoiTypeFilter.acceptAllPoiTypeFilter matcher:reject].count, 0u);
    XCTAssertGreaterThan(calls, 0u);
}

- (void)testDetailedRequestRetainsRelationRadiusAndTags
{
    OAAmenitySearcherRequest *request = [[OAAmenitySearcherRequest alloc] initWithMapObject:fixturePoi];
    request.latLon = [[CLLocation alloc] initWithLatitude:fixturePoi.latitude + .003 longitude:fixturePoi.longitude];
    request.names = [NSMutableArray array];
    request.wikidata = nil;
    request.type = kEntityTypeRelation;
    BaseDetailsObject *relation = [OAAmenitySearcher.sharedInstance searchDetailedObjectWithRequest:request];
    XCTAssertNotNil(relation);
    XCTAssertEqual(relation.syntheticAmenity.getOsmId, fixturePoi.getOsmId);
    request.type = kEntityTypeNode;
    XCTAssertNil([OAAmenitySearcher.sharedInstance searchDetailedObjectWithRequest:request]);
    // A newer installed map may move the same OSM object relative to the bundled fixture.
    // The tag fallback requires coordinates from the representation selected by the search.
    request.latLon = relation.syntheticAmenity.getLocation;
    request.osmId = 0;
    request.tags = [@{@"amenity": relation.syntheticAmenity.subType} mutableCopy];
    XCTAssertNotNil([OAAmenitySearcher.sharedInstance searchDetailedObjectWithRequest:request]);
}

- (void)testDetailedObjectCopiesSelectedGeometry
{
    OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:fixturePoi.sharedAmenity];
    poi.x = [@[@100, @101, @102] mutableCopy];
    poi.y = [@[@200, @201, @202] mutableCopy];
    BaseDetailsObject *details = [OAAmenitySearcher.sharedInstance searchDetailedObject:poi];
    XCTAssertNotNil(details);
    XCTAssertEqualObjects(details.syntheticAmenity.x, poi.x);
    XCTAssertEqualObjects(details.syntheticAmenity.y, poi.y);
    XCTAssertTrue(details.hasGeometry);
    XCTAssertEqual([OAAmenitySearcher.sharedInstance searchDetailedObject:details], details);
    XCTAssertEqualObjects(details.syntheticAmenity.x, poi.x);
    XCTAssertEqualObjects(details.syntheticAmenity.y, poi.y);
}

- (void)testMergeRetainsAllTypesTagsNamesGeometryAndDistance
{
    OASAmenity *first = [self amenity:123 subtype:@"cafe"];
    [first setAdditionalInfoTag:@"wikidata" value:@"Q123"];
    [first setAdditionalInfoTag:@"phone" value:@"123456"];
    OASAmenity *second = [self amenity:456 subtype:@"restaurant"];
    [second setAdditionalInfoTag:@"wikidata" value:@"Q123"];
    [second setAdditionalInfoTag:@"website" value:@"https://example.org"];
    [second setNameLang:@"de" name:@"Kaffeehaus"];
    for (int i = 0; i < 3; i++)
    {
        [[second getX] addValue:100 + i];
        [[second getY] addValue:200 + i];
    }
    OAPOI *a = [OAAmenitySearcher parsePOIBySharedAmenity:first];
    a.distanceMeters = 42;
    OAPOI *b = [OAAmenitySearcher parsePOIBySharedAmenity:second];
    NSArray *merged = [OAAmenitySearcher filterUniqueAmenitiesByOsmIdOrWikidata:@[a, b]];
    XCTAssertEqual(merged.count, 1u);
    OAPOI *poi = merged.firstObject;
    XCTAssertEqualObjects(poi.subType, @"cafe;restaurant");
    XCTAssertEqualObjects(poi.values[@"phone"], @"123456");
    XCTAssertEqualObjects(poi.values[@"website"], @"https://example.org");
    XCTAssertEqualObjects(poi.localizedNames[@"de"], @"Kaffeehaus");
    XCTAssertEqual(poi.x.count, 3u);
    XCTAssertEqual(poi.distanceMeters, 42);
    XCTAssertEqualObjects(a.subType, @"cafe", @"The caller's cached results are not mutated by merging.");
}

- (void)testMergeUsesRealNamesInsteadOfDisplayFallbacks
{
    OASAmenity *unnamed = [self amenity:123 subtype:@"cafe"];
    [unnamed setNameName:@""];
    [unnamed setAdditionalInfoTag:@"wikidata" value:@"Q123"];
    OASAmenity *named = [self amenity:456 subtype:@"restaurant"];
    [named setNameName:@"Actual place name"];
    [named setNameLang:@"en" name:@"Actual English name"];
    [named setNameLang:@"de" name:@"Echter Name"];
    [named setAdditionalInfoTag:@"wikidata" value:@"Q123"];
    OAPOI *first = [OAAmenitySearcher parsePOIBySharedAmenity:unnamed];
    OAPOI *second = [OAAmenitySearcher parsePOIBySharedAmenity:named];
    XCTAssertGreaterThan(first.name.length, 0u, @"The UI still has a category fallback.");
    OASAmenity *back = [OASharedAmenitySearcher sharedAmenity:first];
    XCTAssertEqualObjects([back getName], @"");
    XCTAssertEqual([back getNamesMapIncludeEn:YES].count, 0u);
    NSArray<OAPOI *> *merged = [OAAmenitySearcher filterUniqueAmenitiesByOsmIdOrWikidata:@[first, second]];
    XCTAssertEqual(merged.count, 1u);
    XCTAssertEqualObjects(merged.firstObject.name, @"Actual place name");
    XCTAssertEqualObjects(merged.firstObject.localizedNames[@"en"], @"Actual English name");
    XCTAssertEqualObjects(merged.firstObject.localizedNames[@"de"], @"Echter Name");
    XCTAssertEqualObjects([unnamed getName], @"", @"Conversion must not mutate the source.");
}

- (void)testNameConversionPreservesNativeEditsAndRemovals
{
    OASAmenity *source = [self amenity:123 subtype:@"cafe"];
    [source setNameName:@""];
    [source setNameLang:@"de" name:@"Original German name"];
    OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:source];
    poi.name = @"Edited name";
    poi.enName = @"Edited English name";
    poi.localizedNames[@"fr"] = @"Edited French name";
    [poi.localizedNames removeObjectForKey:@"de"];
    [OAAppSettings.sharedManager.settingPrefMapLanguage set:@"fr"];
    OASAmenity *back = [OASharedAmenitySearcher sharedAmenity:poi];
    XCTAssertEqualObjects([back getName], @"Edited name");
    NSDictionary *names = [back getNamesMapIncludeEn:YES];
    XCTAssertEqualObjects(names[@"en"], @"Edited English name");
    XCTAssertEqualObjects(names[@"fr"], @"Edited French name");
    XCTAssertNil(names[@"de"]);
    XCTAssertEqualObjects([source getNamesMapIncludeEn:YES][@"de"], @"Original German name");

    OAPOI *named = [OAAmenitySearcher parsePOIBySharedAmenity:[self amenity:456 subtype:@"cafe"]];
    named.name = @"";
    [named.localizedNames removeAllObjects];
    OASAmenity *cleared = [OASharedAmenitySearcher sharedAmenity:named];
    XCTAssertEqualObjects([cleared getName], @"");
    XCTAssertEqual([cleared getNamesMapIncludeEn:YES].count, 0u);
}

- (void)testRepeatedDetailsPreserveGeometryOnlyPresentInSyntheticAmenity
{
    OASAmenity *source = [self amenity:8000000000000000LL subtype:@"cafe"];
    [source setLocationLatitude:-80 longitude:-160];
    OAPOI *component = [OAAmenitySearcher parsePOIBySharedAmenity:source];
    OAPOI *synthetic = [OAAmenitySearcher parsePOIBySharedAmenity:source];
    synthetic.x = [@[@100, @101, @102] mutableCopy];
    synthetic.y = [@[@200, @201, @202] mutableCopy];
    synthetic.name = @"Combined name";
    synthetic.values[@"phone"] = @"123456";
    XCTAssertEqual(component.x.count, 0u);
    XCTAssertEqual(component.y.count, 0u);
    // This synthetic ID and location have no corresponding geometry in an installed map.
    for (NSNumber *full in @[@YES, @NO])
    {
        BaseDetailsObject *details = [[BaseDetailsObject alloc] initWithObjects:@[component] amenity:synthetic
            lang:@"en" full:full.boolValue combined:!full.boolValue];
        for (int i = 0; i < 2; i++)
        {
            BaseDetailsObject *result = [OAAmenitySearcher.sharedInstance searchDetailedObject:details];
            XCTAssertEqual(result, details);
            XCTAssertEqualObjects(result.syntheticAmenity.x, (@[@100, @101, @102]));
            XCTAssertEqualObjects(result.syntheticAmenity.y, (@[@200, @201, @202]));
            XCTAssertEqualObjects(result.syntheticAmenity.name, @"Combined name");
            XCTAssertEqualObjects(result.syntheticAmenity.values[@"phone"], @"123456");
            XCTAssertEqual(result.isObjectCombined, !full.boolValue);
        }
    }
}

- (void)testMergePreservesFirstEnglishNameIncludingNativeEdits
{
    for (NSNumber *edited in @[@NO, @YES])
    {
        OASAmenity *first = [self amenity:123 subtype:@"cafe"];
        OASAmenity *second = [self amenity:456 subtype:@"restaurant"];
        [first setNameLang:@"en" name:@"First English name"];
        [second setNameLang:@"en" name:@"Second English name"];
        [first setAdditionalInfoTag:@"wikidata" value:@"Q123"];
        [second setAdditionalInfoTag:@"wikidata" value:@"Q123"];
        OAPOI *a = [OAAmenitySearcher parsePOIBySharedAmenity:first];
        OAPOI *b = [OAAmenitySearcher parsePOIBySharedAmenity:second];
        NSString *expected = edited.boolValue ? @"Edited English name" : @"First English name";
        if (edited.boolValue)
            a.enName = expected;
        OASAmenity *converted = [OASharedAmenitySearcher sharedAmenity:a];
        XCTAssertNil([converted getNamesMapIncludeEn:NO][@"en"]);
        NSArray<OAPOI *> *merged = [OAAmenitySearcher filterUniqueAmenitiesByOsmIdOrWikidata:@[a, b]];
        XCTAssertEqual(merged.count, 1u);
        XCTAssertEqualObjects(merged.firstObject.enName, expected);
        // Compare against merging the original domain models with the same explicit edit.
        [first setNameLang:@"en" name:expected];
        NSArray<OASAmenity *> *direct = [OASharedObfResources.shared.amenitySearcher mergeAmenitiesAmenities:@[first, second]
            settings:OASharedAmenitySearcher.settings];
        XCTAssertEqual(direct.count, 1u);
        XCTAssertEqualObjects([direct.firstObject getNamesMapIncludeEn:YES][@"en"], expected);
    }
}

- (void)testNormalizedLanguageKeysPreserveEditsAndRemovals
{
    OASAmenity *source = [self amenity:123 subtype:@"cafe"];
    NSDictionary *originalNames = @{@"pt-BR": @"Original Portuguese", @" name:zh-Hant ": @"Original Chinese"};
    [source setNamesName:originalNames];
    OAPOI *poi = [OAAmenitySearcher parsePOIBySharedAmenity:source];
    XCTAssertEqualObjects(poi.localizedNames[@"pt-br"], originalNames[@"pt-BR"]);
    XCTAssertEqualObjects(poi.localizedNames[@"zh-hant"], originalNames[@" name:zh-Hant "]);
    XCTAssertEqualObjects([[OASharedAmenitySearcher sharedAmenity:poi] getNamesMapIncludeEn:YES], originalNames);
    poi.localizedNames[@"pt-br"] = @"Edited Portuguese";
    [poi.localizedNames removeObjectForKey:@"zh-hant"];
    OASAmenity *edited = [OASharedAmenitySearcher sharedAmenity:poi];
    XCTAssertEqualObjects([edited getNamesMapIncludeEn:YES], (@{@"pt-BR": @"Edited Portuguese"}));
    OAPOI *roundTrip = [OAAmenitySearcher parsePOIBySharedAmenity:edited];
    XCTAssertEqualObjects(roundTrip.localizedNames[@"pt-br"], @"Edited Portuguese");
    XCTAssertNil(roundTrip.localizedNames[@"zh-hant"]);
    [poi.localizedNames removeAllObjects];
    XCTAssertEqual([[OASharedAmenitySearcher sharedAmenity:poi] getNamesMapIncludeEn:YES].count, 0u);
    XCTAssertEqualObjects([source getNamesMapIncludeEn:YES], originalNames);
}

- (void)testResourceRefreshKeepsRepositoriesAndReplacesSearchContext
{
    OASAmenitySearcher *first = OASharedObfResources.shared.amenitySearcher;
    XCTAssertEqual(first, OASharedObfResources.shared.amenitySearcher);
    id repo = [OASharedObfResources.shared amenityRepositoryForResourceId:fixturePath.lastPathComponent];
    [OASharedObfResources.shared refreshFiles];
    XCTAssertNotEqual(first, OASharedObfResources.shared.amenitySearcher);
    XCTAssertEqual(repo, [OASharedObfResources.shared amenityRepositoryForResourceId:fixturePath.lastPathComponent]);
    XCTAssertEqual(repo, [OASharedObfResources.shared.amenitySearcher getAmenityRepositoryFileName:fixturePath.lastPathComponent]);
}

- (void)testRemovedRepositoryStopsReadingAndReinstalledResourceGetsNewRepository
{
    NSString *copy = [fixtureDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"i4_refresh_%@.obf", NSUUID.UUID.UUIDString.lowercaseString]];
    BOOL installed = NO;
    @try
    {
        NSError *error = nil;
        BOOL copied = [NSFileManager.defaultManager copyItemAtPath:fixturePath toPath:copy error:&error];
        XCTAssertTrue(copied, @"%@", error);
        if (!copied)
            return;
        installed = [OsmAndApp.instance installTestResource:copy];
        XCTAssertTrue(installed);
        [OASharedObfResources.shared refreshFiles];
        id<OASAmenityIndexRepository> old = [OASharedObfResources.shared amenityRepositoryForResourceId:copy.lastPathComponent];
        XCTAssertNotNil(old);
        XCTAssertTrue([OsmAndApp.instance removeTestResource:copy]);
        installed = NO;
        [OASharedObfResources.shared refreshFiles];
        XCTAssertNil([OASharedObfResources.shared amenityRepositoryForResourceId:copy.lastPathComponent]);
        OASSearchRequest *request = [OASSearchRequest.companion buildSearchPoiRequestSleft:0 sright:INT_MAX stop:0 sbottom:INT_MAX
            zoom:-1 poiTypeFilter:nil poiTopIndexAdditionalFilter:nil matcher:nil];
        [old searchPoiSearchRequest:request];
        XCTAssertEqual(request.getSearchResults.count, 0u);
        error = nil;
        copied = [NSFileManager.defaultManager copyItemAtPath:fixturePath toPath:copy error:&error];
        XCTAssertTrue(copied, @"%@", error);
        if (!copied)
            return;
        installed = [OsmAndApp.instance installTestResource:copy];
        XCTAssertTrue(installed);
        [OASharedObfResources.shared refreshFiles];
        id<OASAmenityIndexRepository> replacement = [OASharedObfResources.shared amenityRepositoryForResourceId:copy.lastPathComponent];
        XCTAssertNotNil(replacement);
        XCTAssertNotEqual(old, replacement);
        [replacement searchPoiSearchRequest:request];
        XCTAssertGreaterThan(request.getSearchResults.count, 0u);
    }
    @finally
    {
        if (installed)
            XCTAssertTrue([OsmAndApp.instance removeTestResource:copy]);
        [OASharedObfResources.shared refreshFiles];
    }
}

- (void)testMissingRouteMembersUseAbsentKeys
{
    NSDictionary *members = [OAAmenitySearcher.sharedInstance searchRouteMembers:@"missing-i4-route-1 missing-i4-route-2"];
    XCTAssertNotNil(members);
    XCTAssertNil(members[@"missing-i4-route-1"]);
    XCTAssertNil(members[@"missing-i4-route-2"]);
}

- (void)testAreaResultsAndWarmTimingAgainstCpp
{
    NSMutableArray<NSNumber *> *cppTimes = [NSMutableArray array];
    NSMutableArray<NSNumber *> *sharedTimes = [NSMutableArray array];
    NSMutableSet *cppIds = [NSMutableSet set];
    NSMutableSet *sharedIds = [NSMutableSet set];
    for (NSUInteger round = 0; round < 9; round++)
    {
        for (NSNumber *enabled in round % 2 ? @[@YES, @NO] : @[@NO, @YES])
        {
            [OAAppSettings.sharedManager.useSharedSearch set:enabled.boolValue];
            NSTimeInterval start = NSDate.timeIntervalSinceReferenceDate;
            NSArray<OAPOI *> *results = [self area:nil];
            double milliseconds = (NSDate.timeIntervalSinceReferenceDate - start) * 1000;
            if (round >= 2)
                [(enabled.boolValue ? sharedTimes : cppTimes) addObject:@(milliseconds)];
            NSMutableSet *ids = enabled.boolValue ? sharedIds : cppIds;
            [ids removeAllObjects];
            for (OAPOI *poi in results)
                [ids addObject:[NSString stringWithFormat:@"%llu:%@", poi.obfId, poi.subType]];
        }
    }
    [cppTimes sortUsingSelector:@selector(compare:)];
    [sharedTimes sortUsingSelector:@selector(compare:)];
    fprintf(stderr, "I4 area warm median (7 runs): C++ %.3f ms / %lu IDs; shared %.3f ms / %lu IDs\n",
            cppTimes[3].doubleValue, cppIds.count, sharedTimes[3].doubleValue, sharedIds.count);
    NSMutableSet *cppOnly = [cppIds mutableCopy];
    [cppOnly minusSet:sharedIds];
    NSMutableSet *sharedOnly = [sharedIds mutableCopy];
    [sharedOnly minusSet:cppIds];
    NSLog(@"I4 area differences: C++ only %@; shared only %@", cppOnly, sharedOnly);
    XCTAssertGreaterThan(sharedIds.count, 0u);
    XCTAssertEqualObjects(cppIds, sharedIds);
}

@end
