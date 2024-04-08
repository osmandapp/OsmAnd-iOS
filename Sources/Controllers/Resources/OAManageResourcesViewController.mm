//
//  OAManageResourcesViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAManageResourcesViewController.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <MBProgressHUD.h>
#import "UITableViewCell+getTableView.h"
#import "OARootViewController.h"
#import "OALocalResourceInformationViewController.h"
#import "OAOutdatedResourcesViewController.h"
#import "OAOcbfHelper.h"
#import "OASubscriptionBannerCardView.h"
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
#import "OATextMultilineTableViewCell.h"
#import "OAColors.h"
#import "OANauticalMapsPlugin.h"
#import "Localization.h"
#import "OAResourcesInstaller.h"
#import "OAIAPHelper.h"
#import "OADownloadMultipleResourceViewController.h"
#import "OASearchResult.h"
#import "OAQuickSearchHelper.h"
#import "OAWeatherHelper.h"
#import "OAWeatherForecastDetailsViewController.h"
#import "QuadRect.h"
#import "OASearchUICore.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAButtonTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define kOpenSubregionSegue @"openSubregionSegue"
#define kOpenOutdatedResourcesSegue @"openOutdatedResourcesSegue"
#define kOpenDetailsSegue @"openDetailsSegue"
#define kOpenInstalledResourcesSegue @"openInstalledResourcesSegue"

#define kSearchCityLimit 10000

#define kAllResourcesScope 0
#define kLocalResourcesScope 1

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchResultsUpdating, UISearchBarDelegate, OASubscriptionBannerCardViewDelegate, OASubscribeEmailViewDelegate, OADownloadMultipleResourceDelegate, OAWeatherForecastDetails>

//@property (weak, nonatomic) IBOutlet UISegmentedControl *scopeControl;
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
    OAIAPHelper *_iapHelper;
    OAWeatherHelper *_weatherHelper;

    NSObject *_dataLock;

    NSInteger _currentScope;

    NSInteger _lastUnusedSectionIndex;

    NSMutableArray *_allSubregionItems;

    NSInteger _freeMemorySection;
    NSInteger _subscribeEmailSection;

    NSMutableArray *_regionMapItems;
    NSMutableArray *_localRegionMapItems;
    
    NSInteger _freeMapsBannerSection;
    NSInteger _downloadDescriptionSection;
    NSInteger _extraMapsSection;
    NSInteger _regionMapSection;
    NSInteger _otherMapsSection;
    NSInteger _nauticalMapsSection;
    NSInteger _travelMapsSection;

    NSInteger _outdatedMapsCount;
    uint64_t _totalOutdatedSize;

    NSInteger _localResourcesSection;
    NSInteger _localSqliteSection;
    NSInteger _resourcesSection;
    NSInteger _localOnlineTileSourcesSection;
    NSInteger _localTravelSection;
    NSInteger _localTerrainMapSourcesSection;
    NSMutableArray *_allResourceItems;
    NSMutableArray *_localResourceItems;
    NSMutableArray *_localSqliteItems;
    NSMutableArray *_localOnlineTileSources;
    NSMutableArray *_localTravelItems;
    NSMutableArray *_localTerrainMapSources;

    NSInteger _weatherForecastRow;

    NSString *_lastSearchString;
    NSInteger _lastSearchScope;
    NSArray *_searchResults;
    
    UIBarButtonItem *_updateButton;
    UIBarButtonItem *_doneButton;
    UISearchController *_searchController;
    
    uint64_t _totalInstalledSize;
    uint64_t _liveUpdatesInstalledSize;

    MBProgressHUD *_refreshRepositoryProgressHUD;
    
    BOOL _isSearching;
    BOOL _doNotSearch;
    BOOL hideUpdateButton;
    
    BOOL _doDataUpdate;
    BOOL _doDataUpdateReload;
    
    BOOL _displayBanner;
    OASubscriptionBannerCardView *_subscriptionBannerView;
    OAFreeMemoryView *_freeMemoryView;
    BOOL _displaySubscribeEmailView;
    OASubscribeEmailView *_subscribeEmailView;
    NSInteger _subscriptionBannerSection;

    BOOL _srtmDisabled;
    BOOL _hasSrtm;

    CALayer *_horizontalLine;
    
    BOOL _viewAppeared;
    BOOL _repositoryUpdating;

    NSString *_otherRegionId;
    NSString *_nauticalRegionId;
    NSString *_travelRegionId;
    
    NSArray<OAWorldRegion *> *_customRegions;
    OADownloadDescriptionInfo *_downloadDescriptionInfo;

    NSArray<OAResourceItem *> *_multipleItems;

    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
}

static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
static QHash< OAWorldRegion *__weak, RegionResources > _resourcesByRegions;

static QHash< OAWorldRegion *__weak, RegionResources > _wikivoyageResources;

static NSMutableArray *_searchableWorldwideRegionItems;

static BOOL _lackOfResources = NO;
static BOOL _repositoryUpdated = NO;

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
        _weatherHelper = [OAWeatherHelper sharedInstance];

        _dataLock = [[NSObject alloc] init];

        self.region = _app.worldRegion;
        _otherRegionId = OsmAnd::WorldRegions::OthersRegionId.toNSString();
        _nauticalRegionId = OsmAnd::WorldRegions::NauticalRegionId.toNSString();
        _travelRegionId = OsmAnd::WorldRegions::TravelRegionId.toNSString();

        _currentScope = kAllResourcesScope;

        _allSubregionItems = [NSMutableArray array];

        _allResourceItems = [NSMutableArray array];
        _localResourceItems = [NSMutableArray array];
        _localSqliteItems = [NSMutableArray array];
        _localOnlineTileSources = [NSMutableArray array];
        _localTravelItems = [NSMutableArray array];
        _localTerrainMapSources = [NSMutableArray array];

        _regionMapItems = [NSMutableArray array];
        _localRegionMapItems = [NSMutableArray array];

        _lastSearchString = @"";
        _lastSearchScope = 0;
        _searchResults = nil;
        
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
    self.navigationItem.title = OALocalizedString(@"res_mapsres");
}

