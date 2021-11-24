//
//  OAResourcesBaseViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAResourcesBaseViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>
#import <MBProgressHUD.h>

#import "OAAutoObserverProxy.h"
#import "OALocalResourceInformationViewController.h"
#import "OALog.h"
#import "OAManageResourcesViewController.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OATerrainLayer.h"
#import "OASizes.h"
#import "OARootViewController.h"
#import "OASQLiteTileSource.h"
#import "OATargetMenuViewController.h"
#import "OACustomSourceDetailsViewController.h"

#include "Localization.h"
#include <OsmAndCore/WorldRegions.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
typedef OsmAnd::IncrementalChangesManager::IncrementalUpdate IncrementalUpdate;

static BOOL dataInvalidated = NO;

@interface OAResourcesBaseViewController ()

@end

@implementation OAResourcesBaseViewController
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;

    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _repositoryUpdatedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _sqlitedbResourcesChangedObserver;

    MBProgressHUD* _deleteResourceProgressHUD;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];

        _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                  withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                                   andObserve:_app.downloadsManager.progressCompletedObservable];
        _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                    andObserve:_app.downloadsManager.completedObservable];
        _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                    andObserve:_app.localResourcesChangedObservable];
        _repositoryUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onRepositoryUpdated:withKey:)
                                                                andObserve:_app.resourcesRepositoryUpdatedObservable];

        _sqlitedbResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onSqlitedbResourcesChanged:withKey:)
                                                                    andObserve:[OAMapCreatorHelper sharedInstance].sqlitedbResourcesChangedObservable];

        _resourceItemsComparator = ^NSComparisonResult(id obj1, id obj2) {
            NSString *str1;
            NSString *str2;
            
            if ([obj1 isKindOfClass:[OAWorldRegion class]])
            {
                str1 = ((OAWorldRegion *)obj1).name;
            }
            else
            {
                OAResourceItem *item = obj1;
                if (item.resourceId.startsWith(QStringLiteral("world_")))
                    str1 = [NSString stringWithFormat:@"!%@%d", item.title, item.resourceType];
                else
                    str1 = [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
            }

            if ([obj2 isKindOfClass:[OAWorldRegion class]])
            {
                str2 = ((OAWorldRegion *)obj2).name;
            }
            else
            {
                OAResourceItem *item = obj2;
                if (item.resourceId.startsWith(QStringLiteral("world_")))
                    str2 = [NSString stringWithFormat:@"!%@%d", item.title, item.resourceType];
                else
                    str2 = [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
            }
            
            return [str1 localizedCaseInsensitiveCompare:str2];
        };
    }
    return self;
}

- (void) dealloc
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
    if (_repositoryUpdatedObserver)
    {
        [_repositoryUpdatedObserver detach];
        _repositoryUpdatedObserver = nil;
    }
}

+ (BOOL) isDataInvalidated
{
    return dataInvalidated;
}

+ (void) setDataInvalidated
{
    dataInvalidated = YES;
}

@synthesize resourceItemsComparator = _resourceItemsComparator;

