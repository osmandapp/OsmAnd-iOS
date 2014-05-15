//
//  OADownloadsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>

#import "OsmAndApp.h"
#import "OATableViewCellWithButton.h"
#import "OARegionDownloadsViewController.h"
#import "UIViewController+OARootViewController.h"
#import "OADownloadsManager.h"
#include "Localization.h"

#define _(name) OADownloadsViewController__##name

#define Item_ResourceInRepository _(Item_ResourceInRepository)
@interface Item_ResourceInRepository : NSObject
@property NSString* caption;
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resourceInRepository;
@end
@implementation Item_ResourceInRepository
@end

#define Item_OutdatedResource _(Item_OutdatedResource)
@interface Item_OutdatedResource : Item_ResourceInRepository
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> localResource;
@end
@implementation Item_OutdatedResource
@end

#define Item_InstalledResource _(Item_InstalledResource)
@interface Item_InstalledResource : Item_ResourceInRepository
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> localResource;
@end
@implementation Item_InstalledResource
@end

#define Item_DownloadingResource _(Item_DownloadingResource)
@interface Item_DownloadingResource : Item_ResourceInRepository
@property id<OADownloadTask> downloadTask;
@end
@implementation Item_DownloadingResource
@end

@interface OADownloadsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateActivityIndicator;

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _isRefreshingList;

    NSArray* _mainWorldRegions;
    NSArray* _worldwideResourceItems;

    UIBarButtonItem* _refreshBarButton;
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

    _isRefreshingList = NO;

    _mainWorldRegions = [[NSMutableArray alloc] init];
    _worldwideResourceItems = [[NSMutableArray alloc] init];

    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(onUpdateRepositoryAndRefresh)];

    // These don't change unless application is updated
    [self obtainRootWorldRegions];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add a button to refresh repository
    self.navigationItem.rightBarButtonItem = _refreshBarButton;

    // Update repository if needed or load from cache
    if (_app.resourcesManager->isRepositoryAvailable())
        [self reloadListFromRepositoryCache];
    else
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self updateRepositoryAndReloadListAnimated];
        else
            [self showNoInternetAlert];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // Deselect everything
    [self.tableView beginUpdates];
    for(NSIndexPath* selectedIndexPath in [self.tableView indexPathsForSelectedRows])
    {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath
                                      animated:NO];
    }
    [self.tableView endUpdates];

}

- (void)showNoInternetAlert
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"No Internet connection")
                                message:OALocalizedString(@"Internet connection is required to download maps and other resources. Please check your Internet connection.")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"OK")
                                                             action:^{
                                                                 OAOptionsPanelViewController* menuHostViewController = (OAOptionsPanelViewController*)self.menuHostViewController;
                                                                 [menuHostViewController dismissLastOpenedMenuAnimated:YES];
                                                             }]
                       otherButtonItems:nil] show];
}

- (void)onUpdateRepositoryAndRefresh
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepositoryAndReloadListAnimated];
    else
        [self showNoInternetAlert];
}

- (void)obtainRootWorldRegions
{
    _mainWorldRegions = [_app.worldRegion.subregions sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        OAWorldRegion* worldRegion1 = obj1;
        OAWorldRegion* worldRegion2 = obj2;

        NSString* name1 = worldRegion1.localizedName;
        if (name1 == nil)
            name1 = worldRegion1.nativeName;

        NSString* name2 = worldRegion2.localizedName;
        if (name2 == nil)
            name2 = worldRegion2.nativeName;

        return [name1 localizedCaseInsensitiveCompare:name2];
    }];
}

- (void)obtainResourceItems
{
    NSMutableArray* resourceItems = [[NSMutableArray alloc] init];

    const auto& resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    const auto& outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
    const auto& localResources = _app.resourcesManager->getLocalResources();
    for(const auto& resourceInRepository : resourcesInRepository)
    {
        const auto& resourceId = resourceInRepository->id;
        if (!resourceId.startsWith(QLatin1String("world_")))
            continue;

        Item_ResourceInRepository* item = nil;
        if (item == nil)
        {
            id<OADownloadTask> downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId.toNSString()]] firstObject];
            if (downloadTask != nil)
            {
                Item_DownloadingResource* downloadingItem = [[Item_DownloadingResource alloc] init];
                downloadingItem.downloadTask = downloadTask;

                item = downloadingItem;
            }
        }
        if (item == nil)
        {
            const auto& itOutdatedResource = outdatedResources.constFind(resourceId);
            if (itOutdatedResource != outdatedResources.cend())
            {
                Item_OutdatedResource* outdatedItem = [[Item_OutdatedResource alloc] init];
                outdatedItem.localResource = (*itOutdatedResource);

                item = outdatedItem;
            }
        }
        if (item == nil)
        {
            const auto& itLocalResource = localResources.constFind(resourceId);
            if (itLocalResource != localResources.cend())
            {
                Item_InstalledResource* installedItem = [[Item_InstalledResource alloc] init];
                installedItem.localResource = (*itLocalResource);

                item = installedItem;
            }
        }
        if (item == nil)
            item = [[Item_ResourceInRepository alloc] init];

        item.resourceInRepository = resourceInRepository;
        if (resourceId == QLatin1String("world_basemap.map.obf"))
            item.caption = OALocalizedString(@"Detailed overview map");
        else
            item.caption = resourceId.toNSString();

        [resourceItems addObject:item];
    }
    [resourceItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Item_ResourceInRepository* item1 = obj1;
        Item_ResourceInRepository* item2 = obj2;

        return [item1.caption localizedCaseInsensitiveCompare:item2.caption];
    }];

    _worldwideResourceItems = resourceItems;
}

