//
//  OASharedSearchUICoreTest.mm
//  OsmAnd MapsTests
//
//  The cases of SearchUICoreTest run through the search of the app with the shared search behind it,
//  as the search screens call it: a new phrase, a search, the results of the core once it has finished.
//  The same phrases searched by the shared search itself give the same results in the same order; what
//  differs from the expected results of the cases is counted. The C++ search runs the same phrases the
//  same way for the time each takes.
//

#import <XCTest/XCTest.h>
#import "OASharedSearchUICore.h"
#import "OASearchSettings.h"
#import "OAResultMatcher.h"
#import "OAObjectType.h"
#import "OAUtilities.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ArchiveReader.h>

#define kSearchResourcesPath @"test-resources/search"

@interface OASharedSearchUICoreTest : XCTestCase

@end

@implementation OASharedSearchUICoreTest

// the obf files of a case, unpacked next to the others of the test run, as SearchUICoreTest does
- (NSArray<NSString *> *)obfFilesOf:(NSDictionary *)json path:(NSString *)path
{
    NSMutableArray<NSString *> *gzFiles = [NSMutableArray array];
    NSString *directory = path.stringByDeletingLastPathComponent;
    if ([json[@"files"] isKindOfClass:NSArray.class])
    {
        for (NSString *file in json[@"files"])
        {
            if ([file hasSuffix:@".obf.gz"])
                [gzFiles addObject:[directory stringByAppendingPathComponent:file]];
        }
    }
    else
    {
        [gzFiles addObject:[path.stringByDeletingPathExtension stringByAppendingPathExtension:@"obf.gz"]];
    }

    NSMutableArray<NSString *> *obfFiles = [NSMutableArray array];
    for (NSString *gzFile in gzFiles)
    {
        if (![NSFileManager.defaultManager fileExistsAtPath:gzFile])
            continue;
        NSString *obfFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[gzFile.lastPathComponent stringByReplacingOccurrencesOfString:@".gz" withString:@""]];
        OsmAnd::ArchiveReader archive(QString::fromNSString(gzFile));
        bool ok = false;
        const auto items = archive.getItems(&ok, true);
        if (ok && items.size() > 0 && archive.extractItemToFile(items.first().name, QString::fromNSString(obfFile), true))
        {
            [OsmAndApp.instance installTestResource:obfFile];
            [obfFiles addObject:obfFile];
        }
    }
    return obfFiles;
}

- (NSMutableArray<NSMutableArray<NSString *> *> *)expectedResultsOf:(NSDictionary *)json phrases:(NSUInteger)count
{
    NSMutableArray<NSMutableArray<NSString *> *> *results = [NSMutableArray array];
    for (NSUInteger i = 0; i < count; i++)
        [results addObject:[NSMutableArray array]];
    for (NSString *tag in @[@"results", @"extra-results"])
    {
        NSArray *array = json[tag];
        BOOL inner = array.count > 0 && [array.firstObject isKindOfClass:NSArray.class];
        for (NSUInteger i = 0; i < array.count; i++)
        {
            if (inner && i < results.count)
                [results[i] addObjectsFromArray:array[i]];
            else if (!inner)
                [results[0] addObject:array[i]];
        }
    }
    return results;
}

// what the search screens do: a new phrase, a search, and the results of the core once it has finished
- (NSArray<OASearchResult *> *)search:(NSString *)text core:(OASearchUICore *)core millis:(double *)millis
{
    dispatch_semaphore_t finished = dispatch_semaphore_create(0);
    OAResultMatcher<OASearchResult *> *matcher = [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *result) {
        if ((*result).objectType == EOAObjectTypeSearchFinished)
            dispatch_semaphore_signal(finished);
        return YES;
    } cancelledFunc:^BOOL{
        return NO;
    }];
    NSDate *start = [NSDate date];
    [core search:text delayedExecution:NO matcher:matcher];
    long timedOut = dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (120 * NSEC_PER_SEC)));
    XCTAssertEqual(timedOut, 0, @"'%@' did not finish", text);
    if (millis)
        *millis += [[NSDate date] timeIntervalSinceDate:start] * 1000;
    return [[core getCurrentSearchResult] getCurrentSearchResults];
}

- (NSString *)format:(OASSearchResult *)result phrase:(OASSearchPhrase *)phrase
{
    return [OASSearchUICore.companion formatSearchResultForTestSimpleTest:YES r:result phrase:phrase];
}

