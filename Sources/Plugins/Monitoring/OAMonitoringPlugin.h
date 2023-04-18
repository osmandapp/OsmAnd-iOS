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

@interface OAMonitoringPlugin : OAPlugin

@property (nonatomic) BOOL saving;

- (void) showTripRecordingDialog:(BOOL)showTrackSelection;
- (BOOL) isLiveMonitoringEnabled;

@end
