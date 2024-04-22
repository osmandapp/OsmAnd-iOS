//
//  OALocationServices.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocationServices.h"

#import <UIKit/UIKit.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAUtilities.h"
#import "OALog.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OASimulationProvider.h"
#import "OARoutingHelper.h"
#import "OARoutingHelper+cpp.h"
#import "OAVoiceRouter.h"
#import "OALocationSimulation.h"
#import "OAWaypointHelper.h"
#import "OASavingTrackHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAverageSpeedComputer.h"

#import <FormatterKit/TTTLocationFormatter.h>

#define _(name) OALocationServices__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define LOST_LOCATION_CHECK_DELAY 18.0
#define START_LOCATION_SIMULATION_DELAY 2.0
#define ACCURACY_FOR_GPX_AND_ROUTING 50.0

@interface OALocationServices () <CLLocationManagerDelegate>
@end

@implementation OALocationServices
{
    OsmAndAppInstance _app;
    OARoutingHelper *_routingHelper;
    OAAppSettings *_settings;

    NSObject* _lock;

    CLLocationManager* _manager;
    BOOL _locationActive;
    BOOL _compassActive;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _followTheRouteObserver;
    OAAutoObserverProxy* _simulateRoutingObserver;

    BOOL _waitingForAuthorization;

    CLLocation* _lastLocation;
    CLLocationDirection _lastHeading;
    CLLocationDirection _lastMagneticHeading;
    
    BOOL _gpsSignalLost;
    OASimulationProvider *_simulatePosition;
    CLLocation *_locationStartSim;

    BOOL _isSuspended;
    
    NSDate *_locationLostTime;
}

- (instancetype) initWith:(OsmAndAppInstance)app
{
    self = [super init];
    if (self) {
        [self commonInit:app];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void) commonInit:(OsmAndAppInstance)app
{
    _app = app;
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];

    _lock = [[NSObject alloc] init];

    _locationActive = NO;
    _compassActive = NO;
    _statusObservable = [[OAObservable alloc] init];

    _stateObservable = [[OAObservable alloc] init];

    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];

    _followTheRouteObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onFollowTheRouteChanged)
                                                          andObserve:_app.followTheRouteObservable];

    _simulateRoutingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onSimulateRoutingChanged)
                                                          andObserve:_app.simulateRoutingObservable];

    _waitingForAuthorization = NO;

    _lastLocation = nil;
    _lastHeading = NAN;
    _lastMagneticHeading = NAN;
    _updateLocationObserver = [[OAObservable alloc] init];
    _updateHeadingObserver = [[OAObservable alloc] init];
    _updateFirstTimeObserver = [[OAObservable alloc] init];

    _locationSimulation = [[OALocationSimulation alloc] init];
    
    _isSuspended = NO;

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(onDeviceOrientationDidChange)
                               name:OAScreenOrientationHelper.screenOrientationChangedKey
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onDeviceBatteryStateDidChange)
                               name:UIDeviceBatteryLevelDidChangeNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onApplicationWillEnterForeground)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onApplicationDidEnterBackground)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
}

- (void) deinit
{
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:OAScreenOrientationHelper.screenOrientationChangedKey
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:UIDeviceBatteryLevelDidChangeNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:UIApplicationWillEnterForegroundNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:UIApplicationDidEnterBackgroundNotification
                                object:nil];
}

- (CLLocationManager*) getLocationManager
{
    if (_manager)
        return _manager;

    if ([NSThread isMainThread])
    {
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.distanceFilter = kCLDistanceFilterNone;
        _manager.pausesLocationUpdatesAutomatically = NO;
        if ([_manager respondsToSelector:@selector(allowsBackgroundLocationUpdates)])
            _manager.allowsBackgroundLocationUpdates = YES;

        return _manager;
    }
    return nil;
}

- (BOOL) available
{
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL) compassPresent
{
    return [CLLocationManager headingAvailable];
}

