//
//  OAReverseGeocoderStopTests.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>
#import "OAReverseGeocoder.h"

#include <OsmAndCore.h>
#include <OsmAndCore/ICoreResourcesProvider.h>
#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/ObfsCollection.h>
#include <OsmAndCore/RoadLocator.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Address.h>
#include <OsmAndCore/Search/ReverseGeocoder.h>
#include <OsmAndCore/Search/AddressesByNameSearch.h>

@interface OAReverseGeocoder (StopTests)
- (NSString *)performLookupAddressAtLat:(double)lat lon:(double)lon objectId:(uint64_t)objectId;
@end

static const double kTestLatitude = 50.356646571646124;
static const double kTestLongitude = 7.5956672430038452;
static const int kNeverAbort = -1;
static const NSTimeInterval kLookupTimeout = 5.0;
static NSString * const kViennaStreetName = @"Gießaufgasse";
static NSString * const kViennaObfGzPath = @"test-resources/search/austria_wien.obf.gz";
static NSString * const kViennaObfDirectoryName = @"OAReverseGeocoderStopTests";
static NSString * const kViennaObfFileName = @"austria_wien.obf";

class OATestCoreResourcesProvider : public OsmAnd::ICoreResourcesProvider
{
public:
    QByteArray getResource(const QString& name, const float displayDensityFactor, bool* ok = nullptr) const override
    {
        return getResource(name, ok);
    }

    QByteArray getResource(const QString& name, bool* ok = nullptr) const override
    {
        NSString *path = resourcePath(name);
        NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
        if (ok)
            *ok = data != nil;
        return data ? QByteArray::fromNSData(data) : QByteArray();
    }

    bool containsResource(const QString& name, const float displayDensityFactor) const override
    {
        return containsResource(name);
    }

    bool containsResource(const QString& name) const override
    {
        return resourcePath(name) != nil;
    }

private:
    static NSString *resourcePath(const QString& name)
    {
        if (name == QLatin1String("misc/icu4c/icu-data-l.dat"))
            return [[NSBundle mainBundle] pathForResource:@"icudt52l" ofType:@"dat"];
        return nil;
    }
};

struct OAReverseGeocoderSearchRun
{
    int polls = 0;
    int callbacks = 0;
    bool streetOrBuildingFound = false;
};

static bool initializeTestBundleCore()
{
    static bool initialized = false;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        initialized = OsmAnd::InitializeCore(std::make_shared<OATestCoreResourcesProvider>()) != 0;
    });
    return initialized;
}

static OsmAnd::PointI testPosition31()
{
    return OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(kTestLatitude, kTestLongitude));
}

static OAReverseGeocoderSearchRun runReverseGeocoderSearch(const std::shared_ptr<const OsmAnd::IObfsCollection>& obfsCollection,
                                                           const OsmAnd::PointI& position31,
                                                           int abortFromPoll)
{
    OAReverseGeocoderSearchRun run;
    const auto geocoder = std::make_shared<OsmAnd::ReverseGeocoder>(
        obfsCollection,
        std::make_shared<OsmAnd::RoadLocator>(obfsCollection));
    OsmAnd::ReverseGeocoder::Criteria criteria;
    criteria.position31 = position31;
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
            const auto& entry = static_cast<const OsmAnd::ReverseGeocoder::ResultEntry&>(resultEntry);
            run.callbacks++;
            run.streetOrBuildingFound = entry.street || entry.building;
        },
        queryController);
    return run;
}

static bool findStreetPosition31(const std::shared_ptr<const OsmAnd::IObfsCollection>& obfsCollection,
                                 NSString *streetName,
                                 OsmAnd::PointI& outPosition31)
{
    OsmAnd::AddressesByNameSearch search(obfsCollection);
    OsmAnd::AddressesByNameSearch::Criteria criteria;
    criteria.name = QString::fromNSString(streetName);
    criteria.includeStreets = true;
    bool found = false;
    search.performSearch(criteria,
        [&found, &outPosition31]
        (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::BaseSearch::IResultEntry& resultEntry)
        {
            const auto& address = static_cast<const OsmAnd::AddressesByNameSearch::ResultEntry&>(resultEntry).address;
            if (!found && address && address->addressType == OsmAnd::AddressType::Street)
            {
                outPosition31 = address->position31;
                found = true;
            }
        });
    return found;
}

@interface OAReverseGeocoderStopTests : XCTestCase

@end

@implementation OAReverseGeocoderStopTests

