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
#import "OARouteCalculationResult.h"
#import "OAAppSettings.h"
#import "OATransportRouteCalculationParams.h"
#import "OARouteCalculationParams.h"
#import "Localization.h"
#import "OAWaypointHelper.h"
#import "QuadRect.h"
#import "OARouteProvider.h"
#import "OARootViewController.h"

#include <OsmAndCore/Utilities.h>
#include <transportRoutingObjects.h>
#include <routingConfiguration.h>
#include <transportRoutingConfiguration.h>
#include <transportRoutePlanner.h>
#include <transportRoutingContext.h>

@interface OAWalkingRouteSegment : NSObject

@property (nonatomic) std::shared_ptr<TransportRouteResultSegment> s1;
@property (nonatomic) std::shared_ptr<TransportRouteResultSegment> s2;

@property (nonatomic) CLLocation *start;
@property (nonatomic) BOOL startTransportStop;
@property (nonatomic) CLLocation *end;
@property (nonatomic) BOOL endTransportStop;

- (instancetype) initWithTransportRouteResultSegment:(std::shared_ptr<TransportRouteResultSegment>) s1 s2:(std::shared_ptr<TransportRouteResultSegment>) s2;
- (instancetype) initWithStartLocation:(CLLocation *) start segment:(std::shared_ptr<TransportRouteResultSegment>) s;
- (instancetype) initWithRouteResultSegment:(std::shared_ptr<TransportRouteResultSegment>)s end:(CLLocation *)end;

@end

@implementation OAWalkingRouteSegment

- (instancetype) initWithTransportRouteResultSegment:(std::shared_ptr<TransportRouteResultSegment>) s1 s2:(std::shared_ptr<TransportRouteResultSegment>) s2
{
    self = [super init];
    if (self) {
        _s1 = s1;
        _s2 = s2;

        _start = [[CLLocation alloc] initWithLatitude:s1->getEnd().lat longitude:s1->getEnd().lon];
        _end = [[CLLocation alloc] initWithLatitude:s2->getStart().lat longitude:s2->getStart().lon];
        
        _startTransportStop = YES;
        _endTransportStop = YES;
    }
    return self;
}

- (instancetype) initWithStartLocation:(CLLocation *) start segment:(std::shared_ptr<TransportRouteResultSegment>) s
{
    self = [super init];
    if (self) {
        _start = start;
        _s2 = s;
        _end = [[CLLocation alloc] initWithLatitude:_s2->getStart().lat longitude:_s2->getStart().lon];
        _endTransportStop = YES;
    }
    return self;
}

- (instancetype) initWithRouteResultSegment:(std::shared_ptr<TransportRouteResultSegment>)s end:(CLLocation *)end
{
    self = [super init];
    if (self) {
        _s1 = s;
        _end = end;
        _start = [[CLLocation alloc] initWithLatitude:_s1->getEnd().lat longitude:_s1->getEnd().lon];
        _startTransportStop = true;
    }
    return self;
}

@end

@implementation OATransportRouteResultSegment
- (instancetype) initWithSegment:(std::shared_ptr<TransportRouteResultSegment>)seg
{
    self = [super init];
    if (self) {
        _segment = seg;
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        OATransportRouteResultSegment *seg = other;
        return _segment == seg->_segment;
    }
}

- (NSUInteger)hash
{
    unsigned long long hash = 0;
    if (_segment == nullptr)
        return hash;
    
    if (_segment->getStart().x31 != -1 && _segment->getStart().y31 != -1)
        hash += (_segment->getStart().id);
    if (_segment->getEnd().x31 != -1 && _segment->getEnd().y31 != -1)
        hash += (_segment->getEnd().id);
    return hash^(hash >> 32);
}

@end

@interface OATransportRoutingHelper()

@property (nonatomic) std::vector<std::shared_ptr<TransportRouteResult>> routes;
@property (nonatomic) NSThread *currentRunningJob;

@property (nonatomic) NSString *lastRouteCalcError;
@property (nonatomic) NSString *lastRouteCalcErrorShort;
@property (nonatomic) BOOL waitingNextJob;

@property (nonatomic) NSMutableArray<id<OARouteInformationListener>> *listeners;

- (void) setNewRoute:(std::vector<SHARED_PTR<TransportRouteResult>>)res;
- (void) showMessage:(NSString *)msg;

@end

@interface OATransportRouteRecalculationThread : NSThread <OARouteCalculationProgressCallback, OARouteCalculationResultListener>

