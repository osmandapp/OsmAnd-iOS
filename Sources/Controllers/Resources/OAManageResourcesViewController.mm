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
#import <MBProgressHUD.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OATableViewCell.h"
#import "UITableViewCell+getTableView.h"
#import "OARootViewController.h"
#import "OALocalResourceInformationViewController.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OAWorldRegion.h"
#import "OALog.h"
#include "Localization.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define kOpenSubregionSegue @"openSubregionSegue"

#define _(name) OAManageResourcesViewController__##name

#define ResourceItem _(ResourceItem)
@interface ResourceItem : NSObject
@property NSString* title;
@property QString resourceId;
@property id<OADownloadTask> __weak downloadTask;
@end
@implementation ResourceItem
@end

#define RepositoryResourceItem _(RepositoryResourceItem)
@interface RepositoryResourceItem : ResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resource;
@end
@implementation RepositoryResourceItem
@end

#define LocalResourceItem _(LocalResourceItem)
@interface LocalResourceItem : ResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> resource;
@end
@implementation LocalResourceItem
@end

#define OutdatedResourceItem _(OutdatedResourceItem)
@interface OutdatedResourceItem : LocalResourceItem
@end
@implementation OutdatedResourceItem
@end

#define kAllResourcesScope 0
#define kLocalResourcesScope 1

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UIView *scopeControlContainer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *scopeControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scopeControlContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

struct RegionResources
{
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > allResources;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > repositoryResources;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > localResources;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > outdatedResources;
};

@implementation OAManageResourcesViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _localResourcesChangedObserver;
    OAAutoObserverProxy* _repositoryUpdatedObserver;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;

    OAWorldRegion* _region;

    BOOL _dataInvalidated;
    NSObject* _dataLock;

    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
    QHash< OAWorldRegion* __weak, RegionResources > _resourcesByRegions;

    NSInteger _currentScope;

    NSInteger _lastUnusedSectionIndex;

    NSMutableArray* _searchableWorldwideRegionItems;

    NSInteger _subregionsSection;
    NSMutableArray* _searchableSubregionItems;
    NSMutableArray* _allSubregionItems;
    NSMutableArray* _localSubregionItems;

    NSInteger _resourcesSection;
    NSMutableArray* _allResourceItems;
    NSMutableArray* _localResourceItems;

    NSString* _lastSearchString;
    NSInteger _lastSearchScope;
    NSArray* _searchResults;

    CGFloat _originalScopeControlContainerHeight;

    NSComparator _resourceItemsComparator;

    MBProgressHUD* _refreshRepositoryProgressHUD;
    UIBarButtonItem* _refreshRepositoryBarButton;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                  withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)];
        _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)];
        _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                    andObserve:_app.localResourcesChangedObservable];
        _repositoryUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onRepositoryUpdated:withKey:)
                                                                    andObserve:_app.resourcesRepositoryUpdatedObservable];

        _region = _app.worldRegion;
        _dataInvalidated = NO;
        _dataLock = [[NSObject alloc] init];

        _currentScope = 0;

        _searchableWorldwideRegionItems = [NSMutableArray array];

        _searchableSubregionItems = [NSMutableArray array];
        _allSubregionItems = [NSMutableArray array];
        _localSubregionItems = [NSMutableArray array];
        _allResourceItems = [NSMutableArray array];
        _localResourceItems = [NSMutableArray array];

        _lastSearchString = @"";
        _lastSearchScope = 0;
        _searchResults = nil;

        _resourceItemsComparator = ^NSComparisonResult(id obj1, id obj2) {
            ResourceItem *item1 = obj1;
            ResourceItem *item2 = obj2;

            return [item1.title localizedCaseInsensitiveCompare:item2.title];
        };
    }
    return self;
}

