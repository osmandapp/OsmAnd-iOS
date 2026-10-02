//
//  OAReverseGeocoderStopTests.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"

#include <OsmAndCore/ObfsCollection.h>
#include <OsmAndCore/RoadLocator.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/ReverseGeocoder.h>

static const double kTestLatitude = 50.356646571646124;
static const double kTestLongitude = 7.5956672430038452;
static const int kNeverAbort = -1;
static const NSInteger kPendingLookupsCount = 200;
static const NSTimeInterval kStopMaxDuration = 0.05;
static const NSTimeInterval kAppInitTimeout = 60.0;
static const NSTimeInterval kLookupsDrainTimeout = 5.0;

struct OAReverseGeocoderSearchRun
{
    int polls = 0;
    int callbacks = 0;
};

static OAReverseGeocoderSearchRun runReverseGeocoderSearch(int abortFromPoll)
{
    OAReverseGeocoderSearchRun run;
    const auto obfsCollection = std::make_shared<OsmAnd::ObfsCollection>();
    const auto geocoder = std::make_shared<OsmAnd::ReverseGeocoder>(
        obfsCollection,
        std::make_shared<OsmAnd::RoadLocator>(obfsCollection));
    OsmAnd::ReverseGeocoder::Criteria criteria;
    criteria.position31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(kTestLatitude, kTestLongitude));
    const auto queryController = std::make_shared<OsmAnd::FunctorQueryController>(
        [&run, abortFromPoll]
        (const OsmAnd::FunctorQueryController* const) -> bool
        {
            const bool aborted = abortFromPoll != kNeverAbort && run.polls >= abortFromPoll;
            run.polls++;
            return aborted;
        });
    geocoder->performSearch(criteria,
        [&run]
        (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::BaseSearch::IResultEntry& resultEntry)
        {
            run.callbacks++;
        },
        queryController);
    return run;
}

@interface OAReverseGeocoderStopTests : XCTestCase

@end

@implementation OAReverseGeocoderStopTests

- (BOOL)waitForAppInitialization
{
    OsmAndAppInstance app = [OsmAndApp instance];
    XCTNSPredicateExpectation *appInitialized = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return app.initialized;
        }]
        object:nil];
    return [XCTWaiter waitForExpectations:@[appInitialized] timeout:kAppInitTimeout] == XCTWaiterResultCompleted;
}

- (void)testAbortedSearchSkipsResultCallback
{
    const auto run = runReverseGeocoderSearch(0);

    XCTAssertEqual(run.callbacks, 0);
}

- (void)testNotAbortedSearchConsultsControllerAndDeliversResult
{
    const auto run = runReverseGeocoderSearch(kNeverAbort);

    XCTAssertEqual(run.callbacks, 1);
    XCTAssertGreaterThan(run.polls, 0);
}

- (void)testSyncLookupAfterStopReturnsEmptyAddress
{
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    [geocoder stop];

    NSString *address = [geocoder lookupAddressAtLat:kTestLatitude lon:kTestLongitude];

    XCTAssertEqualObjects(address, @"");
}

- (void)testAsyncLookupAfterStopCompletesWithEmptyAddress
{
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    [geocoder stop];

    XCTestExpectation *completed = [self expectationWithDescription:@"lookup completed"];
    __block NSString *result = nil;
    [geocoder lookupAddressAtLat:kTestLatitude lon:kTestLongitude objectId:0 completion:^(NSString *address) {
        result = address;
        [completed fulfill];
    }];

    [self waitForExpectations:@[completed] timeout:kLookupsDrainTimeout];
    XCTAssertEqualObjects(result, @"");
}

- (void)testStopReturnsImmediatelyAndDrainsLookups
{
    XCTSkipUnless([self waitForAppInitialization], @"OsmAndApp is not initialized");

    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    for (NSInteger i = 0; i < kPendingLookupsCount; i++)
    {
        [geocoder lookupAddressAtLat:kTestLatitude + i * 0.001
                                 lon:kTestLongitude + i * 0.001
                            objectId:0
                          completion:^(NSString *address) {}];
    }

    CFAbsoluteTime stopStart = CFAbsoluteTimeGetCurrent();
    [geocoder stop];
    CFAbsoluteTime stopDuration = CFAbsoluteTimeGetCurrent() - stopStart;

    XCTAssertLessThan(stopDuration, kStopMaxDuration);

    NSOperationQueue *lookupQueue = [geocoder valueForKey:@"lookupQueue"];
    XCTNSPredicateExpectation *lookupsDrained = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return lookupQueue.operationCount == 0;
        }]
        object:nil];
    [self waitForExpectations:@[lookupsDrained] timeout:kLookupsDrainTimeout];
}

@end
