//
//  SearchUICoreTest.m
//  OsmAndMapsTests
//
//  Created by Paul on 08.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OASearchSettings.h"
#import "OASearchUICore.h"
#import "OASearchPhrase.h"
#import "OASearchCoreFactory.h"
#import "OASearchWord.h"
#import "OAResultMatcher.h"
#import "OASearchResultMatcher.h"
#import "OAAtomicInteger.h"
#import "OAUtilities.h"
#import "OAObjectType.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/stdlib_common.h>
#include <OsmAndCore/QtExtensions.h>
#include <QString>
#include <QList>
#include <QDateTime>
#define _OSMAND_LOGGING_H_
#include <common.cpp>
#undef _OSMAND_LOGGING_H_

#define kSearchResourcesPath @"test-resources/search"

static BOOL TEST_EXTRA_RESULTS = YES;

@interface SearchUICoreTest : XCTestCase

@end

@implementation SearchUICoreTest
{
    NSArray<NSString *> *_filePaths;
    std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
    NSInteger _successCount;
    NSInteger _failedCount;
    NSInteger _firstResultCount;
    NSInteger _missingCount;
}

- (void) setUp
{
    [self defaultSetup];
}

- (void) defaultSetup
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//    NSString *path = [bundle pathForResource:@"poi_types" ofType:@"xml"];
    _filePaths = [NSBundle pathsForResourcesOfType:@"json" inDirectory:[[bundle bundlePath] stringByAppendingPathComponent:kSearchResourcesPath]];
}

- (void) tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testSearch
{
    _successCount = 0;
    _failedCount = 0;
    _firstResultCount = 0;
    _missingCount = 0;
    [OsmAndApp.instance loadWorldRegions];
    [OsmAndApp.instance addRegionNamesToCommonWords];
    [OsmAndApp.instance addAbbrevationsToCommonWords];
    for (NSString *path in _filePaths)
    {
        //if ([path.lastPathComponent isEqualToString:@"getmana.json"])
            [self testSearchCase:path];
    }
    NSLog(@"========================================");
    NSLog(@"Search tests done!");
    NSLog(@"SUCCESS: %ld", (long)_successCount);
    NSLog(@"FAILED:  %ld (total)", (long)_failedCount);
    NSLog(@"FAILED:  %ld (first result is matched)", (long)_firstResultCount);
    NSLog(@"FAILED:  %ld (totally missing)", (long)_missingCount);
    NSLog(@"========================================");
    NSLog(@"Search tests done");
}

