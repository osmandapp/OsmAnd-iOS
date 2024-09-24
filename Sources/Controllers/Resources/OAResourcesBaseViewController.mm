//
//  OAResourcesBaseViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAResourcesBaseViewController.h"
#import <MBProgressHUD.h>
#import "OAAutoObserverProxy.h"
#import "OAWorldRegion.h"
#import "OADownloadsManager.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OACustomSourceDetailsViewController.h"
#import "OAPlugin.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OANauticalMapsPlugin.h"
#import "Localization.h"
#import "OASearchResult.h"
#import "OAWeatherHelper.h"
#import "OAWikipediaPlugin.h"
#import "OAChoosePlanHelper.h"
#import "OAIndexConstants.h"
#import "OAPluginsHelper.h"
#import "OADownloadTask.h"
#import "OsmAndApp.h"

#include <OsmAndCore/WorldRegions.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
typedef OsmAnd::IncrementalChangesManager::IncrementalUpdate IncrementalUpdate;

static BOOL dataInvalidated = NO;


@interface OASuspendedDownloadTask : NSObject
@property id<OADownloadTask> task;
@property id<OADownloadTask> nextTask;
@end

@implementation OASuspendedDownloadTask
@end


@interface OAResourcesBaseViewController ()

@end

@implementation OAResourcesBaseViewController
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;

    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _repositoryUpdatedObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _sqlitedbResourcesChangedObserver;

    OAAutoObserverProxy *_backgroundStateObserver;

    MBProgressHUD* _deleteResourceProgressHUD;
    NSMutableArray<OASuspendedDownloadTask *> *_finishedBackgroundDownloadings;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];
        _finishedBackgroundDownloadings = [NSMutableArray array];

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

        _backgroundStateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onBackgroundStateChanged)
                                                              andObserve:OsmAndApp.instance.backgroundStateObservable];

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
                if (item.resourceId == QString::fromUtf8(kWorldSeamarksKey))
                {
                    return NSOrderedAscending;
                }
                if (item.resourceId.startsWith(QStringLiteral("world_")))
                {
                    str1 = [NSString stringWithFormat:@"!%@%d", item.title, item.resourceType];
                }
                else
                {
                    NSString *countryName = [OAResourcesUIHelper getCountryName:item];
                    str1 = countryName ? [NSString stringWithFormat:@"%@ - %@%d", countryName, item.title, item.resourceType] : [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
                }
            }

            if ([obj2 isKindOfClass:[OAWorldRegion class]])
            {
                str2 = ((OAWorldRegion *)obj2).name;
            }
            else
            {
                OAResourceItem *item = obj2;
                if (item.resourceId == QString::fromUtf8(kWorldSeamarksKey))
                {
                    return NSOrderedDescending;
                }
                if (item.resourceId.startsWith(QStringLiteral("world_")))
                {
                    str2 = [NSString stringWithFormat:@"!%@%d", item.title, item.resourceType];
                }
                else
                {
                    NSString *countryName = [OAResourcesUIHelper getCountryName:item];
                    str2 = countryName ? [NSString stringWithFormat:@"%@ - %@%d", countryName, item.title, item.resourceType] : [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
                }
            }
            
            return [str1 localizedCaseInsensitiveCompare:str2];
        };
    }
    return self;
}

- (void) dealloc
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
}

- (void)updateContent
{
}

- (void) refreshContent:(BOOL)update
{
}

- (void) updateDisplayItem:(OAResourceItem *)item
{
}

- (void) downloadCustomItem:(OACustomResourceItem *)item
{
    [OAResourcesUIHelper startDownloadOfCustomItem:item onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
    }];
}

