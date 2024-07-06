//
//  OAFetchBackgroundDataOperation.m
//  OsmAnd
//
//  Created by Paul on 13.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAFetchBackgroundDataOperation.h"
#import "OsmAndApp.h"
#import "OADownloadsManager.h"
#import "OAAutoObserverProxy.h"

#import <AFNetworking/AFNetworkReachabilityManager.h>

@implementation OAFetchBackgroundDataOperation
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_backgroundDownloadCanceledObserver;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = OsmAndApp.instance;
        _backgroundDownloadCanceledObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                        withHandler:@selector(onBackgroundDownloadCanceled)
                                                                         andObserve:_app.downloadsManager.backgroundDownloadCanceledObservable];
    }
    return self;
}

- (void)dealloc
{
    if (_backgroundDownloadCanceledObserver)
    {
        [_backgroundDownloadCanceledObserver detach];
        _backgroundDownloadCanceledObserver = nil;
    }
}

- (void) main
{
    //if ([_app initializeCore] && [_app initialize])
    if (_app.initialized)
    {
        [self performUpdatesCheck];
    }
}

- (void) onBackgroundDownloadCanceled
{
    [self cancel];
}

- (void) performUpdatesCheck
{
    NSLog(@"OAFetchBackgroundDataOperation start");

    [_app checkAndDownloadOsmAndLiveUpdates:NO];

    NSLog(@"OAFetchBackgroundDataOperation LiveUpdates checked");

    OADownloadsManager *downloadManager = _app.downloadsManager;
    BOOL hasNetworkConnection = NO;
    BOOL hasTasks = NO;
    do {
        [NSThread sleepForTimeInterval:0.5];

        hasNetworkConnection = AFNetworkReachabilityManager.sharedManager.isReachable;
        hasTasks = [downloadManager numberOfDownloadTasksWithKeySuffix:@".live.obf"] > 0;

        NSLog(@"OAFetchBackgroundDataOperation processing live tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@".live.obf"]);

    } while (hasNetworkConnection && hasTasks && !self.cancelled);

    if (self.cancelled && hasTasks)
    {
        NSLog(@"OAFetchBackgroundDataOperation LiveUpdates cancel tasks %d", [downloadManager downloadTasksWithKeySuffix:@"tifsqlite"]);
        NSArray *tasks = [downloadManager downloadTasksWithKeySuffix:@".live.obf"];
        for (id<OADownloadTask> task in tasks)
            [task cancel];
    }

    NSLog(@"OAFetchBackgroundDataOperation LiveUpdates done");

    if (!self.cancelled && hasNetworkConnection)
    {
        [_app checkAndDownloadWeatherForecastsUpdates];
        NSLog(@"OAFetchBackgroundDataOperation ForecastsUpdates checked");
        do {
            [NSThread sleepForTimeInterval:0.5];

            hasNetworkConnection = AFNetworkReachabilityManager.sharedManager.isReachable;
            hasTasks = [downloadManager numberOfDownloadTasksWithKeySuffix:@"tifsqlite"] > 0;

            NSLog(@"OAFetchBackgroundDataOperation processing forecasts tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@"tifsqlite"]);

        } while (hasNetworkConnection && hasTasks && !self.cancelled);

        if (self.cancelled && hasTasks)
        {
            NSLog(@"OAFetchBackgroundDataOperation ForecastsUpdates cancel tasks %d", [downloadManager downloadTasksWithKeySuffix:@"tifsqlite"]);
            NSArray *tasks = [downloadManager downloadTasksWithKeySuffix:@"tifsqlite"];
            for (id<OADownloadTask> task in tasks)
                [task cancel];
        }

        NSLog(@"OAFetchBackgroundDataOperation ForecastsUpdates done");
    }

    NSLog(@"OAFetchBackgroundDataOperation finish");
}

@end
