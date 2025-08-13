//
//  OAMonitoringPlugin.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@interface OAMonitoringPlugin : OAPlugin

@property (nonatomic) BOOL saving;

- (void) showTripRecordingDialog;
- (BOOL) isLiveMonitoringEnabled;
- (void) saveTrack:(BOOL)askForRec;
- (void) disable;
- (BOOL) isRecordingTrack;
- (BOOL) hasDataToSave;
- (void) pauseOrResumeRecording;

@end