@property (nonatomic) OATransportRouteCalculationParams *params;
@property (nonatomic) NSThread *prevRunningJob;

@property (nonatomic) BOOL walkingSegmentsCalculated;

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
    NSMapTable<NSArray<OATransportRouteResultSegment *> *, OARouteCalculationResult *> *_walkingRouteSegments;
    
    double _currentDistanceFromBegin;
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
        _walkingRouteSegments = [NSMapTable strongToStrongObjectsMapTable];

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

- (vector<SHARED_PTR<TransportRouteResult>>) calculateRouteImpl:(OATransportRouteCalculationParams *)params
{
    vector<SHARED_PTR<TransportRouteResult>> res;
    auto config = _app.defaultRoutingConfig;
    MAP_STR_STR paramsRes;
    auto router = [OARouteProvider getRouter:params.mode];
    auto paramsMap = router->getParameters();
    for (auto it = paramsMap.begin(); it != paramsMap.end(); ++it)
    {
        std::string key = it->first;
        RoutingParameter pr = it->second;
        std::string vl;
        if (pr.type == RoutingParameterType::BOOLEAN)
        {
            OAProfileBoolean *pref = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:key.c_str()] defaultValue:pr.defaultBoolean];
            BOOL b = [pref get:params.mode];
            vl = b ? "true" : "";
        }
        else
        {
            vl = [[[_settings getCustomRoutingProperty:[NSString stringWithUTF8String:key.c_str()] defaultValue:@""] get:params.mode] UTF8String];
        }
        
        if (vl.length() > 0)
            paramsRes.insert(std::pair<string, string>(key, vl));
    }
    params.params = paramsRes;
    
    auto cfg = make_shared<TransportRoutingConfiguration>(router, params.params);
    const auto planner = unique_ptr<TransportRoutePlanner>(new TransportRoutePlanner());
    auto ctx = unique_ptr<TransportRoutingContext>(new TransportRoutingContext(cfg));
    ctx->startX = get31TileNumberX(params.start.coordinate.longitude);
    ctx->startY = get31TileNumberY(params.start.coordinate.latitude);
    ctx->targetX = get31TileNumberX(params.end.coordinate.longitude);
    ctx->targetY = get31TileNumberY(params.end.coordinate.latitude);
    ctx->calculationProgress = params.calculationProgress;
    
    int leftX = get31TileNumberX(params.start.coordinate.longitude);
    int rightX = leftX;
    int bottomY = get31TileNumberY(params.start.coordinate.latitude);
    int topY = bottomY;
    
    CLLocation *l = params.end;
    leftX = MIN(get31TileNumberX(l.coordinate.longitude), leftX);
    rightX = MAX(get31TileNumberX(l.coordinate.longitude), rightX);
    bottomY = MAX(get31TileNumberY(l.coordinate.latitude), bottomY);
    topY = MIN(get31TileNumberY(l.coordinate.latitude), topY);
    
    [OARoutingHelper.sharedInstance.getRouteProvider checkInitialized:15 leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
    
    planner->buildTransportRoute(ctx, res);
    
    return res;
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
    _params.calculationProgress->distanceFromBegin +=
                (walkingRouteSegment.s1 != nullptr ? walkingRouteSegment.s1->getTravelDist() : 0);

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
    params.walkingRouteSegment = walkingRouteSegment;

    return params;
}

