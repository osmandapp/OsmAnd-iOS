//
//  OAAlarmWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAlarmWidget.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OALocationServices.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OAWaypointHelper.h"
#import "OAAlarmInfo.h"
#import "OACurrentPositionHelper.h"
#import "OAOsmAndFormatter.h"

#include <CommonCollections.h>
#include <binaryRead.h>

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
    NSString *_textString;
    NSString *_bottomTextString;
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
    BOOL trafficWarnings = [_settings.showTrafficWarnings get];
    BOOL cams = [_settings.showCameras get];
    BOOL peds = [_settings.showPedestrian get];
    BOOL tunnels = [_settings.showTunnels get];
    BOOL visible = false;
    if (([_rh isFollowingMode] || [_trackingUtilities isMapLinkedToLocation]) && (trafficWarnings || cams))
    {
        OAAlarmInfo *alarm;
        if([_rh isFollowingMode] && ![OARoutingHelper isDeviatedFromRoute] && ![_rh getCurrentGPXRoute])
        {
            alarm = [_wh getMostImportantAlarm:[_settings.speedSystem get] showCameras:cams];
        }
        else
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            const auto ro = [_currentPositionHelper getLastKnownRouteSegment:loc];
            if (loc && ro)
            {
                alarm = [_wh calculateMostImportantAlarm:ro loc:loc mc:[_settings.metricSystem get] sc:[_settings.speedSystem get] showCameras:cams];
            }
        }
        if (alarm)
        {
            BOOL americanSigns = [OADrivingRegion isAmericanSigns:[_settings.drivingRegion get]];

            NSString  *locImgId = @"warnings_limit";
            NSString *text = @"";
            NSString *bottomText = @"";
            if (alarm.type == AIT_SPEED_LIMIT)
            {
                if (americanSigns)
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
                if (americanSigns)
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
                if (americanSigns)
                    locImgId = @"warnings_traffic_calming_us";
                else
                    locImgId = @"warnings_traffic_calming";
            }
            else if (alarm.type == AIT_STOP)
            {
                locImgId = @"warnings_stop";
            }
            else if(alarm.type == AIT_RAILWAY)
            {
                if (americanSigns)
                    locImgId = @"warnings_railways_us";
                else
                    locImgId = @"warnings_railways";
            }
            else if (alarm.type == AIT_PEDESTRIAN)
            {
                if (americanSigns)
                    locImgId = @"warnings_pedestrian_us";
                else
                    locImgId = @"warnings_pedestrian";
            }
            else if (alarm.type == AIT_TUNNEL)
            {
                if (americanSigns)
                    locImgId = @"warnings_tunnel_us";
                else
                    locImgId = @"warnings_tunnel";

                bottomText = [OAOsmAndFormatter.instance getFormattedAlarmInfoDistance:alarm.floatValue];
            }
            else
            {
                text = nil;
                bottomText = nil;
            }
            visible = (text &&  text.length > 0) || (locImgId.length > 0);
            if (visible)
            {
                if (alarm.type == AIT_SPEED_CAMERA)
                    visible = cams;
                else if (alarm.type == AIT_PEDESTRIAN)
                    visible = peds;
                else if (alarm.type == AIT_TUNNEL)
                    visible = tunnels;
                else
                    visible = trafficWarnings;
            }
            if (visible)
            {
                if (![locImgId isEqualToString:_imgId])
                {
                    _imgId = locImgId;
                    [_imageView setImage:[UIImage imageNamed:locImgId]];
                }
                if (![self stringEquals:text b:_textString])
                {
                    _textString = text;
                    _textView.text = _textString;
                    CGRect f = _textView.frame;
                    f.origin.y = alarm.type == AIT_SPEED_LIMIT && americanSigns ? 10 : 0;
                    _textView.frame = f;
                }
                if (![bottomText isEqualToString:_bottomTextString])
                {
                    _bottomTextString = bottomText;
                    _bottomTextView.text = _bottomTextString;
                    _bottomTextView.textColor = americanSigns ? UIColor.blackColor : UIColor.whiteColor;
                }
            }
        }
    }
    [self updateVisibility:visible];
    return true;
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

@end
