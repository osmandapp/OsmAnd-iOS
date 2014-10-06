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
#import <FormatterKit/TTTArrayFormatter.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OALocalResourceInformationViewController.h"
#import "OALog.h"

#include "Localization.h"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@implementation ResourceItem
@end

@implementation RepositoryResourceItem
@end

@implementation LocalResourceItem
@end

@implementation OutdatedResourceItem
@end

@interface OAResourcesBaseViewController ()

@property OADownloadProgressView* downloadView;


@end

@implementation OAResourcesBaseViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _repositoryUpdatedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;

    MBProgressHUD* _deleteResourceProgressHUD;
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _dataInvalidated = NO;

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

        _resourceItemsComparator = ^NSComparisonResult(id obj1, id obj2) {
            ResourceItem *item1 = obj1;
            ResourceItem *item2 = obj2;

            return [item1.title localizedCaseInsensitiveCompare:item2.title];
        };
    }
    return self;
}

@synthesize resourceItemsComparator = _resourceItemsComparator;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _deleteResourceProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _deleteResourceProgressHUD.labelText = OALocalizedString(@"Deleting...");
    [self.view addSubview:_deleteResourceProgressHUD];
    
    // IOS-178 Add download view
    if (_app.downloadsManager.hasDownloadTasks)
        [self showDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_dataInvalidated)
    {
        [self updateContent];
        _dataInvalidated = NO;
    }
    
    if (self.downloadView)
        if (_app.downloadsManager.hasDownloadTasks)
            [self validateDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
        else
            [self.downloadView removeFromSuperview];
    else {
        if (_app.downloadsManager.hasDownloadTasks)
            [self showDownloadViewForTask:[_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]]];
    }
}

#pragma mark - IOS-178 Add download view
-(void)showDownloadViewForTask:(id<OADownloadTask>)task {
    self.downloadView = [[OADownloadProgressView alloc] initWithFrame:CGRectMake(0, DeviceScreenHeight - 40, DeviceScreenWidth, 40)];
    [self.downloadView setTaskName: [[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0] stringByReplacingOccurrencesOfString:@"resource:" withString:@""] ];
    self.downloadView.translatesAutoresizingMaskIntoConstraints = NO;
    self.downloadView.delegate = self;
    [self validateDownloadViewForTask:task];
    
    [self.view addSubview:self.downloadView];
    
    // Constraints
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:40.0f];
    [self.view addConstraint:constraint];
    
}

-(void) validateDownloadViewForTask:(id<OADownloadTask>)task {
    [self.downloadView setProgress:task.progressCompleted];
    if (task.state == OADownloadTaskStatePaused)
        [self.downloadView setButtonStateResume];
    else
        [self.downloadView setButtonStatePause];
}

@synthesize dataInvalidated = _dataInvalidated;

- (void)updateContent
{
}

- (void)refreshContent
{
}

- (NSString*)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                    inRegion:(OAWorldRegion*)region
              withRegionName:(BOOL)includeRegionName
{
    if (region == _app.worldRegion)
    {
        if (resource->id == QLatin1String("world_basemap.map.obf"))
        {
            if (includeRegionName)
                return OALocalizedString(@"Detailed worldwide overview map");
            else
                return OALocalizedString(@"Detailed overview map");
        }

        // By default, world region has only predefined set of resources
        return nil;
    }

    switch(resource->type)
    {
        case OsmAndResourceType::MapRegion:
            if ([region.subregions count] > 0)
            {
                if (!includeRegionName || region == nil)
                    return OALocalizedString(@"Full map of entire region");
                else
                    return OALocalizedString(@"Full map of entire %@", region.name);
            }
            else
            {
                if (!includeRegionName || region == nil)
                    return OALocalizedString(@"Full map of the region");
                else
                    return OALocalizedString(@"Full map of %@", region.name);
            }
            break;

        default:
            return nil;
    }
}

- (BOOL)isSpaceEnoughToDownloadAndUnpackOf:(ResourceItem*)item_
{
    if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

        return [self isSpaceEnoughToDownloadAndUnpackResource:item.resource];
    }
    else if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        const auto resource = _app.resourcesManager->getResourceInRepository(item_.resourceId);

        return [self isSpaceEnoughToDownloadAndUnpackResource:resource];
    }

    return NO;
}

- (BOOL)isSpaceEnoughToDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
{
    uint64_t spaceNeeded = resource->packageSize + resource->size;
    return (_app.freeSpaceAvailableOnDevice >= spaceNeeded);
}