- (void)setupWithRegion:(OAWorldRegion*)region andWorldRegionItems:(NSArray*)worldRegionItems andScope:(NSInteger)scope
{
    _region = region;
    _searchableWorldwideRegionItems = [worldRegionItems copy];
    _currentScope = scope;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

#if defined(DEBUG)
    //HACK: This stuff is needed to avoid exceptions during Debug. In Release they're harmless
    self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleDefault;
#endif // defined(DEBUG)

    if (_region != _app.worldRegion)
        self.title = _region.name;

    _refreshRepositoryProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_refreshRepositoryProgressHUD];
    _refreshRepositoryBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                target:self
                                                                                action:@selector(onRefreshRepositoryButtonClicked)];
    self.navigationItem.rightBarButtonItem = _refreshRepositoryBarButton;

    _scopeControl.selectedSegmentIndex = _currentScope;

    _originalScopeControlContainerHeight = self.scopeControlContainerHeightConstraint.constant;

    [self obtainDataAndItems];
    [self prepareContent];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // If there's no repository available and there's internet connection, just update it
    if (!_app.resourcesManager->isRepositoryAvailable() &&
        [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        [self updateRepository];
    }
}

- (void)updateContent
{
    [self obtainDataAndItems];
    [self refreshContent];
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        [self prepareData];
        [self collectSubregionsDataAndItems];
        [self collectResourcesDataAndItems];
    }
}

- (void)prepareData
{
    // Obtain all resources separately
    _resourcesInRepository = _app.resourcesManager->getResourcesInRepository();
    _localResources = _app.resourcesManager->getLocalResources();
    _outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();

    // Collect resources for each region (worldwide)
    _resourcesByRegions.clear();
    NSArray* mergedRegions = [_app.worldRegion.flattenedSubregions arrayByAddingObject:_app.worldRegion];
    for(OAWorldRegion* region in mergedRegions)
    {
        const auto regionId = QString::fromNSString(region.regionId);
        const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);

        RegionResources regionResources;
        for (const auto& resource : _outdatedResources)
        {
            if (!resource->id.startsWith(downloadsIdPrefix))
                continue;

            regionResources.allResources.insert(resource->id, resource);
            regionResources.outdatedResources.insert(resource->id, resource);
            regionResources.localResources.insert(resource->id, resource);
        }
        for (const auto& resource : _localResources)
        {
            if (!resource->id.startsWith(downloadsIdPrefix))
                continue;

            if (!regionResources.allResources.contains(resource->id))
                regionResources.allResources.insert(resource->id, resource);
            if (!regionResources.localResources.contains(resource->id))
                regionResources.localResources.insert(resource->id, resource);
        }
        for (const auto& resource : _resourcesInRepository)
        {
            if (!resource->id.startsWith(downloadsIdPrefix))
                continue;

            if (!regionResources.allResources.contains(resource->id))
                regionResources.allResources.insert(resource->id, resource);
            regionResources.repositoryResources.insert(resource->id, resource);
        }

        _resourcesByRegions.insert(region, regionResources);
    }
}

- (void)collectSubregionsDataAndItems
{
    // Collect all regions (and their parents) that have at least one
    // resource available in repository or locally.

    [_searchableSubregionItems removeAllObjects];
    [_allSubregionItems removeAllObjects];
    [_localSubregionItems removeAllObjects];
    for(OAWorldRegion* subregion in _region.flattenedSubregions)
    {
        // Look in repository
        BOOL foundRepositoryResource = NO;
        for(const auto& resource : _resourcesInRepository)
        {
            OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:subregion
                                                                          thatContainsResource:resource->id];
            if (!match)
                continue;

            OAWorldRegion* intermediateRegion = match;
            while (intermediateRegion != subregion && intermediateRegion != nil)
            {
                if (![_searchableSubregionItems containsObject:intermediateRegion])
                    [_searchableSubregionItems addObject:intermediateRegion];

                intermediateRegion = intermediateRegion.superregion;
            }

            foundRepositoryResource = YES;
            break;
        }

        // Look in local resources
        BOOL foundLocalResource = NO;
        for(const auto& resource : _localResources)
        {
            OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:subregion
                                                                          thatContainsResource:resource->id];
            if (!match)
                continue;

            OAWorldRegion* intermediateRegion = match;
            while (intermediateRegion != subregion && intermediateRegion != nil)
            {
                if (![_searchableSubregionItems containsObject:intermediateRegion])
                    [_searchableSubregionItems addObject:intermediateRegion];

                intermediateRegion = intermediateRegion.superregion;
            }

            foundLocalResource = YES;
            break;
        }

        // If subregion has nothing to offer, skip it
        if (!foundRepositoryResource && !foundLocalResource)
        {
            OALog(@"Region %@ (%@) was skipped since it has no resources", subregion.name, subregion.regionId);
            continue;
        }

        if (![_searchableSubregionItems containsObject:subregion])
            [_searchableSubregionItems addObject:subregion];
        if (subregion.superregion == _region)
        {
            [_allSubregionItems addObject:subregion];
            if (foundLocalResource)
                [_localSubregionItems addObject:subregion];
        }
    }
    [_searchableSubregionItems sortUsingSelector:@selector(compare:)];
    [_allSubregionItems sortUsingSelector:@selector(compare:)];
    [_localSubregionItems sortUsingSelector:@selector(compare:)];
}