- (void) calculateWalkingRoutes:(vector<SHARED_PTR<TransportRouteResult>>) routes
{
    _walkingSegmentsCalculated = NO;
    dispatch_sync(_queue, ^{
        [_walkingSegmentsToCalculate removeAllObjects];
    });
    
    [_walkingRouteSegments removeAllObjects];
    if (routes.size() > 0)
    {
        for (SHARED_PTR<TransportRouteResult>& r : routes)
        {
            SHARED_PTR<TransportRouteResultSegment> prev = nullptr;
            for (SHARED_PTR<TransportRouteResultSegment>& s : r->segments)
            {
                CLLocation *start = prev != nullptr ? [[CLLocation alloc] initWithLatitude:prev->getEnd().lat longitude:prev->getEnd().lon] : _params.start;
                CLLocation *end = [[CLLocation alloc] initWithLatitude:s->getStart().lat longitude:s->getStart().lon];

                if (start != nil && end != nil)
                {
                    if (prev == nullptr || OsmAnd::Utilities::distance(OsmAnd::LatLon(start.coordinate.latitude, start.coordinate.longitude), OsmAnd::LatLon(end.coordinate.latitude, end.coordinate.longitude)) > 50)
                    {
                        OAWalkingRouteSegment *seg;
                        if (prev == nullptr)
                            seg = [[OAWalkingRouteSegment alloc] initWithStartLocation:start segment:s];
                        else
                            seg = [[OAWalkingRouteSegment alloc] initWithTransportRouteResultSegment:prev s2:s];
                        dispatch_sync(_queue, ^{
                            [_walkingSegmentsToCalculate addObject:seg];
                        });
                    }
                }
                prev = s;
            }
            if (prev != nullptr)
            {
                dispatch_sync(_queue, ^{
                    [_walkingSegmentsToCalculate addObject:[[OAWalkingRouteSegment alloc] initWithRouteResultSegment:prev end:_params.end]];
                });
            }
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
    
    NSString *error = nil;
    
    auto res = [self calculateRouteImpl:_params];
    if (res.size() != 0 && !_params.calculationProgress->isCancelled())
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
        
        _helper.walkingRouteSegments = _walkingRouteSegments;
        if (res.size() > 0)
        {
            if (_params.resultListener)
                [_params.resultListener onRouteCalculated:res];
        }
        _helper.currentRunningJob = nil;
    }

    if (error)
    {
        _helper.lastRouteCalcError = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"error_calculating_route"), error];
        _helper.lastRouteCalcErrorShort = OALocalizedString(@"error_calculating_route");
    }
    else
    {
        _helper.lastRouteCalcError = OALocalizedString(@"empty_route_calculated");
    }
    [_helper setNewRoute:res];
}

#pragma mark - OARouteCalculationProgressCallback

- (void)startProgress
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

- (void)onRouteCalculated:(OARouteCalculationResult *)route segment:(OAWalkingRouteSegment *)segment
{
    if (segment)
    {
        [_walkingRouteSegments setObject:route forKey:@[[[OATransportRouteResultSegment alloc] initWithSegment:segment.s1], [[OATransportRouteResultSegment alloc] initWithSegment:segment.s2]]];
    }
}

@end

@implementation OATransportRoutingHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSMutableArray<id<OATransportRouteCalculationProgressCallback>> *_progressRoutes;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        _listeners = [NSMutableArray array];
        _applicationMode = OAApplicationMode.PUBLIC_TRANSPORT;
        _progressRoutes = [NSMutableArray new];
        
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

- (SHARED_PTR<TransportRouteResult>) getActiveRoute
{
    return _routes.size() > _currentRoute && _currentRoute >= 0 ? _routes[_currentRoute] : nullptr;
}

- (SHARED_PTR<TransportRouteResult>) getCurrentRouteResult
{
    if (_currentRoute != -1 && _currentRoute < _routes.size())
    {
        return _routes[_currentRoute];
    }
    return nil;
}

- (std::vector<SHARED_PTR<TransportRouteResult>>) getRoutes
{
    return _routes;
}

- (OARouteCalculationResult *) getWalkingRouteSegment:(OATransportRouteResultSegment *)s1 s2:(OATransportRouteResultSegment *)s2
{
    if (_walkingRouteSegments)
    {
        return [_walkingRouteSegments objectForKey:@[s1, s2]];
    }
    return nil;
}

- (NSInteger) getWalkingTime:(vector<SHARED_PTR<TransportRouteResultSegment>>&) segments
{
    NSInteger res = 0;
    if (_walkingRouteSegments)
    {
        SHARED_PTR<TransportRouteResultSegment> prevSegment = nullptr;
        for (const auto& segment : segments)
        {
            OARouteCalculationResult *walkingRouteSegment = [self getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:prevSegment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:segment]];
            if (walkingRouteSegment)
            {
                res += walkingRouteSegment.routingTime;
            }
            prevSegment = segment;
        }
        if (segments.size() > 0)
        {
            OARouteCalculationResult *walkingRouteSegment = [self getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segments[segments.size() - 1]] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nullptr]];
            if (walkingRouteSegment)
            {
                res += walkingRouteSegment.routingTime;
            }
        }
    }
    return res;
}

