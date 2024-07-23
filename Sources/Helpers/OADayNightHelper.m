//
//  OADayNightHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADayNightHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAObservable.h"
#import "SunriseSunset.h"
#import "OALocationServices.h"

@implementation OADayNightHelper
{
    NSTimeInterval _lastTime;
    BOOL _lastNightMode;
    BOOL _firstCall;
    NSTimeInterval _recalcInterval;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _firstCall = YES;
        _recalcInterval = 1.0;
    }
    return self;
}

+ (OADayNightHelper *) instance
{
    static dispatch_once_t once;
    static OADayNightHelper * instance;
    dispatch_once(&once, ^{
        
        instance = [[self alloc] init];
    });
    return instance;
}

- (void) forceUpdate
{
    _lastTime = 0;
    [self isNightMode];
}

/**
 * @return null if could not be determined (in case of error)
 * @return true if day is supposed to be
 */
- (BOOL) isNightMode
{
    BOOL nightMode = _lastNightMode;
    int dayNightMode = [[OAAppSettings sharedManager].appearanceMode get];
    if (dayNightMode == APPEARANCE_MODE_DAY)
    {
        nightMode = NO;
    }
    else if (dayNightMode == APPEARANCE_MODE_NIGHT)
    {
        nightMode = YES;
    }
    else if (dayNightMode == APPEARANCE_MODE_AUTO)
    {
        NSTimeInterval currentTime = CACurrentMediaTime();
        // allow recalculation each 60 seconds
        if (currentTime - _lastTime > _recalcInterval)
        {
            _lastTime = currentTime;
            SunriseSunset *daynightSwitch = [self getSunriseSunset];
            if (daynightSwitch)
            {
                _recalcInterval = 60.0;
                BOOL daytime = [daynightSwitch isDaytime];
                nightMode = !daytime;
            }
        }
    }
    else
    {
        nightMode = NO;
    }
    
    if (_lastNightMode != nightMode)
    {
        _lastNightMode = nightMode;
        NSLog(@"Sunrise/sunset setting to day: %@", nightMode ? @"NO" : @"YES");
        if (!_firstCall)
            [[[OsmAndApp instance] dayNightModeObservable] notifyEvent];
    }

    if (_firstCall)
        _firstCall = NO;

    return nightMode;
}

- (SunriseSunset *) getSunriseSunset
{
    CLLocation *lastKnownLocation = OsmAndApp.instance.locationServices.lastKnownLocation;
    if (!lastKnownLocation)
        return nil;
    
    double longitude = lastKnownLocation.coordinate.longitude;
    NSDate *actualTime = [NSDate date];
    SunriseSunset *daynightSwitch = [[SunriseSunset alloc] initWithLatitude:lastKnownLocation.coordinate.latitude longitude:longitude < 0 ? 360 + longitude : longitude dateInputIn:actualTime tzIn:[NSTimeZone localTimeZone]];
    return daynightSwitch;
}

@end
