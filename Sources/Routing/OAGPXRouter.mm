//
//  OAGPXRouter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAAutoObserverProxy.h"
#import "OADestination.h"
#import "OAGpxRouteWptItem.h"
#import "OADestinationsHelper.h"
#import "OAUtilities.h"

/*
 - default       3 km/h
 - pedestrian    3 km/h
 - car          40 km/h
 - bicycle      12 km/h
 */

const double kKmhToMps = 1.0/3.6;
const double kMotionSpeedDefault = 3.0 * kKmhToMps;
const double kMotionSpeedPedestrian = 3.0 * kKmhToMps;
const double kMotionSpeedBicycle = 12.0 * kKmhToMps;
const double kMotionSpeedCar = 40.0 * kKmhToMps;

@implementation OAGPXRouter
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationServicesUpdateObserver;
    NSTimeInterval _lastUpdate;
}

+ (OAGPXRouter *)sharedInstance
{
    static dispatch_once_t once;
    static OAGPXRouter * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _lastUpdate = 0.0;
        
        _locationUpdatedObservable = [[OAObservable alloc] init];
        _routeDefinedObservable = [[OAObservable alloc] init];
        _routeCanceledObservable = [[OAObservable alloc] init];
        _routeChangedObservable = [[OAObservable alloc] init];

        // Init active route
        NSString *activeRouteFileName = [[OAAppSettings sharedManager] mapSettingActiveRouteFileName];
        if (activeRouteFileName)
        {
            _gpx = [[OAGPXDatabase sharedDb] getGPXItem:activeRouteFileName];

            NSString *path = [_app.gpxPath stringByAppendingPathComponent:activeRouteFileName];
            self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
        }
        
        [self refreshDestinations];
    }
    return self;
}

- (void)setRouteWithGpx:(OAGPX *)gpx
{
    _gpx = gpx;
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFileName];
    self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
    [[OAAppSettings sharedManager] setMapSettingActiveRouteFileName:gpx.gpxFileName];
    
    [self refreshDestinations];
    [self.routeDefinedObservable notifyEvent];
}

-(void)setRouteDoc:(OAGPXRouteDocument *)routeDoc
{
    _routeDoc = routeDoc;
    if (routeDoc)
        [self startLocationObserver];
    else
        [self stopLocationObserver];
}

- (void)cancelRoute
{
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName];
    [_routeDoc clearAndSaveTo:path];
    
    _routeDoc = nil;
    _gpx = nil;
    [[OAAppSettings sharedManager] setMapSettingActiveRouteFileName:nil];

    [self refreshDestinations];
    [self.routeCanceledObservable notifyEvent];
}

- (void)saveRoute
{
    if (_gpx && _routeDoc)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName];
        [_routeDoc saveTo:path];
    }
}

- (void)startLocationObserver
{
    if (!_locationServicesUpdateObserver)
        _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
}

- (void)stopLocationObserver
{
    if (_locationServicesUpdateObserver) {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.3 && !forceUpdate)
        return;
    
    _lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.routeDoc updateDirections:newDirection myLocation:newLocation.coordinate];
        [self.locationUpdatedObservable notifyEvent];
    });
}

- (NSTimeInterval)getRouteDuration
{
    OAMapVariantType variantType = [OAMapStyleSettings getVariantType:_app.data.lastMapSource.variant];
    return [self getRouteDuration:variantType];
}

- (NSTimeInterval)getRouteDuration:(OAMapVariantType)mapVariantType
{
    double distance = self.routeDoc.totalDistance;
    switch (mapVariantType)
    {
        case OAMapVariantDefault:
            return distance / kMotionSpeedDefault;
        case OAMapVariantPedestrian:
            return distance / kMotionSpeedPedestrian;
        case OAMapVariantBicycle:
            return distance / kMotionSpeedBicycle;
        case OAMapVariantCar:
            return distance / kMotionSpeedCar;
            
        default:
            return -1.0;
    }
}

- (void)refreshDestinations
{
    NSArray *array = (self.routeDoc ? self.routeDoc.activePoints : nil);
    [[OADestinationsHelper instance] updateRoutePointsWithinDestinations:array];
}

@end
