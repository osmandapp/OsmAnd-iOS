//
//  OARouteInfoWidgetsFactory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteInfoWidgetsFactory.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OATextInfoWidget.h"
#import "OAUtilities.h"
#import "OAMapViewTrackingUtilities.h"
#import "OACurrentPositionHelper.h"
#import "OADistanceToPointInfoControl.h"
#import "OARTargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OANextTurnInfoWidget.h"
#import "OALanesControl.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"

#include <CommonCollections.h>
#include <binaryRead.h>

#define TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME @"time_control_widget_state_arrival_time"
#define TIME_CONTROL_WIDGET_STATE_TIME_TO_GO @"time_control_widget_state_time_to_go"
#define BEARING_WIDGET_STATE_RELATIVE_BEARING @"bearing_widget_state_relative_bearing"
#define BEARING_WIDGET_STATE_MAGNETIC_BEARING @"bearing_widget_state_magnetic_bearing"

static float MIN_SPEED_FOR_HEADING = 1.f;

@interface OADistanceControl : OADistanceToPointInfoControl

@end

@implementation OADistanceControl

- (instancetype) init
{
    self = [super initWithIcons:@"widget_target_day" nightIconId:@"widget_target_night"];
    if (self)
    {
    }
    return self;
}

- (CLLocation *) getPointToNavigate
{
    OARTargetPoint *p = [[OATargetPointsHelper sharedInstance] getPointToNavigate];
    return p ? p.point : nil;
}

- (CLLocationDistance) getDistance
{
    OARoutingHelper *routinHelper = [OARoutingHelper sharedInstance];
    if ([routinHelper isRouteCalculated])
        return [routinHelper getLeftDistance];
    
    return [super getDistance];
}

@end

@interface OAIntermediateDistanceControl : OADistanceToPointInfoControl

@end

@implementation OAIntermediateDistanceControl

- (instancetype) init
{
    self = [super initWithIcons:@"widget_intermediate_day" nightIconId:@"widget_intermediate_night"];
    if (self)
    {
    }
    return self;
}

- (void) click
{
    if ([[OATargetPointsHelper sharedInstance] getIntermediatePoints].count > 1)
    {
        //TODO map.getMapActions().openIntermediatePointsDialog();
    }
    else
    {
        [super click];
    }
}

- (CLLocation *) getPointToNavigate
{
    OARTargetPoint *p = [[OATargetPointsHelper sharedInstance] getFirstIntermediatePoint];
    return p ? p.point : nil;
}

- (CLLocationDistance) getDistance
{
    OARoutingHelper *routinHelper = [OARoutingHelper sharedInstance];
    if ([self getPointToNavigate] && [routinHelper isRouteCalculated])
        return [routinHelper getLeftDistanceNextIntermediate];
    
    return [super getDistance];
}

@end

@implementation OATimeControlWidgetState
{
    OAProfileBoolean *_showArrival;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _showArrival = [OAAppSettings sharedManager].showArrivalTime;
    }
    return self;
}

- (NSString *) getMenuTitle
{
    return [_showArrival get] ? OALocalizedString(@"access_arrival_time") : OALocalizedString(@"map_widget_time");
}

- (NSString *) getMenuIconId
{
    return [_showArrival get] ? @"ic_action_time" : @"ic_action_time_to_distance";
}

- (NSString *) getMenuItemId
{
    return [_showArrival get] ? TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME : TIME_CONTROL_WIDGET_STATE_TIME_TO_GO;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return @[ @"access_arrival_time", @"map_widget_time" ];
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return @[ @"ic_action_time", @"ic_action_time_to_distance" ];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[ TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME, TIME_CONTROL_WIDGET_STATE_TIME_TO_GO ];
}

- (void) changeState:(NSString *)stateId
{
    [_showArrival set:[TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME isEqualToString:stateId]];
}

@end

@implementation OABearingWidgetState
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (NSString *) getMenuTitle
{
    return _settings.showRelativeBearing ? OALocalizedString(@"map_widget_bearing") : OALocalizedString(@"map_widget_magnetic_bearing");
}