- (NSInteger) getWalkingDistance:(vector<SHARED_PTR<TransportRouteResultSegment>>&) segments
{
    NSInteger res = 0;
    if (_walkingRouteSegments)
    {
        SHARED_PTR<TransportRouteResultSegment> prevSegment = nullptr;
        for (const auto& segment : segments)
        {
            OARouteCalculationResult *walkingRouteSegment = [self getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:prevSegment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:segment]];
            if (walkingRouteSegment)
            {
                res += walkingRouteSegment.getWholeDistance;
            }
            prevSegment = segment;
        }
        if (segments.size() > 0)
        {
            OARouteCalculationResult *walkingRouteSegment = [self getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segments[segments.size() - 1]] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nullptr]];
            if (walkingRouteSegment)
            {
                res += walkingRouteSegment.getWholeDistance;
            }
        }
    }
    return res;
}

- (void) setCurrentRoute:(NSInteger)currentRoute
{
    _currentRoute = currentRoute;
}

- (NSString *) getLastRouteCalcError
{
    return _lastRouteCalcError;
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
    
    double rd = OsmAnd::Utilities::distance(OsmAnd::LatLon(start.coordinate.longitude, start.coordinate.latitude), OsmAnd::LatLon(end.coordinate.longitude, end.coordinate.latitude));
    params.calculationProgress->totalEstimatedDistance = rd * 1.5;
    
    [self startRouteCalculationThread:params];
}

- (void) startRouteCalculationThread:(OATransportRouteCalculationParams *) params
{
    @synchronized(self)
    {
        NSThread *prevRunningJob = _currentRunningJob;
        _settings.lastRoutingApplicationMode = OARoutingHelper.sharedInstance.getAppMode;
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

- (void) addProgressBar:(id<OATransportRouteCalculationProgressCallback>) progressRoute
{
    [_progressRoutes addObject:progressRoute];
}

- (void) startProgress:(OATransportRouteCalculationParams *) params
{
    for (id<OATransportRouteCalculationProgressCallback> pr in _progressRoutes)
    {
        [pr start];
    }
    [self setCurrentRoute:-1];
}

- (void) updateProgress:(OATransportRouteCalculationParams *) params
{
    if (_progressRoutes && _progressRoutes.count > 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            auto calculationProgress = params.calculationProgress;
            if ([self isRouteBeingCalculated])
            {
                float pr = MAX(calculationProgress->distanceFromBegin, calculationProgress->distanceFromEnd);
                for (id<OATransportRouteCalculationProgressCallback> progressRoute in _progressRoutes)
                    [progressRoute updateProgress:(int) pr];
                
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
                for (id<OATransportRouteCalculationProgressCallback> progressRoute in _progressRoutes)
                    [progressRoute finish];
            }
        });
    }
}

- (BOOL) isRouteBeingCalculated
{
    return [_currentRunningJob isKindOfClass:OATransportRouteRecalculationThread.class] || _waitingNextJob;
}

- (OABBox) getBBox
{
    double left = DBL_MAX;
    double top = DBL_MAX;
    double right = DBL_MAX;
    double bottom = DBL_MAX;
    if (![self isRouteBeingCalculated] && _routes.size() > 0 && _currentRoute != -1)
    {
        const auto& segments = _routes[_currentRoute]->segments;
        
        for (const auto& seg : segments)
        {
            vector<std::shared_ptr<Way>> list;
            seg->getGeometry(list);
            for (const auto& way : list)
            {
                for (const auto& node : way->nodes)
                {
                    if (left == DBL_MAX)
                    {
                        left = node.lon;
                        right = node.lon;
                        top = node.lat;
                        bottom = node.lat;
                    }
                    else
                    {
                        left = MIN(left, node.lon);
                        right = MAX(right, node.lon);
                        top = MAX(top, node.lat);
                        bottom = MIN(bottom, node.lat);
                    }
                }
            }
        }
    }
    OABBox result;
    result.bottom = bottom;
    result.top = top;
    result.left = left;
    result.right = right;
    return result;
}

- (void) setNewRoute:(std::vector<SHARED_PTR<TransportRouteResult>>)res
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (res.size() > 0)
             [self setCurrentRoute:0];

        for (id<OARouteInformationListener> listener in _listeners)
        {
            [listener newRouteIsCalculated:YES];
        }
        NSLog(@"Public transport routes calculated: %ld", res.size());
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
        _routes.clear();
        _walkingRouteSegments = nil;
        [OAWaypointHelper.sharedInstance setNewRoute:[[OARouteCalculationResult alloc] initWithErrorMessage:@""]];
        
        // Do not reset route twice (e.g. if not in the pulic transport mode)
        if (OARoutingHelper.sharedInstance.isPublicTransportMode)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (id<OARouteInformationListener> listener in _listeners)
                {
                    [listener routeWasCancelled];
                }
            });
        }
        
        
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
