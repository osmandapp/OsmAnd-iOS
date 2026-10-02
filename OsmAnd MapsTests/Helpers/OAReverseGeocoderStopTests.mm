//
//  OAReverseGeocoderStopTests.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import "OAReverseGeocoder.h"

#include <OsmAndCore/ObfsCollection.h>
#include <OsmAndCore/RoadLocator.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/ReverseGeocoder.h>

static const double kTestLatitude = 50.356646571646124;
static const double kTestLongitude = 7.5956672430038452;
static const int kNeverAbort = -1;
static const NSTimeInterval kLookupTimeout = 5.0;

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

- (void)testAbortedSearchSkipsResultCallback
{
    const auto run = runReverseGeocoderSearch(0);

    XCTAssertEqual(run.callbacks, 0);
}

- (void)testNotAbortedSearchConsultsController
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

    [self waitForExpectations:@[completed] timeout:kLookupTimeout];
    XCTAssertEqualObjects(result, @"");
}

@end
