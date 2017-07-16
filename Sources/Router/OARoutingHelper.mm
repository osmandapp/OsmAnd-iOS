//
//  OARoutingHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingHelper.h"
#import "OsmAndApp.h"
#import "OARouteProvider.h"
#import "OARouteCalculationResult.h"
#import "OAAppSettings.h"
#import "OAVoiceRouter.h"
#import "OAMapUtils.h"
#import "Localization.h"
#import "OATargetPointsHelper.h"

#define POSITION_TOLERANCE 60
#define RECALCULATE_THRESHOLD_COUNT_CAUSING_FULL_RECALCULATE 3
#define RECALCULATE_THRESHOLD_CAUSING_FULL_RECALCULATE_INTERVAL 2 * 60 * 1000

@interface OARouteRecalculationThread : NSObject

- (void) stopCalculation;

@end

@implementation OARouteRecalculationThread

- (void) stopCalculation
{
    // TODO
}

@end

@implementation OARoutingHelper
{
    NSMutableArray<id<OARouteInformationListener>> *_listeners;

    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    BOOL _isFollowingMode;
    BOOL _isRoutePlanningMode;
    BOOL _isPauseNavigation;
    
    OAGPXRouteParamsBuilder *_currentGPXRoute;
    
    OARouteCalculationResult *_route;
    
    CLLocation *_finalLocation;
    NSArray<CLLocation *> *_intermediatePoints;
    CLLocation *_lastProjection;
    CLLocation *_lastFixedLocation;
    
    NSThread *_currentRunningJob;
    long _lastTimeEvaluatedRoute;
    NSString *_lastRouteCalcError;
    NSString *_lastRouteCalcErrorShort;
    long _recalculateCountInInterval;
    int _evalWaitInterval;
    
    OAMapVariantType _mode;
    
    OARouteProvider *_provider;
    OAVoiceRouter *_voiceRouter;
    
    long _deviateFromRouteDetected;
    //long _wrongMovementDetected;
    BOOL _voiceRouterStopped;
    
    id<OARouteCalculationProgressCallback> _progressRoute;
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
        _provider = [[OARouteProvider alloc] init];
        [self setAppMode:[OAApplicationMode getVariantType:_app.data.lastMapSource.variant]];
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

- (void) setAppMode:(OAMapVariantType)mode
{
    _mode = mode;
    [_voiceRouter updateAppMode];
}

- (OAMapVariantType) getAppMode
{
    return _mode;
}

- (BOOL) isFollowingMode
{
    return _isFollowingMode;
}

- (NSString *) getLastRouteCalcError
{
    return _lastRouteCalcError;
}

- (NSString *) getLastRouteCalcErrorShort
{
    return _lastRouteCalcErrorShort;
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
    return [_route isCalculated];
}

- (BOOL) isRouteBeingCalculated
{
    return [_currentRunningJob isKindOfClass:[OARouteRecalculationThread class]];
}

- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation
{
    @synchronized (self)
    {
        OARouteCalculationResult *previousRoute = _route;
        [self clearCurrentRoute:finalLocation newIntermediatePoints:intermediatePoints];
        // to update route
        [self setCurrentLocation:currentLocation returnUpdatedLocation:NO previousRoute:previousRoute targetPointsChanged:YES];
    }
}

+ (int) lookAheadFindMinOrthogonalDistance:(CLLocation *)currentLocation routeNodes:(NSArray<CLLocation *> *)routeNodes currentRoute:(int)currentRoute iterations:(int)iterations
{
    double newDist;
    double dist = DBL_MAX;
    int index = currentRoute;
    while (iterations > 0 && currentRoute + 1 < routeNodes.count)
    {
        newDist = [OAMapUtils getOrthogonalDistance:currentLocation fromLocation:routeNodes[currentRoute] toLocation:routeNodes[currentRoute + 1]];
        if (newDist < dist)
        {
            index = currentRoute;
            dist = newDist;
        }
        currentRoute++;
        iterations--;
    }
    return index;
}

- (float) getArrivalDistance
{
    return [OAApplicationMode getArrivalDistanceByVariantType:[OAApplicationMode getVariantType:_app.data.lastMapSource.variant]] * [_settings.arrivalDistanceFactor get:[OAApplicationMode getVariantType:_app.data.lastMapSource.variant]];
}

- (void) showMessage:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO toast
        // show message
    });
}

