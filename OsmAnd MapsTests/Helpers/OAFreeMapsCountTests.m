#import <XCTest/XCTest.h>
#import "OAIAPHelper.h"

static NSString *const kCounterKey = @"freeMapsAvailable";
static NSString *const kMarkerCreatedKey = @"freeMapsMarkerCreated";
static NSString *testMarkerPath;
static NSUserDefaults *testDefaults;

@interface OAFreeMapsTestHelper : OAIAPHelper
@end

@implementation OAFreeMapsTestHelper
+ (NSString *)freeMapsMarkerPath { return testMarkerPath; }
+ (NSUserDefaults *)freeMapsCountDefaults { return testDefaults; }
@end

@interface OAFreeMapsCountTests : XCTestCase
@end

@implementation OAFreeMapsCountTests
{
    NSString *_suiteName;
    NSString *_directory;
}

- (void)setUp
{
    [super setUp];
    _suiteName = NSUUID.UUID.UUIDString;
    testDefaults = [[NSUserDefaults alloc] initWithSuiteName:_suiteName];
    _directory = [NSTemporaryDirectory() stringByAppendingPathComponent:_suiteName];
    XCTAssertTrue([[NSFileManager defaultManager] createDirectoryAtPath:_directory
                                          withIntermediateDirectories:YES attributes:nil error:nil]);
    testMarkerPath = [_directory stringByAppendingPathComponent:@"freeMapsCount.marker"];
}

- (void)tearDown
{
    [testDefaults removePersistentDomainForName:_suiteName];
    testDefaults = nil;
    testMarkerPath = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_directory error:nil];
    [super tearDown];
}

- (void)testFreshInstallCreatesMarker
{
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertNil([testDefaults objectForKey:kCounterKey]);
    XCTAssertTrue([testDefaults boolForKey:kMarkerCreatedKey]);
    XCTAssertEqualObjects([NSData dataWithContentsOfFile:testMarkerPath], [NSData data]);

    NSNumber *excluded = nil;
    XCTAssertTrue([[NSURL fileURLWithPath:testMarkerPath] getResourceValue:&excluded
                                                                  forKey:NSURLIsExcludedFromBackupKey error:nil]);
    XCTAssertEqualObjects(excluded, @YES);
}

- (void)testLegacyExhaustedCounterWithoutMapsIsReplenished
{
    for (NSNumber *remaining in @[@0, @(-1), @(-2)])
    {
        [testDefaults removePersistentDomainForName:_suiteName];
        [testDefaults setObject:remaining forKey:kCounterKey];
        [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
        XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @7);
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testMarkerPath error:nil]);
    }
}

- (void)testExhaustedCounterIsPreservedAfterDeletingMaps
{
    for (NSNumber *remaining in @[@0, @(-1)])
    {
        [testDefaults removePersistentDomainForName:_suiteName];
        [testDefaults setObject:remaining forKey:kCounterKey];
        [OAFreeMapsTestHelper initializeFreeMapsCount:YES];
        XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], remaining);

        [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
        XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], remaining);
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testMarkerPath error:nil]);
    }
}

- (void)testUpdatePreservesRemainingAndBonusDownloads
{
    for (NSNumber *remaining in @[@3, @10])
    {
        [testDefaults removePersistentDomainForName:_suiteName];
        [testDefaults setObject:remaining forKey:kCounterKey];
        [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
        XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], remaining);
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testMarkerPath error:nil]);
    }
}

- (void)testRestoreResetsAnyCounterRegardlessOfInstalledMaps
{
    // A restored backup contains the flag and counter, but no marker.
    [testDefaults setBool:YES forKey:kMarkerCreatedKey];
    for (NSNumber *mapsInstalled in @[@NO, @YES])
    {
        for (NSNumber *remaining in @[@(-2), @0, @3, @10])
        {
            [testDefaults setObject:remaining forKey:kCounterKey];
            [OAFreeMapsTestHelper initializeFreeMapsCount:mapsInstalled.boolValue];
            XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @7);
            XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testMarkerPath error:nil]);
        }
    }
}

- (void)testSettingsResetRestoresFlagWithoutResettingCounter
{
    [OAFreeMapsTestHelper initializeFreeMapsCount:YES];
    // reset_settings clears the defaults domain but preserves the counter.
    [testDefaults removePersistentDomainForName:_suiteName];
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @0);
    XCTAssertTrue([testDefaults boolForKey:kMarkerCreatedKey]);

    XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testMarkerPath error:nil]);
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @7);
}

- (void)testExistingMarkerBackupExclusionIsRetried
{
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertTrue([[NSURL fileURLWithPath:testMarkerPath] setResourceValue:@NO
                                                                 forKey:NSURLIsExcludedFromBackupKey error:nil]);
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @0);
    NSNumber *excluded = nil;
    XCTAssertTrue([[NSURL fileURLWithPath:testMarkerPath] getResourceValue:&excluded
                                                                  forKey:NSURLIsExcludedFromBackupKey error:nil]);
    XCTAssertEqualObjects(excluded, @YES);
}

- (void)testFailedMarkerCreationPreservesCounterAndFlag
{
    NSString *validPath = testMarkerPath;
    testMarkerPath = [_directory stringByAppendingPathComponent:@"missing/freeMapsCount.marker"];
    for (NSNumber *restored in @[@NO, @YES])
    {
        [testDefaults setBool:restored.boolValue forKey:kMarkerCreatedKey];
        [testDefaults setInteger:0 forKey:kCounterKey];
        [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
        XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @0);
        XCTAssertEqualObjects([testDefaults objectForKey:kMarkerCreatedKey], restored);
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:testMarkerPath]);
    }

    testMarkerPath = validPath;
    [OAFreeMapsTestHelper initializeFreeMapsCount:NO];
    XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @7);
    XCTAssertTrue([testDefaults boolForKey:kMarkerCreatedKey]);
}

@end