-(void) addAccessibilityLabels
{
    _updateButton.accessibilityLabel = OALocalizedString(@"shared_string_update");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
    
    if (self.region != _app.worldRegion)
        self.navigationItem.title = self.region.name;
    else if (_currentScope == kLocalResourcesScope)
        self.navigationItem.title = OALocalizedString(@"download_tab_local");
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 52.;

    _refreshRepositoryProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_refreshRepositoryProgressHUD];
    
    _displayBanner = ![self shouldHideBanner];
    _displaySubscribeEmailView = ![self shouldHideEmailSubscription];
    
    _customRegions = [OAPluginsHelper getCustomDownloadRegions];
    if ([self.region isKindOfClass:OACustomRegion.class])
    {
        OACustomRegion *customReg = (OACustomRegion *) self.region;
        _downloadDescriptionInfo = customReg.descriptionInfo;
    }

    [self obtainDataAndItems];
    [self prepareContent];

    _freeMemoryView = [[OAFreeMemoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 64.0) localResourcesSize:_totalInstalledSize + _liveUpdatesInstalledSize];
    _subscribeEmailView = [[OASubscribeEmailView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 100.0)];
    _subscribeEmailView.delegate = self;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
    
    if (_displayBanner)
        [self setupSubscriptionBanner];

    self.definesPresentationContext = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    if (self.openFromSplash)
    {
        self.navigationItem.hidesBackButton = YES;
        _doneButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_done") style:UIBarButtonItemStylePlain target:self action:@selector(onDoneClicked:)];
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:_doneButton animated:YES];
    }
    _updateButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_update"] style:UIBarButtonItemStylePlain target:self action:@selector(onUpdateBtnClicked:)];
    if (!hideUpdateButton)
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_updateButton animated:YES];
    [self setupSearchControllerWithFilter:NO];

    [self updateContentIfNeeded];
    
    if (_doNotSearch || _currentScope == kLocalResourcesScope)
        self.navigationItem.searchController = nil;

    _weatherSizeCalculatedObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                       andObserve:_weatherHelper.weatherSizeCalculatedObserver];

    if ([self shouldDisplayWeatherForecast:self.region])
        [_weatherHelper calculateCacheSize:self.region onComplete:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceInstallationFailed:) name:OAResourceInstallationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [[OARootViewController instance] requestProductsWithProgress:NO reload:NO];

    [self applySafeAreaMargins];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_viewAppeared)
    {
        if (!_app.isRepositoryUpdating &&
            AFNetworkReachabilityManager.sharedManager.isReachable && self.region == _app.worldRegion && _currentScope != kLocalResourcesScope)
        {
            if (!_repositoryUpdated)
            {
                _repositoryUpdated = YES;
                [self updateRepository];
            }
        }
        else if (self.region == _app.worldRegion &&
                 !AFNetworkReachabilityManager.sharedManager.isReachable)
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
    _viewAppeared = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tableView.editing = NO;

    if (_weatherSizeCalculatedObserver)
    {
        [_weatherSizeCalculatedObserver detach];
        _weatherSizeCalculatedObserver = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        [_subscribeEmailView updateColorForCALayer];
        _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
        [self.tableView reloadData];
    }
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (void) setupSearchControllerWithFilter:(BOOL)isFiltered
{
    if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"res_search_world") attributes:@{NSForegroundColorAttributeName:[UIColor colorNamed:ACColorNameTextColorTertiary]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"res_search_world") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    } completion:nil];
}

- (BOOL) shouldHideBanner
{
    return _currentScope == kLocalResourcesScope || [OAIAPHelper isPaidVersion] || (self.region == _app.worldRegion && [_iapHelper inAppMapsPurchased].count > 0) || (self.region != _app.worldRegion && [self.region isInPurchasedArea]) || [self.region.regionId isEqualToString:_otherRegionId] || [self.region.regionId isEqualToString:_travelRegionId] || [self.region isKindOfClass:OACustomRegion.class];
}

- (BOOL) shouldHideEmailSubscription
{
    return _currentScope == kLocalResourcesScope || [_iapHelper.allWorld isPurchased] || [OAIAPHelper isPaidVersion] || [OAAppSettings sharedManager].emailSubscribed.get || [self.region isKindOfClass:OACustomRegion.class] || [self shouldDisplayFreeMapsMessage];
}

- (BOOL) shouldDisplayWeatherForecast:(OAWorldRegion *)region
{
    return [OAWeatherHelper shouldHaveWeatherForecast:region] && region == self.region;
}

- (BOOL) shouldDisplayFreeMapsMessage
{
    return self.region != OsmAndApp.instance.worldRegion && self.region.superregion != OsmAndApp.instance.worldRegion && [self hasFreeMaps];
}

- (BOOL) hasFreeMaps
{
    BOOL free = NO;
    for (OAResourceItem *item in _regionMapItems)
    {
        const auto repoRes = _app.resourcesManager->getResourceInRepository(item.resourceId);
        if (repoRes)
            free |= repoRes->free;
        if (free)
            return free;
    }
    return free;
}

- (NSString *) getFreeMapsMessage
{
    NSString *message = @"";
    for (OAResourceItem *item in _regionMapItems)
    {
        const auto repoRes = _app.resourcesManager->getResourceInRepository(item.resourceId);
        if (repoRes)
            message = repoRes->message.toNSString();
        if (message.length > 0)
            return message;
    }
    return message;
}

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    if (value == self.region)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_weatherForecastRow != -1)
            {
                OAResourceItem *item = _regionMapItems[_weatherForecastRow];
                [self updateDisplayItem:item];
            }
        });
    }
}

- (void) updateContentIfNeeded
{
    BOOL needUpdateContent = [self isNauticalScope] || [self isTravelGuidesScope];
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
    if (AFNetworkReachabilityManager.sharedManager.isReachable)
    {
        // hide no internet popup
        [OAPluginPopupViewController hideNoInternetConnection];
        
        if (!_app.resourcesManager->isRepositoryAvailable() && !_app.isRepositoryUpdating)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateRepository];
            });
    }
}