- (BOOL)verifySpaceAvailableToDownloadAndUnpackOf:(ResourceItem*)item_
                                         asUpdate:(BOOL)isUpdate
{
    if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

        return [self verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                                  withResourceName:[self titleOfResource:item.resource
                                                                                inRegion:item.worldRegion
                                                                          withRegionName:YES]
                                                          asUpdate:isUpdate];
    }
    else if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        LocalResourceItem* item = (LocalResourceItem*)item_;

        const auto resource = _app.resourcesManager->getResourceInRepository(item.resourceId);

        return [self verifySpaceAvailableDownloadAndUnpackResource:resource
                                                  withResourceName:[self titleOfResource:item.resource
                                                                                inRegion:item.worldRegion
                                                                          withRegionName:YES]
                                                          asUpdate:isUpdate];
    }
    
    return NO;
}

- (BOOL)verifySpaceAvailableDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
                                     withResourceName:(NSString*)resourceName
                                             asUpdate:(BOOL)isUpdate
{
    uint64_t spaceNeeded = resource->packageSize + resource->size;
    BOOL isEnoughSpace = (_app.freeSpaceAvailableOnDevice >= spaceNeeded);

    if (!isEnoughSpace)
    {
        [self showNotEnoughSpaceAlertFor:resourceName
                                withSize:spaceNeeded
                                asUpdate:isUpdate];
    }
    
    return isEnoughSpace;
}

- (void)showNotEnoughSpaceAlertFor:(NSString*)resourceName
                          withSize:(unsigned long long)size
                          asUpdate:(BOOL)isUpdate
{
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:size
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* message = nil;
    if (isUpdate)
    {
        message = OALocalizedString(@"Not enough space to update %1$@. %2$@ is needed. Please free up some space.",
                                    resourceName,
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"Not enough space to install %1$@. %2$@ is needed. Please free up some space.",
                                    resourceName,
                                    stringifiedSize);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"OK")]
                       otherButtonItems:nil] show];
}

- (void)offerDownloadAndUpdateOf:(OutdatedResourceItem*)item
{
    const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);

    NSString* resourceName = [self titleOfResource:item.resource
                                          inRegion:item.worldRegion
                                    withRegionName:YES];

    if (![self verifySpaceAvailableDownloadAndUnpackResource:resourceInRepository
                                            withResourceName:resourceName
                                                    asUpdate:YES])
    {
        return;
    }

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:resourceInRepository->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* message = nil;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded over cellular network. This may incur high charges. Proceed?",
                                    resourceName,
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded over WiFi network. Proceed?",
                                    resourceName,
                                    stringifiedSize);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update")
                                                             action:^{
                                                                 [self startDownloadOf:resourceInRepository];
                                                             }], nil] show];
}

- (void)offerDownloadAndInstallOf:(RepositoryResourceItem*)item
{
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:item.resource->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* resourceName = [self titleOfResource:item.resource
                                          inRegion:item.worldRegion
                                    withRegionName:YES];

    if (![self verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                            withResourceName:resourceName
                                                    asUpdate:YES])
    {
        return;
    }

    NSString* message = nil;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = OALocalizedString(@"Intallation of %1$@ needs %2$@ to be downloaded over cellular network. This may incur high charges. Proceed?",
                                    resourceName,
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"Intallation of %1$@ needs %2$@ to be be downloaded over WiFi network. Proceed?",
                                    resourceName,
                                    stringifiedSize);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Install")
                                                             action:^{
                                                                 [self startDownloadOf:item.resource];
                                                             }], nil] show];
}

- (void)startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
{
    // Create download tasks
    NSURLRequest* request = [NSURLRequest requestWithURL:resource->url.toNSURL()];
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]];

    [self updateContent];

    // Resume task only if it's other resource download tasks are not running
    if ([_app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil) {
        [task resume];
        [self showDownloadViewForTask:task];
    }
}

- (void)offerCancelDownloadOf:(ResourceItem*)item_
{
    BOOL isUpdate = NO;
    std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
    if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        LocalResourceItem* item = (LocalResourceItem*)item_;

        resource = item.resource;
        isUpdate = [item isKindOfClass:[OutdatedResourceItem class]];
    }
    else if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

        resource = item.resource;
    }
    if (!resource)
        return;

    NSString* message = nil;
    if (isUpdate)
    {
        message = OALocalizedString(@"You're going to cancel %@ update. All downloaded data will be lost. Proceed?",
                                    [self titleOfResource:resource
                                                 inRegion:item_.worldRegion
                                           withRegionName:YES]);
    }
    else
    {
        message = OALocalizedString(@"You're going to cancel %@ installation. All downloaded data will be lost. Proceed?",
                                    [self titleOfResource:resource
                                                 inRegion:item_.worldRegion
                                           withRegionName:YES]);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")
                                                             action:^{
                                                                 [self cancelDownloadOf:item_];
                                                             }], nil] show];
}

