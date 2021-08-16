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
#import "UITableViewCell+getTableView.h"
#import "OARootViewController.h"
#import "OALocalResourceInformationViewController.h"
#import "OAOsmAndLiveViewController.h"
#import "OAOutdatedResourcesViewController.h"
#import "OAWorldRegion.h"
#import "OALog.h"
#import "OAOcbfHelper.h"
#import "OABannerView.h"
#import "OAUtilities.h"
#import "OAInAppCell.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAFreeMemoryView.h"
#import "OAAnalyticsHelper.h"
#import "OAChoosePlanHelper.h"
#import "OASubscribeEmailView.h"
#import "OANetworkUtilities.h"
#import "OASQLiteTileSource.h"
#import "OAFileNameTranslationHelper.h"
#import "OAPlugin.h"
#import "OACustomRegion.h"
#import "OADownloadDescriptionInfo.h"
#import "OATextViewSimpleCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OACustomSourceDetailsViewController.h"
#import "OAColors.h"

#include "Localization.h"

#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAResourcesInstaller.h"
#import "OAIAPHelper.h"
#import "OADownloadMultipleResourceViewController.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define kOpenSubregionSegue @"openSubregionSegue"
#define kOpenOutdatedResourcesSegue @"openOutdatedResourcesSegue"
#define kOpenDetailsSegue @"openDetailsSegue"
#define kOpenInstalledResourcesSegue @"openInstalledResourcesSegue"
#define kOpenOsmAndLiveSegue @"openOsmAndLiveSegue"


#define kAllResourcesScope 0
#define kLocalResourcesScope 1

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchResultsUpdating, OABannerViewDelegate, OASubscribeEmailViewDelegate, OADownloadMultipleResourceDelegate>

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
    OAIAPHelper *_iapHelper;

    NSObject *_dataLock;

    NSInteger _currentScope;

    NSInteger _lastUnusedSectionIndex;

    NSMutableArray *_allSubregionItems;

    NSInteger _freeMemorySection;
    NSInteger _subscribeEmailSection;

    NSMutableArray *_regionMapItems;
    NSMutableArray *_localRegionMapItems;
    
    NSInteger _downloadDescriptionSection;
    NSInteger _extraMapsSection;
    NSInteger _regionMapSection;
    NSInteger _osmAndLiveSection;
    NSInteger _otherMapsSection;
    NSInteger _nauticalMapsSection;

    NSInteger _outdatedResourcesSection;
    NSMutableArray *_outdatedResourceItems;
    NSArray *_regionsWithOutdatedResources;

    NSInteger _localResourcesSection;
    NSInteger _localSqliteSection;
    NSInteger _resourcesSection;
    NSInteger _localOnlineTileSourcesSection;
    NSMutableArray *_allResourceItems;
    NSMutableArray *_localResourceItems;
    NSMutableArray *_localSqliteItems;
    NSMutableArray *_localOnlineTileSources;

    NSString *_lastSearchString;
    NSInteger _lastSearchScope;
    NSArray *_searchResults;
    
    UISearchController *_searchController;
    
    uint64_t _totalInstalledSize;
    uint64_t _liveUpdatesInstalledSize;

    MBProgressHUD *_refreshRepositoryProgressHUD;
    
    BOOL _isSearching;
    BOOL _doNotSearch;
    BOOL hideUpdateButton;
    
    UILabel *_updateCouneView;
    BOOL _doDataUpdate;
    BOOL _doDataUpdateReload;
    
    BOOL _displayBanner;
    OABannerView *_bannerView;
    OAFreeMemoryView *_freeMemoryView;
    BOOL _displaySubscribeEmailView;
    OASubscribeEmailView *_subscribeEmailView;
    NSInteger _bannerSection;
    NSString *_purchaseInAppId;
    
    TTTArrayFormatter *_arrFmt;
    NSNumberFormatter *_numberFormatter;

    BOOL _srtmDisabled;
    BOOL _hasSrtm;

    CALayer *_horizontalLine;
    
    BOOL _viewAppeared;
    BOOL _repositoryUpdating;

    NSString *_otherRegionId;
    NSString *_nauticalRegionId;
    
    NSArray<OAWorldRegion *> *_customRegions;
    OADownloadDescriptionInfo *_downloadDescriptionInfo;

    NSArray<OAResourceItem *> *_multipleItems;
}

static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
static QHash< OAWorldRegion *__weak, RegionResources > _resourcesByRegions;

static NSMutableArray *_searchableWorldwideRegionItems;

static BOOL _lackOfResources;

+ (NSArray<NSString *> *)getResourcesInRepositoryIdsByRegion:(OAWorldRegion *)region
{
    const auto citRegionResources = _resourcesByRegions.constFind(region);
    if (citRegionResources == _resourcesByRegions.cend())
        return nil;
    const auto& regionResources = *citRegionResources;
    
    NSMutableArray<NSString *> *res = [NSMutableArray array];
    for (const auto& resource : regionResources.repositoryResources)
    {
        [res addObject:resource->id.toNSString()];
    }
    return [NSArray arrayWithArray:res];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];

        _dataLock = [[NSObject alloc] init];

        self.region = _app.worldRegion;
        _otherRegionId = OsmAnd::WorldRegions::OthersRegionId.toNSString();
        _nauticalRegionId = OsmAnd::WorldRegions::NauticalRegionId.toNSString();

        _currentScope = kAllResourcesScope;

        _allSubregionItems = [NSMutableArray array];

        _outdatedResourceItems = [NSMutableArray array];

        _allResourceItems = [NSMutableArray array];
        _localResourceItems = [NSMutableArray array];
        _localSqliteItems = [NSMutableArray array];
        _localOnlineTileSources = [NSMutableArray array];

        _regionMapItems = [NSMutableArray array];
        _localRegionMapItems = [NSMutableArray array];

        _lastSearchString = @"";
        _lastSearchScope = 0;
        _searchResults = nil;
        
        _arrFmt = [[TTTArrayFormatter alloc] init];
        _arrFmt.usesSerialDelimiter = NO;
        
        _viewAppeared = NO;
    }
    return self;
}

- (void)setupWithRegion:(OAWorldRegion *)region
    andWorldRegionItems:(NSArray *)worldRegionItems
               andScope:(NSInteger)scope
{
    self.region = region;
    _currentScope = scope;
}

- (void)applyLocalization
{
    [super applyLocalization];

    _titleView.text = OALocalizedString(@"res_mapsres");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];

    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    if (self.openFromSplash)
    {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
    
    if (self.region != _app.worldRegion)
        [self.titleView setText:self.region.name];
    else if (_currentScope == kLocalResourcesScope)
        [self.titleView setText:OALocalizedString(@"download_tab_local")];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 52.;

    _refreshRepositoryProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_refreshRepositoryProgressHUD];
    
    _displayBanner = ![self shouldHideBanner];
    _displaySubscribeEmailView = ![self shouldHideEmailSubscription];
    
    _customRegions = [OAPlugin getCustomDownloadRegions];
    if ([self.region isKindOfClass:OACustomRegion.class])
    {
        OACustomRegion *customReg = (OACustomRegion *) self.region;
        self.titlePanelView.backgroundColor = customReg.headerColor;
        _downloadDescriptionInfo = customReg.descriptionInfo;
    }

    [self obtainDataAndItems];
    [self prepareContent];
    
    // IOS-172
    _updateCouneView = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
    _updateCouneView.layer.cornerRadius = 10.0;
    _updateCouneView.layer.masksToBounds = YES;
    _updateCouneView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:143.0/255.0 blue:0.0 alpha:1.0];
    _updateCouneView.font = [UIFont systemFontOfSize:12.0];
    _updateCouneView.textAlignment = NSTextAlignmentCenter;
    _updateCouneView.textColor = [UIColor whiteColor];
    
    if (_displayBanner)
    {
        _bannerView = [[OABannerView alloc] init];
        _bannerView.delegate = self;
        [self updateBannerDimensions:DeviceScreenWidth];
        _bannerView.buttonTitle = OALocalizedString(@"shared_string_buy");
    }
    
    _freeMemoryView = [[OAFreeMemoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 64.0) localResourcesSize:_totalInstalledSize + _liveUpdatesInstalledSize];
    _subscribeEmailView = [[OASubscribeEmailView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 100.0)];
    _subscribeEmailView.delegate = self;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    self.definesPresentationContext = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateContentIfNeeded];
    
    if (_doNotSearch || _currentScope == kLocalResourcesScope)
    {
        
        CGRect f = _searchController.searchBar.frame;
        f.size.height = 0;
        _searchController.searchBar.frame = f;
        _searchController.searchBar.hidden = YES;
        
        self.searchButton.hidden = YES;
        
    }
    else
    {
        if (self.tableView.bounds.origin.y == 0)
        {
            // Hide the search bar until user scrolls up
            CGRect newBounds = self.tableView.bounds;
            newBounds.origin.y = newBounds.origin.y + _searchController.searchBar.bounds.size.height;
            self.tableView.bounds = newBounds;
        }
    }
    
    self.updateButton.hidden = hideUpdateButton;
    
    [self updateFreeDownloadsBanner];
    
    if (_displayBanner)
        [self updateBannerDimensions:DeviceScreenWidth];
    
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceInstallationFailed:) name:OAResourceInstallationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [[OARootViewController instance] requestProductsWithProgress:NO reload:NO];

    [self applySafeAreaMargins];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_viewAppeared)
    {
        // If there's no repository available and there's internet connection, just update it
        if (!_app.resourcesManager->isRepositoryAvailable())
        {
            if (!_app.isRepositoryUpdating &&
                [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            {
                [self updateRepository];
            }
            else if (self.region == _app.worldRegion &&
                     [Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
            {
                // show no internet popup
                [OAPluginPopupViewController showNoInternetConnectionFirst];
            }
            else if (_app.isRepositoryUpdating)
            {
                _repositoryUpdating = YES;
                _updateButton.enabled = NO;
                [_refreshRepositoryProgressHUD show:YES];
            }
        }
        else if (self.openFromSplash)
        {
            [self onSearchBtnClicked:nil];
        }
    }
    _viewAppeared = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tableView.editing = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (UIView *) getTopView
{
    return _titlePanelView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (_displayBanner)
    {
        [UIView animateWithDuration:duration animations:^{            
            [self.tableView beginUpdates];
            [self updateBannerDimensions:DeviceScreenHeight];
            [self.tableView endUpdates];
        }];
    }
}

- (BOOL) shouldHideBanner
{
    return _currentScope == kLocalResourcesScope || _iapHelper.subscribedToLiveUpdates || (self.region == _app.worldRegion && [_iapHelper isAnyMapPurchased]) || (self.region != _app.worldRegion && [self.region isInPurchasedArea]) || [self.region.regionId isEqualToString:_otherRegionId] || [self.region isKindOfClass:OACustomRegion.class];
}

- (BOOL) shouldHideEmailSubscription
{
    return _currentScope == kLocalResourcesScope || [_iapHelper.allWorld isPurchased] || _iapHelper.subscribedToLiveUpdates || [OAAppSettings sharedManager].emailSubscribed.get || [self.region isKindOfClass:OACustomRegion.class];
}

- (void) updateContentIfNeeded
{
    BOOL needUpdateContent = NO;
    if ([self shouldHideBanner] && _displayBanner)
    {
        _displayBanner = NO;
        needUpdateContent = YES;
    }
    if ([self shouldHideEmailSubscription] && _displaySubscribeEmailView)
    {
        _displaySubscribeEmailView = NO;
        needUpdateContent = YES;
    }
    
    if (needUpdateContent)
        [self updateContent];
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        // hide no internet popup
        [OAPluginPopupViewController hideNoInternetConnection];
        
        if (!_app.resourcesManager->isRepositoryAvailable() && !_app.isRepositoryUpdating)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateRepository];
            });
    }
}

