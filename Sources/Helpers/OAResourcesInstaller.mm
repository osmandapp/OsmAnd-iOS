//
//  OAResourcesInstaller.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAResourcesInstaller.h"

#import "OsmAndApp.h"
#import "OADownloadsManager.h"
#import "OAAutoObserverProxy.h"
#import "OALog.h"

NSString *const OAResourceInstalledNotification = @"OAResourceInstalledNotification";


@implementation OAResourcesInstaller
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];

        _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                    andObserve:_app.downloadsManager.completedObservable];
        _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                  withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                                   andObserve:_app.downloadsManager.progressCompletedObservable];
    }
    return self;
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    // Skip other states except Finished (and completed)
    if (task.state != OADownloadTaskStateFinished || task.progressCompleted < 1.0f) {
        
        if (task.state == OADownloadTaskStateFinished)
            [_app updateScreenTurnOffSetting];

        return;
    }

    task.installResourceRetry = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(processResource:) withObject:task afterDelay:0.1];
        
    });

}

-(void)processResource:(id<OADownloadTask>)task
{
    NSString* localPath = task.targetPath;
    NSString* nsResourceId = [task.key substringFromIndex:[@"resource:" length]];
    const auto& resourceId = QString::fromNSString(nsResourceId);
    const auto& filePath = QString::fromNSString(localPath);
    bool success = false;
    
    OALog(@"Going to install/update of %@", nsResourceId);
    
    // Try to install only in case of successful download
    if (task.error == nil)
    {
        // Install or update given resource
        success = _app.resourcesManager->updateFromFile(resourceId, filePath);
        if (!success) {
            success = _app.resourcesManager->installFromRepository(resourceId, filePath);
            if (success) {
                [[NSNotificationCenter defaultCenter] postNotificationName:OAResourceInstalledNotification object:nsResourceId userInfo:nil];
            } else {
                task.installResourceRetry++;
                if (task.installResourceRetry < 10) {
                    OALog(@"installResourceRetry = %d", task.installResourceRetry);
                    [self performSelector:@selector(processResource:) withObject:task afterDelay:0.5];
                    return;
                }
            }
        }
    }
    
    // Remove downloaded file anyways
    [[NSFileManager defaultManager] removeItemAtPath:task.targetPath
                                               error:nil];
    
    OALog(@"Install/update of %@ %@", nsResourceId, success ? @"successful" : @"failed");
    
    // Start next resource download task if such exists
    id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKeyPrefix:@"resource:"];
    if (!nextTask)
        [_app updateScreenTurnOffSetting];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    NSString* nsResourceId = [task.key substringFromIndex:[@"resource:" length]];
    NSNumber* progressCompleted = (NSNumber*)value;
    OALog(@"Resource download task %@: %@ done", nsResourceId, progressCompleted);
}

@end
