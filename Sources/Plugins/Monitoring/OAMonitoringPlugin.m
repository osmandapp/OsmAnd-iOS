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
#import "OALiveMonitoringHelper.h"
#import "OAIAPHelper.h"

#define PLUGIN_ID @"osmand.monitoring"

@implementation OAMonitoringPlugin
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OATextInfoWidget *_monitoringControl;
    OALiveMonitoringHelper *_liveMonitoringHelper;
    BOOL _isSaving;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _liveMonitoringHelper = [[OALiveMonitoringHelper alloc] init];
        NSArray<OAApplicationMode *> *am = [OAApplicationMode allPossibleValues];
        [OAApplicationMode regWidgetVisibility:@"monitoring" am:am];
    }
    return self;
}

+ (NSString *) getId
{
    return PLUGIN_ID;
}

+ (NSString *) getInAppId
{
    return kInAppId_Addon_TrackRecording;
}

- (void) updateLocation:(CLLocation *)location
{
    [_liveMonitoringHelper updateLocation:location];
}

- (NSString *) getLogoResourceId
{
    return @"ic_plugin_tracrecording";
}

- (NSString *) getAssetResourceName
{
    return @"img_plugin_trip_recording.jpg";
}

@end
