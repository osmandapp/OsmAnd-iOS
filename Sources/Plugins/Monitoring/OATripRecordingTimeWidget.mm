//
//  OATripRecordingTimeWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 02.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


#import "OATripRecordingTimeWidget.h"
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

@implementation OATripRecordingTimeWidget

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        __weak OATextInfoWidget *weakSelf = self;
        long __block cachedTimeSpan = -1;
        
        self.updateInfoFunction = ^BOOL {

            [weakSelf setIcons:@"widget_track_recording_duration_day" widgetNightIcon:@"widget_track_recording_duration_night"];
            
            OAGPXMutableDocument *currentTrack = [[OASavingTrackHelper sharedInstance] currentTrack];
            OAGPX *gpxFile = [[OASavingTrackHelper sharedInstance] getCurrentGPX];

            BOOL withoutGaps = !gpxFile.joinSegments &&
            ( (!currentTrack.tracks || currentTrack.tracks.count == 0) || currentTrack.tracks[0].generalTrack);

            OAGPXTrackAnalysis *analysis = [currentTrack getAnalysis:0];
            long timeSpan =  withoutGaps ? analysis.timeSpanWithoutGaps : analysis.timeSpan;
            
            if (cachedTimeSpan != timeSpan)
            {
                cachedTimeSpan = timeSpan;
                NSString *formattedTime = [OAOsmAndFormatter getFormattedDuration:timeSpan fullForm:NO];
                [weakSelf setText:formattedTime subtext:nil];
            }
            return YES;
        };
        
        self.onClickFunction = ^(id sender) {
            if (cachedTimeSpan > 0)
            {
                OAGPX *gpxFile = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpxFile selectedTab:EOATrackMenuHudSegmentsTab selectedStatisticsTab:EOATrackMenuHudSegmentsStatisticsOverviewTab openedFromMap:YES];
            }
        };
        
        [self updateInfo];
    }
    return self;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_duration")];
}

@end
