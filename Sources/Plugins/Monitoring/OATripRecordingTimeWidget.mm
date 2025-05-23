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
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OATripRecordingTimeWidget

- (instancetype)initWithСustomId:(NSString *)customId
                                  appMode:(OAApplicationMode *)appMode
                             widgetParams:(NSDictionary * _Nullable)widgetParams;
{
    self = [super initWithType:OAWidgetType.tripRecordingTime];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        __weak OATextInfoWidget *weakSelf = self;
        long __block cachedTimeSpan = -1;
        
        self.updateInfoFunction = ^BOOL {

            [weakSelf setIcon:@"widget_track_recording_duration"];
            OASGpxFile *currentTrack = [OASavingTrackHelper sharedInstance].currentTrack;
            BOOL withoutGaps = ![[OAAppSettings sharedManager].currentTrackIsJoinSegments get] &&
            ((!currentTrack.tracks || currentTrack.tracks.count == 0) || currentTrack.tracks[0].generalTrack);

            OASGpxTrackAnalysis *analysis = [currentTrack getAnalysisFileTimestamp:0];
            long timeSpan =  withoutGaps ? analysis.timeSpanWithoutGaps : analysis.timeSpan;
            
            if (cachedTimeSpan != timeSpan)
            {
                cachedTimeSpan = timeSpan;
                NSString *formattedTime = [OAOsmAndFormatter getFormattedDurationShort:timeSpan / 1000 fullForm:NO];
                [weakSelf setText:formattedTime subtext:nil];
            }
            return YES;
        };
        
        self.onClickFunction = ^(id sender) {
            if (cachedTimeSpan > 0)
            {
                OASGpxFile *gpxFile = [OASavingTrackHelper sharedInstance].currentTrack;
                OASTrackItem *trackItem = [[OASTrackItem alloc] initWithGpxFile:gpxFile];
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem selectedTab:EOATrackMenuHudSegmentsTab selectedStatisticsTab:EOATrackMenuHudSegmentsStatisticsOverviewTab openedFromMap:YES];
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
