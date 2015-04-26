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
#import "OAManageResourcesViewController.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"

#include "Localization.h"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@implementation ResourceItem

-(BOOL)isEqual:(id)object
{
    if (self.resourceId == nullptr || ((ResourceItem*)object).resourceId == nullptr)
        return NO;
    
    return self.resourceId.compare(((ResourceItem*)object).resourceId) == 0;
}

@end

@implementation RepositoryResourceItem
@end

@implementation LocalResourceItem
@end

@implementation OutdatedResourceItem
@end

@interface OAResourcesBaseViewController ()


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
            NSString *str1;
            NSString *str2;
            
            if ([obj1 isKindOfClass:[OAWorldRegion class]])
                str1 = ((OAWorldRegion *)obj1).name;
            else
                str1 = ((ResourceItem *)obj1).title;

            if ([obj2 isKindOfClass:[OAWorldRegion class]])
                str2 = ((OAWorldRegion *)obj2).name;
            else
                str2 = ((ResourceItem *)obj2).title;
            
            return [str1 localizedCaseInsensitiveCompare:str2];
        };
    }
    return self;
}

@synthesize resourceItemsComparator = _resourceItemsComparator;

-(void)applyLocalization
{
    [_btnToolbarMaps setTitle:OALocalizedStringUp(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedStringUp(@"purchases") forState:UIControlStateNormal];
    
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _deleteResourceProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    _deleteResourceProgressHUD.labelText = OALocalizedString(@"res_deleting");
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
    
    if (self.downloadView && self.downloadView.superview)
        [self.downloadView removeFromSuperview];
    
    self.downloadView = [[OADownloadProgressView alloc] initWithFrame:CGRectMake(0, DeviceScreenHeight - kOADownloadProgressViewHeight, DeviceScreenWidth, kOADownloadProgressViewHeight)];
    [self.downloadView setTaskName: [[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0] stringByReplacingOccurrencesOfString:@"resource:" withString:@""] ];
    self.downloadView.translatesAutoresizingMaskIntoConstraints = NO;
    self.downloadView.delegate = self;
    [self validateDownloadViewForTask:task];
    
    [self.view addSubview:self.downloadView];
    
    // Constraints
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.toolbarView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.downloadView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:kOADownloadProgressViewHeight];
    [self.view addConstraint:constraint];
    
}

-(void) validateDownloadViewForTask:(id<OADownloadTask>)task {
    [self.downloadView setProgress:task.progressCompleted];
    [self.downloadView setTitle:task.name];
    if (task.state == OADownloadTaskStatePaused)
        [self.downloadView setButtonStateResume];
    else
        [self.downloadView setButtonStatePause];
}

@synthesize dataInvalidated = _dataInvalidated;

- (void)updateContent
{
}

- (void)refreshContent:(BOOL)update
{
}

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
}