- (BOOL) allowed
{
    CLLocationManager *manager = self.getLocationManager;
    CLAuthorizationStatus authorizationStatus = manager ? manager.authorizationStatus : kCLAuthorizationStatusNotDetermined;
    return authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (BOOL) denied
{
    CLLocationManager *manager = self.getLocationManager;
    return manager ? manager.authorizationStatus == kCLAuthorizationStatusDenied : YES;
}

@synthesize stateObservable = _stateObservable;

- (OALocationServicesStatus)status
{
    @synchronized(_lock)
    {
        if (_waitingForAuthorization)
            return OALocationServicesStatusAuthorizing;
        if (_isSuspended)
            return OALocationServicesStatusSuspended;
        return (_locationActive || _compassActive) ? OALocationServicesStatusActive : OALocationServicesStatusInactive;
    }
}

@synthesize statusObservable = _statusObservable;

- (BOOL) doStart
{
    CLLocationManager *manager = self.getLocationManager;

    // Do nothing if manager is not initialized or waiting for authorization
    if (!manager || self.status == OALocationServicesStatusAuthorizing)
        return NO;
    
    BOOL didChange = NO;
    
    [self updateDeviceOrientation];
    
    // Set desired accuracy depending on app mode, and query for updates
    if (!_locationActive)
    {
        _waitingForAuthorization = !self.allowed;
        
        if (!self.allowed &&
            [manager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [manager requestAlwaysAuthorization];
        }
        
        manager.desiredAccuracy = [self desiredAccuracy];
        [manager startUpdatingLocation];
        _locationActive = YES;
        didChange = YES;
        
        OALog(@"Setting desired location accuracy to %f", manager.desiredAccuracy);
    }
    
    // Also, if compass is available, query it for updates
    if (!_compassActive && [CLLocationManager headingAvailable])
    {
        [manager startUpdatingHeading];
        _compassActive = YES;
        didChange = YES;
    }
    
    return didChange;
}

- (void) start
{
    @synchronized(_lock)
    {
        if ([self doStart])
        {
            OALog(@"Started location services");
            
            [_statusObservable notifyEvent];
        }
    }
}

- (BOOL) doStop
{
    CLLocationManager *manager = self.getLocationManager;
    BOOL didChange = NO;

    if (_waitingForAuthorization)
    {
        _waitingForAuthorization = NO;
        didChange = YES;
    }
    
    if (manager && _locationActive)
    {
        [manager stopUpdatingLocation];
        _locationActive = NO;
        didChange = YES;
    }
    
    if (manager && _compassActive)
    {
        [manager stopUpdatingHeading];
        _compassActive = NO;
        didChange = YES;
    }
    
    return didChange;
}

- (void) stop
{
    @synchronized(_lock)
    {
        if ([self doStop])
        {
            OALog(@"Stopped location services");
            
            [_statusObservable notifyEvent];
        }
    }
}

- (void) resume
{
    @synchronized(_lock)
    {
        if ([self doStart])
        {
            OALog(@"Resumed location services");

            _isSuspended = NO;

            [_statusObservable notifyEvent];
        }
    }
}

- (void)suspend
{
    @synchronized(_lock)
    {
        if ([self doStop])
        {
            OALog(@"Suspended location services");

            _isSuspended = YES;

            [_statusObservable notifyEvent];
        }
    }
}

- (CLLocation*) lastKnownLocation
{
    //return [[CLLocation alloc] initWithLatitude:44.953197568579 longitude:34.097549412400];

    @synchronized(_lock)
    {
        return _lastLocation;
    }
}

- (CLLocationDirection) lastKnownHeading
{
    @synchronized(_lock)
    {
        if (!isnan(_lastHeading))
            return _lastHeading;
        else
            return -1.0;
    }
}

- (CLLocationDirection) lastKnownMagneticHeading
{
    @synchronized(_lock)
    {
        if (!isnan(_lastMagneticHeading))
            return _lastMagneticHeading;
        else
            return 0;
    }
}

- (CLLocationDegrees) lastKnownDeclination
{
    @synchronized(_lock)
    {
        if (!isnan(_lastHeading) && !isnan(_lastMagneticHeading))
        {
            CLLocationDegrees res = _lastHeading - _lastMagneticHeading;
            EOAAngularConstant unit = [_settings.angularUnits get];
            if (unit == DEGREES && [_settings.showRelativeBearing get])
                return res > 180 ? res - 360 : res;
            else
                return res;
        }
        else
        {
            return 0;
        }
    }
}

@synthesize updateLocationObserver = _updateLocationObserver;
@synthesize updateHeadingObserver = _updateHeadingObserver;
@synthesize updateFirstTimeObserver = _updateFirstTimeObserver;

- (void) updateDeviceOrientation
{
    CLLocationManager *manager = self.getLocationManager;
    if (!manager)
        return;

    const UIInterfaceOrientation interfaceOrientation = [[OAScreenOrientationHelper sharedInstance] getCurrentInterfaceOrientation];
    CLDeviceOrientation clDeviceOrientation;
    switch (interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            clDeviceOrientation = CLDeviceOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            clDeviceOrientation = CLDeviceOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            clDeviceOrientation = CLDeviceOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            clDeviceOrientation = CLDeviceOrientationLandscapeRight;
            break;
        default:
            clDeviceOrientation = CLDeviceOrientationUnknown;
            break;
    }
    manager.headingOrientation = clDeviceOrientation;
}

- (CLLocationAccuracy) desiredAccuracy
{
    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;

    // In case device is plugged-in, there's no reason to save battery
    if (batteryState == UIDeviceBatteryStateFull || batteryState == UIDeviceBatteryStateCharging)
        return kCLLocationAccuracyBestForNavigation;

    // In case app is in navigation mode, also best possible is needed
    if ([_routingHelper isFollowingMode])
        return kCLLocationAccuracyBestForNavigation;

    // In case app is in browsing mode and user is following map, a bit less than best accuracy is needed
    if (_settings.mapSettingTrackRecording)
        return kCLLocationAccuracyBest;

    // If just tracking position while browsing, it's safe to use medium accuracy
    if (_app.mapMode == OAMapModePositionTrack)
        return kCLLocationAccuracyNearestTenMeters;

    // If user is just browsing map, 100 meter accuracy should be ok
    if (_app.mapMode == OAMapModeFree)
        return kCLLocationAccuracyHundredMeters;

    // By default set minimal accuracy
    return kCLLocationAccuracyThreeKilometers;
}

- (void) updateRequestedAccuracy
{
    CLLocationManager *manager = self.getLocationManager;
    if (!manager)
        return;

    CLLocationAccuracy newDesiredAccuracy = [self desiredAccuracy];
    if (manager.desiredAccuracy == newDesiredAccuracy || self.status != OALocationServicesStatusActive)
        return;

    @synchronized(_lock)
    {
        if ([self doStop])
            [self doStart];
    }
}

- (BOOL) shouldBeRunningInBackground
{
    if (_settings.mapSettingTrackRecording || [_routingHelper isFollowingMode] || _app.carPlayActive)
        return YES;

    return NO;
}

- (void) onMapModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // If services are running, simply update accuracy
        OALocationServicesStatus status = self.status;
        if (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing)
        {
            [self updateRequestedAccuracy];
        }
        // If map mode is OAMapModePositionTrack and services are not running,
        // launch them (except if waiting for user authorization).
        else if (_app.mapMode == OAMapModePositionTrack)
        {
            [self start];
        }
    });
}

