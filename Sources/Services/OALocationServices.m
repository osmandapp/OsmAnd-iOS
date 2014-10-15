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
#include "Localization.h"

#define _(name) OALocationServices__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OALocationServices () <CLLocationManagerDelegate>
@end

@implementation OALocationServices
{
    OsmAndAppInstance _app;

    NSObject* _lock;

    CLLocationManager* _manager;
    BOOL _locationActive;
    BOOL _compassActive;

    OAAutoObserverProxy* _appModeObserver;
    OAAutoObserverProxy* _mapModeObserver;

    BOOL _waitingForAuthorization;

    CLLocation* _lastLocation;
    CLLocationDirection _lastHeading;

    BOOL _isSuspended;
}

- (instancetype)initWith:(OsmAndAppInstance)app
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

- (void)commonInit:(OsmAndAppInstance)app
{
    _app = app;

    _lock = [[NSObject alloc] init];

    _locationActive = NO;
    _compassActive = NO;
    _statusObservable = [[OAObservable alloc] init];

    _stateObservable = [[OAObservable alloc] init];

    _manager = [[CLLocationManager alloc] init];
    _manager.delegate = self;
    _manager.distanceFilter = kCLDistanceFilterNone;
    _manager.pausesLocationUpdatesAutomatically = NO;

    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];
    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];

    _waitingForAuthorization = NO;

    _lastLocation = nil;
    _lastHeading = NAN;
    _updateObserver = [[OAObservable alloc] init];

    _isSuspended = NO;

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(onDeviceOrientationDidChange)
                               name:UIDeviceOrientationDidChangeNotification
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

#if defined(OSMAND_IOS_DEV)
    _forceAccuracy = OALocationServicesForcedAccuracyNone;
#endif // defined(OSMAND_IOS_DEV)
}