+ (NSString*)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                    inRegion:(OAWorldRegion*)region
              withRegionName:(BOOL)includeRegionName
{
    if (region == [OsmAndApp instance].worldRegion)
    {
        if (resource->id == QLatin1String("world_basemap.map.obf"))
        {
            if (includeRegionName)
                return OALocalizedString(@"res_wmap");
            else
                return OALocalizedString(@"res_dmap");
        }
        else if (resource->id == QLatin1String("world_seamarks_basemap.map.obf"))
        {
            if (includeRegionName)
                return OALocalizedString(@"res_wsea_map");
            else
                return OALocalizedString(@"res_wsea_map");
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
                    return OALocalizedString(@"res_map_of_region");
                else
                    //return OALocalizedString(@"Map of %@", region.name);
                    return OALocalizedString(@"%@", region.name);
            }
            else
            {
                if (!includeRegionName || region == nil)
                    return OALocalizedString(@"res_map_of_region");
                else
                    //return OALocalizedString(@"Map of %@", region.name);
                    return OALocalizedString(@"%@", region.name);
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
                                                  withResourceName:[self.class titleOfResource:item.resource
                                                                                inRegion:item.worldRegion
                                                                          withRegionName:YES]
                                                          asUpdate:isUpdate];
    }
    else if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        LocalResourceItem* item = (LocalResourceItem*)item_;

        const auto resource = _app.resourcesManager->getResourceInRepository(item.resourceId);

        return [self verifySpaceAvailableDownloadAndUnpackResource:resource
                                                  withResourceName:[self.class titleOfResource:item.resource
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

    NSMutableString* text;
    if (isUpdate)
    {
        text = [OALocalizedString(@"res_update_no_space") mutableCopy];
        [text appendString:@" "];
        [text appendString:resourceName];
        [text appendString:@"."];
        [text appendString:@" "];
        [text appendString:stringifiedSize];
        [text appendString:@" "];
        [text appendString:OALocalizedString(@"res_no_space_free")];
    }
    else
    {
        text = [OALocalizedString(@"res_install_no_space") mutableCopy];
        [text appendString:@" "];
        [text appendString:resourceName];
        [text appendString:@"."];
        [text appendString:@" "];
        [text appendString:stringifiedSize];
        [text appendString:@" "];
        [text appendString:OALocalizedString(@"res_no_space_free")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:text
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_ok")]
                       otherButtonItems:nil] show];
}

- (BOOL)checkIfDownloadEnabled:(OAWorldRegion *)region
{
#if defined(OSMAND_IOS_DEV)
    return YES;
#endif
    
    int tasksCount = _app.downloadsManager.keysOfDownloadTasks.count;
    
    if (region.regionId == nil || [region isInPurchasedArea] || ([OAIAPHelper freeMapsAvailable] > 0 && tasksCount < [OAIAPHelper freeMapsAvailable])) {
        return YES;
        
    } else {
        
        [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"res_free_exp") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
        
        return NO;
    }
}

- (BOOL)checkIfUpdateEnabled:(OAWorldRegion *)region
{
#if defined(OSMAND_IOS_DEV)
    return YES;
#endif
    
    if (region.regionId == nil || [region isInPurchasedArea]) {
        return YES;
        
    } else {
        
        [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"res_updates_exp") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
        
        return NO;
    }
}

- (void)offerDownloadAndUpdateOf:(OutdatedResourceItem*)item
{
    if (![self checkIfUpdateEnabled:item.worldRegion])
        return;
    
    const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);

    NSString* resourceName = [self.class titleOfResource:item.resource
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

    NSMutableString* message;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        [message appendString:resourceName];
        [message appendString:@"."];
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];        
    }
    else
    {
        message = [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        [message appendString:resourceName];
        [message appendString:@"."];
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_update")
                                                             action:^{
                                                                 [self startDownloadOf:resourceInRepository resourceName:resourceName];
                                                             }], nil] show];
}

- (void)offerDownloadAndInstallOf:(RepositoryResourceItem*)item
{
    if (![self checkIfDownloadEnabled:item.worldRegion])
        return;

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:item.resource->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    
    NSString* resourceName = [self.class titleOfResource:item.resource
                                          inRegion:item.worldRegion
                                    withRegionName:YES];

    if (![self verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                            withResourceName:resourceName
                                                    asUpdate:YES])
    {
        return;
    }

    NSMutableString* message;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_cell_q"),
                                    resourceName,
                                    stringifiedSize] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
        
    }
    else
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_wifi_q"),
                    resourceName,
                    stringifiedSize] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_install")
                                                             action:^{
                                                                 [self startDownloadOfItem:item];
                                                             }], nil] show];
}

- (void)startDownloadOfItem:(RepositoryResourceItem*)item
{
    // Create download tasks
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSURL* pureUrl = item.resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);
    
    NSString* name = [self.class titleOfResource:item.resource
                                        inRegion:item.worldRegion
                                  withRegionName:YES];
    
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:item.resource->id.toNSString()]
                                                                     andName:name];
    
    [self updateContent];
    
    // Resume task only if it's other resource download tasks are not running
    if ([_app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil) {
        [task resume];
        [self showDownloadViewForTask:task];
    }
}