- (void)collectResourcesDataAndItems
{
    [_allResourceItems removeAllObjects];
    [_localResourceItems removeAllObjects];

    const auto citRegionResources = _resourcesByRegions.constFind(_region);
    if (citRegionResources == _resourcesByRegions.cend())
        return;
    const auto& regionResources = *citRegionResources;

    for (const auto& resource_ : regionResources.allResources)
    {
        ResourceItem* item_ = nil;

        if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource_))
        {
            if (regionResources.outdatedResources.contains(resource->id))
            {
                OutdatedResourceItem* item = [[OutdatedResourceItem alloc] init];
                item_ = item;
                item.resourceId = resource->id;
                item.title = [self titleOfResource:resource_ withRegionName:NO];
                item.resource = resource;
                item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

                if (item.title == nil)
                    continue;

                [_localResourceItems addObject:item];
            }
            else
            {
                LocalResourceItem* item = [[LocalResourceItem alloc] init];
                item_ = item;
                item.resourceId = resource->id;
                item.title = [self titleOfResource:resource_ withRegionName:NO];
                item.resource = resource;
                item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

                if (item.title == nil)
                    continue;

                [_localResourceItems addObject:item];
            }
        }
        else if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource_))
        {
            RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
            item_ = item;
            item.resourceId = resource->id;
            item.title = [self titleOfResource:resource_ withRegionName:NO];
            item.resource = resource;
            item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

            if (item.title == nil)
                continue;
        }

        [_allResourceItems addObject:item_];
        if (item_.downloadTask != nil)
        {
            [_downloadTaskProgressObserver observe:item_.downloadTask.progressCompletedObservable];
            [_downloadTaskCompletedObserver observe:item_.downloadTask.completedObservable];
        }
    }
    [_allResourceItems sortUsingComparator:_resourceItemsComparator];
    [_localResourceItems sortUsingComparator:_resourceItemsComparator];
}

- (void)prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;

        if ([[self getSubregionItems] count] > 0)
            _subregionsSection = _lastUnusedSectionIndex++;
        else
            _subregionsSection = -1;

        if ([[self getResourceItems] count] > 0)
            _resourcesSection = _lastUnusedSectionIndex++;
        else
            _resourcesSection = -1;

        // Configure search scope
        if (_region == _app.worldRegion || [_searchableSubregionItems count] == 0)
        {
            self.searchDisplayController.searchBar.scopeButtonTitles = nil;
            self.searchDisplayController.searchBar.placeholder = OALocalizedString(@"Search worldwide");
        }
        else
        {
            self.searchDisplayController.searchBar.scopeButtonTitles = @[_region.name, OALocalizedString(@"Worldwide")];
            self.searchDisplayController.searchBar.placeholder = OALocalizedString(@"Search in %@ or worldwide", _region.name);
        }
    }
}