- (void) applyLocalization
{
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _deleteResourceProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _deleteResourceProgressHUD.labelText = OALocalizedString(@"res_deleting");
    [self.view addSubview:_deleteResourceProgressHUD];
    
    if (_app.downloadsManager.hasDownloadTasks)
        [self showDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.dataInvalidated || dataInvalidated)
    {
        [self updateContent];
        self.dataInvalidated = NO;
        dataInvalidated = NO;
    }
    
    if (self.downloadView)
    {
        if (_app.downloadsManager.hasDownloadTasks)
            [self validateDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
        else
            [self.downloadView removeFromSuperview];
    }
    else
    {
        if (_app.downloadsManager.hasDownloadTasks)
            [self showDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
    }
}

- (void) showDownloadViewForTask:(id<OADownloadTask>)task
{
    UITableView *tableView = [self getTableView];
    if (tableView)
    {
        if (self.downloadView && self.downloadView.superview)
            [self.downloadView removeFromSuperview];
        
        self.downloadView = [[OADownloadProgressView alloc] initWithFrame:CGRectMake(0, DeviceScreenHeight - kOADownloadProgressViewHeight, DeviceScreenWidth, kOADownloadProgressViewHeight)];
        [self.downloadView setTaskName:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]];
        self.downloadView.translatesAutoresizingMaskIntoConstraints = NO;
        self.downloadView.delegate = self;
        [self validateDownloadViewForTask:task];
        
        [self.view insertSubview:self.downloadView aboveSubview:tableView];
        
        // Constraints
        NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.f];
        [self.view addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
        [self.view addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
        [self.view addConstraint:constraint];
        
        [OAUtilities getBottomMargin];
        
        constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:kOADownloadProgressViewHeight + [OAUtilities getBottomMargin]];
        [self.view addConstraint:constraint];
    }
}

- (void) validateDownloadViewForTask:(id<OADownloadTask>)task
{
    [self.downloadView setProgress:task.progressCompleted];
    [self.downloadView setTitle:task.name];
    [self.downloadView setTaskName:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]];
    if (task.state == OADownloadTaskStatePaused)
        [self.downloadView setButtonStateResume];
    else
        [self.downloadView setButtonStatePause];
}

- (void)updateContent
{
}

- (void) refreshContent:(BOOL)update
{
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
}

