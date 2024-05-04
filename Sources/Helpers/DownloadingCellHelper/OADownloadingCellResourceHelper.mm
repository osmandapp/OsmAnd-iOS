//
//  OADownloadingCellResourceHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellResourceHelper.h"
#import "OAResourcesUIHelper.h"
#import "OARightIconTableViewCell.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADownloadingCellResourceHelper
{
    NSMutableDictionary<NSString *, OAResourceItem *> *_resourceItems;
    
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

- (OARightIconTableViewCell *) getOrCreateCellForResourceId:(NSString *)resourceId resourceItem:(OAResourceItem *)resourceItem
{
    if (!_resourceItems[resourceId])
        _resourceItems[resourceId] = resourceItem;
    
    return [super getOrCreateCellForResourceId:resourceId];
}

- (OARightIconTableViewCell *) getOrCreateSwiftCellForResourceId:(NSString *)resourceId swiftResourceItem:(OAResourceSwiftItem *)swiftResourceItem
{
    if (swiftResourceItem && swiftResourceItem.objcResourceItem)
    {
        OAResourceItem *resourceItem = (OAResourceItem *)swiftResourceItem.objcResourceItem;
        if (!_resourceItems[resourceId])
            _resourceItems[resourceId] = resourceItem;
        
        return [super getOrCreateCellForResourceId:resourceId];
    }
    return nil;
}

// Override
- (OARightIconTableViewCell *) getOrCreateCellForResourceId:(NSString *)resourceId
{
    // use new method instead
    return nil;
}

// Override
- (OARightIconTableViewCell *) setupCellForResourceId:(NSString *)resourceId
{
    OAResourceItem *resourceItem = _resourceItems[resourceId];
    if (resourceItem)
    {
        uint64_t _sizePkg = resourceItem.sizePkg;
        NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:resourceItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
        NSString *title = resourceItem.title;
        NSString *iconName = [OAResourceType getIconName:resourceItem.resourceType];
        BOOL isDownloading = resourceItem.downloadTask;
        
        OARightIconTableViewCell *cell = [super setupCellForResourceId:resourceId title:title isTitleBold:NO desc:subtitle leftIconName:iconName rightIconName:@"ic_custom_download" isDownloading:isDownloading];
        
        if ([self isInstalled:resourceId])
        {
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            [cell rightIconVisibility:NO];
        }
        if ([self isDisabled:resourceItem])
        {
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            [cell rightIconVisibility:NO];
        }
        
        return cell;
    }
    return nil;
}

- (void) onRowSelectedWith:(NSString *)resourceId
{
    OAResourceItem *resourceItem = _resourceItems[resourceId];
    if (resourceItem)
    {
        if (![self isInstalled:resourceId])
        {
            if (resourceItem.downloadTask == nil)
            {
                //Start new downloading
                OARepositoryResourceItem *resItem = (OARepositoryResourceItem *) resourceItem;
                if ([self isDisabled:resourceItem])
                    [self showPopup:resourceItem];
                else
                    [OAResourcesUIHelper offerDownloadAndInstallOf:resItem onTaskCreated:nil onTaskResumed:nil];
            }
            else if ([resourceItem isKindOfClass:[OARepositoryResourceItem class]])
            {
                //Stop current downloading
                [OAResourcesUIHelper offerCancelDownloadOf:resourceItem onTaskStop:nil completionHandler:^(UIAlertController *alert) {
                    if (_hostViewController)
                        [_hostViewController presentViewController:alert animated:YES completion:nil];
                }];
            }
        }
    }
}

- (BOOL)isDisabled:(OAResourceItem *)resourceItem
{
    OAIAPHelper *iapHelper = OAIAPHelper.sharedInstance;
    if ((resourceItem.resourceType == OsmAndResourceType::WikiMapRegion) && ![iapHelper.wiki isActive])
        return YES;
    else if ((resourceItem.resourceType == OsmAndResourceType::SrtmMapRegion || resourceItem.resourceType == OsmAndResourceType::HillshadeRegion || resourceItem.resourceType == OsmAndResourceType::SlopeRegion)
        && ![iapHelper.srtm isActive])
        return YES;
    
    return NO;
}

- (BOOL) isInstalled:(NSString *)resourceId
{
    OAResourceItem *resourceItem = _resourceItems[resourceId];
    if (resourceItem)
    {
        return resourceItem.isInstalled || [super isInstalled:resourceId];
    }
    return NO;
}

- (void)showPopup:(OAResourceItem *)mapItem
{
    if (mapItem.resourceType == OsmAndResourceType::WikiMapRegion)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
    else if (mapItem.resourceType == OsmAndResourceType::SrtmMapRegion || mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
}


#pragma mark - Downloading cell progress observer's methods

- (void)onDownloadResourceTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString *taskKey = task.key;
    taskKey = [taskKey stringByReplacingOccurrencesOfString:@"resource:" withString:@""];
    float progress = ((NSNumber *)value).floatValue;
    
    // Skip downloadings from another screens
    OAResourceItem *resourceItem = _resourceItems[taskKey];
    if (resourceItem)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [super setProgressForResourceId:taskKey progress:progress status:EOAItemStatusInProgressType];
        });
    }
}

- (void)onDownloadResourceTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString *taskKey = task.key;
    taskKey = [taskKey stringByReplacingOccurrencesOfString:@"resource:" withString:@""];
    float progress = task.progressCompleted;

    // Skip downloadings from another screens
    OAResourceItem *resourceItem = _resourceItems[taskKey];
    if (resourceItem)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setProgressForResourceId:taskKey progress:progress status:EOAItemStatusFinishedType];
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

@end