- (void)refreshContent
{
    @synchronized(_dataLock)
    {
        [self prepareContent];
        if (self.searchDisplayController.isActive)
            [self.searchDisplayController.searchResultsTableView reloadData];
        [self.tableView reloadData];
    }
}

- (id<OADownloadTask>)getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (NSMutableArray*)getSubregionItems
{
    switch (_currentScope)
    {
        case kAllResourcesScope:
            return _allSubregionItems;

        case kLocalResourcesScope:
            return _localSubregionItems;
    }

    return nil;
}

- (NSMutableArray*)getResourceItems
{
    switch (_currentScope)
    {
        case kAllResourcesScope:
            return _allResourceItems;

        case kLocalResourcesScope:
            return _localResourceItems;
    }
    
    return nil;
}

- (NSString*)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
              withRegionName:(BOOL)includeRegionName
{
    return [self titleOfResource:resource
                        inRegion:_region
            withRegionName:includeRegionName];
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
            if ([_region.subregions count] > 0)
            {
                if (!includeRegionName)
                    return OALocalizedString(@"Full map of entire region");
                else
                    return OALocalizedString(@"Full map of entire %@", region.name);
            }
            else
            {
                if (!includeRegionName)
                    return OALocalizedString(@"Full map of the region");
                else
                    return OALocalizedString(@"Full map of %@", region.name);
            }
            break;

        default:
            return nil;
    }
}

- (void)performSearchForSearchString:(NSString*)searchString
                      andSearchScope:(NSInteger)searchScope
{
    @synchronized(_dataLock)
    {
        // If case searchString is empty, there are no results
        if (searchString == nil || [searchString length] == 0)
        {
            _searchResults = @[];
            return;
        }

        // In case searchString has only spaces, also nothing to do here
        if ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
        {
            _searchResults = @[];
            return;
        }

        // Select where to look
        NSArray* searchableContent = nil;
        if (_region == _app.worldRegion || (searchScope == 0 && [_searchableSubregionItems count] > 0))
            searchableContent = _searchableSubregionItems;
        else
            searchableContent = _searchableWorldwideRegionItems;

        // Search through subregions:

        NSComparator regionComparator = ^NSComparisonResult(id obj1, id obj2) {
            OAWorldRegion *item1 = obj1;
            OAWorldRegion *item2 = obj2;

            return [item1.name localizedCaseInsensitiveCompare:item2.name];
        };

        // Regions that start with given name have higher priority
        NSPredicate* startsWith = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", searchString];
        NSMutableArray *regions_startsWith = [[searchableContent filteredArrayUsingPredicate:startsWith] mutableCopy];
        if ([regions_startsWith count] == 0)
        {
            NSPredicate* anyStartsWith = [NSPredicate predicateWithFormat:@"ANY allNames BEGINSWITH[cd] %@", searchString];
            [regions_startsWith addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyStartsWith]];
        }
        [regions_startsWith sortUsingComparator:regionComparator];

        // Regions that only contain given string have less priority
        NSPredicate* onlyContains = [NSPredicate predicateWithFormat:
                                     @"(name CONTAINS[cd] %@) AND NOT (name BEGINSWITH[cd] %@)",
                                     searchString,
                                     searchString];
        NSMutableArray *regions_onlyContains = [[searchableContent filteredArrayUsingPredicate:onlyContains] mutableCopy];
        if ([regions_onlyContains count] == 0)
        {
            NSPredicate* anyOnlyContains = [NSPredicate predicateWithFormat:
                                            @"(ANY allNames CONTAINS[cd] %@) AND NOT (ANY allNames BEGINSWITH[cd] %@)",
                                            searchString,
                                            searchString];
            [regions_onlyContains addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyOnlyContains]];
        }
        [regions_onlyContains sortUsingComparator:regionComparator];

        // Assemble all regions all togather
        NSArray* regions = [regions_startsWith arrayByAddingObjectsFromArray:regions_onlyContains];
        NSMutableArray* results = [NSMutableArray array];
        for (OAWorldRegion* region in regions)
        {
            [results addObject:region];

            // Get all resources that are direct children of current region
            const auto citRegionResources = _resourcesByRegions.constFind(region);
            if (citRegionResources == _resourcesByRegions.cend())
                continue;
            const auto& regionResources = *citRegionResources;

            // Create items for each resource found
            NSMutableArray* resourceItems = [NSMutableArray array];
            for (const auto& resource_ : regionResources.allResources)
            {
                if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource_))
                {
                    if (regionResources.outdatedResources.contains(resource->id))
                    {
                        OutdatedResourceItem* item = [[OutdatedResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.title = [self titleOfResource:resource_
                                                  inRegion:region
                                            withRegionName:YES];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                    else
                    {
                        LocalResourceItem* item = [[LocalResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.title = [self titleOfResource:resource_
                                                  inRegion:region
                                            withRegionName:YES];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                }
                else if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource_))
                {
                    RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.title = [self titleOfResource:resource_
                                              inRegion:region
                                        withRegionName:YES];
                    item.resource = resource;
                    item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];

                    if (item.title == nil)
                        continue;

                    [resourceItems addObject:item];
                }

                ResourceItem* item = (ResourceItem*)[resourceItems lastObject];
                if (item.downloadTask != nil)
                {
                    [_downloadTaskProgressObserver observe:item.downloadTask.progressCompletedObservable];
                    [_downloadTaskCompletedObserver observe:item.downloadTask.completedObservable];
                }
            }
            [resourceItems sortUsingComparator:_resourceItemsComparator];
            
            [results addObjectsFromArray:resourceItems];
        }
        
        _searchResults = results;
    }
}

