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

#import "OAPurchasesViewController.h"
#import "OAResourcesInstaller.h"
#import "OAIAPHelper.h"

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

    NSMutableArray* _regionMapItems;
    NSMutableArray* _localRegionMapItems;
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
    
    uint64_t _totalInstalledSize;

    MBProgressHUD* _refreshRepositoryProgressHUD;
    UIBarButtonItem* _refreshRepositoryBarButton;
    
    BOOL _isSearching;
    BOOL _doNotSearch;
    BOOL hideUpdateButton;
    
    UILabel *_updateCouneView;
    BOOL _doDataUpdate;
    BOOL _doDataUpdateReload;
    
    BOOL _displayBanner;
    UIView *_freeDownloadsView;
    UIView *_freeDownloadsBanner;
    UILabel *_freeTextLabel;
    UIButton *_btnPurchasesOnBanner;
    NSInteger _bannerSection;
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

        _regionMapItems = [NSMutableArray array];
        _localRegionMapItems = [NSMutableArray array];

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
    
#if !defined(OSMAND_IOS_DEV)
    if (_currentScope == kLocalResourcesScope ||
        (self.region == _app.worldRegion && [[OAIAPHelper sharedInstance] isAnyMapPurchased]) ||
        (self.region != _app.worldRegion && [self.region isInPurchasedArea]))
        _displayBanner = NO;
    else
        _displayBanner = YES;
#endif

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
    
    if (_displayBanner) {
        _freeDownloadsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 76.0)];
        _freeDownloadsView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        UIColor *bannerColor;
        if ([OAIAPHelper freeMapsAvailable] > 0)
            bannerColor = [UIColor colorWithRed:0.306f green:0.792f blue:0.388f alpha:1.00f];
        else
            bannerColor = [UIColor colorWithRed:0.992f green:0.749f blue:0.176f alpha:1.00f];
        
        _freeDownloadsBanner = [[UIView alloc] initWithFrame:CGRectMake(15.0, 15.0, 70.0, 60.0)];
        _freeDownloadsBanner.backgroundColor = bannerColor;
        _freeDownloadsBanner.layer.cornerRadius = 5.0;
        _freeDownloadsBanner.layer.masksToBounds = YES;
        _freeDownloadsBanner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_freeDownloadsView addSubview:_freeDownloadsBanner];
        
        _freeTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 6.0, 46.0, 48.0)];
        _freeTextLabel.backgroundColor = bannerColor;
        _freeTextLabel.textColor = [UIColor whiteColor];
        _freeTextLabel.font = [UIFont fontWithName:@"Avenir-Light" size:17.0];
        _freeTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _freeTextLabel.numberOfLines = 2;
        
        [_freeDownloadsBanner addSubview:_freeTextLabel];
        
        _btnPurchasesOnBanner = [[UIButton alloc] initWithFrame:_freeDownloadsBanner.bounds];
        [_btnPurchasesOnBanner addTarget:self action:@selector(btnToolbarPurchasesClicked:) forControlEvents:UIControlEventTouchUpInside];
        _btnPurchasesOnBanner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_freeDownloadsBanner addSubview:_btnPurchasesOnBanner];
    }
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
    
    [self updateFreeDownloadsBanner];
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceInstalled:) name:OAResourceInstalledNotification object:nil];
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

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tableView.editing = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (_freeTextLabel) {
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
            _freeTextLabel.textAlignment = NSTextAlignmentLeft;
        else
            _freeTextLabel.textAlignment = NSTextAlignmentCenter;        
    }
}

-(void)updateFreeDownloadsBanner
{
    int freeMaps = [OAIAPHelper freeMapsAvailable];

    UIColor *bannerColor;
    if (freeMaps > 0)
        bannerColor = [UIColor colorWithRed:0.306f green:0.792f blue:0.388f alpha:1.00f];
    else
        bannerColor = [UIColor colorWithRed:0.992f green:0.749f blue:0.176f alpha:1.00f];

    _freeDownloadsBanner.backgroundColor = bannerColor;
    _freeTextLabel.backgroundColor = bannerColor;

    if (freeMaps > 1) {
        _freeTextLabel.text = [NSString stringWithFormat:@"There are %d free maps available without updates", freeMaps];
    } else if (freeMaps == 1) {
        _freeTextLabel.text = @"There is one free map available without update";
    } else {
        _freeTextLabel.text = @"You have no free maps availabe for download/update";
    }
}

