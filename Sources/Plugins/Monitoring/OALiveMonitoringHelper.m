//
//  OALiveMonitoringHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALiveMonitoringHelper.h"
#import "OAAppSettings.h"

@implementation OALiveMonitoringHelper
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (BOOL) isLiveMonitoringEnabled
{
    return NO;
    // TODO
    //return settings.LIVE_MONITORING.get() && (settings.SAVE_TRACK_TO_GPX.get() || settings.SAVE_GLOBAL_TRACK_TO_GPX.get());
}

- (void) updateLocation:(CLLocation *)location
{
    // TODO
}

@end