- (void)showNoInternetAlertForCatalogUpdate
{
    [[OARootViewController instance] showNoInternetAlertFor:OALocalizedString(@"Catalog update")];
}

- (void)updateRepository
{
    _refreshRepositoryBarButton.enabled = NO;
    [_refreshRepositoryProgressHUD showAnimated:YES
                            whileExecutingBlock:^{
                                _app.resourcesManager->updateRepository();
                            }
                                completionBlock:^{
                                    _refreshRepositoryBarButton.enabled = YES;
                                }];
}

- (void)offerDownloadAndUpdateOf:(OutdatedResourceItem*)item
{
    const auto citRepositoryResource = _resourcesInRepository.constFind(item.resourceId);
    if (citRepositoryResource == _resourcesInRepository.cend())
        return;
    const auto& resourceInRepository = *citRepositoryResource;

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:resourceInRepository->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* message = nil;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded over cellular network. This may incur high charges. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES],
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"An update is available for %1$@. %2$@ will be downloaded over WiFi network. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES],
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
    const auto citRepositoryResource = _resourcesInRepository.constFind(item.resourceId);
    if (citRepositoryResource == _resourcesInRepository.cend())
        return;
    const auto& resourceInRepository = *citRepositoryResource;

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:resourceInRepository->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSString* message = nil;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = OALocalizedString(@"Intallation of %1$@ needs %2$@ to be downloaded over cellular network. This may incur high charges. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES],
                                    stringifiedSize);
    }
    else
    {
        message = OALocalizedString(@"Intallation of %1$@ needs %2$@ to be be downloaded over WiFi network. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES],
                                    stringifiedSize);
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Install")
                                                             action:^{
                                                                 [self startDownloadOf:resourceInRepository];
                                                             }], nil] show];
}

- (void)startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
{
    // Create download tasks
    NSURLRequest* request = [NSURLRequest requestWithURL:resource->url.toNSURL()];
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]];

    [self updateContent];

    // Resume task finally
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

    NSString* message = nil;
    if (isUpdate)
    {
        message = OALocalizedString(@"You're going to cancel %@ update. All downloaded data will be lost. Proceed?",
                                    [self titleOfResource:resource inRegion:_region withRegionName:YES]);
    }
    else
    {
        message = OALocalizedString(@"You're going to cancel %@ installation. All downloaded data will be lost. Proceed?",
                                    [self titleOfResource:resource inRegion:_region withRegionName:YES]);
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
    [item.downloadTask cancel];
}

