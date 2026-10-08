#import <XCTest/XCTest.h>
#import "OAIAPHelper.h"

static NSString *const kCounterKey = @"freeMapsAvailable";
static NSString *testCounterPath;
static NSUserDefaults *testDefaults;

@interface OAFreeMapsTestHelper : OAIAPHelper
@end

@implementation OAFreeMapsTestHelper
+ (NSString *)freeMapsCountPath { return testCounterPath; }
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
    testCounterPath = [_directory stringByAppendingPathComponent:@"counter.plist"];
}

- (void)tearDown
{
    [testDefaults removePersistentDomainForName:_suiteName];
    testDefaults = nil;
    testCounterPath = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_directory error:nil];
    [super tearDown];
}

- (void)testFreshInstallAndCounterChanges
{
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 7);
    [OAFreeMapsTestHelper decreaseFreeMapsCount];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 6);
    [OAFreeMapsTestHelper increaseFreeMapsCount:3];
    XCTAssertEqualObjects([NSDictionary dictionaryWithContentsOfFile:testCounterPath][kCounterKey], @9);

    NSNumber *excluded = nil;
    XCTAssertTrue([[NSURL fileURLWithPath:testCounterPath] getResourceValue:&excluded
                                                                  forKey:NSURLIsExcludedFromBackupKey error:nil]);
    XCTAssertEqualObjects(excluded, @YES);
}

- (void)testLegacyZeroWithoutMapsIsReplenished
{
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 7);
    XCTAssertNil([testDefaults objectForKey:kCounterKey]);
}

- (void)testExhaustedCounterIsPreservedAfterDeletingMaps
{
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:YES];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 0);
    XCTAssertNil([testDefaults objectForKey:kCounterKey]);

    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 0);
}

- (void)testMigrationPreservesRemainingAndBonusDownloads
{
    for (NSNumber *remaining in @[@3, @10, @(-1)])
    {
        [testDefaults setObject:remaining forKey:kCounterKey];
        [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
        XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], remaining.intValue);
        XCTAssertNil([testDefaults objectForKey:kCounterKey]);
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testCounterPath error:nil]);
    }
}

- (void)testRestoreAfterMigrationStartsWithSevenDownloads
{
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:YES];
    XCTAssertNil([testDefaults objectForKey:kCounterKey]);
    // Simulate a restored backup containing neither the file nor the legacy key.
    XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:testCounterPath error:nil]);
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 7);
}

- (void)testFileTakesPriorityOverStaleLegacyCounter
{
    [testDefaults setInteger:3 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    [testDefaults setInteger:0 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 3);
    XCTAssertNil([testDefaults objectForKey:kCounterKey]);
}

- (void)testFailedWriteKeepsLegacyCounter
{
    testCounterPath = [_directory stringByAppendingPathComponent:@"missing/counter.plist"];
    [testDefaults setInteger:3 forKey:kCounterKey];
    [OAFreeMapsTestHelper initializeFreeMapsCountWithMapsInstalled:NO];
    XCTAssertEqualObjects([testDefaults objectForKey:kCounterKey], @3);
    XCTAssertEqual([OAFreeMapsTestHelper freeMapsAvailable], 3);
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:testCounterPath]);
}

@end
