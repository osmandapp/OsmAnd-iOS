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
#import "OAMapStyleSettings.h"
#import "OATspAnt.h"
#import "OASmartNaviWatchNavigationWaypoint.h"
#import "OASmartNaviWatchSession.h"

/*
 - pedestrian slow       3 km/h
 - pedestrian            5 km/h
 - bicycle              15 km/h
 - car                  40 km/h
 */

const double kKmhToMps = 1.0/3.6;
const double kMotionSpeedPedestrianSlow = 3.0 * kKmhToMps;
const double kMotionSpeedPedestrian = 5.0 * kKmhToMps;
const double kMotionSpeedBicycle = 15.0 * kKmhToMps;
const double kMotionSpeedCar = 40.0 * kKmhToMps;

@implementation OAGPXRouter
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationServicesUpdateObserver;
    NSTimeInterval _lastUpdate;
    BOOL _isModified;
    
    OAAutoObserverProxy *_routeChangedObserver;
    
    NSObject *_saveSynchObj;
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
        _saveSynchObj = [[NSObject alloc] init];
        
        _app = [OsmAndApp instance];
        _lastUpdate = 0.0;
        _isModified = NO;
        
        _locationUpdatedObservable = [[OAObservable alloc] init];
        _routeDefinedObservable = [[OAObservable alloc] init];
        _routeCanceledObservable = [[OAObservable alloc] init];
        _routeChangedObservable = [[OAObservable alloc] init];
        
        _routePointDeactivatedObservable = [[OAObservable alloc] init];
        _routePointActivatedObservable = [[OAObservable alloc] init];
 
        // Init active route
        NSString *activeRouteFileName = [[OAAppSettings sharedManager] mapSettingActiveRouteFileName];
        if (activeRouteFileName)
        {
            _gpx = [[OAGPXDatabase sharedDb] getGPXItem:activeRouteFileName];

            NSString *path = [_app.gpxPath stringByAppendingPathComponent:activeRouteFileName];
            self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
        }
        
        [self refreshDestinations];
        
        _routeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onRouteChanged)
                                                              andObserve:self.routeChangedObservable];
    }
    return self;
}

- (BOOL)hasActiveRoute
{
    return self.gpx != nil;
}

- (void)setRouteWithGpx:(OAGPX *)gpx
{
    _gpx = gpx;
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFileName];
    self.routeDoc = [[OAGPXRouteDocument alloc] initWithGpxFile:path];
    [[OAAppSettings sharedManager] setMapSettingActiveRouteFileName:gpx.gpxFileName];
    
    OAMapVariantType variantType = [OAMapStyleSettings getVariantType:_app.data.lastMapSource.variant];
    switch (variantType)
    {
        case OAMapVariantCar:
            self.routeVariantType = OAGPXRouteVariantCar;
            break;
        case OAMapVariantPedestrian:
            self.routeVariantType = OAGPXRouteVariantPedestrian;
            break;
        case OAMapVariantBicycle:
            self.routeVariantType = OAGPXRouteVariantBicycle;
            break;
            
        default:
            self.routeVariantType = OAGPXRouteVariantPedestrian;
            break;
    }
    
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
    @synchronized(_saveSynchObj)
    {
        if (_gpx && _routeDoc)
        {
            _isModified = NO;
            NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName];
            [_routeDoc saveTo:path];
        }
    }
}

- (void)saveRouteIfModified
{
    if (_isModified)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self saveRoute];
        });
    }
}