- (NSString *) getMenuIconId
{
    return _settings.showRelativeBearing ? @"ic_action_relative_bearing" : @"ic_action_bearing";
}

- (NSString *) getMenuItemId
{
    return _settings.showRelativeBearing ? BEARING_WIDGET_STATE_RELATIVE_BEARING : BEARING_WIDGET_STATE_MAGNETIC_BEARING;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return @[ @"map_widget_magnetic_bearing", @"map_widget_bearing" ];
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return @[ @"ic_action_bearing", @"ic_action_relative_bearing" ];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[ BEARING_WIDGET_STATE_MAGNETIC_BEARING, BEARING_WIDGET_STATE_RELATIVE_BEARING ];
}

- (void) changeState:(NSString *)stateId
{
    _settings.showRelativeBearing = [BEARING_WIDGET_STATE_RELATIVE_BEARING isEqualToString:stateId];
}

@end

@implementation OARouteInfoWidgetsFactory
{
    OsmAndAppInstance _app;
    OARoutingHelper *_routingHelper;
    OACurrentPositionHelper *_currentPositionHelper;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _routingHelper = [OARoutingHelper sharedInstance];
        _currentPositionHelper = [OACurrentPositionHelper instance];
    }
    return self;
}

- (OATextInfoWidget *) createTimeControl
{
    NSString *time = @"widget_time_day";
    NSString *timeN = @"widget_time_night";
    NSString *timeToGo = @"widget_time_to_distance_day";
    NSString *timeToGoN = @"widget_time_to_distance_night";
    
    OAProfileBoolean *showArrival = [OAAppSettings sharedManager].showArrivalTime;
    OATextInfoWidget *leftTimeControl = [[OATextInfoWidget alloc] init];
    
    __weak OATextInfoWidget *leftTimeControlWeak = leftTimeControl;
    NSTimeInterval __block cachedLeftTime = 0;
    leftTimeControl.updateInfoFunction = ^BOOL{
        [leftTimeControlWeak setIcons:[showArrival get] ? time : timeToGo widgetNightIcon:[showArrival get] ? timeN : timeToGoN];
        NSTimeInterval time = 0;
        if (_routingHelper && [_routingHelper isRouteCalculated])
        {
            //boolean followingMode = routingHelper.isFollowingMode();
            time = [_routingHelper getLeftTime];
            if (time != 0)
            {
                if (/*followingMode && */[showArrival get])
                {
                    NSTimeInterval toFindTime = time + [NSDate date].timeIntervalSince1970;
                    if (ABS(toFindTime - cachedLeftTime) > 30)
                    {
                        cachedLeftTime = toFindTime;
                        [leftTimeControlWeak setContentTitle:OALocalizedString(@"access_arrival_time")];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        NSDate *toFindDate = [NSDate dateWithTimeIntervalSince1970:toFindTime];
                        if (![OAUtilities is12HourTimeFormat])
                        {
                            [dateFormatter setDateFormat:@"HH:mm"];
                            [leftTimeControlWeak setText:[dateFormatter stringFromDate:toFindDate] subtext:nil];
                        }
                        else
                        {
                            [dateFormatter setDateFormat:@"h:mm"];
                            NSString *timeStr = [dateFormatter stringFromDate:toFindDate];
                            [dateFormatter setDateFormat:@"a"];
                            NSString *aStr = [dateFormatter stringFromDate:toFindDate];
                            [leftTimeControlWeak setText:timeStr subtext:aStr];
                        }
                        return YES;
                    }
                }
                else
                {
                    if (ABS(time - cachedLeftTime) > 30)
                    {
                        cachedLeftTime = time;
                        int hours, minutes, seconds;
                        [OAUtilities getHMS:time hours:&hours minutes:&minutes seconds:&seconds];
                        NSString *timeStr = [NSString stringWithFormat:@"%d:%02d", hours, minutes];
                        [leftTimeControlWeak setContentTitle:OALocalizedString(@"map_widget_time")];
                        [leftTimeControlWeak setText:timeStr subtext:nil];
                        return YES;
                    }
                }
            }
        }
        if (time == 0 && cachedLeftTime != 0) {
            cachedLeftTime = 0;
            [leftTimeControlWeak setText:nil subtext:nil];
            return YES;
        }
        return NO;
    };

    leftTimeControl.onClickFunction = ^(id sender) {
        [showArrival set:![showArrival get]];
        [leftTimeControlWeak setIcons:[showArrival get] ? time : timeToGo widgetNightIcon:[showArrival get] ? timeN : timeToGoN];
    };
    
    [leftTimeControl setText:nil subtext:nil];
    [leftTimeControl setIcons:[showArrival get] ? time : timeToGo widgetNightIcon:[showArrival get] ? timeN : timeToGoN];
    return leftTimeControl;
}