- (void) onFollowTheRouteChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // If services are running, simply update accuracy
        OALocationServicesStatus status = self.status;
        if (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing)
            [self updateRequestedAccuracy];
        else
            [self start];
    });
}

- (void) onSimulateRoutingChanged
{
    if (!_settings.simulateNavigation && [_locationSimulation isRouteAnimating])
        [_locationSimulation startStopRouteAnimation];
}

- (void) onDeviceOrientationDidChange
{
    [self updateDeviceOrientation];
}

- (void) onDeviceBatteryStateDidChange
{
    [self updateRequestedAccuracy];
}

- (void) onApplicationDidEnterBackground
{
    OALocationServicesStatus status = self.status;
    BOOL isRunning = (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing);
    if (isRunning && ![self shouldBeRunningInBackground])
    {
        OALog(@"Stopping location services when application went to background");

        [self suspend];
    }
    else
    {
        [self setupDistanceFilter:YES];
    }
}


- (void) onApplicationWillEnterForeground
{
    OALocationServicesStatus status = self.status;
    BOOL isRunning = (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing);
    if (!isRunning && _isSuspended)
    {
        OALog(@"Starting location services when application going to foreground");

        [self resume];
    }
    else
    {
        [self setupDistanceFilter:NO];
    }
}

