//
//  OAManageResourcesViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAManageResourcesViewController.h"

#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <FFCircularProgressView.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OALocalResourceInformationViewController.h"
#import "OAWorldRegion.h"
#include "Localization.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define _(name) OAManageResourcesViewController__##name

#define Item _(Item)
@interface Item : NSObject
@property NSString* title;
@property NSString* resourceId;
@end
@implementation Item
@end

#define OutdatedResourceItem _(OutdatedResourceItem)
@interface OutdatedResourceItem : Item
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> resource;
@end
@implementation OutdatedResourceItem
@end

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updateIndicator;

@end

@implementation OAManageResourcesViewController
{
    OsmAndAppInstance _app;

    OAWorldRegion* _region;

    BOOL _dataInvalidated;
    NSObject* _dataLock;

    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;

    NSInteger _lastUnusedSectionIndex;

    NSInteger _subregionsSection;
    NSMutableArray* _searchableSubregionItems;
    NSMutableArray* _subregionItems;

    NSInteger _resourcesSection;
    NSMutableArray* _resourceItems;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _region = _app.worldRegion;
        _dataInvalidated = NO;
        _dataLock = [[NSObject alloc] init];

        _searchableSubregionItems = [NSMutableArray array];
        _subregionItems = [NSMutableArray array];
        _resourceItems = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self obtainDataAndItems];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_dataInvalidated)
    {
        [self updateContent];
        _dataInvalidated = NO;
    }
}

- (void)updateContent
{
    [self obtainDataAndItems];
    [self.tableView reloadData];
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;

        // Obtain all resources separately
        _resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
        _localResources = _app.resourcesManager->getLocalResources();
        _outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();

        [self collectSubregionsDataAndItems];
        if ([_subregionItems count] > 0)
            _subregionsSection = _lastUnusedSectionIndex++;
        else
            _subregionsSection = -1;

        _resourcesSection = -1;

        /*[_items removeAllObjects];


        // Process outdated installed resources first
        for(const auto& itOutdatedResource : OsmAnd::rangeOf(_outdatedResources))
        {
            OutdatedResourceItem* newItem = [[OutdatedResourceItem alloc] init];

            newItem.resourceId = itOutdatedResource.key().toNSString();
            newItem.resource = itOutdatedResource.value();
            newItem.title = nil;

            [_items setObject:newItem forKey:newItem.resourceId];
        }*/
    }
}

- (void)collectSubregionsDataAndItems
{
    // Collect all regions (and their parents) that have at least one
    // resource available in repository or locally.

    [_searchableSubregionItems removeAllObjects];
    [_subregionItems removeAllObjects];
    for(OAWorldRegion* subregion in _region.subregions)
    {
        BOOL isEmpty = YES;

        // Look in repository
        if (isEmpty)
        {
            for(const auto& resource : _resourcesInRepository)
            {
                OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:subregion
                                                                              thatContainsResource:resource->id];

                if (match)
                {
                    OAWorldRegion* intermediateRegion = match;
                    while (intermediateRegion != subregion && intermediateRegion != nil)
                    {
                        if (![_searchableSubregionItems containsObject:intermediateRegion])
                            [_searchableSubregionItems addObject:intermediateRegion];

                        intermediateRegion = intermediateRegion.superregion;
                    }
                    
                    isEmpty = NO;
                    break;
                }
            }
        }

        // Look in local resources
        if (isEmpty)
        {
            for(const auto& resource : _localResources)
            {
                OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:subregion
                                                                              thatContainsResource:resource->id];

                if (match)
                {
                    OAWorldRegion* intermediateRegion = match;
                    while (intermediateRegion != subregion && intermediateRegion != nil)
                    {
                        if (![_searchableSubregionItems containsObject:intermediateRegion])
                            [_searchableSubregionItems addObject:intermediateRegion];

                        intermediateRegion = intermediateRegion.superregion;
                    }

                    isEmpty = NO;
                    break;
                }
            }
        }

        // If subregion has nothing to offer, skip it
        if (isEmpty)
            continue;

        if (![_searchableSubregionItems containsObject:subregion])
            [_searchableSubregionItems addObject:subregion];
        [_subregionItems addObject:subregion];
    }
    [_searchableSubregionItems sortUsingSelector:@selector(compare:)];
    [_subregionItems sortUsingSelector:@selector(compare:)];
}

/*
- (NSString*)titleOfResource:
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
*/
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionsCount = 0;

    if (_subregionsSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _subregionsSection)
        return [_subregionItems count];
    if (section == _resourcesSection)
        return [_resourceItems count];

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_region.superregion == nil)
    {
        if (section == _subregionsSection)
            return OALocalizedString(@"By regions");
        if (section == _resourcesSection)
            return OALocalizedString(@"Worldwide");
        return nil;
    }

    if (section == _subregionsSection)
        return OALocalizedString(@"Regions");
    if (section == _resourcesSection)
        return OALocalizedString(@"Maps & resources");

    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const subregionCell = @"subregionCell";

    NSString* cellTypeId = nil;
    NSString* caption = nil;
    if (indexPath.section == _subregionsSection)
    {
        OAWorldRegion* worldRegion = [_subregionItems objectAtIndex:indexPath.row];

        cellTypeId = subregionCell;
        caption = worldRegion.name;
    }
    /*else if (indexPath.section == _downloadsSection)
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
*/
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
  /*  if (cell == nil)
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
*/
    // Fill cell content
    cell.textLabel.text = caption;
    /*if ([cellTypeId isEqualToString:downloadedItemCell])
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
    }*/

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
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
     */
}

#pragma mark - Navigation
/*
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
*/
#pragma mark -

+ (OAWorldRegion*)findRegionOrAnySubregionOf:(OAWorldRegion*)region
                        thatContainsResource:(const QString&)resourceId
{
    const auto& regionId = QString::fromNSString(region.regionId);

    if (resourceId.startsWith(regionId))
        return region;

    for (OAWorldRegion* subregion in region.subregions)
    {
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:subregion
                                                                      thatContainsResource:resourceId];
        if (match)
            return match;
    }

    return nil;
}

@end
