//
//  OATripRecordingElevationWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 04.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATripRecordingElevationWidget.h"
#import "OASavingTrackHelper.h"
#import "OAOsmAndFormatter.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAGPXDatabase.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OARootViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OATripRecordingElevationWidget

- (instancetype) initWithType:(OAWidgetType *)type
{
    self = [super initWithType:type];
    if (self)
    {
        __weak OATextInfoWidget *weakSelf = self;
        double __block cachedElevationDiff = -1;
        
        self.updateInfoFunction = ^BOOL {
            double elevationDiff = [((OATripRecordingElevationWidget *)weakSelf) getElevationDiff];
            
            if (cachedElevationDiff != elevationDiff)
            {
                cachedElevationDiff = elevationDiff;
                EOAMetricsConstant metricsConstants = [[OAAppSettings sharedManager].metricSystem get];
                NSString *formattedUphill = [OAOsmAndFormatter getFormattedAlt:elevationDiff mc:metricsConstants];
                [weakSelf setText:formattedUphill subtext:nil];
            }
            return YES;
        };
        
        self.onClickFunction = ^(id sender) {
            OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
            if (analysis.hasElevationData)
            {
                OAGPX *gpxFile = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpxFile selectedTab:EOATrackMenuHudSegmentsTab selectedStatisticsTab:EOATrackMenuHudSegmentsStatisticsAlititudeTab openedFromMap:YES];
            }
        };
        
        [self updateInfo];
    }
    return self;
}

//Override
- (double) getElevationDiff
{
    return -1;
}

//Override
+ (NSString *) getName
{
    return @"";
}

@end


@implementation OATripRecordingUphillWidget

- (instancetype) init
{
    self = [super initWithType:OAWidgetType.tripRecordingUphill];
    if (self)
    {
        [self setIcons:@"widget_track_recording_uphill_day" widgetNightIcon:@"widget_track_recording_uphill_night"];
    }
    return self;
}

- (double) getElevationDiff
{
    OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
    return analysis.diffElevationUp;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_uphill")];
}

@end


@implementation OATripRecordingDownhillWidget

- (instancetype) init
{
    self = [super initWithType:OAWidgetType.tripRecordingDownhill];
    if (self)
    {
        [self setIcons:@"widget_track_recording_downhill_day" widgetNightIcon:@"widget_track_recording_downhill_night"];
    }
    return self;
}

- (double) getElevationDiff
{
    OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
    return analysis.diffElevationDown;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_downhill")];
}

@end
