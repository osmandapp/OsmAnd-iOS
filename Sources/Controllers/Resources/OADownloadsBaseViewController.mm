//
//  OADownloadsBaseViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsBaseViewController.h"


#define ctor _(ctor)
#define dtor _(dtor)

#define BaseDownloadItem _(BaseDownloadItem)
@interface BaseDownloadItem : NSObject
@property NSString* caption;
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resourceInRepository;
@end
@implementation BaseDownloadItem
@end

#define InstallableItem _(InstallableItem)
@interface InstallableItem : BaseDownloadItem
@end
@implementation InstallableItem
@end

#define InstalledItem _(InstalledItem)
@interface InstalledItem : BaseDownloadItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> localResource;
@end
@implementation InstalledItem
@end

#define OutdatedItem _(OutdatedItem)
@interface OutdatedItem : InstalledItem
@end
@implementation OutdatedItem
@end

#define DownloadedItem _(DownloadedItem)
@interface DownloadedItem : BaseDownloadItem
@property id<OADownloadTask> downloadTask;
@end
@implementation DownloadedItem
@end



@interface OADownloadsBaseViewController ()
@end

@implementation OADownloadsBaseViewController
{
    NSString* _openSubregionSegueId;

    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _app = [OsmAndApp instance];

    _worldRegion = nil;

    _lastUnusedSectionIndex = 0;

    _subregionsSection = -1;
    _subregionItems = [[NSMutableArray alloc] init];

    _downloadsSection = -1;
    _downloadItems = [[NSMutableArray alloc] init];

    _openSubregionSegueId = @"openSubregion";

    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
}

@synthesize tableView = _tableView;

@synthesize worldRegion = _worldRegion;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load dynamic content
    [self reloadDynamicContent];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Deselect previously selected rows
    for(NSIndexPath* selectedIndexPath in [_tableView indexPathsForSelectedRows])
    {
        [_tableView deselectRowAtIndexPath:selectedIndexPath
                                  animated:animated];
    }
}

- (void)reloadList
{
    [self reloadDynamicContent];
    [_tableView reloadData];
}

- (void)reloadDynamicContent
{
    _lastUnusedSectionIndex = 0;
    [self loadDynamicContent];
}

- (void)loadDynamicContent
{
    [self obtainSubregionItems];
    if ([_subregionItems count] > 0)
        _subregionsSection = [self allocateSection];
    else
        _subregionsSection = -1;

    [self obtainDownloadItems];
    if ([_downloadItems count] > 0)
        _downloadsSection = [self allocateSection];
    else
        _downloadsSection = -1;
}

- (NSInteger)allocateSection
{
    return _lastUnusedSectionIndex++;
}

- (void)startDownloadOf:(BaseDownloadItem*)item
{
    // Create download tasks
    NSURLRequest* request = [NSURLRequest requestWithURL:item.resourceInRepository->url.toNSURL()];
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:item.resourceInRepository->id.toNSString()]];
    [self obtainDownloadItems];

    // Reload this item in the table
    NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[DownloadedItem class]])
            return NO;

        DownloadedItem* downloaded = (DownloadedItem*)obj;
        if (downloaded.downloadTask != task)
            return NO;

        *stop = YES;
        return YES;
    }];
    NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                    inSection:_downloadsSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:itemIndexPath]
                      withRowAnimation:UITableViewRowAnimationAutomatic];

    // Resume task finally
    [task resume];
}

