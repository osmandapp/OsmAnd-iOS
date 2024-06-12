//
//  OADownloadingCellResourceHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellResourceHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADownloadingCellResourceHelper
{
    NSMutableDictionary<NSString *, OAResourceSwiftItem *> *_resourceItems;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _resourceItems = [NSMutableDictionary dictionary];
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadResourceTaskProgressChanged:withKey:andValue:) andObserve:OsmAndApp.instance.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadResourceTaskFinished:withKey:andValue:) andObserve:OsmAndApp.instance.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onLocalResourcesChanged:withKey:andValue:) andObserve:OsmAndApp.instance.localResourcesChangedObservable];
}

- (void)dealloc
{
    if (_downloadTaskProgressObserver)
    {
        [_downloadTaskProgressObserver detach];
        _downloadTaskProgressObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
}

#pragma mark - Resource methods

- (BOOL) helperHasItemFor:(NSString *)resourceId
{
    return _resourceItems[resourceId] != nil;
}

- (NSArray<NSString *> *) getAllResourceIds
{
    return [_resourceItems allKeys];
}

- (OAResourceSwiftItem *) getResource:(NSString *)resourceId
{
    return _resourceItems[resourceId];
}

- (void) saveResource:(OAResourceSwiftItem *)resource resourceId:(NSString *)resourceId;
{
    _resourceItems[resourceId] = resource;
}

- (BOOL) isDisabled:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
    {
        OAIAPHelper *iapHelper = OAIAPHelper.sharedInstance;
        if (([resourceItem resourceType] == EOAOAResourceSwiftItemTypeWikiMapRegion) && ![iapHelper.wiki isActive])
            return YES;
        else if (([resourceItem resourceType] == EOAOAResourceSwiftItemTypeSrtmMapRegion || [resourceItem resourceType] == EOAOAResourceSwiftItemTypeHillshadeRegion || [resourceItem resourceType] == EOAOAResourceSwiftItemTypeSlopeRegion)
                 && ![iapHelper.srtm isActive])
            return YES;
    }
    return NO;
}

// Override
- (BOOL) isInstalled:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
        return [resourceItem isInstalled] || [super isInstalled:resourceId];
    return NO;
}

// Override
- (BOOL) isDownloading:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
        return [resourceItem downloadTask] != nil && [super isDownloading:resourceId];
    return NO;
}

// Override
- (void) startDownload:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
        [OAResourcesUISwiftHelper offerDownloadAndInstallOf:resourceItem onTaskCreated:nil onTaskResumed:nil];
}

