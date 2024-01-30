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
#import "OsmAnd_Maps-Swift.h"

@implementation OATripRecordingDistanceWidget

- (instancetype)initWithPlugin:(OAMonitoringPlugin *)plugin
                               customId:(NSString *)customId
                                appMode:(OAApplicationMode *)appMode
                           widgetParams:(NSDictionary *)widgetParams;
{
    self = [super initWithType:OAWidgetType.tripRecordingDistance];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        __weak OATextInfoWidget *distanceWidgetWeak = self;
        __weak OAMonitoringPlugin *pluginWeak = plugin;
        long __block cachedLastUpdateTime;
        
        self.updateInfoFunction = ^BOOL {
            if (pluginWeak.saving)
            {
                [distanceWidgetWeak setText:OALocalizedString(@"shared_string_save") subtext:@""];
                [distanceWidgetWeak setIcon:@"widget_monitoring_rec_big"];
                return YES;
            }
            NSString *txt = OALocalizedString(@"monitoring_control_start");
            NSString *subtxt = nil;
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
            
            BOOL liveMonitoringEnabled = [pluginWeak isLiveMonitoringEnabled];
            if (globalRecord)
            {
                //indicates global recording (+background recording)
                if (liveMonitoringEnabled)
                {
                    d = @"widget_live_monitoring_rec_big";
                }
                else
                {
                    d = @"widget_monitoring_rec_big";
                }
            }
            else if (isRecording)
            {
                //indicates (profile-based, configured in settings) recording (looks like is only active during nav in follow mode)
                if (liveMonitoringEnabled)
                {
                    d = @"widget_live_monitoring_rec_small";
                }
                else
                {
                    d = @"widget_monitoring_rec_small";
                }
            }
            else
            {
                d = @"widget_monitoring_rec_inactive";
            }
            
            [distanceWidgetWeak setText:txt subtext:subtxt];
            [distanceWidgetWeak setIcon:d];
            if ((last != cachedLastUpdateTime) && (globalRecord || isRecording))
            {
                cachedLastUpdateTime = last;
                //blink implementation with 2 indicator states (global logging + profile/navigation logging)
                if (liveMonitoringEnabled)
                {
                    d = @"widget_live_monitoring_rec_small";
                }
                else
                {
                    d = @"widget_monitoring_rec_small";
                }
                [distanceWidgetWeak setIcon:d];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSString *dn;
                    NSString *d;
                    if (globalRecord)
                    {
                        if (liveMonitoringEnabled)
                        {
                            d = @"widget_live_monitoring_rec_big";
                        } else
                        {
                            d = @"widget_monitoring_rec_big";
                        }
                    }
                    else
                    {
                        if (liveMonitoringEnabled)
                        {
                            d = @"widget_live_monitoring_rec_small";
                        }
                        else
                        {
                            d = @"widget_monitoring_rec_small";
                        }
                    }
                    [distanceWidgetWeak setIcon:d];
                });
            }
            return YES;
        };
        
        [self updateInfo];
        
        self.onClickFunction = ^(id sender) {
            [pluginWeak showTripRecordingDialog:true];
        };
    }
    return self;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_distance")];
}

@end
