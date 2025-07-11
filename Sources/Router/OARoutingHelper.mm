//
//  OARoutingHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingHelper.h"
#import "OARoutingHelper+cpp.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OARouteProvider.h"
#import "OARouteCalculationResult.h"
#import "OAAppSettings.h"
#import "OAVoiceRouter.h"
#import "OAObservable.h"
#import "OAMapUtils.h"
#import "Localization.h"
#import "OATargetPointsHelper.h"
#import "OARouteCalculationParams.h"
#import "OAWaypointHelper.h"
#import "OARouteDirectionInfo.h"
#import "OATTSCommandPlayerImpl.h"
#import "OAGPXUIHelper.h"
#import "OARouteExporter.h"
#import "OATransportRoutingHelper.h"
#import "OAGpxRouteApproximation.h"
#import "OACurrentStreetName.h"
#import "OARouteRecalculationHelper.h"
#import "OARoutingHelperUtils.h"
#import "OARTargetPoint.h"
#import "OAResultMatcher.h"
#import "OAApplicationMode.h"
#import "CLLocation+Extension.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <OsmAndCore/Utilities.h>
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#include <routeSegmentResult.h>

#define DEFAULT_GPS_TOLERANCE 12
#define POSITION_TOLERANCE 60
#define POS_TOLERANCE_DEVIATION_MULTIPLIER 2
#define MAX_POSSIBLE_SPEED 340 // ~ 1 Mach

static NSInteger GPS_TOLERANCE = DEFAULT_GPS_TOLERANCE;
static double ARRIVAL_DISTANCE_FACTOR = 1;

@interface OARoutingHelper()

@property (nonatomic) OARouteCalculationResult *route;

- (void) showMessage:(NSString *)msg;

@end

@implementation OARoutingHelper
{
    NSMutableArray<id<OARouteInformationListener>> *_listeners;

    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARouteRecalculationHelper *_recalcHelper;

    BOOL _isFollowingMode;
    BOOL _isRoutePlanningMode;
    BOOL _isPauseNavigation;
    
    OAGPXRouteParamsBuilder *_currentGPXRoute;
    
    CLLocation *_finalLocation;
    NSMutableArray<CLLocation *> *_intermediatePoints;
    CLLocation *_lastProjection;
    CLLocation *_lastFixedLocation;
    CLLocation *_lastGoodRouteLocation;
    
    OAApplicationMode *_mode;
    
    NSTimeInterval _deviateFromRouteDetected;
    //long _wrongMovementDetected;
    BOOL _voiceRouterStopped;
    BOOL _deviceHasBearing;
    
    OATransportRoutingHelper *_transportRoutingHelper;
}

static BOOL _isDeviatedFromRoute = false;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        _listeners = [NSMutableArray array];
        _route = [[OARouteCalculationResult alloc] initWithErrorMessage:@""];
        
        _voiceRouter = [[OAVoiceRouter alloc] initWithHelper:self];
        [_voiceRouter setPlayer:[[OATTSCommandPlayerImpl alloc] initWithVoiceRouter:_voiceRouter voiceProvider:[_settings.voiceProvider get]]];
        _provider = [[OARouteProvider alloc] init];
        _recalcHelper = [[OARouteRecalculationHelper alloc] initWithRoutingHelper:self];

        [self setAppMode:_settings.applicationMode.get];
        _transportRoutingHelper = OATransportRoutingHelper.sharedInstance;
        _routingModeChangedObservable  = [[OAObservable alloc] init];
    }
    return self;
}

+ (OARoutingHelper *) sharedInstance
{
    static OARoutingHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OARoutingHelper alloc] init];
    });
    return _sharedInstance;
}

- (void) setAppMode:(OAApplicationMode *)mode
{
    _mode = mode;
    ARRIVAL_DISTANCE_FACTOR = MAX([_settings.arrivalDistanceFactor get:mode], 0.1f);
    GPS_TOLERANCE = (NSInteger) (DEFAULT_GPS_TOLERANCE * ARRIVAL_DISTANCE_FACTOR);
    [_voiceRouter updateAppMode];
    [_routingModeChangedObservable notifyEventWithKey:mode];
}

- (OAApplicationMode *) getAppMode
{
    return _mode;
}

- (OARouteProvider *) getRouteProvider
{
    return _provider;
}

- (BOOL) isFollowingMode
{
    return _isFollowingMode;
}

- (OAVoiceRouter *) getVoiceRouter
{
    return _voiceRouter;
}

- (NSString *) getLastRouteCalcError
{
    return _recalcHelper.lastRouteCalcError;
}

- (NSString *) getLastRouteCalcErrorShort
{
    return _recalcHelper.lastRouteCalcErrorShort;
}

- (void) setPauseNaviation:(BOOL) b
{
    _isPauseNavigation = b;
    if (b)
    {
        // TODO notifications
        //app.getNotificationHelper().updateTopNotification();
        //app.getNotificationHelper().refreshNotifications();
    }
}

- (BOOL) isPauseNavigation
{
    return _isPauseNavigation;
}

