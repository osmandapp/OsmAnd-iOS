//
//  OAAlarmWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAlarmWidget.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAWaypointHelper.h"
#import "OAAlarmInfo.h"
#import "OACurrentPositionHelper.h"
#import "OAOsmAndFormatter.h"

@implementation OAAlarmWidgetInfo

@end

@interface OAAlarmWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *bottomTextView;

@end

@implementation OAAlarmWidget
{
    OAMapViewTrackingUtilities *_trackingUtilities;
    OALocationServices *_locationProvider;
    OARoutingHelper *_rh;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAWaypointHelper *_wh;
    OACurrentPositionHelper *_currentPositionHelper;
    
    NSString *_imgId;
    NSString *_cachedText;
    NSString *_cachedBottomText;
    OADrivingRegion *_cachedRegion;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAAlarmWidget class]])
        {
            self = (OAAlarmWidget *)v;
            break;
        }
    }
    
    if (self)
        self.frame = CGRectMake(0, 0, 100, 100);
    
    [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OAAlarmWidget class]])
        {
            self = (OAAlarmWidget *)v;
            break;
        }
    }
    
    if (self)
        self.frame = CGRectMake(0, 0, 100, 100);
    
    [self commonInit];
    
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _rh = [OARoutingHelper sharedInstance];
    _app = [OsmAndApp instance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _locationProvider = _app.locationServices;
    _wh = [OAWaypointHelper sharedInstance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
    
    self.hidden = YES;
}

- (BOOL) updateInfo
{
//    BOOL showRoutingAlarms = [_settings.showRoutingAlarms get];
    BOOL trafficWarnings = [_settings.showTrafficWarnings get];
    BOOL cams = [_settings.showCameras get];
    BOOL browseMap = [_settings.applicationMode get] == OAApplicationMode.DEFAULT;
    BOOL visible = NO;
    if (([_rh isFollowingMode] || [_trackingUtilities isMapLinkedToLocation] && !browseMap)
            /*&& showRoutingAlarms*/ && (trafficWarnings || cams))
    {
        OAAlarmInfo *alarm;
        if ([_rh isFollowingMode] && ![OARoutingHelper isDeviatedFromRoute]
                && (![_rh getCurrentGPXRoute]) || [_rh isCurrentGPXRouteV2])
        {
            alarm = [_wh getMostImportantAlarm:[_settings.speedSystem get] showCameras:cams];
        }
        else
        {
            const auto ro = [_currentPositionHelper getLastKnownRouteSegment:_locationProvider.lastKnownLocation];
            CLLocation *loc = _locationProvider.lastKnownLocation;
            if (loc && ro)
            {
                alarm = [_wh calculateMostImportantAlarm:ro
                                                     loc:loc
                                                      mc:[_settings.metricSystem get]
                                                      sc:[_settings.speedSystem get]
                                             showCameras:cams];
            }
        }
        OAAlarmWidgetInfo *info;
        if (alarm)
        {
            info = [self createWidgetInfo:alarm];
            if (info)
            {
                visible = YES;
                if (![info.locImgId isEqualToString:_imgId])
                {
                    _imgId = info.locImgId;
                    [_imageView setImage:[UIImage imageNamed:info.locImgId]];
                }
                if (![self stringEquals:info.text b:_cachedText] || _cachedRegion != info.region)
                {
                    _cachedText = info.text;
                    _cachedRegion = info.region;
                    [_textView setText:_cachedText];

                    CGRect f = _textView.frame;
                    if (alarm.type == AIT_SPEED_LIMIT && info.americanType && !info.isCanadianRegion)
                        f.origin.y = alarm.type == 10;
                    else
                        f.origin.y = alarm.type == 0;
                    _textView.frame = f;
                }
                if (![self stringEquals:info.bottomText b:_cachedBottomText] || _cachedRegion != info.region)
                {
                    _cachedBottomText = info.bottomText;
                    _cachedRegion = info.region;
                    _bottomTextView.text = _cachedBottomText;
                    /*if (alarm.type == AIT_SPEED_LIMIT && info.isCanadianRegion)
                    {
                        int bottomPadding = res.getDimensionPixelSize(R.dimen.map_button_margin);
                        widgetBottomText.setPadding(0, 0, 0, bottomPadding);
                        widgetBottomText.setTextSize(COMPLEX_UNIT_PX, res.getDimensionPixelSize(R.dimen.map_alarm_bottom_si_text_size));
                    } else {
                        widgetBottomText.setPadding(0, 0, 0, 0);
                        widgetBottomText.setTextSize(COMPLEX_UNIT_PX, res.getDimensionPixelSize(R.dimen.map_alarm_bottom_text_size));
                    }*/
                    [_bottomTextView setTextColor:info.americanType ? UIColor.blackColor : UIColor.whiteColor];
                }
            }
        }
    }

    [self updateVisibility:visible];
    return YES;
}

- (BOOL) stringEquals:(NSString *)a b:(NSString *)b
{
    if (!a)
        return !b;
    else
        return [a isEqualToString:b];
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:nil visible:visible];
        
        return YES;
    }
    return NO;
}