- (void) updateBannerDimensions:(CGFloat)width
{
    CGFloat height = [_bannerView getHeightByWidth:width];
    _bannerView.frame = CGRectMake(_bannerView.frame.origin.x, _bannerView.frame.origin.y, width, height);
}

- (void) updateFreeDownloadsBanner
{
    NSString *title;
    NSString *desc;
    NSString *buttonTitle = OALocalizedString(@"shared_string_buy");
    
    OAProduct *product;
    NSString *regionId;
    
    if ([self.region isKindOfClass:OACustomRegion.class])
        return;

    if (self.region == _app.worldRegion)
    {
        if (!_displayBannerPurchaseAllMaps)
        {
            int freeMaps = [OAIAPHelper freeMapsAvailable];
            if (freeMaps > 0)
            {
                title = [NSString stringWithFormat:OALocalizedString(@"res_banner_free_maps_title"), freeMaps];
                desc = [NSString stringWithFormat:OALocalizedString(@"res_banner_free_maps_desc"), freeMaps];
            }
            else
            {
                title = OALocalizedString(@"res_banner_no_free_maps_title");
                desc = OALocalizedString(@"res_banner_no_free_maps_desc");
            }
            buttonTitle = OALocalizedString(@"get_unlimited_access");
        }
        else
        {
            product = _iapHelper.allWorld;
        }
    }
    else
    {
        // For some reason worldRegion can get corrupred in which case we get an infinite loop here
        OAWorldRegion *region = self.region;
        while (region.superregion != _app.worldRegion && region)
        {
            region = region.superregion;
        }

        if (region)
            regionId = region.regionId;
        
        if ([regionId isEqualToString:OsmAnd::WorldRegions::AntarcticaRegionId.toNSString()])
            product = _iapHelper.antarctica;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::AfricaRegionId.toNSString()])
            product = _iapHelper.africa;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::AsiaRegionId.toNSString()])
            product = _iapHelper.asia;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::AustraliaAndOceaniaRegionId.toNSString()])
            product = _iapHelper.australia;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::CentralAmericaRegionId.toNSString()])
            product = _iapHelper.centralAmerica;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::EuropeRegionId.toNSString()])
            product = _iapHelper.europe;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::NorthAmericaRegionId.toNSString()])
            product = _iapHelper.northAmerica;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()])
            product = _iapHelper.russia;
        else if ([regionId isEqualToString:OsmAnd::WorldRegions::SouthAmericaRegionId.toNSString()])
            product = _iapHelper.southAmerica;
    }

    if (product)
    {
        _purchaseInAppId = product.productIdentifier;
        title = product.localizedTitle;
        if (product.price)
        {
            [_numberFormatter setLocale:product.priceLocale];
            NSString *price = [_numberFormatter stringFromNumber:product.price];
            buttonTitle = [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"shared_string_buy"), price];
            desc = [NSString stringWithFormat:@"%@ %@ %@ %@", OALocalizedString(@"shared_string_buy"), product.localizedDescription, OALocalizedString(@"shared_string_buy_for"), price];
        }
        else
        {
            desc = product.localizedDescription;
        }
    }

    _bannerView.title = title;
    _bannerView.desc = desc;
    _bannerView.buttonTitle = buttonTitle;

    [_bannerView setNeedsLayout];
    [_bannerView setNeedsDisplay];
}

- (void) resourceInstallationFailed:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
    });
}

- (void) updateContent
{
    _doDataUpdate = YES;
    _customRegions = [OAPlugin getCustomDownloadRegions];
    [self updateMultipleResources];
    [self obtainDataAndItems];
    [self prepareContent];
    [self refreshContent:YES];
    
    if (_displayBanner)
        [self updateFreeDownloadsBanner];
    
    if (_repositoryUpdating)
    {
        _repositoryUpdating = NO;
        _updateButton.enabled = YES;

        [_refreshRepositoryProgressHUD hide:YES];
        if (self.openFromSplash)
            [self onSearchBtnClicked:nil];
    }
}

- (void)updateMultipleResources
{
    if (_multipleItems && _multipleItems.count > 0 && [self.region hasGroupItems])
    {
        NSMutableArray<OAResourceItem *> *multipleRepositoryItems = [_multipleItems mutableCopy];
        NSMutableArray *itemsToRemove = [NSMutableArray new];
        for (OAResourceItem *item in _multipleItems)
        {
            if (_app.resourcesManager->isResourceInstalled(item.resourceId))
                [itemsToRemove addObject:item];
        }
        [multipleRepositoryItems removeObjectsInArray:itemsToRemove];
        _multipleItems = multipleRepositoryItems.count > 0 ? [NSArray arrayWithArray:multipleRepositoryItems] : nil;
    }
}

- (void) obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        if (_doDataUpdateReload)
            _resourcesByRegions.clear();
        
        if (_doDataUpdate || _resourcesByRegions.count() == 0 || _lackOfResources)
            [OAManageResourcesViewController prepareData];

        [self collectSubregionsDataAndItems];
        [self collectResourcesDataAndItems];

        _doDataUpdate = NO;
        _doDataUpdateReload = NO;
    }
}

+ (BOOL) lackOfResources
{
    return _lackOfResources;
}

+ (void) prepareData
{
    _lackOfResources = NO;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    
    if (!app.resourcesManager->isRepositoryAvailable())
    {
        _lackOfResources = YES;
        return;
    }
    
    // Obtain all resources separately
    _resourcesInRepository = app.resourcesManager->getResourcesInRepository();
    _localResources = app.resourcesManager->getLocalResources();
    
    // IOS-199
    _outdatedResources = app.resourcesManager->getOutdatedInstalledResources();
    
    BOOL doInit = (_resourcesByRegions.count() == 0);
    BOOL initWorldwideRegionItems = (_searchableWorldwideRegionItems == nil) || doInit;
    
    if (initWorldwideRegionItems)
        _searchableWorldwideRegionItems = [NSMutableArray array];
    
    NSArray<OAWorldRegion *> *mergedRegions = [app.worldRegion.flattenedSubregions arrayByAddingObject:app.worldRegion];
    for (OAWorldRegion *region in mergedRegions)
    {
        if (initWorldwideRegionItems)
            [_searchableWorldwideRegionItems addObject:region];
        
        const auto regionId = QString::fromNSString(region.regionId);
        const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix).toLower();
        
        RegionResources regionResources;
        RegionResources regionResPrevious;

        if (!doInit)
        {
            const auto citRegionResources = _resourcesByRegions.constFind(region);
            if (citRegionResources != _resourcesByRegions.cend())
                regionResources = *citRegionResources;
        }

        if (!doInit)
        {
            for (const auto& resource : _localResources)
            {
                if (resource->id.startsWith(downloadsIdPrefix))
                    regionResources.allResources.remove(resource->id);
            }
            for (const auto& resource : regionResources.outdatedResources)
            {
                regionResPrevious.outdatedResources.insert(resource->id, resource);
                regionResources.allResources.remove(resource->id);
            }
            for (const auto& resource : regionResources.localResources)
            {
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
        
        if (doInit)
        {
            NSMutableArray *typesArray = [NSMutableArray array];
            BOOL hasSrtm = NO;
            for (const auto& resource : _resourcesInRepository)
            {
                if (!resource->id.startsWith(downloadsIdPrefix))
                    continue;
                
                switch (resource->type)
                {
                    case OsmAndResourceType::SrtmMapRegion:
                        hasSrtm = YES;
                    case OsmAndResourceType::MapRegion:
                    case OsmAndResourceType::WikiMapRegion:
                    case OsmAndResourceType::HillshadeRegion:
                    case OsmAndResourceType::SlopeRegion:
                    case OsmAndResourceType::DepthContourRegion:
                        [typesArray addObject:@((int) resource->type)];
                        break;
                    default:
                        break;
                }
                
                if (!regionResources.allResources.contains(resource->id))
                    regionResources.allResources.insert(resource->id, resource);
                
                regionResources.repositoryResources.insert(resource->id, resource);
            }

            region.resourceTypes = [typesArray sortedArrayUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2) {
                NSInteger orderValue1 = [OAResourceType getOrderIndex:num1];
                NSInteger orderValue2 = [OAResourceType getOrderIndex:num2];
                if (orderValue1 < orderValue2)
                    return NSOrderedAscending;
                else if (orderValue1 > orderValue2)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
            }];
        }
        else
        {
            for (const auto& resource : regionResPrevious.outdatedResources)
                if (!regionResources.allResources.contains(resource->id))
                    regionResources.allResources.insert(resource->id, _resourcesInRepository.value(resource->id));

            for (const auto& resource : regionResPrevious.localResources)
                if (!regionResources.allResources.contains(resource->id))
                    regionResources.allResources.insert(resource->id, _resourcesInRepository.value(resource->id));
        }
        
        _resourcesByRegions.insert(region, regionResources);
    }
}
- (void) collectSubregionsDataAndItems
{
    _srtmDisabled = _iapHelper.srtm.disabled;
    _hasSrtm = NO;

    // Collect all regions (and their parents) that have at least one
    // resource available in repository or locally.
    
    [_allResourceItems removeAllObjects];
    [_allSubregionItems removeAllObjects];
    [_regionMapItems removeAllObjects];
    [_localRegionMapItems removeAllObjects];
    
    for (OAWorldRegion *subregion in self.region.flattenedSubregions)
    {
        if (!self.region.superregion && ([subregion.regionId isEqualToString:_otherRegionId] || [subregion.regionId isEqualToString:_nauticalRegionId]))
            continue;

        if (subregion.superregion == self.region)
        {
            if (subregion.subregions.count > 0)
                [_allSubregionItems addObject:subregion];
            else
                [self collectSubregionItems:subregion];
        }
    }
}

- (void) collectCustomItems
{
    _customRegions = self.region.flattenedSubregions;
    for (OAResourceItem *item in ((OACustomRegion *) self.region).loadIndexItems)
    {
        item.downloadTask = [self getDownloadTaskFor:item.resourceId.toNSString()];
        [_regionMapItems addObject:item];
    }
}