- (void) setFollowingMode:(BOOL)follow
{
    _isFollowingMode = follow;
    _isPauseNavigation = false;
    if (!follow)
    {
        // TODO notifications
        //app.getNotificationHelper().updateTopNotification();
        //app.getNotificationHelper().refreshNotifications();
    }
}

- (BOOL) isRoutePlanningMode
{
    return _isRoutePlanningMode;
}

- (void) setRoutePlanningMode:(BOOL)isRoutePlanningMode
{
    _isRoutePlanningMode = isRoutePlanningMode;
}

- (BOOL) isRouteCalculated
{
    return _route.isCalculated;
}

- (BOOL) isRouteBeingCalculated
{
    return _recalcHelper.isRouteBeingCalculated;
}

- (void) addListener:(id<OARouteInformationListener>)l
{
    @synchronized (_listeners)
    {
        if (![_listeners containsObject:l])
            [_listeners addObject:l];
        [_transportRoutingHelper addListener:l];
    }
}

- (OABBox) getBBox
{
    double left = DBL_MAX;
    double top = DBL_MAX;
    double right = DBL_MAX;
    double bottom = DBL_MAX;
    if ([self isRouteCalculated])
    {
        NSArray<CLLocation *> *locations = [_route getImmutableAllLocations];
        
        for (CLLocation *loc : locations)
        {
            if (left == DBL_MAX)
            {
                left = loc.coordinate.longitude;
                right = loc.coordinate.longitude;
                top = loc.coordinate.latitude;
                bottom = loc.coordinate.latitude;
            }
            else
            {
                left = MIN(left, loc.coordinate.longitude);
                right = MAX(right, loc.coordinate.longitude);
                top = MAX(top, loc.coordinate.latitude);
                bottom = MIN(bottom, loc.coordinate.latitude);
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
        [_transportRoutingHelper removeListener:lt];
        return result;
    }
}

- (void) addCalculationProgressCallback:(id<OARouteCalculationProgressCallback>)callback
{
    [_recalcHelper addCalculationProgressCallback:callback];
}

- (void)newRouteHasMissingOrOutdatedMaps:(NSArray<OAWorldRegion *> *)missingMaps
                            mapsToUpdate:(NSArray<OAWorldRegion *> *)mapsToUpdate
                     potentiallyUsedMaps:(NSArray<OAWorldRegion *> *)potentiallyUsedMaps
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (_listeners)
        {
            NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
            for (id<OARouteInformationListener> l in _listeners)
            {
                if (l && [l respondsToSelector:@selector(newRouteHasMissingOrOutdatedMaps:mapsToUpdate:potentiallyUsedMaps:)])
                    [l newRouteHasMissingOrOutdatedMaps:missingMaps mapsToUpdate:mapsToUpdate potentiallyUsedMaps:potentiallyUsedMaps];
                else
                    [inactiveListeners addObject:l];
            }
            [_listeners removeObjectsInArray:inactiveListeners];
        }
    });
}

- (void) newRouteCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (_listeners)
        {
            NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
            for (id<OARouteInformationListener> l in _listeners)
            {
                if (l)
                    [l newRouteIsCalculated:newRoute];
                else
                    [inactiveListeners addObject:l];
            }
            [_listeners removeObjectsInArray:inactiveListeners];
        }
    });
}

- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation
{
    @synchronized (self)
    {
        OARouteCalculationResult *previousRoute = _route;
        [self clearCurrentRoute:finalLocation newIntermediatePoints:intermediatePoints];
        [OARoutingHelperUtils updateDrivingRegionIfNeeded:currentLocation force:NO];
        // to update route
        [self setCurrentLocation:currentLocation returnUpdatedLocation:NO previousRoute:previousRoute targetPointsChanged:YES];
    }
}

- (double) getArrivalDistance
{
    OAApplicationMode *m = _mode == nil ? _settings.applicationMode.get : _mode;
    float defaultSpeed = MAX(0.3f, [m getDefaultSpeed]);

    /// Used to be: car - 90 m, bicycle - 50 m, pedestrian - 20 m
    // return ((float)settings.getApplicationMode().getArrivalDistance()) * settings.ARRIVAL_DISTANCE_FACTOR.getModeValue(m);
    // GPS_TOLERANCE - 12 m
    // 5 seconds: car - 80 m @ 50 kmh, bicyle - 45 m @ 25 km/h, bicyle - 25 m @ 10 km/h, pedestrian - 18 m @ 4 km/h,
    return GPS_TOLERANCE + defaultSpeed * 5 * ARRIVAL_DISTANCE_FACTOR;
}

- (void) showMessage:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO toast
        // show message
    });
}

- (double) getRouteDeviation
{
    @synchronized(self)
    {
        if (!_route || [_route getImmutableAllDirections].count < 2 || _route.currentRoute == 0 || _route.currentRoute >= [_route getImmutableAllDirections].count)
            return 0;
        
        NSArray<CLLocation *> *routeNodes = [_route getImmutableAllLocations];
        return [OAMapUtils getOrthogonalDistance:_lastFixedLocation fromLocation:routeNodes[_route.currentRoute - 1] toLocation:routeNodes[_route.currentRoute]];
    }
}

