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
#import <FormatterKit/TTTArrayFormatter.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OATableViewCell.h"
#import "UITableViewCell+getTableView.h"
#import "OARootViewController.h"
#import "OALocalResourceInformationViewController.h"
#import "OAOutdatedResourcesViewController.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OAWorldRegion.h"
#import "OALog.h"
#include "Localization.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define kOpenSubregionSegue @"openSubregionSegue"
#define kOpenOutdatedResourcesSegue @"openOutdatedResourcesSegue"
#define kOpenDetailsSegue @"openDetailsSegue"
#define kOpenInstalledResourcesSegue @"openInstalledResourcesSegue"


#define kAllResourcesScope 0
#define kLocalResourcesScope 1

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate>

//@property (weak, nonatomic) IBOutlet UISegmentedControl *scopeControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *updateButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;


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

    NSObject* _dataLock;

    NSInteger _currentScope;

    NSInteger _lastUnusedSectionIndex;

    NSMutableArray* _allSubregionItems;
    ResourceItem* _regionMap;
    NSInteger _regionMapSection;

    NSInteger _outdatedResourcesSection;
    NSMutableArray* _outdatedResourceItems;
    NSArray* _regionsWithOutdatedResources;

    NSInteger _localResourcesSection;
    NSInteger _resourcesSection;
    NSMutableArray* _allResourceItems;
    NSMutableArray* _localResourceItems;

    NSString* _lastSearchString;
    NSInteger _lastSearchScope;
    NSArray* _searchResults;

    MBProgressHUD* _refreshRepositoryProgressHUD;
    UIBarButtonItem* _refreshRepositoryBarButton;
    
    BOOL _isSearching;
    BOOL _doNotSearch;
    BOOL hideUpdateButton;
    
    UILabel *_updateCouneView;
    BOOL _doDataUpdate;
    BOOL _doDataUpdateReload;
}

static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
static QHash< OAWorldRegion* __weak, RegionResources > _resourcesByRegions;

static NSMutableArray* _searchableWorldwideRegionItems;


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _dataLock = [[NSObject alloc] init];

        self.region = _app.worldRegion;

        _currentScope = kAllResourcesScope;

        _allSubregionItems = [NSMutableArray array];

        _outdatedResourceItems = [NSMutableArray array];

        _allResourceItems = [NSMutableArray array];
        _localResourceItems = [NSMutableArray array];

        _lastSearchString = @"";
        _lastSearchScope = 0;
        _searchResults = nil;
    }
    return self;
}

- (void)setupWithRegion:(OAWorldRegion*)region
    andWorldRegionItems:(NSArray*)worldRegionItems
               andScope:(NSInteger)scope
{
    self.region = region;
    _currentScope = scope;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.openFromSplash) {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
    
    if (self.region != _app.worldRegion)
        [self.titleView setText:self.region.name];
    else if (_currentScope == kLocalResourcesScope) {
        [self.titleView setText:OALocalizedString(@"Installed")];
    }

    _refreshRepositoryProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_refreshRepositoryProgressHUD];

    [self obtainDataAndItems];
    [self prepareContent];
    
    // IOS-172
    _updateCouneView = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
    _updateCouneView.layer.cornerRadius = 10.0;
    _updateCouneView.layer.masksToBounds = YES;
    _updateCouneView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:143.0/255.0 blue:0.0 alpha:1.0];
    _updateCouneView.font = [UIFont fontWithName:@"Avenir-Roman" size:12.0];
    _updateCouneView.textAlignment = NSTextAlignmentCenter;
    _updateCouneView.textColor = [UIColor whiteColor];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_doNotSearch || _currentScope == kLocalResourcesScope) {
        
        CGRect f = self.searchDisplayController.searchBar.frame;
        f.size.height = 0;
        self.searchDisplayController.searchBar.frame = f;
        self.searchDisplayController.searchBar.hidden = YES;
        
        self.searchButton.hidden = YES;
        
    } else {
        
        if (self.tableView.bounds.origin.y == 0) {
            // Hide the search bar until user scrolls up
            CGRect newBounds = self.tableView.bounds;
            newBounds.origin.y = newBounds.origin.y + self.searchDisplayController.searchBar.bounds.size.height;
            self.tableView.bounds = newBounds;
        }
    }
    
    self.updateButton.hidden = hideUpdateButton;
    
    //[[UIApplication sharedApplication] setStatusBarHidden:_isSearching];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // If there's no repository available and there's internet connection, just update it
    if (!_app.resourcesManager->isRepositoryAvailable() &&
        [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable) {
        [self updateRepository];
    } else {
        if (self.openFromSplash)
            [self onSearchBtnClicked:nil];
    }
}

