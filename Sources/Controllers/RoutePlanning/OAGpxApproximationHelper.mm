//
//  OAGpxApproximationHelper.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationHelper.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxRouteApproximation.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAGpxApproximator.h"
#import "OALocationsHolder.h"
#import "OAApplicationMode.h"
#import "OAGpxApproximationParams.h"
#import "OAGPXDatabase.h"
#import "OAGpxData.h"

#include <gpxRouteApproximation.h>
#include <routeSegment.h>
#include <routeSegmentResult.h>

static BOOL hasValidExternalTimestamps(NSArray<OASWptPt *> *points)
{
    if (points.count == 0)
        return NO;

    int64_t lastTimestamp = 0;
    for (OASWptPt *point in points)
    {
        if (point.time == 0 || point.time < lastTimestamp)
            return NO;
        lastTimestamp = point.time;
    }
    return YES;
}

static float externalSpeed(const SHARED_PTR<GpxPoint> &gpxPoint,
                           const SHARED_PTR<RouteSegmentResult> &segment,
                           NSArray<OASWptPt *> *sourcePoints)
{
    NSInteger startIndex = gpxPoint->ind;
    NSInteger endIndex = gpxPoint->targetInd;
    if (endIndex == -1 && startIndex >= 0 && startIndex + 1 < sourcePoints.count)
        endIndex = startIndex + 1;

    if (startIndex < 0 || endIndex <= 0 || startIndex >= endIndex || endIndex >= sourcePoints.count)
        return segment->segmentSpeed;

    int64_t duration = sourcePoints[endIndex].time - sourcePoints[startIndex].time;
    if (duration <= 0)
        return segment->segmentSpeed;

    double distance = 0;
    for (NSInteger index = startIndex; index < endIndex; index++)
    {
        OASWptPt *firstPoint = sourcePoints[index];
        OASWptPt *secondPoint = sourcePoints[index + 1];
        distance += getDistance(firstPoint.getLatitude,
                                firstPoint.getLongitude,
                                secondPoint.getLatitude,
                                secondPoint.getLongitude);
    }
    return distance > 0 ? distance / (duration / 1000.0) : segment->segmentSpeed;
}

static void recalculateTimeAndDistance(const vector<SHARED_PTR<RouteSegmentResult>> &segments)
{
    for (const auto &segment : segments)
    {
        float speed = segment->segmentSpeed;
        if (speed == 0)
            continue;

        BOOL isForward = segment->getStartPointIndex() < segment->getEndPointIndex();
        double distance = 0;
        for (NSInteger index = segment->getStartPointIndex(); index != segment->getEndPointIndex();)
        {
            NSInteger nextIndex = isForward ? index + 1 : index - 1;
            distance += measuredDist31(segment->object->getPoint31XTile((int)index),
                                       segment->object->getPoint31YTile((int)index),
                                       segment->object->getPoint31XTile((int)nextIndex),
                                       segment->object->getPoint31YTile((int)nextIndex));
            index = nextIndex;
        }
        segment->segmentTime = distance / speed;
        segment->segmentSpeed = speed;
        segment->distance = distance;
    }
}

static void applyExternalTimestamps(OAGpxRouteApproximation *approximation,
                                    OALocationsHolder *locationsHolder)
{
    NSArray<OASWptPt *> *sourcePoints = locationsHolder.getWptPtList;
    if (approximation == nil || approximation.gpxApproximation == nullptr)
        return;
    if (!hasValidExternalTimestamps(sourcePoints))
        return;

    for (const auto &gpxPoint : approximation.gpxApproximation->finalPoints)
    {
        for (const auto &segment : gpxPoint->routeToTarget)
            segment->segmentSpeed = externalSpeed(gpxPoint, segment, sourcePoints);
        recalculateTimeAndDistance(gpxPoint->routeToTarget);
    }
}

@interface OAGpxApproximationHelper () <OAGpxApproximationProgressDelegate>

@end

@implementation OAGpxApproximationHelper
{
    NSArray<OALocationsHolder *> *_locationsHolders;
    OAGpxApproximator *_currentApproximator;
    OAApplicationMode *_appMode;
    float _distanceThreshold;
}

- (instancetype)initWithLocations:(NSArray<OALocationsHolder *> *)locations initialAppMode:(OAApplicationMode *)appMode initialThreshold:(float)threshold
{
    self = [super init];
    if (self)
    {
        _locationsHolders = [locations copy];
        _appMode = appMode;
        _distanceThreshold = threshold;
    }
    
    return self;
}

- (void)updateAppMode:(OAApplicationMode *)appMode
{
    _appMode = appMode;
}

- (void)updateDistanceThreshold:(float)threshold
{
    _distanceThreshold = threshold;
}

- (void)calculateGpxApproximationAsync
{
    if (_currentApproximator != nil)
    {
        [_currentApproximator cancelApproximation];
        _currentApproximator = nil;
    }
    
    if (self.delegate)
        [self.delegate didStartProgress];
    
    NSMutableArray<OAGpxApproximator *> *approximateList = [NSMutableArray array];
    for (OALocationsHolder *locationsHolder in _locationsHolders)
    {
        OAGpxApproximator *approximate = [self getNewGpxApproximator:locationsHolder];
        if (approximate != nil)
            [approximateList addObject:approximate];
    }
    
    NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *approximateResult = [[NSMutableDictionary alloc] init];
    if (self.delegate)
        [self.delegate didApproximationStarted];
    
    @try {
        [self approximateMultipleGpxAsync:approximateList withResult:approximateResult];
    } @catch (NSException *exception) {
        NSLog(@"Error: %@, %@", exception.name, exception.reason);
    }
}