- (void)resourceInstalled:(NSNotification *)notification {
    
    NSString * resourceId = notification.object;
    OAWorldRegion* match = [OAResourcesBaseViewController findRegionOrAnySubregionOf:_app.worldRegion
                                                                thatContainsResource:QString([resourceId UTF8String])];
    
    if (!match || ![match isInPurchasedArea])
        [OAIAPHelper decreaseFreeMapsCount];
}

- (void)updateContent
{
    _doDataUpdate = YES;
    [self obtainDataAndItems];
    [self prepareContent];
    [self refreshContent:YES];
    
    if (_displayBanner)
        [self updateFreeDownloadsBanner];
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
        
        if ([region purchased] || [region isInPurchasedArea]) {
            for (const auto& resource : _outdatedResources)
            {
                if (!resource->id.startsWith(downloadsIdPrefix))
                    continue;
                
                regionResources.allResources.insert(resource->id, resource);
                regionResources.outdatedResources.insert(resource->id, resource);
                regionResources.localResources.insert(resource->id, resource);
            }
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
                }
            for (const auto& resource : regionResPrevious.localResources)
                if (!regionResources.allResources.contains(resource->id)) {
                    regionResources.allResources.insert(resource->id, _resourcesInRepository.value(resource->id));
                }
        }
        
        _resourcesByRegions.insert(region, regionResources);
    }
}
- (void)collectSubregionsDataAndItems
{
    // Collect all regions (and their parents) that have at least one
    // resource available in repository or locally.
    
    [_allResourceItems removeAllObjects];
    [_allSubregionItems removeAllObjects];
    [_regionMapItems removeAllObjects];
    [_localRegionMapItems removeAllObjects];
    
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
                item.size = resource->size;
                item.worldRegion = region;
                
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
                item.size = resource->size;
                item.worldRegion = region;
                
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
            item.size = resource->size;
            item.sizePkg = resource->packageSize;
            item.worldRegion = region;

            if (item.title == nil)
                continue;
        }
        
        if (region == self.region)
            [_regionMapItems addObject:item_];
        else
            [_allResourceItems addObject:item_];
        
    }
}

