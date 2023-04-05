//
//  OATripRecordingDistanceWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 30.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATripRecordingDistanceWidget.h"
#import "OASavingTrackHelper.h"
#import "OAMonitoringPlugin.h"
#import "OAOsmAndFormatter.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

@implementation OATripRecordingDistanceWidget

- (instancetype) initWithPlugin:(OAMonitoringPlugin *)plugin
{
    self = (OATripRecordingDistanceWidget *)[[OATextInfoWidget alloc] init];
    
    if (self)
    {
        __weak OATextInfoWidget *distanceWidgetWeak = self;
        __weak OAMonitoringPlugin *pluginWeak = plugin;
        long __block cachedLastUpdateTime;
        
        self.updateInfoFunction = ^BOOL {
            if (pluginWeak.saving)
            {
                [distanceWidgetWeak setText:OALocalizedString(@"shared_string_save") subtext:@""];
                [distanceWidgetWeak setIcons:@"widget_monitoring_rec_big_day" widgetNightIcon:@"widget_monitoring_rec_big_night"];
                return YES;
            }
            NSString *txt = OALocalizedString(@"monitoring_control_start");
            NSString *subtxt = nil;
            NSString *dn;
            NSString *d;
            long last = cachedLastUpdateTime;
            BOOL globalRecord = [OAAppSettings sharedManager].mapSettingTrackRecording;
            BOOL isRecording = [OASavingTrackHelper sharedInstance].getIsRecording;
            float dist = [OASavingTrackHelper sharedInstance].distance;
            
            //make sure widget always shows recorded track distance if unsaved track exists
            if (dist > 0)
            {
                last = [OASavingTrackHelper sharedInstance].lastTimeUpdated;
                NSString *ds = [OAOsmAndFormatter getFormattedDistance:dist];
                int ls = [ds indexOf:@" "];
                if (ls == -1)
                {
                    txt = ds;
                }
                else
                {
                    txt = [ds substringToIndex:ls];
                    subtxt = [ds substringFromIndex:ls + 1];
                }
            }
            
            BOOL liveMonitoringEnabled = [pluginWeak.liveMonitoringHelper isLiveMonitoringEnabled];
            if (globalRecord)
            {
                //indicates global recording (+background recording)
                if (liveMonitoringEnabled)
                {
                    dn = @"widget_live_monitoring_rec_big_night";
                    d = @"widget_live_monitoring_rec_big_day";
                }
                else
                {
                    dn = @"widget_monitoring_rec_big_night";
                    d = @"widget_monitoring_rec_big_day";
                }
            }
            else if (isRecording)
            {
                //indicates (profile-based, configured in settings) recording (looks like is only active during nav in follow mode)
                if (liveMonitoringEnabled)
                {
                    dn = @"widget_live_monitoring_rec_small_night";
                    d = @"widget_live_monitoring_rec_small_day";
                }
                else
                {
                    dn = @"widget_monitoring_rec_small_night";
                    d = @"widget_monitoring_rec_small_day";
                }
            }
            else
            {
                dn = @"widget_monitoring_rec_inactive_night";
                d = @"widget_monitoring_rec_inactive_day";
            }
            
            [distanceWidgetWeak setText:txt subtext:subtxt];
            [distanceWidgetWeak setIcons:d widgetNightIcon:dn];
            if ((last != cachedLastUpdateTime) && (globalRecord || isRecording))
            {
                cachedLastUpdateTime = last;
                //blink implementation with 2 indicator states (global logging + profile/navigation logging)
                if (liveMonitoringEnabled)
                {
                    dn = @"widget_live_monitoring_rec_small_night";
                    d = @"widget_live_monitoring_rec_small_day";
                }
                else
                {
                    dn = @"widget_monitoring_rec_small_night";
                    d = @"widget_monitoring_rec_small_day";
                }
                [distanceWidgetWeak setIcons:d widgetNightIcon:dn];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSString *dn;
                    NSString *d;
                    if (globalRecord)
                    {
                        if (liveMonitoringEnabled)
                        {
                            dn = @"widget_live_monitoring_rec_big_night";
                            d = @"widget_live_monitoring_rec_big_day";
                        } else
                        {
                            dn = @"widget_monitoring_rec_big_night";
                            d = @"widget_monitoring_rec_big_day";
                        }
                    }
                    else
                    {
                        if (liveMonitoringEnabled)
                        {
                            dn = @"widget_live_monitoring_rec_small_night";
                            d = @"widget_live_monitoring_rec_small_day";
                        }
                        else
                        {
                            dn = @"widget_monitoring_rec_small_night";
                            d = @"widget_monitoring_rec_small_day";
                        }
                    }
                    [distanceWidgetWeak setIcons:d widgetNightIcon:dn];
                });
            }
            return YES;
        };
        
        [self updateInfo];
        
        self.onClickFunction = ^(id sender) {
            [pluginWeak controlDialog:true];
        };
    }
    return self;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_distance")];
}

@end
