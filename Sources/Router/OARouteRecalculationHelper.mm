//
//  OARouteRecalculationHelper.m
//  OsmAnd Maps
//
//  Created by Alexey K on 10.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteRecalculationHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAWaypointHelper.h"
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"
#import "OARoutingHelperUtils.h"
#import "Localization.h"

#import <AFNetworking/AFNetworkReachabilityManager.h>

#define RECALCULATE_THRESHOLD_COUNT_CAUSING_FULL_RECALCULATE 3
#define RECALCULATE_THRESHOLD_CAUSING_FULL_RECALCULATE_INTERVAL 2 * 60

@interface OARouteRecalculationTask : NSOperation

@property (nonatomic) OARouteCalculationParams *params;
@property (nonatomic, readonly) BOOL paramsChanged;

@property (nonatomic) NSString *routeCalcError;
@property (nonatomic) NSString *routeCalcErrorShort;
@property (nonatomic) int evalWaitInterval;

- (instancetype) initWithName:(NSString *)name params:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged helper:(OARouteRecalculationHelper *)helper;

- (void) stopCalculation;

@end

@interface OARouteRecalculationHelper()

- (void) setNewRoute:(OARouteCalculationResult *)prevRoute res:(OARouteCalculationResult *)res start:(CLLocation *)start;

@end

@implementation OARouteRecalculationHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSOperationQueue *_executor;
    NSMutableArray<OARouteRecalculationTask *> *_tasks;
    OARouteRecalculationTask *_lastTask;

    NSMutableArray<id<OARouteCalculationProgressCallback>> *_calculationProgressCallbacks;
}

- (instancetype) initWithRoutingHelper:(OARoutingHelper *)helper
{
    self = [super init];
    if (self) 
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _routingHelper = helper;

        _executor = [[NSOperationQueue alloc] init];
        _executor.maxConcurrentOperationCount = 1;
        _tasks = [NSMutableArray array];

        _calculationProgressCallbacks = [NSMutableArray array];
    }
    return self;
}

- (void) addCalculationProgressCallback:(id<OARouteCalculationProgressCallback>)callback
{
    @synchronized (self) {
	    NSMutableArray<id<OARouteCalculationProgressCallback>> *calculationProgressCallbacks = [NSMutableArray arrayWithArray:_calculationProgressCallbacks];

        [calculationProgressCallbacks addObject:callback];
        _calculationProgressCallbacks = calculationProgressCallbacks;
    }
}

- (BOOL) isRouteBeingCalculated
{
    @synchronized (self)
    {
        for (OARouteRecalculationTask *task in _tasks)
            if (!task.finished)
                return YES;

        return NO;
    }
}

- (void) resetEvalWaitInterval
{
    _evalWaitInterval = 0;
}

- (void) setNewRoute:(OARouteCalculationResult *)prevRoute res:(OARouteCalculationResult *)res start:(CLLocation *)start
{
    BOOL newRoute = ![prevRoute isCalculated];
    if (_routingHelper.isFollowingMode)
    {
        if (_routingHelper.getLastFixedLocation)
            start = _routingHelper.getLastFixedLocation;

        // try remove false route-recalculated prompts by checking direction to second route node
        BOOL wrongMovementDirection = false;
        NSArray<CLLocation *> *routeNodes = [res getImmutableAllLocations];
        if (routeNodes && routeNodes.count > 0)
        {
            int newCurrentRoute = [OARoutingHelperUtils lookAheadFindMinOrthogonalDistance:start routeNodes:routeNodes currentRoute:res.currentRoute iterations:15];
            if (newCurrentRoute + 1 < routeNodes.count)
            {
                CLLocation *prev = [res getRouteLocationByDistance:-15];
                // This check is valid for Online/GPX services (offline routing is aware of route direction)
                wrongMovementDirection = [OARoutingHelperUtils checkWrongMovementDirection:start prevRouteLocation:prev nextRouteLocation:routeNodes[newCurrentRoute + 1]];
                // set/reset evalWaitInterval only if new route is in forward direction
                if (wrongMovementDirection)
                {
                    _evalWaitInterval = 3;
                }
                else
                {
                    _evalWaitInterval = MAX(3, _evalWaitInterval * 3 / 2);
                    _evalWaitInterval = MIN(_evalWaitInterval, 120);
                }
            }
        }
        // trigger voice prompt only if new route is in forward direction
        // If route is in wrong direction after one more setLocation it will be recalculated
        if (!wrongMovementDirection || newRoute)
            [_routingHelper.voiceRouter newRouteIsCalculated:newRoute];
    }

    [[OAWaypointHelper sharedInstance] setNewRoute:res];
    [_routingHelper newRouteCalculated:newRoute];
}