- (void) setupDistanceFilter:(BOOL)enable
{
    CLLocationManager *manager = self.getLocationManager;
    if (!manager)
        return;

    if (enable)
        manager.distanceFilter = [_settings.applicationMode.get getBackgroundDistanceFilter];
    else
        manager.distanceFilter = kCLDistanceFilterNone;
}

+ (BOOL) isPointAccurateForRouting:(CLLocation *)loc
{
    return loc && loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy < ACCURACY_FOR_GPX_AND_ROUTING * 3 / 2;
}

- (void) onLocationLost
{
    _gpsSignalLost = YES;
    if ([_routingHelper isFollowingMode] && [_routingHelper getLeftDistance] > 0)
        [[_routingHelper getVoiceRouter] gpsLocationLost];
    
    [self setLocation:nil];
}

- (void) startLocationSimulation:(CLLocation *)location
{
    const auto& tunnel = [_routingHelper getUpcomingTunnel:1000];
    if (!tunnel.empty())
    {
        _simulatePosition = [[OASimulationProvider alloc] init];
        [_simulatePosition startSimulation:tunnel currentLocation:location];
        [self simulatePositionImpl];
    }
}

- (void) simulatePosition
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(simulatePositionImpl) object:nil];
    [self performSelector:@selector(simulatePositionImpl) withObject:nil afterDelay:0.6];
}

- (void) simulatePositionImpl
{
    if (_simulatePosition)
    {
        CLLocation *loc = [_simulatePosition getSimulatedLocation];
        if (loc)
        {
            [self setLocation:loc];
            [self simulatePosition];
        }
        else
        {
            _simulatePosition = nil;
        }
    }
}

- (void) scheduleLocationLostCheck:(CLLocation *)location
{
    if (location)
    {
        if ([_routingHelper isFollowingMode] && [_routingHelper getLeftDistance] > 0 && !_simulatePosition)
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startLocationSimulation:) object:_locationStartSim];
            _locationStartSim = [location copy];
            [self performSelector:@selector(startLocationSimulation:) withObject:_locationStartSim afterDelay:START_LOCATION_SIMULATION_DELAY];
        }
    }
}

- (void) setLocationFromSimulation:(CLLocation *)location
{
    [self setLocation:location];
}

- (BOOL) isInLocationSimulation
{
    return _simulatePosition != nil;
}