- (void)setupSubscriptionBanner
{
    if (!_displayBanner)
    {
        _subscriptionBannerView = nil;
        return;
    }

    if ([self.region isKindOfClass:OACustomRegion.class])
        return;

    int freeMaps = [OAIAPHelper freeMapsAvailable];
    EOASubscriptionBannerType bannerType = freeMaps > 0 ? EOASubscriptionBannerFree : EOASubscriptionBannerNoFree;

    if (_subscriptionBannerView && _subscriptionBannerView.type == bannerType && _subscriptionBannerView.freeMapsCount == freeMaps)
    {
        [_subscriptionBannerView updateFrame];
        return;
    }

    if (!_subscriptionBannerView || _subscriptionBannerView.type != bannerType)
    {
        _subscriptionBannerView = [[OASubscriptionBannerCardView alloc] initWithType:bannerType];
        _subscriptionBannerView.delegate = self;
    }

    [_subscriptionBannerView updateView];
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
    _customRegions = [OAPluginsHelper getCustomDownloadRegions];
    [self updateMultipleResources];
    [self obtainDataAndItems];
    [self prepareContent];
    [self setupSubscriptionBanner];
    [self refreshContent:YES];

    if ([self shouldDisplayWeatherForecast:self.region])
        [_weatherHelper calculateCacheSize:self.region onComplete:nil];

    if (_repositoryUpdating)
    {
        _repositoryUpdating = NO;
        _updateButton.enabled = YES;

        [_refreshRepositoryProgressHUD hide:YES];
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
        const auto acceptedExtension = QString::fromNSString(region.acceptedExtension).toLower();
        bool checkExtension = acceptedExtension.length() > 0;
        
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
                if (checkExtension)
                {
                    if (resource->id.endsWith(acceptedExtension))
                        regionResources.allResources.remove(resource->id);
                }
                else if (resource->id.startsWith(downloadsIdPrefix))
                {
                    regionResources.allResources.remove(resource->id);
                }
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
            if (checkExtension)
            {
                if (!resource->id.endsWith(acceptedExtension))
                    continue;
            }
            else if (!resource->id.startsWith(downloadsIdPrefix))
            {
                continue;
            }
            
            regionResources.allResources.insert(resource->id, resource);
            regionResources.outdatedResources.insert(resource->id, resource);
            regionResources.localResources.insert(resource->id, resource);
        }
        
        for (const auto& resource : _localResources)
        {
            if (checkExtension)
            {
                if (!resource->id.endsWith(acceptedExtension))
                    continue;
            }
            else if (!resource->id.startsWith(downloadsIdPrefix))
            {
                continue;
            }

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
                if (checkExtension)
                {
                    if (!resource->id.endsWith(acceptedExtension))
                        continue;
                }
                else if (!resource->id.startsWith(downloadsIdPrefix))
                {
                    continue;
                }
                
                switch (resource->type)
                {
                    case OsmAndResourceType::SrtmMapRegion:
                        hasSrtm = YES;
                    case OsmAndResourceType::MapRegion:
                    case OsmAndResourceType::WikiMapRegion:
                    case OsmAndResourceType::DepthContourRegion:
                    case OsmAndResourceType::DepthMapRegion:
                    case OsmAndResourceType::HeightmapRegionLegacy:
                    case OsmAndResourceType::GeoTiffRegion:
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
        if (!self.region.superregion && ([subregion.regionId isEqualToString:_otherRegionId] || [subregion.regionId isEqualToString:_nauticalRegionId] || [subregion.regionId isEqualToString:_travelRegionId]))
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
    BOOL travelRegion = region == self.region && [region.regionId isEqualToString:_travelRegionId];

    NSMutableArray<OAResourceItem *> *regionMapArray = [NSMutableArray array];
    NSMutableArray<OAResourceItem *> *allResourcesArray = [NSMutableArray array];
    NSMutableArray<OAResourceItem *> *srtmResourcesArray = [NSMutableArray array];

    OAOsmandDevelopmentPlugin *plugin = (OAOsmandDevelopmentPlugin *) [OAPluginsHelper getPlugin:OAOsmandDevelopmentPlugin.class];
    for (const auto& resource_ : regionResources.allResources)
    {
        OAResourceItem *item_ = [self collectSubregionItem:region regionResources:regionResources resource:resource_];
        if (item_)
        {
            if (nauticalRegion || travelRegion)
            {
                [allResourcesArray addObject:item_];
            }
            else if (item_.resourceType == OsmAndResourceType::HeightmapRegionLegacy)
            {
                // Hide heightmaps of sqlite format
                continue;
            }
            else if (region == self.region)
            {
                if ([OAResourceType isSRTMResourceItem:item_])
                    [srtmResourcesArray addObject:item_];
                else
                    [regionMapArray addObject:item_];
            }
            else
            {
                [allResourcesArray addObject:item_];
            }
        }
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

    if (srtmResourcesArray.count > 0)
    {
        OAMultipleResourceItem *multipleResourceItem = [[OAMultipleResourceItem alloc] initWithType:OsmAndResourceType::SrtmMapRegion items:srtmResourcesArray];
        multipleResourceItem.worldRegion = self.region;
        if (![OAResourceType isSingleSRTMResourceItem:multipleResourceItem])
        {
            [_regionMapItems addObject:multipleResourceItem];
        }
        else
        {
            BOOL isInstalled = NO;
            for (OAResourceItem *resourceItem in srtmResourcesArray)
            {
                isInstalled = _app.resourcesManager->isResourceInstalled(resourceItem.resourceId);
                if (isInstalled)
                {
                    [regionMapArray addObject:resourceItem];
                    [_regionMapItems addObject:resourceItem];
                    break;
                }
            }
            if (!isInstalled)
                [_regionMapItems addObject:multipleResourceItem];
        }
    }

    for (OAResourceItem *regItem in regionMapArray)
    {
        for (OAResourceItem *resItem in _allResourceItems)
        {
            if (resItem.resourceId == regItem.resourceId)
            {
                [_allResourceItems removeObject:regItem];
                break;
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
    else if (travelRegion)
    {
        [_allResourceItems addObjectsFromArray:allResourcesArray];
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
                item.title = OALocalizedString(@"srtm_plugin_disabled");
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

- (BOOL) isNauticalScope
{
    return [self.region.regionId isEqualToString:_nauticalRegionId];
}

- (BOOL) isTravelGuidesScope
{
    return [self.region.regionId isEqualToString:_travelRegionId];
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
    [_localTravelItems removeAllObjects];
    [_localTerrainMapSources removeAllObjects];
    _outdatedMapsCount = 0;
    _totalOutdatedSize = 0;
    for (const auto& outdatedResource : _outdatedResources)
    {
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:outdatedResource->id];
        if (!match)
            continue;

        OAOutdatedResourceItem *item = [[OAOutdatedResourceItem alloc] init];
        item.resourceId = outdatedResource->id;
        item.resourceType = outdatedResource->type;
        item.title = [OAResourcesUIHelper titleOfResource:outdatedResource
                                                 inRegion:match
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = outdatedResource;
        item.downloadTask = [self getDownloadTaskFor:outdatedResource->id.toNSString()];
        item.worldRegion = match;

        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.size = resourceInRepository->size;
        item.sizePkg = resourceInRepository->packageSize;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];

        if (item.title != nil)
        {
            if (![item.worldRegion.regionId isEqualToString:_travelRegionId])
            {
                if (match == self.region)
                    [_localRegionMapItems addObject:item];
                else
                    [_localResourceItems addObject:item];
            }
            _outdatedMapsCount++;
            _totalOutdatedSize += resourceInRepository->packageSize;
        }
    }

    // Local Resources
    _liveUpdatesInstalledSize = _app.resourcesManager->changesManager->getUpdatesSize();
    
    _totalInstalledSize = 0;
    for (const auto& localResource : _localResources)
    {
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:localResource->id];

        if ((!match && ![OAResourceType isMapResourceType:localResource->type]) || localResource->id == QString::fromNSString(kWorldMiniBasemapKey.lowercaseString))
            continue;

        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = localResource->id;
        item.resourceType = localResource->type;
        if (match)
        {
            item.title = [OAResourcesUIHelper titleOfResource:localResource
                                                     inRegion:match
                                               withRegionName:YES
                                             withResourceType:NO];
        }
        else
        {
            NSString *title = [OAFileNameTranslationHelper getMapName:localResource->id.toNSString()];
            item.title = title;
        }
            
        item.resource = localResource;
        if (match)
            item.downloadTask = [self getDownloadTaskFor:localResource->id.toNSString()];
        item.size = localResource->size;
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];;
        item.worldRegion = match;
        NSString *localResourcePath = localResource->localPath.toNSString();
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResourcePath error:NULL] fileModificationDate];

        _totalInstalledSize += localResource->size;
        
        if (item.title != nil)
        {
            if ([item.worldRegion.regionId isEqualToString:_travelRegionId])
            {
                [_localTravelItems addObject:item];
            }
            else
            {

                if (match == self.region)
                {
                    if (![_localRegionMapItems containsObject:item])
                        [_localRegionMapItems addObject:item];
                    
                }
                else
                {
                    if (![_localResourceItems containsObject:item] && ![_localTerrainMapSources containsObject:item])
                    {
                        if (item.resourceType != OsmAndResourceType::GeoTiffRegion && item.resourceType != OsmAndResourceType::HeightmapRegionLegacy)
                            [_localResourceItems addObject:item];
                        else
                            [_localTerrainMapSources addObject:item];

                    }
                }
            }
        }
    }
    [_localResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_localRegionMapItems sortUsingComparator:self.resourceItemsComparator];
    [_localTravelItems sortUsingComparator:self.resourceItemsComparator];
    [_localTerrainMapSources sortUsingComparator:self.resourceItemsComparator];
    
    for (OAResourceItem *item in _regionMapItems)
    {
        if (item.resourceId == QStringLiteral(kWorldSeamarksKey) || item.resourceId == QStringLiteral(kWorldSeamarksOldKey))
        {
            [_regionMapItems removeObject:item];
            break;
        }
    }
}

- (void) prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;
        _freeMapsBannerSection = -1;
        _downloadDescriptionSection = -1;
        _extraMapsSection = -1;
        _otherMapsSection = -1;
        _nauticalMapsSection = -1;
        _travelMapsSection = -1;
        _regionMapSection = -1;
        _subscriptionBannerSection = -1;
        _subscribeEmailSection = -1;
        _localResourcesSection = -1;
        _resourcesSection = -1;
        _localSqliteSection = -1;
        _localOnlineTileSourcesSection = -1;
        _localTravelSection = -1;
        _localTerrainMapSourcesSection = -1;
        _freeMemorySection = -1;

        _weatherForecastRow = -1;
        if ([self shouldDisplayWeatherForecast:self.region])
        {
            for (NSInteger i = 0; i < _regionMapItems.count; i ++)
            {
                OAResourceItem *resourceItem = _regionMapItems[i];
                if (resourceItem.resourceType == OsmAndResourceType::WeatherForecast)
                {
                    _weatherForecastRow = i;
                    break;
                }
            }
        }

        if (_displayBanner)
            _subscriptionBannerSection = _lastUnusedSectionIndex++;
        
        if (![self.region isKindOfClass:OACustomRegion.class])
            _freeMemorySection = _lastUnusedSectionIndex++;
        
        if ([self shouldDisplayFreeMapsMessage])
            _freeMapsBannerSection = _lastUnusedSectionIndex++;
        
        if (_displaySubscribeEmailView)
            _subscribeEmailSection = _lastUnusedSectionIndex++;

        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion)
            _localResourcesSection = _lastUnusedSectionIndex++;

        if (_currentScope == kAllResourcesScope && _downloadDescriptionInfo)
            _downloadDescriptionSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && _customRegions.count > 0 && (self.region == _app.worldRegion || [self.region isKindOfClass:OACustomRegion.class]))
            _extraMapsSection = _lastUnusedSectionIndex++;

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
        
        if (_currentScope == kLocalResourcesScope && _localTravelItems.count > 0)
            _localTravelSection = _lastUnusedSectionIndex++;

        if (_currentScope == kLocalResourcesScope && _localTerrainMapSources.count > 0)
            _localTerrainMapSourcesSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion && [_app.worldRegion containsSubregion:_otherRegionId])
        {
            OAWorldRegion *otherMaps = [_app.worldRegion getSubregion:_otherRegionId];
            if (otherMaps.subregions.count > 0)
                _otherMapsSection = _lastUnusedSectionIndex++;
        }

        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion && [_app.worldRegion containsSubregion:_nauticalRegionId] && [[_app.worldRegion getSubregion:_nauticalRegionId] isInPurchasedArea])
            _nauticalMapsSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion)
            _travelMapsSection = _lastUnusedSectionIndex++;
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
            else
            {
                [self.tableView reloadData];
            }
        }
        else
        {
            [self.tableView reloadData];
        }
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

                id searchResult = _searchResults[i];
                OAResourceItem *item = (OAResourceItem *) ([searchResult isKindOfClass:OASearchResult.class] ? ((OASearchResult *) searchResult).relatedObject : searchResult);

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

