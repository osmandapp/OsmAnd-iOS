//
//  OATripRecordingUphillWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 04.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATripRecordingUphillWidget.h"
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

@implementation OATripRecordingUphillWidget

- (instancetype) init
{
    self = (OATripRecordingUphillWidget *)[[OATextInfoWidget alloc] init];
    
    if (self)
    {
        __weak OATripRecordingUphillWidget *weakSelf = self;
        long __block cachedElevationDiff = -1;
        
        self.updateInfoFunction = ^BOOL {
            [weakSelf setIcons:@"widget_track_recording_uphill_day" widgetNightIcon:@"widget_track_recording_uphill_night"];
            OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
            double elevationDiff = analysis.diffElevationUp;
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

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_uphill")];
}

@end