- (OANextDirectionInfo *) getNextRouteDirectionInfo:(OANextDirectionInfo *)info toSpeak:(BOOL)toSpeak
{
    @synchronized(self)
    {
        OANextDirectionInfo *i = [_route getNextRouteDirectionInfo:info fromLoc:_lastProjection toSpeak:toSpeak];
        if (i)
            i.imminent = [_voiceRouter calculateImminent:i.distanceTo loc:_lastProjection];
        
        return i;
    }
}

- (OANextDirectionInfo *) getNextRouteDirectionInfoAfter:(OANextDirectionInfo *)previous to:(OANextDirectionInfo *)to toSpeak:(BOOL)toSpeak
{
    @synchronized(self)
    {
        OANextDirectionInfo *i = [_route getNextRouteDirectionInfoAfter:previous next:to toSpeak:toSpeak];
        if (i)
            i.imminent = [_voiceRouter calculateImminent:i.distanceTo loc:nil];

        return i;
    }
}

- (std::shared_ptr<RouteSegmentResult>) getCurrentSegmentResult
{
    return [_route getCurrentSegmentResult];
}

- (std::shared_ptr<RouteSegmentResult>) getNextStreetSegmentResult
{
    return [_route getNextStreetSegmentResult];
}

- (BOOL) identifyUTurnIsNeeded:(CLLocation *)currentLocation posTolerance:(float)posTolerance
{
    if (!_finalLocation || !currentLocation || ![_route isCalculated] || self.isPublicTransportMode)
        return false;
    
    BOOL isOffRoute = false;
    if (currentLocation.course >= 0)
    {
        auto bearingMotion = currentLocation.course;
        CLLocation *nextRoutePosition = [_route getNextRouteLocation];
        float bearingToRoute = [currentLocation bearingTo:nextRoutePosition];
        double diff = degreesDiff(bearingMotion, bearingToRoute);
        // 7. Check if you left the route and an unscheduled U-turn would bring you back (also Issue 863)
        // This prompt is an interim advice and does only sound if a new route in forward direction could not be found in x seconds
        if (ABS(diff) > 135.0)
        {
            float d = [currentLocation distanceFromLocation:nextRoutePosition];
            // 60m tolerance to allow for GPS inaccuracy
            if (d > posTolerance)
            {
                // require x sec continuous since first detection
                if (_deviateFromRouteDetected == 0)
                {
                    _deviateFromRouteDetected = [[NSDate date] timeIntervalSince1970];
                }
                else if ([[NSDate date] timeIntervalSince1970] - _deviateFromRouteDetected > 10)
                {
                    isOffRoute = true;
                    //log.info("bearingMotion is opposite to bearingRoute"); //$NON-NLS-1$
                }
            }
        }
        else
        {
            _deviateFromRouteDetected = 0;
        }
    }
    return isOffRoute;
}

- (int) calculateCurrentRoute:(CLLocation *)currentLocation posTolerance:(float)posTolerance routeNodes:(NSArray<CLLocation *> *)routeNodes currentRoute:(int)currentRoute updateAndNotify:(BOOL)updateAndNotify
{
    // 1. Try to proceed to next point using orthogonal distance (finding minimum orthogonal dist)
    while (currentRoute + 1 < routeNodes.count)
    {
        double dist = [currentLocation distanceFromLocation:routeNodes[currentRoute]];
        if (currentRoute > 0)
            dist = [OAMapUtils getOrthogonalDistance:currentLocation fromLocation:routeNodes[currentRoute - 1] toLocation:routeNodes[currentRoute]];

        BOOL processed = false;
        // if we are still too far try to proceed many points
        // if not then look ahead only 3 in order to catch sharp turns
        BOOL longDistance = dist >= 250;
        int newCurrentRoute = [OARoutingHelperUtils lookAheadFindMinOrthogonalDistance:currentLocation routeNodes:routeNodes currentRoute:currentRoute iterations:longDistance ? 15 : 8];
        double newDist = [OAMapUtils getOrthogonalDistance:currentLocation fromLocation:routeNodes[newCurrentRoute] toLocation:routeNodes[newCurrentRoute + 1]];
        if (longDistance)
        {
            if (newDist < dist)
            {
                NSLog(@"Processed by distance : (new) %f (old) %f", newDist, dist);
                processed = true;
            }
        }
        else if (newDist < dist || newDist < (posTolerance / 8))
        {
            // newDist < posTolerance / 8 - 4-8 m (avoid distance 0 till next turn)
            if (dist > posTolerance)
            {
                processed = true;
                NSLog(@"Processed by distance : %f %f", newDist, dist);
            }
            else
            {
                if ([currentLocation hasBearing] && !_deviceHasBearing)
                {
                    _deviceHasBearing = YES;
                }
                // lastFixedLocation.bearingTo -  gives artefacts during u-turn, so we avoid for devices with bearing
                if ((currentRoute > 0 || newCurrentRoute > 0) &&
                        ([currentLocation hasBearing] || (!_deviceHasBearing && _lastFixedLocation)))
                {
                    float bearingToRoute = [currentLocation bearingTo:routeNodes[currentRoute]];
                    float bearingRouteNext = [routeNodes[newCurrentRoute] bearingTo:routeNodes[newCurrentRoute + 1]];
                    float bearingMotion = [currentLocation hasBearing] ? currentLocation.course : [_lastFixedLocation bearingTo:currentLocation];
                    double diff = ABS(degreesDiff(bearingMotion, bearingToRoute));
                    double diffToNext = ABS(degreesDiff(bearingMotion, bearingRouteNext));
                    if (diff > diffToNext)
                    {
                        NSLog(@"Processed point bearing deltas : %f %f", diff, diffToNext);
                        processed = true;
                    }
                }
            }
        }
        if (processed)
        {
            // that node already passed
            currentRoute = newCurrentRoute + 1;
            if (updateAndNotify)
            {
                [_route updateCurrentRoute:newCurrentRoute + 1];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @synchronized (_listeners)
                    {
                        NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
                        for (id<OARouteInformationListener> l in _listeners)
                        {
                            if (l)
                                [l routeWasUpdated];
                            else
                                [inactiveListeners addObject:l];
                        }
                        [_listeners removeObjectsInArray:inactiveListeners];
                    }
                });
            }

            // TODO notifications
            //app.getNotificationHelper().refreshNotification(NotificationType.NAVIGATION);
        }
        else
        {
            break;
        }
    }
    return currentRoute;
}