- (void) startRouteCalculationThread:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged updateProgress:(BOOL)updateProgress
{
    @synchronized (self)
    {
        _settings.lastRoutingApplicationMode = _routingHelper.getAppMode;

        OARouteRecalculationTask *newTask = [[OARouteRecalculationTask alloc] initWithName:@"Calculating route" params:params paramsChanged:paramsChanged helper:self];
        _lastTask = newTask;
        [self startProgress:params];
        if (updateProgress)
            [self updateProgressWithDelay:params];

        __weak OARouteRecalculationTask *newTaskRef = newTask;
        [newTask setCompletionBlock:^{
            OARouteRecalculationTask *newTask = newTaskRef;
            if (newTask)
            {
                [_tasks removeObject:newTask];
                _evalWaitInterval = newTask.evalWaitInterval;
                _lastRouteCalcError = newTask.routeCalcError;
                _lastRouteCalcErrorShort = newTask.routeCalcErrorShort;
                _lastTimeEvaluatedRoute = [[NSDate date] timeIntervalSince1970];
            }
        }];
        [_tasks addObject:newTask];
        [_executor addOperation:newTask];
    }
}

- (void) startProgress:(OARouteCalculationParams *) params
{
    if (params.calculationProgressCallback)
        [params.calculationProgressCallback startProgress];
    else
        for (id<OARouteCalculationProgressCallback> callback in _calculationProgressCallbacks)
            [callback startProgress];
}

- (void) finishProgress:(OARouteCalculationParams *) params
{
    if (params.calculationProgressCallback)
        [params.calculationProgressCallback finish];
    else
        for (id<OARouteCalculationProgressCallback> callback in _calculationProgressCallbacks)
            [callback finish];
}

- (void) updateProgressWithDelay:(OARouteCalculationParams *)params
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateProgressInUIThread:params];
    });
}

- (void) updateProgressInUIThread:(OARouteCalculationParams *)params
{
    NSArray<id<OARouteCalculationProgressCallback>> *callbacks = params.calculationProgressCallback
        ? @[params.calculationProgressCallback]
        : _calculationProgressCallbacks;

    BOOL isRouteBeingCalculated = callbacks.count > 0;
    for (id<OARouteCalculationProgressCallback> callback : callbacks)
        isRouteBeingCalculated &= [self updateProgress:callback params:params];

    if (isRouteBeingCalculated)
        [self updateProgressWithDelay:params];
}

- (BOOL) updateProgress:(id<OARouteCalculationProgressCallback> __nonnull)callback params:(OARouteCalculationParams *)params
{
    auto calculationProgress = params.calculationProgress;
    if ([self isRouteBeingCalculated])
    {
        if (_lastTask && _lastTask.params == params)
        {
            [callback updateProgress:calculationProgress->getLinearProgress()];
            if (calculationProgress->requestPrivateAccessRouting)
                [callback requestPrivateAccessRouting];

            return YES;
        }
    }
    else
    {
        if (calculationProgress->requestPrivateAccessRouting)
            [callback requestPrivateAccessRouting];

        [callback finish];
    }
    return NO;
}

- (void) recalculateRouteInBackground:(CLLocation *)start end:(CLLocation *)end intermediates:(NSArray<CLLocation *> *)intermediates gpxRoute:(OAGPXRouteParamsBuilder *)gpxRoute previousRoute:(OARouteCalculationResult *)previousRoute paramsChanged:(BOOL)paramsChanged onlyStartPointChanged:(BOOL)onlyStartPointChanged
{
    if (!start || !end)
        return;

    if ((![self isRouteBeingCalculated] && [[NSDate date] timeIntervalSince1970] - _lastTimeEvaluatedRoute > _evalWaitInterval)
        || paramsChanged || !onlyStartPointChanged)
    {
        if ([[NSDate date] timeIntervalSince1970] - _lastTimeEvaluatedRoute < RECALCULATE_THRESHOLD_CAUSING_FULL_RECALCULATE_INTERVAL)
        {
            _recalculateCountInInterval ++;
        }

        OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
        params.start = start;
        params.end = end;
        params.intermediates = intermediates;
        params.gpxRoute = gpxRoute == nil ? nil : [gpxRoute build:start];
        params.onlyStartPointChanged = onlyStartPointChanged;
        if (_recalculateCountInInterval < RECALCULATE_THRESHOLD_COUNT_CAUSING_FULL_RECALCULATE || (gpxRoute && gpxRoute.passWholeRoute && OARoutingHelper.isDeviatedFromRoute))
        {
            params.previousToRecalculate = previousRoute;
        }
        else
        {
            _recalculateCountInInterval = 0;
        }
        OAApplicationMode *mode = _routingHelper.getAppMode;
        params.leftSide = [OADrivingRegion isLeftHandDriving:[_settings.drivingRegion get:mode]];
        params.fast = [_settings.fastRouteMode get:mode];
        params.mode = mode;
        BOOL updateProgress = NO;
        if (params.mode.getRouterService == OSMAND)
        {
            params.calculationProgress = std::make_shared<RouteCalculationProgress>();
            [self updateProgressWithDelay:params];
            updateProgress = YES;
        }
        [self startRouteCalculationThread:params paramsChanged:paramsChanged updateProgress:updateProgress];
    }
}