- (void)collectResourcesDataAndItems
{
    [self collectSubregionItems:self.region];
    
    [_allResourceItems addObjectsFromArray:_allSubregionItems];
    [_allResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_regionMapItems sortUsingComparator:self.resourceItemsComparator];
    
    // Outdated Resources
    [_localResourceItems removeAllObjects];
    [_outdatedResourceItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:self.region
                                                                      thatContainsResource:resource->id];
        if (!match || ![match isInPurchasedArea])
            continue;

        OutdatedResourceItem* item = [[OutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [self.class titleOfResource:resource
                                  inRegion:match
                            withRegionName:YES];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;
        item.size = resource->size;
        
        if (item.title != nil) {
            if (match == self.region)
                [_localRegionMapItems addObject:item];
            else
                [_localResourceItems addObject:item];
        
            [_outdatedResourceItems addObject:item];
        }
    }
    [_outdatedResourceItems sortUsingComparator:self.resourceItemsComparator];
    
    // Local Resources
    _totalInstalledSize = 0;
    for (const auto& resource : _localResources)
    {        
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:self.region
                                                                      thatContainsResource:resource->id];
        
        if (!match && (resource->type != OsmAndResourceType::MapRegion))
            continue;
        
        LocalResourceItem* item = [[LocalResourceItem alloc] init];
        item.resourceId = resource->id;
        if (match)
            item.title = [self.class titleOfResource:resource
                                        inRegion:match
                                  withRegionName:YES];
        else
            item.title = resource->id.toNSString();
            
        item.resource = resource;
        if (match)
            item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.size = resource->size;
        item.worldRegion = match;
        
        _totalInstalledSize += resource->size;
        
        if (item.title != nil) {
            if (match == self.region) {
                
                if (![_localRegionMapItems containsObject:item])
                    [_localRegionMapItems addObject:item];
                
            } else {
                
                if (![_localResourceItems containsObject:item])
                    [_localResourceItems addObject:item];
            }
        }
    }
    [_localResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_localRegionMapItems sortUsingComparator:self.resourceItemsComparator];
    
    if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_Nautical]) {
        for (ResourceItem *item in _regionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksKey)) == 0) {
                [_regionMapItems removeObject:item];
                break;
            }
        for (ResourceItem *item in _localRegionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksKey)) == 0) {
                [_localRegionMapItems removeObject:item];
                break;
            }
    }
    
    NSMutableSet* regionsSet = [NSMutableSet set];
    for (OutdatedResourceItem* item in _outdatedResourceItems)
        if (item.worldRegion.regionId)
            [regionsSet addObject:item.worldRegion];
    _regionsWithOutdatedResources = [[regionsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;

        if (_displayBanner)
            _bannerSection = _lastUnusedSectionIndex++;
        else
            _bannerSection = -1;
        
        
        // Updates always go first
        if (_currentScope == kAllResourcesScope && [_outdatedResourceItems count] > 0 && self.region == _app.worldRegion)
            _outdatedResourcesSection = _lastUnusedSectionIndex++;
        else
            _outdatedResourcesSection = -1;

        if (_currentScope == kAllResourcesScope && ([_localResourceItems count] > 0 || [_localRegionMapItems count] > 0) && self.region == _app.worldRegion)
            _localResourcesSection = _lastUnusedSectionIndex++;
        else
            _localResourcesSection = -1;

        if ([[self getResourceItems] count] > 0)
            _resourcesSection = _lastUnusedSectionIndex++;
        else
            _resourcesSection = -1;

        if ([[self getRegionMapItems] count] > 0)
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

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        if (self.searchDisplayController.isActive)
        {
            for (int i = 0; i < _searchResults.count; i++) {
                if ([_searchResults[i] isKindOfClass:[OAWorldRegion class]])
                    continue;
                ResourceItem *item = _searchResults[i];
                if ([[item.downloadTask key] isEqualToString:downloadTaskKey]) {
                    [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                    return;
                }
            }
        }

        NSMutableArray *resourceItems = [self getResourceItems];
        for (int i = 0; i < resourceItems.count; i++) {
            if ([resourceItems[i] isKindOfClass:[OAWorldRegion class]])
                continue;
            ResourceItem *item = resourceItems[i];
            if ([[item.downloadTask key] isEqualToString:downloadTaskKey]) {
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:(_displayBanner ? 1 : 0)]];
                break;
            }
        }
        
        NSMutableArray *regionMapItems = [self getRegionMapItems];
        for (int i = 0; i < regionMapItems.count; i++) {
            ResourceItem *item = regionMapItems[i];
            if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_regionMapSection]];
        }

    }
}

