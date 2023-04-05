//
//  OAMonitoringPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"
#import "OALiveMonitoringHelper.h"
#import "OASavingTrackHelper.h"

#define TRIP_RECORDING_DISTANCE @"monitoring"
#define TRIP_RECORDING_TIME @"trip_recording_time"
#define TRIP_RECORDING_UPHILL @"trip_recording_uphill"
#define TRIP_RECORDING_DOWNHILL @"trip_recording_downhill"

@interface OAMonitoringPlugin : OAPlugin

@property (nonatomic) BOOL saving;
@property (nonatomic) OALiveMonitoringHelper *liveMonitoringHelper;
@property (nonatomic) OASavingTrackHelper *savingTrackHelper;

- (void) controlDialog:(BOOL)showTrackSelection;

@end
