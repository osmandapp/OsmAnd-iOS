//
//  OADownloadingCellMultipleResourceHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 06/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellMultipleResourceHelper.h"
#import "OADownloadMultipleResourceViewController.h"

@interface OADownloadingCellMultipleResourceHelper() <OADownloadMultipleResourceDelegate>

@end


@implementation OADownloadingCellMultipleResourceHelper
{
    NSArray<OAResourceItem *> *_multipleDownloadingItems;
}

#pragma mark - Resource methods

// OAMultipleResourceItem is using for Contour lines. It have two OAResourceItem subitems - for feet and for meters file.
// This method return currently downloading subitem. Or just the first one.
- (OAResourceItem *) getActiveItemFrom:(OAResourceItem *)resourceItem useDefautValue:(BOOL)useDefautValue
{
    if (resourceItem && [resourceItem isKindOfClass:OAMultipleResourceItem.class])
    {
        OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *)resourceItem;
        for (OARepositoryResourceItem *item in multipleItem.items)
        {
            if (item.downloadTask != nil)
                return item;
        }
        if (useDefautValue)
            return multipleItem.items[0];
    }
    return nil;
}

- (NSString *) getResourceId:(OAMultipleResourceItem *)multipleItem
{
    OAResourceItem *firstItem = multipleItem.items[0];
    NSString *resourceId = firstItem.resourceId.toNSString();
    return [resourceId stringByReplacingOccurrencesOfString:@"srtmf" withString:@"srtm"];
}

- (OAResourceItem *) getResource:(NSString *)resourceId
{
    OAResourceItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceItem.class])
        item = [self getActiveItemFrom:item useDefautValue:YES];
    return item;
}

// Override
- (BOOL) isInstalled:(NSString *)resourceId
{
    OAResourceItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceItem.class])
    {
        OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *)item;
        for (OAResourceItem *subitem in multipleItem.items)
        {
            if (subitem.isInstalled)
                return YES;
        }
    }
    return NO || [super isInstalled:resourceId];
}

// Override
- (BOOL) isDownloading:(NSString *)resourceId
{
    OAResourceItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceItem.class])
        item = [self getActiveItemFrom:item useDefautValue:NO];
    if (item)
        return item.downloadTask != nil;
    return NO || [super isDownloading:resourceId];
}

- (void) refreshMultipleDownloadTasks
{
    for (NSString *resourceId in [self getAllResourceIds])
    {
        OAResourceItem *item = [super getResource:resourceId];
        if ([item isKindOfClass:OAMultipleResourceItem.class])
        {
            OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *)item;
            for (OARepositoryResourceItem *subitem in multipleItem.items)
                subitem.downloadTask = [self getDownloadTaskFor:subitem.resource->id.toNSString()];
        }
    }
}

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

#pragma mark - Cell setup methods

//Override
- (OADownloadingCell *) getOrCreateCellForResourceId:(NSString *)resourceId resourceItem:(OAResourceItem *)resourceItem
{
    OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *)resourceItem;
    for (OARepositoryResourceItem *subitem in multipleItem.items)
        subitem.downloadTask = [self getDownloadTaskFor:subitem.resource->id.toNSString()];
    
    if (![super getResource:resourceId])
    {
        // Saving OAMultipleResourceItem here. Not OAResourceItem subitem.
        [self saveResource:resourceItem resourceId:resourceId];
    
        OAResourceItem *downloadingSubitem = [self getActiveItemFrom:resourceItem useDefautValue:YES];
        if (downloadingSubitem && downloadingSubitem.downloadTask)
            [self saveStatus:EOAItemStatusInProgressType resourceId:resourceId];
    }
    
    return [super getOrCreateCell:resourceId];
}



#pragma mark - Cell behavior methods

// Override
- (void) onCellClicked:(NSString *)resourceId
{
    OAMultipleResourceItem *multipleItem = [super getResource:resourceId];
    
    if (![self isInstalled:resourceId] || self.isAlwaysClickable)
    {
        if (![self isDownloading:resourceId])
        {
            if (![self isDisabled:resourceId])
            {
                if (self.hostViewController)
                {
                    OADownloadMultipleResourceViewController *controller = [[OADownloadMultipleResourceViewController alloc] initWithResource:multipleItem];
                    controller.delegate = self;
                    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                    [self.hostViewController presentViewController:navigationController animated:YES completion:nil];
                }
            }
            else
            {
                [self showActivatePluginPopup:resourceId];
            }
        }
        else
        {
            OAResourceItem *downloadingItem = [self getActiveItemFrom:multipleItem useDefautValue:NO];
            if (downloadingItem)
                [self stopDownload:downloadingItem.resourceId.toNSString()];
        }
    }
    else
    {
        // do nothing
    }
}

#pragma mark - OADownloadMultipleResourceDelegate

- (void)downloadResources:(OAMultipleResourceItem *)item selectedItems:(NSArray<OAResourceItem *> *)selectedItems;
{
    _multipleDownloadingItems = selectedItems;
    [OAResourcesUIHelper offerMultipleDownloadAndInstallOf:item selectedItems:selectedItems onTaskCreated:^(id<OADownloadTask> task) {
        [self refreshMultipleDownloadTasks];
        if (self.hostTableView)
            [self.hostTableView reloadData];
    } onTaskResumed:^(id<OADownloadTask> task) {
    }];
}

- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceItem *> *)itemsToCheck
{
    NSMutableArray<OALocalResourceItem *> *itemsToRemove = [NSMutableArray new];
    OAResourceItem *prevItem;
    for (OAResourceItem *itemToCheck in itemsToCheck)
    {
        QString srtmMapName = itemToCheck.resourceId.remove(QLatin1String([OAResourceType isSRTMF:itemToCheck] ? ".srtmf.obf" : ".srtm.obf"));
        if (prevItem && prevItem.resourceId.startsWith(srtmMapName))
        {
            BOOL prevItemInstalled = OsmAndApp.instance.resourcesManager->isResourceInstalled(prevItem.resourceId);
            if (prevItemInstalled && prevItem.resourceId.compare(itemToCheck.resourceId) != 0)
            {
                [itemsToRemove addObject:(OALocalResourceItem *) prevItem];
            }
            else
            {
                BOOL itemToCheckInstalled = OsmAndApp.instance.resourcesManager->isResourceInstalled(itemToCheck.resourceId);
                if (itemToCheckInstalled && itemToCheck.resourceId.compare(prevItem.resourceId) != 0)
                    [itemsToRemove addObject:(OALocalResourceItem *) itemToCheck];
            }
        }
        prevItem = itemToCheck;
    }
    [self offerSilentDeleteResourcesOf:itemsToRemove];
}

- (void)offerSilentDeleteResourcesOf:(NSArray<OALocalResourceItem *> *)items
{
    [OAResourcesUIHelper deleteResourcesOf:items progressHUD:nil executeAfterSuccess:nil];
}

- (void)clearMultipleResources
{
    _multipleDownloadingItems = nil;
}

@end