- (std::shared_ptr<const OsmAnd::IObfsCollection>)viennaObfsCollection
{
    NSString *gzPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:kViennaObfGzPath];
    NSString *obfDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:kViennaObfDirectoryName];
    [[NSFileManager defaultManager] removeItemAtPath:obfDirectory error:nil];
    if (![[NSFileManager defaultManager] createDirectoryAtPath:obfDirectory withIntermediateDirectories:YES attributes:nil error:nil])
        return nullptr;
    NSString *obfPath = [obfDirectory stringByAppendingPathComponent:kViennaObfFileName];

    OsmAnd::ArchiveReader archive(QString::fromNSString(gzPath));
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok, true);
    if (!ok || archiveItems.isEmpty())
        return nullptr;
    if (!archive.extractItemToFile(archiveItems.first().name, QString::fromNSString(obfPath), true))
        return nullptr;

    const auto obfsCollection = std::make_shared<OsmAnd::ObfsCollection>();
    obfsCollection->addDirectory(QString::fromNSString(obfDirectory), false);
    return obfsCollection;
}

- (BOOL)prepareViennaCollection:(std::shared_ptr<const OsmAnd::IObfsCollection> &)outCollection streetPosition31:(OsmAnd::PointI &)outPosition31
{
    XCTAssertTrue(initializeTestBundleCore(), @"InitializeCore failed for the test bundle core copy");
    outCollection = [self viennaObfsCollection];
    XCTAssertTrue(outCollection != nullptr, @"Failed to extract %@", kViennaObfGzPath);
    if (!outCollection)
        return NO;
    BOOL found = findStreetPosition31(outCollection, kViennaStreetName, outPosition31);
    XCTAssertTrue(found, @"%@ not found in %@", kViennaStreetName, kViennaObfGzPath);
    return found;
}

- (void)testAbortedSearchSkipsResultCallback
{
    const auto run = runReverseGeocoderSearch(std::make_shared<OsmAnd::ObfsCollection>(), testPosition31(), 0);

    XCTAssertEqual(run.callbacks, 0);
}

- (void)testNotAbortedSearchConsultsController
{
    const auto run = runReverseGeocoderSearch(std::make_shared<OsmAnd::ObfsCollection>(), testPosition31(), kNeverAbort);

    XCTAssertEqual(run.callbacks, 1);
    XCTAssertGreaterThan(run.polls, 0);
}

- (void)testSearchOnMapDataFindsStreet
{
    std::shared_ptr<const OsmAnd::IObfsCollection> obfsCollection;
    OsmAnd::PointI streetPosition31;
    if (![self prepareViennaCollection:obfsCollection streetPosition31:streetPosition31])
        return;

    const auto run = runReverseGeocoderSearch(obfsCollection, streetPosition31, kNeverAbort);
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"full search polls: %d", run.polls] block:^(id<XCTActivity> activity) {}];

    XCTAssertEqual(run.callbacks, 1);
    XCTAssertTrue(run.streetOrBuildingFound);
}

- (void)testAbortAtAnyPollSkipsResultCallback
{
    std::shared_ptr<const OsmAnd::IObfsCollection> obfsCollection;
    OsmAnd::PointI streetPosition31;
    if (![self prepareViennaCollection:obfsCollection streetPosition31:streetPosition31])
        return;

    const auto fullRun = runReverseGeocoderSearch(obfsCollection, streetPosition31, kNeverAbort);
    XCTAssertEqual(fullRun.callbacks, 1);

    for (int abortFromPoll = 0; abortFromPoll < fullRun.polls; abortFromPoll++)
    {
        const auto abortedRun = runReverseGeocoderSearch(obfsCollection, streetPosition31, abortFromPoll);
        XCTAssertEqual(abortedRun.callbacks, 0, @"Result delivered after abort from poll %d of %d", abortFromPoll, fullRun.polls);
        XCTAssertLessThanOrEqual(abortedRun.polls, fullRun.polls, @"Aborted search from poll %d did more work than a full one", abortFromPoll);
    }
}

- (void)testAbortInTheMiddleStopsScanning
{
    std::shared_ptr<const OsmAnd::IObfsCollection> obfsCollection;
    OsmAnd::PointI streetPosition31;
    if (![self prepareViennaCollection:obfsCollection streetPosition31:streetPosition31])
        return;

    const auto fullRun = runReverseGeocoderSearch(obfsCollection, streetPosition31, kNeverAbort);
    const int abortFromPoll = fullRun.polls / 2;
    const auto abortedRun = runReverseGeocoderSearch(obfsCollection, streetPosition31, abortFromPoll);
    const int pollsAfterAbort = abortedRun.polls - abortFromPoll;
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"full search polls: %d, aborted from poll %d, polls after abort: %d",
                                  fullRun.polls, abortFromPoll, pollsAfterAbort]
                           block:^(id<XCTActivity> activity) {}];

    XCTAssertEqual(abortedRun.callbacks, 0);
    XCTAssertLessThan(abortedRun.polls, fullRun.polls);
}

- (void)testLookupWorkerAfterStopReturnsEmptyAddress
{
    OAReverseGeocoder *geocoder = [[OAReverseGeocoder alloc] init];
    [geocoder stop];

    NSString *address = [geocoder performLookupAddressAtLat:kTestLatitude lon:kTestLongitude objectId:0];

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