- (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item
{
    [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:^(id<OADownloadTask> task) {
            [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
    }];
}

- (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item
{
    if (item.resourceType == OsmAndResourceType::WeatherForecast)
    {
        OARepositoryResourceItem *repositoryItem = [[OARepositoryResourceItem alloc] init];
        repositoryItem.resourceId = item.resourceId;
        repositoryItem.resourceType = item.resourceType;
        repositoryItem.title = item.title;
        repositoryItem.size = item.size;
        repositoryItem.sizePkg = item.sizePkg;
        repositoryItem.worldRegion = item.worldRegion;
        repositoryItem.date = item.date;

        [self offerDownloadAndInstallOf:repositoryItem];
        return;
    }

    [OAResourcesUIHelper offerDownloadAndUpdateOf:item onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
    }];
}

- (void) startDownloadOfItem:(OARepositoryResourceItem *)item
{
    [OAResourcesUIHelper startDownloadOfItem:item onTaskCreated:^(id<OADownloadTask>  _Nonnull task) {
        [self updateContent];
    } onTaskResumed:nil];
}

- (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
            resourceName:(NSString *)name
            resourceItem:(OAResourceItem *)resourceItem
{
    [OAResourcesUIHelper startDownloadOf:resource resourceName:name resourceItem:nil onTaskCreated:^(id<OADownloadTask> _Nonnull task) {
        [self updateContent];
    } onTaskResumed:nil];
}

- (void) offerCancelDownloadOf:(OAResourceItem *)item_
{
    [OAResourcesUIHelper offerCancelDownloadOf:item_ onTaskStop:nil];
}

- (void) offerDeleteResourceOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)onComplete
{
    BOOL isWeatherForecast = item.resourceType == OsmAndResourceType::WeatherForecast;
    dispatch_block_t onComplete_ = ^{
        if (!isWeatherForecast)
            [self.region.superregion updateGroupItems:self.region type:[OAResourceType toValue:item.resourceType]];

        if (onComplete)
            onComplete();

        if (isWeatherForecast)
        {
            [self updateDisplayItem:item];
            [[OAWeatherHelper sharedInstance] calculateCacheSize:self.region onComplete:nil];
        }
    };
    [OAResourcesUIHelper offerDeleteResourceOf:item viewController:self progressHUD:_deleteResourceProgressHUD executeAfterSuccess:onComplete_];
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
    if ([senderItem isKindOfClass:[OAResourceItem class]] || [senderItem isKindOfClass:[OASearchResult class]])
    {
        OAResourceItem* item_ = (OAResourceItem *) ([senderItem isKindOfClass:OASearchResult.class] ? ((OASearchResult *) senderItem).relatedObject : senderItem);

        if (item_.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:item_];
        }
        else if ([item_ isKindOfClass:[OAOutdatedResourceItem class]] && item_.resourceType != OsmAndResourceType::WeatherForecast)
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
            
            if (item.resource && [item isFree])
                return [self offerDownloadAndInstallOf:item];
            
            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion || item.resourceType == OsmAndResourceType::HeightmapRegionLegacy || item.resourceType == OsmAndResourceType::GeoTiffRegion) && ![_iapHelper.srtm isActive])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
            else if (item.resourceType == OsmAndResourceType::WikiMapRegion && ![_iapHelper.wiki isActive])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            else if ((item.resourceType == OsmAndResourceType::DepthContourRegion || item.resourceType == OsmAndResourceType::DepthMapRegion) && ![OAIAPHelper isDepthContoursPurchased])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_DepthContours];
            else if ((item.resourceType == OsmAndResourceType::DepthContourRegion || item.resourceType == OsmAndResourceType::DepthMapRegion) && ![OAPluginsHelper isEnabled:OANauticalMapsPlugin.class])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Nautical];
            else if (item.resourceType == OsmAndResourceType::MapRegion && [item.worldRegion.regionId isEqualToString:OsmAnd::WorldRegions::NauticalRegionId.toNSString()] && ![OAPluginsHelper isEnabled:OANauticalMapsPlugin.class])
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Nautical];
            else if ([item.worldRegion.regionId isEqualToString:OsmAnd::WorldRegions::TravelRegionId.toNSString()] && ![OAPluginsHelper isEnabled:OAWikipediaPlugin.class])
            {
                if ([_iapHelper.wiki isPurchased])
                    [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
                else
                    [OAChoosePlanHelper showChoosePlanScreenWithProduct:_iapHelper.wiki navController:self.navigationController];
            }
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
        if (!self.isViewLoaded || self.view.window == nil || _app.isInBackgroundOnDevice)
        {
            self.dataInvalidated = YES;
            return;
        }

        [self updateContent];
    });
}

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *nsResourceId = [task.key substringFromIndex:[@"resource:" length]];
        const auto resourceId = QString::fromNSString(nsResourceId);
        const auto resource = _app.resourcesManager->getResource(resourceId);

        if (!self.isViewLoaded || self.view.window == nil)
        {
            if (task.progressCompleted == 1. && ![nsResourceId hasSuffix:@".live.obf"])
                [_app.data.mapLayerChangeObservable notifyEvent];

            self.dataInvalidated = YES;
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
        
        id<OADownloadTask> nextTask = nil;
        if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            nextTask = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
        
        if (task.progressCompleted < 1.0)
        {
            if (nextTask)
                [nextTask resume];
        }
        else
        {
            if ((resource != nullptr && resource->type == OsmAndResourceType::MapRegion)
                || (resource == nullptr && [nsResourceId hasSuffix:@".live.obf"]))
                [_app.data.mapLayerChangeObservable notifyEvent];
        }
        
        OASuspendedDownloadTask *suspendedTask = [[OASuspendedDownloadTask alloc] init];
        suspendedTask.task = task;
        suspendedTask.nextTask = nextTask;
        if (_app.isInBackgroundOnDevice)
            [_finishedBackgroundDownloadings addObject:suspendedTask];
        else
            [self refreshUIOnTaskFinished:suspendedTask];

    });
}

- (void)refreshUIOnTaskFinished:(OASuspendedDownloadTask *)suspendedTask
{
    if (suspendedTask.task.progressCompleted < 1.0)
    {
        [self updateContent];
    }
    else
    {
        // TODO: FIX
        //[self refreshDownloadingContent:suspendedTask.task.key];
    }
}

- (void) onBackgroundStateChanged
{
    if (!_app.isInBackgroundOnDevice)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            while (_finishedBackgroundDownloadings && _finishedBackgroundDownloadings.count > 0)
            {
                OASuspendedDownloadTask *suspendedTask = [_finishedBackgroundDownloadings firstObject];
                [self refreshUIOnTaskFinished:suspendedTask];
                [_finishedBackgroundDownloadings removeObjectAtIndex:0];
            }

            if (self.dataInvalidated || dataInvalidated)
            {
                [self updateContent];
                self.dataInvalidated = NO;
                dataInvalidated = NO;
            }


            [self updateContent];
            [self.getTableView reloadData];
            // TODO: FIX
            //[self refreshDownloadingContent:nil]; // restart all cells animations
        });
    }
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