- (void)deinit
{
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:UIDeviceOrientationDidChangeNotification
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

- (BOOL)available
{
    return [CLLocationManager locationServicesEnabled];
}

- (BOOL)compassPresent
{
    return [CLLocationManager headingAvailable];
}

- (BOOL)allowed
{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
}

- (BOOL)denied
{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied);
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

- (BOOL)doStart
{
    @synchronized(_lock)
    {
        // Do nothing if waiting for authorization
        if (self.status == OALocationServicesStatusAuthorizing)
            return NO;

        BOOL didChange = NO;

        [self updateDeviceOrientation];

        // Set desired accuracy depending on app mode, and query for updates
        if (!_locationActive)
        {
            _waitingForAuthorization = !self.allowed;

            // For iOS 8.0+ explicit authorization request is needed
            if (!self.allowed &&
                [OAUtilities iosVersionIsAtLeast:@"8.0"] &&
                [_manager respondsToSelector:@selector(requestAlwaysAuthorization)])
            {
                [_manager requestAlwaysAuthorization];
            }

            _manager.desiredAccuracy = [self desiredAccuracy];
            [_manager startUpdatingLocation];
            _locationActive = YES;
            didChange = YES;

            OALog(@"Setting desired location accuracy to %f", _manager.desiredAccuracy);
        }

        // Also, if compass is available, query it for updates
        if (!_compassActive && [CLLocationManager headingAvailable])
        {
            [_manager startUpdatingHeading];
            _compassActive = YES;
            didChange = YES;
        }

        return didChange;
    }
}

- (void)start
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

- (BOOL)doStop
{
    @synchronized(_lock)
    {
        BOOL didChange = NO;

        if (_waitingForAuthorization)
        {
            _waitingForAuthorization = NO;
            didChange = YES;
        }

        if (_locationActive)
        {
            [_manager stopUpdatingLocation];
            _locationActive = NO;
            didChange = YES;
        }

        if (_compassActive)
        {
            [_manager stopUpdatingHeading];
            _compassActive = NO;
            didChange = YES;
        }

        return didChange;
    }
}

- (void)stop
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

- (void)resume
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

- (CLLocation*)lastKnownLocation
{
    if (_lastLocation != nil)
        return _lastLocation;
    return [_manager.location copy];
}

- (CLLocationDirection)lastKnownHeading
{
    if (!isnan(_lastHeading))
        return _lastHeading;
    return _manager.heading.trueHeading;
}

@synthesize updateObserver = _updateObserver;

- (void)updateDeviceOrientation
{
    const UIDeviceOrientation uiDeviceOrientation = [UIDevice currentDevice].orientation;
    CLDeviceOrientation clDeviceOrientation;
    switch (uiDeviceOrientation)
    {
        case UIDeviceOrientationPortrait:
            clDeviceOrientation = CLDeviceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            clDeviceOrientation = CLDeviceOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            clDeviceOrientation = CLDeviceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            clDeviceOrientation = CLDeviceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationFaceUp:
            clDeviceOrientation = CLDeviceOrientationFaceUp;
            break;
        case UIDeviceOrientationFaceDown:
            clDeviceOrientation = CLDeviceOrientationFaceDown;
            break;

        case UIDeviceOrientationUnknown:
        default:
            clDeviceOrientation = CLDeviceOrientationUnknown;
            break;
    }
    _manager.headingOrientation = clDeviceOrientation;
}

#if defined(OSMAND_IOS_DEV)
@synthesize forceAccuracy = _forceAccuracy;
#endif // defined(OSMAND_IOS_DEV)

- (CLLocationAccuracy)desiredAccuracy
{
#if defined(OSMAND_IOS_DEV)
    switch (_forceAccuracy)
    {
        default:
        case OALocationServicesForcedAccuracyNone:
            // Do nothing
            break;

        case OALocationServicesForcedAccuracyBest:
            return kCLLocationAccuracyBest;

        case OALocationServicesForcedAccuracyBestForNavigation:
            return kCLLocationAccuracyBestForNavigation;
    }
#endif // defined(OSMAND_IOS_DEV)

    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;

    // In case device is plugged-in, there's no reason to save battery
    if (batteryState == UIDeviceBatteryStateFull || batteryState == UIDeviceBatteryStateCharging)
        return kCLLocationAccuracyBestForNavigation;

    // In case app is in navigation mode, also best possible is needed
    if (_app.appMode == OAAppModeNavigation)
        return kCLLocationAccuracyBestForNavigation;

    // In case app is in driving mode, a bit less than best accuracy is needed
    if (_app.appMode == OAAppModeDrive)
        return kCLLocationAccuracyBest;

    // In case app is in browsing mode and user is following map, a bit less than best accuracy is needed
    if (_app.appMode == OAAppModeBrowseMap && _app.mapMode == OAMapModeFollow)
        return kCLLocationAccuracyBest;

    // If just tracking position while browsing, it's safe to use medium accuracy
    if (_app.appMode == OAAppModeBrowseMap && _app.mapMode == OAMapModePositionTrack)
        return kCLLocationAccuracyNearestTenMeters;

    // If user is just browsing map, 100 meter accuracy should be ok
    if (_app.appMode == OAAppModeBrowseMap && _app.mapMode == OAMapModeFree)
        return kCLLocationAccuracyHundredMeters;

    // By default set minimal accuracy
    return kCLLocationAccuracyThreeKilometers;
}

- (void)updateRequestedAccuracy
{
    CLLocationAccuracy newDesiredAccuracy = [self desiredAccuracy];
    if (_manager.desiredAccuracy == newDesiredAccuracy || self.status != OALocationServicesStatusActive)
        return;

    OALog(@"Changing desired location accuracy from %f to %f", _manager.desiredAccuracy, newDesiredAccuracy);

    @synchronized(_lock)
    {
        _manager.desiredAccuracy = newDesiredAccuracy;
        if ([self doStop])
            [self doStart];
    }
}

- (BOOL)shouldBeRunningInBackground
{
    //TODO: Or if recording GPX track
    if (_app.appMode == OAAppModeNavigation)
        return YES;

    return NO;
}

- (void)onAppModeChanged
{
    // If services are running, simply update accuracy
    OALocationServicesStatus status = self.status;
    if (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing)
    {
        [self updateRequestedAccuracy];
        return;
    }

    // For OAAppModeDrive and OAAppModeNavigation, services must be running
    if (_app.appMode == OAAppModeDrive || _app.appMode == OAAppModeNavigation)
        [self start];
}

- (void)onMapModeChanged
{
    // If services are running, simply update accuracy
    OALocationServicesStatus status = self.status;
    if (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing)
    {
        [self updateRequestedAccuracy];
        return;
    }

    // If map mode is OAMapModePositionTrack or OAMapModeFollow, and services are not running,
    // launch them (except if waiting for user authorization).
    if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
        [self start];
}

- (void)onDeviceOrientationDidChange
{
    [self updateDeviceOrientation];
}

- (void)onDeviceBatteryStateDidChange
{
    [self updateRequestedAccuracy];
}

- (void)onApplicationDidEnterBackground
{
    OALocationServicesStatus status = self.status;
    BOOL isRunning = (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing);
    if (isRunning && ![self shouldBeRunningInBackground])
    {
        OALog(@"Stopping location services when application went to background");

        [self suspend];
    }
}


- (void)onApplicationWillEnterForeground
{
    OALocationServicesStatus status = self.status;
    BOOL isRunning = (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing);
    if (!isRunning && _isSuspended)
    {
        OALog(@"Starting location services when application going to foreground");

        [self resume];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // If services were running, but now authorization was revoked, stop them
    if (status != kCLAuthorizationStatusAuthorized && status != kCLAuthorizationStatusNotDetermined && (_locationActive || _compassActive))
        [self stop];

    [_stateObservable notifyEvent];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.domain == kCLErrorDomain && error.code == kCLErrorDenied)
    {
        // User have denied services or revoked authorization, stop the services
        // If services were running, but now authorization was revoked, stop them
        if (_locationActive || _compassActive)
            [self stop];
        return;
    }

    OALog(@"CLLocationManager didFailWithError %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If was waiting for authorization, now it's granted
    if (_waitingForAuthorization)
    {
        [_statusObservable notifyEvent];
        _waitingForAuthorization = NO;
    }

    _lastLocation = [locations lastObject];
    [_updateObserver notifyEvent];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    // If was waiting for authorization, now it's granted
    if (_waitingForAuthorization)
    {
        [_statusObservable notifyEvent];
        _waitingForAuthorization = NO;
    }

    _lastHeading = newHeading.trueHeading;
    [_updateObserver notifyEvent];
}

#pragma mark -

+ (void)showDeniedAlert
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Access denied")
                                message:OALocalizedString(@"Access to location service has been denied")
                               delegate:nil
                      cancelButtonTitle:OALocalizedString(@"OK")
                      otherButtonTitles:nil] show];
}

