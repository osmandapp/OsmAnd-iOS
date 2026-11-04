//
//  OASharedRouteProgressTest.mm
//  OsmAnd MapsTests
//
//  A route calculation reports its progress into one OsmAndShared object, whichever planner runs
//  it. The OsmAndShared planner writes there itself; the C++ one writes to a progress of its own
//  kind that passes everything on. This is about that passing on: the same search reported to both
//  kinds has to leave them saying the same thing - the same percentage, the same routing status,
//  the same reason to stop.
//

#import <XCTest/XCTest.h>
#import "OACppRouteCalculationProgress.h"
#import "OsmAndSharedWrapper.h"

#include <routeCalculationProgress.h>

@interface OASharedRouteProgressTest : XCTestCase

@end

@implementation OASharedRouteProgressTest
{
    OASRouteCalculationProgress *_shared;
    std::shared_ptr<RouteCalculationProgress> _bridge; // an OACppRouteCalculationProgress, as the router sees it
    std::shared_ptr<RouteCalculationProgress> _plain;
}

- (void)setUp
{
    _shared = [[OASRouteCalculationProgress alloc] init];
    _bridge = std::make_shared<OACppRouteCalculationProgress>(_shared);
    _plain = std::make_shared<RouteCalculationProgress>();
}

- (void)testTheSearchTowardsTheTargetsReportsTheSamePercentage
{
    [self comparePercentage:@"nothing reported yet"];

    for (const auto &progress : { _bridge, _plain })
    {
        progress->updateTotalEstimatedDistance(4000);
        progress->updateIteration(0);
    }
    [self comparePercentage:@"the distance to cover is known"];

    for (float reached : { 100.f, 900.f, 2600.f })
    {
        for (const auto &progress : { _bridge, _plain })
            progress->updateStatus(reached, 12, reached / 2, 8);
        [self comparePercentage:[NSString stringWithFormat:@"%.0f m from the start", reached]];
    }

    // the search reports where it has got to, and a step back does not move the bar back
    for (const auto &progress : { _bridge, _plain })
        progress->updateStatus(1000, 12, 100, 8);
    [self comparePercentage:@"a shorter way found later"];
}

- (void)testTheHierarchicalSearchReportsTheSamePercentage
{
    for (const auto &progress : { _bridge, _plain })
        progress->hhTargetsProgress(0, 2);

    NSArray<NSNumber *> *steps = @[@(RouteCalculationProgress::SELECT_REGIONS), @(RouteCalculationProgress::LOAD_POINTS),
                                   @(RouteCalculationProgress::ROUTING), @(RouteCalculationProgress::DETAILED)];
    for (NSNumber *step in steps)
    {
        for (const auto &progress : { _bridge, _plain })
            progress->hhIteration((RouteCalculationProgress::HHIteration) step.intValue);
        [self comparePercentage:[NSString stringWithFormat:@"step %@ started", step]];

        for (double k : { 0.25, 0.75 })
        {
            for (const auto &progress : { _bridge, _plain })
                progress->hhIterationProgress(k);
            [self comparePercentage:[NSString stringWithFormat:@"step %@ at %.0f%%", step, k * 100]];
        }
    }

    for (const auto &progress : { _bridge, _plain })
        progress->hhTargetsProgress(1, 2);
    [self comparePercentage:@"the first of two targets reached"];
}

- (void)testTheTrackApproximationReportsTheSamePercentage
{
    for (const auto &progress : { _bridge, _plain })
        progress->updateTotalApproximateDistance(2500);
    XCTAssertEqualWithAccuracy([_shared getApproximationProgress], _plain->getApproximationProgress(), 1e-4,
                               @"the track to attach is known");

    for (const auto &progress : { _bridge, _plain })
        progress->updateApproximatedDistance(1000);
    XCTAssertEqualWithAccuracy([_shared getApproximationProgress], _plain->getApproximationProgress(), 1e-4,
                               @"1000 m of 2500 attached");
}

- (void)testTheRoutingStatusIsRaisedAndReadBack
{
    XCTAssertEqual(_bridge->getFastRoutingStatusOrdinal(), (int) OASFastRoutingStateStatus.ready.ordinal);

    _bridge->raiseFastRoutingStatus(FastRoutingState::MISSING_MAPS_AT_START_OR_END);
    XCTAssertTrue([_shared hasMixedOrMissingMaps], @"the maps the check found missing");
    XCTAssertEqual(_bridge->getFastRoutingStatusOrdinal(), (int) OASFastRoutingStateStatus.missingMapsAtStartOrEnd.ordinal);

    // the hierarchical search gives up over the maps that are missing, which the status has to keep
    _bridge->failFastRoutingStatus(false);
    XCTAssertEqual(_bridge->getFastRoutingStatusOrdinal(), (int) OASFastRoutingStateStatus.failedWithMissingMaps.ordinal);
    XCTAssertTrue([_shared hasMixedOrMissingMaps]);

    _bridge->resetFastRoutingStatus();
    XCTAssertEqual(_bridge->getFastRoutingStatusOrdinal(), (int) OASFastRoutingStateStatus.ready.ordinal);
    XCTAssertFalse([_shared hasMixedOrMissingMaps]);
}

- (void)testWhatStopsTheSearchAndWhatTheScreenAsksAbout
{
    XCTAssertFalse(_bridge->isCancelled());
    _shared.isCancelled = YES;
    XCTAssertTrue(_bridge->isCancelled(), @"the screen cancelled the calculation and the search has to notice");

    _bridge->setSegmentNotFound(2);
    XCTAssertEqual(_shared.segmentNotFound, 2, @"which of the points has no road near it");

    // the router raises this one on itself; it reaches the screen as the search goes past
    _bridge->requestPrivateAccessRouting = true;
    XCTAssertFalse(_shared.requestPrivateAccessRouting);
    _bridge->isCancelled();
    XCTAssertTrue(_shared.requestPrivateAccessRouting, @"the road behind the gate the user has to allow");
}

- (void) comparePercentage:(NSString *)message
{
    XCTAssertEqualWithAccuracy([_shared getLinearProgress], _plain->getLinearProgress(), 1e-4, @"%@", message);
}

@end