- (void)updateContent
{
    _doDataUpdate = YES;
    [self obtainDataAndItems];
    [self prepareContent];
    [self refreshContent:YES];
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        if (_doDataUpdateReload)
            _resourcesByRegions.clear();
        
        if (_doDataUpdate || _resourcesByRegions.count() == 0)
            [OAManageResourcesViewController prepareData];
        [self collectSubregionsDataAndItems];
        [self collectResourcesDataAndItems];

        _doDataUpdate = NO;
        _doDataUpdateReload = NO;
    }
}

+ (void)prepareData
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain all resources separately
    _resourcesInRepository = app.resourcesManager->getResourcesInRepository();
    _localResources = app.resourcesManager->getLocalResources();
    
    // IOS-199
#if defined(OSMAND_IOS_DEV)
    if (app.debugSettings.setAllResourcesAsOutdated)
        _outdatedResources = app.resourcesManager->getLocalResources();
    else
        _outdatedResources = app.resourcesManager->getOutdatedInstalledResources();
#else
    _outdatedResources = app.resourcesManager->getOutdatedInstalledResources();
#endif // defined(OSMAND_IOS_DEV)
    
    BOOL doInit = (_resourcesByRegions.count() == 0);
    
    // Collect resources for each region (worldwide)
    //_resourcesByRegions.clear();
    
    BOOL initWorldwideRegionItems = (_searchableWorldwideRegionItems == nil) || doInit;
    
    if (initWorldwideRegionItems)
        _searchableWorldwideRegionItems = [NSMutableArray array];
    
    NSArray* mergedRegions = [app.worldRegion.flattenedSubregions arrayByAddingObject:app.worldRegion];
    for(OAWorldRegion* region in mergedRegions)
    {
        if (initWorldwideRegionItems)
            [_searchableWorldwideRegionItems addObject:region];
        
        const auto regionId = QString::fromNSString(region.regionId);
        const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);
        
        RegionResources regionResources;
        RegionResources regionResPrevious;

        if (!doInit) {
            const auto citRegionResources = _resourcesByRegions.constFind(region);
            if (citRegionResources != _resourcesByRegions.cend())
                regionResources = *citRegionResources;
        }

        if (!doInit) {

            for (const auto& resource : regionResources.outdatedResources) {
                regionResPrevious.outdatedResources.insert(resource->id, resource);
                regionResources.allResources.remove(resource->id);
            }
            for (const auto& resource : regionResources.localResources) {
                regionResPrevious.localResources.insert(resource->id, resource);
                regionResources.allResources.remove(resource->id);
            }
            
            regionResources.outdatedResources.clear();
            regionResources.localResources.clear();
        }
        
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
        
        if (doInit) {
            for (const auto& resource : _resourcesInRepository)
            {
                if (!resource->id.startsWith(downloadsIdPrefix))
                    continue;
                
                if (!regionResources.allResources.contains(resource->id))
                    regionResources.allResources.insert(resource->id, resource);
                regionResources.repositoryResources.insert(resource->id, resource);
            }
        } else {
            for (const auto& resource : regionResPrevious.outdatedResources)
                if (!regionResources.allResources.contains(resource->id)) {
                    regionResources.allResources.insert(resource->id, _resourcesInRepository.value(resource->id));
                    NSLog(@"outdatedResources +");
                }
            for (const auto& resource : regionResPrevious.localResources)
                if (!regionResources.allResources.contains(resource->id)) {
                    regionResources.allResources.insert(resource->id, _resourcesInRepository.value(resource->id));
                    NSLog(@"localResources +");
                }
        }
        
        _resourcesByRegions.insert(region, regionResources);
    }
}
- (void)collectSubregionsDataAndItems
{
    // Collect all regions (and their parents) that have at least one
    // resource available in repository or locally.

    _regionMap = nil;
    [_allResourceItems removeAllObjects];
    [_allSubregionItems removeAllObjects];
    
    for (OAWorldRegion* subregion in self.region.flattenedSubregions)
    {
        if (subregion.superregion == self.region) {
            if (subregion.subregions.count > 0)
                [_allSubregionItems addObject:subregion];
            else
                [self collectSubregionItems:subregion];
        }
    }
    
}