- (NSString *)stringFromBearingToLocation:(CLLocation *)destinationLocation
{
    return [_app.locationFormatter stringFromBearingFromLocation:self.lastKnownLocation toLocation:destinationLocation];
}

- (CGFloat)radiusFromBearingToLocation:(CLLocation *)destinationLocation
{
    return [self radiusFromBearing:[self locationDegreesBearingBetweenCoordinates:self.lastKnownLocation.coordinate andCoordinates:destinationLocation.coordinate]];
}

static inline double DEG2RAD(double degrees) {
    return degrees * M_PI / 180;
}

static inline double RAD2DEG(double radians) {
    return radians * 180 / M_PI;
}

- (CLLocationDegrees) locationDegreesBearingBetweenCoordinates:(CLLocationCoordinate2D)originCoordinate andCoordinates:(CLLocationCoordinate2D) destinationCoordinate {
    double lat1 = DEG2RAD(originCoordinate.latitude);
    double lon1 = DEG2RAD(originCoordinate.longitude);
    double lat2 = DEG2RAD(destinationCoordinate.latitude);
    double lon2 = DEG2RAD(destinationCoordinate.longitude);
    
    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) + (2 * M_PI);
    
    // `atan2` works on a range of -π to 0 to π, so add on 2π and perform a modulo check
    if (bearing > (2 * M_PI)) {
        bearing = bearing - (2 * M_PI);
    }
    
    return RAD2DEG(bearing);
}

- (CGFloat) radiusFromBearing:(CLLocationDegrees)bearing {
    TTTLocationCardinalDirection direction = TTTLocationCardinalDirectionFromBearing(bearing);
    switch (direction) {
        case TTTNorthDirection:
            return 0;
        case TTTNortheastDirection:
            return 45;
        case TTTEastDirection:
            return 90;
        case TTTSoutheastDirection:
            return 135;
        case TTTSouthDirection:
            return 180;
        case TTTSouthwestDirection:
            return 225;
        case TTTWestDirection:
            return 270;
        case TTTNorthwestDirection:
            return 315;
        default:
            return 0;
    }
}

@end