- (void) setLocation:(CLLocation *)location
{
    if (location)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onLocationLost) object:nil];

        _simulatePosition = nil;
        if (_gpsSignalLost)
        {
            _gpsSignalLost = NO;
            if ([_routingHelper isFollowingMode] && [_routingHelper getLeftDistance] > 0)
                [[_routingHelper getVoiceRouter] gpsLocationRecover];
        }
    }
    //[self enhanceLocation:location];
    [self scheduleLocationLostCheck:location];
    // 1. Logging services
    if (location)
    {
        [OASavingTrackHelper.sharedInstance updateLocation:location heading:_lastHeading];
        [OAAverageSpeedComputer.sharedInstance updateLocation:location];
        [[OAAverageGlideComputer shared] updateLocation:location];
        //OsmandPlugin.updateLocationPlugins(location);
    }
    
    // 2. routing
    [_routingHelper updateLocation:location];
    CLLocation *updatedLocation = location;
    if ([_routingHelper isFollowingMode])
    {
        if (!location || [self.class isPointAccurateForRouting:location])
        {
            // Update routing position and get location for sticking mode
            updatedLocation = [_routingHelper setCurrentLocation:location returnUpdatedLocation:[_settings.snapToRoad get]];
        }
    }
    else if ([_routingHelper isRoutePlanningMode] && !_app.data.pointToStart)
    {
        [_routingHelper setCurrentLocation:location returnUpdatedLocation:NO];
    }
    else if ([_locationSimulation isRouteAnimating])
    {
        [_routingHelper setCurrentLocation:location returnUpdatedLocation:NO];
    }

    [[OAWaypointHelper sharedInstance] locationChanged:location];
    @synchronized(_lock)
    {
        _lastLocation = updatedLocation;
        [_updateLocationObserver notifyEvent];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void) locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    CLAuthorizationStatus status = manager.authorizationStatus;

    // If services were running, but now authorization was revoked, stop them
    if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse && status != kCLAuthorizationStatusNotDetermined && (_locationActive || _compassActive))
        [self stop];
    else if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse)
        [self start];

    [_stateObservable notifyEvent];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.domain == kCLErrorDomain)
    {
        if (error.code == kCLErrorDenied)
        {
            // User have denied services or revoked authorization, stop the services
            // If services were running, but now authorization was revoked, stop them
            if (_locationActive || _compassActive)
                [self stop];
            return;
        }
        else if (error.code == kCLErrorLocationUnknown)
        {
            _locationLostTime = [NSDate date];
            [self onLocationLost];
        }
    }

    OALog(@"CLLocationManager didFailWithError %@", error);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If was waiting for authorization, now it's granted
    if (_waitingForAuthorization)
    {
        [_statusObservable notifyEvent];
        _waitingForAuthorization = NO;
    }
    
    if (!locations || ![locations lastObject] || [_locationSimulation isRouteAnimating])
        return;
    
    BOOL wasLocationUnknown = (_lastLocation == nil);
    
    [self setLocation:[locations lastObject]];

    if (wasLocationUnknown)
        [_updateFirstTimeObserver notifyEvent];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    // If was waiting for authorization, now it's granted
    if (_waitingForAuthorization)
    {
        [_statusObservable notifyEvent];
        _waitingForAuthorization = NO;
    }
    @synchronized(_lock)
    {
        _lastHeading = newHeading.trueHeading;
        _lastMagneticHeading = newHeading.magneticHeading;
        //if (![_locationSimulation isRouteAnimating])
            [_updateHeadingObserver notifyEvent];
    }
}

#pragma mark -

+ (void) showDeniedAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"loc_access_denied") message:OALocalizedString(@"loc_access_denied_desc") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.sharedApplication.mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (NSString *) stringFromBearingToLocation:(CLLocation *)destinationLocation
{
    CLLocation *location = self.lastKnownLocation;
    if (location && destinationLocation)
    {
        TTTLocationFormatter* formatter = [[TTTLocationFormatter alloc] init];
        return [formatter stringFromBearingFromLocation:location toLocation:destinationLocation];
    }
    else
    {
        return nil;
    }
}

// Relative to north
- (CGFloat) radiusFromBearingToLocation:(CLLocation *)destinationLocation
{
    return [self radiusFromBearingToLocation:destinationLocation sourceLocation:self.lastKnownLocation];
}

- (CGFloat) radiusFromBearingToLocation:(CLLocation *)destinationLocation sourceLocation:(CLLocation*)sourceLocation
{
    if (sourceLocation && destinationLocation)
    {
        return [self radiusFromBearingToLatitude:destinationLocation.coordinate.latitude longitude:destinationLocation.coordinate.longitude sourceLocation:sourceLocation];
    }
    else
    {
        return 0;
    }
}

- (CGFloat) radiusFromBearingToLatitude:(double)latitude longitude:(double)longitude
{
    return [self radiusFromBearingToLatitude:latitude longitude:longitude sourceLocation:self.lastKnownLocation];
}

- (CGFloat) radiusFromBearingToLatitude:(double)latitude longitude:(double)longitude sourceLocation:(CLLocation*)sourceLocation
{
    if (sourceLocation)
    {
        CLLocationCoordinate2D coord1 = sourceLocation.coordinate;
        CLLocationCoordinate2D coord2 = CLLocationCoordinate2DMake(latitude, longitude);
        double distance, bearing;
        [self.class computeDistanceAndBearing:coord1.latitude lon1:coord1.longitude lat2:coord2.latitude lon2:coord2.longitude distance:&distance initialBearing:&bearing];
        
        return bearing;
    }
    else
    {
        return 0;
    }
}