- (void)collectSubregionItems:(OAWorldRegion *) region
{
    const auto citRegionResources = _resourcesByRegions.constFind(region);
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
                item.title = [self.class titleOfResource:resource_
                                                inRegion:region
                                          withRegionName:YES];
                item.resource = resource;
                item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                
                if (item.title == nil)
                    continue;
            }
            else
            {
                LocalResourceItem* item = [[LocalResourceItem alloc] init];
                item_ = item;
                item.resourceId = resource->id;
                item.title = [self.class titleOfResource:resource_
                                                inRegion:region
                                          withRegionName:YES];
                item.resource = resource;
                item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                
                if (item.title == nil)
                    continue;
            }
        }
        else if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource_))
        {
            RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
            item_ = item;
            item.resourceId = resource->id;
            item.title = [self.class titleOfResource:resource_
                                            inRegion:region
                                      withRegionName:YES];
            item.resource = resource;
            item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
            
            if (item.title == nil)
                continue;
        }
        
        if (region == self.region)
            _regionMap = item_;
        else
            [_allResourceItems addObject:item_];
        
    }
}

- (void)collectResourcesDataAndItems
{
    [self collectSubregionItems:self.region];
    
    [_allResourceItems addObjectsFromArray:_allSubregionItems];
    [_allResourceItems sortUsingComparator:self.resourceItemsComparator];
    
    // Outdated Resources
    [_localResourceItems removeAllObjects];
    [_outdatedResourceItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:self.region
                                                                      thatContainsResource:resource->id];
        if (!match)
            continue;

        OutdatedResourceItem* item = [[OutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [self.class titleOfResource:resource
                                  inRegion:match
                            withRegionName:YES];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;
        
        if (item.title != nil) {
            if (match == self.region) {
                _regionMap = item;
            } else {
                [_outdatedResourceItems addObject:item];
                [_localResourceItems addObject:item];
            }
        }
    }
    [_outdatedResourceItems sortUsingComparator:self.resourceItemsComparator];
    
    // Local Resources
    for (const auto& resource : _localResources)
    {
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:self.region
                                                                      thatContainsResource:resource->id];
        if (!match)
            continue;
        
        LocalResourceItem* item = [[LocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [self.class titleOfResource:resource
                                        inRegion:match
                                  withRegionName:YES];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        
        if (item.title != nil) {
            if (match == self.region) {
                if (!_regionMap)
                    _regionMap = item;
                
            } else {
                
                BOOL exists = NO;
                for (LocalResourceItem *i in _localResourceItems)
                    if ([i.resourceId.toNSString() isEqualToString:item.resourceId.toNSString()]) {
                        exists = YES;
                        break;
                    }
                if (!exists)
                    [_localResourceItems addObject:item];
            }
        }
    }
    [_localResourceItems sortUsingComparator:self.resourceItemsComparator];
    
    NSMutableSet* regionsSet = [NSMutableSet set];
    for (OutdatedResourceItem* item in _outdatedResourceItems)
        [regionsSet addObject:item.worldRegion];
    _regionsWithOutdatedResources = [[regionsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;

        // Updates always go first
        if (_currentScope == kAllResourcesScope && [_outdatedResourceItems count] > 0 && self.region == _app.worldRegion)
            _outdatedResourcesSection = _lastUnusedSectionIndex++;
        else
            _outdatedResourcesSection = -1;

        if (_currentScope == kAllResourcesScope && [_localResourceItems count] > 0 && self.region == _app.worldRegion)
            _localResourcesSection = _lastUnusedSectionIndex++;
        else
            _localResourcesSection = -1;

        if ([[self getResourceItems] count] > 0)
            _resourcesSection = _lastUnusedSectionIndex++;
        else
            _resourcesSection = -1;

        if (_regionMap)
            _regionMapSection = _lastUnusedSectionIndex++;
        else
            _regionMapSection = -1;

        // Configure search scope
        self.searchDisplayController.searchBar.scopeButtonTitles = nil;
        self.searchDisplayController.searchBar.placeholder = OALocalizedString(@"Search worldwide");
    }
}

- (void)refreshContent:(BOOL)update
{
    @synchronized(_dataLock)
    {
        if (self.searchDisplayController.isActive)
        {
            if (update)
                [self updateSearchResults];
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        [self.tableView reloadData];
    }
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
    return [self.class titleOfResource:resource
                        inRegion:self.region
                  withRegionName:includeRegionName];
}

- (void)updateSearchResults
{
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];
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
        NSArray* searchableContent = _searchableWorldwideRegionItems;

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
            if (region.subregions.count > 0)
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
                        item.title = [self.class titleOfResource:resource_
                                                  inRegion:region
                                            withRegionName:YES];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                        item.worldRegion = region;

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                    else
                    {
                        LocalResourceItem* item = [[LocalResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.title = [self.class titleOfResource:resource_
                                                  inRegion:region
                                            withRegionName:YES];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                        item.worldRegion = region;

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                }
                else if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource_))
                {
                    RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.title = [self.class titleOfResource:resource_
                                              inRegion:region
                                        withRegionName:YES];
                    item.resource = resource;
                    item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                    item.worldRegion = region;
                    
                    if (item.title == nil)
                        continue;

                    [resourceItems addObject:item];
                }
            }
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
    _doDataUpdateReload = YES;
    _refreshRepositoryBarButton.enabled = NO;
    [_refreshRepositoryProgressHUD showAnimated:YES
                            whileExecutingBlock:^{
                                _app.resourcesManager->updateRepository();
                            }
                                completionBlock:^{
                                    _refreshRepositoryBarButton.enabled = YES;
                                    if (self.openFromSplash)
                                        [self onSearchBtnClicked:nil];
                                }];
}

- (void)showDetailsOf:(LocalResourceItem*)item
{
    /*
    NSString* resourceId = item.resourceId.toNSString();
    UIViewController* detailsViewController = nil;
    if (self.searchDisplayController.isActive)
    {
        //NOTE: What a freaky way to do this...
        self.navigationItem.backBarButtonItem = _searchBackButton;
        detailsViewController = [[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId
                                                                                                forRegion:item.worldRegion];
    }
    else
    {
        self.navigationItem.backBarButtonItem = nil;
        detailsViewController = [[OALocalResourceInformationViewController alloc] initWithLocalResourceId:resourceId];
    }

    [self.navigationController pushViewController:detailsViewController
                                         animated:YES];
     */
}

- (IBAction)onDoneClicked:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)onCustomBackButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
- (IBAction)onScopeChanged:(id)sender
{
    _currentScope = _scopeControl.selectedSegmentIndex;

    [self prepareContent];
    [self refreshContent];
}
 */

- (IBAction)onUpdateBtnClicked:(id)sender
{
    [self onRefreshRepositoryButtonClicked];
}

- (IBAction)onSearchBtnClicked:(id)sender
{
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)onRefreshRepositoryButtonClicked
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepository];
    else
        [self showNoInternetAlertForCatalogUpdate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;

    if (_currentScope == kLocalResourcesScope)
        return 1 + (_regionMap ? 1 : 0);

    NSInteger sectionsCount = 0;

    if (_localResourcesSection > 0)
        sectionsCount++;
    if (_outdatedResourcesSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;
    if (_regionMap)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults count];

    if (section == _outdatedResourcesSection)
        return 1;
    if (section == _resourcesSection)
        return [[self getResourceItems] count];
    if (section == _localResourcesSection)
        return 1;
    if (section == _regionMapSection)
        return 1;

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;

    if (self.region.superregion == nil)
    {
        if (_currentScope == kLocalResourcesScope) {
            if (section == _regionMapSection)
                return OALocalizedString(@"World Map");
            else
                return OALocalizedString(@"Maps & resources");

        }
        
        if (section == _outdatedResourcesSection)
            return OALocalizedString(@"Updates");
        if (section == _resourcesSection)
            return OALocalizedString(@"Worldwide");
        if (section == _localResourcesSection)
            return OALocalizedString(@"Installed");
        if (section == _regionMapSection)
            return OALocalizedString(@"World Map");
        return nil;
    }

    if (section == _outdatedResourcesSection)
        return OALocalizedString(@"Updates");
    if (section == _resourcesSection)
        return OALocalizedString(@"Maps & resources");
    if (section == _localResourcesSection)
        return OALocalizedString(@"Installed");
    if (section == _regionMapSection)
        return OALocalizedString(@"Region Map");

    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const subregionCell = @"subregionCell";
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const localResourceCell = @"localResourceCell";
    static NSString* const repositoryResourceCell = @"repositoryResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";
    static NSString* const outdatedResourcesSubmenuCell = @"outdatedResourcesSubmenuCell";
    static NSString* const installedResourcesSubmenuCell = @"installedResourcesSubmenuCell";

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
            if (item.worldRegion.superregion)
                subtitle = item.worldRegion.superregion.name;
            else
                subtitle = item.worldRegion.name;
        }
    }
    else
    {
        if (indexPath.section == _outdatedResourcesSection && _outdatedResourcesSection >= 0)
        {
            cellTypeId = outdatedResourcesSubmenuCell;
            title = OALocalizedString(@"Updates available");

            NSArray* regionsNames = [_regionsWithOutdatedResources valueForKey:NSStringFromSelector(@selector(name))];
            subtitle = [TTTArrayFormatter localizedStringFromArray:regionsNames
                                                        arrayStyle:TTTArrayFormatterSentenceStyle];
        }
        else if (indexPath.section == _localResourcesSection && _localResourcesSection >= 0)
        {
            cellTypeId = installedResourcesSubmenuCell;
            title = OALocalizedString(@"Installed");
            
            subtitle = [NSString stringWithFormat:@"%d map(s)", _localResources.count()];
        }
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
        {
            item_ = [[self getResourceItems] objectAtIndex:indexPath.row];

            if ([item_ isKindOfClass:[OAWorldRegion class]])
            {
                OAWorldRegion* item = (OAWorldRegion*)item_;
                
                cellTypeId = subregionCell;
                title = item.name;
                if (item.superregion != nil)
                    subtitle = item.superregion.name;
                
            } else {
                
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
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            ResourceItem* item = _regionMap;
            
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
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    if ([cellTypeId isEqualToString:outdatedResourcesSubmenuCell])
    {
        [_updateCouneView setText:[NSString stringWithFormat:@"%d", _outdatedResources.count()]];
        cell.accessoryView = _updateCouneView;
    }

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
    {
        item = [_searchResults objectAtIndex:indexPath.row];
    }
    else if (tableView == self.tableView)
    {
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
        if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
            item = _regionMap;
    }

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (_searchResults.count > 0) {
            item = [_searchResults objectAtIndex:indexPath.row];
        }
    }
    else if (tableView == self.tableView) {
        
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
        if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
            item = _regionMap;
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
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
        if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
            item = _regionMap;
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
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
        if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
            item = _regionMap;
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
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
            item = [[self getResourceItems] objectAtIndex:indexPath.row];
        if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
            item = _regionMap;
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

- (BOOL)prefersStatusBarHidden
{
    return _isSearching;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    _isSearching = YES;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [self setNeedsStatusBarAppearanceUpdate];
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         CGRect newBounds = self.tableView.bounds;
                         newBounds.origin.y = 0.0;
                         self.tableView.bounds = newBounds;
                         self.titlePanelView.frame = CGRectOffset(self.titlePanelView.frame, 0.0, -64.0);
                         self.tableView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
                         
                     } completion:^(BOOL finished) {
                         self.titlePanelView.userInteractionEnabled = NO;
                     }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    _isSearching = NO;

    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
        [self setNeedsStatusBarAppearanceUpdate];
    //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.titlePanelView.frame = CGRectOffset(self.titlePanelView.frame, 0.0, 64.0);
                         self.tableView.frame = CGRectMake(0.0, 64.0, self.view.bounds.size.width, self.view.bounds.size.height - 64.0);

                     } completion:^(BOOL finished) {
                         self.titlePanelView.userInteractionEnabled = YES;
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
            if (tableView == self.searchDisplayController.searchResultsTableView)
                subregion = [_searchResults objectAtIndex:cellPath.row];
            else if (tableView == _tableView)
                subregion = [[self getResourceItems] objectAtIndex:cellPath.row];

            return (subregion != nil);
        }
    }

    return YES;
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

        subregionViewController->hideUpdateButton = YES;
        subregionViewController->_doNotSearch = _isSearching || _doNotSearch;
        
        OAWorldRegion* subregion = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView)
        {
            subregion = [_searchResults objectAtIndex:cellPath.row];
        }
        else if (tableView == _tableView)
        {
            subregion = [[self getResourceItems] objectAtIndex:cellPath.row];

            self.navigationItem.backBarButtonItem = nil;
        }

        [subregionViewController setupWithRegion:subregion
                             andWorldRegionItems:nil
                                        andScope:_currentScope];
    }
    else if ([segue.identifier isEqualToString:kOpenOutdatedResourcesSegue])
    {
        OAOutdatedResourcesViewController* outdatedResourcesViewController = [segue destinationViewController];

        [outdatedResourcesViewController setupWithRegion:self.region
                                        andOutdatedItems:_outdatedResourceItems];
    }
    else if ([segue.identifier isEqualToString:kOpenInstalledResourcesSegue])
    {
        OAManageResourcesViewController* subregionViewController = [segue destinationViewController];
        
        subregionViewController->hideUpdateButton = YES;
        subregionViewController->_doNotSearch = _isSearching || _doNotSearch;
        subregionViewController->_currentScope = kLocalResourcesScope;
        
    }
    else if ([segue.identifier isEqualToString:kOpenDetailsSegue])
    {
        OALocalResourceInformationViewController* resourceInfoViewController = [segue destinationViewController];

        LocalResourceItem* item = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView)
            item = [_searchResults objectAtIndex:cellPath.row];
        else if (tableView == self.tableView)
        {
            if (cellPath.section == _resourcesSection && _resourcesSection >= 0)
                item = [[self getResourceItems] objectAtIndex:cellPath.row];
            if (cellPath.section == _regionMapSection && _regionMapSection >= 0)
                item = (LocalResourceItem*)_regionMap;
        }

        if (item) {
            
            if (item.worldRegion) {
                resourceInfoViewController.regionTitle = item.worldRegion.name;
            } else if (self.region.name) {
                resourceInfoViewController.regionTitle = self.region.name;
            } else {
                resourceInfoViewController.regionTitle = item.title;
            }
            
            NSString* resourceId = item.resourceId.toNSString();
            [resourceInfoViewController initWithLocalResourceId:resourceId];
        }

    }
}

#pragma mark -

@end
