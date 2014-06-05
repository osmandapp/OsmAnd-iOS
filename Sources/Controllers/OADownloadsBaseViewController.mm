//
//  OADownloadsBaseViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsBaseViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OARegionDownloadsViewController.h"
#import "OATableViewCellWithButton.h"
#import "OATableViewCellWithClickableAccessoryView.h"
#import "OALocalResourceInformationViewController.h"
#import "UITableViewCell+getTableView.h"
#include "Localization.h"

#define _(name) OADownloadsBaseViewController__##name
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

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OADownloadsBaseViewController ()
@end

@implementation OADownloadsBaseViewController
{
    OsmAndAppInstance _app;

    NSInteger _lastUnusedSectionIndex;

    NSInteger _subregionsSection;
    NSMutableArray* _subregionItems;

    NSInteger _downloadsSection;
    NSMutableArray* _downloadItems;

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

    [self setupTabBar];
    
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

- (NSString*)titleOfResourceId:(NSString*)resourceId ofType:(OsmAndResourceType)type
{
    if (_worldRegion.superregion == nil)
    {
        if ([resourceId isEqualToString:@"world_basemap.map.obf"])
            return OALocalizedString(@"Detailed overview map");
        return nil;
    }

    switch(type)
    {
        case OsmAndResourceType::MapRegion:
            if ([_worldRegion.subregions count] > 0)
                return OALocalizedString(@"Full map of entire region");
            else
                return OALocalizedString(@"Full map of the region");
            break;

        default:
            return nil;
    }
}

- (BOOL)regionOrAnySubregionOf:(OAWorldRegion*)region
            isDownloadableFrom:(const QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> >&)resourcesInRepository
{
    const auto& regionId = QString::fromNSString(region.regionId);
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        if (!resourceInRepository->id.startsWith(regionId))
            continue;

        return YES;
    }

    for (OAWorldRegion* subregion in region.subregions)
    {
        if (![self regionOrAnySubregionOf:subregion
                       isDownloadableFrom:resourcesInRepository])
        {
            continue;
        }

        return YES;
    }

    return NO;
}