- (void)updateDisplayItem:(OAResourceItem *)item
{
    if (item.resourceType == OsmAndResourceType::WeatherForecast && self.region == item.worldRegion)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_weatherForecastRow inSection:_regionMapSection];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (BOOL)hasLocalResources
{
    return _localResourceItems.count > 0 || _localRegionMapItems.count > 0 || _localSqliteItems.count > 0 || _localOnlineTileSources.count > 0 || _localTravelItems.count > 0 || _localTerrainMapSources.count > 0;
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

- (void)cancelSearch
{
    [[OAQuickSearchHelper instance] cancelSearchCities];
    _searchResults = @[];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.view removeSpinner];
    });
}

- (void) performSearchForSearchString:(NSString *)searchString
                       andSearchScope:(NSInteger)searchScope
{
    @synchronized(_dataLock)
    {
        // If case searchString is empty, there are no results
        if (searchString == nil || searchString.length == 0)
        {
            [self cancelSearch];
            return;
        }

        searchString = [searchString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        // In case searchString has only spaces, also nothing to do here
        if (searchString.length == 0)
        {
            [self cancelSearch];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSpinner];
        });

        // Select where to look
        NSArray<OAWorldRegion *> *searchableContent = _searchableWorldwideRegionItems;

        // Search through subregions:
        NSComparator regionComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
            return [region1.name localizedCaseInsensitiveCompare:region2.name];
        };

        // Regions that start with given name have higher priority
        NSPredicate *startsWith = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", searchString];
        NSMutableArray *regionsStartsWith = [[searchableContent filteredArrayUsingPredicate:startsWith] mutableCopy];
        if ([regionsStartsWith count] == 0)
        {
            NSPredicate *anyStartsWith = [NSPredicate predicateWithFormat:@"ANY allNames BEGINSWITH[cd] %@", searchString];
            [regionsStartsWith addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyStartsWith]];
        }
        [regionsStartsWith sortUsingComparator:regionComparator];

        // Regions that only contain given string have less priority
        NSPredicate *onlyContains = [NSPredicate predicateWithFormat:
                                     @"(name CONTAINS[cd] %@) AND NOT (name BEGINSWITH[cd] %@)",
                                     searchString,
                                     searchString];
        NSMutableArray *regionsOnlyContains = [[searchableContent filteredArrayUsingPredicate:onlyContains] mutableCopy];
        if ([regionsOnlyContains count] == 0)
        {
            NSPredicate *anyOnlyContains = [NSPredicate predicateWithFormat:
                                            @"(ANY allNames CONTAINS[cd] %@) AND NOT (ANY allNames BEGINSWITH[cd] %@)",
                                            searchString,
                                            searchString];
            [regionsOnlyContains addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyOnlyContains]];
        }
        [regionsOnlyContains sortUsingComparator:regionComparator];

        // Assemble all regions all togather
        NSArray *regions = [regionsStartsWith arrayByAddingObjectsFromArray:regionsOnlyContains];
        NSArray *resultByContains = [self createSearchResult:regions byMapRegion:NO];
        _searchResults = resultByContains;
        [_tableView reloadData];

        [self.view addSpinner];
        [OAQuickSearchHelper.instance searchCityLocations:searchString
                                       searchLocation:_app.locationServices.lastKnownLocation
                                         searchBBox31:[[QuadRect alloc] initWithLeft:0 top:0 right:INT_MAX bottom:INT_MAX]
                                         allowedTypes:@[@"city", @"town"]
                                                limit:kSearchCityLimit
                                           onComplete:^(NSArray<OASearchResult *> *searchResults)
         {
            NSMutableArray *regionsByCity = [NSMutableArray array];
            for (OASearchResult *amenity in searchResults)
            {
                OAWorldRegion *region = [_app.worldRegion findAtLat:amenity.location.coordinate.latitude lon:amenity.location.coordinate.longitude];
                if (region)
                {
                    NSArray *searchResult = [self createSearchResult:@[region] byMapRegion:YES];
                    if (searchResult.count == 1 && [searchResult.firstObject isKindOfClass:OAResourceItem.class])
                    {
                        amenity.relatedObject = searchResult.firstObject;
                        [regionsByCity addObject:amenity];
                    }
                    else
                    {
                        [regionsByCity addObjectsFromArray:searchResult];
                    }
                }
            }
            if (regionsByCity.count > 0)
            {
                _searchResults = [resultByContains arrayByAddingObjectsFromArray:regionsByCity];
                [_tableView reloadData];
            }
            [self.view removeSpinner];
        }];
    }
}

- (OAResourceItem *)createResourceItemResult:(std::shared_ptr<const OsmAnd::ResourcesManager::Resource>)resource_
                                     region:(OAWorldRegion *)region
                            regionResources:(RegionResources)regionResources
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
            item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];

            if (item.title == nil)
                return nil;

            return item;
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
            auto localResource = _app.resourcesManager->getLocalResource(item.resourceId);
            if (localResource)
            {
                NSString *localResourcePath = localResource->localPath.toNSString();
                item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResourcePath error:NULL] fileModificationDate];
                item.resource = localResource;
                item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];
            }

            item.size = resource->size;

            if (item.title == nil)
                return nil;

            return item;
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
        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

        if (item.title == nil)
            return nil;

        return item;
    }

    return nil;
}