- (void) testSearchCase:(NSString *)path
{
    NSLog(@"Testing case: %@", path.lastPathComponent);

    NSString *jsonFile = path;
    NSString *obfGzFile = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"obf.gz"];
    NSString *obfFile = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"obf"];
    //        NSString *obfZipFile = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"obf.gz"];
    NSError *err = nil;
    NSString *sourceJsonText = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:&err];
    XCTAssertNil(err);
    XCTAssertNotNil(sourceJsonText);
    XCTAssertTrue(sourceJsonText.length > 0);
    
    NSError *error;
    NSDictionary *sourceJson = [NSJSONSerialization JSONObjectWithData:[sourceJsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    XCTAssertNil(error);
    // this is not a search test, simply skip it
    if ([sourceJson isKindOfClass:NSArray.class])
        return;
    
    NSArray *phrasesJson = sourceJson[@"phrases"];
    NSString *singlePhrase = sourceJson[@"phrase"];
    NSMutableArray<NSString *> *phrases = [NSMutableArray new];
    if (singlePhrase != nil)
        [phrases addObject:singlePhrase];
    
    if (phrasesJson != nil)
    {
        for (NSInteger i = 0; i < phrasesJson.count; i++)
        {
            NSString *phrase = phrasesJson[i];
            [phrases addObject:phrase];
        }
    }
    NSDictionary *settingsJson = sourceJson[@"settings"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *filesJson = sourceJson[@"files"];
    NSString *currentDirectory = [path stringByDeletingLastPathComponent];
    NSMutableArray<NSString *> *obfFilePaths = [NSMutableArray array];
    NSString *tempDir = NSTemporaryDirectory();

    if (filesJson && [filesJson isKindOfClass:[NSArray class]])
    {
        for (NSString *fileName in filesJson)
        {
            if ([fileName isKindOfClass:[NSString class]] && [fileName hasSuffix:@".obf.gz"])
            {
                NSString *gzFilePath = [currentDirectory stringByAppendingPathComponent:fileName];
                NSString *obfName = [fileName stringByReplacingOccurrencesOfString:@".gz" withString:@""];
                NSString *destObfPath = [tempDir stringByAppendingPathComponent:obfName];

                OsmAnd::ArchiveReader archive(QString::fromNSString(gzFilePath));
                bool ok = false;
                const auto archiveItems = archive.getItems(&ok, true);

                XCTAssertTrue(ok, @"Failed to open archive %@", gzFilePath);

                if (ok && archiveItems.size() > 0)
                {
                    const auto& archiveItem = archiveItems.first();
                    bool extracted = archive.extractItemToFile(archiveItem.name, QString::fromNSString(destObfPath), true);
                    XCTAssertTrue(extracted, @"Failed to extract target OBF from gz");
                    if (extracted)
                    {
                        [obfFilePaths addObject:destObfPath];
                    }
                }
            }
        }
    }
    else if ([fileManager fileExistsAtPath:obfGzFile])
    {
        NSString *extractedObfPath = [tempDir stringByAppendingPathComponent:[obfFile lastPathComponent]];
        OsmAnd::ArchiveReader archive(QString::fromNSString(obfGzFile));
        bool ok = false;
        const auto archiveItems = archive.getItems(&ok, true);

        XCTAssertTrue(ok, @"Failed to open archive %@", obfGzFile);

        if (ok && archiveItems.size() > 0)
        {
            const auto& archiveItem = archiveItems.first();
            bool extracted = archive.extractItemToFile(archiveItem.name, QString::fromNSString(extractedObfPath), true);
            XCTAssertTrue(extracted, @"Failed to extract target OBF from gz");
            if (extracted)
            {
                [obfFilePaths addObject:extractedObfPath];
            }
        }
    }

    if (obfFilePaths.count == 0 && [fileManager fileExistsAtPath:obfFile])
    {
        [obfFilePaths addObject:obfFile];
    }

    if (obfFilePaths.count == 0)
    {
        XCTFail(@"No OBF files found or extracted for test: %@", path.lastPathComponent);
        _failedCount++;
        return;
    }

    [OsmAndApp.instance installTestResources:obfFilePaths];

    NSMutableArray<NSMutableArray<NSString *> *> *results = [NSMutableArray new];
    for (NSInteger i = 0; i < phrases.count; i++)
    {
        [results addObject:[NSMutableArray new]];
    }

    if (sourceJson[@"results"])
        [self parseResults:sourceJson tag:@"results" results:results];
    
    if (TEST_EXTRA_RESULTS && sourceJson[@"extra-results"])
        [self parseResults:sourceJson tag:@"extra-results" results:results];
    
    XCTAssertEqual(phrases.count, results.count);
    if (phrases.count != results.count)
    {
        _failedCount++;
        return;
    }

    NSMutableArray<NSString *> *offlineIndexNames = [NSMutableArray array];
    for (NSString *filePath in obfFilePaths)
    {
        [offlineIndexNames addObject:[filePath lastPathComponent]];
    }

    OASearchSettings *s = [OASearchSettings parseJSON:settingsJson];
    [s setOfflineIndexes:offlineIndexNames];
    OASearchUICore *core = [[OASearchUICore alloc] initWithLang:@"en" transliterate:NO];
    [core initApi];
    
    OAResultMatcher<OASearchResult *> *rm = [[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
        return true;
    } cancelledFunc:^BOOL{
        return false;
    }];
    
    BOOL simpleTest = YES;
    OASearchPhrase *emptyPhrase = [OASearchPhrase emptyPhrase:s];
    for (NSInteger k = 0; k < phrases.count; k++)
    {
        NSString *text = phrases[k];
        NSArray<NSString *> *result = results[k];
        NSArray<OASearchResult *> *searchResults;
        OASearchPhrase *phrase;
        NSArray<NSString *> *arr = [text regexSplitInStringByPattern:@"[\\{}]"];
        if (arr.count > 0 && [arr.firstObject isEqualToString:@"POI_TYPE:"])
        {
            [OASearchCoreFactory setDisplayDefaultPoiTypes:YES];
            phrase = [emptyPhrase generateNewPhrase:@"" settings:s];
            searchResults = [self getSearchResult:phrase rm:rm core:core];
            for (OASearchResult *searchResult in searchResults)
            {
                if (arr.count > 1 && [arr[1] isEqualToString:searchResult.localeName])
                {
                    NSString *fullText = @"";
                    if (arr.count > 2)
                        fullText = arr[2];
                
                    phrase = [emptyPhrase generateNewPhrase:fullText settings:s];
                    [phrase.getWords addObject:[[OASearchWord alloc] initWithWord:searchResult.localeName res:searchResult]];
                    searchResults = [self getSearchResult:phrase rm:rm core:core];
                    break;
                }
            }
            [OASearchCoreFactory setDisplayDefaultPoiTypes:NO];
        }
        else
        {
            phrase = [emptyPhrase generateNewPhrase:text settings:s];
            searchResults = [self getSearchResult:phrase rm:rm core:core];
        }
        for (NSInteger i = 0; i < result.count; i++)
        {
            NSString *expected = result[i];
            if (simpleTest && [expected indexOf:@"["] != -1) {
                expected = [expected substringToIndex:[expected indexOf:@"["]].trim;
            }
            OASearchResult *res = i >= searchResults.count ? nil : searchResults[i];
            NSString *present = (res == nil) ? [NSString stringWithFormat:@"#MISSING %ld", i + 1] : [self formatResult:simpleTest res:res phrase:phrase];
            expected = [expected stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
            present = [present stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];

            if ([expected caseInsensitiveCompare:present] != NSOrderedSame && ![self sameToDuplicate:result[i] res:res phrase:phrase])
            {
                NSLog(@"Phrase: %@", [phrase toString]);
                NSLog(@"Mismatch for '%@' != '%@'. Result: ", expected, present);
                NSLog(@"CURRENT RESULTS: ");
                int limit = (int)result.count;
                int cnt = 1;
                for (OASearchResult *r : searchResults)
                {
                    NSLog(@"\t\"%@\",", [self formatResult:NO res:r phrase:phrase]);
                    cnt++;
                    if (cnt > limit)
                        break;
                }
                NSLog(@"EXPECTED: ");
                for (NSString *exp in result)
                {
                    NSLog(@"\t\"%@\",", exp);
                }
                _failedCount++;
                if (i > 0)
                {
                    _firstResultCount++;
                }
                if (res == nil && i == 0)
                {
                    _missingCount++;
                }

                for (NSString *fileToRemove in obfFilePaths)
                {
                    if ([fileToRemove hasPrefix:tempDir])
                    {
                        [fileManager removeItemAtPath:fileToRemove error:nil];
                    }
                }
                XCTFail(@"Test failed due to mismatch");
                return;
            }
        }
        NSLog(@"Test phrase: %@ done (%@)", [phrase toString], @"PASSED");
    }

    _successCount++;

    for (NSString *fileToRemove in obfFilePaths)
    {
        if ([fileToRemove hasPrefix:tempDir])
        {
            [fileManager removeItemAtPath:fileToRemove error:nil];
        }
    }
}

- (NSArray<OASearchResult *> *) getSearchResult:(OASearchPhrase *)phrase rm:(OAResultMatcher<OASearchResult *> *)rm core:(OASearchUICore *)core
{
    OASearchResultMatcher *matcher = [[OASearchResultMatcher alloc] initWithMatcher:rm phrase:phrase request:1 requestNumber:[OAAtomicInteger atomicInteger:1] totalLimit:-1];
    [core searchInBackground:phrase matcher:matcher];
    OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
    [collection addSearchResults:matcher.getRequestResults resortAll:YES removeDuplicates:YES];
    
    return collection.getCurrentSearchResults;
}

- (void) parseResults:(NSDictionary *)sourceJson tag:(NSString *)tag results:(NSMutableArray<NSMutableArray<NSString *> *> *)results
{
    NSMutableArray<NSString *> *result = results[0];
    NSArray *resultsArr = sourceJson[tag];
    BOOL hasInnerArray = resultsArr.count > 0 && resultsArr.firstObject != nil && [resultsArr.firstObject isKindOfClass:NSArray.class];
    for (NSInteger i = 0; i < resultsArr.count; i++)
    {
        if (hasInnerArray)
        {
            NSArray *innerArray = resultsArr[i];
            if (innerArray != nil && results.count > i)
            {
                result = results[i];
                for (NSInteger k = 0; k < innerArray.count; k++)
                {
                    [result addObject:innerArray[k]];
                }
            }
        }
        else
        {
            if (![resultsArr[i] containsString:@"[[ios, "])
                [result addObject:resultsArr[i]];
        }
    }
}

- (NSString *) formatResult:(BOOL)simpleTest res:(OASearchResult *)r phrase:(OASearchPhrase *)phrase
{
    if (simpleTest)
        return [r toString].trim;
    double dist = 0;
    if(r.location != nil)
        dist = getDistance(r.location.coordinate.latitude, r.location.coordinate.longitude, phrase.getLastTokenLocation.coordinate.latitude, phrase.getLastTokenLocation.coordinate.longitude);
    return [NSString stringWithFormat:@"%@ [[%d, %@, %.3f, %.2f km]]", [r toString],
            r.getFoundWordCount, [OAObjectType toString:r.objectType],
            r.unknownPhraseMatchWeight,
            dist / 1000
            ];
}

- (BOOL) sameToDuplicate:(NSString *)expected res:(OASearchResult *)res phrase:(OASearchPhrase *)phrase
{
    NSString * quotes1 = [expected substringFromIndex:[expected indexOf:@"["]].trim;
    NSString * fullPresent = (res == nil) ? @"" : [self formatResult:NO res:res phrase:phrase];
    NSString * quotes2 = [fullPresent substringFromIndex:[fullPresent indexOf:@"["]].trim;
    if ([quotes1 containsString:@"LOCATION"]
        && [quotes2 containsString:@"LOCATION"]
        && [quotes1 isEqual:quotes2])
    {
        return YES;
    }
    NSString * part1 = [expected substringToIndex:[expected indexOf:@","]].trim;
    part1 = [part1 stringByReplacingOccurrencesOfString:@"@" withString:@""];// geocoding
    if ([part1 indexOf:@"("] != -1)
    {
        part1 = [part1 substringToIndex:[part1 indexOf:@"("]].trim;
    }
    NSString * part2 = [fullPresent substringToIndex:[fullPresent indexOf:@","]].trim;
    if ([part2 indexOf:@"("] != -1)
    {
        part2 = [part2 substringToIndex:[part2 indexOf:@"("]].trim;
    }
    if ([quotes1 isEqual:quotes2] && [part1 isEqual:part2])
        return YES;

    NSString * partial1 = [expected substringToIndex:[expected indexOf:@"["]].trim;
    NSString * partial2 = [fullPresent substringToIndex:[fullPresent indexOf:@"["]].trim;
    partial1 = [partial1 stringByReplacingOccurrencesOfString:@"(" withString:@""];
    partial1 = [partial1 stringByReplacingOccurrencesOfString:@"," withString:@""];
    partial2 = [partial2 stringByReplacingOccurrencesOfString:@"(" withString:@""];
    partial2 = [partial2 stringByReplacingOccurrencesOfString:@"," withString:@""];
    long length = min(partial1.length, partial2.length);
    return [[partial1 substringToIndex:length] isEqualToString:[partial2 substringToIndex:length]];
}

@end
