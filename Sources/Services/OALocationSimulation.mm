//
//  OALocationSimulation.mm
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALocationSimulation.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OARoutingHelper.h"
#import "Localization.h"
#import "OAAlertBottomSheetViewController.h"
#import "OAMapUtils.h"

@implementation OALocationSimulation
{
    OsmAndAppInstance _app;
    
    NSThread *_routeAnimation;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
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
        NSArray<CLLocation *> *currentRoute = [[OARoutingHelper sharedInstance] getCurrentCalculatedRoute];
        if (!currentRoute || currentRoute.count == 0)
        {
            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"route_simulation")
                                                       titleIcon:@"ic_custom_alert"
                                                         message:OALocalizedString(@"animate_routing_route_not_calculated")
                                                     cancelTitle:OALocalizedString(@"shared_string_cancel")];
        }
        else
        {
            [self startAnimationThread:currentRoute useLocationTime:false coeff:1];
        }
    }
    else
    {
        [self stop];
    }
}

- (void) startAnimationThread:(NSArray<CLLocation *> *)directionsArray useLocationTime:(BOOL)useLocationTime coeff:(float)coeff
{
    NSTimeInterval time = 1.5f;
    _routeAnimation = [[NSThread alloc] initWithBlock:^{
        
        NSMutableArray<CLLocation *> *directions = [NSMutableArray arrayWithArray:directionsArray];
        CLLocation *current = directions.count == 0 ? nil : directions[0];
        [directions removeObjectAtIndex:0];
        
        CLLocation *prev = current;
        NSTimeInterval prevTime = !current ? 0 : [current.timestamp timeIntervalSince1970];
        float meters = [self metersToGoInFiveSteps:directions current:current];

        while (directions.count > 0 && _routeAnimation)
        {
            NSTimeInterval timeout = time;
            NSTimeInterval intervalTime = time;
            if (useLocationTime)
            {
                current = directions[0];
                [directions removeObjectAtIndex:0];
                meters = [current distanceFromLocation:prev];
                if (directions.count > 0)
                {
                    timeout = [directions[0].timestamp timeIntervalSince1970] - [current.timestamp timeIntervalSince1970];
                    intervalTime = [current.timestamp timeIntervalSince1970] - prevTime;
                    prevTime = [current.timestamp timeIntervalSince1970];
                }
            }
            else
            {
                if (current && [current distanceFromLocation:directions[0]] > meters)
                {
                    current = [self middleLocation:current end:directions[0] meters:meters];
                }
                else
                {
                    current = directions[0];
                    [directions removeObjectAtIndex:0];
                    meters = [self metersToGoInFiveSteps:directions current:current];
                }
            }
            CLLocationSpeed speed = -1;
            if (intervalTime != 0)
                speed = (meters / intervalTime * coeff);
            
            CLLocationAccuracy accuracy = -1;
            if (current.horizontalAccuracy < 0)
                accuracy = 5;
            
            CLLocationDirection course = -1;
            if (prev && [prev distanceFromLocation:current] > 3)
                course = [OAMapUtils adjustBearing:[prev bearingTo:current]];
                        
            CLLocation *toset = [[CLLocation alloc] initWithCoordinate:current.coordinate altitude:current.altitude horizontalAccuracy:accuracy >= 0 ? accuracy : current.horizontalAccuracy verticalAccuracy:current.verticalAccuracy course:course >= 0 ? course : current.course speed:speed >= 0 ? speed : current.speed timestamp:[NSDate date]];
            
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

- (CLLocation *) middleLocation:(CLLocation *)start end:(CLLocation *)end meters:(float)meters
{
    double lat1 = qDegreesToRadians(start.coordinate.latitude);
    double lon1 = qDegreesToRadians(start.coordinate.longitude);
    double R = 6371; // radius of earth in km
    double d = meters / 1000; // in km
    double brngDeg = [start bearingTo:end];
    float brng = (float) (qDegreesToRadians(brngDeg));
    double lat2 = asin(sin(lat1) * cos(d / R) + cos(lat1) * sin(d / R) * cos(brng));
    double lon2 = lon1 + atan2(sin(brng) * sin(d / R) * cos(lat1), cos(d / R) - sin(lat1) * sin(lat2));
    CLLocation *nl = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(qRadiansToDegrees(lat2), qRadiansToDegrees(lon2)) altitude:start.altitude horizontalAccuracy:0 verticalAccuracy:start.verticalAccuracy course:[OAMapUtils adjustBearing:brngDeg] speed:start.speed timestamp:start.timestamp];
    return nl;
}

- (float) metersToGoInFiveSteps:(NSArray<CLLocation *> *)directions current:(CLLocation *)current
{
    return directions.count == 0 ? 20.0f : MAX(20.0f, [current distanceFromLocation:directions[0]] / 2);
}

- (void) stop
{
    _routeAnimation = nil;
}

@end
