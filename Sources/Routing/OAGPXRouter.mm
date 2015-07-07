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
            NSString *path = [_app.gpxPath stringByAppendingPathComponent:activeRouteFileName];
            self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
        }
    }
    return self;
}

- (void)setRouteWithGpx:(OAGPX *)gpx
{
    _gpx = gpx;
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFileName];
    self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
    [[OAAppSettings sharedManager] setMapSettingActiveRouteFileName:gpx.gpxFileName];
    
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
    self.routeDoc = nil;
    [[OAAppSettings sharedManager] setMapSettingActiveRouteFileName:nil];

    [self.routeCanceledObservable notifyEvent];
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

@end
