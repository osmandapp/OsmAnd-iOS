//
//  OATransportRoutingHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATransportRoutingHelper.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OARoutingHelper.h"
#import "OATransportRouteResult.h"
#import "OARouteCalculationResult.h"
#import "OAAppSettings.h"
#import "OATransportRouteCalculationParams.h"
#import "OARouteCalculationParams.h"
#import "Localization.h"
#import "OAWaypointHelper.h"

#include <OsmAndCore/Utilities.h>

@interface OAWalkingRouteSegment : NSObject

// C++
//@property (nonatomic) OATransportRouteResultSegment *s1;
//@property (nonatomic) OATransportRouteResultSegment *s2;
@property (nonatomic) CLLocation *start;
@property (nonatomic) BOOL startTransportStop;
@property (nonatomic) CLLocation *end;
@property (nonatomic) BOOL endTransportStop;

- (instancetype) initWithTransportRouteResultSegment:(id) s1 s2:(id) s2;
- (instancetype) initWithStartLocation:(CLLocation *) start segment:(id) s;
- (instancetype) initWithRouteResultSegment:(id)s end:(CLLocation *)end;

@end

@implementation OAWalkingRouteSegment

- (instancetype) initWithTransportRouteResultSegment:(id) s1 s2:(id) s2
{
    self = [super init];
    if (self) {
//        _s1 = s1;
//        _s2 = s2;
//
//        start = s1->getEnd()->getLocation();
//        end = s2->getStart()->getLocation();
        
        _startTransportStop = YES;
        _endTransportStop = YES;
    }
    return self;
}

- (instancetype) initWithStartLocation:(CLLocation *) start segment:(id) s
{
    self = [super init];
    if (self) {
//        _start = start;
//        s2 = s;
//        _end = s2->getStart()->getLocation();
        _endTransportStop = YES;
    }
    return self;
}

- (instancetype) initWithRouteResultSegment:(id)s end:(CLLocation *)end
{
    self = [super init];
    if (self) {
//        _s1 = s;
//        _end = end;
//        _start = s1->getEnd()->getLocation();
        _startTransportStop = true;
    }
    return self;
}

@end

@interface OATransportRoutingHelper()

@property (nonatomic) NSArray <OATransportRouteResult *> *routes;
@property (nonatomic) NSThread *currentRunningJob;

@property (nonatomic) NSString *lastRouteCalcError;
@property (nonatomic) NSString *lastRouteCalcErrorShort;
@property (nonatomic) BOOL waitingNextJob;

@property (nonatomic) NSMutableArray<id<OARouteInformationListener>> *listeners;

- (void) setNewRoute:(NSArray<OATransportRouteResult *> *)res;

@end

@interface OATransportRouteRecalculationThread : NSThread <OARouteCalculationProgressCallback, OARouteCalculationResultListener>

@property (nonatomic) OATransportRouteCalculationParams *params;
@property (nonatomic) NSThread *prevRunningJob;

@property (nonatomic) BOOL walkingSegmentsCalculated;

//private final Queue<WalkingRouteSegment> walkingSegmentsToCalculate = new ConcurrentLinkedQueue<>();
//private Map<Pair<TransportRouteResultSegment, TransportRouteResultSegment>, RouteCalculationResult> walkingRouteSegments;

- (void) stopCalculation;
- (void) setWaitPrevJob:(NSThread *)prevRunningJob;

@end

@implementation OATransportRouteRecalculationThread
{
    OATransportRoutingHelper *_helper;
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    dispatch_queue_t _queue;
    NSMutableArray<OAWalkingRouteSegment *> *_walkingSegmentsToCalculate;
    
    double _currentDistanceFromBegin;
    
//    private Map<Pair<TransportRouteResultSegment, TransportRouteResultSegment>, RouteCalculationResult> walkingRouteSegments = new HashMap<>();
}

- (instancetype)initWithName:(NSString *)name params:(OATransportRouteCalculationParams *)params helper:(OATransportRoutingHelper *)helper
{
    self = [super init];
    if (self)
    {
        self.qualityOfService = NSQualityOfServiceUtility;
        
        self.name = name;
        _app = [OsmAndApp instance];
        _helper = helper;
        _settings = [OAAppSettings sharedManager];
        _params = params;
        _queue = dispatch_queue_create("array_queue", DISPATCH_QUEUE_CONCURRENT);
        _walkingSegmentsToCalculate = [NSMutableArray new];

        if (!params.calculationProgress)
        {
            params.calculationProgress = std::make_shared<RouteCalculationProgress>();
        }
    }
    return self;
}

