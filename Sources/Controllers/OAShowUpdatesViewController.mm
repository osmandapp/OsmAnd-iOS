//
//  OAShowUpdatesViewController.mm
//  OsmAnd
//
//  Created by Feschenko Fedor on 5/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAShowUpdatesViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OATableViewCellWithButton.h"
#import "OATableViewCellWithClickableAccessoryView.h"
#import "OALocalResourceInformationViewController.h"
#import "UITableViewCell+getTableView.h"
#include "Localization.h"

#define _(name) OAShowUpdatesViewController__##name
#define ctor _(ctor)

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

@interface OAShowUpdatesViewController ()

@property OAWorldRegion *worldRegion;

@end

@implementation OAShowUpdatesViewController
{
    OsmAndAppInstance _app;
    
    NSMutableArray* _downloadItems;
    
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
    
    _downloadItems = [[NSMutableArray alloc] init];
    
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.delegate = self;
    
    _tableView.dataSource = self;
    
    ((OADownloadsTabBarViewController *)self.tabBarController).refreshBtnDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Deselect previously selected rows
    for (NSIndexPath *selectedIndexPath in [_tableView indexPathsForSelectedRows])
    {
        [_tableView deselectRowAtIndexPath:selectedIndexPath
                                  animated:animated];
    }
    
    [self reloadList];
}

- (void)reloadList
{
    [self loadDynamicContent];
    [_tableView reloadData];
}

- (void)loadDynamicContent
{
    [_downloadItems removeAllObjects];
    const auto& outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    NSArray *keysOfDownloadTasks = [_app.downloadsManager keysOfDownloadTasks];
    for (const auto& resource : outdatedResources)
    {
        NSString *resourceID = resource->id.toNSString();
        BOOL isDownloading = false;
        
        for (NSString *key : keysOfDownloadTasks) {
            if ([resourceID isEqualToString:[[key componentsSeparatedByString:@":"] objectAtIndex:1]]) {
                isDownloading = true;
                break;
            }
        }
        
        if (isDownloading) {
            continue;
        }
                 
        OutdatedItem *outdatedItem = [[OutdatedItem alloc] init];
        outdatedItem.localResource = resource;
        
        const auto& resourceInRepository = resourcesInRepository.constFind(resource->id);
        outdatedItem.resourceInRepository = (*resourceInRepository);
        
        outdatedItem.caption = [self titleOfResourceId:resourceID];
        
        [_downloadItems addObject:outdatedItem];
    }
    [_downloadItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        BaseDownloadItem *item1 = obj1;
        BaseDownloadItem *item2 = obj2;
        
        return [item1.caption localizedCaseInsensitiveCompare:item2.caption];
    }];
}

- (void)startDownloadOf:(BaseDownloadItem *)item
{
    // Create download tasks
    NSURLRequest *request = [NSURLRequest requestWithURL:item.resourceInRepository->url.toNSURL()];
    id <OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:item.resourceInRepository->id.toNSString()]];
    
    // Resume task finally
    [task resume];
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadList];
    });
}

- (BOOL)isValidResourceForRegion:(NSString *)resourceId
{
    return [resourceId hasPrefix:_worldRegion.superregion == nil ? @"world_" : [_worldRegion.regionId stringByAppendingString:@"."]];
}

- (NSString *)titleOfResourceId:(NSString *)resourceId
{
    NSArray *regions = [_app.worldRegion flattenedSubregions];
    NSRange rangeOfPoint = [resourceId rangeOfString:@"."];
    if (rangeOfPoint.location != NSNotFound) {
        for (OAWorldRegion *region : regions) {
            if ([region.regionId isEqualToString:[resourceId substringToIndex:rangeOfPoint.location]]) {
                return region.name;
            }
        }
    }
    
    return @"";
}


- (BOOL)regionOrAnySubregionOf:(OAWorldRegion *)region
            isDownloadableFrom:(const QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> >&)resourcesInRepository
{
    const auto& regionId = QString::fromNSString(region.regionId);
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        if (!resourceInRepository->id.startsWith(regionId))
            continue;
        
        return YES;
    }
    
    for (OAWorldRegion *subregion in region.subregions)
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_downloadItems count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([_downloadItems count] == 0)
        return OALocalizedString(@"There is no available updates");
    
    return OALocalizedString(@"Available updates");
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([_downloadItems count] == 0) {
        return nil;
    }
    
    UIButton *updateAllButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [updateAllButton setTitle:OALocalizedString(@"Update all") forState:UIControlStateNormal];
    [updateAllButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [updateAllButton addTarget: self
                        action: @selector(updateAllButtonClicked:)
              forControlEvents: UIControlEventTouchUpInside];
    
    return updateAllButton;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Obtain reusable cell or create one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"outdatedItemCell"];
    if (cell == nil)
    {
        cell = [[OATableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault
                                                  andButtonType:UIButtonTypeSystem
                                                reuseIdentifier:@"outdatedItemCell"];
        OATableViewCellWithButton *cellWithButton = (OATableViewCellWithButton*)cell;
        UIImage *iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
        [cellWithButton.buttonView setImage:iconImage
                                   forState:UIControlStateNormal];
        cellWithButton.buttonView.frame = CGRectMake(0.0f, 0.0f,
                                                     iconImage.size.width, iconImage.size.height);
    }
    
    // Fill cell content
    cell.textLabel.text = ((OutdatedItem *)[_downloadItems objectAtIndex:indexPath.row]).caption;
    
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
    OutdatedItem *item = [_downloadItems objectAtIndex:indexPath.row];
    
    [[[UIAlertView alloc] initWithTitle:nil
                                message:[NSString stringWithFormat:OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded. %3$@Proceed?"),
                                         [tableView cellForRowAtIndexPath:indexPath].textLabel.text,
                                         [NSByteCountFormatter stringFromByteCount:item.resourceInRepository->packageSize
                                                                        countStyle:NSByteCountFormatterCountStyleFile],
                                         [Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN ? OALocalizedString(@"HEY YOU'RE ON 3G!!! ") : @""]
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update")
                                                             action:^{
                                                                 [self startDownloadOf:item];
                                                                 [self reloadList];
                                                             }], nil] show];
    
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

#pragma mark - Actions

- (void)updateAllButtonClicked:(id)sender {
    ByteCount count = 0L;
    for (OutdatedItem *item in _downloadItems) {
        count+=item.resourceInRepository->packageSize;
    }
    [[[UIAlertView alloc] initWithTitle:nil
                                message:[NSString stringWithFormat:OALocalizedString(@"An update is available for %1$d elements. %2$@ will be downloaded. %3$@Proceed?"),
                                         [_downloadItems count],
                                         [NSByteCountFormatter stringFromByteCount:count
                                                                        countStyle:NSByteCountFormatterCountStyleFile],
                                         [Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN ? OALocalizedString(@"HEY YOU'RE ON 3G!!! ") : @""]
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update")
                                                             action:^{
                                                                 for (OutdatedItem *item in _downloadItems) {
                                                                     [self startDownloadOf:item];
                                                                 }
                                                                 [self reloadList];
                                                             }], nil] show];
}

#pragma mark - OADownloadsRefreshButtonDelegate

- (void)clickedOnRefreshButton:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index
{
    if (index == 2) {
        [self reloadList];
    }
}

- (void)onViewDidLoadAction:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index
{
    
}

#pragma mark -

@end