- (void)cancelDownloadOf:(ResourceItem*)item
{
    if ([[item.resourceId.toNSString() stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:self.downloadView.taskName])
        [self.downloadView removeFromSuperview];
    
    [item.downloadTask stop];
    
}

- (void)offerDeleteResourceOf:(LocalResourceItem*)item
{
    BOOL isInstalled = (std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(item.resource) != nullptr);

    NSString* message = nil;
    if (isInstalled)
    {
        message = OALocalizedString(@"You're going to uninstall %@. You can reinstall it later from catalog. Proceed?",
                                    [self titleOfResource:item.resource
                                                 inRegion:item.worldRegion
                                           withRegionName:YES]);
    }
    else
    {
        message = OALocalizedString(@"You're going to delete %@. It's not from catalog, so please be sure you have a backup if needed. Proceed?",
                                    [self titleOfResource:item.resource
                                                 inRegion:item.worldRegion
                                           withRegionName:YES]);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")]
                       otherButtonItems:[RIButtonItem itemWithLabel:isInstalled ? OALocalizedString(@"Uninstall") : OALocalizedString(@"Delete")
                                                             action:^{
                                                                 [self deleteResourceOf:item];
                                                             }], nil] show];
}

- (void)deleteResourceOf:(LocalResourceItem*)item
{
    [_deleteResourceProgressHUD showAnimated:YES
                         whileExecutingBlock:^{
                             const auto success = _app.resourcesManager->uninstallResource(item.resourceId);
                             if (!success)
                             {
                                 OALog(@"Failed to uninstall resource %@ from %@",
                                       item.resourceId.toNSString(),
                                       item.resource->localPath.toNSString());
                             }
                         }];
}

- (void)showDetailsOf:(LocalResourceItem*)item
{
    NSString* resourceId = item.resourceId.toNSString();
    [self.navigationController pushViewController:[[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId]
                                         animated:YES];
}

- (void)onItemClicked:(id)senderItem
{
    if ([senderItem isKindOfClass:[ResourceItem class]])
    {
        ResourceItem* item_ = (ResourceItem*)senderItem;

        if (item_.downloadTask != nil)
        {
            [self offerCancelDownloadOf:item_];
        }
        else if ([item_ isKindOfClass:[OutdatedResourceItem class]])
        {
            OutdatedResourceItem* item = (OutdatedResourceItem*)item_;

            [self offerDownloadAndUpdateOf:item];
        }
        else if ([item_ isKindOfClass:[LocalResourceItem class]])
        {
            LocalResourceItem* item = (LocalResourceItem*)item_;

            [self showDetailsOf:item];
        }
        else if ([item_ isKindOfClass:[RepositoryResourceItem class]])
        {
            RepositoryResourceItem* item = (RepositoryResourceItem*)item_;
            
            [self offerDownloadAndInstallOf:item];
        }
    }
}

- (id<OADownloadTask>)getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void)onRepositoryUpdated:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _dataInvalidated = YES;
            return;
        }

        [self updateContent];
    });
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _dataInvalidated = YES;
            return;
        }

        [self updateContent];
    });
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
            return;
        [self.downloadView setProgress:[value floatValue]];
        [self refreshContent];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _dataInvalidated = YES;
            return;
        }

        if ([[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:self.downloadView.taskName])
            [self.downloadView removeFromSuperview];
        
        if ([_app.downloadsManager.keysOfDownloadTasks count] > 0) {
            id<OADownloadTask> nextTask =  [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
            [nextTask resume];
            
            self.downloadView = nil;
            
            //update balance
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showDownloadViewForTask:nextTask];
            });
        }
        

        [self updateContent];
    });
}

+ (OAWorldRegion*)findRegionOrAnySubregionOf:(OAWorldRegion*)region
                        thatContainsResource:(const QString&)resourceId
{
    const auto& downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);

    if (resourceId.startsWith(downloadsIdPrefix))
        return region;

    for (OAWorldRegion* subregion in region.subregions)
    {
        OAWorldRegion* match = [OAResourcesBaseViewController findRegionOrAnySubregionOf:subregion
                                                                    thatContainsResource:resourceId];
        if (match)
            return match;
    }

    return nil;
}



#pragma mark - OADownloadProgressViewDelegate
-(void) resumeDownloadButtonClicked:(OADownloadProgressView *)view {
    if (_app.downloadsManager.hasDownloadTasks) {
        id<OADownloadTask> task = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
        if (task)
            [task resume];
    }
}

-(void) pauseDownloadButtonClicked:(OADownloadProgressView *)view {
    if (_app.downloadsManager.hasActiveDownloadTasks) {
        id<OADownloadTask> task = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
        if (task)
            [task pause];
    }
}



@end