- (OAAlarmWidgetInfo *)createWidgetInfo:(OAAlarmInfo *)alarm
{
    EOADrivingRegion region = [_settings.drivingRegion get];
    BOOL trafficWarnings = [_settings.showTrafficWarnings get];
    BOOL cams = [_settings.showCameras get];
    BOOL peds = [_settings.showPedestrian get];
    BOOL tunnels = [_settings.showTunnels get];
    BOOL americanType = [OADrivingRegion isAmericanSigns:region];

    NSString *locImgId = @"warnings_limit";
    NSString *text = @"";
    NSString *bottomText = @"";
    BOOL isCanadianRegion = region == DR_CANADA;
    if (alarm.type == AIT_SPEED_LIMIT)
    {
        if (isCanadianRegion)
        {
            locImgId = @"warnings_speed_limit_us";
            bottomText = [OASpeedConstant toShortString:[_settings.speedSystem get]];
        }
        else if (americanType)
        {
            locImgId = @"warnings_speed_limit_us";
            //else case is done by drawing red ring
        }
        text = @(alarm.intValue).stringValue;
    }
    else if (alarm.type == AIT_SPEED_CAMERA)
    {
        locImgId = @"warnings_speed_camera";
    }
    else if (alarm.type == AIT_BORDER_CONTROL)
    {
        locImgId = @"warnings_border_control";
    }
    else if (alarm.type == AIT_HAZARD)
    {
        if (americanType)
            locImgId = @"warnings_hazard_us";
        else
            locImgId = @"warnings_hazard";
    }
    else if (alarm.type == AIT_TOLL_BOOTH)
    {
        //image done by drawing red ring
        text = @"$";
    }
    else if (alarm.type == AIT_TRAFFIC_CALMING)
    {
        if (americanType)
            locImgId = @"warnings_traffic_calming_us";
        else
            locImgId = @"warnings_traffic_calming";
    }
    else if (alarm.type == AIT_STOP)
    {
        locImgId = @"warnings_stop";
    }
    else if (alarm.type == AIT_RAILWAY)
    {
        /*if (isCanadianRegion)
            locImgId = @"warnings_railways_ca";
        else*/ if (americanType)
            locImgId = @"warnings_railways_us";
        else
            locImgId = @"warnings_railways";
    }
    else if (alarm.type == AIT_PEDESTRIAN)
    {
        if (americanType)
            locImgId = @"warnings_pedestrian_us";
        else
            locImgId = @"warnings_pedestrian";
    }
    else if (alarm.type == AIT_TUNNEL)
    {
        if (americanType)
            locImgId = @"warnings_tunnel_us";
        else
            locImgId = @"warnings_tunnel";
        bottomText = [OAOsmAndFormatter getFormattedAlarmInfoDistance:alarm.floatValue];
    }
    else
    {
        text = nil;
        bottomText = nil;
    }
    BOOL visible;
    if (alarm.type == AIT_SPEED_CAMERA)
        visible = cams;
    else if (alarm.type == AIT_PEDESTRIAN)
        visible = peds;
    else if (alarm.type == AIT_TUNNEL)
        visible = tunnels;
    else
        visible = trafficWarnings;
    if (visible)
    {
        OAAlarmWidgetInfo *info = [OAAlarmWidgetInfo new];
        info.alarm = alarm;
        info.americanType = americanType;
        info.isCanadianRegion = isCanadianRegion;
        info.locImgId = locImgId;
        info.text = text;
        info.bottomText = bottomText;
        info.region = [OADrivingRegion withRegion:region];
        return info;
    }
    else
    {
        return nil;
    }
}

@end
