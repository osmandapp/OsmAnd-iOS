//
//  OALocationServices.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocationServices.h"

#import "OsmAndApp.h"

@interface OALocationServices () <CLLocationManagerDelegate>
@end

@implementation OALocationServices
{
    OsmAndAppInstance _app;
    
    CLLocationManager* _manager;
    BOOL _locationActive;
    BOOL _compassActive;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _app = [OsmAndApp instance];
    
    _locationActive = NO;
    _compassActive = NO;
    _statusObservable = [[OAObservable alloc] init];
    
    _stateObservable = [[OAObservable alloc] init];
    
    _manager = [[CLLocationManager alloc] init];
    _manager.delegate = self;
    _manager.distanceFilter = kCLDistanceFilterNone;
    _manager.pausesLocationUpdatesAutomatically = NO;
}

- (void)dtor
{
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

@synthesize stateObservable = _stateObservable;

- (OALocationServicesStatus)status
{
    //TODO:
    return OALocationServicesStatusAuthorizing;//(_locationActive || _compassActive);
}

@synthesize statusObservable = _statusObservable;

- (void)start
{
    //TODO: use different accuracy modes
    // kCLLocationAccuracyBestForNavigation (when plugged in) && kCLLocationAccuracyBest - during navigation
    
    // Set desired accuracy depending on app mode, and query for updates
    _manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [_manager startUpdatingLocation];
    _locationActive = YES;
    
    // Also, if compass is available, query it for updates
    if([CLLocationManager headingAvailable])
    {
       [_manager startUpdatingHeading];
        _compassActive = YES;
    }
    
    [_statusObservable notifyEvent];
}

- (void)stop
{
    BOOL didChange = NO;
    
    if(_locationActive)
    {
        [_manager stopUpdatingLocation];
        _locationActive = NO;
        didChange = YES;
    }
    
    if(_compassActive)
    {
        [_manager stopUpdatingHeading];
        _compassActive = NO;
        didChange = YES;
    }
    
    if(didChange)
       [_statusObservable notifyEvent];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // If services were running, but now authorization was revoked, stop them
    if(status != kCLAuthorizationStatusAuthorized && (_locationActive || _compassActive))
        [self stop];
    
    [_stateObservable notifyEvent];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if(error.code == kCLErrorDenied)
    {
        //TODO: User have denied services, stop the services
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    
}

@end
