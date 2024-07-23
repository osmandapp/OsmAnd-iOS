//
//  OALocationSimulation.mm
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/OsmAndLocationSimulation.java
// git revision af522f8c5c428aa6cacbd8ce1e44dfac779b6458

#import "OALocationSimulation.h"
#import "OsmAndApp.h"
#import "OAObservable.h"
#import "OALocationServices.h"
#import "OARoutingHelper.h"
#import "Localization.h"
#import "OAAlertBottomSheetViewController.h"
#import "OAMapUtils.h"
#import "OAAppSettings.h"
#import "OARouteCalculationResult.h"
#import "CLLocation+Extension.h"

#define PRECISION_1_M 0.00001f
#define DEVIATION_M 6
#define MOTORWAY_MAX_SPEED 120;
#define TRUNK_MAX_SPEED 90;
#define PRIMARY_MAX_SPEED 60;
#define SECONDARY_MAX_SPEED 50;
#define LIVING_SPTREET_MAX_SPEED 15;
#define DEFAULT_MAX_SPEED 40;

@implementation OALocationSimulation
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSThread *_routeAnimation;
    double _lastCourse;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}


- (BOOL) isRouteAnimating
{
    return _routeAnimation != nil; 
}

- (void) startStopRouteAnimation
{
    if (![self isRouteAnimating])
    {
        if ([[[OARoutingHelper sharedInstance] getRoute] isEmpty])
        {
            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"route_simulation")
                                                       titleIcon:@"ic_custom_alert"
                                                         message:OALocalizedString(@"animate_routing_route_not_calculated")
                                                     cancelTitle:OALocalizedString(@"shared_string_cancel")];
        }
        else
        {
            [self startAnimationThread:nil useLocationTime:false coeff:1];
        }
    }
    else
    {
        [self stop];
    }
}

- (void) startAnimationThread:(NSArray<OASimulatedLocation *> *)directionsArray useLocationTime:(BOOL)useLocationTime coeff:(float)coeff
{
    NSTimeInterval time = 1.5f;
    float simSpeed = _settings.simulateNavigationSpeed;
    EOASimulationMode simulationMode = [OASimulationMode getMode:_settings.simulateNavigationMode];
    BOOL realistic = simulationMode == EOASimulationModeRealistic;
    
    _routeAnimation = [[NSThread alloc] initWithBlock:^{
        
        NSMutableArray<OASimulatedLocation *> *directions;
        if (!directionsArray)
        {
            NSArray<OASimulatedLocation *> *currentRoute =  [[[OARoutingHelper sharedInstance] getRoute] getImmutableSimulatedLocations];
            directions = [NSMutableArray arrayWithArray:currentRoute];
        }
        else
        {
            directions = [NSMutableArray arrayWithArray:directionsArray];
        }

        if (directions.count == 0)
        {
            [self stop];
            return;
        }

        OASimulatedLocation *current = [[OASimulatedLocation alloc] initWithSimulatedLocation:directions[0]];
        [directions removeObjectAtIndex:0];

        OASimulatedLocation *prev = current;
        NSTimeInterval prevTime = !current ? 0 : [current.timestamp timeIntervalSince1970];
        double meters = [self metersToGoInFiveSteps:directions current:current];
        int stopDelayCount = 0;

        while (directions.count > 0 && _routeAnimation)
        {
            NSTimeInterval timeout = time;
            NSTimeInterval intervalTime = time;
            CLLocationSpeed speed = -1;
            CLLocationAccuracy accuracy = -1;
            CLLocationDirection course = -1;
            
            if (stopDelayCount == 0)
            {
                if (useLocationTime)
                {
                    current = [[OASimulatedLocation alloc] initWithSimulatedLocation:directions[0]];
                    [directions removeObjectAtIndex:0];
                    meters = [current distanceFromLocation:prev];
                    if (directions.count > 0)
                    {
                        timeout = ABS([directions[0].timestamp timeIntervalSince1970] - [current.timestamp timeIntervalSince1970]);
                        intervalTime = ABS([current.timestamp timeIntervalSince1970] - prevTime);
                        prevTime = [current.timestamp timeIntervalSince1970];
                    }
                }
                else
                {
                    NSArray *result;
                    if (simulationMode == EOASimulationModeConstant)
                    {
                        result = [self useSimulationConstantSpeed:simSpeed current:current directions:directions meters:meters intervalTime:intervalTime coeff:coeff];
                    }
                    else
                    {
                        result = [self useDefaultSimulation:current directions:directions meters:meters intervalTime:intervalTime coeff:coeff isRealistic:realistic];
                    }
                    current = (OASimulatedLocation *)result[0];
                    meters = ((NSNumber *)result[1]).floatValue;
                }
                if (intervalTime != 0)
                {
                    speed = (meters / intervalTime * coeff);
                }
                if (current.horizontalAccuracy <= 0 || isnan(current.horizontalAccuracy) || (realistic && speed < 10))
                {
                    accuracy = 5;
                }

                if ((prev && [prev distanceFromLocation:current] > 3) || (realistic && speed >= 3))
                {
                    course = [OAMapUtils normalizeDegrees360:[prev bearingTo:current]];
                    if (course > 0)
                        _lastCourse = course;
                }
                else if ([current hasBearing])
                {
                    course = current.course;
                    _lastCourse = course;
                }
                
                if (course < 0)
                    course = _lastCourse;
            }
            
            CLLocation *toset = [[CLLocation alloc] initWithCoordinate:current.coordinate altitude:current.altitude horizontalAccuracy:accuracy >= 0 ? accuracy : current.horizontalAccuracy verticalAccuracy:current.verticalAccuracy course:course speed:speed >= 0 ? speed : current.speed timestamp:[NSDate date]];
            
            if (realistic) {
                toset = [self addNoise:toset];
            }
            
            if (realistic && current.isTrafficLight && stopDelayCount == 0)
            {
                stopDelayCount = 5;
                speed = 0;
                current = [self removeBearing:current];
            }
            else if (stopDelayCount > 0)
            {
                stopDelayCount--;
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [_app.locationServices setLocationFromSimulation:toset];
            });

            [NSThread sleepForTimeInterval:timeout / coeff];

            prev = current;
        }
        
        [self stop];
    }];
    
    [_routeAnimation start];
}