- (NSArray *)createSearchResult:(NSArray<OAWorldRegion *> *)regions byMapRegion:(BOOL)byMapRegion
{
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
            OAResourceItem *item = [self createResourceItemResult:resource_ region:region regionResources:regionResources];
            if (item)
                [resourceItems addObject:item];
        }

        if (resourceItems.count > 1)
        {
            if (byMapRegion)
            {
                for (OAResourceItem *item in resourceItems)
                {
                    if (item.resourceType == OsmAndResourceType::MapRegion)
                        [results addObject:item];
                }
            }

            if ((!byMapRegion && ![results containsObject:region]) || results.count == 0)
                [results addObject:region];
        }
        else
        {
            [results addObjectsFromArray:resourceItems];
        }
    }
    return results;
}

- (void) showNoInternetAlertForCatalogUpdate
{
    [[OARootViewController instance] showNoInternetAlertFor:OALocalizedString(@"res_catalog_upd")];
}

- (void) updateRepository
{
    _doDataUpdateReload = YES;
    _updateButton.enabled = NO;
    [_refreshRepositoryProgressHUD show:YES];
    [OAOcbfHelper downloadOcbfIfUpdated:^{
        [_app loadWorldRegions];
        self.region = _app.worldRegion;
        [_app startRepositoryUpdateAsync:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_refreshRepositoryProgressHUD hide:YES];
            [self updateContent];
            [_app.worldRegion buildResourceGroupItem];
            _updateButton.enabled = YES;
        });
    }];
}

- (UITableView *) getTableView
{
    return self.tableView;
}

- (void) showDetailsOf:(OALocalResourceItem *)item
{
    if (item.resourceType == OsmAndResourceType::WeatherForecast)
    {
        OAWeatherForecastDetailsViewController *forecastDetailsViewController = [[OAWeatherForecastDetailsViewController alloc] initWithRegion:item.worldRegion localResourceItem:item];
        forecastDetailsViewController.delegate = self;
        [self.navigationController pushViewController:forecastDetailsViewController animated:YES];
    }
    else
    {
        [self performSegueWithIdentifier:kOpenDetailsSegue sender:item];
    }
}

- (IBAction) onDoneClicked:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)onUpdateBtnClicked:(id)sender
{
    [self onRefreshRepositoryButtonClicked];
}

