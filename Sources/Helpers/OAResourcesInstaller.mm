//
//  OAResourcesInstaller.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAResourcesInstaller.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OADownloadsManager.h"
#import "OAAutoObserverProxy.h"
#import "OALog.h"
#import "OAObservable.h"
#import <MBProgressHUD.h>
#import "Localization.h"
#import "OAPluginPopupViewController.h"
#import "OAAppSettings.h"
#import "OAResourcesUIHelper.h"
#import "OAMapCreatorHelper.h"
#import "OADownloadTask.h"
#import "OAIAPHelper.h"
#import "OAGPXDatabase.h"
#import "OAWeatherHelper.h"
#import "OAWorldRegion.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/ArchiveReader.h>

NSString *const OAResourceInstalledNotification = @"OAResourceInstalledNotification";
NSString *const OAResourceInstallationFailedNotification = @"OAResourceInstallationFailedNotification";


@implementation OAResourcesInstaller
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy *_backgroundStateObserver;

    MBProgressHUD* _progressHUD;
    
    NSObject *_sync;
    
    OAWorldRegion *_lastDownloadedRegionInBackground;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _sync = [[NSObject alloc] init];
        
        _app = [OsmAndApp instance];

        _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                    andObserve:_app.downloadsManager.completedObservable];
        _backgroundStateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onBackgroundStateChanged)
                                                              andObserve:_app.backgroundStateObservable];
    }
    return self;
}

- (void)dealloc
{
    if (_backgroundStateObserver)
    {
        [_backgroundStateObserver detach];
        _backgroundStateObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
}

- (void) onBackgroundStateChanged
{
    if (!_app.isInBackgroundOnDevice && _lastDownloadedRegionInBackground)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [OAPluginPopupViewController showRegionOnMap:_lastDownloadedRegionInBackground];
            _lastDownloadedRegionInBackground = nil;
        });
    }
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    // Skip other states except Finished (and completed)
    if (task.state != OADownloadTaskStateFinished || task.error)
        return;

    task.installResourceRetry = 0;

    NSString* resourceId = [task.key substringFromIndex:[@"resource:" length]];
    [self checkDownload:resourceId downloadTime:task.downloadTime fileSize:task.fileSize];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self processResource:task];
    });
}

- (void) checkDownload:(NSString *)fileName downloadTime:(NSTimeInterval)downloadTime fileSize:(CGFloat)fileSize
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];

    [params setObject:fileName forKey:@"file_name"];
    [params setObject:[NSString stringWithFormat:@"%.1f", fileSize] forKey:@"file_size"];
    [params setObject:[NSString stringWithFormat:@"%d", (int)downloadTime] forKey:@"download_time"];

    [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/api/check_download" params:params post:NO async:YES onComplete:nil];
}

+ (void)installGpxResource:(NSString *)localPath fileName:(NSString *)fileName
{
    //OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:localPath];
    
    OASKFile *file = [[OASKFile alloc] initWithFilePath:localPath];
    OASGpxFile *doc = [OASGpxUtilities.shared loadGpxFileFile:file];
    NSString *destFilePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:fileName];
    [NSFileManager.defaultManager createDirectoryAtPath:destFilePath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    
    OASKFile *fileDest = [[OASKFile alloc] initWithFilePath:destFilePath];
    OASKException *exception = [OASGpxUtilities.shared writeGpxFileFile:fileDest gpxFile:doc];
    if (!exception)
    {
        OASGpxDataItem *dataItem = [[OAGPXDatabase sharedDb] addGPXFileToDBIfNeeded:destFilePath];
        if (dataItem)
        {
            OASGpxTrackAnalysis *analysis = [dataItem getAnalysis];
            
            NSString *nearestCity;
            if (analysis.locationStart)
            {
                OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:analysis.locationStart.position];
                dataItem.nearestCity = nearestCityPOI ? nearestCityPOI.nameLocalized : @"";
                [[OAGPXDatabase sharedDb] updateDataItem:dataItem];
            }
        }

    }
}

+ (void)installObfResource:(BOOL &)failed resourceId:(NSString *)resourceId localPath:(NSString *)localPath fileName:(NSString *)fileName hidden:(BOOL)hidden
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
    NSString *defaultPath = [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:fileName].stringByDeletingPathExtension;
    NSString *hiddenPath = [OsmAndApp.instance.hiddenMapsPath stringByAppendingPathComponent:fileName].stringByDeletingPathExtension;
    NSString *unzippedPath = hidden ? hiddenPath : defaultPath;

    [NSFileManager.defaultManager removeItemAtPath:unzippedPath error:nil];
    QString pathToFile = QString::fromNSString(unzippedPath);
    if (!archive.extractItemToFile(obfArchiveItem.name, pathToFile))
    {
        [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
        NSLog(@"Failed to extract custom obf from the archive");
        failed = YES;
    }
    else if (hidden && [NSFileManager.defaultManager fileExistsAtPath:defaultPath])
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        if ([resourceId hasSuffix:@".zip"])
            resourceId = [resourceId stringByDeletingPathExtension];
        if (app.resourcesManager->uninstallResource(QString::fromNSString(resourceId)))
            [app.data.mapLayerChangeObservable notifyEvent];
    }
    [NSFileManager.defaultManager removeItemAtPath:localPath error:nil];
    OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
}