- (CLLocation *)addNoise:(CLLocation *)location
{
    float d = (((int)arc4random_uniform(DEVIATION_M + 1)) - DEVIATION_M / 2) * PRECISION_1_M;
    double lat = location.coordinate.latitude + d;
    d = (((int)arc4random_uniform(DEVIATION_M + 1)) - DEVIATION_M / 2) * PRECISION_1_M;
    double lon = location.coordinate.longitude + d;
    
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon) altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
}

- (OASimulatedLocation *)removeBearing:(CLLocation *)location
{
    return [[OASimulatedLocation alloc] initWithLocation:[[CLLocation alloc] initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:0 speed:location.speed timestamp:location.timestamp]];
}

- (NSArray *)useSimulationConstantSpeed:(float)speed current:(OASimulatedLocation *)current directions:(NSMutableArray<OASimulatedLocation *> *)directions meters:(float)meters intervalTime:(float)intervalTime coeff:(float)coeff
{
    NSMutableArray *result = [NSMutableArray array];
    if ([current distanceFromLocation:directions[0]] > meters)
    {
        current = [[OASimulatedLocation alloc] initWithSimulatedLocation:[self middleLocation:current end:directions[0] meters:meters]];
    }
    else
    {
        current = [[OASimulatedLocation alloc] initWithSimulatedLocation:directions[0]];
        [directions removeObjectAtIndex:0];
    }
    meters = speed * intervalTime * coeff;
    
    [result addObject:current];
    [result addObject:[NSNumber numberWithFloat:meters]];
    
    return [NSArray arrayWithArray:result];
}

- (NSArray *)useDefaultSimulation:(OASimulatedLocation *)current directions:(NSMutableArray<OASimulatedLocation *> *)directions meters:(float)meters intervalTime:(float)intervalTime coeff:(float)coeff isRealistic:(BOOL)isRealistic
{
    NSMutableArray *result = [NSMutableArray array];
    if ([current distanceFromLocation:directions[0]] > meters)
    {
        current = [[OASimulatedLocation alloc] initWithSimulatedLocation:[self middleLocation:current end:directions[0] meters:meters]];
    }
    else
    {
        current = [[OASimulatedLocation alloc] initWithSimulatedLocation:directions[0]];
        [directions removeObjectAtIndex:0];
        meters = [self metersToGoInFiveSteps:directions current:current];  
    }

    if (isRealistic)
    {
        float limit = [self getMetersLimitForPoint:current intervalTime:intervalTime coeff:coeff];
        if (meters > limit)
            meters = limit;
    }
    
    [result addObject:current];
    [result addObject:[NSNumber numberWithFloat:meters]];
    
    return [NSArray arrayWithArray:result];
}

