//
//  OADownloadingCellMultipleResourceHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 06/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellMultipleResourceHelper.h"
#import "OADownloadMultipleResourceViewController.h"
#import "OAResourcesUISwiftHelper.h"

@interface OADownloadingCellMultipleResourceHelper() <OADownloadMultipleResourceDelegate>

@end


@implementation OADownloadingCellMultipleResourceHelper
{
    NSArray<OAMultipleResourceSwiftItem *> *_multipleDownloadingItems;
}

#pragma mark - Resource methods

// OAMultipleResourceItem is using for Contour lines. It have two OAResourceItem subitems - for feet and for meters file.
// This method return currently downloading subitem. Or just the first one.
- (OAResourceSwiftItem *) getActiveItemFrom:(OAResourceSwiftItem *)resourceItem useDefautValue:(BOOL)useDefautValue
{
    if (resourceItem && [resourceItem isKindOfClass:OAMultipleResourceSwiftItem.class])
    {
        OAMultipleResourceSwiftItem *multipleItem = (OAMultipleResourceSwiftItem *)resourceItem;
        return [multipleItem getActiveItem:useDefautValue];
    }
    return nil;
}

- (NSString *) getResourceId:(OAMultipleResourceSwiftItem *)multipleItem
{
    return [multipleItem getResourceId];
}

- (OAResourceSwiftItem *) getResource:(NSString *)resourceId
{
    OAResourceSwiftItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceSwiftItem.class])
        item = [self getActiveItemFrom:item useDefautValue:YES];
    return item;
}

// Override
- (BOOL) isInstalled:(NSString *)resourceId
{
    OAResourceSwiftItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceSwiftItem.class])
    {
        OAMultipleResourceSwiftItem *multipleItem = (OAMultipleResourceSwiftItem *)item;
        for (OAResourceSwiftItem *subitem in [multipleItem items])
        {
            if ([subitem isInstalled])
                return YES;
        }
    }
    return NO || [super isInstalled:resourceId];
}

// Override
- (BOOL) isDownloading:(NSString *)resourceId
{
    OAResourceSwiftItem *item = [super getResource:resourceId];
    if ([item isKindOfClass:OAMultipleResourceSwiftItem.class])
        item = [self getActiveItemFrom:item useDefautValue:NO];
    if (item)
        return item.downloadTask != nil;
    return NO || [super isDownloading:resourceId];
}

- (void) refreshMultipleDownloadTasks
{
    for (NSString *resourceId in [self getAllResourceIds])
    {
        OAResourceSwiftItem *item = [super getResource:resourceId];
        if ([item isKindOfClass:OAMultipleResourceSwiftItem.class])
        {
            OAMultipleResourceSwiftItem *multipleItem = (OAMultipleResourceSwiftItem *)item;
            for (OAResourceSwiftItem *subitem in [multipleItem items])
                [subitem refreshDownloadTask];
        }
    }
}

#pragma mark - Cell setup methods

//Override
- (OADownloadingCell *) getOrCreateCellForResourceId:(NSString *)resourceId swiftResourceItem:(OAResourceSwiftItem *)swiftResourceItem
{
    OAMultipleResourceSwiftItem *multipleItem = (OAMultipleResourceSwiftItem *)swiftResourceItem;
    for (OAResourceSwiftItem *subitem in multipleItem.items)
        [subitem refreshDownloadTask];

    if (![super getResource:resourceId])
    {
        // Saving OAMultipleResourceItem here. Not OAResourceItem subitem.
        [self saveResource:swiftResourceItem resourceId:resourceId];
        
        OAResourceSwiftItem *downloadingSubitem = [self getActiveItemFrom:swiftResourceItem useDefautValue:YES];
        if (downloadingSubitem && downloadingSubitem.downloadTask)
            [self saveStatus:EOAItemStatusInProgressType resourceId:resourceId];
    }
    
    return [super getOrCreateCell:resourceId];
}



#pragma mark - Cell behavior methods

// Override
- (void) onCellClicked:(NSString *)resourceId
{
    OAMultipleResourceSwiftItem *multipleItem = (OAMultipleResourceSwiftItem *)[super getResource:resourceId];
    
    if (![self isInstalled:resourceId] || self.isAlwaysClickable)
    {
        if (![self isDownloading:resourceId])
        {
            if (![self isDisabled:resourceId])
            {
                if (self.hostViewController)
                {
                    OADownloadMultipleResourceViewController *controller = [[OADownloadMultipleResourceViewController alloc] initWithSwiftResource:multipleItem];
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
            OAResourceSwiftItem *downloadingItem = [self getActiveItemFrom:multipleItem useDefautValue:NO];
            if (downloadingItem)
                [self stopDownload:[downloadingItem resourceId]];
        }
    }
}

#pragma mark - OADownloadMultipleResourceDelegate

- (void)downloadResources:(OAMultipleResourceSwiftItem *)item selectedItems:(NSArray<OAResourceSwiftItem *> *)selectedItems;
{
    [OAResourcesUISwiftHelper offerMultipleDownloadAndInstallOf:item selectedItems:selectedItems onTaskCreated:^(id<OADownloadTask> task) {
        [self refreshMultipleDownloadTasks];
        if ([self hostTableView])
            [[self hostTableView] reloadData];
    } onTaskResumed:nil];
}

- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceSwiftItem *> *)itemsToCheck
{
    [OAResourcesUISwiftHelper checkAndDeleteOtherSRTMResources:itemsToCheck];
}

- (void)clearMultipleResources
{
    _multipleDownloadingItems = nil;
}

@end
