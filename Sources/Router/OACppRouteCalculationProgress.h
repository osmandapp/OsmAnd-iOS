//
//  OACppRouteCalculationProgress.h
//  OsmAnd
//
//  The progress the C++ router reports into, so that a route calculated by either router reports
//  through the one OsmAndShared progress object the app reads. The C++ router writes to an object
//  of its own kind, which is what this is; everything it writes is passed on, the way the JNI
//  wrapper passes it on to java's progress on Android.
//
//  Temporary by design: it exists only while the C++ router does.
//

#import <Foundation/Foundation.h>

#include <routeCalculationProgress.h>

@class OASRouteCalculationProgress;

struct OACppRouteCalculationProgress : RouteCalculationProgress
{
    OACppRouteCalculationProgress(OASRouteCalculationProgress *progress);
    virtual ~OACppRouteCalculationProgress() override;

    virtual bool isCancelled() override;

    virtual int getFastRoutingStatusOrdinal() override;
    virtual void setFastRoutingStatusOrdinal(int status) override;

    virtual void setSegmentNotFound(int s) override;
    virtual void updateIteration(int i) override;
    virtual void updateTotalEstimatedDistance(float distance) override;
    virtual void updateTotalApproximateDistance(float distance) override;
    virtual void updateApproximatedDistance(float distance) override;
    virtual void updateStatus(float distanceFromBegin, int directSegmentQueueSize, float distanceFromEnd,
                              int reverseSegmentQueueSize) override;

    virtual void hhIteration(HHIteration step) override;
    virtual void hhTargetsProgress(int done, int total) override;
    virtual void hhIterationProgress(double k) override;

    /** The fields the router sets on itself, with no method to catch them by; passed on as it goes past. */
    void publishPlainFields();

private:
    OASRouteCalculationProgress *_progress;
};
