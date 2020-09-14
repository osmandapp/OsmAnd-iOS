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
#include <common.cpp>

#define kSearchResourcesPath @"test-resources/search"

static BOOL TEST_EXTRA_RESULTS = YES;

@interface SearchUICoreTest : XCTestCase

@end

@implementation SearchUICoreTest
{
    NSArray<NSString *> *_filePaths;
    
    std::shared_ptr<OsmAnd::ResourcesManager> resourcesManager;
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
    for (NSString *path in _filePaths)
        [self testSearchCase:path];

    NSLog(@"Search tests done");
}

- (void) testSearchCase:(NSString *)path
{
    NSLog(@"Testing case: %@", path.lastPathComponent);

    NSString *jsonFile = path;
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
    //        BinaryMapIndexReader reader = null;
    [OsmAndApp.instance installTestResource:obfFile];
    BOOL useData = [settingsJson[@"useData"] boolValue];
    if (useData)
    {
        
        //Assert.assertTrue(obfZipFileExists);
        //            OsmAnd::ArchiveReader archive(QString::fromNSString(obfZipFile));
        //            BOOL ok = NO;
        //            const auto archiveItems = archive.getItems(&ok, false);
        //            XCTAssertTrue(ok);
        //            XCTAssertTrue(archiveItems.size() == 1);
        //
        //            for (const auto& archiveItem : constOf(archiveItems))
        //            {
        //                obfFile = [tempDir stringByAppendingPathComponent:archiveItem.name.toNSString()];
        //                XCTAssertTrue(archive.extractItemToFile(archiveItem.name, QString::fromNSString(obfFile)));
        //            }
        
        //            reader = new BinaryMapIndexReader(new RandomAccessFile(obfFile.getPath(), "r"), obfFile);
    }
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
        return;
    
    OASearchSettings *s = [OASearchSettings parseJSON:settingsJson];
    [s setOfflineIndexes:@[[obfFile lastPathComponent]]];
    
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
        BOOL passed = YES;
        NSString *text = phrases[k];
        NSArray<NSString *> *result = results[k];
        OASearchPhrase *phrase = [emptyPhrase generateNewPhrase:text settings:s];
        OASearchResultMatcher *matcher = [[OASearchResultMatcher alloc] initWithMatcher:rm phrase:phrase request:1 requestNumber:[OAAtomicInteger atomicInteger:1] totalLimit:-1];
        [core searchInBackground:phrase matcher:matcher];
        
        OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
        [collection addSearchResults:matcher.getRequestResults resortAll:YES removeDuplicates:YES];
        NSArray<OASearchResult *> *searchResults = collection.getCurrentSearchResults;
        for(NSInteger i = 0; i < result.count; i++)
        {
            NSString *expected = result[i];
            OASearchResult *res = i >= searchResults.count ? nil : searchResults[i];
            if (simpleTest && [expected indexOf:@"["] != -1)
                expected = [expected substringToIndex:[expected indexOf:@"["]].trim;
            //                String present = result.toString();
            NSString *present = res == nil ? [NSString stringWithFormat:@"#MISSING %ld", i+1] : [self formatResult:simpleTest res:res phrase:phrase];
            if (![expected isEqualToString:present])
            {
                NSLog(@"Phrase: %@", [phrase toString]);
                NSLog(@"Mismatch for '%@' != '%@'. Result: ", expected, present);
                for (OASearchResult *r : searchResults)
                {
                    NSLog(@"\t\"%@\",", [self formatResult:NO res:r phrase:phrase]);
                }
                passed = NO;
                break;
            }
            XCTAssertEqualObjects(expected, present);
        }
        NSLog(@"Test phrase: %@ done (%@)", [phrase toString], passed ? @"PASSED" : @"FAILED");
    }
    // Do not use this map for future searches
    //[OsmAndApp.instance removeTestResource:obfFile];
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

@end