- (BOOL) updateCurrentRouteStatus:(CLLocation *)currentLocation posTolerance:(float)posTolerance
{
    NSArray<CLLocation *> *routeNodes = [_route getImmutableAllLocations];
    int currentRoute = _route.currentRoute;

    // 1. Try to proceed to next point using orthogonal distance (finding minimum orthogonal dist)
    currentRoute = [self calculateCurrentRoute:currentLocation posTolerance:posTolerance routeNodes:routeNodes currentRoute:_route.currentRoute updateAndNotify:YES];
    
    // 2. check if intermediate found
    if ([_route getIntermediatePointsToPass]  > 0
        && [_route getDistanceToNextIntermediate:_lastFixedLocation] < [self getArrivalDistance] * 2.0 && !_isRoutePlanningMode)
    {
        [self showMessage:OALocalizedString(@"arrived_at_intermediate_point")];
        [_route passIntermediatePoint];
        OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
        NSString *name = @"";
        if (_intermediatePoints && _intermediatePoints.count > 0)
        {
            CLLocation *rm = _intermediatePoints[0];
            [_intermediatePoints removeObjectAtIndex:0];
            NSArray<OARTargetPoint *> *ll = [targets getIntermediatePointsNavigation];
            int ind = -1;
            for (int i = 0; i < ll.count; i++)
            {
                if (ll[i].point && [ll[i].point distanceFromLocation:rm] < 5)
                {
                    name = [ll[i] getOnlyName];
                    ind = i;
                    break;
                }
            }
            if (ind >= 0)
                [targets removeWayPoint:false index:ind];
        }
        if (_isFollowingMode)
            [_voiceRouter arrivedIntermediatePoint:name];
        
        // double check
        while (_intermediatePoints && [_route getIntermediatePointsToPass] < _intermediatePoints.count)
        {
            [_intermediatePoints removeObjectAtIndex:0];
        }
    }
    
    // 3. check if destination found
    CLLocation *lastPoint = routeNodes[routeNodes.count - 1];
    if (currentRoute > routeNodes.count - 3
        && [currentLocation distanceFromLocation:lastPoint] < [self getArrivalDistance]
        && !_isRoutePlanningMode)
    {
        //showMessage(app.getString(R.string.arrived_at_destination));
        OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
        OARTargetPoint *tp = [targets getPointToNavigate];
        NSString *description = tp == nil ? @"" : [tp getOnlyName];
        if (_isFollowingMode)
            [_voiceRouter arrivedDestinationPoint:description];
        
        BOOL onDestinationReached = true; //OsmandPlugin.onDestinationReached();
        //onDestinationReached &= app.getAppCustomization().onDestinationReached();
        if (onDestinationReached)
        {
            [self clearCurrentRoute:nil newIntermediatePoints:nil];
            [self setRoutePlanningMode:false];
            dispatch_async(dispatch_get_main_queue(), ^{
                /* TODO
                settings.LAST_ROUTING_APPLICATION_MODE = settings.APPLICATION_MODE.get();
                settings.APPLICATION_MODE.set(settings.DEFAULT_APPLICATION_MODE.get());
                 */
            });
            [self finishCurrentRoute];
            // targets.clearPointToNavigate(false);
            return true;
        }
        
    }
    
    // 4. update angle point
    if (_route.routeVisibleAngle > 0)
    {
        // proceed to the next point with min acceptable bearing
        double ANGLE_TO_DECLINE = _route.routeVisibleAngle;
        int nextPoint = _route.currentRoute;
        for (; nextPoint < (NSInteger) routeNodes.count - 1; nextPoint++)
        {
            float bearingTo = [currentLocation bearingTo:routeNodes[nextPoint]];
            float bearingTo2 = [routeNodes[nextPoint] bearingTo:routeNodes[nextPoint + 1]];
            if (abs(OsmAnd::Utilities::degreesDiff(bearingTo2, bearingTo)) <= ANGLE_TO_DECLINE)
                break;
        }

        if(nextPoint > 0)
        {
            CLLocation *next = routeNodes[nextPoint];
            CLLocation *prev = routeNodes[nextPoint - 1];
            float bearing = [prev bearingTo:next];
            double bearingTo = abs(OsmAnd::Utilities::degreesDiff(bearing, [currentLocation bearingTo:next]));
            double bearingPrev = abs(OsmAnd::Utilities::degreesDiff(bearing, [currentLocation bearingTo:prev]));
            while (YES) {
                CLLocation *mp = [OAMapUtils calculateMidPoint:prev s2:next];
                if([mp distanceFromLocation:next] <= 100) {
                    break;
                }
                double bearingMid = abs(OsmAnd::Utilities::degreesDiff(bearing, [currentLocation bearingTo:mp]));
                if (bearingPrev < ANGLE_TO_DECLINE)
                {
                    next = mp;
                    bearingTo = bearingMid;
                }
                else if(bearingTo < ANGLE_TO_DECLINE)
                {
                    prev = mp;
                    bearingPrev = bearingMid;
                }
                else
                {
                    break;
                }
            }
            [_route updateNextVisiblePoint:nextPoint location:next];
        }

    }
    return false;
}

