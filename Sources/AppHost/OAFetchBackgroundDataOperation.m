//
//  OAFetchBackgroundDataOperation.m
//  OsmAnd
//
//  Created by Paul on 13.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAFetchBackgroundDataOperation.h"
#import "OsmAndApp.h"

@implementation OAFetchBackgroundDataOperation
{
    OsmAndAppInstance _app;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = OsmAndApp.instance;
    }
    return self;
}

- (void) main
{
    //if ([_app initializeCore] && [_app initialize])
    if (_app.initialized)
    {
        [self performUpdatesCheck];
    }
}

- (void) performUpdatesCheck
{
    NSLog(@"OAFetchBackgroundDataOperation start");

    [_app checkAndDownloadOsmAndLiveUpdates];
    if (!self.cancelled)
        [_app checkAndDownloadWeatherForecastsUpdates];

    NSLog(@"OAFetchBackgroundDataOperation finish");
}

@end