+ (void) computeDistanceAndBearing:(double)lat1 lon1:(double)lon1 lat2:(double)lat2 lon2:(double)lon2 distance:(double *)distance initialBearing:(double *)initialBearing /*finalBearing:(double *)finalBearing*/
{
    // Based on https://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf
    // using the "Inverse Formula" (section 4)

    int MAXITERS = 20;
    // Convert lat/long to radians
    lat1 *= M_PI / 180.0;
    lat2 *= M_PI / 180.0;
    lon1 *= M_PI / 180.0;
    lon2 *= M_PI / 180.0;
    
    double a = 6378137.0; // WGS84 major axis
    double b = 6356752.3142; // WGS84 semi-major axis
    double f = (a - b) / a;
    double aSqMinusBSqOverBSq = (a * a - b * b) / (b * b);
    
    double L = lon2 - lon1;
    double A = 0.0;
    double U1 = atan((1.0 - f) * tan(lat1));
    double U2 = atan((1.0 - f) * tan(lat2));
    
    double cosU1 = cos(U1);
    double cosU2 = cos(U2);
    double sinU1 = sin(U1);
    double sinU2 = sin(U2);
    double cosU1cosU2 = cosU1 * cosU2;
    double sinU1sinU2 = sinU1 * sinU2;
    
    double sigma = 0.0;
    double deltaSigma = 0.0;
    double cosSqAlpha = 0.0;
    double cos2SM = 0.0;
    double cosSigma = 0.0;
    double sinSigma = 0.0;
    double cosLambda = 0.0;
    double sinLambda = 0.0;
    
    double lambda = L; // initial guess
    for (int iter = 0; iter < MAXITERS; iter++)
    {
        double lambdaOrig = lambda;
        cosLambda = cos(lambda);
        sinLambda = sin(lambda);
        double t1 = cosU2 * sinLambda;
        double t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
        double sinSqSigma = t1 * t1 + t2 * t2; // (14)
        sinSigma = sqrt(sinSqSigma);
        cosSigma = sinU1sinU2 + cosU1cosU2 * cosLambda; // (15)
        sigma = atan2(sinSigma, cosSigma); // (16)
        double sinAlpha = (sinSigma == 0) ? 0.0 :
        cosU1cosU2 * sinLambda / sinSigma; // (17)
        cosSqAlpha = 1.0 - sinAlpha * sinAlpha;
        cos2SM = (cosSqAlpha == 0) ? 0.0 :
        cosSigma - 2.0 * sinU1sinU2 / cosSqAlpha; // (18)
        
        double uSquared = cosSqAlpha * aSqMinusBSqOverBSq; // defn
        A = 1 + (uSquared / 16384.0) * // (3)
        (4096.0 + uSquared *
         (-768 + uSquared * (320.0 - 175.0 * uSquared)));
        double B = (uSquared / 1024.0) * // (4)
        (256.0 + uSquared *
         (-128.0 + uSquared * (74.0 - 47.0 * uSquared)));
        double C = (f / 16.0) *
        cosSqAlpha *
        (4.0 + f * (4.0 - 3.0 * cosSqAlpha)); // (10)
        double cos2SMSq = cos2SM * cos2SM;
        deltaSigma = B * sinSigma * // (6)
        (cos2SM + (B / 4.0) *
         (cosSigma * (-1.0 + 2.0 * cos2SMSq) -
          (B / 6.0) * cos2SM *
          (-3.0 + 4.0 * sinSigma * sinSigma) *
          (-3.0 + 4.0 * cos2SMSq)));
        
        lambda = L +
        (1.0 - C) * f * sinAlpha *
        (sigma + C * sinSigma *
         (cos2SM + C * cosSigma *
          (-1.0 + 2.0 * cos2SM * cos2SM))); // (11)
        
        double delta = (lambda - lambdaOrig) / lambda;

        if (fabs(delta) < 1.0e-12)
            break;
    }
    if (distance)
        *distance = (b * A * (sigma - deltaSigma));
    if (initialBearing)
        *initialBearing = atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (180.0 / M_PI);
    //*finalBearing = atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda) * (180.0 / M_PI);
}

@end