- (void) stopCalculation
{
    _params.calculationProgress->cancelled = true;
}

- (void) setWaitPrevJob:(NSThread *)prevRunningJob
{
    _prevRunningJob = prevRunningJob;
}

- (NSArray<OATransportRouteResult *> *) calculateRouteImpl:(OATransportRouteCalculationParams *)params
{
//    RoutingConfiguration.Builder config = params.ctx.getRoutingConfigForMode(params.mode);
//    BinaryMapIndexReader[] files = params.ctx.getResourceManager().getTransportRoutingMapFiles();
//    params.params.clear();
//    OsmandSettings settings = params.ctx.getSettings();
//    for(Map.Entry<String, GeneralRouter.RoutingParameter> e : config.getRouter(params.mode.getRoutingProfile()).getParameters().entrySet()){
//        String key = e.getKey();
//        GeneralRouter.RoutingParameter pr = e.getValue();
//        String vl;
//        if(pr.getType() == GeneralRouter.RoutingParameterType.BOOLEAN) {
//            OsmandSettings.CommonPreference<Boolean> pref = settings.getCustomRoutingBooleanProperty(key, pr.getDefaultBoolean());
//            Boolean bool = pref.getModeValue(params.mode);
//            vl = bool ? "true" : null;
//        } else {
//            vl = settings.getCustomRoutingProperty(key, "").getModeValue(params.mode);
//        }
//        if(vl != null && vl.length() > 0) {
//            params.params.put(key, vl);
//        }
//    }
//    GeneralRouter prouter = config.getRouter(params.mode.getRoutingProfile());
//    TransportRoutingConfiguration cfg = new TransportRoutingConfiguration(prouter, params.params);
//    TransportRoutePlanner planner = new TransportRoutePlanner();
//    TransportRoutingContext ctx = new TransportRoutingContext(cfg, files);
//    ctx.calculationProgress =  params.calculationProgress;
    return /*planner.buildRoute(ctx, params.start, params.end)*/nil;
}

- (OARouteCalculationParams *) getWalkingRouteParams
{

    OAApplicationMode *walkingMode = OAApplicationMode.PEDESTRIAN;

    __block OAWalkingRouteSegment *walkingRouteSegment = nil;
    dispatch_sync(_queue, ^{
        walkingRouteSegment = _walkingSegmentsToCalculate.firstObject;
        [_walkingSegmentsToCalculate removeObjectAtIndex:0];
    });
    if (!walkingRouteSegment)
        return nil;

    CLLocation *start = [[CLLocation alloc] initWithLatitude:walkingRouteSegment.start.coordinate.latitude longitude:walkingRouteSegment.start.coordinate.longitude];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:walkingRouteSegment.end.coordinate.latitude longitude:walkingRouteSegment.end.coordinate.longitude];

    _currentDistanceFromBegin = 0;
//            _params.calculationProgress.distanceFromBegin +
//                    (walkingRouteSegment.s1 != nil ? walkingRouteSegment.s1.getTravelDist() : 0);

    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.inPublicTransportMode = YES;
    params.start = start;
    params.end = end;
    params.startTransportStop = walkingRouteSegment.startTransportStop;
    params.targetTransportStop = walkingRouteSegment.endTransportStop;
    [OARoutingHelper applyApplicationSettings:params appMode:walkingMode];
    params.mode = walkingMode;
    params.calculationProgress = std::make_shared<RouteCalculationProgress>();
    params.calculationProgressCallback = self;
    params.resultListener = self;

    return params;
}