- (void)startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name
{
    // Create download tasks
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSURL* pureUrl = resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);
    
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]
                               andName:name];

    [self updateContent];

    // Resume task only if it's other resource download tasks are not running
    if ([_app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil) {
        [task resume];
        [self showDownloadViewForTask:task];
    }
}

+ (void)startBackgroundDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource  resourceName:(NSString *)name
{
    // Create download tasks
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSURL* pureUrl = resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);

    id<OADownloadTask> task = [[OsmAndApp instance].downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]
                                                                     andName:name];
    
    if ([[OsmAndApp instance].downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
        [task resume];
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

    NSMutableString* message;
    if (isUpdate)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_upd_q"),
                                    [self.class titleOfResource:resource
                                                 inRegion:item_.worldRegion
                                           withRegionName:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_inst_q"),
                                    [self.class titleOfResource:resource
                                                 inRegion:item_.worldRegion
                                           withRegionName:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes")
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

- (void)offerDeleteResourceOf:(LocalResourceItem*)item executeAfterSuccess:(dispatch_block_t)block
{
    //BOOL isInstalled = (std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(item.resource) != nullptr);
    BOOL isInstalled = (item.worldRegion != nil);
    
    NSMutableString* message;
    if (isInstalled)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_uninst_managed_q"),
                                    [self.class titleOfResource:item.resource
                                                       inRegion:item.worldRegion
                                                 withRegionName:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_uninst_unmanaged_q"),
                                    [self.class titleOfResource:item.resource
                                                       inRegion:item.worldRegion
                                                 withRegionName:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    
    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")]
                       otherButtonItems:[RIButtonItem itemWithLabel:isInstalled ? OALocalizedString(@"shared_string_uninstall") : OALocalizedString(@"shared_string_delete")
                                                             action:^{
                                                                 [self deleteResourceOf:item executeAfterSuccess:block];
                                                             }], nil] show];
}

- (void)offerDeleteResourceOf:(LocalResourceItem*)item
{
    [self offerDeleteResourceOf:item executeAfterSuccess:nil];
}

- (void)deleteResourceOf:(LocalResourceItem*)item executeAfterSuccess:(dispatch_block_t)block
{
    [_deleteResourceProgressHUD showAnimated:YES
                         whileExecutingBlock:^{
                             const auto success = _app.resourcesManager->uninstallResource(item.resourceId);
                             if (!success)
                             {
                                 OALog(@"Failed to uninstall resource %@ from %@",
                                       item.resourceId.toNSString(),
                                       item.resource->localPath.toNSString());
                             } else if (block) {
                                 block();
                             }
                         }];
}

- (void)deleteResourceOf:(LocalResourceItem*)item
{
    [self deleteResourceOf:item executeAfterSuccess:nil];
}

- (void)showDetailsOf:(LocalResourceItem*)item
{
    /*
    NSString* resourceId = item.resourceId.toNSString();
    [self.navigationController pushViewController:[[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId]
                                         animated:YES];
    */
}

- (void)onItemClicked:(id)senderItem
{
    //OAWorldRegion* reg = self.region;
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
            //LocalResourceItem* item = (LocalResourceItem*)item_;

            //[self showDetailsOf:item];
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
        
        if (!self.downloadView || !self.downloadView.superview)
            [self showDownloadViewForTask:task];
        
        [self.downloadView setProgress:[value floatValue]];
        //[self refreshContent:NO];
        [self refreshDownloadingContent:task.key];
        
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
        
        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0) {
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

- (void) updateTableLayout
{
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

- (void)downloadProgressViewDidAppear:(OADownloadProgressView *)view
{
    [self updateTableLayout];
}

- (void)downloadProgressViewDidDisappear:(OADownloadProgressView *)view
{
    [self updateTableLayout];
}


@end
