//
//  OADownloadingCellHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 31.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OADownloadingCellHelper.h"
#import "OAResourcesUIHelper.h"
#import "OARightIconTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAManageResourcesViewController.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OAPluginPopupViewController.h"
#import "OAIAPHelper.h"
#import "OADownloadMultipleResourceViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "GeneratedAssetSymbols.h"

@interface OADownloadingCellHelper() <OADownloadMultipleResourceDelegate>

@end

@implementation OADownloadingCellHelper
{
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
    NSArray<OAResourceItem *> *_multipleDownloadingItems;
}

- (instancetype)init
{
    self = [super init];
    if (self)
        [self commonInit];
    return self;
}

- (void)commonInit
{
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:) andObserve:OsmAndApp.instance.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskFinished:withKey:andValue:) andObserve:OsmAndApp.instance.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onLocalResourcesChanged:withKey:) andObserve:OsmAndApp.instance.localResourcesChangedObservable];
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


#pragma mark - Cell setup

- (OARightIconTableViewCell *)setupSwiftCell:(OAResourceSwiftItem *)swiftMapItem indexPath:(NSIndexPath *)indexPath
{
    if (swiftMapItem)
    {
        return [self setupCell:swiftMapItem.objcResourceItem indexPath:indexPath];
    }
    return nil;
}

- (OARightIconTableViewCell *)setupCell:(OAResourceItem *)mapItem indexPath:(NSIndexPath *)indexPath
{
    if ([mapItem isKindOfClass:OAMultipleResourceItem.class])
        mapItem = [self getActiveItemForIndexPath:indexPath useDefautValue:YES];
    
    static NSString* const repositoryResourceCell = @"repositoryResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";
   
    NSString* cellTypeId = mapItem.downloadTask ? downloadingResourceCell : repositoryResourceCell;
    uint64_t _sizePkg = mapItem.sizePkg;
    NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:mapItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
    NSString *title = mapItem.title;
    mapItem.disabled = [self isDisabled:mapItem];

    OARightIconTableViewCell* cell = [_hostTableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *) nib[0];
        [cell leftIconVisibility:YES];
        [cell descriptionVisibility:YES];
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        cell.descriptionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
    
    if ([cellTypeId isEqualToString:repositoryResourceCell])
    {
        cell.accessoryView = nil;
        [cell rightIconVisibility:YES];
        cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_download"];
        cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    }
    else if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        [cell rightIconVisibility:NO];
        FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
        progressView.iconView = [[UIView alloc] init];
        progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.accessoryView = progressView;
    }
    
    if ([cellTypeId isEqualToString:repositoryResourceCell])
    {
        if (!mapItem.disabled)
        {
            cell.accessoryView = nil;
            [cell rightIconVisibility:YES];
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_download"];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        else
        {
            cell.accessoryView = nil;
            [cell rightIconVisibility:NO];
            cell.titleLabel.textColor = [UIColor lightGrayColor];
        }
    }
    else if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        [cell rightIconVisibility:NO];
        FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
        progressView.iconView = [[UIView alloc] init];
        progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.accessoryView = progressView;
    }
    
    cell.leftIconView.image = [OAResourceType getIcon:mapItem.resourceType templated:YES];
    cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    cell.titleLabel.text = title;
    cell.descriptionLabel.text = subtitle;

    if ([cellTypeId isEqualToString:downloadingResourceCell])
        [self updateDownloadingCell:cell indexPath:indexPath mapItem:mapItem];

    return cell;
}

- (BOOL)isDisabled:(OAResourceItem *)mapItem
{
    OAIAPHelper *iapHelper = OAIAPHelper.sharedInstance;
    if ((mapItem.resourceType == OsmAndResourceType::WikiMapRegion) && ![iapHelper.wiki isActive])
        return YES;
    else if ((mapItem.resourceType == OsmAndResourceType::SrtmMapRegion || mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion)
        && ![iapHelper.srtm isActive])
        return YES;
    
    return NO;
}

