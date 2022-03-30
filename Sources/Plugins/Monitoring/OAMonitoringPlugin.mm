//
//  OAMonitoringPlugin.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMonitoringPlugin.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OALiveMonitoringHelper.h"
#import "OAIAPHelper.h"
#import "OARoutingHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAUtilities.h"
#import "OAMapViewController.h"
#import "OAOsmAndFormatter.h"
#import "OAAlertBottomSheetViewController.h"
#import "OARecordSettingsBottomSheetViewController.h"
#import "OARootViewController.h"

#define PLUGIN_ID kInAppId_Addon_TrackRecording

@interface OAMonitoringPlugin ()

@property (nonatomic) BOOL saving;
@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OALiveMonitoringHelper *liveMonitoringHelper;
@property (nonatomic) OASavingTrackHelper *recHelper;

@end

@implementation OAMonitoringPlugin
{
    OATextInfoWidget *_monitoringControl;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _liveMonitoringHelper = [[OALiveMonitoringHelper alloc] init];
        _recHelper = [OASavingTrackHelper sharedInstance];
        NSArray<OAApplicationMode *> *am = [OAApplicationMode allPossibleValues];
        [OAApplicationMode regWidgetVisibility:PLUGIN_ID am:am];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void) updateLocation:(CLLocation *)location
{
    [_liveMonitoringHelper updateLocation:location];
}

- (void) disable
{
    _settings.mapSettingTrackRecording = NO;
    
    if ([_recHelper hasDataToSave])
        [_recHelper saveDataToGpx];
    
    [[self getMapViewController] hideRecGpxTrack];
}

- (void) registerLayers
{
    [self registerWidget];
}

- (void) registerWidget
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        _monitoringControl = [self createMonitoringControl];
        
        [mapInfoController registerSideWidget:_monitoringControl imageId:@"ic_action_play_dark" message:[self getName] key:PLUGIN_ID left:NO priorityOrder:30];
        [mapInfoController recreateControls];
    }
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isEnabled])
        {
            if (!_monitoringControl)
                [self registerWidget];
        }
        else
        {
            if (_monitoringControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_monitoringControl];
                [mapInfoController recreateControls];
                _monitoringControl = nil;
            }
        }
    });
}

- (OATextInfoWidget *) createMonitoringControl
{
    _monitoringControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *monitoringControlWeak = _monitoringControl;
    __weak OAMonitoringPlugin *pluginWeak = self;
    
    long __block lastUpdateTime;
    _monitoringControl.updateInfoFunction = ^BOOL {
        
        if (pluginWeak.saving)
        {
            [monitoringControlWeak setText:OALocalizedString(@"shared_string_save") subtext:@""];
            [monitoringControlWeak setIcons:@"widget_monitoring_rec_big_day" widgetNightIcon:@"widget_monitoring_rec_big_night"];
            return YES;
        }
        NSString *txt = OALocalizedString(@"monitoring_control_start");
        NSString *subtxt = nil;
        NSString *dn;
        NSString *d;
        long last = lastUpdateTime;
        BOOL globalRecord = [OAAppSettings sharedManager].mapSettingTrackRecording;
        BOOL isRecording = pluginWeak.recHelper.getIsRecording;
        float dist = pluginWeak.recHelper.distance;
        
        //make sure widget always shows recorded track distance if unsaved track exists
        if (dist > 0)
        {
            last = pluginWeak.recHelper.lastTimeUpdated;
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
        
        [monitoringControlWeak setText:txt subtext:subtxt];
        [monitoringControlWeak setIcons:d widgetNightIcon:dn];
        if ((last != lastUpdateTime) && (globalRecord || isRecording))
        {
            lastUpdateTime = last;
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
            [monitoringControlWeak setIcons:d widgetNightIcon:dn];
            
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
                [monitoringControlWeak setIcons:d widgetNightIcon:dn];
            });
        }
        return YES;
    };
    
    [_monitoringControl updateInfo];
    
    _monitoringControl.onClickFunction = ^(id sender) {
        [pluginWeak controlDialog:true];
    };

    return _monitoringControl;
}