- (void)collectSubregionItemsFromRegularRegion:(OAWorldRegion *)region
{
    const auto citRegionResources = _resourcesByRegions.constFind(region);
    if (citRegionResources == _resourcesByRegions.cend())
        return;
    const auto& regionResources = *citRegionResources;
    
    BOOL nauticalRegion = region == self.region && [region.regionId isEqualToString:_nauticalRegionId];
    
    NSMutableArray<OAResourceItem *> *regionMapArray = [NSMutableArray array];
    NSMutableArray<OAResourceItem *> *allResourcesArray = [NSMutableArray array];
    
    for (const auto& resource_ : regionResources.allResources)
    {
        OAResourceItem *item_ = [self collectSubregionItem:region regionResources:regionResources resource:resource_];
        if (item_)
        {
            if (nauticalRegion)
                [allResourcesArray addObject:item_];
            else if (region == self.region)
                [regionMapArray addObject:item_];
            else
                [allResourcesArray addObject:item_];
        }
    }
    
    for (OAResourceItem *regItem in regionMapArray)
        for (OAResourceItem *resItem in _allResourceItems)
            if (resItem.resourceId == regItem.resourceId)
            {
                [_allResourceItems removeObject:regItem];
                break;
            }
    
    [_regionMapItems addObjectsFromArray:regionMapArray];
    
    NSString *northAmericaRegionId = OsmAnd::WorldRegions::NorthAmericaRegionId.toNSString();
    NSString *russiaRegionId = OsmAnd::WorldRegions::RussiaRegionId.toNSString();
    NSString *unitedKingdomRegionId = [NSString stringWithFormat:@"%@_gb", OsmAnd::WorldRegions::EuropeRegionId.toNSString()];

    if ([self.region hasGroupItems] && (([self.region getLevel] > 1 && _regionMapItems.count > 0) || [self.region.superregion.regionId hasPrefix:northAmericaRegionId] || [self.region.regionId hasPrefix:russiaRegionId] || [self.region.regionId hasPrefix:unitedKingdomRegionId]))
    {
        NSMutableArray<NSNumber *> *regionMapItemsTypes = [NSMutableArray new];
        for (OAResourceItem *resource in _regionMapItems)
        {
            [regionMapItemsTypes addObject:[OAResourceType toValue:resource.resourceType]];
        }
        NSMutableArray<NSNumber *> *regionMapItemsTypesInGroup = [[self.region.groupItem getTypes] mutableCopy];
        [regionMapItemsTypesInGroup removeObjectsInArray:regionMapItemsTypes];

        for (NSNumber *type in regionMapItemsTypesInGroup)
        {
            OsmAndResourceType resourceType = [OAResourceType toResourceType:type isGroup:YES];
            if (resourceType != [OAResourceType unknownType])
            {
                OAMultipleResourceItem *multipleResourceItem = [[OAMultipleResourceItem alloc] initWithType:resourceType items:[self.region.groupItem getItems:resourceType]];
                multipleResourceItem.worldRegion = self.region;
                [_regionMapItems addObject:multipleResourceItem];
            }
        }
    }

    if (nauticalRegion)
    {
        [_allResourceItems addObjectsFromArray:allResourcesArray];
        OAResourceItem *worldSeamarksItem = [self collectWorldSeamarksItem];
        if (worldSeamarksItem)
            [_allResourceItems addObject:worldSeamarksItem];
    }
    else if (allResourcesArray.count > 1)
    {
        [_allSubregionItems addObject:region];
    }
    else
    {
        [_allResourceItems addObjectsFromArray:allResourcesArray];
    }
}

- (void) collectSubregionItems:(OAWorldRegion *)region
{
    if ([region isKindOfClass:OACustomRegion.class])
        [self collectCustomItems];
    else
        [self collectSubregionItemsFromRegularRegion:region];
}

- (OAResourceItem *) collectSubregionItem:(OAWorldRegion *)region
                          regionResources:(const RegionResources &)regionResources
                                 resource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>)resource
{
    OAResourceItem *item_ = nil;

    if (const auto localResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource))
    {
        if (regionResources.outdatedResources.contains(localResource->id))
        {
            OAOutdatedResourceItem *item = [[OAOutdatedResourceItem alloc] init];
            item_ = item;
            item.resourceId = localResource->id;
            item.resourceType = localResource->type;
            item.title = [OAResourcesUIHelper titleOfResource:resource
                                                     inRegion:region
                                               withRegionName:YES
                                             withResourceType:NO];
            item.resource = localResource;
            item.downloadTask = [self getDownloadTaskFor:localResource->id.toNSString()];
            item.worldRegion = region;

            const auto repositoryResource = _app.resourcesManager->getResourceInRepository(item.resourceId);
            item.size = repositoryResource->size;
            item.sizePkg = repositoryResource->packageSize;
            item.date = [NSDate dateWithTimeIntervalSince1970:(repositoryResource->timestamp / 1000)];

            if (item.title == nil)
                return nil;
        }
        else
        {
            OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
            item_ = item;
            item.resourceId = localResource->id;
            item.resourceType = localResource->type;
            item.title = [OAResourcesUIHelper titleOfResource:resource
                                                     inRegion:region
                                               withRegionName:YES
                                             withResourceType:NO];
            item.resource = localResource;
            item.downloadTask = [self getDownloadTaskFor:localResource->id.toNSString()];
            item.size = localResource->size;
            item.worldRegion = region;

            NSString *localResourcePath = _app.resourcesManager->getLocalResource(item.resourceId)->localPath.toNSString();
            item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResourcePath error:NULL] fileModificationDate];

            if (item.title == nil)
                return nil;
        }
    }
    else if (const auto repositoryResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource))
    {
        OARepositoryResourceItem *item = [[OARepositoryResourceItem alloc] init];
        item_ = item;
        item.resourceId = repositoryResource->id;
        item.resourceType = repositoryResource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:region
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = repositoryResource;
        item.downloadTask = [self getDownloadTaskFor:repositoryResource->id.toNSString()];
        item.size = repositoryResource->size;
        item.sizePkg = repositoryResource->packageSize;
        item.date = [NSDate dateWithTimeIntervalSince1970:(repositoryResource->timestamp / 1000)];
        item.worldRegion = region;

        if (item.title == nil)
            return nil;

        if (region != self.region && _srtmDisabled)
        {
            if (_hasSrtm && repositoryResource->type == OsmAndResourceType::SrtmMapRegion)
                return nil;

            if (repositoryResource->type == OsmAndResourceType::SrtmMapRegion)
            {
                item.title = OALocalizedString(@"srtm_disabled");
                item.size = 0;
                item.sizePkg = 0;
            }

            if (!_hasSrtm && repositoryResource->type == OsmAndResourceType::SrtmMapRegion)
                _hasSrtm = YES;
        }
    }
    return item_;
}

- (OAResourceItem *) collectWorldSeamarksItem
{
    const auto citRegionResources = _resourcesByRegions.constFind(_app.worldRegion);
    if (citRegionResources == _resourcesByRegions.cend())
        return nil;
    const auto& regionResources = *citRegionResources;
        
    for (const auto& resource_ : regionResources.allResources)
    {
        if (resource_->id == QStringLiteral(kWorldSeamarksKey) || resource_->id == QStringLiteral(kWorldSeamarksOldKey))
        {
            OAResourceItem *item_ = [self collectSubregionItem:_app.worldRegion regionResources:regionResources resource:resource_];
            if (item_)
                item_.worldRegion = [_app.worldRegion getSubregion:_nauticalRegionId];
            
            return item_;
        }
    }
    return nil;
}