- (void)cancelDownloadOf:(BaseDownloadItem*)item
{
    DownloadedItem* downloadedItem = (DownloadedItem*)item;

    [downloadedItem.downloadTask cancel];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSNumber* progressCompleted = (NSNumber*)value;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;

        NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[DownloadedItem class]])
                return NO;

            DownloadedItem* downloadedItem = (DownloadedItem*)obj;
            if (downloadedItem.downloadTask != task)
                return NO;

            *stop = YES;
            return YES;
        }];
        NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                        inSection:_downloadsSection];
        UITableViewCell* itemCell = [_tableView cellForRowAtIndexPath:itemIndexPath];
        FFCircularProgressView* progressView = (FFCircularProgressView*)itemCell.accessoryView;

        [progressView stopSpinProgressBackgroundLayer];
        progressView.progress = [progressCompleted floatValue];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString* localPath = task.targetPath;

    BOOL needsManualRowReload = YES;

    if (localPath != nil && task.state == OADownloadTaskStateFinished)
    {
        const auto& filePath = QString::fromNSString(localPath);
        bool ok = false;

        // Try to install only in case of successful download
        if (task.error == nil)
        {
            // Install or update given resource
            const auto& resourceId = QString::fromNSString([task.key substringFromIndex:[@"resource:" length]]);
            ok = _app.resourcesManager->updateFromFile(resourceId, filePath);
            if (!ok)
                ok = _app.resourcesManager->installFromRepository(resourceId, filePath);
        }

        [[NSFileManager defaultManager] removeItemAtPath:task.targetPath error:nil];

        needsManualRowReload = !ok;
    }

    if (needsManualRowReload)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isViewLoaded)
                return;

            [self obtainDownloadItems];

            NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if (![obj isKindOfClass:[DownloadedItem class]])
                    return NO;

                DownloadedItem* downloadedItem = (DownloadedItem*)obj;
                if (downloadedItem.downloadTask != task)
                    return NO;

                *stop = YES;
                return YES;
            }];
            NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                            inSection:_downloadsSection];

            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:itemIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadList];
    });
}

- (BOOL)isValidResourceForRegion:(NSString*)resourceId
{
    return [resourceId hasPrefix:_worldRegion.superregion == nil ? @"world_" : [_worldRegion.regionId stringByAppendingString:@"."]];
}


- (void)obtainDownloadItems
{
    [_downloadItems removeAllObjects];
    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    const auto& outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
    const auto& localResources = _app.resourcesManager->getLocalResources();
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        NSString* resourceId = resourceInRepository->id.toNSString();
        if (![self isValidResourceForRegion:resourceId])
            continue;

        BaseDownloadItem* item = nil;
        if (item == nil)
        {
            id<OADownloadTask> downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
            if (downloadTask != nil && (downloadTask.state != OADownloadTaskStateFinished))
            {
                DownloadedItem* downloadedItem = [[DownloadedItem alloc] init];
                downloadedItem.downloadTask = downloadTask;

                [_downloadTaskProgressObserver observe:downloadTask.progressCompletedObservable];
                [_downloadTaskCompletedObserver observe:downloadTask.completedObservable];

                item = downloadedItem;
            }
        }
        if (item == nil)
        {
            const auto& itOutdatedResource = outdatedResources.constFind(resourceInRepository->id);
            if (itOutdatedResource != outdatedResources.cend())
            {
                OutdatedItem* outdatedItem = [[OutdatedItem alloc] init];
                outdatedItem.localResource = (*itOutdatedResource);

                item = outdatedItem;
            }
        }
        if (item == nil)
        {
            const auto& itLocalResource = localResources.constFind(resourceInRepository->id);
            if (itLocalResource != localResources.cend())
            {
                InstalledItem* installedItem = [[InstalledItem alloc] init];
                installedItem.localResource = (*itLocalResource);

                item = installedItem;
            }
        }
        if (item == nil)
            item = [[InstallableItem alloc] init];

        item.resourceInRepository = resourceInRepository;
        item.caption = [self titleOfResourceId:resourceId ofType:resourceInRepository->type];
        if (item.caption == nil)
            continue;

        [_downloadItems addObject:item];
    }
    [_downloadItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        BaseDownloadItem* item1 = obj1;
        BaseDownloadItem* item2 = obj2;

        return [item1.caption localizedCaseInsensitiveCompare:item2.caption];
    }];
}



@end