// Override
- (void) stopDownload:(NSString *)resourceId
{
    if (_stopWithAlertMessage)
    {
        OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
        if (resourceItem)
        {
            [OAResourcesUISwiftHelper offerCancelDownloadOf:resourceItem onTaskStop:nil completionHandler:^(UIAlertController *alert) {
                if (_hostViewController)
                    [_hostViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
    else
    {
        // Stop immediately
        id<OADownloadTask> task = [self getDownloadTask:resourceId];
        if (task)
            [task stop];
    }
    
}

- (id<OADownloadTask>) getDownloadTask:(NSString*)resourceId
{
    return [[[OsmAndApp instance].downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

#pragma mark - Cell setup methods

- (OADownloadingCell *) getOrCreateSwiftCellForResourceId:(NSString *)resourceId swiftResourceItem:(OAResourceSwiftItem *)swiftResourceItem
{
    if (swiftResourceItem && swiftResourceItem.objcResourceItem)
    {
        if (![self getResource:resourceId])
        {
            [self saveResource:swiftResourceItem resourceId:resourceId];
            if ([swiftResourceItem downloadTask])
                [self saveStatus:EOAItemStatusInProgressType resourceId:resourceId];
        }
        return [super getOrCreateCell:resourceId];
    }
    return nil;
}

// Override
- (OADownloadingCell *) setupCell:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
    {
        NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [resourceItem type], [resourceItem formatedSizePkg]];
        NSString *title = resourceItem.title;
        NSString *iconName = [resourceItem iconName];
        BOOL isDownloading = [self isDownloading:resourceId];
        
        // get cell with default settings
        OADownloadingCell *cell = [super setupCell:resourceId title:title isTitleBold:NO desc:subtitle leftIconName:iconName rightIconName:[self getRightIconName] isDownloading:isDownloading];
        
        if ([self isDisabled:resourceId])
        {
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            [cell rightIconVisibility:NO];
        }
        return cell;
    }
    return nil;
}

#pragma mark - Cell behavior methods

// Override
- (void) onCellClicked:(NSString *)resourceId
{
    if (![self isInstalled:resourceId] || self.isAlwaysClickable)
    {
        if (![self isDownloading:resourceId])
        {
            if (![self isDisabled:resourceId])
                [self startDownload:resourceId];
            else
                [self showActivatePluginPopup:resourceId];
        }
        else
        {
            [self stopDownload:resourceId];
        }
    }
}

- (void)showActivatePluginPopup:(NSString *)resourceId
{
    OAResourceSwiftItem *resourceItem = [self getResource:resourceId];
    if (resourceItem)
    {
        if ([resourceItem resourceType] == EOAOAResourceSwiftItemTypeWikiMapRegion)
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
        else if ([resourceItem resourceType] == EOAOAResourceSwiftItemTypeSrtmMapRegion || [resourceItem resourceType] == EOAOAResourceSwiftItemTypeHillshadeRegion || resourceItem.resourceType == EOAOAResourceSwiftItemTypeSlopeRegion)
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
    }
}

#pragma mark - Downloading cell progress observer's methods

- (void)onDownloadResourceTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    float progress = ((NSNumber *)value).floatValue;
    NSString *resourceId = [self getResourceIdFromNotificationKey:key andValue:value];
    if ([self helperHasItemFor:resourceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [super setCellProgress:resourceId progress:progress status:EOAItemStatusInProgressType];
        });
    }
}

- (void)onDownloadResourceTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    float progress = ((NSNumber *)value).floatValue;
    NSString *resourceId = [self getResourceIdFromNotificationKey:key andValue:value];
    if (resourceId && [self helperHasItemFor:resourceId])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setCellProgress:resourceId progress:progress status:EOAItemStatusFinishedType];
            
            // Start next downloading if needed
            if ([OsmAndApp.instance.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                id<OADownloadTask> nextTask = [OsmAndApp.instance.downloadsManager firstDownloadTasksWithKey:OsmAndApp.instance.downloadsManager.keysOfDownloadTasks[0]];
                [nextTask resume];
            }
        });
    }
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_hostViewController.isViewLoaded || _hostViewController.view.window == nil)
            return;
        
        [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
        [OAManageResourcesViewController prepareData];
        if (_delegate && [_delegate respondsToSelector:@selector(onDownldedResourceInstalled)])
            [_delegate onDownldedResourceInstalled];
    });
}

- (NSString *) getResourceIdFromNotificationKey:(id)key andValue:(id)value
{
    // When we're creating a cell Contour Lines resource, we don't know which subfile user will download (srtm or srtmf).
    // But we're allready need a "resourceId" key for dictionary at this moment.
    // Anyway, user allowed to download and store only type of Contour Line resource (srtm or srtmf file).
    // So on cell creating we can use any common key for booth of them. Let it be "srtm".
    //
    // "resource:africa.srtmf" -> "africa.srtm"
    
    id<OADownloadTask> task = key;
    NSString *taskKey = task.key;
    
    // Skip all downloads that are not resources
    if (![taskKey hasPrefix:@"resource:"])
        return nil;
    
    taskKey = [taskKey stringByReplacingOccurrencesOfString:@"resource:" withString:@""];
    taskKey = [taskKey stringByReplacingOccurrencesOfString:@"srtmf" withString:@"srtm"];
    return taskKey;
}

@end