- (void) collectResourcesDataAndItems
{
    [self collectSubregionItems:self.region];
    
    [_allResourceItems addObjectsFromArray:_allSubregionItems];
    [_allResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_regionMapItems sortUsingComparator:^NSComparisonResult(OAResourceItem *res1, OAResourceItem *res2) {
        NSInteger orderValue1 = [OAResourceType getOrderIndex:[OAResourceType toValue:res1.resourceType]];
        NSInteger orderValue2 = [OAResourceType getOrderIndex:[OAResourceType toValue:res2.resourceType]];
        if (orderValue1 < orderValue2)
            return NSOrderedAscending;
        else if (orderValue1 > orderValue2)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];

    // Map Creator sqlitedb files
    [_localSqliteItems removeAllObjects];
    [_localOnlineTileSources removeAllObjects];
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        OASqliteDbResourceItem *item = [[OASqliteDbResourceItem alloc] init];
        item.title = [OASQLiteTileSource getTitleOf:filePath];
        item.fileName = filePath.lastPathComponent;
        item.path = filePath;
        item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
        if ([OASQLiteTileSource isOnlineTileSource:filePath])
            [_localOnlineTileSources addObject:item];
        else
            [_localSqliteItems addObject:item];
    }
    [_localSqliteItems sortUsingComparator:^NSComparisonResult(OASqliteDbResourceItem *obj1, OASqliteDbResourceItem *obj2) {
        return [obj1.title caseInsensitiveCompare:obj2.title];
    }];
    
    // Installed online tile sources
    const auto& resource = _app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            OAOnlineTilesResourceItem *item = [[OAOnlineTilesResourceItem alloc] init];
            
            item.title = onlineTileSource->name.toNSString();
            item.path = [_app.cachePath stringByAppendingPathComponent:item.title];
            [_localOnlineTileSources addObject:item];
        }
    }
    
    // Outdated Resources
    [_localResourceItems removeAllObjects];
    [_outdatedResourceItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:resource->id];
        if (!match)
            continue;

        OAOutdatedResourceItem *item = [[OAOutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:match
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;

        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.size = resourceInRepository->size;
        item.sizePkg = resourceInRepository->packageSize;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];

        if (item.title != nil)
        {
            if (match == self.region)
                [_localRegionMapItems addObject:item];
            else
                [_localResourceItems addObject:item];
        
            [_outdatedResourceItems addObject:item];
        }
    }
    [_outdatedResourceItems sortUsingComparator:self.resourceItemsComparator];
    
    // Local Resources
    _liveUpdatesInstalledSize = _app.resourcesManager->changesManager->getUpdatesSize();
    
    _totalInstalledSize = 0;
    for (const auto& resource : _localResources)
    {
        //NSLog(@"=== %@", resource->id.toNSString());
        
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:resource->id];
        
        if (!match && ![OAResourceType isMapResourceType:resource->type])
            continue;
        
        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        if (match)
        {
            item.title = [OAResourcesUIHelper titleOfResource:resource
                                                     inRegion:match
                                               withRegionName:YES
                                             withResourceType:NO];
        }
        else
        {
            NSString *title = [OAFileNameTranslationHelper getMapName:resource->id.toNSString()];
            item.title = title;
        }
            
        item.resource = resource;
        if (match)
            item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.size = resource->size;
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:resource->localPath.toNSString() error:NULL] fileModificationDate];;
        item.worldRegion = match;
        
        _totalInstalledSize += resource->size;
        
        if (item.title != nil)
        {
            if (match == self.region)
            {
                if (![_localRegionMapItems containsObject:item])
                    [_localRegionMapItems addObject:item];
                
            }
            else
            {
                if (![_localResourceItems containsObject:item])
                    [_localResourceItems addObject:item];
            }
        }
    }
    [_localResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_localRegionMapItems sortUsingComparator:self.resourceItemsComparator];
    
    for (OAResourceItem *item in _regionMapItems)
    {
        if (item.resourceId == QStringLiteral(kWorldSeamarksKey) || item.resourceId == QStringLiteral(kWorldSeamarksOldKey))
        {
            [_regionMapItems removeObject:item];
            break;
        }
    }

    NSMutableSet *regionsSet = [NSMutableSet set];
    for (OAOutdatedResourceItem *item in _outdatedResourceItems)
    {
        if (item.worldRegion.regionId)
            [regionsSet addObject:item.worldRegion];
    }
    _regionsWithOutdatedResources = [[regionsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void) prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;
        _downloadDescriptionSection = -1;
        _extraMapsSection = -1;
        _osmAndLiveSection = -1;
        _otherMapsSection = -1;
        _nauticalMapsSection = -1;
        _regionMapSection = -1;
        _bannerSection = -1;
        _subscribeEmailSection = -1;
        _outdatedResourcesSection = -1;
        _localResourcesSection = -1;
        _resourcesSection = -1;
        _localSqliteSection = -1;
        _localOnlineTileSourcesSection = -1;
        _freeMemorySection = -1;
        
        if (_displayBanner)
            _bannerSection = _lastUnusedSectionIndex++;
        
        if (![self.region isKindOfClass:OACustomRegion.class])
            _freeMemorySection = _lastUnusedSectionIndex++;
        
        if (_displaySubscribeEmailView)
            _subscribeEmailSection = _lastUnusedSectionIndex++;

        // Updates always go first
        if (_currentScope == kAllResourcesScope && [_outdatedResourceItems count] > 0 && self.region == _app.worldRegion)
            _outdatedResourcesSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion)
            _osmAndLiveSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && _downloadDescriptionInfo)
            _downloadDescriptionSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && _customRegions.count > 0 && (self.region == _app.worldRegion || [self.region isKindOfClass:OACustomRegion.class]))
            _extraMapsSection = _lastUnusedSectionIndex++;

        if (_currentScope == kAllResourcesScope && ([_localResourceItems count] > 0 || [_localRegionMapItems count] > 0 || _localSqliteItems.count > 0 || _localOnlineTileSources.count > 0) && self.region == _app.worldRegion)
            _localResourcesSection = _lastUnusedSectionIndex++;

        if (self.region && self.region != _app.worldRegion && _currentScope == kAllResourcesScope)
        {
            if ([[self getRegionMapItems] count] > 0)
                _regionMapSection = _lastUnusedSectionIndex++;
        }

        if ([[self getResourceItems] count] > 0)
            _resourcesSection = _lastUnusedSectionIndex++;

        if (_regionMapSection == -1 && [[self getRegionMapItems] count] > 0)
            _regionMapSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kLocalResourcesScope && _localSqliteItems.count > 0)
            _localSqliteSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kLocalResourcesScope && _localOnlineTileSources.count > 0)
            _localOnlineTileSourcesSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion && [_app.worldRegion containsSubregion:_otherRegionId])
        {
            OAWorldRegion *otherMaps = [_app.worldRegion getSubregion:_otherRegionId];
            if (otherMaps.subregions.count > 0)
                _otherMapsSection = _lastUnusedSectionIndex++;
        }

        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion && [_app.worldRegion containsSubregion:_nauticalRegionId] && [[_app.worldRegion getSubregion:_nauticalRegionId] isInPurchasedArea])
            _nauticalMapsSection = _lastUnusedSectionIndex++;

        // Configure search scope
        _searchController.searchBar.scopeButtonTitles = nil;
        _searchController.searchBar.placeholder = OALocalizedString(@"res_search_world");
    }
}

- (void) refreshContent:(BOOL)update
{
    @synchronized(_dataLock)
    {
        if (_searchController.isActive)
        {
            if (update)
                [self updateSearchResults];
            [self.tableView reloadData];
        }
        [self.tableView reloadData];
    }
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        if (_searchController.isActive)
        {
            for (int i = 0; i < _searchResults.count; i++)
            {
                if ([_searchResults[i] isKindOfClass:[OAWorldRegion class]])
                    continue;
                OAResourceItem *item = _searchResults[i];
                if ([[item.downloadTask key] isEqualToString:downloadTaskKey])
                {
                    [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                    return;
                }
            }
            return;
        }

        NSMutableArray *resourceItems = [self getResourceItems];
        for (int i = 0; i < resourceItems.count; i++)
        {
            if ([resourceItems[i] isKindOfClass:[OAWorldRegion class]])
                continue;
            OAResourceItem *item = resourceItems[i];
            if ([[item.downloadTask key] isEqualToString:downloadTaskKey])
            {
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_resourcesSection]];
                break;
            }
        }
        
        NSMutableArray *regionMapItems = [self getRegionMapItems];
        for (int i = 0; i < regionMapItems.count; i++)
        {
            OAResourceItem *item = regionMapItems[i];
            if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
            {
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_regionMapSection]];
            }
            else if ([item isKindOfClass:OAMultipleResourceItem.class])
            {
                BOOL hasTask = NO;
                OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *) item;
                for (OAResourceItem *resourceItem in multipleItem.items)
                {
                    if ([resourceItem.downloadTask.key isEqualToString:downloadTaskKey])
                    {
                        hasTask = YES;
                        break;
                    }
                }
                if (hasTask)
                    [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_regionMapSection]];
            }
        }

    }
}

- (void) updateTableLayout
{
    CGRect frame = self.tableView.frame;
    CGFloat h = self.view.bounds.size.height - frame.origin.y;
    if (self.downloadView.superview)
        h -= self.downloadView.bounds.size.height;
    
    [UIView animateWithDuration:.2 animations:^{
        self.tableView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    }];
}

- (NSMutableArray *) getResourceItems
{
    switch (_currentScope)
    {
        case kAllResourcesScope:
            return _allResourceItems;
        case kLocalResourcesScope:
            return _localResourceItems;
        default:
            return nil;
    }
}

- (NSMutableArray *) getRegionMapItems
{
    switch (_currentScope)
    {
        case kAllResourcesScope:
            return _regionMapItems;
        case kLocalResourcesScope:
            return _localRegionMapItems;
        default:
            return nil;
    }
}

- (void) updateSearchResults
{
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];
}

- (void) performSearchForSearchString:(NSString *)searchString
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
        NSArray *searchableContent = _searchableWorldwideRegionItems;

        // Search through subregions:

        NSComparator regionComparator = ^NSComparisonResult(id obj1, id obj2) {
            OAWorldRegion *item1 = obj1;
            OAWorldRegion *item2 = obj2;

            return [item1.name localizedCaseInsensitiveCompare:item2.name];
        };

        // Regions that start with given name have higher priority
        NSPredicate *startsWith = [NSPredicate predicateWithFormat:@"(ANY resourceTypes == 0) AND name BEGINSWITH[cd] %@", searchString];
        NSMutableArray *regions_startsWith = [[searchableContent filteredArrayUsingPredicate:startsWith] mutableCopy];
        if ([regions_startsWith count] == 0)
        {
            NSPredicate *anyStartsWith = [NSPredicate predicateWithFormat:@"ANY allNames BEGINSWITH[cd] %@", searchString];
            [regions_startsWith addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyStartsWith]];
        }
        [regions_startsWith sortUsingComparator:regionComparator];

        // Regions that only contain given string have less priority
        NSPredicate *onlyContains = [NSPredicate predicateWithFormat:
                                     @"(ANY resourceTypes == 0) AND (name CONTAINS[cd] %@) AND NOT (name BEGINSWITH[cd] %@)",
                                     searchString,
                                     searchString];
        NSMutableArray *regions_onlyContains = [[searchableContent filteredArrayUsingPredicate:onlyContains] mutableCopy];
        if ([regions_onlyContains count] == 0)
        {
            NSPredicate *anyOnlyContains = [NSPredicate predicateWithFormat:
                                            @"(ANY resourceTypes == 0) AND (ANY allNames CONTAINS[cd] %@) AND NOT (ANY allNames BEGINSWITH[cd] %@)",
                                            searchString,
                                            searchString];
            [regions_onlyContains addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyOnlyContains]];
        }
        [regions_onlyContains sortUsingComparator:regionComparator];

        // Assemble all regions all togather
        NSArray *regions = [regions_startsWith arrayByAddingObjectsFromArray:regions_onlyContains];
        NSMutableArray *results = [NSMutableArray array];
        for (OAWorldRegion *region in regions)
        {
            if (region.subregions.count > 0)
                [results addObject:region];

            // Get all resources that are direct children of current region
            const auto citRegionResources = _resourcesByRegions.constFind(region);
            if (citRegionResources == _resourcesByRegions.cend())
                continue;
            const auto& regionResources = *citRegionResources;

            // Create items for each resource found
            NSMutableArray *resourceItems = [NSMutableArray array];
            for (const auto& resource_ : regionResources.allResources)
            {
                if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource_))
                {
                    if (regionResources.outdatedResources.contains(resource->id))
                    {
                        OAOutdatedResourceItem *item = [[OAOutdatedResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [OAResourcesUIHelper titleOfResource:resource_
                                                                 inRegion:region
                                                           withRegionName:YES
                                                         withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                        item.worldRegion = region;

                        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
                        item.size = resourceInRepository->size;
                        item.sizePkg = resourceInRepository->packageSize;

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                    else
                    {
                        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [OAResourcesUIHelper titleOfResource:resource_
                                                                 inRegion:region
                                                           withRegionName:YES
                                                         withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                        item.worldRegion = region;

                        item.size = resource->size;

                        if (item.title == nil)
                            continue;

                        [resourceItems addObject:item];
                    }
                }
                else if (const auto resource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ResourceInRepository>(resource_))
                {
                    OARepositoryResourceItem *item = [[OARepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.title = [OAResourcesUIHelper titleOfResource:resource_
                                                             inRegion:region
                                                       withRegionName:YES
                                                     withResourceType:NO];
                    item.resource = resource;
                    item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
                    item.worldRegion = region;
                    item.size = resource->size;
                    item.sizePkg = resource->packageSize;

                    if (item.title == nil)
                        continue;

                    [resourceItems addObject:item];
                }
            }

            if (resourceItems.count > 1)
            {
                if (![results containsObject:region])
                    [results addObject:region];
            }
            else
            {
                [results addObjectsFromArray:resourceItems];
            }
        }
        
        _searchResults = results;
    }
}

- (void) showNoInternetAlertForCatalogUpdate
{
    [[OARootViewController instance] showNoInternetAlertFor:OALocalizedString(@"res_catalog_upd")];
}

- (void) updateRepository
{
    _doDataUpdateReload = YES;
    _updateButton.enabled = NO;
    [_refreshRepositoryProgressHUD showAnimated:YES
                            whileExecutingBlock:^{
                                [OAOcbfHelper downloadOcbfIfUpdated];
                                [_app loadWorldRegions];
                                self.region = _app.worldRegion;                                
                                [_app startRepositoryUpdateAsync:NO];
                            }
                                completionBlock:^{
                                    _updateButton.enabled = YES;
                                    if (self.openFromSplash)
                                        [self onSearchBtnClicked:nil];
                                }];
}

- (UITableView *) getTableView
{
    return self.tableView;
}

- (void) showDetailsOf:(OALocalResourceItem *)item
{
    [self performSegueWithIdentifier:kOpenDetailsSegue sender:item];
}

- (IBAction) onDoneClicked:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)backButtonClicked:(id)sender
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
    [_tableView setContentOffset:CGPointZero animated:NO];
    [_searchController.searchBar becomeFirstResponder];
}

- (void)onRefreshRepositoryButtonClicked
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        [self updateRepository];
    else
        [self showNoInternetAlertForCatalogUpdate];
}