- (OATextInfoWidget *) createPlainTimeControl
{
    OATextInfoWidget *plainTimeControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *plainTimeControlWeak = plainTimeControl;
    NSTimeInterval __block cachedLeftTime = 0;
    plainTimeControl.updateInfoFunction = ^BOOL{
        NSTimeInterval time = [NSDate date].timeIntervalSince1970;
        if (time - cachedLeftTime > 5)
        {
            cachedLeftTime = time;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
            if (![OAUtilities is12HourTimeFormat])
            {
                [dateFormatter setDateFormat:@"HH:mm"];
                [plainTimeControlWeak setText:[dateFormatter stringFromDate:date] subtext:nil];
            }
            else
            {
                [dateFormatter setDateFormat:@"h:mm"];
                NSString *timeStr = [dateFormatter stringFromDate:date];
                [dateFormatter setDateFormat:@"a"];
                NSString *aStr = [dateFormatter stringFromDate:date];
                [plainTimeControlWeak setText:timeStr subtext:aStr];
            }
        }
        return NO;
    };

    [plainTimeControl setText:nil subtext:nil];
    [plainTimeControl setIcons:@"widget_time_day" widgetNightIcon:@"widget_time_night"];
    return plainTimeControl;
}

- (OATextInfoWidget *) createBatteryControl
{
    NSString *battery = @"widget_battery_day";
    NSString *batteryN = @"widget_battery_night";
    NSString *batteryCharging = @"widget_battery_charging_day";
    NSString *batteryChargingN = @"widget_battery_charging_night";

    OATextInfoWidget *batteryControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *batteryControlWeak = batteryControl;
    NSTimeInterval __block cachedLeftTime = 0;
    batteryControl.updateInfoFunction = ^BOOL{
        NSTimeInterval time = [NSDate date].timeIntervalSince1970;
        if (time - cachedLeftTime > 1)
        {
            cachedLeftTime = time;

            float level = [UIDevice currentDevice].batteryLevel;
            UIDeviceBatteryState status = [UIDevice currentDevice].batteryState;
            
            if (level == -1 || status == UIDeviceBatteryStateUnknown)
            {
                [batteryControlWeak setText:@"?" subtext:nil];
                [batteryControlWeak setIcons:battery widgetNightIcon:batteryN];
            }
            else
            {
                BOOL charging = (status == UIDeviceBatteryStateCharging || status == UIDeviceBatteryStateFull);
                [batteryControlWeak setText:[NSString stringWithFormat:@"%d%%", (int)(level * 100)] subtext:nil];
                [batteryControlWeak setIcons:charging ? batteryCharging : battery widgetNightIcon:charging ? batteryChargingN : batteryN];
            }
        }
        return NO;
    };

    [batteryControl setText:nil subtext:nil];
    [batteryControl setIcons:battery widgetNightIcon:batteryN];
    return batteryControl;
}

