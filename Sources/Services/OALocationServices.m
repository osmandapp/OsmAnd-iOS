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
#include "Localization.h"
#import "OALog.h"

#define _(name) OALocationServices__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OALocationServices () <CLLocationManagerDelegate>
@end

@implementation OALocationServices
{
    OsmAndAppInstance _app;

    NSObject* _lock;

    CLLocationManager* _manager;
    BOOL _locationActive;
    BOOL _compassActive;

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
        [self ctor:app];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor:(OsmAndAppInstance)app
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

    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onMapModeChanged)];
    [_mapModeObserver observe:_app.mapModeObservable];

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
}

- (void)dtor
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
    return _manager.location;
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

- (CLLocationAccuracy)desiredAccuracy
{
    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;

    if (batteryState == UIDeviceBatteryStateFull || batteryState == UIDeviceBatteryStateCharging)
        return kCLLocationAccuracyBestForNavigation;
    if (_app.mapMode == OAMapModeFollow)
        return kCLLocationAccuracyBest;
    if (_app.mapMode == OAMapModePositionTrack)
        return kCLLocationAccuracyNearestTenMeters;
    if (_app.mapMode == OAMapModeFree)
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
    //TODO: YES only when not in drive or navigation mode
    return NO;
}

- (void)onMapModeChanged
{
    // If mode is OAMapModePositionTrack or OAMapModeFollow, and services are not running,
    // launch them (except if waiting for user authorization).
    OALocationServicesStatus status = self.status;
    if (status == OALocationServicesStatusActive || status == OALocationServicesStatusAuthorizing)
    {
        if (_app.mapMode == OAMapModeFree)
        {
            [self updateRequestedAccuracy];
            return;
        }

        return;
    }

    // Otherwise start service
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

@end
