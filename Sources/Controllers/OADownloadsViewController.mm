//
//  OADownloadsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsViewController.h"

#import "OsmAndApp.h"
#import "OATableViewCellWithButton.h"
#import "OARegionDownloadsViewController.h"
#import "Reachability.h"
#import "UIViewController+OARootViewController.h"
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

@interface OADownloadsViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateActivityIndicator;

@end

@implementation OADownloadsViewController
{
    OsmAndAppInstance _app;

    BOOL _isUpdatingRepository;

    NSMutableArray* _mainWorldRegions;
    NSMutableArray* _worldwideResourceItems;

    UIBarButtonItem* _refreshBarButton;

    UIAlertView* _noInternetAlertView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
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

    _isUpdatingRepository = NO;

    _mainWorldRegions = [[NSMutableArray alloc] init];
    _worldwideResourceItems = [[NSMutableArray alloc] init];

    _noInternetAlertView = nil;

    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(onUpdateRepositoryAndRefresh)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add a button to refresh repository
    self.navigationItem.rightBarButtonItem = _refreshBarButton;

    // Update repository if needed or load from cache
    if (!_app.resourcesManager->isRepositoryAvailable())
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self updateRepository:YES];
        else
            [self showNoInternetAlert];
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            _isUpdatingRepository = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                _refreshBarButton.enabled = NO;
                [self.tableView reloadData];
                [self.updateActivityIndicator startAnimating];
            });

            [self obtainMainWorldRegions];
            [self obtainWorldwideDownloads];

            _isUpdatingRepository = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.updateActivityIndicator stopAnimating];
                [self.tableView reloadData];
                _refreshBarButton.enabled = YES;
            });
        });
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
    if (_noInternetAlertView == nil)
    {
        _noInternetAlertView = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"No Internet connection")
                                                          message:OALocalizedString(@"Internet connection is required to download maps and other resources. Please check your Internet connection.")
                                                         delegate:self
                                                cancelButtonTitle:OALocalizedString(@"OK")
                                                otherButtonTitles: nil];
    }
    [_noInternetAlertView show];
}

- (void)onUpdateRepositoryAndRefresh
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepository:YES];
    else
        [self showNoInternetAlert];
}

- (void)obtainMainWorldRegions
{
    [_mainWorldRegions removeAllObjects];
    [_mainWorldRegions addObjectsFromArray:_app.worldRegion.subregions];
    [_mainWorldRegions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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

- (void)obtainWorldwideDownloads
{
    [_worldwideResourceItems removeAllObjects];
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

        [_worldwideResourceItems addObject:item];
    }
    [_worldwideResourceItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Item_ResourceInRepository* item1 = obj1;
        Item_ResourceInRepository* item2 = obj2;

        return [item1.caption localizedCaseInsensitiveCompare:item2.caption];
    }];
}

- (void)updateRepository:(BOOL)animated
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _isUpdatingRepository = YES;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _refreshBarButton.enabled = NO;
                [self.tableView reloadData];
                [self.updateActivityIndicator startAnimating];
            });
        }

        bool ok = _app.resourcesManager->updateRepository();

        if (ok)
        {
            [self obtainMainWorldRegions];
            [self obtainWorldwideDownloads];
        }

        _isUpdatingRepository = NO;
        if (animated)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.updateActivityIndicator stopAnimating];
                [self.tableView reloadData];
                _refreshBarButton.enabled = YES;
            });
        }
    });
}

#define kMainWorldRegionsSection 0
#define kWorldwideDownloadItemsSection 1

#pragma mark - OAMenuViewControllerProtocol

@synthesize menuHostViewController = _menuHostViewController;

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _noInternetAlertView)
    {
        OAOptionsPanelViewController* menuHostViewController = (OAOptionsPanelViewController*)self.menuHostViewController;
        [menuHostViewController dismissLastOpenedMenuAnimated:YES];

        _noInternetAlertView = nil;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isUpdatingRepository)
        return 0; // No sections at all

    return 2 /* 'By regions', 'Worldwide' */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isUpdatingRepository)
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
        if ([item isKindOfClass:[Item_OutdatedResource class]])
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
    NSLog(@"i'm clicked");
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