- (void)showPopup:(OAResourceItem *)mapItem
{
    if (mapItem.resourceType == OsmAndResourceType::WikiMapRegion)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
    else if (mapItem.resourceType == OsmAndResourceType::SrtmMapRegion || mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
}


#pragma mark - Actions

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [_hostTableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:_hostTableView]];

    if (indexPath)
        [self onItemClicked:indexPath];
}

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    OAResourceItem *mapItem = [self getResourceByIndex:indexPath];
    if (mapItem)
    {
        if ([mapItem isKindOfClass:OAMultipleResourceItem.class])
        {
            //Multiple cell (contour lines with feet/meters selector)
            OAResourceItem *subItem = [self getActiveItemForIndexPath:indexPath useDefautValue:NO];
            if (subItem.downloadTask != nil)
            {
                [OAResourcesUIHelper offerCancelDownloadOf:subItem onTaskStop:nil completionHandler:^(UIAlertController *alert) {
                    [_hostViewController presentViewController:alert animated:YES completion:nil];
                }];
            }
            else
            {
                if ([self isDisabled:subItem])
                {
                    [self showPopup:subItem];
                }
                else
                {
                    OAMultipleResourceItem *item = (OAMultipleResourceItem *)[self getResourceByIndex:indexPath];
                    if (item)
                    {
                        OADownloadMultipleResourceViewController *controller = [[OADownloadMultipleResourceViewController alloc] initWithResource:item];
                        controller.delegate = self;
                        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                        [_hostViewController presentViewController:navigationController animated:YES completion:nil];
                    }
                }
            }
        }
        else
        {
            //Regular cell
            if (mapItem.downloadTask != nil)
            {
                [OAResourcesUIHelper offerCancelDownloadOf:mapItem onTaskStop:nil completionHandler:^(UIAlertController *alert) {
                    [_hostViewController presentViewController:alert animated:YES completion:nil];
                }];
            }
            else if ([mapItem isKindOfClass:[OARepositoryResourceItem class]])
            {
                OARepositoryResourceItem *resItem = (OARepositoryResourceItem *) mapItem;
                if ([self isDisabled:mapItem])
                {
                    [self showPopup:mapItem];
                }
                else
                {
                    [OAResourcesUIHelper offerDownloadAndInstallOf:resItem onTaskCreated:^(id<OADownloadTask> task) {
                        [self updateAvailableMaps];
                    } onTaskResumed:nil];
                }
            }
        }
    }
}


#pragma mark - Cell animating methods

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void)updateAvailableMaps
{
    [self refreshMultipleDownloadTasks];
    if (_fetchResourcesBlock)
        _fetchResourcesBlock();
    
    [UIView transitionWithView:self.hostTableView duration:0.35f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
        [_hostTableView reloadData];
    } completion:nil];
}

- (void)updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath mapItem:(OAResourceItem *)mapItem
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OARightIconTableViewCell *cell = [_hostTableView cellForRowAtIndexPath:indexPath];
        [self updateDownloadingCell:cell indexPath:indexPath mapItem:mapItem];
    });
}

- (void)updateDownloadingCell:(OARightIconTableViewCell *)cell indexPath:(NSIndexPath *)indexPath mapItem:(OAResourceItem *)mapItem
{
    if ([mapItem isKindOfClass:OAMultipleResourceItem.class])
        mapItem = [self getActiveItemForIndexPath:indexPath useDefautValue:NO];
    
    if (mapItem.downloadTask)
    {
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;

        float progressCompleted = mapItem.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && mapItem.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (mapItem.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            progressView.progress = 0.0f;
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
        progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    }
}

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
    [self iterateAllCellsWithAction:^(OAResourceItem *item, NSIndexPath *indexPath) {
        if ([item isKindOfClass:OAMultipleResourceItem.class])
            item = [self getActiveItemForIndexPath:indexPath useDefautValue:NO];
        
        if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
        {
            [self updateDownloadingCellAtIndexPath:indexPath mapItem:item];
        }
    }];
}

- (void) refreshMultipleDownloadTasks
{
    [self iterateAllCellsWithAction:^(OAResourceItem *item, NSIndexPath *indexPath) {
        if ([item isKindOfClass:OAMultipleResourceItem.class])
        {
            for (OARepositoryResourceItem *subitem in ((OAMultipleResourceItem *)item).items)
                subitem.downloadTask = [self getDownloadTaskFor:subitem.resource->id.toNSString()];
        }
    }];
}