- (void) stopCalculationIfParamsNotChanged
{
    @synchronized (self) {
        for (OARouteRecalculationTask *task in _tasks)
            if (!task.paramsChanged)
                [task cancel];
    }
}

- (void) stopCalculation
{
    @synchronized (self) {
        for (OARouteRecalculationTask *task in _tasks)
            [task cancel];
    }
}

@end


@implementation OARouteRecalculationTask
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    OARouteRecalculationHelper *_recalcHelper;
}

- (instancetype)initWithName:(NSString *)name params:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged helper:(OARouteRecalculationHelper *)helper
{
    self = [super init];
    if (self)
    {
        self.qualityOfService = NSQualityOfServiceUtility;

        self.name = name;
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _routingHelper = helper.routingHelper;
        _recalcHelper = helper;
        _params = params;
        _paramsChanged = paramsChanged;
        if (!params.calculationProgress)
            params.calculationProgress = std::make_shared<RouteCalculationProgress>();
    }
    return self;
}

- (void) stopCalculation
{
    _params.calculationProgress->cancelled = true;
}

- (void) cancel
{
    [super cancel];

    [self stopCalculation];
}

- (void) main
{
    _routeCalcError = nil;
    _routeCalcErrorShort = nil;
    OARouteCalculationResult *res = [_routingHelper.provider calculateRouteImpl:_params];
    if (_params.calculationProgress->isCancelled())
        return;

    BOOL onlineSourceWithoutInternet = ![res isCalculated] && [OARouteService isOnline:(EOARouteService)_params.mode.getRouterService] && !AFNetworkReachabilityManager.sharedManager.isReachable;
    if (onlineSourceWithoutInternet && _settings.gpxRouteCalcOsmandParts.get)
        if (_params.previousToRecalculate && [_params.previousToRecalculate isCalculated])
            res = [_routingHelper.provider recalculatePartOfflineRoute:res params:_params];

    OARouteCalculationResult *prev = _routingHelper.getRoute;
    @synchronized (_routingHelper)
    {
        if ([res isCalculated])
        {
            if (!_params.inSnapToRoadMode && !_params.inPublicTransportMode)
                [_routingHelper setRoute:res];

            if (_params.resultListener)
                [_params.resultListener onRouteCalculated:res segment:_params.walkingRouteSegment];

            [_routingHelper setRoute:res];
        }
        else
        {
            _evalWaitInterval = MAX(3, _evalWaitInterval * 3 / 2); // for Issue #3899
            _evalWaitInterval = MIN(_evalWaitInterval, 120);
        }
    }
    if ([res isCalculated])
    {
        if (!_routingHelper.isPublicTransportMode && !_params.inSnapToRoadMode)
            [_recalcHelper setNewRoute:prev res:res start:_params.start];
    }
    else if (onlineSourceWithoutInternet)
    {
        _routeCalcError = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"error_calculating_route"), OALocalizedString(@"internet_connection_required_for_online_route")];
        _routeCalcErrorShort = OALocalizedString(@"error_calculating_route");
        [self showMessage:_routeCalcError];
    }
    else
    {
        if (res.errorMessage)
        {
            _routeCalcError = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"error_calculating_route"), res.errorMessage];
            _routeCalcErrorShort = OALocalizedString(@"error_calculating_route");
            [self showMessage:_routeCalcError];
        }
        else
        {
            _routeCalcError = OALocalizedString(@"empty_route_calculated");
            _routeCalcErrorShort = OALocalizedString(@"empty_route_calculated");
            [self showMessage:_routeCalcError];
        }
    }
}

- (void) showMessage:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO toast
        // show message
    });
}

@end