- (BOOL)isLocationJumping:(CLLocation *)currentLocation targetPointsChanged:(BOOL)targetPointsChanged {
    if ([_route hasMissingMaps] && _lastGoodRouteLocation != nil && !targetPointsChanged) {
        NSTimeInterval time = [currentLocation.timestamp timeIntervalSinceDate:_lastGoodRouteLocation.timestamp];
        CLLocationDistance dist = [currentLocation distanceFromLocation:_lastGoodRouteLocation];
        if (time > 0) {
            double speed = dist / (time / 1000.0);
            return speed > MAX_POSSIBLE_SPEED;
        }
    }
    return NO;
}

- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation previousRoute:(OARouteCalculationResult *)previousRoute targetPointsChanged:(BOOL)targetPointsChanged
{
    CLLocation *locationProjection = currentLocation;
    if (self.isPublicTransportMode && currentLocation != nil && _finalLocation != nil &&
        (targetPointsChanged || _transportRoutingHelper.startLocation == nil))
    {
        _lastFixedLocation = currentLocation;
        _lastProjection = locationProjection;
        _transportRoutingHelper.applicationMode = _mode;
        [_transportRoutingHelper setFinalAndCurrentLocation:_finalLocation currentLocation:[[CLLocation alloc] initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude]];
    }
    if (_finalLocation == nil || currentLocation == nil || self.isPublicTransportMode)
    {
        _isDeviatedFromRoute = false;
        return locationProjection;
    }
    double posTolerance = [self.class getPosTolerance:currentLocation.horizontalAccuracy];
    BOOL calculateRoute = false;
    @synchronized (self)
    {
        _isDeviatedFromRoute = false;
        double distOrth = 0;
        
        // 0. Route empty or needs to be extended? Then re-calculate route.
        if ([_route isEmpty])
        {
            calculateRoute = ![_route hasMissingMaps] || [self isLocationJumping:currentLocation targetPointsChanged:targetPointsChanged];
        }
        else
        {
            // 1. Update current route position status according to latest received location
            BOOL finished = [self updateCurrentRouteStatus:currentLocation posTolerance:posTolerance];
            if (finished)
                return nil;
            
            NSArray<CLLocation *> *routeNodes = [_route getImmutableAllLocations];
            int currentRoute = _route.currentRoute;
            
            double allowableDeviation = _route.routeRecalcDistance;
            if (allowableDeviation <= 0)
                allowableDeviation = [self.class getDefaultAllowedDeviation:_route.appMode posTolerance:posTolerance];
            
            // 2. Analyze if we need to recalculate route
            // >100m off current route (sideways) or parameter (for Straight line)
            if (allowableDeviation > 0)
            {
                if (currentRoute == 0) {
                    distOrth = [currentLocation distanceFromLocation:routeNodes[currentRoute]]; // deviation at the start
                } else {
                    distOrth = [OAMapUtils getOrthogonalDistance:currentLocation fromLocation:routeNodes[currentRoute - 1] toLocation:routeNodes[currentRoute]];
                }
                if (distOrth > allowableDeviation)
                {
                    NSLog(@"Recalculate route, because correlation  : %f", distOrth);
                    _isDeviatedFromRoute = true;
                    calculateRoute = ![_settings.disableOffrouteRecalc get];
                }
            }
            // 3. Identify wrong movement direction
            CLLocation *next = [_route getNextRouteLocation];
            CLLocation *prev = [_route getRouteLocationByDistance:-15];
            BOOL isStraight = _route.routeProvider == DIRECT_TO || _route.routeProvider == STRAIGHT;
            BOOL wrongMovementDirection = [OARoutingHelperUtils checkWrongMovementDirection:currentLocation prevRouteLocation:prev nextRouteLocation:next];
            if (allowableDeviation > 0 && wrongMovementDirection && !isStraight
                && ([currentLocation distanceFromLocation:routeNodes[currentRoute]] > allowableDeviation) && ![_settings.disableWrongDirectionRecalc get])
            {
                NSLog(@"Recalculate route, because wrong movement direction: %f", [currentLocation distanceFromLocation:routeNodes[currentRoute]]);
                _isDeviatedFromRoute = true;
                calculateRoute = true;
            }
            // 4. Identify if UTurn is needed
            if ([self identifyUTurnIsNeeded:currentLocation posTolerance:posTolerance])
                _isDeviatedFromRoute = true;
            // 4.5. Disable recalculation in tunnels (tunnel locations are simulated)
            if ([self isTunnelLocationSimulated:currentLocation])
            {
                _isDeviatedFromRoute = false;
                calculateRoute = false;
            }
            // 5. Update Voice router
            // Do not update in route planning mode
            BOOL inRecalc = calculateRoute || [self isRouteBeingCalculated];
            if (_isFollowingMode)
            {
                if (!inRecalc && !wrongMovementDirection)
                {
                    [_voiceRouter updateStatus:currentLocation repeat:false];
                    _voiceRouterStopped = false;
                }
                else if (_isDeviatedFromRoute && !_voiceRouterStopped)
                {
                    [_voiceRouter interruptRouteCommands];
                    _voiceRouterStopped = true; // Prevents excessive execution of stop() code
                }
                [_voiceRouter announceOffRoute:distOrth];
            }
            // calculate projection of current location
            if (currentRoute > 0 && !inRecalc)
            {
                CLLocation *previousRouteLocation = routeNodes[currentRoute - 1];
                CLLocation *currentRouteLocation = routeNodes[currentRoute];
                locationProjection = [OAMapUtils getProjection:currentLocation fromLocation:previousRouteLocation toLocation:currentRouteLocation];
                
                if ([_settings.snapToRoad get] && currentRoute + 1 < routeNodes.count)
                {
                    CLLocation *nextRouteLocation = routeNodes[currentRoute + 1];
                    BOOL previewNextTurn = _settings.previewNextTurn.get;
                    locationProjection = [OARoutingHelperUtils approximateBearingIfNeeded:self projection:locationProjection location:currentLocation previousRouteLocation:previousRouteLocation currentRouteLocation:currentRouteLocation nextRouteLocation:nextRouteLocation previewNextTurn:previewNextTurn];
                }
                else if ([_settings.snapToRoad get])
                {
                    // for snapping to road on start track
                    CLLocation *nextLocation = routeNodes[currentRoute];
                    float bearingTo = [locationProjection bearingTo:nextLocation];
                    locationProjection = [[CLLocation alloc] initWithCoordinate:locationProjection.coordinate altitude:currentLocation.altitude horizontalAccuracy:currentLocation.horizontalAccuracy verticalAccuracy:currentLocation.verticalAccuracy course:bearingTo speed:currentLocation.speed timestamp:currentLocation.timestamp];
                }
            }
        }
        _lastFixedLocation = currentLocation;
        _lastProjection = locationProjection;
        if (![_route isEmpty]) {
            _lastGoodRouteLocation = currentLocation;
        }
    }
    
    if (calculateRoute)
    {
        [_recalcHelper recalculateRouteInBackground:currentLocation end:_finalLocation intermediates:_intermediatePoints gpxRoute:_currentGPXRoute previousRoute:[previousRoute isCalculated] ? previousRoute : nil paramsChanged:false onlyStartPointChanged:!targetPointsChanged];
    }
    else
    {
        [_recalcHelper stopCalculationIfParamsNotChanged];
    }

    double projectDist = _mode.hasFastSpeed ? posTolerance : posTolerance / 2;
    if (returnUpdatedLocation && locationProjection && [currentLocation distanceFromLocation:locationProjection] < projectDist)
        return locationProjection;
    else
        return currentLocation;

    return nil;
}

