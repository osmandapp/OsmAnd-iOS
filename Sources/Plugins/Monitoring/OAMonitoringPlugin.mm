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
#import "OAIAPHelper.h"
#import "OARoutingHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAMapViewController.h"
#import "OAOsmAndFormatter.h"
#import "OAAlertBottomSheetViewController.h"
#import "OARecordSettingsBottomSheetViewController.h"
#import "OARootViewController.h"
#import "OATripRecordingDistanceWidget.h"
#import "OATripRecordingTimeWidget.h"
#import "OATripRecordingElevationWidget.h"
#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_TrackRecording

#define TRIP_RECORDING_DISTANCE @"monitoring"
#define TRIP_RECORDING_TIME @"trip_recording_time"
#define TRIP_RECORDING_UPHILL @"trip_recording_uphill"
#define TRIP_RECORDING_DOWNHILL @"trip_recording_downhill"

@interface OAMonitoringPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OALiveMonitoringHelper *liveMonitoringHelper;
@property (nonatomic) OASavingTrackHelper *savingTrackHelper;

@end

@implementation OAMonitoringPlugin

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _liveMonitoringHelper = [[OALiveMonitoringHelper alloc] init];
        _savingTrackHelper = [OASavingTrackHelper sharedInstance];
        [self registerWidgetsVisibility];
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
    
    if ([_savingTrackHelper hasDataToSave])
        [_savingTrackHelper saveDataToGpx];
    
    [[self getMapViewController] hideRecGpxTrack];
}

- (void) registerLayers
{
}

- (void) registerWidgetsVisibility
{
    for (OAWidgetType *widget in OAWidgetGroup.tripRecording.getWidgets)
    {
        NSArray<OAApplicationMode *> *appModes = widget == OAWidgetType.tripRecordingDistance ? nil : @[];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:widget appModes:appModes];
    }
}

- (NSArray<NSString *> *) getWidgetIds
{
    return @[OAWidgetType.tripRecordingDistance.id, OAWidgetType.tripRecordingTime.id, OAWidgetType.tripRecordingUphill.id, OAWidgetType.tripRecordingDownhill.id];
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];

    OABaseWidgetView *distanceWidget = [self createMapWidgetForParams:OAWidgetType.tripRecordingDistance appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:distanceWidget]];

    OABaseWidgetView *timeWidget = [self createMapWidgetForParams:OAWidgetType.tripRecordingTime appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:timeWidget]];

    OABaseWidgetView *uphillWidget = [self createMapWidgetForParams:OAWidgetType.tripRecordingUphill appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:uphillWidget]];

    OABaseWidgetView *downhillWidget = [self createMapWidgetForParams:OAWidgetType.tripRecordingDownhill appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:downhillWidget]];
}

- (nullable OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode
{
    if (widgetType == OAWidgetType.tripRecordingDistance) {
        return [[OATripRecordingDistanceWidget alloc] initWithPlugin:self customId:@"" appMode:appMode];
    } else if (widgetType == OAWidgetType.tripRecordingTime) {
        return [[OATripRecordingTimeWidget alloc] initWithСustomId:@"" appMode:appMode];
    } else if (widgetType == OAWidgetType.tripRecordingUphill) {
        return [[OATripRecordingUphillWidget alloc] initWithСustomId:@"" appMode:appMode];
    } else if (widgetType == OAWidgetType.tripRecordingDownhill) {
        return [[OATripRecordingDownhillWidget alloc] initWithСustomId:@"" appMode:appMode];
    }
    return nil;
}

- (void) updateLayers
{
    
}

- (void) showTripRecordingDialog:(BOOL)showTrackSelection
{
    BOOL recOn = _settings.mapSettingTrackRecording;
    if (recOn)
    {
        [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_recording")
                                                   titleIcon:@"ic_custom_route"
                                                 cancelTitle:OALocalizedString(@"shared_string_cancel")
                                       selectableItemsTitles:@[ OALocalizedString(@"track_stop_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"gpx_start_new_segment"), OALocalizedString(@"save_current_track") ]
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
                        [_savingTrackHelper startNewSegment];
                        break;
                    }
                    case 3:
                    {
                        if ([_savingTrackHelper hasDataToSave] && _savingTrackHelper.distance < 10.0)
                        {
                            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                                                       titleIcon:@"ic_custom_route"
                                                                         message:nil
                                                                     cancelTitle:OALocalizedString(@"shared_string_no")
                                                                       doneTitle:OALocalizedString(@"shared_string_yes")
                                                                doneColpletition:^{
                                
                                    _settings.mapSettingTrackRecording = NO;
                                    [self saveTrack:YES];
//                                    [_distanceWidget updateInfo];
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
//                [_distanceWidget updateInfo];
        }];
    }
    else
    {
        if ([_savingTrackHelper hasData])
        {
            [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"track_recording")
                                                       titleIcon:@"ic_custom_route"
                                                     cancelTitle:nil
                                           selectableItemsTitles:@[OALocalizedString(@"track_continue_rec"), OALocalizedString(@"show_info"), OALocalizedString(@"track_clear"), OALocalizedString(@"save_current_track")]
                                           selectableItemsImages:@[@"ic_action_rec_start.png", @"icon_info.png", @"track_clear_data.png", @"track_save.png"]
                                              selectColpletition:^(NSInteger selectedIndex) {
                
                switch (selectedIndex) {
                    case 0:
                    {
                        [_savingTrackHelper startNewSegment];
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
                            [_savingTrackHelper clearData];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self getMapViewController] hideContextPinMarker];
                                [[self getMapViewController] hideRecGpxTrack];
//                                [_distanceWidget updateInfo];
                            });
                        }];
                        break;
                    }
                    case 3:
                    {
                        if ([_savingTrackHelper hasDataToSave] && _savingTrackHelper.distance < 10.0)
                        {
                            [OAAlertBottomSheetViewController showAlertWithTitle:nil
                                                                       titleIcon:nil
                                                                         message:OALocalizedString(@"track_save_short_q")
                                                                     cancelTitle:OALocalizedString(@"shared_string_no")
                                                                       doneTitle:OALocalizedString(@"shared_string_yes")
                                                                doneColpletition:^{
                                [self saveTrack:NO];
//                                [_distanceWidget updateInfo];
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
//                [_distanceWidget updateInfo];
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
//                    [_distanceWidget updateInfo];
                }];
                
                [bottomSheet presentInViewController:OARootViewController.instance];
            }
            else
            {
                _settings.mapSettingTrackRecording = YES;
            }
//            [_distanceWidget updateInfo];
        }
    }
}

- (void) saveTrack:(BOOL)askForRec
{
    _saving = YES;
    if ([_savingTrackHelper hasDataToSave])
    {
        [_savingTrackHelper saveDataToGpxWithCompletionHandler:^{
            _saving = NO;
        }];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getMapViewController] hideRecGpxTrack];
        [[self getMapViewController] hideContextPinMarker];
//        [_distanceWidget updateInfo];
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

- (NSString *) getName
{
    return OALocalizedString(@"record_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"record_plugin_description");
}

- (BOOL) isLiveMonitoringEnabled
{
    return [_liveMonitoringHelper isLiveMonitoringEnabled];
}

@end
