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
#import "QuadRect.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/ArchiveReader.h>

@interface OASharedSearchFacadeTest : XCTestCase

@end

@implementation OASharedSearchFacadeTest

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
    return obf;
}

- (void)testEveryKindOfResultOfTheAppHasTheSameOneInTheSharedSearch
{
    for (NSInteger i = EOAObjectTypeCity; i <= EOAObjectTypeIndexItem; i++)
    {
        EOAObjectType type = (EOAObjectType) i;
        OASObjectType *shared = [OASharedSearchObjects sharedObjectType:type];
        XCTAssertNotNil(shared, @"%ld", (long) type);
        XCTAssertEqual([OASharedSearchObjects appObjectType:shared], type, @"%ld %@", (long) type, shared.name);
    }
    XCTAssertEqual([OASharedSearchObjects appObjectType:nil], EOAObjectTypeUndefined);
    for (OASObjectType *shared in @[OASObjectType.route, OASObjectType.mapMarker, OASObjectType.onlineSearch, OASObjectType.suggestion])
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

    [OASharedSearchReaders.shared retireReadersAfter:core.shared];
    // made after the change, of settings made before it
    OASharedSearchSettings *madeAfter = [[OASharedSearchSettings alloc] initWithShared:[[OASSearchSettings alloc] initWithS:settings.shared]];
    OASBinaryMapIndexReader *after = [[madeAfter sharedWithCurrentReaders] getOfflineIndexes].firstObject;
    XCTAssertNotNil(after);
    XCTAssertNotEqual(after, before, @"a retired reader is not read again");
    XCTAssertEqual([[ofPhrase sharedWithCurrentReaders] getOfflineIndexes].firstObject, after);

    // once the retired reader is closed, after the searches of the core, its map is still known
    XCTestExpectation *searchesEnded = [self expectationWithDescription:@"searches ended"];
    [core.shared runAfterSearchTask:^{
        [searchesEnded fulfill];
    }];
    [self waitForExpectations:@[searchesEnded] timeout:10];
    XCTAssertEqualObjects([OASharedSearchReaders.shared resourceIdsOf:@[before]], @[resourceId]);
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
    return [[core shallowSearch:OASearchAmenityByTypeAPI.class text:[[core getPhrase] getText:YES] matcher:nil resortAll:YES removeDuplicates:YES] getCurrentSearchResults];
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
    for (OASearchResult *result in [[classic shallowSearch:OASearchAmenityByNameAPI.class text:@"Union Turnpike" matcher:nil] getCurrentSearchResults])
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

@end