#pragma mark - Helpers

- (OAResourceItem *)getResourceByIndex:(NSIndexPath *)indexPath
{
    OAResourceItem *item = nil;
    if (_getResourceByIndexBlock)
    {
        item = _getResourceByIndexBlock(indexPath);
    }
    if (_getSwiftResourceByIndexBlock)
    {
        OAResourceSwiftItem *swiftItem = _getSwiftResourceByIndexBlock(indexPath);
        if (swiftItem)
        {
            item = swiftItem.objcResourceItem;
        }
    }
    return item;
}

- (OAResourceItem *) getActiveItemForIndexPath:(NSIndexPath *)indexPath useDefautValue:(BOOL)useDefautValue
{
    OAResourceItem *item = [self getResourceByIndex:indexPath];
    if (item && [item isKindOfClass:OAMultipleResourceItem.class])
    {
        OAMultipleResourceItem *mapItem = (OAMultipleResourceItem *)item;
        for (OARepositoryResourceItem *resourceItem in mapItem.items)
        {
            if (resourceItem.downloadTask != nil)
                return resourceItem;
        }
        if (useDefautValue)
            return mapItem.items[0];
    }
    else
    {
        return item;
    }
    return nil;
}

- (void)iterateAllCellsWithAction:(void (^)(OAResourceItem *, NSIndexPath *))action
{
    @synchronized(_hostDataLock)
    {
        if (_getTableDataBlock)
        {
            __weak NSArray<NSArray <NSDictionary *> *> *tableData = _getTableDataBlock();
            if (tableData)
            {
                for (int sectionIndex = 0; sectionIndex < tableData.count; sectionIndex++)
                {
                    for (int rowIndex = 0; rowIndex < tableData[sectionIndex].count; rowIndex++)
                    {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                        OAResourceItem *item = _getResourceByIndexBlock(indexPath);
                        if (item && action)
                            action(item, indexPath);
                    }
                }
            }
        }
        else if (_getTableDataModelBlock)
        {
            __weak OATableDataModel *tableDataModel = _getTableDataModelBlock();
            if (tableDataModel)
            {
                for (int sectionIndex = 0; sectionIndex < tableDataModel.sectionCount; sectionIndex++)
                {
                    OATableSectionData *section = [tableDataModel sectionDataForIndex:sectionIndex];
                    for (int rowIndex = 0; rowIndex < section.rowCount; rowIndex++)
                    {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                        OAResourceItem *item = [self getResourceByIndex:indexPath];
                        if (item && action)
                            action(item, indexPath);
                    }
                }
            }
        }
    }
}


#pragma mark - Downloading cell progress observer's methods

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString *taskKey = task.key;

    // Skip all downloads that are not resources
    if (![taskKey hasPrefix:@"resource:"] && ![taskKey hasSuffix:@"travel.obf"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_hostViewController.isViewLoaded || _hostViewController.view.window == nil)
            return;

        [self refreshDownloadingContent:taskKey];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_hostViewController.isViewLoaded || _hostViewController.view.window == nil)
            return;

        if (task.progressCompleted < 1.0)
        {
            if ([OsmAndApp.instance.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                id<OADownloadTask> nextTask = [OsmAndApp.instance.downloadsManager firstDownloadTasksWithKey:OsmAndApp.instance.downloadsManager.keysOfDownloadTasks[0]];
                [nextTask resume];
            }
            [self updateAvailableMaps];
        }
        else
        {
            [self refreshDownloadingContent:task.key];
        }
    });
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_hostViewController.isViewLoaded || _hostViewController.view.window == nil)
            return;

        [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];

        [OAManageResourcesViewController prepareData];
        [self updateAvailableMaps];
    });
}


#pragma mark - OADownloadMultipleResourceDelegate

- (void)downloadResources:(OAMultipleResourceItem *)item selectedItems:(NSArray<OAResourceItem *> *)selectedItems;
{
    _multipleDownloadingItems = selectedItems;
    [OAResourcesUIHelper offerMultipleDownloadAndInstallOf:item selectedItems:selectedItems onTaskCreated:^(id<OADownloadTask> task) {
        [self refreshMultipleDownloadTasks];
        [_hostTableView reloadData];
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