- (void) calculateWalkingRoutes:(NSArray<OATransportRouteResult *> *) routes
{
    _walkingSegmentsCalculated = NO;
    dispatch_sync(_queue, ^{
        [_walkingSegmentsToCalculate removeAllObjects];
    });
    
//    walkingRouteSegments.clear();
    if (routes && routes.count > 0)
    {
        for (OATransportRouteResult *r : routes)
        {
//            TransportRouteResultSegment prev = nil;
//            for (TransportRouteResultSegment s : r.getSegments()) {
//                LatLon start = prev != null ? prev.getEnd().getLocation() : params.start;
//                LatLon end = s.getStart().getLocation();
//                if (start != null && end != null) {
//                    if (prev == null || MapUtils.getDistance(start, end) > 50) {
//                        walkingSegmentsToCalculate.add(prev == null ?
//                                new WalkingRouteSegment(start, s) : new WalkingRouteSegment(prev, s));
//                    }
//                }
//                prev = s;
//            }
//            if (prev != null) {
//                walkingSegmentsToCalculate.add(new WalkingRouteSegment(prev, params.end));
//            }
        }
        OARouteCalculationParams *walkingRouteParams = [self getWalkingRouteParams];
        if (walkingRouteParams != nil)
        {
            [OARoutingHelper.sharedInstance startRouteCalculationThread:walkingRouteParams paramsChanged:YES updateProgress:YES];
            // wait until all segments calculated
            while (!_walkingSegmentsCalculated) {
                [NSThread sleepForTimeInterval:0.05];
                
                if (_params.calculationProgress->isCancelled())
                {
                    dispatch_sync(_queue, ^{
                        [_walkingSegmentsToCalculate removeAllObjects];
                    });
                    _walkingSegmentsCalculated = YES;
                }
            }
        }
    }
}

- (void) main
{
    @synchronized (_helper)
    {
        _helper.currentRunningJob = self;
        _helper.waitingNextJob = _prevRunningJob != nil;
    }
    
    if (_prevRunningJob)
    {
        while (_prevRunningJob.executing)
        {
            [NSThread sleepForTimeInterval:.05];
        }
        @synchronized (_helper)
        {
            _helper.currentRunningJob = self;
            _helper.waitingNextJob = false;
        }
    }
    
    NSArray<OATransportRouteResult *> *res = nil;
    NSString *error = nil;
    
    res = [self calculateRouteImpl:_params];
    if (res && !_params.calculationProgress->isCancelled())
    {
        [self calculateWalkingRoutes:res];
    }
    
    if (_params.calculationProgress->isCancelled())
    {
        @synchronized (_helper)
        {
            _helper.currentRunningJob = nil;
        }
        return;
    }
    
    @synchronized (_helper)
    {
        _helper.routes = res;
        
//        _helper.walkingRouteSegments = _walkingRouteSegments;
        if (res)
        {
            if (_params.resultListener)
                [_params.resultListener onRouteCalculated:res];
        }
        _helper.currentRunningJob = nil;
    }
    if (res)
    {
        [_helper setNewRoute:res];
    }
    else if (error)
    {
        _helper.lastRouteCalcError = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"error_calculating_route"), error];
//        _helper.lastRouteCalcErrorShort = OALocalizedString(@"error_calculating_route");
//        [_helper showMessage:_helper.lastRouteCalcError];
    }
    else
    {
        _helper.lastRouteCalcError = OALocalizedString(@"empty_route_calculated");
    }
}

#pragma mark - OARouteCalculationProgressCallback

- (void)start
{
}

- (void)requestPrivateAccessRouting
{
}

- (void)updateProgress:(int)progress
{
    double p = max(_params.calculationProgress->distanceFromBegin,
            _params.calculationProgress->distanceFromEnd);

    _params.calculationProgress->distanceFromBegin =
            max(_params.calculationProgress->distanceFromBegin, (float)(_currentDistanceFromBegin + p));
}

- (void)finish
{
    if (_walkingSegmentsToCalculate.count == 0)
    {
        _walkingSegmentsCalculated = YES;
    }
    else
    {
        [self updateProgress:0];
        OARouteCalculationParams *walkingRouteParams = [self getWalkingRouteParams];
        if (walkingRouteParams)
        {
            [OARoutingHelper.sharedInstance startRouteCalculationThread:walkingRouteParams paramsChanged:YES updateProgress:YES];
        }
    }
}

#pragma mark - OARouteCalculationResultListener

- (void)onRouteCalculated:(OARouteCalculationResult *)route
{
//    _walkingRouteSegments setObject forKey
//    walkingRouteSegments.put(new Pair<>(walkingRouteSegment.s1, walkingRouteSegment.s2), route);
}

@end

@implementation OATransportRoutingHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAApplicationMode *_applicationMode;
    
    OARoutingHelper *_routingHelper;

    
//    private Map<Pair<TransportRouteResultSegment, TransportRouteResultSegment>, RouteCalculationResult> walkingRouteSegments;
    
    NSInteger _currentRoute;
    
    CLLocation *_startLocation;
    CLLocation *_endLocation;
    
    id<OATransportRouteCalculationProgressCallback> _progressRoute;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        _routingHelper = OARoutingHelper.sharedInstance;

        _listeners = [NSMutableArray array];
        _applicationMode = OAApplicationMode.PUBLIC_TRANSPORT;
        
        
        _currentRoute = -1;
    }
    return self;
}