- (void) downloadCustomItem:(OACustomResourceItem *)item
{
    [OAResourcesUIHelper startDownloadOfCustomItem:item onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item
{
    [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item
{
    [OAResourcesUIHelper offerDownloadAndUpdateOf:item onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void) startDownloadOfItem:(OARepositoryResourceItem *)item
{
    [OAResourcesUIHelper startDownloadOfItem:item onTaskCreated:^(id<OADownloadTask>  _Nonnull task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask>  _Nonnull task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
            resourceName:(NSString *)name
{
    [OAResourcesUIHelper startDownloadOf:resource resourceName:name onTaskCreated:^(id<OADownloadTask> _Nonnull task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask>  _Nonnull task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void) offerCancelDownloadOf:(OAResourceItem *)item_
{
    [OAResourcesUIHelper offerCancelDownloadOf:item_ onTaskStop:^(id<OADownloadTask>  _Nonnull task) {
        if ([[item_.resourceId.toNSString() stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:self.downloadView.taskName])
            [self.downloadView removeFromSuperview];
    }];
}

- (void) offerDeleteResourceOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block
{
    dispatch_block_t block_ = ^{
        [self.region.superregion updateGroupItems:self.region type:[OAResourceType toValue:item.resourceType]];
        if (block)
            block();
    };
    [OAResourcesUIHelper offerDeleteResourceOf:item viewController:self progressHUD:_deleteResourceProgressHUD executeAfterSuccess:block_];
}

- (void) offerDeleteResourceOf:(OALocalResourceItem *)item
{
    [self offerDeleteResourceOf:item executeAfterSuccess:nil];
}

- (void)offerSilentDeleteResourcesOf:(NSArray<OALocalResourceItem *> *)items
{
    dispatch_block_t block = ^{
        NSMutableSet *typesSet = [NSMutableSet new];
        for (OALocalResourceItem *item in items)
        {
            [typesSet addObject:[OAResourceType toValue:item.resourceType]];
        }
        for (NSNumber *type in typesSet.allObjects)
        {
            [self.region.superregion updateGroupItems:self.region type:type];
        }
    };
    [OAResourcesUIHelper deleteResourcesOf:items progressHUD:nil executeAfterSuccess:block];
}

- (void) offerClearCacheOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block
{
    [OAResourcesUIHelper offerClearCacheOf:item viewController:self executeAfterSuccess:block];
}

- (void) showDetailsOf:(OALocalResourceItem*)item
{
}

- (UITableView *) getTableView
{
    return nil;
}

- (void) onItemClicked:(id)senderItem
{
    if ([senderItem isKindOfClass:[OAResourceItem class]])
    {
        OAResourceItem* item_ = (OAResourceItem *)senderItem;

        if (item_.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:item_];
        }
        else if ([item_ isKindOfClass:[OAOutdatedResourceItem class]])
        {
            OAOutdatedResourceItem* item = (OAOutdatedResourceItem *)item_;
            [self offerDownloadAndUpdateOf:item];
        }
        else if ([item_ isKindOfClass:[OALocalResourceItem class]])
        {
            OALocalResourceItem* item = (OALocalResourceItem *)item_;
            [self showDetailsOf:item];
        }
        else if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
        {
            OARepositoryResourceItem* item = (OARepositoryResourceItem *)item_;
            
            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion) && ![_iapHelper.srtm isActive])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
            else if (item.resourceType == OsmAndResourceType::WikiMapRegion && ![_iapHelper.wiki isActive])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            else
                [self offerDownloadAndInstallOf:item];
        }
        else if ([item_ isKindOfClass:OACustomResourceItem.class])
        {
            OACustomResourceItem *customItem = (OACustomResourceItem *) item_;
            if (!customItem.isInstalled)
                [self downloadCustomItem:customItem];
            else
                [self showDetailsOfCustomItem:customItem];
        }
    }
}
    
- (void) showDetailsOfCustomItem:(OACustomResourceItem *)item
{
    OACustomSourceDetailsViewController *customSourceDetails = [[OACustomSourceDetailsViewController alloc] initWithCustomItem:item region:(OACustomRegion *)self.region];
    [self.navigationController pushViewController:customSourceDetails animated:YES];
}

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void) onRepositoryUpdated:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            self.dataInvalidated = YES;
            return;
        }

        [self updateContent];
    });
}

- (void) onSqlitedbResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            self.dataInvalidated = YES;
            return;
        }
        
        [self updateContent];
    });
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            self.dataInvalidated = YES;
            return;
        }

        [self updateContent];
    });
}

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
            return;
        
        if (!self.downloadView || !self.downloadView.superview)
            [self showDownloadViewForTask:task];
        
        [self.downloadView setProgress:[value floatValue]];
        //[self refreshContent:NO];
        [self refreshDownloadingContent:task.key];
        
    });
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* nsResourceId = [task.key substringFromIndex:[@"resource:" length]];
        const auto resourceId = QString::fromNSString(nsResourceId);
        const auto resource = _app.resourcesManager->getResource(resourceId);

        if (!self.isViewLoaded || self.view.window == nil)
        {
            self.dataInvalidated = YES;
            if (resource->type == OsmAndResourceType::MapRegion)
                [_app.data.mapLayerChangeObservable notifyEvent];

            return;
        }

        if (resource)
        {
            OAWorldRegion *foundRegion;
            for (OAWorldRegion *region in self.region.subregions)
            {
                if (resource->id.startsWith(QString::fromNSString(region.downloadsIdPrefix)))
                {
                    foundRegion = region;
                    break;
                }
            }
            if (foundRegion)
                [self.region updateGroupItems:foundRegion type:[OAResourceType toValue:resource->type]];
        }

        if ([[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:self.downloadView.taskName])
            [self.downloadView removeFromSuperview];
        
        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                id<OADownloadTask> nextTask =  [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
                [nextTask resume];

                //update balance
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self showDownloadViewForTask:nextTask];
                });
                
            }
            [self updateContent];
        }
        else
        {
            [self refreshDownloadingContent:task.key];
        }

    });
}

- (void) updateTableLayout
{
}

#pragma mark - OADownloadProgressViewDelegate

- (void) resumeDownloadButtonClicked:(OADownloadProgressView *)view {
    if (_app.downloadsManager.hasDownloadTasks) {
        id<OADownloadTask> task = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
        if (task)
            [task resume];
    }
}

- (void) pauseDownloadButtonClicked:(OADownloadProgressView *)view {
    if (_app.downloadsManager.hasActiveDownloadTasks) {
        id<OADownloadTask> task = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
        if (task)
            [task pause];
    }
}

- (void) downloadProgressViewDidAppear:(OADownloadProgressView *)view
{
    [self updateTableLayout];
}

- (void) downloadProgressViewDidDisappear:(OADownloadProgressView *)view
{
    [self updateTableLayout];
}


@end