- (void)offerDeleteResourceOf:(LocalResourceItem*)item
{
    BOOL isInstalled = (std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(item.resource) != nullptr);

    NSString* message = nil;
    if (isInstalled)
    {
        message = OALocalizedString(@"You're going to uninstall %@. You can reinstall it later from catalog. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES]);
    }
    else
    {
        message = OALocalizedString(@"You're going to delete %@. It's not from catalog, so please be sure you have a backup if needed. Proceed?",
                                    [self titleOfResource:item.resource inRegion:_region withRegionName:YES]);
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
    _app.resourcesManager->uninstallResource(item.resourceId);
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

            NSString* resourceId = item.resourceId.toNSString();
            [self.navigationController pushViewController:[[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId]
                                                 animated:YES];
        }
        else if ([item_ isKindOfClass:[RepositoryResourceItem class]])
        {
            RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

            [self offerDownloadAndInstallOf:item];
        }
    }
}

- (IBAction)onScopeChanged:(id)sender
{
    _currentScope = _scopeControl.selectedSegmentIndex;

    [self refreshContent];
}

- (void)onRefreshRepositoryButtonClicked
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepository];
    else
        [self showNoInternetAlertForCatalogUpdate];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
            return;

        if (self.searchDisplayController.isActive)
            [self.searchDisplayController.searchResultsTableView reloadData];
        [self.tableView reloadData];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;

    NSInteger sectionsCount = 0;

    if (_subregionsSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults count];

    if (section == _subregionsSection)
        return [[self getSubregionItems] count];
    if (section == _resourcesSection)
        return [[self getResourceItems] count];

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;

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
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const localResourceCell = @"localResourceCell";
    static NSString* const repositoryResourceCell = @"repositoryResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";

    NSString* cellTypeId = nil;
    NSString* title = nil;
    NSString* subtitle = nil;
    id item_ = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        item_ = [_searchResults objectAtIndex:indexPath.row];

        if ([item_ isKindOfClass:[OAWorldRegion class]])
        {
            OAWorldRegion* item = (OAWorldRegion*)item_;

            cellTypeId = subregionCell;
            title = item.name;
            if (item.superregion != nil)
                subtitle = item.superregion.name;
        }
        else if ([item_ isKindOfClass:[ResourceItem class]])
        {
            ResourceItem* item = (ResourceItem*)item_;

            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
            else if ([item isKindOfClass:[OutdatedResourceItem class]])
                cellTypeId = outdatedResourceCell;
            else if ([item isKindOfClass:[LocalResourceItem class]])
                cellTypeId = localResourceCell;
            else if ([item isKindOfClass:[RepositoryResourceItem class]])
                cellTypeId = repositoryResourceCell;

            title = item.title;
        }
    }
    else
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
        {
            item_ = [[self getSubregionItems] objectAtIndex:indexPath.row];
            OAWorldRegion* worldRegion = (OAWorldRegion*)item_;

            cellTypeId = subregionCell;
            title = worldRegion.name;
            subtitle = nil;
        }
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
        {
            item_ = [[self getResourceItems] objectAtIndex:indexPath.row];
            ResourceItem* item = (ResourceItem*)item_;

            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
            else if ([item isKindOfClass:[OutdatedResourceItem class]])
                cellTypeId = outdatedResourceCell;
            else if ([item isKindOfClass:[LocalResourceItem class]])
                cellTypeId = localResourceCell;
            else if ([item isKindOfClass:[RepositoryResourceItem class]])
                cellTypeId = repositoryResourceCell;

            title = item.title;
        }
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:outdatedResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellTypeId];

            FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    // Fill cell content
    cell.textLabel.text = title;
    if (cell.detailTextLabel != nil)
        cell.detailTextLabel.text = subtitle;
    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        ResourceItem* item = (ResourceItem*)item_;
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;

        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.0f && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = 1.0f;
        }
        else
        {
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
            item = [[self getSubregionItems] objectAtIndex:indexPath.row];
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
    }

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
            item = [[self getSubregionItems] objectAtIndex:indexPath.row];
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
    }

    if (item != nil)
        [self onItemClicked:item];

    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
            item = [[self getSubregionItems] objectAtIndex:indexPath.row];
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
    }

    if (item == nil)
        return NO;

    if (![item isKindOfClass:[LocalResourceItem class]])
        return NO;

    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
            item = [[self getSubregionItems] objectAtIndex:indexPath.row];
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
    }

    if (item == nil)
        return UITableViewCellEditingStyleNone;

    if (![item isKindOfClass:[LocalResourceItem class]])
        return UITableViewCellEditingStyleNone;

    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _subregionsSection && _subregionsSection >= 0)
            item = [[self getSubregionItems] objectAtIndex:indexPath.row];
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
    }

    if (item == nil)
        return;

    if ([item isKindOfClass:[LocalResourceItem class]])
        [self offerDeleteResourceOf:item];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    _lastSearchScope = searchOption;
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];

    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _lastSearchString = searchString;
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];

    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.scopeControlContainerHeightConstraint.constant = 0.0f;
                         [self.scopeControlContainer.superview layoutIfNeeded];

                         self.scopeControlContainer.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         self.scopeControlContainer.userInteractionEnabled = NO;
                     }];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    //NOTE: This doesn't work as expected
    /*dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.scopeControlContainerHeightConstraint.constant = _originalScopeControlContainerHeight;
                             [self.scopeControlContainer.superview layoutIfNeeded];

                             self.scopeControlContainer.alpha = 1.0f;
                         } completion:^(BOOL finished) {
                             self.scopeControlContainer.userInteractionEnabled = YES;
                         }];
    });*/
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.scopeControlContainerHeightConstraint.constant = _originalScopeControlContainerHeight;
                         [self.scopeControlContainer.superview layoutIfNeeded];

                         self.scopeControlContainer.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         self.scopeControlContainer.userInteractionEnabled = YES;
                     }];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)sender;
        UITableView* tableView = [cell getTableView];
        NSIndexPath* cellPath = [tableView indexPathForCell:cell];

        if ([identifier isEqualToString:kOpenSubregionSegue])
        {
            OAWorldRegion* subregion = nil;
            if (tableView == _tableView && _subregionsSection >= 0)
                subregion = [[self getSubregionItems] objectAtIndex:cellPath.row];
            else if (tableView == self.searchDisplayController.searchResultsTableView)
                subregion = [_searchResults objectAtIndex:cellPath.row];

            return (subregion != nil);
        }
    }

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![sender isKindOfClass:[UITableViewCell class]])
        return;

    UITableViewCell* cell = (UITableViewCell*)sender;
    UITableView* tableView = [cell getTableView];
    NSIndexPath* cellPath = [tableView indexPathForCell:cell];

    if ([segue.identifier isEqualToString:kOpenSubregionSegue])
    {
        OAManageResourcesViewController* subregionViewController = [segue destinationViewController];

        OAWorldRegion* subregion = nil;
        if (tableView == _tableView && _subregionsSection >= 0)
            subregion = [[self getSubregionItems] objectAtIndex:cellPath.row];
        else if (tableView == self.searchDisplayController.searchResultsTableView)
            subregion = [_searchResults objectAtIndex:cellPath.row];

        [subregionViewController setupWithRegion:subregion
                             andWorldRegionItems:(_region == _app.worldRegion) ? _searchableSubregionItems : _searchableWorldwideRegionItems
                                        andScope:_currentScope];
    }
}

#pragma mark -

+ (OAWorldRegion*)findRegionOrAnySubregionOf:(OAWorldRegion*)region
                        thatContainsResource:(const QString&)resourceId
{
    const auto& downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);

    if (resourceId.startsWith(downloadsIdPrefix))
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