+ (OATransportRoutingHelper *) sharedInstance
{
    static OATransportRoutingHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OATransportRoutingHelper alloc] init];
    });
    return _sharedInstance;
}

- (OATransportRouteResult *) getActiveRoute
{
    return _routes != nil && _routes.count > _currentRoute && _currentRoute >= 0 ? _routes[_currentRoute] : nil;
}

- (OATransportRouteResult *) getCurrentRouteResult
{
    if (_routes && _currentRoute != -1 && _currentRoute < _routes.count) {
        return _routes[_currentRoute];
    }
    return nil;
}

- (NSArray<OATransportRouteResult *> *) getRoutes
{
    return _routes;
}

- (OARouteCalculationResult *) getWalkingRouteSegment:/*TransportRouteResultSegment s1, TransportRouteResultSegment s2)*/(id)s1 s2:(id)s2
{
//    if (walkingRouteSegments != null) {
//        return walkingRouteSegments.get(new Pair<>(s1, s2));
//    }
    return nil;
}

- (int) getWalkingTime:(/*@NonNull List<TransportRouteResultSegment>*/id) segments
{
    int res = 0;
//    Map<Pair<TransportRouteResultSegment, TransportRouteResultSegment>, RouteCalculationResult> walkingRouteSegments = this.walkingRouteSegments;
//    if (walkingRouteSegments != null) {
//        TransportRouteResultSegment prevSegment = null;
//        for (TransportRouteResultSegment segment : segments) {
//            RouteCalculationResult walkingRouteSegment = getWalkingRouteSegment(prevSegment, segment);
//            if (walkingRouteSegment != null) {
//                res += walkingRouteSegment.getRoutingTime();
//            }
//            prevSegment = segment;
//        }
//        if (segments.size() > 0) {
//            RouteCalculationResult walkingRouteSegment = getWalkingRouteSegment(segments.get(segments.size() - 1), null);
//            if (walkingRouteSegment != null) {
//                res += walkingRouteSegment.getRoutingTime();
//            }
//        }
//    }
    return res;
}

- (int) getWalkingDistance:(/*@NonNull List<TransportRouteResultSegment>*/id) segments
{
    int res = 0;
//    Map<Pair<TransportRouteResultSegment, TransportRouteResultSegment>, RouteCalculationResult> walkingRouteSegments = this.walkingRouteSegments;
//    if (walkingRouteSegments != null) {
//        TransportRouteResultSegment prevSegment = null;
//        for (TransportRouteResultSegment segment : segments) {
//            RouteCalculationResult walkingRouteSegment = getWalkingRouteSegment(prevSegment, segment);
//            if (walkingRouteSegment != null) {
//                res += walkingRouteSegment.getWholeDistance();
//            }
//            prevSegment = segment;
//        }
//        if (segments.size() > 0) {
//            RouteCalculationResult walkingRouteSegment = getWalkingRouteSegment(segments.get(segments.size() - 1), null);
//            if (walkingRouteSegment != null) {
//                res += walkingRouteSegment.getWholeDistance();
//            }
//        }
//    }
    return res;
}

- (void) setCurrentRoute:(int)currentRoute
{
    _currentRoute = currentRoute;
}

- (void) addListener:(id<OARouteInformationListener>)l
{
    @synchronized (_listeners)
    {
        if (![_listeners containsObject:l])
            [_listeners addObject:l];
    }
}

- (BOOL) removeListener:(id<OARouteInformationListener>)lt
{
    @synchronized (_listeners)
    {
        BOOL result = NO;
        NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
        for (id<OARouteInformationListener> l in _listeners)
        {
            if (!l || lt == l)
            {
                [inactiveListeners addObject:l];
                result = YES;
            }
        }
        [_listeners removeObjectsInArray:inactiveListeners];
        
        return result;
    }
}

- (void) recalculateRouteDueToSettingsChange
{
    [self clearCurrentRoute:_endLocation];
    [self recalculateRouteInBackground:_startLocation endLocation:_endLocation];
}