- (void) onWebPagePressed:(UIButton *)sender
{
    [self openUrlforIndex:sender.tag];
}

- (void) openUrlforIndex:(NSInteger)index
{
    NSArray<OADownloadActionButton *> *buttons = _downloadDescriptionInfo.getActionButtons;
    if (index < buttons.count)
    {
        OADownloadActionButton *btn = buttons[index];
        NSURL *url = [NSURL URLWithString:btn.url];
        if ([[UIApplication sharedApplication] canOpenURL:url])
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void) onItemClicked:(id)senderItem
{
    if ([senderItem isKindOfClass:OAMultipleResourceItem.class])
    {
        OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *) senderItem;
        if ((multipleItem.resourceType == OsmAndResourceType::SrtmMapRegion || multipleItem.resourceType == OsmAndResourceType::HillshadeRegion || multipleItem.resourceType == OsmAndResourceType::SlopeRegion) && ![_iapHelper.srtm isActive])
        {
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
        }
        else if (multipleItem.resourceType == OsmAndResourceType::WikiMapRegion && ![_iapHelper.wiki isActive])
        {
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
        }
        else
        {
            BOOL downloading = NO;
            for (OAResourceItem *item in multipleItem.items)
            {
                if (item.downloadTask != nil)
                {
                    downloading = YES;
                    break;
                }
            }
            if (downloading)
            {
                [OAResourcesUIHelper offerCancelDownloadOf:multipleItem];
            }
            else
            {
                OADownloadMultipleResourceViewController *controller = [[OADownloadMultipleResourceViewController alloc] initWithResource:multipleItem];
                controller.delegate = self;
                [self presentViewController:controller animated:YES completion:nil];
            }
        }
    }
    else
    {
        [super onItemClicked:senderItem];
    }
}
#pragma mark - UITableViewDataSource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self isFiltering])
        return nil;

    if (section == _bannerSection)
        return _bannerView;

    if (section == _freeMemorySection)
        return _freeMemoryView;

    if (section == _subscribeEmailSection)
        return _subscribeEmailView;

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isFiltering] || (_downloadDescriptionInfo && section == _downloadDescriptionSection))
        return 0.0;

    if (section == _bannerSection)
        return _bannerView.bounds.size.height;

    if (section == _freeMemorySection)
        return _freeMemoryView.bounds.size.height;

    if (section == _subscribeEmailSection)
        return [_subscribeEmailView updateFrame:self.tableView.frame.size.width margin:[OAUtilities getLeftMargin]].size.height;

    if (section == 0)
        return 56.0;
    
    return 40.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self isFiltering])
        return 1;

    if (_currentScope == kLocalResourcesScope)
        return ([_localResourceItems count] > 0 ? 1 : 0) + ([_localRegionMapItems count] > 0 ? 1 : 0) + (_localSqliteItems.count > 0 ? 1 : 0) + (_displaySubscribeEmailView ? 1 : 0) + (_localOnlineTileSources.count > 0 ? 1 : 0) + 1;

    NSInteger sectionsCount = 0;

    if (_bannerSection >= 0)
        sectionsCount++;
    if (_subscribeEmailSection >= 0)
        sectionsCount++;
    if (_freeMemorySection >= 0)
        sectionsCount++;
    if (_osmAndLiveSection >= 0)
        sectionsCount++;
    if (_extraMapsSection >= 0)
        sectionsCount++;
    if (_downloadDescriptionSection >= 0)
        sectionsCount++;
    if (_localResourcesSection >= 0)
        sectionsCount++;
    if (_outdatedResourcesSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;
    if (_regionMapSection >= 0)
        sectionsCount++;
    if (_otherMapsSection >= 0)
        sectionsCount++;
    if (_nauticalMapsSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isFiltering])
        return [_searchResults count];

    if (section == _bannerSection)
        return 0;
    if (section == _freeMemorySection)
        return 0;
    if (section == _outdatedResourcesSection)
        return 1;
    if (section == _osmAndLiveSection)
        return 1;
    if (section == _extraMapsSection)
        return _customRegions.count;
    if (section == _downloadDescriptionSection)
        return _downloadDescriptionInfo.getActionButtons.count + 1;
    if (section == _resourcesSection)
        return [[self getResourceItems] count];
    if (section == _localResourcesSection)
        return 1;
    if (section == _regionMapSection)
        return [[self getRegionMapItems] count];
    if (section == _localSqliteSection)
        return _localSqliteItems.count;
    if (section == _localOnlineTileSourcesSection)
        return [_localOnlineTileSources count];
    if (section == _otherMapsSection)
        return 1;
    if (section == _nauticalMapsSection)
        return 1;

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self isFiltering])
        return nil;

    if (self.region.superregion == nil)
    {
        if (_currentScope == kLocalResourcesScope)
        {
            if (section == _regionMapSection)
                return OALocalizedString(@"res_world_map");
            else if (section == _localSqliteSection)
                return OALocalizedString(@"offline_raster_maps");
            else if (section == _localOnlineTileSourcesSection)
                return OALocalizedString(@"online_raster_maps");
            else
                return OALocalizedString(@"res_mapsres");
        }
        
        if (section == _outdatedResourcesSection)
            return OALocalizedString(@"res_updates");
        if (section == _osmAndLiveSection)
            return OALocalizedString(@"osmand_live_title");
        if (section == _extraMapsSection)
            return OALocalizedString(@"extra_maps");
        if (section == _resourcesSection)
            return OALocalizedString(@"res_worldwide");
        if (section == _localResourcesSection)
            return OALocalizedString(@"download_tab_local");
        if (section == _regionMapSection)
            return OALocalizedString(@"res_world_map");
        if (section == _otherMapsSection)
            return OALocalizedString(@"region_others");
        if (section == _nauticalMapsSection)
            return OALocalizedString(@"region_nautical");

        return nil;
    }

    if (section == _outdatedResourcesSection)
        return OALocalizedString(@"res_updates");
    if (section == _osmAndLiveSection)
        return OALocalizedString(@"osmand_live_title");
    if (section == _extraMapsSection)
        return OALocalizedString(@"extra_maps");
    if (section == _resourcesSection)
        return OALocalizedString(@"res_mapsres");
    if (section == _localResourcesSection)
        return OALocalizedString(@"download_tab_local");
    if (section == _regionMapSection)
        return OALocalizedString(@"res_region_map");
    if (section == _otherMapsSection)
        return OALocalizedString(@"region_others");
    if (section == _nauticalMapsSection)
        return OALocalizedString(@"region_nautical");

    return nil;
}

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    static NSString *const downloadingResourceCell = @"downloadingResourceCell";
    
    NSString *cellTypeId = nil;
    id item_ = nil;
    if ([self isFiltering])
    {
        item_ = _searchResults[indexPath.row];
        
        if (![item_ isKindOfClass:[OAWorldRegion class]])
        {
            OAResourceItem *item = (OAResourceItem *) item_;
            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
        }
    }
    else
    {
        if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
        {
            item_ = [self getResourceItems][indexPath.row];
            
            if (![item_ isKindOfClass:[OAWorldRegion class]])
            {
                OAResourceItem *item = (OAResourceItem *) item_;

                if (item.downloadTask != nil)
                    cellTypeId = downloadingResourceCell;
            }
        }
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            item_ = [self getRegionMapItems][indexPath.row];
            if ([item_ isKindOfClass:OAMultipleResourceItem.class])
            {
                OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *) item_;
                for (OAResourceItem *resourceItem in multipleItem.items)
                {
                    if (resourceItem.downloadTask != nil)
                    {
                        item_ = resourceItem;
                        break;
                    }
                }
            }
            OAResourceItem *item = (OAResourceItem *) item_;

            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
        }
    }
    
    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        OAResourceItem *item = (OAResourceItem *) item_;
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;

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
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const descriptionButtonIconCell = @"OAMultiIconTextDescCell";
    static NSString *const subregionCell = @"subregionCell";
    static NSString *const outdatedResourceCell = @"outdatedResourceCell";
    static NSString *const osmAndLiveCell = @"osmAndLiveCell";
    static NSString *const localResourceCell = @"localResourceCell";
    static NSString *const repositoryResourceCell = @"repositoryResourceCell";
    static NSString *const downloadingResourceCell = @"downloadingResourceCell";
    static NSString *const outdatedResourcesSubmenuCell = @"outdatedResourcesSubmenuCell";
    static NSString *const installedResourcesSubmenuCell = @"installedResourcesSubmenuCell";

    NSString *cellTypeId = nil;
    NSString *title = nil;
    NSString *subtitle = nil;
    BOOL disabled = NO;

    OAResourceItem *downloadingMultipleItem = nil;

    id item_ = nil;
    if ([self isFiltering])
    {
        item_ = _searchResults[indexPath.row];

        if ([item_ isKindOfClass:[OAWorldRegion class]])
        {
            OAWorldRegion *item = (OAWorldRegion *) item_;

            cellTypeId = subregionCell;
            title = item.name;
            if (item.superregion != nil)
                subtitle = item.superregion.name;
        }
        else if ([item_ isKindOfClass:[OAResourceItem class]])
        {
            OAResourceItem *item = (OAResourceItem *) item_;

            if ([item isKindOfClass:[OAMultipleResourceItem class]])
            {
                BOOL hasTask = NO;
                for (OAResourceItem *resourceItem in ((OAMultipleResourceItem *) item).items)
                {
                    if (resourceItem.downloadTask != nil)
                    {
                        downloadingMultipleItem = resourceItem;
                        hasTask = YES;
                        break;
                    }
                }
                cellTypeId = hasTask ? downloadingResourceCell : repositoryResourceCell;
            }
            else if (item.downloadTask != nil)
            {
                cellTypeId = downloadingResourceCell;
            }
            else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
            {
                cellTypeId = outdatedResourceCell;
            }
            else if ([item isKindOfClass:[OALocalResourceItem class]])
            {
                cellTypeId = localResourceCell;
            }
            else if ([item isKindOfClass:[OARepositoryResourceItem class]])
            {
                cellTypeId = repositoryResourceCell;
            }

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
            title = OALocalizedString(@"res_updates_avail");

            NSArray *regionsNames = [_regionsWithOutdatedResources valueForKey:NSStringFromSelector(@selector(name))];
            subtitle = [_arrFmt stringFromArray:regionsNames];
        }
        else if (indexPath.section == _localResourcesSection && _localResourcesSection >= 0)
        {
            cellTypeId = installedResourcesSubmenuCell;
            title = OALocalizedString(@"download_tab_local");
            
            subtitle = [NSString stringWithFormat:@"%d %@ - %@", (int)(_localResourceItems.count + _localRegionMapItems.count + _localSqliteItems.count + _localOnlineTileSources.count), OALocalizedString(@"res_maps_inst"), [NSByteCountFormatter stringFromByteCount:_totalInstalledSize countStyle:NSByteCountFormatterCountStyleFile]];
        }
        else if (indexPath.section == _osmAndLiveSection)
        {
            cellTypeId = osmAndLiveCell;
            title = OALocalizedString(@"osmand_live_title");
        }
        else if (indexPath.section == _extraMapsSection)
        {
            cellTypeId = subregionCell;
            title = _customRegions[indexPath.row].localizedName;
        }
        else if (indexPath.section == _downloadDescriptionSection)
        {
            if (indexPath.row == 0)
            {
                cellTypeId = [OATextViewSimpleCell getCellIdentifier];
                title = nil;
            }
            else
            {
                cellTypeId = descriptionButtonIconCell;
            }
        }
        else if (indexPath.section == _otherMapsSection)
        {
            cellTypeId = subregionCell;
            title = OALocalizedString(@"region_others");
        }
        else if (indexPath.section == _nauticalMapsSection)
        {
            cellTypeId = subregionCell;
            title = OALocalizedString(@"region_nautical");
        }
        else if (indexPath.section == _resourcesSection && _resourcesSection >= 0)
        {
            item_ = [self getResourceItems][indexPath.row];

            if ([item_ isKindOfClass:[OAWorldRegion class]])
            {
                OAWorldRegion *item = (OAWorldRegion *) item_;
                
                cellTypeId = subregionCell;
                title = item.name;
                if (item.superregion != nil && item.superregion != _app.worldRegion)
                {
                    if (item.resourceTypes.count > 0)
                    {
                        NSMutableOrderedSet<NSNumber *> *typesSet = [NSMutableOrderedSet orderedSetWithArray:item.resourceTypes];
                        NSArray<NSNumber *> *sortedTypesWithoutDuplicate = [[typesSet array] sortedArrayUsingComparator:^NSComparisonResult(NSNumber *type1, NSNumber *type2) {
                            NSInteger orderValue1 = [OAResourceType getOrderIndex:type1];
                            NSInteger orderValue2 = [OAResourceType getOrderIndex:type2];
                            if (orderValue1 < orderValue2)
                                return NSOrderedAscending;
                            else if (orderValue1 > orderValue2)
                                return NSOrderedDescending;
                            else
                                return NSOrderedSame;
                        }];

                        NSMutableArray<NSString *> *typesLocalized = [NSMutableArray new];
                        [sortedTypesWithoutDuplicate enumerateObjectsUsingBlock:^(NSNumber *type, NSUInteger idx, BOOL *stop) {
                            [typesLocalized addObject:[OAResourceType resourceTypeLocalized:[OAResourceType toResourceType:type isGroup:NO]]];
                        }];
                        subtitle = [typesLocalized componentsJoinedByString:@", "];
                    }
                    else
                    {
                        subtitle = item.superregion.name;
                    }
                }
            }
            else
            {
                OAResourceItem *item = (OAResourceItem *) item_;
                uint64_t _sizePkg = item.sizePkg;
                
                if (item.downloadTask != nil)
                {
                    cellTypeId = downloadingResourceCell;
                }
                else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
                {
                    cellTypeId = outdatedResourceCell;
                }
                else if ([item isKindOfClass:[OALocalResourceItem class]])
                {
                    cellTypeId = localResourceCell;
                    _sizePkg = item.size;
                }
                else if ([item isKindOfClass:[OARepositoryResourceItem class]])
                {
                    cellTypeId = repositoryResourceCell;
                }
                
                BOOL mapDownloaded = NO;
                for (OAResourceItem *it in [self getRegionMapItems])
                {
                    if (it.resourceType == OsmAndResourceType::MapRegion && ([it isKindOfClass:[OALocalResourceItem class]] || [it isKindOfClass:[OAOutdatedResourceItem class]]))
                    {
                        mapDownloaded = YES;
                        break;
                    }
                }
                
                if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion)
                    && ![_iapHelper.srtm isActive] && ![self.region isInPurchasedArea])
                {
                    disabled = YES;
                    item.disabled = disabled;
                }
                if (item.resourceType == OsmAndResourceType::WikiMapRegion
                    && ![_iapHelper.wiki isActive] && ![self.region isInPurchasedArea])
                {
                    disabled = YES;
                    item.disabled = disabled;
                }

                if (_currentScope == kLocalResourcesScope && item.worldRegion && item.worldRegion.superregion)
                {
                    NSString *countryName = [OAResourcesUIHelper getCountryName:item];
                    if (countryName)
                        title = [NSString stringWithFormat:@"%@ - %@", countryName, item.title];
                    else
                        title = item.title;
                }
                else
                {
                    title = item.title;
                }
                
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
                else
                    subtitle = [NSString stringWithFormat:@"%@", [OAResourceType resourceTypeLocalized:item.resourceType]];
            }
        }
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            item_ = [self getRegionMapItems][indexPath.row];

            OAResourceItem *item = (OAResourceItem *) item_;
            uint64_t _sizePkg = item.sizePkg;

            if ([item isKindOfClass:OAMultipleResourceItem.class])
            {
                _sizePkg = 0;
                BOOL hasTask = NO;
                for (OAResourceItem *resourceItem in ((OAMultipleResourceItem *) item).items)
                {
                    if ([resourceItem isKindOfClass:OARepositoryResourceItem.class])
                        _sizePkg += ((OARepositoryResourceItem *) resourceItem).resource->packageSize;

                    if (resourceItem.downloadTask != nil)
                    {
                        downloadingMultipleItem = resourceItem;
                        hasTask = YES;
                        break;
                    }
                }
                cellTypeId = hasTask ? downloadingResourceCell : repositoryResourceCell;
            }
            else if (item.downloadTask != nil)
            {
                cellTypeId = downloadingResourceCell;
            }
            else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
            {
                cellTypeId = outdatedResourceCell;
            }
            else if ([item isKindOfClass:[OALocalResourceItem class]] || ([item isKindOfClass:OACustomResourceItem.class] && ((OACustomResourceItem *) item).isInstalled))
            {
                cellTypeId = localResourceCell;
                _sizePkg = item.size;
            }
            else if ([item isKindOfClass:[OARepositoryResourceItem class]] || [item isKindOfClass:OACustomResourceItem.class])
            {
                cellTypeId = repositoryResourceCell;
            }

            BOOL mapDownloaded = NO;
            for (OAResourceItem *it in [self getRegionMapItems])
            {
                if (it.resourceType == OsmAndResourceType::MapRegion && ([it isKindOfClass:[OALocalResourceItem class]] || [it isKindOfClass:[OAOutdatedResourceItem class]]))
                {
                    mapDownloaded = YES;
                    break;
                }
            }

            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion)
                && ![_iapHelper.srtm isActive] && ![self.region isInPurchasedArea])
            {
                disabled = YES;
                item.disabled = disabled;
            }
            if (item.resourceType == OsmAndResourceType::WikiMapRegion
                && ![_iapHelper.wiki isActive] && ![self.region isInPurchasedArea])
            {
                disabled = YES;
                item.disabled = disabled;
            }

            subtitle = @"";

            if (_currentScope == kLocalResourcesScope && item.worldRegion && item.worldRegion.superregion)
            {
                NSString *countryName = [OAResourcesUIHelper getCountryName:item];
                if (countryName)
                    title = [NSString stringWithFormat:@"%@ - %@", countryName, item.title];
                else
                    title = item.title;
                
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

            }
            else if ([item isKindOfClass:OACustomResourceItem.class])
            {
                OACustomResourceItem *customItem = (OACustomResourceItem *) item;
                title = customItem.getVisibleName;
                
                subtitle = customItem.getSubName;
            }
            else if (self.region != _app.worldRegion)
            {
                title = [OAResourceType resourceTypeLocalized:item.resourceType];

                if (_sizePkg > 0)
                {
                    subtitle = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
                }
                if ([item isKindOfClass:OAMultipleResourceItem.class] && [self.region hasGroupItems])
                {
                    NSString *allRegions = [NSString stringWithFormat:@"%@: %li", OALocalizedString(@"shared_strings_all_regions"), [self.region.groupItem getItems:item.resourceType].count];
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", allRegions, subtitle];
                }
                else if (item.date)
                {
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", subtitle, [item getDate]];
                }
            }
            else
            {
                title = item.title;
                
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
            }
        }
        else if (indexPath.section == _localSqliteSection)
        {
            OASqliteDbResourceItem *item = _localSqliteItems[indexPath.row];
            cellTypeId = localResourceCell;
            
            title = item.title;
            subtitle = [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile];
        }
        else if (indexPath.section == _localOnlineTileSourcesSection)
        {
            OALocalResourceItem *item = _localOnlineTileSources[indexPath.row];
            cellTypeId = localResourceCell;
            
            title = item.title;
            if ([item isKindOfClass:OASqliteDbResourceItem.class])
                subtitle = [NSString stringWithFormat:@"%@ • %@", OALocalizedString(@"online_map"), [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
            else
                subtitle = OALocalizedString(@"online_map");
        }
    }

    // Obtain reusable cell or create one
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:outdatedResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

            UIImage *iconImage = [UIImage templateImageNamed:@"menu_item_update_icon"];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            [btnAcc setTintColor:UIColorFromRGB(color_primary_purple)];
            btnAcc.frame = CGRectMake(0.0, 0.0, 60.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else if ([cellTypeId isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if ([cellTypeId isEqualToString:descriptionButtonIconCell])
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:descriptionButtonIconCell owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

            NSString *imageNamed = [item_ isKindOfClass:OAMultipleResourceItem.class] ? @"ic_custom_multi_download" : @"ic_custom_download";
            UIImage *iconImage = [UIImage templateImageNamed:imageNamed];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            btnAcc.tintColor = UIColorFromRGB(color_primary_purple);
            btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

            FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];
            progressView.tintColor = UIColorFromRGB(color_primary_purple);

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    if ([cellTypeId isEqualToString:outdatedResourcesSubmenuCell])
    {
        [_updateCouneView setText:[NSString stringWithFormat:@"%d", (int)_outdatedResourceItems.count]];
        cell.accessoryView = _updateCouneView;
    }

    // Fill cell content
    
    if ([cellTypeId isEqualToString:repositoryResourceCell])
    {
        if (!disabled)
        {
            cell.textLabel.textColor = [UIColor blackColor];
            NSString *imageNamed = [item_ isKindOfClass:OAMultipleResourceItem.class] ? @"ic_custom_multi_download" : @"ic_custom_download";
            UIImage *iconImage = [UIImage templateImageNamed:imageNamed];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            btnAcc.tintColor = UIColorFromRGB(color_primary_purple);
            btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
                
            if (self.region && [self.region isInPurchasedArea])
            {
                UILabel *labelGet = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 100.0)];
                labelGet.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
                labelGet.textAlignment = NSTextAlignmentCenter;
                labelGet.textColor = [UIColor colorWithRed:0.992f green:0.561f blue:0.149f alpha:1.00f];
                labelGet.text = [OALocalizedString(@"purchase_get") uppercaseStringWithLocale:[NSLocale currentLocale]];
                
                [labelGet sizeToFit];
                CGSize priceSize = CGSizeMake(MAX(kPriceMinTextWidth, labelGet.bounds.size.width), MAX(kPriceMinTextHeight, labelGet.bounds.size.height));
                CGRect priceFrame = labelGet.frame;
                priceFrame.origin = CGPointMake(kPriceTextInset, 0.0);
                priceFrame.size = priceSize;
                labelGet.frame = priceFrame;
                
                UIView *itemGetView = [[UIView alloc] initWithFrame:CGRectMake(priceFrame.origin.x - kPriceTextInset, priceFrame.origin.y, priceFrame.size.width + kPriceTextInset * 2.0, priceFrame.size.height)];
                itemGetView.layer.cornerRadius = 4;
                itemGetView.layer.masksToBounds = YES;
                itemGetView.layer.borderWidth = 0.8;
                itemGetView.layer.borderColor = [UIColor colorWithRed:0.992f green:0.561f blue:0.149f alpha:1.00f].CGColor;
                
                [itemGetView addSubview:labelGet];
                
                cell.accessoryView = itemGetView;
            }
            else
            {
                cell.accessoryView = nil;
            }
        }
    }

    if ([item_ isKindOfClass:OAMultipleResourceItem.class] && [self.region hasGroupItems])
    {
        OAMultipleResourceItem *item = (OAMultipleResourceItem *) item_;
        UIColor *color = UIColorFromRGB(color_tint_gray);
        for (OAResourceItem *resourceItem in [self.region.groupItem getItems:item.resourceType])
        {
            if (_app.resourcesManager->isResourceInstalled(resourceItem.resourceId))
            {
                color = UIColorFromRGB(resource_installed_icon_color);
                break;
            }
        }
        cell.imageView.image = [OAResourceType getIcon:item.resourceType];
        cell.imageView.tintColor = color;
    }
    else if ([item_ isKindOfClass:OAResourceItem.class])
    {
        OAResourceItem *item = (OAResourceItem *) item_;
        UIColor *color = _app.resourcesManager->isResourceInstalled(item.resourceId) ? UIColorFromRGB(resource_installed_icon_color) : UIColorFromRGB(color_tint_gray);
        cell.imageView.image = [OAResourceType getIcon:item.resourceType];
        cell.imageView.tintColor = color;
    }

    cell.textLabel.text = title;
    if (cell.detailTextLabel != nil)
        cell.detailTextLabel.text = subtitle;

    if ([cellTypeId isEqualToString:subregionCell])
    {
        OAWorldRegion *item = (OAWorldRegion *) item_;

        if (item.superregion.regionId == nil)
        {
            if ([item purchased])
            {
                BOOL viewExists = NO;
                for (UIView *view in cell.contentView.subviews)
                {
                    if (view.tag == -1)
                    {
                        viewExists = YES;
                        break;
                    }
                }

                if (!viewExists)
                {
                    UIView *purchasedView = [[UIView alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 14.0, cell.contentView.bounds.size.height / 2.0 - 5.0, 10.0, 10.0)];
                    purchasedView.layer.cornerRadius = 5.0;
                    purchasedView.layer.masksToBounds = YES;
                    purchasedView.layer.backgroundColor = [UIColor colorWithRed:0.306f green:0.792f blue:0.388f alpha:1.00f].CGColor;
                    purchasedView.tag = -1;
                    purchasedView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
                    
                    [cell.contentView addSubview:purchasedView];
                }
            }
            else
            {
                for (UIView *view in cell.contentView.subviews)
                {
                    if (view.tag == -1)
                    {
                        [view removeFromSuperview];
                        break;
                    }
                }
            }
        }
        else
        {
            for (UIView *view in cell.contentView.subviews)
            {
                if (view.tag == -1)
                {
                    [view removeFromSuperview];
                    break;
                }
            }
        }
    }
    else if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        OAResourceItem *item = [item_ isKindOfClass:OAMultipleResourceItem.class] && downloadingMultipleItem ? downloadingMultipleItem : (OAResourceItem *) item_;
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;

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
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
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
    else if ([cellTypeId isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *textViewCell = (OATextViewSimpleCell *) cell;
        textViewCell.textView.attributedText = [OAUtilities attributedStringFromHtmlString:_downloadDescriptionInfo.getLocalizedDescription fontSize:17];
        textViewCell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
        [textViewCell.textView sizeToFit];
    }
    else if ([cellTypeId isEqualToString:descriptionButtonIconCell])
    {
        OAMultiIconTextDescCell *buttonCell = (OAMultiIconTextDescCell *) cell;
        OADownloadActionButton *button = _downloadDescriptionInfo.getActionButtons[indexPath.row - 1];
        buttonCell.textView.text = button.name;
        buttonCell.descView.text = button.url;
        buttonCell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
        buttonCell.textView.textColor = UIColorFromRGB(color_primary_purple);
        [buttonCell.overflowButton setImage:[UIImage templateImageNamed:@"ic_custom_safari"] forState:UIControlStateNormal];
        buttonCell.overflowButton.tag = indexPath.row - 1;
        buttonCell.overflowButton.tintColor = UIColorFromRGB(color_primary_purple);
        [buttonCell.overflowButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [buttonCell.overflowButton addTarget:self action:@selector(onWebPagePressed:) forControlEvents:UIControlEventTouchUpInside];
    }

    return cell;
}

- (void) accessoryButtonPressed:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (!indexPath)
        return;
    
    [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

#pragma mark - UITableViewDelegate

- (id)getItemByIndexPath:(NSIndexPath *)indexPath
{
    id item;
    if (indexPath.section == _resourcesSection)
        item = [self getResourceItems][indexPath.row];
    else if (indexPath.section == _regionMapSection)
        item = [self getRegionMapItems][indexPath.row];
    else if (indexPath.section == _localSqliteSection)
        item = _localSqliteItems[indexPath.row];
    else if (indexPath.section == _localOnlineTileSourcesSection)
        item = _localOnlineTileSources[indexPath.row];
    else if (indexPath.section == _otherMapsSection)
        item = [_app.worldRegion getSubregion:_otherRegionId];
    else if (indexPath.section == _nauticalMapsSection)
        item = [_app.worldRegion getSubregion:_nauticalRegionId];
    else if (indexPath.section == _extraMapsSection)
        item = _customRegions[indexPath.row];

    return item;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item;
    if ([self isFiltering])
        item = _searchResults[indexPath.row];
    else
        item = [self getItemByIndexPath:indexPath];

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if ([self isFiltering])
    {
        if (_searchResults.count > 0)
            item = _searchResults[indexPath.row];
    }
    else if (indexPath.section == _downloadDescriptionSection)
    {
        if (indexPath.row > 0)
            [self openUrlforIndex:indexPath.row - 1];
    }
    else
    {
        item = [self getItemByIndexPath:indexPath];
    }

    if (item)
    {
        if ([item isKindOfClass:[OAMultipleResourceItem class]])
        {
            [self onItemClicked:item];
        }
        else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
        {
            if (((OAOutdatedResourceItem *) item).downloadTask != nil)
                [self onItemClicked:item];
            else
                [self showDetailsOf:item];
        }
        else if ([item isKindOfClass:OACustomResourceItem.class])
        {
            [self showDetailsOfCustomItem:item];
        }
        else if (![item isKindOfClass:[OALocalResourceItem class]])
        {
            [self onItemClicked:item];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if ([self isFiltering])
        item = _searchResults[indexPath.row];
    else
        item = [self getItemByIndexPath:indexPath];

    if (item == nil)
        return NO;

    if (![item isKindOfClass:[OALocalResourceItem class]])
        return NO;

    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if ([self isFiltering])
        item = _searchResults[indexPath.row];
    else
        item = [self getItemByIndexPath:indexPath];

    if (item == nil)
        return UITableViewCellEditingStyleNone;

    if (![item isKindOfClass:[OALocalResourceItem class]])
        return UITableViewCellEditingStyleNone;

    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if ([self isFiltering])
        item = _searchResults[indexPath.row];
    else
        item = [self getItemByIndexPath:indexPath];

    if (item == nil)
        return;

    if ([item isKindOfClass:[OALocalResourceItem class]])
    {
        [self offerDeleteResourceOf:item];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UISearchDisplayDelegate

//- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
//{
//    _lastSearchScope = searchOption;
//    [self performSearchForSearchString:_lastSearchString
//                        andSearchScope:_lastSearchScope];
//
//    return YES;
//}
//
//- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
//{
//    _lastSearchString = searchString;
//    [self performSearchForSearchString:_lastSearchString
//                        andSearchScope:_lastSearchScope];
//
//    return YES;
//}
//
//- (BOOL)prefersStatusBarHidden
//{
//    return _isSearching;
//}
//
//- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
//{
//    _isSearching = YES;
//
//    [self setNeedsStatusBarAppearanceUpdate];
//
//    [UIView animateWithDuration:0.3
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^{
//
//                         CGRect newBounds = self.tableView.bounds;
//                         newBounds.origin.y = 0.0;
//                         self.tableView.bounds = newBounds;
//
//                         self.titlePanelView.frame = CGRectMake(0.0, -self.titlePanelView.frame.size.height, self.titlePanelView.frame.size.width, self.titlePanelView.frame.size.height);
//                         self.toolbarView.frame = CGRectMake(0.0, self.view.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
//                         self.tableView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
//
//                     } completion:^(BOOL finished) {
//                         self.titlePanelView.userInteractionEnabled = NO;
//                     }];
//}
//
//- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
//{
//    _isSearching = NO;
//
//    [self setNeedsStatusBarAppearanceUpdate];
//
//    CGFloat h = self.view.bounds.size.height - 50.0 - 61.0;
//    if (self.downloadView && self.downloadView.superview)
//        h -= self.downloadView.bounds.size.height;
//
//    [UIView animateWithDuration:0.1
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^{
//
//                         self.titlePanelView.frame = CGRectMake(0.0, 0.0, self.titlePanelView.frame.size.width, self.titlePanelView.frame.size.height);
//                         self.toolbarView.frame = CGRectMake(0.0, self.view.frame.size.height - self.toolbarView.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
//                         self.tableView.frame = CGRectMake(0.0, 64.0, self.view.bounds.size.width, h);
//                         [self applySafeAreaMargins];
//
//                     } completion:^(BOOL finished) {
//                         self.titlePanelView.userInteractionEnabled = YES;
//                         if (_displayBanner)
//                             [self.tableView reloadData];
//                     }];
//
//    if (self.openFromSplash && _app.resourcesManager->isRepositoryAvailable())
//    {
//        int showMapIterator = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kShowMapIterator];
//        if (showMapIterator == 0)
//        {
//            [[NSUserDefaults standardUserDefaults] setInteger:++showMapIterator forKey:kShowMapIterator];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//
//            NSString *key = [@"resource:" stringByAppendingString:_app.resourcesManager->getResourceInRepository(kWorldBasemapKey)->id.toNSString()];
//            BOOL _isWorldMapDownloading = [_app.downloadsManager.keysOfDownloadTasks containsObject:key];
//
//            const auto worldMap = _app.resourcesManager->getLocalResource(kWorldBasemapKey);
//            if (!worldMap && !_isWorldMapDownloading)
//                [OAPluginPopupViewController askForWorldMap];
//        }
//    }
//}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    _lastSearchString = _searchController.searchBar.text;
    _lastSearchScope = _searchController.searchBar.selectedScopeButtonIndex;
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];
    [_tableView reloadData];
}

- (BOOL) isFiltering
{
    return _searchController.isActive && ![self searchBarIsEmpty];
}

- (BOOL) searchBarIsEmpty
{
    return _searchController.searchBar.text.length == 0;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([self.region isKindOfClass:OACustomRegion.class] && [identifier isEqualToString:kOpenDetailsSegue])
    {
        return NO;
    }
    if ([sender isKindOfClass:[UITableViewCell class]])
    {
        UITableViewCell *cell = (UITableViewCell *) sender;
        UITableView *tableView = [cell getTableView];
        NSIndexPath *cellPath = [tableView indexPathForCell:cell];

        if ([identifier isEqualToString:kOpenSubregionSegue])
        {
            OAWorldRegion *subregion = nil;
            if ([self isFiltering])
                subregion = _searchResults[cellPath.row];
            else if ([self.region isKindOfClass:OACustomRegion.class])
                subregion = _customRegions[cellPath.row];
            else if (tableView == _tableView)
                subregion = [self getResourceItems][cellPath.row];

            return (subregion != nil);
        }
    }

    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kOpenDetailsSegue] && [sender isKindOfClass:[OALocalResourceItem class]])
    {
        OALocalResourceInformationViewController *resourceInfoViewController = [segue destinationViewController];
        resourceInfoViewController.openFromSplash = _openFromSplash;
        resourceInfoViewController.baseController = self;
        
        OALocalResourceItem *item = sender;
        if (item)
        {
            if (item.worldRegion)
                resourceInfoViewController.regionTitle = item.worldRegion.name;
            else if (self.region.name)
                resourceInfoViewController.regionTitle = self.region.name;
            else
                resourceInfoViewController.regionTitle = item.title;
            
            if ([item isKindOfClass:[OASqliteDbResourceItem class]])
            {
                [resourceInfoViewController initWithLocalSqliteDbItem:(OASqliteDbResourceItem *) item];
                return;
            }
            else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
            {
                [resourceInfoViewController initWithLocalOnlineSourceItem:(OAOnlineTilesResourceItem *) item];
                return;
            }
            else
            {
                NSString *resourceId = item.resourceId.toNSString();
                [resourceInfoViewController initWithLocalResourceId:resourceId];
            }
        }
        
        resourceInfoViewController.localItem = item;
        return;
    }

    if (![sender isKindOfClass:[UITableViewCell class]])
        return;

    UITableViewCell *cell = (UITableViewCell *) sender;
    UITableView *tableView = [cell getTableView];
    NSIndexPath *cellPath = [tableView indexPathForCell:cell];

    if ([segue.identifier isEqualToString:kOpenSubregionSegue])
    {
        OAManageResourcesViewController *subregionViewController = [segue destinationViewController];

        subregionViewController->hideUpdateButton = YES;
        subregionViewController->_doNotSearch = [self isFiltering] || _doNotSearch || cellPath.section == _extraMapsSection;
        
        OAWorldRegion *subregion = nil;
        if ([self isFiltering])
            subregion = _searchResults[cellPath.row];
        else if (cellPath.section == _otherMapsSection)
            subregion = [_app.worldRegion getSubregion:_otherRegionId];
        else if (cellPath.section == _nauticalMapsSection)
            subregion = [_app.worldRegion getSubregion:_nauticalRegionId];
        else if (cellPath.section == _extraMapsSection)
            subregion = _customRegions[cellPath.row];
        else if (tableView == _tableView)
            subregion = [self getResourceItems][cellPath.row];

        self.navigationItem.backBarButtonItem = nil;

        [subregionViewController setupWithRegion:subregion
                             andWorldRegionItems:nil
                                        andScope:_currentScope];
    }
    else if ([segue.identifier isEqualToString:kOpenOutdatedResourcesSegue])
    {
        OAOutdatedResourcesViewController *outdatedResourcesViewController = [segue destinationViewController];
        outdatedResourcesViewController.openFromSplash = _openFromSplash;
        [outdatedResourcesViewController setupWithRegion:self.region
                                        andOutdatedItems:_outdatedResourceItems];
    }
    else if ([segue.identifier isEqualToString:kOpenInstalledResourcesSegue])
    {
        OAManageResourcesViewController *subregionViewController = [segue destinationViewController];
        
        subregionViewController->hideUpdateButton = YES;
        subregionViewController->_doNotSearch = _isSearching || _doNotSearch;
        subregionViewController->_currentScope = kLocalResourcesScope;
        
    }
    else if ([segue.identifier isEqualToString:kOpenDetailsSegue])
    {
        OALocalResourceInformationViewController *resourceInfoViewController = [segue destinationViewController];
        resourceInfoViewController.openFromSplash = _openFromSplash;
        resourceInfoViewController.baseController = self;
        
        OALocalResourceItem *item = nil;
        if ([self isFiltering])
        {
            item = _searchResults[cellPath.row];
        }
        else
        {
            if (cellPath.section == _resourcesSection && _resourcesSection >= 0)
                item = [self getResourceItems][cellPath.row];
            if (cellPath.section == _regionMapSection && _regionMapSection >= 0)
                item = [self getRegionMapItems][cellPath.row];
            if (cellPath.section == _localSqliteSection)
                item = _localSqliteItems[cellPath.row];
            if (cellPath.section == _localOnlineTileSourcesSection)
                item = _localOnlineTileSources[cellPath.row];
        }

        if (item)
        {
            if (item.worldRegion)
                resourceInfoViewController.regionTitle = item.worldRegion.name;
            else if (self.region.name)
                resourceInfoViewController.regionTitle = self.region.name;
            else
                resourceInfoViewController.regionTitle = item.title;
            
            if ([item isKindOfClass:[OASqliteDbResourceItem class]])
            {
                [resourceInfoViewController initWithLocalSqliteDbItem:(OASqliteDbResourceItem *) item];
                return;
            }
            else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
            {
                [resourceInfoViewController initWithLocalOnlineSourceItem:(OAOnlineTilesResourceItem *) item];
                return;
            }
            else
            {
                NSString *resourceId = item.resourceId.toNSString();
                [resourceInfoViewController initWithLocalResourceId:resourceId];
            }
        }
        
        resourceInfoViewController.localItem = item;
    }
}

#pragma mark -

- (void) doSubscribe:(NSString *)email
{
    [_refreshRepositoryProgressHUD show:YES];
    NSDictionary<NSString *, NSString *> *params = @{ @"os" : @"ios", @"email" : email };
    [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/register_email" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             BOOL error = YES;
             if (response && data)
             {
                 @try
                 {
                     NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                     if (map)
                     {
                         NSString *responseEmail = [map objectForKey:@"email"];
                         if ([email caseInsensitiveCompare:responseEmail] == NSOrderedSame)
                         {
                             [OAIAPHelper increaseFreeMapsCount:3];
                             [[OAAppSettings sharedManager].emailSubscribed set:YES];
                             
                             if (_displaySubscribeEmailView)
                             {
                                 _displaySubscribeEmailView = NO;
                                 [self updateContent];
                             }

                             error = NO;
                             [OAAnalyticsHelper logEvent:@"subscribed_by_email"];
                         }
                     }
                 }
                 @catch (NSException *e)
                 {
                     // ignore
                 }
             }
             [_refreshRepositoryProgressHUD hide:YES];
             if (error)
             {
                 [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"shared_string_unexpected_error") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
             }
         });
     }];
}

#pragma mark OASubscribeEmailViewDelegate

- (void) subscribeEmailButtonPressed
{
    [OAAnalyticsHelper logEvent:@"subscribe_email_pressed"];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_email_address") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *email = alert.textFields.firstObject.text;
        if (email.length == 0 || ![email isValidEmail])
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"osm_live_enter_email") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
        else
            [self doSubscribe:email];
    }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = OALocalizedString(@"shared_string_email_address");
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark OABannerViewDelegate

- (void) bannerButtonPressed
{
    [OAAnalyticsHelper logEvent:@"subscribe_email_pressed"];

    if (self.region == _app.worldRegion && !_displayBannerPurchaseAllMaps)
    {
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:_iapHelper.allWorld navController:self.navigationController];
        /*
        _displayBannerPurchaseAllMaps = YES;
        [self updateFreeDownloadsBanner];
        [_tableView beginUpdates];
        [self updateBannerDimensions:DeviceScreenWidth];
        [_tableView endUpdates];
        */
    }
    else if (_purchaseInAppId)
    {
        OAProduct *product = [_iapHelper product:_purchaseInAppId];
        if (product)
            [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:self.navigationController];
    }
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateFreeDownloadsBanner];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContentIfNeeded];
    });
}

#pragma mark - OADownloadMultipleResourceDelegate

- (void)downloadResources:(OAMultipleResourceItem *)item selectedItems:(NSArray<OAResourceItem *> *)selectedItems;
{
    _multipleItems = selectedItems;
    [OAResourcesUIHelper offerMultipleDownloadAndInstallOf:item selectedItems:selectedItems onTaskCreated:^(id<OADownloadTask> task) {
        [self updateContent];
    } onTaskResumed:^(id<OADownloadTask> task) {
        [self showDownloadViewForTask:task];
    }];
}

- (void)clearMultipleResources
{
    _multipleItems = nil;
}

@end