- (void)updateRepositoryAndReloadListAnimated
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _isRefreshingList = YES;
            _refreshBarButton.enabled = NO;
            [self.tableView reloadData];
            [self.updateActivityIndicator startAnimating];
        });

        _app.resourcesManager->updateRepository();

        dispatch_async(dispatch_get_main_queue(), ^{
            _isRefreshingList = NO;
            [self obtainResourceItems];
            [self.updateActivityIndicator stopAnimating];
            [self.tableView reloadData];
            _refreshBarButton.enabled = YES;
        });
    });
}

- (void)reloadListFromRepositoryCache
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self obtainResourceItems];
        [self.tableView reloadData];
    });
}

- (void)startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resourceInRepository
{
    NSURLRequest* request = [NSURLRequest requestWithURL:resourceInRepository->url.toNSURL()];

    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:resourceInRepository->id.toNSString()]];
    [task resume];
}

#define kMainWorldRegionsSection 0
#define kWorldwideDownloadItemsSection 1

#pragma mark - OAMenuViewControllerProtocol

@synthesize menuHostViewController = _menuHostViewController;

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isRefreshingList)
        return 0; // No sections at all

    return 2 /* 'By regions', 'Worldwide' */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isRefreshingList)
        return 0; // No rows at all

    switch (section)
    {
        case kMainWorldRegionsSection:
            return [_mainWorldRegions count];

        case kWorldwideDownloadItemsSection:
            return [_worldwideResourceItems count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kMainWorldRegionsSection:
            return OALocalizedString(@"By regions");

        case kWorldwideDownloadItemsSection:
            return OALocalizedString(@"Worldwide");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const installableItemCell = @"installableItemCell";
    static NSString* const outdatedItemCell = @"outdatedItemCell";
    static NSString* const installedItemCell = @"installedItemCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    if (indexPath.section == kMainWorldRegionsSection)
    {
        OAWorldRegion* worldRegion = [_mainWorldRegions objectAtIndex:indexPath.row];

        cellTypeId = submenuCell;
        caption = worldRegion.localizedName;
        if (caption == nil)
            caption = worldRegion.nativeName;
    }
    else if (indexPath.section == kWorldwideDownloadItemsSection)
    {
        Item_ResourceInRepository* item = [_worldwideResourceItems objectAtIndex:indexPath.row];
        if ([item isKindOfClass:[Item_DownloadingResource class]])
        {
            cellTypeId = installableItemCell;
        }
        else if ([item isKindOfClass:[Item_OutdatedResource class]])
            cellTypeId = outdatedItemCell;
        else if ([item isKindOfClass:[Item_InstalledResource class]])
            cellTypeId = installedItemCell;
        else
            cellTypeId = installableItemCell;
        caption = item.caption;
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
        else
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];
        }
    }

    // Fill cell content
    cell.textLabel.text = caption;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kWorldwideDownloadItemsSection)
        return;

    Item_ResourceInRepository* item = [_worldwideResourceItems objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[Item_InstalledResource class]])
    {
        //TODO: open info segue
    }
    else
    {
        NSString* itemTitle = [_tableView cellForRowAtIndexPath:indexPath].textLabel.text;

        if ([item isKindOfClass:[Item_OutdatedResource class]])
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded. Proceed?"),
                                                 itemTitle,
                                                 [NSByteCountFormatter stringFromByteCount:item.resourceInRepository->packageSize
                                                                                countStyle:NSByteCountFormatterCountStyleFile]]
                               cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                               otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Update")
                                                                     action:^{
                                                                         [self startDownloadOf:item.resourceInRepository];
                                                                     }], nil] show];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:OALocalizedString(@"Installation of %1$@ requires %2$@ to be downloaded. Proceed?"),
                                                 itemTitle,
                                                 [NSByteCountFormatter stringFromByteCount:item.resourceInRepository->packageSize
                                                                                countStyle:NSByteCountFormatterCountStyleFile]]
                               cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                               otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Install")
                                                                     action:^{
                                                                         [self startDownloadOf:item.resourceInRepository];
                                                                     }], nil] show];
        }
    }
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow only selection in world regions
    if (indexPath.section != kMainWorldRegionsSection)
        return nil;

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kMainWorldRegionsSection)
        return;

    // Open region that was selected
    OAWorldRegion* worldRegion = [_mainWorldRegions objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"openRegion" sender:worldRegion];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"openRegion"] && [sender isKindOfClass:[OAWorldRegion class]])
        return YES;

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"openRegion"] && [sender isKindOfClass:[OAWorldRegion class]])
    {
        OARegionDownloadsViewController* regionDownloadsViewController = [segue destinationViewController];
        [regionDownloadsViewController prepareForRegion:(OAWorldRegion*)sender];
    }
}

#pragma mark -

@end