- (void) recalculateRouteInBackground:(CLLocation *)start endLocation:(CLLocation *)end
{
    if (!start || !end)
        return;
    
    OATransportRouteCalculationParams *params = [[OATransportRouteCalculationParams alloc] init];
    params.start = start;
    params.end = end;
    params.mode = _applicationMode;
    params.type = OSMAND;
    params.calculationProgress = std::make_shared<RouteCalculationProgress>();
    
    double rd = OsmAnd::Utilities::distance(OsmAnd::LatLon(start.coordinate.latitude, start.coordinate.longitude), OsmAnd::LatLon(end.coordinate.latitude, end.coordinate.longitude));
    params.calculationProgress->totalEstimatedDistance = rd * 1.5;
    
    [self startRouteCalculationThread:params];
}

- (void) startRouteCalculationThread:(OATransportRouteCalculationParams *) params
{
    @synchronized(self)
    {
        NSThread *prevRunningJob = _currentRunningJob;
        _settings.lastRoutingApplicationMode = _routingHelper.getAppMode;
        OATransportRouteRecalculationThread *newThread = [[OATransportRouteRecalculationThread alloc] initWithName:@"Calculating public transport route" params:params helper:self];
        _currentRunningJob = newThread;
        
        [self startProgress:params];
        [self updateProgress:params];
        if (prevRunningJob)
        {
            [newThread setWaitPrevJob:prevRunningJob];
        }
        [_currentRunningJob start];
    }
}

- (void) setProgressBar:(id<OATransportRouteCalculationProgressCallback>) progressRoute
{
    _progressRoute = progressRoute;
}

- (void) startProgress:(OATransportRouteCalculationParams *) params
{
    id<OATransportRouteCalculationProgressCallback> progressRoute = _progressRoute;
    if (progressRoute) {
        [progressRoute start];
    }
    [self setCurrentRoute:-1];
}

- (void) updateProgress:(OATransportRouteCalculationParams *) params
{
    id<OATransportRouteCalculationProgressCallback> progressRoute = _progressRoute;
    if (progressRoute)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            auto calculationProgress = params.calculationProgress;
            if ([self isRouteBeingCalculated])
            {
                float pr = calculationProgress->getLinearProgress();
                [_progressRoute updateProgress:(int) pr];
                NSThread *t = _currentRunningJob;
                if ([t isKindOfClass:[OATransportRouteRecalculationThread class]] && ((OATransportRouteRecalculationThread *) t).params != params)
                {
                    // different calculation started
                    return;
                }
                else
                {
                    [self updateProgress:params];
                }
            }
            else
            {
                if (_routes != nil && _routes.count > 0)
                {
                     [self setCurrentRoute:0];
                }
                [_progressRoute finish];
            }
        });
    }
}

- (BOOL) isRouteBeingCalculated
{
    return [_currentRunningJob isKindOfClass:OATransportRouteRecalculationThread.class] || _waitingNextJob;
}

- (void) setNewRoute:(NSArray<OATransportRouteResult *> *)res
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<OARouteInformationListener> listener in _listeners)
        {
            [listener newRouteIsCalculated:YES];
        }
        [_listeners removeAllObjects];
        
        NSLog(@"Public transport routes calculated: %ld", res.count);
    });
}

- (void) setFinalAndCurrentLocation:(CLLocation *) finalLocation currentLocation:(CLLocation *)currentLocation
{
    @synchronized (self)
    {
        [self clearCurrentRoute:finalLocation];
        // to update route
        [self setCurrentLocation:currentLocation];
    }
}

- (void) clearCurrentRoute:(CLLocation *) newFinalLocation
{
    @synchronized (self)
    {
        _currentRoute = -1;
        _routes = nil;
//        _walkingRouteSegments = nil;
        [OAWaypointHelper.sharedInstance setNewRoute:[[OARouteCalculationResult alloc] initWithErrorMessage:@""]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<OARouteInformationListener> listener in _listeners)
            {
                [listener routeWasCancelled];
            }
            [_listeners removeAllObjects];
        });
        
        
        _endLocation = newFinalLocation;
        if ([_currentRunningJob isKindOfClass:OATransportRouteRecalculationThread.class])
        {
            [((OATransportRouteRecalculationThread *) _currentRunningJob) stopCalculation];
        }
    }
    
}

- (void) setCurrentLocation:(CLLocation *) currentLocation
{
    if (!_endLocation || !currentLocation)
        return;
    
    _startLocation = currentLocation;
    [self recalculateRouteInBackground:currentLocation endLocation:_endLocation];
}

- (void) showMessage:(NSString *)msg
{
    NSLog(@"Public Transport error: %@", msg);
}

@end