- (void)onRouteChanged
{
    _isModified = YES;
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
    //TODO move this as an observable
    [[OASmartNaviWatchSession sharedInstance] updateSignificantLocationChange:_app.locationServices.lastKnownLocation];
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

-(OAGPXRouteVariantType)routeVariantType
{
    return (OAGPXRouteVariantType)[OAAppSettings sharedManager].mapSettingActiveRouteVariantType;
}

-(void)setRouteVariantType:(OAGPXRouteVariantType)routeVariantType
{
    [OAAppSettings sharedManager].mapSettingActiveRouteVariantType = routeVariantType;
}

- (NSTimeInterval)getRouteDuration
{
    return [self getRouteDuration:self.routeVariantType];
}

- (NSTimeInterval)getRouteDuration:(OAGPXRouteVariantType)routeVariantType
{
    double distance = self.routeDoc.totalDistance;
    switch (routeVariantType)
    {
        case OAGPXRouteVariantPedestrianSlow:
            return distance / kMotionSpeedPedestrianSlow;
        case OAGPXRouteVariantPedestrian:
            return distance / kMotionSpeedPedestrian;
        case OAGPXRouteVariantBicycle:
            return distance / kMotionSpeedBicycle;
        case OAGPXRouteVariantCar:
            return distance / kMotionSpeedCar;
            
        default:
            return -1.0;
    }
}

- (void)refreshDestinations
{
    [self refreshDestinations:NO];
}

- (void)refreshDestinations:(BOOL)rebuildPointsOrder
{
    NSArray *array = (self.routeDoc ? self.routeDoc.activePoints : nil);
    [[OADestinationsHelper instance] updateRoutePointsWithinDestinations:array rebuildPointsOrder:rebuildPointsOrder];
}

- (void)refreshRoute
{
    [self refreshRoute:NO];
}

- (void)refreshRoute:(BOOL)rebuildPointsOrder
{
    [self.routeDoc updateDistances];
    [self refreshDestinations:rebuildPointsOrder];
    [self.routeDoc buildRouteTrack];
}

- (NSString *)getRouteVariantTypeIconName
{
    switch (self.routeVariantType)
    {
        case OAGPXRouteVariantPedestrian:
        case OAGPXRouteVariantPedestrianSlow:
            return @"ic_mode_pedestrian";

        case OAGPXRouteVariantBicycle:
            return @"ic_mode_bike";

        case OAGPXRouteVariantCar:
            return @"ic_mode_car";
            
        default:
            return @"ic_mode_pedestrian";
    }
}

- (NSString *)getRouteVariantTypeSmallIconName
{
    switch (self.routeVariantType)
    {
        case OAGPXRouteVariantPedestrian:
        case OAGPXRouteVariantPedestrianSlow:
            return @"ic_trip_pedestrian";

        case OAGPXRouteVariantBicycle:
            return @"ic_trip_bike";

        case OAGPXRouteVariantCar:
            return @"ic_trip_car";
            
        default:
            return @"ic_trip_pedestrian";
    }
}

- (CGFloat)getMovementSpeed
{
    return [self getMovementSpeed:self.routeVariantType];
}

- (CGFloat)getMovementSpeed:(OAGPXRouteVariantType)routeVariantType
{
    switch (routeVariantType)
    {
        case OAGPXRouteVariantPedestrianSlow:
            return kMotionSpeedPedestrianSlow;

        case OAGPXRouteVariantPedestrian:
            return kMotionSpeedPedestrian;
            
        case OAGPXRouteVariantBicycle:
            return kMotionSpeedBicycle;
            
        case OAGPXRouteVariantCar:
            return kMotionSpeedCar;
            
        default:
            return kMotionSpeedPedestrian;
    }
}

- (void)sortRoute
{
    OAGpxRouteWptItem *startItem = [_routeDoc.activePoints firstObject];
    OAGpxRouteWptItem *endItem = [_routeDoc.activePoints lastObject];
    NSMutableArray *otherItems = [NSMutableArray array];
    for (OAGpxRouteWptItem *item in _routeDoc.activePoints)
    {
        if (item != startItem && item != endItem)
            [otherItems addObject:item];
    }
    
    CLLocation *start = [[CLLocation alloc] initWithLatitude:startItem.point.position.latitude longitude:startItem.point.position.longitude];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:endItem.point.position.latitude longitude:endItem.point.position.longitude];
    NSMutableArray *l = [NSMutableArray array];
    for (OAGpxRouteWptItem *item in otherItems)
        [l addObject:[[CLLocation alloc] initWithLatitude:item.point.position.latitude longitude:item.point.position.longitude]];
    
    OATspAnt *t = [[OATspAnt alloc] init];
    [t readGraph:l start:start end:end];
    NSArray *ans = [t solve];
    for (int k = 0; k < ans.count; k++)
    {
        int ansK = [ans[k] intValue];
        ((OAGpxRouteWptItem *)_routeDoc.activePoints[ansK]).point.index = k;
    }
    
    [_routeDoc.activePoints sortUsingComparator:^NSComparisonResult(OAGpxRouteWptItem *item1, OAGpxRouteWptItem *item2) {
        if (item2.point.index > item1.point.index)
            return NSOrderedAscending;
        else if (item2.point.index < item1.point.index)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
}

-(NSArray *)getCurrentWaypointsForCurrentLocation:(CLLocation*)currentLocation {
    
    NSMutableArray *currentWaypoints = [[NSMutableArray alloc] init];
    
    // fetch active location data
    
    // 1. drawn waypoints if any
    if (_routeDoc.activePoints.count > 0) {

        return [self convertOALocationMarksToSmartNaviWaypointsWithData:_routeDoc.activePoints andLocation:currentLocation];
        
    } else if (_routeDoc.routes.count > 0) {
        
        // 2. gpx route if any
        NSArray *points = ((OAGpxRte*)[_routeDoc.routes objectAtIndex:0]).points;
        return [self convertOALocationMarksToSmartNaviWaypointsWithData:points andLocation:currentLocation];

        
    } else if (_routeDoc.tracks.count > 0) {
        // 3. gpx track if any
        OAGpxTrk *gpxTrk = ((OAGpxTrk*) [_routeDoc.tracks objectAtIndex:0]);
        NSArray *segments = gpxTrk.segments;
        if (segments.count > 0) {
            OAGpxTrkSeg* segment = [segments objectAtIndex:0];
            return [self convertOALocationMarksToSmartNaviWaypointsWithData:segment.points andLocation:currentLocation];
        }
    }
    
    return currentWaypoints;
}

-(NSString*)getTitleOfActiveRoute {
    return [_gpx getNiceTitle];
}

-(NSArray*)convertOALocationMarksToSmartNaviWaypointsWithData:(NSArray*)locationMarks andLocation:(CLLocation*)currentLocation {
    
    NSMutableArray *currentWaypoints = [[NSMutableArray alloc] init];
    CLLocation *lastLocation = currentLocation;

    for (int i=0; i<locationMarks.count; ++i) {
        OASmartNaviWatchNavigationWaypoint *waypoint = [[OASmartNaviWatchNavigationWaypoint alloc] init];

        NSObject *locationObject = [locationMarks objectAtIndex:i];
        OALocationMark *locationMark;
        
        // wptItem already has distance set, OALocatioMark needs to be extracted
        if ([locationObject isKindOfClass:[OAGpxRouteWptItem class]]) {
            OAGpxRouteWptItem* wptItem = (OAGpxRouteWptItem*)locationObject;
            locationMark = wptItem.point;
            [waypoint setDistance:wptItem.distanceMeters];
        } else {
            locationMark = (OALocationMark*)locationObject;
            [waypoint setDistance: [lastLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:locationMark.position.latitude longitude:locationMark.position.longitude]]];
        }
        
        [waypoint setPosition:locationMark.position];
        [waypoint setName:locationMark.name];
        lastLocation = [[CLLocation alloc] initWithLatitude:locationMark.position.latitude longitude:locationMark.position.longitude];
        [currentWaypoints addObject:waypoint];
        
    }
    return currentWaypoints;
}

@end
