//
//  OASharedSearchContextTest.mm
//  OsmAnd MapsTests
//
//  What the app hands the shared search: the names of the poi types out of its own phrases, and the
//  files to read in the order the search of the app reads them.
//

#import <XCTest/XCTest.h>
#import "OAPOIHelper.h"
#import "OAObfFileList.h"
#import "OAUtilities.h"
#import "OsmAndSharedWrapper.h"

@interface OASharedSearchContextTest : XCTestCase

@end

@implementation OASharedSearchContextTest

- (void)testATypeIsNamedByThePhrasesOfTheApp
{
    OAPOIHelper *helper = OAPOIHelper.sharedInstance;
    OASMapPoiTypes *types = helper.kPoiTypes;
    id<OASPoiTranslator> translator = [types getPoiTranslator];
    XCTAssertNotNil(translator);

    OASPoiType *cafe = [types getPoiTypeByKeyName:@"cafe"];
    XCTAssertNotNil(cafe);
    NSString *phrase = [helper getPhraseByName:@"cafe" withDefatultValue:NO];
    XCTAssertNotNil(phrase, @"the app has a name for a cafe");
    XCTAssertEqualObjects([cafe getTranslation], phrase);
    XCTAssertEqualObjects([translator getEnTranslationType:cafe], [helper getPhraseENByName:@"cafe"]);
    XCTAssertEqualObjects([translator getSynonymsType:cafe], [helper getSynonymsByName:@"cafe"]);
}

- (void)testAKeyWithoutAPhraseHasNoName
{
    id<OASPoiTranslator> translator = [OAPOIHelper.sharedInstance.kPoiTypes getPoiTranslator];
    XCTAssertNil([translator getTranslationKeyName:@"no_such_poi_type"]);
    XCTAssertNil([translator getEnTranslationKeyName:@"no_such_poi_type"]);
    XCTAssertEqualObjects([translator getSynonymsKeyName:@"no_such_poi_type"], @"");
}

- (void)testATypeOfALanguageIsNamedByItsBaseAndTheLanguage
{
    OASMapPoiTypes *types = OAPOIHelper.sharedInstance.kPoiTypes;
    id<OASPoiTranslator> translator = [types getPoiTranslator];
    OASAbstractPoiType *nameDe = [types getAnyPoiAdditionalTypeByKeyName:@"name:de"];
    OASAbstractPoiType *name = [nameDe getBaseLangType];
    XCTAssertNotNil(name, @"name:de is the name in German");

    NSString *baseName = [translator getTranslationType:name] ?: [types getBasePoiNameAbstractPoiType:name];
    NSString *language = [OAUtilities translatedLangName:@"de"].lowercaseString;
    XCTAssertEqualObjects([translator getTranslationType:nameDe], ([NSString stringWithFormat:@"%@ (%@)", baseName, language]));
}

- (void)testATranslatorOfAnotherLanguageReadsItsPhrases
{
    OASMapPoiTypes *types = OAPOIHelper.sharedInstance.kPoiTypes;
    id<OASPoiTranslator> german = [[types getPoiTranslator] getTranslatorLang:@"de"];
    XCTAssertNotNil(german);

    NSString *phrase = [OAPOIHelper loadPhraseFileForLanguage:@"de"][@"poi_cafe"];
    XCTAssertNotNil(phrase, @"the German phrases name a cafe");
    NSString *expected = [phrase componentsSeparatedByString:@";"].firstObject;
    XCTAssertEqualObjects([german getTranslationType:[types getPoiTypeByKeyName:@"cafe"]], expected);
    XCTAssertNil([[types getPoiTranslator] getTranslatorLang:@"xx"], @"no phrases for a language the app does not have");
}

- (void)testARegionsFileThatCannotBeReadIsAnErrorNotACrash
{
    NSString *ocbf = [NSHomeDirectory() stringByAppendingString:@"/Documents/Resources/regions.ocbf"];
    NSData *data = [NSData dataWithContentsOfFile:ocbf];
    XCTAssertNotNil(data, @"the app keeps regions.ocbf in its resources");

    NSString *damaged = [NSTemporaryDirectory() stringByAppendingPathComponent:@"damaged-regions.ocbf"];
    XCTAssertTrue([[data subdataWithRange:NSMakeRange(0, data.length / 2)] writeToFile:damaged atomically:YES]);
    NSString *missing = [NSTemporaryDirectory() stringByAppendingPathComponent:@"missing-regions.ocbf"];
    for (NSString *path in @[damaged, missing])
    {
        NSError *error = nil;
        XCTAssertNil([[[OASOsmandRegions alloc] initWithIsInitialized:NO] prepareFileFileName:path error:&error], @"%@", path);
        XCTAssertNotNil(error, @"%@", path);
    }
    [NSFileManager.defaultManager removeItemAtPath:damaged error:nil];
}

- (void)testTheLiveUpdateOfARegionGoesBeforeTheRegion
{
    NSArray<NSString *> *sorted = [OAObfFileList sortedForSearch:@[@"germany_berlin_europe.obf", @"germany_berlin_europe_25_10_28.live.obf"]];
    XCTAssertEqualObjects(sorted, (@[@"germany_berlin_europe_25_10_28.live.obf", @"germany_berlin_europe.obf"]));
}

- (void)testTheSearchFilesAreTheFilesOfTheSearchIdsInTheirOrder
{
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSString *path in [OAObfFileList searchFilePathsIncludingTravel:YES])
        [names addObject:path.lastPathComponent.lowercaseString];
    if (names.count == 0)
        XCTSkip(@"no maps installed");

    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (NSString *resourceId in [OAObfFileList searchResourceIdsIncludingTravel:YES])
    {
        if ([names containsObject:resourceId.lowercaseString])
            [ids addObject:resourceId.lowercaseString];
    }
    XCTAssertEqualObjects(names, ids);
}

- (void)testTravelFilesAreLeftOutWhenAskedTo
{
    NSPredicate *isTravel = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[c] '.travel.obf'"];
    NSArray<NSString *> *withTravel = [OAObfFileList searchResourceIdsIncludingTravel:YES];
    NSArray<NSString *> *travel = [withTravel filteredArrayUsingPredicate:isTravel];
    if (travel.count == 0)
        XCTSkip(@"no travel files installed");

    NSMutableSet<NSString *> *expected = [NSMutableSet setWithArray:withTravel];
    [expected minusSet:[NSSet setWithArray:travel]];
    XCTAssertEqualObjects([NSSet setWithArray:[OAObfFileList searchResourceIdsIncludingTravel:NO]], expected);
}

@end