- (void)onRefreshRepositoryButtonClicked
{
    if (AFNetworkReachabilityManager.sharedManager.isReachable)
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
        if ((multipleItem.resourceType == OsmAndResourceType::SrtmMapRegion || multipleItem.resourceType == OsmAndResourceType::HeightmapRegionLegacy || multipleItem.resourceType == OsmAndResourceType::GeoTiffRegion) && ![_iapHelper.srtm isActive])
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
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                [self.navigationController presentViewController:navigationController animated:YES completion:nil];
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

    if (section == _subscriptionBannerSection)
        return _subscriptionBannerView;

    if (section == _freeMemorySection)
        return _freeMemoryView;

    if (section == _subscribeEmailSection)
        return _subscribeEmailView;

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isFiltering] || (_downloadDescriptionInfo && section == _downloadDescriptionSection) || section == _freeMapsBannerSection)
        return 0.0;

    if (section == _subscriptionBannerSection)
        return _subscriptionBannerView.bounds.size.height;

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
        return ([_localResourceItems count] > 0 ? 1 : 0) + ([_localRegionMapItems count] > 0 ? 1 : 0) + (_localSqliteItems.count > 0 ? 1 : 0) + (_displaySubscribeEmailView ? 1 : 0) + (_localOnlineTileSources.count > 0 ? 1 : 0) + (_localTravelItems.count > 0 ? 1 : 0) + (_localTerrainMapSources.count > 0 ? 1 : 0) + 1;

    NSInteger sectionsCount = 0;

    if (_subscriptionBannerSection >= 0)
        sectionsCount++;
    if (_subscribeEmailSection >= 0)
        sectionsCount++;
    if (_freeMemorySection >= 0)
        sectionsCount++;
    if (_freeMapsBannerSection)
        sectionsCount++;
    if (_extraMapsSection >= 0)
        sectionsCount++;
    if (_downloadDescriptionSection >= 0)
        sectionsCount++;
    if (_localResourcesSection >= 0)
        sectionsCount++;
    if (_resourcesSection >= 0)
        sectionsCount++;
    if (_regionMapSection >= 0)
        sectionsCount++;
    if (_otherMapsSection >= 0)
        sectionsCount++;
    if (_nauticalMapsSection >= 0)
        sectionsCount++;
    if (_travelMapsSection >= 0)
        sectionsCount++;

    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isFiltering])
        return [_searchResults count];

    if (section == _subscriptionBannerSection)
        return 0;
    if (section == _freeMemorySection)
        return 0;
    if (section == _freeMapsBannerSection)
        return 1;
    if (section == _extraMapsSection)
        return _customRegions.count;
    if (section == _downloadDescriptionSection)
        return _downloadDescriptionInfo.getActionButtons.count + 1;
    if (section == _resourcesSection)
        return [[self getResourceItems] count];
    if (section == _localResourcesSection)
        return ([self hasLocalResources]) ? 2 : 1;
    if (section == _regionMapSection)
        return [[self getRegionMapItems] count];
    if (section == _localSqliteSection)
        return _localSqliteItems.count;
    if (section == _localOnlineTileSourcesSection)
        return [_localOnlineTileSources count];
    if (section == _localTravelSection)
        return [_localTravelItems count];
    if (section == _localTerrainMapSourcesSection)
        return [_localTerrainMapSources count];
    if (section == _otherMapsSection)
        return 1;
    if (section == _nauticalMapsSection)
        return 1;
    if (section == _travelMapsSection)
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
            else if (section == _localTravelSection)
                return OALocalizedString(@"shared_string_travel_guides");
            else if (section == _localTerrainMapSourcesSection)
                return OALocalizedString(@"terrain_3D_maps");
            else
                return OALocalizedString(@"res_mapsres");
        }

        if (section == _extraMapsSection)
            return OALocalizedString(@"extra_maps_menu_group");
        if (section == _resourcesSection)
        {
            if ([self isNauticalScope])
                return OALocalizedString(@"nautical_maps");
            else if ([self isTravelGuidesScope])
                return OALocalizedString(@"shared_string_travel_guides");
            else
                return OALocalizedString(@"res_worldwide");
        }
        if (section == _regionMapSection)
            return OALocalizedString(@"res_world_map");
        if (section == _otherMapsSection)
            return OALocalizedString(@"download_select_map_types");
        if (section == _nauticalMapsSection)
            return OALocalizedString(@"nautical_maps");
        if (section == _travelMapsSection)
            return OALocalizedString(@"shared_string_travel_guides");

        return nil;
    }

    if (section == _extraMapsSection)
        return OALocalizedString(@"extra_maps_menu_group");
    if (section == _resourcesSection)
    {
        if ([self isNauticalScope])
            return OALocalizedString(@"nautical_maps");
        else if ([self isTravelGuidesScope])
            return OALocalizedString(@"shared_string_travel_guides");
        else
            return OALocalizedString(@"res_mapsres");
    }
    if (section == _regionMapSection)
        return OALocalizedString(@"res_region_map");
    if (section == _otherMapsSection)
        return OALocalizedString(@"download_select_map_types");
    if (section == _nauticalMapsSection)
        return OALocalizedString(@"nautical_maps");
    if (section == _travelMapsSection)
        return OALocalizedString(@"shared_string_travel_guides");

    return nil;
}

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    static NSString * const downloadingResourceCell = @"downloadingResourceCell";
    
    NSString *cellTypeId = nil;
    id item_ = nil;
    if ([self isFiltering])
    {
        item_ = _searchResults[indexPath.row];
        
        if (![item_ isKindOfClass:[OAWorldRegion class]])
        {
            OAResourceItem *item = (OAResourceItem *) ([item_ isKindOfClass:OASearchResult.class] ? ((OASearchResult *) item_).relatedObject : item_);
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
        OAResourceItem *item = (OAResourceItem *) ([item_ isKindOfClass:OASearchResult.class] ? ((OASearchResult *) item_).relatedObject : item_);
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
    static NSString * const subregionCell = @"subregionCell";
    static NSString * const outdatedResourceCell = @"outdatedResourceCell";
    static NSString * const localResourceCell = @"localResourceCell";
    static NSString * const repositoryResourceCell = @"repositoryResourceCell";
    static NSString * const downloadingResourceCell = @"downloadingResourceCell";
    static NSString * const outdatedResourcesSubmenuCell = @"outdatedResourcesSubmenuCell";
    static NSString * const installedResourcesSubmenuCell = @"installedResourcesSubmenuCell";

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
        else if ([item_ isKindOfClass:[OAResourceItem class]] || [item_ isKindOfClass:[OASearchResult class]])
        {
            OAResourceItem *item = (OAResourceItem *) ([item_ isKindOfClass:OASearchResult.class] ? ((OASearchResult *) item_).relatedObject : item_);

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

            BOOL isSearchResult = [item_ isKindOfClass:[OASearchResult class]];
            title = isSearchResult ? ((OASearchResult *) item_).localeName : item.title;
            if (isSearchResult)
                subtitle = item.title;
            else if (item.worldRegion.superregion)
                subtitle = item.worldRegion.superregion.name;
            else
                subtitle = item.worldRegion.name;
        }
    }
    else
    {
        if (indexPath.section == _localResourcesSection && _localResourcesSection >= 0)
        {
            BOOL isLocalCell = indexPath.row == 0 && [self hasLocalResources];
            cellTypeId = isLocalCell ? installedResourcesSubmenuCell : outdatedResourcesSubmenuCell;
            title = OALocalizedString(isLocalCell ? @"download_tab_local" : @"download_tab_updates");

            if (isLocalCell)
            {
                subtitle = [NSString stringWithFormat:@"%lu %@ - %@",
                        _localResourceItems.count + _localRegionMapItems.count + _localSqliteItems.count + _localOnlineTileSources.count + _localTravelItems.count,
                        OALocalizedString(@"res_maps_inst"),
                        [NSByteCountFormatter stringFromByteCount:_totalInstalledSize
                                                       countStyle:NSByteCountFormatterCountStyleFile]];
            }
            else
            {
                subtitle = _outdatedMapsCount > 0
                        ? [NSString stringWithFormat:@"%li %@ - %@",
                                _outdatedMapsCount,
                                OALocalizedString(@"res_maps_inst"),
                                [NSByteCountFormatter stringFromByteCount:_totalOutdatedSize
                                                               countStyle:NSByteCountFormatterCountStyleFile]]
                        : OALocalizedString(@"all_maps_are_up_to_date");
            }
        }
        else if (indexPath.section == _extraMapsSection)
        {
            cellTypeId = subregionCell;
            title = _customRegions[indexPath.row].localizedName;
        }
        else if (indexPath.section == _downloadDescriptionSection)
        {
            cellTypeId = indexPath.row == 0 ? [OATextMultilineTableViewCell getCellIdentifier] : [OAButtonTableViewCell getCellIdentifier];
            title = nil;
        }
        else if (indexPath.section == _otherMapsSection)
        {
            cellTypeId = subregionCell;
            title = OALocalizedString(@"download_select_map_types");
        }
        else if (indexPath.section == _nauticalMapsSection)
        {
            cellTypeId = subregionCell;
            title = OALocalizedString(@"nautical_maps");
        }
        else if (indexPath.section == _travelMapsSection)
        {
            cellTypeId = subregionCell;
            title = OALocalizedString(@"shared_string_travel_guides");
        }
        else if ((indexPath.section == _resourcesSection && _resourcesSection >= 0) || indexPath.section == _localTerrainMapSourcesSection)
        {
            item_ = indexPath.section == _localTerrainMapSourcesSection ? _localTerrainMapSources[indexPath.row] : [self getResourceItems][indexPath.row];

            if ([item_ isKindOfClass:[OAWorldRegion class]])
            {
                OAWorldRegion *item = (OAWorldRegion *) item_;
                
                cellTypeId = subregionCell;
                title = item.name;
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
                NSArray *selectedArray = nil;
                if (item.resourceType == OsmAndResourceType::GeoTiffRegion || item.resourceType == OsmAndResourceType::HeightmapRegionLegacy)
                    selectedArray = _localTerrainMapSources;
                else
                    selectedArray = [self getRegionMapItems];

                for (OAResourceItem *it in selectedArray)
                {
                    if (it.resourceType == OsmAndResourceType::MapRegion && ([it isKindOfClass:[OALocalResourceItem class]] || [it isKindOfClass:[OAOutdatedResourceItem class]]))
                    {
                        mapDownloaded = YES;
                        break;
                    }
                }
                
                if (!item.isFree)
                {
                    if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HeightmapRegionLegacy || item.resourceType == OsmAndResourceType::GeoTiffRegion)
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
                    if (item.resourceType == OsmAndResourceType::MapRegion && [self isNauticalScope] && ![OAPluginsHelper isEnabled:OANauticalMapsPlugin.class])
                    {
                        disabled = YES;
                        item.disabled = disabled;
                    }
                    if ([self isTravelGuidesScope] && ![OAPluginsHelper isEnabled:OAWikipediaPlugin.class])
                    {
                        disabled = YES;
                        item.disabled = disabled;
                    }
                    if ((item.resourceType == OsmAndResourceType::DepthContourRegion || item.resourceType == OsmAndResourceType::DepthMapRegion) && (![OAIAPHelper isDepthContoursPurchased] || ![OAPluginsHelper isEnabled:OANauticalMapsPlugin.class]))
                    {
                        disabled = YES;
                        item.disabled = disabled;
                    }
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
                {
                    NSString *srtmFormat = @"";
                    if ([OAResourceType isSRTMResourceItem:item])
                        srtmFormat = [NSString stringWithFormat:@" (%@)", [OAResourceType getSRTMFormatItem:item longFormat:NO]];

                    subtitle = [NSString stringWithFormat:@"%@%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType], srtmFormat, [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
                }
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
                NSArray<OAResourceItem *> *items = ((OAMultipleResourceItem *) item).items;
                for (OAResourceItem *resourceItem in items)
                {
                    if ([OAResourceType isSRTMResourceItem:resourceItem])
                    {
                        if (([OAResourceType isSRTMFSettingOn] && [OAResourceType isSRTMF:resourceItem]) || (![OAResourceType isSRTMFSettingOn] && ![OAResourceType isSRTMF:resourceItem]))
                        {
                            if ([resourceItem isKindOfClass:OARepositoryResourceItem.class])
                                _sizePkg += ((OARepositoryResourceItem *) resourceItem).sizePkg;
                            else if ([resourceItem isKindOfClass:OALocalResourceItem.class] && [OAResourceType isSingleSRTMResourceItem:(OAMultipleResourceItem *) item])
                                _sizePkg += ((OALocalResourceItem *) resourceItem).size;
                        }
                    }
                    else
                    {
                        if ([resourceItem isKindOfClass:OARepositoryResourceItem.class])
                            _sizePkg += ((OARepositoryResourceItem *) resourceItem).sizePkg;
                    }
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

            if (![item isFree])
            {
                if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HeightmapRegionLegacy || item.resourceType == OsmAndResourceType::GeoTiffRegion)
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
                if (item.resourceType == OsmAndResourceType::WeatherForecast
                    && ![_iapHelper.weather isActive] && ![self.region isInPurchasedArea])
                {
                    disabled = YES;
                    item.disabled = disabled;
                }
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

                if (item.resourceType == OsmAndResourceType::WeatherForecast && _sizePkg <= 0 )
                   subtitle = OALocalizedString(@"shared_string_download_update");
                else if (_sizePkg >= 0)
                    subtitle = [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile];
                if ([item isKindOfClass:OAMultipleResourceItem.class] && ([self.region hasGroupItems] || [OAResourceType isSRTMResourceItem:item]))
                {
                    OAMultipleResourceItem *multipleItem = (OAMultipleResourceItem *) item;
                    if ([self.region.resourceTypes containsObject:[OAResourceType toValue:multipleItem.resourceType]])
                    {
                        for (OAResourceItem *resItem in multipleItem.items)
                        {
                            if (([OAResourceType isSRTMFSettingOn] && [OAResourceType isSRTMF:resItem]) || (![OAResourceType isSRTMFSettingOn] && ![OAResourceType isSRTMF:resItem]))
                            {
                                subtitle = [NSString stringWithFormat:@"%@ (%@)  •  %@", subtitle, [OAResourceType getSRTMFormatItem:resItem longFormat:NO], [resItem getDate]];
                                break;
                            }
                        }
                    }
                    else
                    {
                        NSInteger allRegionsCount = 0;
                        NSInteger downloadedRegionsCount = 0;
                        for (OAResourceItem *resourceItem in [self.region.groupItem getItems:multipleItem.resourceType])
                        {
                            allRegionsCount ++;
                            if ([OsmAndApp instance].resourcesManager->isResourceInstalled(resourceItem.resourceId))
                                downloadedRegionsCount ++;
                        }
                        
                        if ([OAResourceType isSRTMResourceItem:multipleItem])
                            allRegionsCount /= 2;
                        
                        if (downloadedRegionsCount == allRegionsCount)
                            subtitle = [NSString stringWithFormat:@"%@: %li", OALocalizedString(@"shared_strings_all_regions"), allRegionsCount];
                        else if (downloadedRegionsCount == 0)
                            subtitle = [NSString stringWithFormat:@"%@: %li  •  %@", OALocalizedString(@"shared_strings_all_regions"), allRegionsCount, subtitle];
                        else
                            subtitle = [NSString stringWithFormat:@"%@: %li / %li  •  %@", OALocalizedString(@"regions"), (allRegionsCount - downloadedRegionsCount), allRegionsCount, subtitle];
                    }
                }
                else
                {
                    NSString *srtmFormat = @"";
                    if ([OAResourceType isSRTMResourceItem:item])
                        srtmFormat = [NSString stringWithFormat:@" (%@)", [OAResourceType getSRTMFormatItem:item longFormat:NO]];

                    subtitle = [NSString stringWithFormat:@"%@%@  •  %@", subtitle, srtmFormat, [item getDate]];
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
        else if (indexPath.section == _localTravelSection)
        {
            OALocalResourceItem *item = _localTravelItems[indexPath.row];
            cellTypeId = localResourceCell;
            title = item.title;
            if (item.size > 0)
                subtitle = [NSString stringWithFormat:@"%@  •  %@", OALocalizedString(@"shared_string_wikivoyage"), [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
            else
                subtitle = OALocalizedString(@"shared_string_wikivoyage");
        }
        
        else if (indexPath.section == _freeMapsBannerSection)
        {
            OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OASimpleTableViewCell *) nib[0];
                [cell anchorContent:EOATableViewCellContentTopStyle];
            }
            if (cell)
            {
                cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 66., 0., 0.);
                cell.titleLabel.text = OALocalizedString(@"free_downloads");
                cell.descriptionLabel.text = [self getFreeMapsMessage];
                cell.leftIconView.image = [UIImage rtlImageNamed:@"ic_custom_map_updates_colored"];
            }
            return cell;
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
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            cell.detailTextLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];

            UIImage *iconImage = [UIImage templateImageNamed:@"ic_custom_download"];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            [btnAcc setTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
            btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else if ([cellTypeId isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        else if ([cellTypeId isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            OAButtonTableViewCell *buttonCell = (OAButtonTableViewCell *) nib[0];
            cell = buttonCell;
            buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [buttonCell leftIconVisibility:NO];
            [buttonCell titleVisibility:NO];
            [buttonCell descriptionVisibility:NO];
            buttonCell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [buttonCell setCustomLeftSeparatorInset:YES];
            buttonCell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            cell.detailTextLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            BOOL isMultipleItem = [item_ isKindOfClass:OAMultipleResourceItem.class];
            BOOL addInfoAccessory = isMultipleItem && [((OAMultipleResourceItem *) item_) allDownloaded];
            if (addInfoAccessory)
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
            }
            else
            {
                NSString *imageNamed = [item_ isKindOfClass:OAMultipleResourceItem.class] && ![self.region.resourceTypes containsObject:[OAResourceType toValue:((OAResourceItem *) item_).resourceType]] ? @"ic_custom_multi_download" : @"ic_custom_download";
                UIImage *iconImage = [UIImage templateImageNamed:imageNamed];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            cell.detailTextLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];

            FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];
            progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    // Fill cell content
    
    if ([cellTypeId isEqualToString:repositoryResourceCell])
    {
        if (!disabled)
        {
            cell.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            BOOL isMultipleItem = [item_ isKindOfClass:OAMultipleResourceItem.class];
            BOOL addInfoAccessory = isMultipleItem && [((OAMultipleResourceItem *) item_) allDownloaded];
            if (addInfoAccessory)
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
            }
            else
            {
                NSString *imageNamed = isMultipleItem && ![self.region.resourceTypes containsObject:[OAResourceType toValue:((OAResourceItem *) item_).resourceType]] ? @"ic_custom_multi_download" : @"ic_custom_download";
                UIImage *iconImage = [UIImage templateImageNamed:imageNamed];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonPressed:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
        }
        else
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
                
            if (self.region && [self.region isInPurchasedArea])
            {
                UILabel *labelGet = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 100.0)];
                labelGet.font = [UIFont scaledSystemFontOfSize:13 weight:UIFontWeightSemibold];
                labelGet.textAlignment = NSTextAlignmentCenter;
                labelGet.textColor = [UIColor colorNamed:ACColorNameIconColorSelected];
                labelGet.text = [OALocalizedString(@"shared_string_get") uppercaseStringWithLocale:[NSLocale currentLocale]];
                
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
                itemGetView.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorSelected].CGColor;
                
                [itemGetView addSubview:labelGet];
                
                cell.accessoryView = itemGetView;
            }
            else
            {
                cell.accessoryView = nil;
            }
        }
    }

    if ([item_ isKindOfClass:OAMultipleResourceItem.class] && ([self.region hasGroupItems] || ((OAResourceItem *) item_).resourceType == OsmAndResourceType::SrtmMapRegion))
    {
        OAMultipleResourceItem *item = (OAMultipleResourceItem *) item_;
        UIColor *color = [UIColor colorNamed:ACColorNameIconColorDisabled];
        NSArray<OAResourceItem *> *items = [self.region hasGroupItems] ? [self.region.groupItem getItems:item.resourceType] : item.items;
        for (OAResourceItem *resourceItem in items)
        {
            if (_app.resourcesManager->isResourceInstalled(resourceItem.resourceId))
            {
                color = UIColorFromRGB(resource_installed_icon_color);
                break;
            }
        }
        cell.imageView.image = [OAResourceType getIcon:item.resourceType templated:YES];
        cell.imageView.tintColor = color;
    }
    else if ([item_ isKindOfClass:OAResourceItem.class] || [item_ isKindOfClass:OASearchResult.class])
    {
        OAResourceItem *item = (OAResourceItem *) ([item_ isKindOfClass:OASearchResult.class] ? ((OASearchResult *) item_).relatedObject : item_);
        UIColor *color = _app.resourcesManager->isResourceInstalled(item.resourceId) ? UIColorFromRGB(resource_installed_icon_color) : [UIColor colorNamed:ACColorNameIconColorDisabled];
        cell.imageView.image = [OAResourceType getIcon:item.resourceType templated:YES];
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
        OAResourceItem *item = [item_ isKindOfClass:OAMultipleResourceItem.class] && downloadingMultipleItem
                ? downloadingMultipleItem
                : (OAResourceItem *) ([item_ isKindOfClass:OASearchResult.class] ? ((OASearchResult *) item_).relatedObject : item_);

        if (item.resourceType != OsmAndResourceType::WeatherForecast)
        {
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
        else
        {
            FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            [progressView setNeedsDisplay];
        }
    }
    else if ([cellTypeId isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *textViewCell = (OATextMultilineTableViewCell *) cell;
        [textViewCell leftIconVisibility:NO];
        [textViewCell clearButtonVisibility:NO];
        textViewCell.textView.attributedText = [OAUtilities attributedStringFromHtmlString:_downloadDescriptionInfo.getLocalizedDescription fontSize:17 textColor:[UIColor colorNamed:ACColorNameTextColorPrimary]];
        textViewCell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorActive]};
        [textViewCell.textView sizeToFit];
    }
    else if ([cellTypeId isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *buttonCell = (OAButtonTableViewCell *) cell;
        [buttonCell.button setTitle:_downloadDescriptionInfo.getActionButtons[indexPath.row - 1].name forState:UIControlStateNormal];
        [buttonCell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [buttonCell.button addTarget:self action:@selector(downloadDescriptionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        buttonCell.button.tag = indexPath.row;
    }
    return cell;
}

- (void) downloadDescriptionButtonPressed:(id)sender
{
    UIButton *button = sender;
    if (button.tag > 0)
        [self openUrlforIndex:button.tag - 1];
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
    else if (indexPath.section == _localTerrainMapSourcesSection)
        item = _localTerrainMapSources[indexPath.row];
    else if (indexPath.section == _otherMapsSection)
        item = [_app.worldRegion getSubregion:_otherRegionId];
    else if (indexPath.section == _nauticalMapsSection)
        item = [_app.worldRegion getSubregion:_nauticalRegionId];
    else if (indexPath.section == _travelMapsSection)
        item = [_app.worldRegion getSubregion:_travelRegionId];
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
        if ([item isKindOfClass:OASearchResult.class])
            item = ((OASearchResult *) item).relatedObject;

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
        else if ([item isKindOfClass:OALocalResourceItem.class] && ((OAResourceItem *) item).resourceType == OsmAndResourceType::WeatherForecast)
        {
            [self showDetailsOf:item];
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

    if (!([item isKindOfClass:[OALocalResourceItem class]] || [item isKindOfClass:[OASearchResult class]] && [((OASearchResult *) item).relatedObject isKindOfClass:[OALocalResourceItem class]]))
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

    if (!([item isKindOfClass:[OALocalResourceItem class]] || [item isKindOfClass:[OASearchResult class]] && [((OASearchResult *) item).relatedObject isKindOfClass:[OALocalResourceItem class]]))
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

    if ([item isKindOfClass:OASearchResult.class])
        item = ((OASearchResult *) item).relatedObject;

    if ([item isKindOfClass:[OALocalResourceItem class]])
    {
        [self offerDeleteResourceOf:item];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL) isFiltering
{
    return _searchController.isActive && ![self searchBarIsEmpty];
}

- (BOOL) searchBarIsEmpty
{
    return _searchController.searchBar.text.length == 0;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    _lastSearchString = @"";
    _lastSearchScope = searchBar.selectedScopeButtonIndex;
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];
    [self setupSearchControllerWithFilter:NO];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    _lastSearchString = searchText;
    _lastSearchScope = searchBar.selectedScopeButtonIndex;
    [self performSearchForSearchString:_lastSearchString
                        andSearchScope:_lastSearchScope];
    if (searchText.length > 0)
        [self setupSearchControllerWithFilter:YES];
    else
        [self setupSearchControllerWithFilter:NO];
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
        else if ([identifier isEqualToString:kOpenDetailsSegue] && [self shouldDisplayWeatherForecast:self.region] && cellPath.row == _weatherForecastRow)
        {
            return NO;
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
        else if (cellPath.section == _travelMapsSection)
            subregion = [_app.worldRegion getSubregion:_travelRegionId];
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
            id searchResult = _searchResults[cellPath.row];
            item = (OALocalResourceItem *) ([searchResult isKindOfClass:OASearchResult.class] ? ((OASearchResult *) searchResult).relatedObject : searchResult);
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
            if (cellPath.section == _localTravelSection)
                item = _localTravelItems[cellPath.row];
            if (cellPath.section == _localTerrainMapSourcesSection)
                item = _localTerrainMapSources[cellPath.row];
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
                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"shared_string_unexpected_error") preferredStyle:UIAlertControllerStyleAlert];
                 [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
                 [self presentViewController:alert animated:YES completion:nil];
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
        if (email.length == 0 || ![email isValidEmail]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_live_enter_email") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
            [self doSubscribe:email];
    }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = OALocalizedString(@"shared_string_email_address");
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void) onButtonPressed
{
    [OAAnalyticsHelper logEvent:@"subscription_pressed"];
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.UNLIMITED_MAP_DOWNLOADS navController:self.navigationController];
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContentIfNeeded];
    });
}

- (void) productRestored:(NSNotification *)notification
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

- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceItem *> *)itemsToCheck
{
    NSMutableArray<OALocalResourceItem *> *itemsToRemove = [NSMutableArray new];
    OAResourceItem *prevItem;
    for (OAResourceItem *itemToCheck in itemsToCheck)
    {
        QString srtmMapName = itemToCheck.resourceId.remove(QLatin1String([OAResourceType isSRTMF:itemToCheck] ? ".srtmf.obf" : ".srtm.obf"));
        if (prevItem && prevItem.resourceId.startsWith(srtmMapName))
        {
            BOOL prevItemInstalled = _app.resourcesManager->isResourceInstalled(prevItem.resourceId);
            if (prevItemInstalled && prevItem.resourceId.compare(itemToCheck.resourceId) != 0)
            {
                [itemsToRemove addObject:(OALocalResourceItem *) prevItem];
            }
            else
            {
                BOOL itemToCheckInstalled = _app.resourcesManager->isResourceInstalled(itemToCheck.resourceId);
                if (itemToCheckInstalled && itemToCheck.resourceId.compare(prevItem.resourceId) != 0)
                    [itemsToRemove addObject:(OALocalResourceItem *) itemToCheck];
            }
        }
        prevItem = itemToCheck;
    }
    [self offerSilentDeleteResourcesOf:itemsToRemove];
}

- (void)clearMultipleResources
{
    _multipleItems = nil;
}

- (void)onDetailsSelected:(OALocalResourceItem *)item
{
    [self showDetailsOf:item];
}

#pragma mark - OAWeatherForecastDetails

- (void)onRemoveForecast
{
    if (_weatherForecastRow != -1)
    {
        [self updateDisplayItem:_regionMapItems[_weatherForecastRow]];
    }
}

- (void)onUpdateForecast
{
    if (_weatherForecastRow != -1)
    {
        [self updateDisplayItem:_regionMapItems[_weatherForecastRow]];
    }
}

- (void)onClearForecastCache;
{
    if (_weatherForecastRow != -1)
    {
        [self updateDisplayItem:_regionMapItems[_weatherForecastRow]];
    }
}

@end