- (void) controlDialog:(BOOL)showTrackSelection
{
    BOOL recOn = _settings.mapSettingTrackRecording;
    if (recOn)
    {
        [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_recording")
                                                   titleIcon:@"ic_custom_route"
                                                 cancelTitle:OALocalizedString(@"shared_string_cancel")
                                       selectableItemsTitles:@[ OALocalizedString(@"track_stop_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"track_new_segment"), OALocalizedString(@"track_save") ]
                                       selectableItemsImages:@[@"track_recording_stop.png", @"icon_info.png", @"track_new_segement.png" , @"track_save.png"]
                                          selectColpletition:^(NSInteger selectedIndex) {
            
                switch (selectedIndex)
                {
                    case 0:
                    {
                        _settings.mapSettingTrackRecording = NO;
                        break;
                    }
                    case 1:
                    {
                        [[self getMapPanelViewController] openTargetViewWithGPX:nil];
                        break;
                    }
                    case 2:
                    {
                        [_recHelper startNewSegment];
                        break;
                    }
                    case 3:
                    {
                        if ([_recHelper hasDataToSave] && _recHelper.distance < 10.0)
                        {
                            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                                                       titleIcon:@"ic_custom_route"
                                                                         message:nil
                                                                     cancelTitle:OALocalizedString(@"shared_string_no")
                                                                       doneTitle:OALocalizedString(@"shared_string_yes")
                                                                doneColpletition:^{
                                
                                    _settings.mapSettingTrackRecording = NO;
                                    [self saveTrack:YES];
                                    [_monitoringControl updateInfo];
                            }];
                        }
                        else
                        {
                            _settings.mapSettingTrackRecording = NO;
                            [self saveTrack:YES];
                        }
                        break;
                    }
                    default:
                        break;
                }
                [_monitoringControl updateInfo];
        }];
    }
    else
    {
        if ([_recHelper hasData])
        {
            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_recording")
                                                       titleIcon:@"ic_custom_route"
                                                     cancelTitle:nil
                                           selectableItemsTitles:@[OALocalizedString(@"track_continue_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"track_clear"), OALocalizedString(@"track_save")]
                                           selectableItemsImages:@[@"ic_action_rec_start.png", @"icon_info.png", @"track_clear_data.png", @"track_save.png"]
                                              selectColpletition:^(NSInteger selectedIndex) {
                
                switch (selectedIndex) {
                    case 0:
                    {
                        [_recHelper startNewSegment];
                        _settings.mapSettingTrackRecording = YES;
                        break;
                    }
                    case 1:
                    {
                        [[self getMapPanelViewController] openTargetViewWithGPX:nil];
                        break;
                    }
                    case 2:
                    {
                        [OAAlertBottomSheetViewController showAlertWithTitle:nil
                                                                   titleIcon:nil
                                                                     message:OALocalizedString(@"track_clear_q")
                                                                 cancelTitle:OALocalizedString(@"shared_string_no")
                                                                   doneTitle:OALocalizedString(@"shared_string_yes")
                                                            doneColpletition:^{
                            [_recHelper clearData];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self getMapViewController] hideContextPinMarker];
                                [[self getMapViewController] hideRecGpxTrack];
                                [_monitoringControl updateInfo];
                            });
                        }];
                        break;
                    }
                    case 3:
                    {
                        if ([_recHelper hasDataToSave] && _recHelper.distance < 10.0)
                        {
                            [OAAlertBottomSheetViewController showAlertWithTitle:nil
                                                                       titleIcon:nil
                                                                         message:OALocalizedString(@"track_save_short_q")
                                                                     cancelTitle:OALocalizedString(@"shared_string_no")
                                                                       doneTitle:OALocalizedString(@"shared_string_yes")
                                                                doneColpletition:^{
                                [self saveTrack:NO];
                                [_monitoringControl updateInfo];
                            }];
                        }
                        else
                        {
                            [self saveTrack:NO];
                        }
                        break;
                    }
                        
                    default:
                        break;
                }
                [_monitoringControl updateInfo];
            }];
        }
        else
        {
            if (![_settings.mapSettingSaveTrackIntervalApproved get])
            {
                OARecordSettingsBottomSheetViewController *bottomSheet = [[OARecordSettingsBottomSheetViewController alloc] initWithCompletitionBlock:^(int recordingInterval, BOOL rememberChoice, BOOL showOnMap) {
                    
                    [_settings.mapSettingSaveTrackIntervalGlobal set:[_settings.trackIntervalArray[recordingInterval] intValue]];
                    if (rememberChoice)
                        [_settings.mapSettingSaveTrackIntervalApproved set:YES];

                    [_settings.mapSettingShowRecordingTrack set:showOnMap];
                    _settings.mapSettingTrackRecording = YES;
                    [_monitoringControl updateInfo];
                }];
                
                [bottomSheet presentInViewController:OARootViewController.instance];
            }
            else
            {
                _settings.mapSettingTrackRecording = YES;
            }
            [_monitoringControl updateInfo];
        }
    }
}

- (void) saveTrack:(BOOL)askForRec
{
    if ([_recHelper hasDataToSave])
        [_recHelper saveDataToGpx];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getMapViewController] hideRecGpxTrack];
        [[self getMapViewController] hideContextPinMarker];
        [_monitoringControl updateInfo];
    });
    
    OAMapPanelViewController *mapPanelViewController = [self getMapPanelViewController];
    if (mapPanelViewController.activeTargetActive && [mapPanelViewController hasGpxActiveTargetType] && !mapPanelViewController.activeTargetObj)
        [mapPanelViewController targetHideMenu:.3 backButtonClicked:NO onComplete:nil];
    
    if (askForRec)
    {
        [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_continue_rec_q")
                                                   titleIcon:@"ic_custom_route"
                                                     message:nil
                                                 cancelTitle:OALocalizedString(@"shared_string_no")
                                                   doneTitle:OALocalizedString(@"shared_string_yes")
                                            doneColpletition:^{
            _settings.mapSettingTrackRecording = YES;
        }];
    }
}

@end
