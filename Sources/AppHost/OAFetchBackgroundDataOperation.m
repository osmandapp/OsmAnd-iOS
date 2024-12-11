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
#import "OAObservable.h"
#import "OADownloadTask.h"
#import "OALog.h"
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
    OALog(@"OAFetchBackgroundDataOperation start");

    [_app checkAndDownloadOsmAndLiveUpdates:NO];

    OALog(@"OAFetchBackgroundDataOperation LiveUpdates checked");

    OADownloadsManager *downloadManager = _app.downloadsManager;
    BOOL hasNetworkConnection = NO;
    BOOL hasTasks = NO;
    do {
        [NSThread sleepForTimeInterval:0.5];

        hasNetworkConnection = AFNetworkReachabilityManager.sharedManager.isReachable;
        hasTasks = [downloadManager numberOfDownloadTasksWithKeySuffix:@".live.obf"] > 0;

        OALog(@"OAFetchBackgroundDataOperation processing live tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@".live.obf"]);

    } while (hasNetworkConnection && hasTasks && !self.cancelled);

    if (self.cancelled && hasTasks)
    {
        OALog(@"OAFetchBackgroundDataOperation LiveUpdates cancel tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@".live.obf"]);
        NSArray *tasks = [downloadManager downloadTasksWithKeySuffix:@".live.obf"];
        for (id<OADownloadTask> task in tasks)
            [task cancel];
    }

    OALog(@"OAFetchBackgroundDataOperation LiveUpdates done");

    if (!self.cancelled && hasNetworkConnection)
    {
        [_app checkAndDownloadWeatherForecastsUpdates];
        OALog(@"OAFetchBackgroundDataOperation ForecastsUpdates checked");
        do {
            [NSThread sleepForTimeInterval:0.5];

            hasNetworkConnection = AFNetworkReachabilityManager.sharedManager.isReachable;
            hasTasks = [downloadManager numberOfDownloadTasksWithKeySuffix:@"tifsqlite"] > 0;

            OALog(@"OAFetchBackgroundDataOperation processing forecasts tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@"tifsqlite"]);

        } while (hasNetworkConnection && hasTasks && !self.cancelled);

        if (self.cancelled && hasTasks)
        {
            OALog(@"OAFetchBackgroundDataOperation ForecastsUpdates cancel tasks %d", [downloadManager numberOfDownloadTasksWithKeySuffix:@"tifsqlite"]);
            NSArray *tasks = [downloadManager downloadTasksWithKeySuffix:@"tifsqlite"];
            for (id<OADownloadTask> task in tasks)
                [task cancel];
        }

        OALog(@"OAFetchBackgroundDataOperation ForecastsUpdates done");
    }

    OALog(@"OAFetchBackgroundDataOperation finish");
}

@end
