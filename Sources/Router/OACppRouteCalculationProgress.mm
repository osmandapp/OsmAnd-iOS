//
//  OACppRouteCalculationProgress.mm
//  OsmAnd
//

#import "OACppRouteCalculationProgress.h"
#import "OsmAndSharedWrapper.h"

OACppRouteCalculationProgress::OACppRouteCalculationProgress(OASRouteCalculationProgress *progress)
    : RouteCalculationProgress(), _progress(progress)
{
}

OACppRouteCalculationProgress::~OACppRouteCalculationProgress()
{
}

bool OACppRouteCalculationProgress::isCancelled()
{
    // the router asks this often enough to be where the fields it sets on itself are picked up
    publishPlainFields();
    return _progress.isCancelled;
}

int OACppRouteCalculationProgress::getFastRoutingStatusOrdinal()
{
    return (int) [[_progress getFastRoutingStatus] ordinal];
}

void OACppRouteCalculationProgress::setFastRoutingStatusOrdinal(int status)
{
    RouteCalculationProgress::setFastRoutingStatusOrdinal(status);

    // the status only ever moves forward or back to the start, which is all the shared object offers
    NSArray<OASFastRoutingStateStatus *> *statuses = OASFastRoutingStateStatus.entries;
    if (status == FastRoutingState::READY)
        [_progress resetFastRoutingStatus];
    else if (status > 0 && status < (int) statuses.count)
        [_progress raiseFastRoutingStatusStatus:statuses[status]];
}

void OACppRouteCalculationProgress::setSegmentNotFound(int s)
{
    RouteCalculationProgress::setSegmentNotFound(s);
    _progress.segmentNotFound = s;
}

void OACppRouteCalculationProgress::updateIteration(int i)
{
    RouteCalculationProgress::updateIteration(i);
    _progress.iteration = i;
}

void OACppRouteCalculationProgress::updateTotalEstimatedDistance(float distance)
{
    RouteCalculationProgress::updateTotalEstimatedDistance(distance);
    _progress.totalEstimatedDistance = distance;
}

void OACppRouteCalculationProgress::updateTotalApproximateDistance(float distance)
{
    RouteCalculationProgress::updateTotalApproximateDistance(distance);
    _progress.totalApproximateDistance = distance;
}

void OACppRouteCalculationProgress::updateApproximatedDistance(float distance)
{
    RouteCalculationProgress::updateApproximatedDistance(distance);
    _progress.approximatedDistance = distance;
}

void OACppRouteCalculationProgress::updateStatus(float distanceFromBegin, int directSegmentQueueSize,
                                                 float distanceFromEnd, int reverseSegmentQueueSize)
{
    RouteCalculationProgress::updateStatus(distanceFromBegin, directSegmentQueueSize, distanceFromEnd,
                                           reverseSegmentQueueSize);
    // the distances the search reports are the ones it has got furthest with, not the ones passed in
    _progress.distanceFromBegin = this->distanceFromBegin;
    _progress.distanceFromEnd = this->distanceFromEnd;
    publishPlainFields();
}

void OACppRouteCalculationProgress::hhIteration(HHIteration step)
{
    RouteCalculationProgress::hhIteration(step);

    NSArray<OASRouteCalculationProgressHHIteration *> *steps = OASRouteCalculationProgressHHIteration.entries;
    if (step >= 0 && step < (int) steps.count)
        [_progress hhIterationStep:steps[step]];
}

void OACppRouteCalculationProgress::hhTargetsProgress(int done, int total)
{
    RouteCalculationProgress::hhTargetsProgress(done, total);
    [_progress hhTargetsProgressDone:done total:total];
}

void OACppRouteCalculationProgress::hhIterationProgress(double k)
{
    RouteCalculationProgress::hhIterationProgress(k);
    [_progress hhIterationProgressK:k];
}

void OACppRouteCalculationProgress::publishPlainFields()
{
    // the router raises this one on the object itself, and the route screen polls it while the
    // search is still running
    if (requestPrivateAccessRouting)
        _progress.requestPrivateAccessRouting = YES;
}
