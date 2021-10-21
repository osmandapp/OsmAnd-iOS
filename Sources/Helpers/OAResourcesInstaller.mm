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
#import "OAAppSettings.h"
#import "OAResourcesUIHelper.h"
#import "OAMapCreatorHelper.h"
#import "OAIAPHelper.h"
#import "OAGPXDocument.h"
#import "OAGPXDatabase.h"

#include <OsmAndCore/ArchiveReader.h>

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

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _sync = [[NSObject alloc] init];
        
        _app = [OsmAndApp instance];

        _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskFinished:withKey:andValue:) andObserve:_app.downloadsManager.completedObservable];

        _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:) andObserve:_app.downloadsManager.progressCompletedObservable];
    }
    return self;
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    // Skip other states except Finished (and completed)
    if (task.state != OADownloadTaskStateFinished || task.error)
    {
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

+ (void)installGpxResource:(NSString *)localPath fileName:(NSString *)fileName
{
    OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:localPath];
    NSString *destFilePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:fileName];
    [NSFileManager.defaultManager createDirectoryAtPath:destFilePath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    [doc saveTo:destFilePath];
    [[OAGPXDatabase sharedDb] addGpxItem:destFilePath title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds document:doc];
    [[OAGPXDatabase sharedDb] save];
}

+ (void)installObfResource:(BOOL &)failed localPath:(NSString *)localPath fileName:(NSString *)fileName
{
    OsmAnd::ArchiveReader archive(QString::fromNSString(localPath));
    // List items
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok);
    if (!ok)
    {
        [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
        NSLog(@"Failed to install custom obf from the archive");
        failed = YES;
    }
    
    // Find the OBF file
    OsmAnd::ArchiveReader::Item obfArchiveItem;
    for (const auto& archiveItem : constOf(archiveItems))
    {
        if (!archiveItem.isValid() || !archiveItem.name.endsWith(QLatin1String(".obf")))
            continue;
        
        obfArchiveItem = archiveItem;
        break;
    }
    if (!obfArchiveItem.isValid())
    {
        [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
        NSLog(@"Custom obf in the archive is not valid");
        failed = YES;
    }
    NSString *unzippedPath = [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:fileName].stringByDeletingPathExtension;
    [NSFileManager.defaultManager removeItemAtPath:unzippedPath error:nil];
    QString pathToFile = QString::fromNSString(unzippedPath);
    if (!archive.extractItemToFile(obfArchiveItem.name, pathToFile))
    {
        [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
        NSLog(@"Failed to extract custom obf from the archive");
        failed = YES;
    }
    [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
    OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
}

+ (void)installSqliteResource:(NSString *)localPath fileName:(NSString *)fileName
{
    OAMapCreatorHelper *mapCreatorHelper = OAMapCreatorHelper.sharedInstance;
    [mapCreatorHelper installFile:localPath newFileName:fileName.lastPathComponent];
}

+ (BOOL) installCustomResource:(NSString *)localPath nsResourceId:(NSString *)nsResourceId fileName:(NSString *)fileName
{
    BOOL failed = NO;
    NSString *unzippedFilePath = localPath;
    if ([nsResourceId hasSuffix:@".gz"] || ([nsResourceId hasSuffix:@".zip"] && ![nsResourceId hasSuffix:@"obf.zip"]))
    {
        const auto fileExt = QString::fromNSString(nsResourceId.stringByDeletingPathExtension.pathExtension);
        if (fileExt.isEmpty())
            return YES;
        OsmAnd::ArchiveReader archive(QString::fromNSString(localPath));
        OsmAnd::ArchiveReader::Item targetArchiveItem;
        // List items
        bool ok = false;
        const auto archiveItems = archive.getItems(&ok);
        if (!ok)
        {
            [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
            NSLog(@"Failed to install custom resource from the archive");
            return YES;
        }
        for (const auto& archiveItem : constOf(archiveItems))
        {
            if (!archiveItem.isValid() || !archiveItem.name.endsWith(fileExt))
                continue;
            
            targetArchiveItem = archiveItem;
            break;
        }
        if (!targetArchiveItem.isValid())
        {
            [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
            NSLog(@"Custom resource file in the archive is not valid");
            return YES;
        }
        unzippedFilePath = [localPath stringByDeletingPathExtension];
        [NSFileManager.defaultManager removeItemAtPath:unzippedFilePath error:nil];
        QString pathToFile = QString::fromNSString(unzippedFilePath);
        if (!archive.extractItemToFile(targetArchiveItem.name, pathToFile))
        {
            [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
            NSLog(@"Failed to extract custom resource from the archive");
            return YES;
        }
        nsResourceId = [nsResourceId stringByDeletingPathExtension];
    }
    if ([nsResourceId hasSuffix:@"sqlitedb"])
        [self installSqliteResource:unzippedFilePath fileName:fileName];
    else if ([nsResourceId hasSuffix:@"obf.zip"])
        [self installObfResource:failed localPath:unzippedFilePath fileName:fileName];
    else if ([nsResourceId hasSuffix:@"gpx"])
        [self installGpxResource:unzippedFilePath fileName:fileName];
    
    [NSFileManager.defaultManager removeItemAtPath:unzippedFilePath error:nil];
    
    return failed;
}

- (void) processResource:(id<OADownloadTask>)task
{
    @synchronized(_sync)
    {
        NSString* localPath = task.targetPath;
        NSString* nsResourceId = [task.key substringFromIndex:[@"resource:" length]];
        const auto& resourceId = QString::fromNSString(nsResourceId);
        const auto& filePath = QString::fromNSString(localPath);
        bool success = false;
        bool showProgressHud = !resourceId.endsWith(QStringLiteral(".live.obf"));
        
        OALog(@"Going to install/update of %@", nsResourceId);
        // Try to install only in case of successful download
        if (task.error == nil)
        {
            if (showProgressHud)
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
            }
            
            // Install or update given resource
            success = _app.resourcesManager->updateFromFile(resourceId, filePath);
            if (!success)
            {
                success = _app.resourcesManager->installFromRepository(resourceId, filePath);
                if (success)
                {
                    if (nsResourceId && [[nsResourceId lowercaseString] hasSuffix:@".map.obf"])
                    {
                        OAWorldRegion* match = [OAResourcesUIHelper findRegionOrAnySubregionOf:_app.worldRegion thatContainsResource:QString([nsResourceId UTF8String])];
                        if (!match || ![match isInPurchasedArea])
                            [OAIAPHelper decreaseFreeMapsCount];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:OAResourceInstalledNotification object:nsResourceId userInfo:nil];
                    
                    // Set NSURLIsExcludedFromBackupKey for installed resource
                    if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(_app.resourcesManager->getResource(resourceId)))
                    {
                        NSURL *url = [NSURL fileURLWithPath:resource->localPath.toNSString()];
                        BOOL res = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
                        OALog(@"Set (%@) NSURLIsExcludedFromBackupKey for %@", (res ? @"OK" : @"FAILED"), resource->localPath.toNSString());

                        NSString *ext = [[resource->localPath.toNSString() pathExtension] lowercaseString];
                        NSString *type = [[[resource->localPath.toNSString() stringByDeletingPathExtension] pathExtension] lowercaseString];
                        if ([ext isEqualToString:@"sqlitedb"] && ([type isEqualToString:@"hillshade"] || [type isEqualToString:@"slope"]))
                            [_app.data.terrainResourcesChangeObservable notifyEvent];

                        if (resourceId == QString(kWorldSeamarksKey) || resourceId == QString(kWorldSeamarksOldKey))
                        {
                            if (resourceId == QString(kWorldSeamarksKey))
                            {
                                const auto& localResources = _app.resourcesManager->getLocalResources();
                                const auto& it = localResources.find(QString(kWorldSeamarksOldKey));
                                if (it != localResources.end())
                                {
                                    NSString *filePath = it.value()->localPath.toNSString();
                                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                                }
                            }
                        }
                        else
                        {
                            OAWorldRegion *foundRegion;
                            if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion || resource->type == OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion)
                            {
                                for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
                                {
                                    if (resource->id.startsWith(QString::fromNSString(region.downloadsIdPrefix)))
                                    {
                                        foundRegion = region;
                                        break;
                                    }
                                }
                                
                                //NSLog(@"found name=%@ bbox=(%f,%f)(%f,%f)", foundRegion.name, foundRegion.bboxTopLeft.latitude, foundRegion.bboxTopLeft.longitude, foundRegion.bboxBottomRight.latitude, foundRegion.bboxBottomRight.longitude);
                                
                                if (foundRegion && foundRegion.superregion && resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                                {
                                    [self initSettingsFirstMap:foundRegion];
                                }
                                
                                if (foundRegion && foundRegion.superregion && !task.silentInstall)
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [OAPluginPopupViewController showRegionOnMap:foundRegion];
                                    });
                                }
                            }
                            if (foundRegion)
                                [foundRegion.superregion updateGroupItems:foundRegion type:[OAResourceType toValue:resource->type]];
                        }
                    }
                    else
                    {
                        OALog(@"Cannot find installed resource %@", nsResourceId);
                    }
                }
                else
                {
                    // Handle custom resources
                    BOOL failed = [self.class installCustomResource:localPath nsResourceId:nsResourceId fileName:task.name];
                    if (failed)
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
            }
            
            if (showProgressHud)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (_progressHUD)
                    {
                        [_progressHUD hide:YES];
                        _progressHUD = nil;
                    }
                });
            }
            
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

- (void) initSettingsFirstMap:(OAWorldRegion *)reg
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (settings.firstMapIsDownloaded || !reg)
        return;
    
    settings.firstMapIsDownloaded = YES;
    
    if (![settings.drivingRegionAutomatic get])
        [_app setupDrivingRegion:reg];
    
    /*
    String lang = params.getRegionLang();
    if (lang != null) {
        String lng = lang.split(",")[0];
        String setTts = null;
        for (String s : OsmandSettings.TTS_AVAILABLE_VOICES) {
            if (lng.startsWith(s)) {
                setTts = s + "-tts";
                break;
            } else if (lng.contains("," + s)) {
                setTts = s + "-tts";
            }
        }
        if (setTts != null) {
            app.getSettings().VOICE_PROVIDER.set(setTts);
        }
    }
     */
}

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
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