- (void)updateLocation:(CLLocation *)currentLocation
{
    if (!_app.data.pointToStart && !_app.data.myLocationToStart && currentLocation != nil)
        [[OATargetPointsHelper sharedInstance] setMyLocationPoint:currentLocation updateRoute:NO name:nil];
}

- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation
{
    return [self setCurrentLocation:currentLocation returnUpdatedLocation:returnUpdatedLocation previousRoute:_route targetPointsChanged:false];
}

- (OACurrentStreetName *) getCurrentName:(OANextDirectionInfo *)next
{
    @synchronized (self) {
        return [[OACurrentStreetName alloc] initWithStreetName:self info:next];
    }
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getUpcomingTunnel:(float)distToStart
{
    return [_route getUpcomingTunnel:distToStart];
}

- (NSArray<CLLocation *> *) getCurrentCalculatedRoute
{
    return [_route getImmutableAllLocations];
}

- (OARouteCalculationResult *) getRoute
{
    return _route;
}

- (void) setRoute:(OARouteCalculationResult *)route;
{
    _route = route;
}

- (OASGpxTrackAnalysis *) getTrackAnalysis
{
    OASGpxFile *gpx = [OAGPXUIHelper makeGpxFromRoute:_route];
    return [gpx getAnalysisFileTimestamp:0];
}

- (int) getLeftDistance
{
    return [_route getDistanceToFinish:_lastFixedLocation];
}

- (int) getLeftDistanceNextIntermediate
{
    return [_route getDistanceToNextIntermediate:_lastFixedLocation];
}

- (int) getLeftDistanceNextIntermediateWith:(int)intermediateIndexOffset
{
    return [_route getDistanceToNextIntermediate:_lastFixedLocation intermediateIndexOffset:intermediateIndexOffset];
}

- (long) getLeftTime
{
    return [_route getLeftTime:_lastFixedLocation];
}

- (long) getLeftTimeNextTurn
{
    return [_route getLeftTimeToNextTurn:_lastFixedLocation];
}

- (long) getLeftTimeNextIntermediate
{
    return [self getLeftTimeNextIntermediateWith:0];
}

- (long) getLeftTimeNextIntermediateWith:(int)intermediateIndexOffset
{
    return [_route getLeftTimeToNextIntermediate:_lastFixedLocation intermediateIndexOffset:intermediateIndexOffset];
}

- (NSArray<OARouteDirectionInfo *> *) getRouteDirections
{
    return [_route getRouteDirections];
}

- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i
{
    return [_route getLocationFromRouteDirection:i];
}

+ (BOOL) isDeviatedFromRoute
{
    return _isDeviatedFromRoute;
}

- (void) clearCurrentRoute:(CLLocation *)newFinalLocation newIntermediatePoints:(NSArray<CLLocation *> *)newIntermediatePoints
{
    @synchronized (self)
    {
        _route = [[OARouteCalculationResult alloc] initWithErrorMessage:@""];
        _isDeviatedFromRoute = false;
        [_recalcHelper resetEvalWaitInterval];

        [[OAWaypointHelper sharedInstance] setNewRoute:_route];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized (_listeners)
            {
                NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
                for (id<OARouteInformationListener> l in _listeners)
                {
                    if (l)
                        [l routeWasCancelled];
                    else
                        [inactiveListeners addObject:l];
                }
                [_listeners removeObjectsInArray:inactiveListeners];
            }
        });
        _finalLocation = newFinalLocation;
        _lastGoodRouteLocation = nil;
        _intermediatePoints = newIntermediatePoints ? [NSMutableArray arrayWithArray:newIntermediatePoints] : nil;

        [_recalcHelper stopCalculation];

        if (!newFinalLocation)
        {
            [_settings.followTheRoute set:NO];
            [[[OsmAndApp instance] followTheRouteObservable] notifyEvent];
            [_settings.followTheGpxRoute set:nil];
            // clear last fixed location
            _lastProjection = nil;
            [self setFollowingMode:NO];
        }
        [_transportRoutingHelper clearCurrentRoute:newFinalLocation];
    }
}

