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
#import <MBProgressHUD.h>
#import "Localization.h"
#import "OAPluginPopupViewController.h"

NSString *const OAResourceInstalledNotification = @"OAResourceInstalledNotification";
NSString *const OAResourceInstallationFailedNotification = @"OAResourceInstallationFailedNotification";


@implementation OAResourcesInstaller
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;

    MBProgressHUD* _progressHUD;
    
    NSObject *_sync;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _sync = [[NSObject alloc] init];
        
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

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self processResource:task];
    });
}

-(void)processResource:(id<OADownloadTask>)task
{
    @synchronized(_sync)
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
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!_progressHUD)
                {
                    UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
                    _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
                    _progressHUD.removeFromSuperViewOnHide = YES;
                    _progressHUD.labelText = OALocalizedString(@"res_installing");
                    [topView addSubview:_progressHUD];
                    
                    [_progressHUD show:YES];
                }
            });
            
            // Install or update given resource
            success = _app.resourcesManager->updateFromFile(resourceId, filePath);
            if (!success)
            {
                success = _app.resourcesManager->installFromRepository(resourceId, filePath);
                if (success)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:OAResourceInstalledNotification object:nsResourceId userInfo:nil];
                    
                    // Set NSURLIsExcludedFromBackupKey for installed resource
                    if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(_app.resourcesManager->getResource(resourceId)))
                    {
                        NSURL *url = [NSURL fileURLWithPath:resource->localPath.toNSString()];
                        BOOL res = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
                        OALog(@"Set (%@) NSURLIsExcludedFromBackupKey for %@", (res ? @"OK" : @"FAILED"), resource->localPath.toNSString());

                        NSString *ext = [[resource->localPath.toNSString() pathExtension] lowercaseString];
                        NSString *type = [[[resource->localPath.toNSString() stringByDeletingPathExtension] pathExtension] lowercaseString];
                        if([ext isEqualToString:@"sqlitedb"] && [type isEqualToString:@"hillshade"])
                            [_app.data.hillshadeResourcesChangeObservable notifyEvent];

                        if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion || resource->type == OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion)
                        {
                            OAWorldRegion *foundRegion;
                            for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
                            {
                                if (resource->id.startsWith(QString::fromNSString(region.downloadsIdPrefix)))
                                {
                                    foundRegion = region;
                                    break;
                                }
                            }
                            
                            //NSLog(@"found name=%@ bbox=(%f,%f)(%f,%f)", foundRegion.name, foundRegion.bboxTopLeft.latitude, foundRegion.bboxTopLeft.longitude, foundRegion.bboxBottomRight.latitude, foundRegion.bboxBottomRight.longitude);

                            if (foundRegion && foundRegion.superregion && !task.silentInstall)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [OAPluginPopupViewController showRegionOnMap:foundRegion];
                                });
                            }
                        }
                        if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion || resource->type == OsmAnd::ResourcesManager::ResourceType::RoadMapRegion)
                        {
                            [_app initRoutingFile:resource->localPath.toNSString()];
                        }
                    }
                    else
                    {
                        OALog(@"Cannot find installed resource %@", nsResourceId);
                    }
                }
                else
                {
                    task.installResourceRetry++;
                    if (task.installResourceRetry < 20)
                    {
                        OALog(@"installResourceRetry = %d", task.installResourceRetry);
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                            [self processResource:task];
                        });
                        return;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (_progressHUD)
                {
                    [_progressHUD hide:YES];
                    _progressHUD = nil;
                }
            });
        }
        
        // Remove downloaded file anyways
        [[NSFileManager defaultManager] removeItemAtPath:task.targetPath
                                                   error:nil];
        
        OALog(@"Install/update of %@ %@", nsResourceId, success ? @"successful" : @"failed");
        
        if (!success)
            [[NSNotificationCenter defaultCenter] postNotificationName:OAResourceInstallationFailedNotification object:nsResourceId userInfo:nil];
        
        // Start next resource download task if such exists
        if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
        {
            id<OADownloadTask> nextTask =  [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
            [nextTask resume];
        }
        else
        {
            [_app updateScreenTurnOffSetting];
        }
    }
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