- (BOOL) updateCurrentRouteStatus:(CLLocation *)currentLocation posTolerance:(float)posTolerance
{
    NSArray<CLLocation *> *routeNodes = [_route getImmutableAllLocations];
    int currentRoute = _route.currentRoute;
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
        int newCurrentRoute = [self.class lookAheadFindMinOrthogonalDistance:currentLocation routeNodes:routeNodes currentRoute:currentRoute iterations:longDistance ? 15 : 8];
        double newDist = [OAMapUtils getOrthogonalDistance:currentLocation fromLocation:routeNodes[newCurrentRoute] toLocation:routeNodes[newCurrentRoute + 1]];
        if (longDistance)
        {
            if (newDist < dist)
            {
                NSLog(@"Processed by distance : (new) %f (old) %f", newDist, dist);
                processed = true;
            }
        }
        else if (newDist < dist || newDist < 10)
        {
            // newDist < 10 (avoid distance 0 till next turn)
            if (dist > posTolerance)
            {
                processed = true;
                NSLog(@"Processed by distance : %f %f", newDist, dist);
            }
            else
            {
                // case if you are getting close to the next point after turn
                // but you have not yet turned (could be checked bearing)
                if (currentLocation.course >= 0 || _lastFixedLocation)
                {
                    float bearingToRoute = [currentLocation bearingTo:routeNodes[currentRoute]];
                    float bearingRouteNext = [routeNodes[newCurrentRoute] bearingTo:routeNodes[newCurrentRoute + 1]];
                    float bearingMotion = currentLocation.course >= 0 ? currentLocation.course : [_lastFixedLocation bearingTo:currentLocation];
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
            [_route updateCurrentRoute:newCurrentRoute + 1];
            currentRoute = newCurrentRoute + 1;
            // TODO notifications
            //app.getNotificationHelper().refreshNotification(NotificationType.NAVIGATION);
        }
        else
        {
            break;
        }
    }
    
    /* TODO
    // 2. check if intermediate found
    if ([_route getIntermediatePointsToPass]  > 0
        && [_route getDistanceToNextIntermediate:_lastFixedLocation] < [self getArrivalDistance] * 2.0 && !_isRoutePlanningMode)
    {
        [self showMessage:OALocalizedString(@"arrived_at_intermediate_point")];
        [_route passIntermediatePoint];
        TargetPointsHelper targets = app.getTargetPointsHelper();
        String name = "";
        if(intermediatePoints != null && !intermediatePoints.isEmpty()) {
            LatLon rm = intermediatePoints.remove(0);
            List<TargetPoint> ll = targets.getIntermediatePointsNavigation();
            int ind = -1;
            for(int i = 0; i < ll.size(); i++) {
                if(ll.get(i).point != null && MapUtils.getDistance(ll.get(i).point, rm) < 5) {
                    name = ll.get(i).getOnlyName();
                    ind = i;
                    break;
                }
            }
            if(ind >= 0) {
                targets.removeWayPoint(false, ind);
            }
        }
        if(isFollowingMode) {
            voiceRouter.arrivedIntermediatePoint(name);
        }
        // double check
        while(intermediatePoints != null  && route.getIntermediatePointsToPass() < intermediatePoints.size()) {
            intermediatePoints.remove(0);
        }
    }
    
    // 3. check if destination found
    Location lastPoint = routeNodes.get(routeNodes.size() - 1);
    if (currentRoute > routeNodes.size() - 3
        && currentLocation.distanceTo(lastPoint) < getArrivalDistance()
        && !isRoutePlanningMode) {
        //showMessage(app.getString(R.string.arrived_at_destination));
        TargetPointsHelper targets = app.getTargetPointsHelper();
        TargetPoint tp = targets.getPointToNavigate();
        String description = tp == null ? "" : tp.getOnlyName(); 
        if(isFollowingMode) {
            voiceRouter.arrivedDestinationPoint(description);
        }
        BOOL onDestinationReached = OsmandPlugin.onDestinationReached();
        onDestinationReached &= app.getAppCustomization().onDestinationReached();
        if (onDestinationReached) {
            clearCurrentRoute(null, null);
            setRoutePlanningMode(false);
            app.runInUIThread(new Runnable() {
                @Override
                public void run() {
                    settings.LAST_ROUTING_APPLICATION_MODE = settings.APPLICATION_MODE.get();
                    settings.APPLICATION_MODE.set(settings.DEFAULT_APPLICATION_MODE.get());
                }
            });
            finishCurrentRoute();
            // targets.clearPointToNavigate(false);
            return true;
        }
        
    }
     */
    return false;
}

- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation previousRoute:(OARouteCalculationResult *)previousRoute targetPointsChanged:(BOOL)targetPointsChanged
{
    /* TODO
    CLLocation *locationProjection = currentLocation;
    if (!_finalLocation || !currentLocation)
    {
        _isDeviatedFromRoute = false;
        return locationProjection;
    }
    float posTolerance = POSITION_TOLERANCE;
    if (currentLocation.horizontalAccuracy >= 0)
        posTolerance = POSITION_TOLERANCE / 2 + currentLocation.horizontalAccuracy;
    
    BOOL calculateRoute = false;
    @synchronized (self)
    {
        _isDeviatedFromRoute = false;
        double distOrth = 0;
        
        // 0. Route empty or needs to be extended? Then re-calculate route.
        if ([_route isEmpty])
        {
            calculateRoute = true;
        }
        else
        {
            // 1. Update current route position status according to latest received location
            BOOL finished = [self updateCurrentRouteStatus:currentLocation, posTolerance];
            if (finished)
                return nil;
            
            NSArray<CLLocation *> *routeNodes = [_route getImmutableAllLocations];
            int currentRoute = _route.currentRoute;
            
            // 2. Analyze if we need to recalculate route
            // >100m off current route (sideways)
            if (currentRoute > 0)
            {
                distOrth = getOrthogonalDistance(currentLocation, routeNodes.get(currentRoute - 1), routeNodes.get(currentRoute));
                if ((!settings.DISABLE_OFFROUTE_RECALC.get()) && (distOrth > (1.7 * posTolerance))) {
                    log.info("Recalculate route, because correlation  : " + distOrth); //$NON-NLS-1$
                    isDeviatedFromRoute = true;
                    calculateRoute = true;
                }
            }
            // 3. Identify wrong movement direction
            Location next = route.getNextRouteLocation();
            BOOL wrongMovementDirection = checkWrongMovementDirection(currentLocation, next);
            if ((!settings.DISABLE_WRONG_DIRECTION_RECALC.get()) && wrongMovementDirection && (currentLocation.distanceTo(routeNodes.get(currentRoute)) > (2 * posTolerance))) {
                log.info("Recalculate route, because wrong movement direction: " + currentLocation.distanceTo(routeNodes.get(currentRoute))); //$NON-NLS-1$
                isDeviatedFromRoute = true;
                calculateRoute = true;
            }
            // 4. Identify if UTurn is needed
            if (identifyUTurnIsNeeded(currentLocation, posTolerance)) {
                isDeviatedFromRoute = true;
            }
            // 5. Update Voice router
            // Do not update in route planning mode
            if (isFollowingMode) {
                BOOL inRecalc = calculateRoute || isRouteBeingCalculated();
                if (!inRecalc && !wrongMovementDirection) {
                    voiceRouter.updateStatus(currentLocation, false);
                    voiceRouterStopped = false;
                } else if (isDeviatedFromRoute && !voiceRouterStopped) {
                    voiceRouter.interruptRouteCommands();
                    voiceRouterStopped = true; // Prevents excessive execution of stop() code
                }
                if (distOrth > 350) {
                    voiceRouter.announceOffRoute(distOrth);
                }
            }
            
            // calculate projection of current location
            if (currentRoute > 0) {
                locationProjection = new Location(currentLocation);
                Location nextLocation = routeNodes.get(currentRoute);
                LatLon project = getProject(currentLocation, routeNodes.get(currentRoute - 1), routeNodes.get(currentRoute));
                
                locationProjection.setLatitude(project.getLatitude());
                locationProjection.setLongitude(project.getLongitude());
                // we need to update bearing too
                float bearingTo = locationProjection.bearingTo(nextLocation);
                locationProjection.setBearing(bearingTo);
            }
        }
        lastFixedLocation = currentLocation;
        lastProjection = locationProjection;
    }
    
    if (calculateRoute) {
        recalculateRouteInBackground(currentLocation, finalLocation, intermediatePoints, currentGPXRoute,
                                     previousRoute.isCalculated() ? previousRoute : null, false, !targetPointsChanged);
    } else {
        Thread job = currentRunningJob;
        if(job instanceof RouteRecalculationThread) {
            RouteRecalculationThread thread = (RouteRecalculationThread) job;
            if(!thread.isParamsChanged()) {
                thread.stopCalculation();
            }
            if (isFollowingMode){
                voiceRouter.announceBackOnRoute();
            }
        }
    }
    
    double projectDist = mode != null && mode.hasFastSpeed() ? posTolerance : posTolerance / 2;
    if(returnUpdatedLocation && locationProjection != null && currentLocation.distanceTo(locationProjection) < projectDist) {
        return locationProjection;
    } else {
        return currentLocation;
    }
     */
    return nil;
}

- (void) clearCurrentRoute:(CLLocation *)newFinalLocation newIntermediatePoints:(NSArray<CLLocation *> *)newIntermediatePoints
{
    @synchronized (self)
    {
        _route = [[OARouteCalculationResult alloc] initWithErrorMessage:@""];
        _isDeviatedFromRoute = false;
        _evalWaitInterval = 0;
        //_app.getWaypointHelper().setNewRoute(_route); TODO
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray<id<OARouteInformationListener>> *inactiveListeners = [NSMutableArray array];
            for (id<OARouteInformationListener> l in _listeners)
            {
                if (l)
                    [l routeWasCancelled];
                else
                    [inactiveListeners addObject:l];
            }
            [_listeners removeObjectsInArray:inactiveListeners];
        });
        _finalLocation = newFinalLocation;
        _intermediatePoints = newIntermediatePoints;
        if ([_currentRunningJob isKindOfClass:[OARouteRecalculationThread class]])
            [((OARouteRecalculationThread *) _currentRunningJob) stopCalculation];
        
        if (!newFinalLocation)
        {
            _settings.followTheRoute = false;
            _settings.followTheGpxRoute = nil;
            // clear last fixed location
            _lastProjection = nil;
            [self setFollowingMode:NO];
        }
    }
}

+ (NSString *) formatStreetName:(NSString *)name ref:(NSString *)ref destination:(NSString *)destination towards:(NSString *)towards
{
    //Hardy, 2016-08-05:
    //Now returns: (ref) + ((" ")+name) + ((" ")+"toward "+dest) or ""
    
    NSString *formattedStreetName = @"";
    if (ref && ref.length > 0)
        formattedStreetName = ref;
    
    if (name && name.length > 0)
    {
        if (formattedStreetName.length > 0)
            formattedStreetName = [formattedStreetName stringByAppendingString:@" "];
        
        formattedStreetName = [formattedStreetName stringByAppendingString:name];
    }
    if (destination && destination.length > 0)
    {
        if (formattedStreetName.length > 0)
            formattedStreetName = [formattedStreetName stringByAppendingString:@" "];
        
        formattedStreetName = [formattedStreetName stringByAppendingString:[NSString stringWithFormat:@"%@ %@",towards, destination]];
    }
    return [formattedStreetName stringByReplacingOccurrencesOfString:@";" withString:@", "];
}

@end