- (void)cancelApproximation
{
    _currentApproximator.progressDelegate = nil;
    [_currentApproximator cancelApproximation];
    _currentApproximator = nil;
}

- (OAGpxApproximator *)getNewGpxApproximator:(OALocationsHolder *)locationsHolder
{
    OAGpxApproximator *gpxApproximator = [[OAGpxApproximator alloc] initWithApplicationMode:_appMode pointApproximation:_distanceThreshold locationsHolder:locationsHolder];
    gpxApproximator.progressDelegate = self;
    [gpxApproximator setMode:_appMode];
    [gpxApproximator setPointApproximation:_distanceThreshold];
    return gpxApproximator;
}

- (void)approximateMultipleGpxAsync:(NSMutableArray<OAGpxApproximator *> *)approximationsToDo withResult:(NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *)approximateResult
{
    if (approximationsToDo.count > 0)
    {
        OAGpxApproximator *gpxApproximator = approximationsToDo.firstObject;
        [approximationsToDo removeObjectAtIndex:0];
        _currentApproximator = gpxApproximator;
        __weak __typeof(self) weakSelf = self;
        [gpxApproximator calculateGpxApproximation:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approxPtr) {
            OAGpxRouteApproximation *strongApprox = (approxPtr && *approxPtr) ? *approxPtr : nil;
            applyExternalTimestamps(strongApprox, gpxApproximator.locationsHolder);
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!gpxApproximator.isCancelled)
                {
                    approximateResult[gpxApproximator.locationsHolder] = strongApprox;
                    [strongSelf approximateMultipleGpxAsync:approximationsToDo withResult:approximateResult];
                }
            });
            return YES;
        } cancelledFunc:^BOOL {
            return NO;
        }]];
    } else {
        NSArray *pair = [self processApproximationResults:approximateResult];
        if (self.delegate)
            [self.delegate didFinishAllApproximationsWithResults:pair.firstObject points:pair.lastObject];
    }
}

- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params
{
    OAMeasurementEditingContext *context = [self createEditingContext:gpxFile params:params];
    NSArray *pair = [self calculateGpxApproximationSync];
    NSArray<OAGpxRouteApproximation *> *approximations = pair.firstObject;
    NSArray<NSArray<OASWptPt *> *> *points = pair.lastObject;
    if (approximations.count == 0 || points.count == 0)
        return gpxFile;

    OASGpxFile *approximatedGpx = [self createApproximatedGpx:context params:params approximations:approximations points:points];
    if (approximatedGpx != nil && [approximatedGpx isAttachedToRoads])
        return approximatedGpx;
    
    return gpxFile;
}

- (NSArray *)calculateGpxApproximationSync
{
    NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *approximateResult = [[NSMutableDictionary alloc] init];
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxApproximator *approximator = [self getNewGpxApproximator:holder];
        if (approximator)
        {
            [approximator calculateGpxApproximationSync:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approximation) {
                if (approximation && *approximation)
                {
                    applyExternalTimestamps(*approximation, holder);
                    approximateResult[holder] = *approximation;
                }
                return YES;
            } cancelledFunc:^BOOL {
                return NO;
            }]];
        }
    }
    
    return [self processApproximationResults:approximateResult];
}

- (NSArray *)processApproximationResults:(NSDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *)approximateResult
{
    NSMutableArray<OAGpxRouteApproximation *> *approximations = [NSMutableArray array];
    NSMutableArray<NSArray<OASWptPt *> *> *points = [NSMutableArray array];
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxRouteApproximation *approximation = approximateResult[holder];
        if (approximation)
        {
            [approximations addObject:approximation];
            [points addObject:holder.getWptPtList];
        }
    }
    
    return @[approximations, points];
}

- (OASGpxFile *)createApproximatedGpx:(OAMeasurementEditingContext *)context params:(OAGpxApproximationParams *)params approximations:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    for (NSUInteger i = 0; i < [approximations count]; i++)
    {
        OAGpxRouteApproximation *approximation = [approximations objectAtIndex:i];
        NSArray<OASWptPt *> *segment = [points objectAtIndex:i];
        [context setPoints:approximation originalPoints:segment mode:_appMode];
    }
    
    return [context exportGpx:context.gpxData.gpxFile.path.lastPathComponent.stringByDeletingPathExtension];
}

- (OAMeasurementEditingContext *)createEditingContext:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params
{
    OAMeasurementEditingContext *editingContext = [[OAMeasurementEditingContext alloc] init];
    editingContext.gpxData = [[OAGpxData alloc] initWithFile:gpxFile];
    editingContext.appMode = [params getAppMode];
    [editingContext addPoints];
    [params setTrackPoints:[editingContext getPointsSegments:YES route:YES]];
    _locationsHolders = params.locationsHolders;
    return editingContext;
}

// MARK: OAGpxApproximationProgressDelegate

- (void)updateProgress:(OAGpxApproximator *)approximator progress:(NSInteger)progress
{
    // UI Thread+
    if (approximator == _currentApproximator)
    {
        if (self.delegate)
            [self.delegate didUpdateProgress:progress];
    }
}

@end