- (void) finishCurrentRoute
{
    @synchronized (self)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized (_listeners)
            {
                NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
                for (id<OARouteInformationListener> l in _listeners)
                {
                    if (l)
                        [l routeWasFinished];
                    else
                        [inactiveListeners addObject:l];
                }
                [_listeners removeObjectsInArray:inactiveListeners];
            }
        });
    }
}

- (float) getCurrentMaxSpeed
{
    return [_route getCurrentMaxSpeed:[[self getAppMode] getRouteTypeProfile]];
}

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end
{
	return [_provider getRoutingEnvironment:mode start:start end:end];
}

- (std::vector<SHARED_PTR<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(std::shared_ptr<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder
{
	return [_provider generateGpxPoints:env gctx:gctx locationsHolder:locationsHolder];
}

- (SHARED_PTR<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
														   gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
														 points:(std::vector<SHARED_PTR<GpxPoint>> &)points
												  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
	return [_provider calculateGpxApproximation:env gctx:gctx points:points resultMatcher:resultMatcher];
}

- (CLLocation *) getLastProjection
{
    return _lastProjection;
}

- (CLLocation *) getLastFixedLocation
{
    return _lastFixedLocation;
}

- (OAGPXRouteParamsBuilder *) getCurrentGPXRoute
{
    return _currentGPXRoute;
}

- (void) setGpxParams:(OAGPXRouteParamsBuilder *)params
{
    _currentGPXRoute = params;
}

- (CLLocation *) getFinalLocation
{
    return _finalLocation;
}

- (void) recalculateRouteDueToSettingsChange
{
    [self clearCurrentRoute:_finalLocation newIntermediatePoints:_intermediatePoints];
    if (self.isPublicTransportMode)
    {
        CLLocation *start = _lastFixedLocation;
        CLLocation *finish = _finalLocation;
        _transportRoutingHelper.applicationMode = _mode;
        if (start != nil && finish != nil)
        {
            [_transportRoutingHelper setFinalAndCurrentLocation:finish currentLocation:[[CLLocation alloc] initWithLatitude:start.coordinate.latitude longitude:start.coordinate.longitude]];
        }
        else
        {
            [_transportRoutingHelper recalculateRouteDueToSettingsChange];
        }
    }
    else
    {
        [_recalcHelper recalculateRouteInBackground:_lastFixedLocation end:_finalLocation intermediates:_intermediatePoints gpxRoute:_currentGPXRoute previousRoute:_route paramsChanged:YES onlyStartPointChanged:NO];
    }
}

- (void) notifyIfRouteIsCalculated
{
    if ([_route isCalculated])
        [_voiceRouter newRouteIsCalculated:true];
}

- (BOOL) isPublicTransportMode
{
    return [_mode isDerivedRoutingFrom:OAApplicationMode.PUBLIC_TRANSPORT];
}

- (void) startRouteCalculationThread:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged updateProgress:(BOOL)updateProgress
{
    [_recalcHelper startRouteCalculationThread:params paramsChanged:paramsChanged updateProgress:updateProgress];
}

- (OASGpxFile *) generateGPXFileWithRoute:(NSString *)name
{
    return [self generateGPXFileWithRoute:_route name:name];
}

- (OASGpxFile *) generateGPXFileWithRoute:(OARouteCalculationResult *)route name:(NSString *)name
{
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
    NSArray<OARTargetPoint *> *ps = targets.getIntermediatePointsWithTarget;
    for (NSInteger k = 0; k < ps.count; k++)
    {
        OASWptPt *pt = [[OASWptPt alloc] init];
        pt.position = CLLocationCoordinate2DMake(ps[k].getLatitude, ps[k].getLongitude);
        if (k < ps.count)
        {
            pt.name = ps[k].getOnlyName;
            if (k == ps.count - 1)
            {
                NSString *target = [NSString stringWithFormat:OALocalizedString(@"destination_point"), @""];
                if ([pt.name hasPrefix:target])
                    pt.name = [NSString stringWithFormat:OALocalizedString(@"destination_point"), pt.name];
            }
            else
            {
                NSString *prefix = [NSString stringWithFormat:@"%ld. ", (k+1)];
                if(pt.name.length == 0)
                    pt.name = [NSString stringWithFormat:OALocalizedString(@"destination_point"), pt.name];
                if ([pt.name hasPrefix:prefix])
                    pt.name = [prefix stringByAppendingString:pt.name];
            }
            pt.desc = pt.name;
        }
        [points addObject:pt];
    }
    
    NSArray<CLLocation *> *locations = route.getImmutableAllLocations;
    auto originalRoute = route.getOriginalRoute;
    OARouteExporter *exporter = [[OARouteExporter alloc] initWithName:name route:originalRoute locations:locations routePointIndexes:{} points:points];
    return [exporter exportRoute];
}

+ (void) applyApplicationSettings:(OARouteCalculationParams *) params  appMode:(OAApplicationMode *) mode
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    params.leftSide = [OADrivingRegion isLeftHandDriving:[settings.drivingRegion get:mode]];
    params.fast = [settings.fastRouteMode get:mode];
}

+ (NSInteger) getGpsTolerance
{
    return GPS_TOLERANCE;
}

+ (double) getArrivalDistanceFactor
{
    return ARRIVAL_DISTANCE_FACTOR;
}

+ (double) getDefaultAllowedDeviation:(OAApplicationMode *)mode posTolerance:(double)posTolerance
{
    if ([mode getRouterService] == DIRECT_TO)
    {
        return -1.0f;
    }
    else if ([mode getRouterService] == STRAIGHT)
    {
        EOAMetricsConstant mc = [[OAAppSettings sharedManager].metricSystem get:mode];
        if (mc == KILOMETERS_AND_METERS || mc == MILES_AND_METERS)
        {
            return 500.;
        }
        else
        {
            // 1/4 mile
            return 482.;
        }
    }
    return posTolerance * POS_TOLERANCE_DEVIATION_MULTIPLIER;
}

+ (double) getPosTolerance:(double)accuracy
{
    if (accuracy > 0)
    {
        return POSITION_TOLERANCE / 2 + accuracy;
    }
    return POSITION_TOLERANCE;
}

- (double) getMaxAllowedProjectDist:(CLLocation *)location
{
    double posTolerance = [self.class getPosTolerance:location.horizontalAccuracy];
    return _mode && _mode.hasFastSpeed ? posTolerance : posTolerance / 2;
}

- (BOOL) isTunnelLocationSimulated:(CLLocation *)location
{
    if ([location isKindOfClass:OALocation.class])
    {
        OALocation *loc = (OALocation *) location;
        return [loc.provider isEqualToString:@"TUNNEL"];
    }
    return false;
}

@end