- (OASimulatedLocation *) middleLocation:(OASimulatedLocation *)start end:(OASimulatedLocation *)end meters:(float)meters
{
    double lat1 = qDegreesToRadians(start.coordinate.latitude);
    double lon1 = qDegreesToRadians(start.coordinate.longitude);
    double R = 6371; // radius of earth in km
    double d = meters / 1000; // in km
    double brngDeg = [start bearingTo:end];
    float brng = (float) (qDegreesToRadians(brngDeg));
    double lat2 = asin(sin(lat1) * cos(d / R) + cos(lat1) * sin(d / R) * cos(brng));
    double lon2 = lon1 + atan2(sin(brng) * sin(d / R) * cos(lat1), cos(d / R) - sin(lat1) * sin(lat2));
    CLLocation *nl = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(qRadiansToDegrees(lat2), qRadiansToDegrees(lon2)) altitude:start.altitude horizontalAccuracy:0 verticalAccuracy:start.verticalAccuracy course:[OAMapUtils normalizeDegrees360:brngDeg] speed:start.speed timestamp:start.timestamp];
    OASimulatedLocation *result = [[OASimulatedLocation alloc] initWithLocation:nl];
    [result setTrafficLight:false];
    return result;
}

- (float) metersToGoInFiveSteps:(NSArray<OASimulatedLocation *> *)directions current:(OASimulatedLocation *)current
{
    return directions.count == 0 ? 20.0f : MAX(20.0f, [current distanceFromLocation:directions[0]] / 2);
}

- (float) getMetersLimitForPoint:(OASimulatedLocation *)point intervalTime:(float)intervalTime coeff:(float)coeff
{
    float maxSpeed = [self getMaxSpeedForRoadType:[point getHighwayType]] / 3.6;
    float speedLimit = [point getSpeedLimit];
    if (speedLimit > 0 && maxSpeed > speedLimit)
        maxSpeed = speedLimit;
    return maxSpeed * intervalTime / coeff;
}

- (float) getMaxSpeedForRoadType:(NSString *)roadType
{
    if ([roadType isEqualToString:@"motorway"])
    {
        return MOTORWAY_MAX_SPEED;
    }
    else if ([roadType isEqualToString:@"trunk"])
    {
        return TRUNK_MAX_SPEED;
    }
    else if ([roadType isEqualToString:@"primary"])
    {
        return PRIMARY_MAX_SPEED;
    }
    else if ([roadType isEqualToString:@"secondary"])
    {
        return SECONDARY_MAX_SPEED;
    }
    else if ([roadType isEqualToString:@"living_street"] || [roadType isEqualToString:@"residential"])
    {
        return LIVING_SPTREET_MAX_SPEED;
    }
    else
    {
        return DEFAULT_MAX_SPEED;
    }
}

- (void) stop
{
    _routeAnimation = nil;
    [_app.simulateRoutingObservable notifyEvent];
}

@end


@implementation OALocation

- (instancetype)initWithProvider:(NSString *)provider location:(CLLocation *)location
{
    self = [super initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    if (self)
    {
        _provider = provider;
    }
    return self;
}

@end


@implementation OASimulatedLocation
{
    BOOL _trafficLight;
    NSString *_highwayType;
    float _speedLimit;
}

- (instancetype)initWithSimulatedLocation:(OASimulatedLocation *)location
{
    self = [super initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
    if (self)
    {
        _trafficLight = [location isTrafficLight];
        _highwayType = [location getHighwayType];
        _speedLimit = [location getSpeedLimit];
    }
    return self;
}

- (instancetype)initWithLocation:(CLLocation *)location
{
    self = [super initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
    if (self)
    {
        _trafficLight = NO;
        _highwayType = @"";
        _speedLimit = 0;
    }
    return self;
}

- (BOOL)isTrafficLight
{
    return _trafficLight;
}

- (void)setTrafficLight:(BOOL)trafficLight
{
    _trafficLight = trafficLight;
}

- (CLLocationDistance) distanceFromLocation:(OASimulatedLocation *)location
{
    return [super distanceFromLocation:((CLLocation *)location)];
}

- (NSString *)getHighwayType
{
    return _highwayType;
}

- (void)setHighwayType:(NSString *)highwayType
{
    _highwayType = highwayType;
}

- (float)getSpeedLimit
{
    return _speedLimit;
}

- (void)setSpeedLimit:(float)speedLimit
{
    _speedLimit = speedLimit;
}

@end