+ (void)installSqliteResource:(NSString *)localPath fileName:(NSString *)fileName
{
    OAMapCreatorHelper *mapCreatorHelper = OAMapCreatorHelper.sharedInstance;
    [mapCreatorHelper installFile:localPath newFileName:fileName.lastPathComponent];
}

+ (BOOL) installCustomResource:(NSString *)localPath resourceId:(NSString *)resourceId fileName:(NSString *)fileName hidden:(BOOL)hidden
{
    BOOL failed = NO;
    NSString *unzippedFilePath = localPath;
    if ([resourceId hasSuffix:@".gz"] || ([resourceId hasSuffix:@".zip"] && ![resourceId hasSuffix:@"obf.zip"]))
    {
        const auto fileExt = QString::fromNSString(resourceId.stringByDeletingPathExtension.pathExtension);
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
        resourceId = [resourceId stringByDeletingPathExtension];
    }
    if ([resourceId hasSuffix:@"sqlitedb"])
        [self installSqliteResource:unzippedFilePath fileName:fileName];
    else if ([resourceId hasSuffix:@"obf.zip"])
        [self installObfResource:failed resourceId:resourceId localPath:unzippedFilePath fileName:fileName hidden:hidden];
    else if ([resourceId hasSuffix:@"gpx"])
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
        const auto resourceId = QString::fromNSString(nsResourceId);
        const auto filePath = QString::fromNSString(localPath);
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
                        UIView *topView = [UIApplication sharedApplication].mainWindow;
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
                    if (nsResourceId && [[nsResourceId lowercaseString] hasSuffix:@".obf"] && ![[nsResourceId lowercaseString] hasSuffix:@"live.obf"])
                    {
                        OAWorldRegion* match = [OAResourcesUIHelper findRegionOrAnySubregionOf:_app.worldRegion thatContainsResource:QString([nsResourceId UTF8String])];
                        const auto resource = _app.resourcesManager->getResourceInRepository(resourceId);
                        bool free = resource && resource->free;
                        if (!free)
                        {
                            if (!match || ![match isInPurchasedArea])
                                [OAIAPHelper decreaseFreeMapsCount];
                        }
                    }
                    else if (nsResourceId && [[nsResourceId lowercaseString] hasSuffix:@".tifsqlite"])
                    {
                        OAWorldRegion* match = [OAResourcesUIHelper findRegionOrAnySubregionOf:_app.worldRegion thatContainsResource:QString([nsResourceId UTF8String])];
                        [[OAWeatherHelper sharedInstance] setupDownloadStateFinished:match regionId:match.regionId];
                    }

                    [[NSNotificationCenter defaultCenter] postNotificationName:OAResourceInstalledNotification object:nsResourceId userInfo:nil];

                    // Set NSURLIsExcludedFromBackupKey for installed resource
                    if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(_app.resourcesManager->getResource(resourceId)))
                    {
                        NSURL *url = [NSURL fileURLWithPath:resource->localPath.toNSString()];
                        BOOL res = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
                        OALog(@"Set (%@) NSURLIsExcludedFromBackupKey for %@", (res ? @"OK" : @"FAILED"), resource->localPath.toNSString());

                        NSString *ext = [[resource->localPath.toNSString() pathExtension] lowercaseString];
                        NSString *type = [[[nsResourceId stringByDeletingPathExtension] pathExtension] lowercaseString];
                        if ([ext isEqualToString:@"sqlitedb"] && [type isEqualToString:@"heightmap"])
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
                                    if (region.downloadsIdPrefix.length > 0 &&  resource->id.startsWith(QString::fromNSString(region.downloadsIdPrefix)))
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
                                        if (_app.isInBackgroundOnDevice)
                                            _lastDownloadedRegionInBackground = foundRegion;
                                        else
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
                    BOOL failed = [self.class installCustomResource:localPath resourceId:nsResourceId fileName:task.name hidden:task.hidden];
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
        if ([_app.downloadsManager.keysOfDownloadTasks count] > 0 && (!_app.isInBackgroundOnDevice || _app.downloadsManager.backgroundDownloadTaskActive))
        {
            id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
            if (_app.isInBackgroundOnDevice)
                OALog(@"Resume background download of %@", nextTask.key);
            else
                OALog(@"Resume download of %@", nextTask.key);

            [nextTask resume];
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

@end