- (void) updateTableLayout
{
    CGRect frame = self.tableView.frame;
    CGFloat h = self.view.bounds.size.height - self.toolbarView.bounds.size.height - frame.origin.y;
    if (self.downloadView.superview)
        h -= self.downloadView.bounds.size.height;
    
    [UIView animateWithDuration:.2 animations:^{
        self.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    }];
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

- (NSMutableArray*)getRegionMapItems
{
    switch (_currentScope)
    {
        case kAllResourcesScope:
            return _regionMapItems;
            
        case kLocalResourcesScope:
            return _localRegionMapItems;
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

-(void)backButtonClicked:(id)sender
{
    if (self.region.regionId == nil && _currentScope == kAllResourcesScope)
        [self.navigationController popToRootViewControllerAnimated:YES];
    else
        [self.navigationController popViewControllerAnimated:YES];
    
}

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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;

    if (section == _bannerSection)
        return _freeDownloadsView;
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 0.0;

    if (section == _bannerSection)
        return _freeDownloadsView.bounds.size.height;
    
    if (section == 0)
        return 56.0;
    
    return 40.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;

    if (_currentScope == kLocalResourcesScope)
        return ([_localResourceItems count] > 0 ? 1 : 0) + ([_localRegionMapItems count] ? 1 : 0);

    NSInteger sectionsCount = 0;

    if (_bannerSection >= 0)
        sectionsCount++;
    if (_localResourcesSection >= 0)
        sectionsCount++;
    if (_outdatedResourcesSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;
    if (_regionMapSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResults count];

    if (section == _bannerSection)
        return 0;
    if (section == _outdatedResourcesSection)
        return 1;
    if (section == _resourcesSection)
        return [[self getResourceItems] count];
    if (section == _localResourcesSection)
        return 1;
    if (section == _regionMapSection)
        return [[self getRegionMapItems] count];

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

-(void)updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableView *tableView;
    if (self.searchDisplayController.isActive)
        tableView = self.searchDisplayController.searchResultsTableView;
    else
        tableView = self.tableView;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";
    
    NSString* cellTypeId = nil;
    id item_ = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        item_ = [_searchResults objectAtIndex:indexPath.row];
        
        if (![item_ isKindOfClass:[OAWorldRegion class]])
        {
            ResourceItem* item = (ResourceItem*)item_;
            
            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
            
        }
    }
    else
    {
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
        {
            item_ = [[self getResourceItems] objectAtIndex:indexPath.row];
            
            if (![item_ isKindOfClass:[OAWorldRegion class]])
            {
                ResourceItem* item = (ResourceItem*)item_;
                
                if (item.downloadTask != nil)
                    cellTypeId = downloadingResourceCell;
            }
        }
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            item_ = [[self getRegionMapItems] objectAtIndex:indexPath.row];
            ResourceItem* item = (ResourceItem*)item_;
            
            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
        }
    }
    
    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        ResourceItem* item = (ResourceItem*)item_;
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [self tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            progressView.progress = 0.0f;
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }

}

-(UIBezierPath *)tickPath:(FFCircularProgressView *)progressView
{
    CGFloat radius = MIN(progressView.frame.size.width, progressView.frame.size.height)/2;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat tickWidth = radius * .3;
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, tickWidth * 2)];
    [path addLineToPoint:CGPointMake(tickWidth * 3, tickWidth * 2)];
    [path addLineToPoint:CGPointMake(tickWidth * 3, tickWidth)];
    [path addLineToPoint:CGPointMake(tickWidth, tickWidth)];
    [path addLineToPoint:CGPointMake(tickWidth, 0)];
    [path closePath];
    
    [path applyTransform:CGAffineTransformMakeRotation(-M_PI_4)];
    [path applyTransform:CGAffineTransformMakeTranslation(radius * .46, 1.02 * radius)];
    
    return path;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
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
            
            subtitle = [NSString stringWithFormat:@"%d map(s) - %@", (int)_localResourceItems.count + _localRegionMapItems.count, [NSByteCountFormatter stringFromByteCount:_totalInstalledSize countStyle:NSByteCountFormatterCountStyleFile]];
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
                uint64_t _size = item.size;
                uint64_t _sizePkg = item.sizePkg;
                
                if (item.downloadTask != nil)
                    cellTypeId = downloadingResourceCell;
                else if ([item isKindOfClass:[OutdatedResourceItem class]])
                    cellTypeId = outdatedResourceCell;
                else if ([item isKindOfClass:[LocalResourceItem class]])
                    cellTypeId = localResourceCell;
                else if ([item isKindOfClass:[RepositoryResourceItem class]]) {
                    cellTypeId = repositoryResourceCell;
                }
                
                title = item.title;
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:_size countStyle:NSByteCountFormatterCountStyleFile]];
                else
                    subtitle = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:_size countStyle:NSByteCountFormatterCountStyleFile]];
            }
        }
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            item_ = [[self getRegionMapItems] objectAtIndex:indexPath.row];

            ResourceItem* item = (ResourceItem*)item_;
            uint64_t _size = item.size;
            uint64_t _sizePkg = item.sizePkg;
            
            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
            else if ([item isKindOfClass:[OutdatedResourceItem class]])
                cellTypeId = outdatedResourceCell;
            else if ([item isKindOfClass:[LocalResourceItem class]])
                cellTypeId = localResourceCell;
            else if ([item isKindOfClass:[RepositoryResourceItem class]]) {
                cellTypeId = repositoryResourceCell;
            }
            
            title = item.title;
            if (_sizePkg > 0)
                subtitle = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:_size countStyle:NSByteCountFormatterCountStyleFile]];
            else
                subtitle = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:_size countStyle:NSByteCountFormatterCountStyleFile]];
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
            cell.textLabel.font = [UIFont fontWithName:@"Avenir-Light" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12.0];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont fontWithName:@"Avenir-Light" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12.0];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            cell.textLabel.font = [UIFont fontWithName:@"Avenir-Light" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12.0];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];

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
        [_updateCouneView setText:[NSString stringWithFormat:@"%d", _outdatedResourceItems.count]];
        cell.accessoryView = _updateCouneView;
    }

    // Fill cell content
    cell.textLabel.text = title;
    if (cell.detailTextLabel != nil)
        cell.detailTextLabel.text = subtitle;
    
    if ([cellTypeId isEqualToString:subregionCell]) {
    
        OAWorldRegion* item = (OAWorldRegion*)item_;
        
        if (item.superregion.regionId == nil) {
            if ([item purchased]) {

                BOOL viewExists = NO;
                for (UIView *view in cell.contentView.subviews)
                    if (view.tag == -1) {
                        viewExists = YES;
                        break;
                    }

                if (!viewExists) {
                    UIView *purchasedView = [[UIView alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 14.0, cell.contentView.bounds.size.height / 2.0 - 5.0, 10.0, 10.0)];
                    purchasedView.layer.cornerRadius = 5.0;
                    purchasedView.layer.masksToBounds = YES;
                    purchasedView.layer.backgroundColor = [UIColor colorWithRed:0.306f green:0.792f blue:0.388f alpha:1.00f].CGColor;
                    purchasedView.tag = -1;
                    purchasedView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
                    
                    [cell.contentView addSubview:purchasedView];
                }
                
            } else {
                for (UIView *view in cell.contentView.subviews)
                    if (view.tag == -1) {
                        [view removeFromSuperview];
                        break;
                    }
            }
        }
        
    }
    else if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        ResourceItem* item = (ResourceItem*)item_;
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [self tickPath:progressView];
            progressView.progress = 0.0f;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            [progressView setNeedsDisplay];
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
            item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
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
            item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
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
            item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
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
            item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
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
            item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
    }

    if (item == nil)
        return;

    if ([item isKindOfClass:[LocalResourceItem class]]) {
        [self offerDeleteResourceOf:item];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         CGRect newBounds = self.tableView.bounds;
                         newBounds.origin.y = 0.0;
                         self.tableView.bounds = newBounds;
                         
                         self.titlePanelView.frame = CGRectMake(0.0, -self.titlePanelView.frame.size.height, self.titlePanelView.frame.size.width, self.titlePanelView.frame.size.height);
                         self.toolbarView.frame = CGRectMake(0.0, self.view.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
                         self.tableView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
                         
                     } completion:^(BOOL finished) {
                         self.titlePanelView.userInteractionEnabled = NO;
                     }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    _isSearching = NO;

    [self setNeedsStatusBarAppearanceUpdate];

    CGFloat h = self.view.bounds.size.height - 64.0 - 61.0;
    if (self.downloadView && self.downloadView.superview)
        h -= self.downloadView.bounds.size.height;

    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.titlePanelView.frame = CGRectMake(0.0, 0.0, self.titlePanelView.frame.size.width, self.titlePanelView.frame.size.height);
                         self.toolbarView.frame = CGRectMake(0.0, self.view.frame.size.height - self.toolbarView.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
                         self.tableView.frame = CGRectMake(0.0, 64.0, self.view.bounds.size.width, h);

                     } completion:^(BOOL finished) {
                         self.titlePanelView.userInteractionEnabled = YES;
                         if (_displayBanner)
                             [self.tableView reloadData];
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
        outdatedResourcesViewController.openFromSplash = _openFromSplash;
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
        resourceInfoViewController.openFromSplash = _openFromSplash;
        resourceInfoViewController.baseController = self;
        
        LocalResourceItem* item = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView)
            item = [_searchResults objectAtIndex:cellPath.row];
        else if (tableView == self.tableView)
        {
            if (cellPath.section == _resourcesSection && _resourcesSection >= 0)
                item = [[self getResourceItems] objectAtIndex:cellPath.row];
            if (cellPath.section == _regionMapSection && _regionMapSection >= 0)
                item = [[self getRegionMapItems] objectAtIndex:cellPath.row];
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
        resourceInfoViewController.localItem = item;

    }
}

#pragma mark -

- (IBAction)btnToolbarMapsClicked:(id)sender
{
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:purchasesViewController animated:NO];
}

@end