- (OATextInfoWidget *) createMaxSpeedControl
{
    //final OsmAndLocationProvider locationProvider = map.getMyApplication().getLocationProvider();
    OATextInfoWidget *speedControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *speedControlWeak = speedControl;
    float __block cachedSpeed = 0.f;
    speedControl.updateInfoFunction = ^BOOL{
        float mx = 0;
        OAMapViewTrackingUtilities *trackingUtilities = [OAMapViewTrackingUtilities instance];
        if ((!_routingHelper || ![_routingHelper isFollowingMode] || [OARoutingHelper isDeviatedFromRoute] || [_routingHelper getCurrentGPXRoute]) && [trackingUtilities isMapLinkedToLocation])
        {
            // TODO
            //auto ro = [_currentPositionHelper getLastKnownRouteSegment:_app.locationServices.lastKnownLocation];
            //if (ro)
                //mx = ro->getMaximumSpeed(ro.bearingVsRouteDirection(locationProvider.getLastKnownLocation()));
        }
        else if (_routingHelper)
        {
            mx = [_routingHelper getCurrentMaxSpeed];
        }
        else
        {
            mx = 0;
        }
        if (cachedSpeed != mx)
        {
            cachedSpeed = mx;
            if (cachedSpeed == 0)
            {
                [speedControlWeak setText:nil subtext:nil];
            }
            else if (cachedSpeed == 40.f /*RouteDataObject::NONE_MAX_SPEED*/)
            {
                [speedControlWeak setText:OALocalizedString(@"max_speed_none") subtext:@""];
            }
            else
            {
                NSString *ds = [[OsmAndApp instance] getFormattedSpeed:cachedSpeed];
                int ls = [ds indexOf:@" "];
                if (ls == -1)
                    [speedControlWeak setText:ds subtext:nil];
                else
                    [speedControlWeak setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
            }
            return true;
        }
        return false;
    };
        
    [speedControl setIcons:@"widget_max_speed_day" widgetNightIcon:@"widget_max_speed_night"];
    [speedControl setText:nil subtext:nil];
    return speedControl;
}

- (OATextInfoWidget *) createSpeedControl
{
    OATextInfoWidget *speedControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *speedControlWeak = speedControl;
    float __block cachedSpeed = 0;
    speedControl.updateInfoFunction = ^BOOL{
        CLLocation *loc = _app.locationServices.lastKnownLocation;
        // draw speed
        if (loc && loc.speed >= 0)
        {
            // .1 mps == 0.36 kph
            float minDelta = .1f;
            // Update more often at walk/run speeds, since we give higher resolution
            // and use .02 instead of .03 to account for rounding effects.
            if (cachedSpeed < 6)
                minDelta = .015f;

            if (ABS(loc.speed - cachedSpeed) > minDelta)
            {
                cachedSpeed = loc.speed;
                NSString *ds = [_app getFormattedSpeed:cachedSpeed];
                int ls = [ds indexOf:@" "];
                if (ls == -1)
                    [speedControlWeak setText:ds subtext:nil];
                else
                    [speedControlWeak setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];

                return YES;
            }
        }
        else if (cachedSpeed != 0)
        {
            cachedSpeed = 0;
            [speedControlWeak setText:nil subtext:nil];
            return YES;
        }
        return NO;
    };
        
    [speedControl setIcons:@"widget_speed_day" widgetNightIcon:@"widget_speed_night"];
    [speedControl setText:nil subtext:nil];
    return speedControl;
}

+ (BOOL) degreesChanged:(int)oldDegrees degrees:(int)degrees
{
    return ABS(oldDegrees - degrees) >= 1;
}

+ (CLLocation *) getPointToNavigate
{
    OARTargetPoint *p = [[OATargetPointsHelper sharedInstance] getFirstIntermediatePoint];
    return p ? p.point : nil;
}

+ (int) getBearing:(BOOL)relative
{
    int d = -1000;
    CLLocation *myLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    CLLocationDirection heading = [OsmAndApp instance].locationServices.lastKnownHeading;
    CLLocationDegrees declination = [OsmAndApp instance].locationServices.lastKnownDeclination;
    CLLocation *l = [self.class getPointToNavigate];
    if (!l)
    {
        NSMutableArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        if (destinations.count > 0)
        {
            OADestination *d = destinations[0];
            l = [[CLLocation alloc] initWithLatitude:d.latitude longitude:d.longitude];
        }
    }
    if (myLocation && l)
    {
        double bearing = [myLocation bearingTo:l];
        double bearingToDest = bearing - declination;
        if (relative)
        {
            float b = -1000;
            if (myLocation.speed < MIN_SPEED_FOR_HEADING || myLocation.course < 0)
            {
                b = heading;
            }
            else if (myLocation.course >= 0)
            {
                b = myLocation.course - declination;
            }
            if (b > -1000) {
                bearingToDest -= b;
                if (bearingToDest > 180)
                    bearingToDest -= 360;
                else if (bearingToDest < -180)
                    bearingToDest += 360;
                
                d = (int) bearingToDest;
            }
        }
        else
        {
            d = (int) bearingToDest;
        }
    }
    return d;
}

- (OATextInfoWidget *) createBearingControl
{
    OATextInfoWidget *bearingControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *bearingControlWeak = bearingControl;
    int __block cachedDegrees = 0;
    
    static NSString *bearingResId = @"widget_bearing_day";
    static NSString *bearingNightResId = @"widget_bearing_night";
    static NSString *relativeBearingResId = @"widget_relative_bearing_day";
    static NSString *relativeBearingNightResId = @"widget_relative_bearing_night";
    
    bearingControl.updateInfoFunction = ^BOOL {
        
        BOOL relative = [OAAppSettings sharedManager].showRelativeBearing;
        BOOL modeChanged = [bearingControlWeak setIcons:relative ? relativeBearingResId : bearingResId widgetNightIcon:relative ? relativeBearingNightResId : bearingNightResId];
        [bearingControlWeak setContentTitle:relative ? OALocalizedString(@"map_widget_bearing") : OALocalizedString(@"map_widget_magnetic_bearing")];
        int b = [OARouteInfoWidgetsFactory getBearing:relative];
        if ([OARouteInfoWidgetsFactory degreesChanged:cachedDegrees degrees:b] || modeChanged)
        {
            cachedDegrees = b;
            if (b != -1000)
                [bearingControlWeak setText:[NSString stringWithFormat:@"%d°%@", b, relative ? @"" : @" M"] subtext:nil];
            else
                [bearingControlWeak setText:nil subtext:nil];
            
            return YES;
        }
        return NO;
    };
    
    bearingControl.onClickFunction = ^(id sender) {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        settings.showRelativeBearing = !settings.showRelativeBearing;
        [bearingControlWeak updateInfo];
    };
    
    BOOL showRelativeBearing = [OAAppSettings sharedManager].showRelativeBearing;
    [bearingControl setText:nil subtext:nil];
    [bearingControl setIcons:!showRelativeBearing ? bearingResId : relativeBearingResId widgetNightIcon:!showRelativeBearing ? bearingNightResId : relativeBearingNightResId];
    return bearingControl;
}

- (OATextInfoWidget *) createDistanceControl
{
    return [[OADistanceControl alloc] init];
}

- (OATextInfoWidget *) createIntermediateDistanceControl
{
    return [[OAIntermediateDistanceControl alloc] init];
}

- (OANextTurnInfoWidget *) createNextInfoControl:(BOOL)horisontalMini
{
    OANextTurnInfoWidget *widget = [[OANextTurnInfoWidget alloc] initWithHorisontalMini:horisontalMini nextNext:NO];
    [widget updateVisibility:NO];
    return widget;
}

- (OANextTurnInfoWidget *) createNextNextInfoControl:(BOOL)horisontalMini
{
    OANextTurnInfoWidget *widget = [[OANextTurnInfoWidget alloc] initWithHorisontalMini:horisontalMini nextNext:YES];
    [widget updateVisibility:NO];
    return widget;
}

- (OALanesControl *) createLanesControl
{
    return [[OALanesControl alloc] init];
}

@end