- (void)testTheCasesOfTheSearch
{
    [self searchTheCasesWithRulesDir:nil];
}

// the java test has the cases for the classic search only: the spatial one is compared with the shared one by itself
- (void)testTheCasesOfTheSpatialSearch
{
    NSString *searchRulesDir = [NSBundle.mainBundle pathForResource:@"abbr" ofType:nil];
    XCTAssertNotNil(searchRulesDir, @"the app has the search rules");
    if (searchRulesDir)
        [self searchTheCasesWithRulesDir:searchRulesDir];
}

- (void)searchTheCasesWithRulesDir:(NSString *)searchRulesDir
{
    BOOL spatial = searchRulesDir != nil;
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSArray<NSString *> *paths = [NSBundle pathsForResourcesOfType:@"json" inDirectory:[bundle.bundlePath stringByAppendingPathComponent:kSearchResourcesPath]];
    XCTAssertGreaterThan(paths.count, 0u);
    [OsmAndApp.instance loadWorldRegions];
    [OsmAndApp.instance addRegionNamesToCommonWords];
    // the app hands the shared search its regions while it starts; the common words of the shared search
    // take the names of the regions once, at the first search
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:60];
    while (![OASOsmandRegions.companion getDefault] && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertNotNil([OASOsmandRegions.companion getDefault], @"the app has not read the regions");

    NSInteger cases = 0, phrasesCount = 0, compared = 0, notExpected = 0;
    double sharedMillis = 0, cppMillis = 0;
    NSMutableArray<NSString *> *differences = [NSMutableArray array];
    for (NSString *path in [paths sortedArrayUsingSelector:@selector(compare:)])
    {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:NSJSONReadingAllowFragments error:nil];
        NSDictionary *settingsJson = [json isKindOfClass:NSDictionary.class] ? json[@"settings"] : nil;
        if (!settingsJson || [settingsJson[@"disabled"] boolValue])
            continue;

        NSMutableArray<NSString *> *phrases = [NSMutableArray array];
        if (json[@"phrase"])
            [phrases addObject:json[@"phrase"]];
        if (json[@"phrases"])
            [phrases addObjectsFromArray:json[@"phrases"]];
        NSMutableArray<NSMutableArray<NSString *> *> *expected = [self expectedResultsOf:json phrases:phrases.count];
        NSArray<NSString *> *obfFiles = [self obfFilesOf:json path:path];
        NSMutableArray<NSString *> *resourceIds = [NSMutableArray array];
        BOOL useData = !settingsJson[@"useData"] || [settingsJson[@"useData"] boolValue];
        // the core keeps a map by its file name in lower case
        for (NSString *file in useData ? obfFiles : @[])
            [resourceIds addObject:file.lastPathComponent.lowercaseString];
        // as the java test does for the cases picking a type of POI from what an empty phrase offers
        BOOL poiTypes = NO;
        for (NSString *text in phrases)
            poiTypes = poiTypes || [text hasPrefix:@"POI_TYPE:"];
        OASSearchCoreFactory.shared.DISPLAY_DEFAULT_POI_TYPES = poiTypes;

        NSString *settingsText = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:settingsJson options:0 error:nil] encoding:NSUTF8StringEncoding];
        OASharedSearchSettings *settings = [OASharedSearchSettings settingsOfJSON:settingsText];
        [settings setOfflineIndexes:resourceIds];
        OASharedSearchUICore *core = [[OASharedSearchUICore alloc] initWithLang:@"en" transliterate:NO];
        if (spatial)
            [core initApiUseSpatialSearch:YES searchRulesDir:searchRulesDir];
        else
            [core initApi];
        [core updateSettings:settings];
        // the shared search by itself, without the app's search around it
        OASSearchUICore *direct = [[OASSearchUICore alloc] initWithPoiTypes:OAPOIHelper.sharedInstance.kPoiTypes locale:@"en" transliterate:NO];
        if (spatial)
            [direct doInitUseSpatialSearch:YES searchRulesDir:searchRulesDir];
        else
            [direct doInit];
        BOOL spatialApi = NO;
        for (id<OASSearchCoreAPI> api in [core.shared getApis])
            spatialApi = spatialApi || [(NSObject *) api isKindOfClass:OASSpatialTextSearchAPI.class];
        XCTAssertEqual(spatialApi, spatial, @"%@", path.lastPathComponent);
        [direct updateSettingsSettings:settings.shared];

        OASearchUICore *cppCore = nil;
        if (!spatial)
        {
            OASearchSettings *cppSettings = [OASearchSettings parseJSON:settingsJson];
            [cppSettings setOfflineIndexes:resourceIds];
            cppCore = [[OASearchUICore alloc] initWithLang:@"en" transliterate:NO];
            [cppCore initApi];
            [cppCore updateSettings:cppSettings];
        }

        for (NSUInteger k = 0; k < phrases.count; k++)
        {
            NSString *text = phrases[k];
            NSArray<NSString *> *parts = [text regexSplitInStringByPattern:@"[\\{}]"];
            NSArray<OASearchResult *> *results;
            OASSearchUICoreSearchResultCollection *directResults;
            [core resetPhrase];
            [direct resetPhrase];
            [cppCore resetPhrase];
            if (parts.count > 0 && [parts.firstObject isEqualToString:@"POI_TYPE:"])
            {
                // the type picked from what an empty phrase offers, then the rest typed after it
                results = [self search:@"" core:core millis:NULL];
                directResults = [direct immediateSearchText:@"" loc:nil];
                NSString *rest = parts.count > 2 ? parts[2] : @"";
                for (OASearchResult *result in results)
                {
                    if (parts.count > 1 && [parts[1] isEqualToString:result.localeName])
                    {
                        [core selectSearchResult:result];
                        [direct selectSearchResultR:result.sharedResult];
                        results = [self search:[[[core getPhrase] getText:YES] stringByAppendingString:rest] core:core millis:NULL];
                        directResults = [direct immediateSearchText:[[[direct getPhrase] getTextIncludeUnknownPart:YES] stringByAppendingString:rest] loc:nil];
                        break;
                    }
                }
            }
            else
            {
                results = [self search:text core:core millis:&sharedMillis];
                directResults = [direct immediateSearchText:text loc:nil];
                if (cppCore)
                    [self search:text core:cppCore millis:&cppMillis];
            }
            phrasesCount++;

            OASSearchPhrase *phrase = ((OASharedSearchPhrase *) [core getPhrase]).shared;
            NSMutableArray<NSString *> *viaApp = [NSMutableArray array];
            for (OASearchResult *result in results)
                [viaApp addObject:[self format:result.sharedResult phrase:phrase]];
            NSMutableArray<NSString *> *byItself = [NSMutableArray array];
            for (OASSearchResult *result in [directResults getCurrentSearchResults])
                [byItself addObject:[self format:result phrase:phrase]];
            XCTAssertEqualObjects(viaApp, byItself, @"%@ '%@'", path.lastPathComponent, text);

            for (NSUInteger i = 0; !spatial && i < expected[k].count; i++)
            {
                NSString *expectedResult = expected[k][i];
                if ([expectedResult containsString:@"["])
                    expectedResult = [expectedResult substringToIndex:[expectedResult rangeOfString:@"["].location].trim;
                if ([expectedResult hasPrefix:@"@"])
                    expectedResult = [expectedResult substringFromIndex:1];
                // org.json, which the java test reads the cases with, takes \' for '
                expectedResult = [expectedResult stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
                NSString *present = i < viaApp.count ? viaApp[i] : [NSString stringWithFormat:@"#MISSING %lu", (unsigned long) i + 1];
                compared++;
                if (![expectedResult isEqualToString:present])
                {
                    notExpected++;
                    [differences addObject:[NSString stringWithFormat:@"%@ '%@' %lu: expected '%@', found '%@'", path.lastPathComponent, text, (unsigned long) i + 1, expectedResult, present]];
                }
            }
        }
        cases++;
        OASSearchCoreFactory.shared.DISPLAY_DEFAULT_POI_TYPES = NO;
        for (NSString *obfFile in obfFiles)
            [NSFileManager.defaultManager removeItemAtPath:obfFile error:nil];
    }

    NSLog(@"OASharedSearchUICoreTest%@: %ld cases, %ld phrases, %ld results compared, %ld not the ones expected; shared %.0f ms, C++ %.0f ms (without the POI_TYPE phrases)\n%@",
          spatial ? @" (spatial)" : @"", (long) cases, (long) phrasesCount, (long) compared, (long) notExpected, sharedMillis, cppMillis, [differences componentsJoinedByString:@"\n"]);
    XCTAssertGreaterThan(cases, 0);
}

@end
