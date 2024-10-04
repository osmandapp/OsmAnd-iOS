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
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAOsmAndFormatter.h"

@implementation OATripRecordingElevationWidget
{
    int _currentTrackIndex;
}

- (instancetype) initWithType:(OAWidgetType *)type
{
    self = [super initWithType:type];
    if (self)
    {
        __weak OATripRecordingElevationWidget *weakSelf = self;
        double __block cachedElevationDiff = -1;
        
        self.updateInfoFunction = ^BOOL {
            int currentTrackIndex = OASavingTrackHelper.sharedInstance.currentTrackIndex;
            double elevationDiff = [((OATripRecordingElevationWidget *)weakSelf) getElevationDiff:_currentTrackIndex != currentTrackIndex];
            _currentTrackIndex = currentTrackIndex;
            if (cachedElevationDiff != elevationDiff)
            {
                cachedElevationDiff = elevationDiff;
                EOAMetricsConstant metricsConstants = [[OAAppSettings sharedManager].metricSystem get];
                NSMutableArray *valueUnitArray = [NSMutableArray array];
                [OAOsmAndFormatter getFormattedAlt:elevationDiff mc:metricsConstants valueUnitArray:valueUnitArray];
                NSDictionary<NSString *, NSString *> *result = [weakSelf getValueAndUnitWithArray:valueUnitArray];
                if (result) {
                    [weakSelf setText:result[@"value"] subtext:result[@"unit"]];
                }
            }
            return YES;
        };
        
        self.onClickFunction = ^(id sender) {
            // FIXME:
            OASGpxTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysisFileTimestamp:0];
            if (analysis.hasElevationData)
            {
                OASGpxFile *gpxFile = [[OASavingTrackHelper sharedInstance] currentTrack];
                // FIXME:
//                [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpxFile selectedTab:EOATrackMenuHudSegmentsTab selectedStatisticsTab:EOATrackMenuHudSegmentsStatisticsAltitudeTab openedFromMap:YES];
            }
        };
        [self updateInfo];
    }
    return self;
}

- (nullable NSDictionary<NSString *, NSString *> *)getValueAndUnitWithArray:(NSMutableArray *)valueUnitArray
{
    if (valueUnitArray.count == 2)
    {
        NSString *value = [valueUnitArray objectAtIndex:0];
        NSString *unit = [valueUnitArray objectAtIndex:1];
        
        if ([value isKindOfClass:[NSString class]] && [unit isKindOfClass:[NSString class]])
        {
            return @{@"value": value, @"unit": unit};
        }
    }
    
    return nil;
}

//Override
- (double) getElevationDiff:(BOOL)reset
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
{
    double _diffElevationUp;
}

- (instancetype)initWithСustomId:(NSString *)customId
                                  appMode:(OAApplicationMode *)appMode
                             widgetParams:(NSDictionary *)widgetParams;

{
    self = [super initWithType:OAWidgetType.tripRecordingUphill];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _diffElevationUp = 0.0;
        [self setIcon:@"widget_track_recording_uphill"];
    }
    return self;
}

- (double) getElevationDiff:(BOOL)reset
{
    if (reset)
        _diffElevationUp = 0.0;
// FIXME:
//    OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
//    _diffElevationUp = MAX(analysis.diffElevationUp, _diffElevationUp);
    
    return _diffElevationUp;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_uphill")];
}

@end


@implementation OATripRecordingDownhillWidget
{
    double _diffElevationDown;
}

- (instancetype)initWithСustomId:(NSString *)customId
                                  appMode:(OAApplicationMode *)appMode
                             widgetParams:(NSDictionary *)widgetParams;
{
    self = [super initWithType:OAWidgetType.tripRecordingDownhill];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _diffElevationDown = 0.0;
        [self setIcon:@"widget_track_recording_downhill"];
    }
    return self;
}

- (double) getElevationDiff:(BOOL)reset
{
    if (reset)
        _diffElevationDown = 0.0;
// FIXME:
//    OAGPXTrackAnalysis *analysis = [[[OASavingTrackHelper sharedInstance] currentTrack] getAnalysis:0];
//    _diffElevationDown = MAX(analysis.diffElevationDown, _diffElevationDown);
    return _diffElevationDown;
}

+ (NSString *) getName
{
    return [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"record_plugin_name"), OALocalizedString(@"map_widget_trip_recording_downhill")];
}

@end