- (void)obtainSubregionItems
{
    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    [_subregionItems removeAllObjects];
    for(OAWorldRegion* subregion in _worldRegion.subregions)
    {
        // Verify that subregion has at least one download for itself or at least one of it's subregions
        if (![self regionOrAnySubregionOf:subregion
                       isDownloadableFrom:resourcesInRepository])
        {
            continue;
        }

        [_subregionItems addObject:subregion];
    }
    [_subregionItems sortUsingSelector:@selector(compare:)];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionsCount = 0;

    if (_subregionsSection >= 0)
        sectionsCount++;
    if (_downloadsSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _subregionsSection)
        return [_subregionItems count];
    if (section == _downloadsSection)
        return [_downloadItems count];

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_worldRegion.superregion == nil)
    {
        if (section == _subregionsSection)
            return OALocalizedString(@"By regions");
        if (section == _downloadsSection)
            return OALocalizedString(@"Worldwide");
        return nil;
    }

    if (section == _subregionsSection)
        return OALocalizedString(@"Regions");
    if (section == _downloadsSection)
        return OALocalizedString(@"Downloads");

    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const subregionItemCell = @"subregionItemCell";
    static NSString* const installableItemCell = @"installableItemCell";
    static NSString* const installedItemCell = @"installedItemCell";
    static NSString* const outdatedItemCell = @"outdatedItemCell";
    static NSString* const downloadedItemCell = @"downloadedItemCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    BaseDownloadItem* downloadItem = nil;
    if (indexPath.section == _subregionsSection)
    {
        OAWorldRegion* worldRegion = [_subregionItems objectAtIndex:indexPath.row];

        cellTypeId = subregionItemCell;
        caption = worldRegion.name;
    }
    else if (indexPath.section == _downloadsSection)
    {
        downloadItem = [_downloadItems objectAtIndex:indexPath.row];

        if ([downloadItem isKindOfClass:[DownloadedItem class]])
            cellTypeId = downloadedItemCell;
        else if ([downloadItem isKindOfClass:[OutdatedItem class]])
            cellTypeId = outdatedItemCell;
        else if ([downloadItem isKindOfClass:[InstalledItem class]])
            cellTypeId = installedItemCell;
        else //if ([downloadItem isKindOfClass:[InstallableItem class]])
            cellTypeId = installableItemCell;
        caption = downloadItem.caption;
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:outdatedItemCell])
        {
            cell = [[OATableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault
                                                      andButtonType:UIButtonTypeSystem
                                                    reuseIdentifier:cellTypeId];
            OATableViewCellWithButton* cellWithButton = (OATableViewCellWithButton*)cell;
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            [cellWithButton.buttonView setImage:iconImage
                                       forState:UIControlStateNormal];
            cellWithButton.buttonView.frame = CGRectMake(0.0f, 0.0f,
                                                         iconImage.size.width, iconImage.size.height);
        }
        else if ([cellTypeId isEqualToString:installableItemCell])
        {
            cell = [[OATableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault
                                                      andButtonType:UIButtonTypeSystem
                                                    reuseIdentifier:cellTypeId];
            OATableViewCellWithButton* cellWithButton = (OATableViewCellWithButton*)cell;
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            [cellWithButton.buttonView setImage:iconImage
                                       forState:UIControlStateNormal];
            cellWithButton.buttonView.frame = CGRectMake(0.0f, 0.0f,
                                                         iconImage.size.width, iconImage.size.height);
        }
        else if ([cellTypeId isEqualToString:downloadedItemCell])
        {
            FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];
            [progressView startSpinProgressBackgroundLayer];
            cell = [[OATableViewCellWithClickableAccessoryView alloc] initWithStyle:UITableViewCellStyleDefault
                                                             andCustomAccessoryView:progressView
                                                                    reuseIdentifier:cellTypeId];
        }
        else
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];
        }
    }

    // Fill cell content
    cell.textLabel.text = caption;
    if ([cellTypeId isEqualToString:downloadedItemCell])
    {
        DownloadedItem* downloadedItem = (DownloadedItem*)downloadItem;

        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        float progressCompleted = downloadedItem.downloadTask.progressCompleted;
        if (progressCompleted >= 0.0f && downloadedItem.downloadTask.state == OADownloadTaskStateRunning)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted;
        }
        else if (downloadedItem.downloadTask.state == OADownloadTaskStateFinished)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = 1.0f;
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView selectedAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView selectedAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView selectedAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != _downloadsSection)
    return;
    
    BaseDownloadItem* item = [_downloadItems objectAtIndex:indexPath.row];
    
    NSString* itemName = nil;
    if (_worldRegion.superregion == nil)
    itemName = [_tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    else
    {
        itemName = [NSString stringWithFormat:OALocalizedString(@"%1$@ (%2$@)"),
                    [_tableView cellForRowAtIndexPath:indexPath].textLabel.text,
                    _worldRegion.name];
    }
    
    if ([item isKindOfClass:[OutdatedItem class]])
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded. %3$@Proceed?"),
                                             itemName,
                                             [NSByteCountFormatter stringFromByteCount:item.resourceInRepository->packageSize
                                                                            countStyle:NSByteCountFormatterCountStyleFile],
                                             [Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN ? OALocalizedString(@"HEY YOU'RE ON 3G!!! ") : @""]
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                           otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update")
                                                                 action:^{
                                                                     [self startDownloadOf:item];
                                                                 }], nil] show];
    }
    else if ([item isKindOfClass:[InstalledItem class]])
    {
        InstalledItem* installedItem = (InstalledItem*)item;
        
        NSString* resourceId = installedItem.localResource->id.toNSString();
        [self.navigationController pushViewController:[[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId]
                                             animated:YES];
    }
    else if ([item isKindOfClass:[InstallableItem class]])
    {
        [self checkInternetConnection:[[UIAlertView alloc] initWithTitle:nil
                                                                 message:[NSString stringWithFormat:OALocalizedString(@"Installation of %1$@ requires %2$@ to be downloaded. %3$@Proceed?"),
                                                                          itemName,
                                                                          [NSByteCountFormatter stringFromByteCount:item.resourceInRepository->packageSize
                                                                                                         countStyle:NSByteCountFormatterCountStyleFile],
                                                                          [Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN ? OALocalizedString(@"HEY YOU'RE ON 3G!!! ") : @""]
                                                        cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                                                        otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Install")
                                                                                              action:^{
                                                                                                  [self startDownloadOf:item];
                                                                                              }], nil]];
    }
    else if ([item isKindOfClass:[DownloadedItem class]])
    {
        [self checkInternetConnection:[[UIAlertView alloc] initWithTitle:nil
                                                                 message:[NSString stringWithFormat:OALocalizedString(@"You're going to cancel download of %1$@. Are you sure?"),
                                                                          itemName]
                                                        cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Continue")]
                                                        otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")
                                                                                              action:^{
                                                                                                  [self cancelDownloadOf:item];
                                                                                              }], nil]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)checkInternetConnection:(UIAlertView *)alertView
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"No Internet connection")
                                    message:OALocalizedString(@"Internet connection is required to download maps. Please check your Internet connection.")
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"OK")]
                           otherButtonItems:nil] show];
    }
    else
    {
        [alertView show];
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    UITableView* tableView = nil;
    if ([sender isKindOfClass:[OATableViewCell class]] || [[sender class] isSubclassOfClass:[OATableViewCell class]])
    {
        OATableViewCell* cell = (OATableViewCell*)sender;
        tableView = cell.tableView;
    }
    else if ([sender isKindOfClass:[UITableViewCell class]] || [[sender class] isSubclassOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)sender;
        tableView = [cell getTableView];
    }

    if (tableView == _tableView)
    {
        NSIndexPath* selectedItemPath = [_tableView indexPathForSelectedRow];

        if (selectedItemPath != nil &&
            selectedItemPath.section == _subregionsSection &&
            [identifier isEqualToString:_openSubregionSegueId])
        {
            return (selectedItemPath.row < [_subregionItems count]);
        }
    }

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UITableView* tableView = nil;
    if ([sender isKindOfClass:[OATableViewCell class]] || [[sender class] isSubclassOfClass:[OATableViewCell class]])
    {
        OATableViewCell* cell = (OATableViewCell*)sender;
        tableView = cell.tableView;
    }
    else if ([sender isKindOfClass:[UITableViewCell class]] || [[sender class] isSubclassOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)sender;
        tableView = [cell getTableView];
    }

    if (tableView == _tableView)
    {
        NSIndexPath* selectedItemPath = [_tableView indexPathForSelectedRow];

        if (selectedItemPath != nil &&
            selectedItemPath.section == _subregionsSection &&
            [segue.identifier isEqualToString:_openSubregionSegueId])
        {
            OARegionDownloadsViewController* regionDownloadsViewController = [segue destinationViewController];
            regionDownloadsViewController.worldRegion = [_subregionItems objectAtIndex:selectedItemPath.row];
        }
    }
}

#pragma mark - Tab bar configurating

- (void)setupTabBar
{
    UITabBar *tabBar = [self tabBarController].tabBar;
    
    UITabBarItem *tab = [tabBar.items objectAtIndex:0];
    tab.image = [[UIImage imageNamed:@"tab_regions_icon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.selectedImage = [[UIImage imageNamed:@"tab_regions_icon_filled.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.title = OALocalizedString(@"Regions");
    
    tab = [tabBar.items objectAtIndex:1];
    tab.image = [[UIImage imageNamed:@"tab_downloads_icon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.selectedImage = [[UIImage imageNamed:@"tab_downloads_icon_filled.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.title = OALocalizedString(@"Downloads");
    
    tab = [tabBar.items objectAtIndex:2];
    tab.image = [[UIImage imageNamed:@"tab_updates_icon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.selectedImage = [[UIImage imageNamed:@"tab_updates_icon_filled.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    tab.title = OALocalizedString(@"Updates");
}

#pragma mark -

@end
