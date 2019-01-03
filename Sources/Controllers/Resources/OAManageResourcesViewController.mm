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
#import "OAOsmAndLiveViewController.h"
#import "OAOutdatedResourcesViewController.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OAWorldRegion.h"
#import "OALog.h"
#import "OAOcbfHelper.h"
#import "OABannerView.h"
#import "OAUtilities.h"
#import "OAInAppCell.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAFreeMemoryView.h"
#import "OAFirebaseHelper.h"
#import "OAChoosePlanHelper.h"
#import "OASubscribeEmailView.h"
#import "OANetworkUtilities.h"

#include "Localization.h"

#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAResourcesInstaller.h"
#import "OAIAPHelper.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/QKeyValueIterator.h>
#include <OsmAndCore/WorldRegions.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

#define kOpenSubregionSegue @"openSubregionSegue"
#define kOpenOutdatedResourcesSegue @"openOutdatedResourcesSegue"
#define kOpenDetailsSegue @"openDetailsSegue"
#define kOpenInstalledResourcesSegue @"openInstalledResourcesSegue"
#define kOpenOsmAndLiveSegue @"openOsmAndLiveSegue"


#define kAllResourcesScope 0
#define kLocalResourcesScope 1

@interface OAManageResourcesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, OABannerViewDelegate, OASubscribeEmailViewDelegate, UIAlertViewDelegate>

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

    NSObject* _dataLock;

    NSInteger _currentScope;

    NSInteger _lastUnusedSectionIndex;

    NSMutableArray* _allSubregionItems;

    NSInteger _freeMemorySection;
    NSInteger _subscribeEmailSection;

    NSMutableArray* _regionMapItems;
    NSMutableArray* _localRegionMapItems;
    NSInteger _regionMapSection;

    NSInteger _osmAndLiveSection;
    
    NSInteger _outdatedResourcesSection;
    NSMutableArray* _outdatedResourceItems;
    NSArray* _regionsWithOutdatedResources;

    NSInteger _localResourcesSection;
    NSInteger _localSqliteSection;
    NSInteger _resourcesSection;
    NSMutableArray* _allResourceItems;
    NSMutableArray* _localResourceItems;
    NSMutableArray* _localSqliteItems;

    NSString* _lastSearchString;
    NSInteger _lastSearchScope;
    NSArray* _searchResults;
    
    uint64_t _totalInstalledSize;

    MBProgressHUD* _refreshRepositoryProgressHUD;
    
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
}

static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> > _resourcesInRepository;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _localResources;
static QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
static QHash< OAWorldRegion* __weak, RegionResources > _resourcesByRegions;

static NSMutableArray* _searchableWorldwideRegionItems;

static BOOL _lackOfResources;

+ (NSArray<NSString *> *)getResourcesInRepositoryIdsyRegion:(OAWorldRegion *)region
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
    if (self) {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];

        _dataLock = [[NSObject alloc] init];

        self.region = _app.worldRegion;

        _currentScope = kAllResourcesScope;

        _allSubregionItems = [NSMutableArray array];

        _outdatedResourceItems = [NSMutableArray array];

        _allResourceItems = [NSMutableArray array];
        _localResourceItems = [NSMutableArray array];
        _localSqliteItems = [NSMutableArray array];

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

- (void)setupWithRegion:(OAWorldRegion*)region
    andWorldRegionItems:(NSArray*)worldRegionItems
               andScope:(NSInteger)scope
{
    self.region = region;
    _currentScope = scope;
}

-(void)applyLocalization
{
    [super applyLocalization];

    _titleView.text = OALocalizedString(@"res_mapsres");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.toolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.toolbarView.layer addSublayer:_horizontalLine];

    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    if (self.openFromSplash) {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
    
    if (self.region != _app.worldRegion)
        [self.titleView setText:self.region.name];
    else if (_currentScope == kLocalResourcesScope) {
        [self.titleView setText:OALocalizedString(@"res_installed")];
    }

    _refreshRepositoryProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_refreshRepositoryProgressHUD];
    
    if (_currentScope == kLocalResourcesScope ||
        _iapHelper.subscribedToLiveUpdates ||
        (self.region == _app.worldRegion && [_iapHelper isAnyMapPurchased]) ||
        (self.region != _app.worldRegion && [self.region isInPurchasedArea]))
        _displayBanner = NO;
    else
        _displayBanner = YES;

    _displaySubscribeEmailView = ![_iapHelper.allWorld isPurchased] && !_iapHelper.subscribedToLiveUpdates && ![OAAppSettings sharedManager].emailSubscribed;

    [self obtainDataAndItems];
    [self prepareContent];
    
    // IOS-172
    _updateCouneView = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
    _updateCouneView.layer.cornerRadius = 10.0;
    _updateCouneView.layer.masksToBounds = YES;
    _updateCouneView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:143.0/255.0 blue:0.0 alpha:1.0];
    _updateCouneView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12.0];
    _updateCouneView.textAlignment = NSTextAlignmentCenter;
    _updateCouneView.textColor = [UIColor whiteColor];
    
    if (_displayBanner)
    {
        _bannerView = [[OABannerView alloc] init];
        _bannerView.delegate = self;
        [self updateBannerDimensions:DeviceScreenWidth];
        _bannerView.buttonTitle = OALocalizedString(@"shared_string_buy");
    }
    
    _freeMemoryView = [[OAFreeMemoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 64.0)];
    _subscribeEmailView = [[OASubscribeEmailView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 100.0)];
    _subscribeEmailView.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_currentScope == kLocalResourcesScope ||
        (self.region == _app.worldRegion && [_iapHelper isAnyMapPurchased]) ||
        (self.region != _app.worldRegion && [self.region isInPurchasedArea]))
    {
        if (_displayBanner)
        {
            _displayBanner = NO;
            [self updateContent];
        }
    }
    
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
    
    if (_displayBanner)
        [self updateBannerDimensions:DeviceScreenWidth];
    
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceInstalled:) name:OAResourceInstalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceInstallationFailed:) name:OAResourceInstallationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    if (![_iapHelper productsLoaded])
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self loadProducts];
    }
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
                
            } else if (_app.isRepositoryUpdating)
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

- (void)reachabilityChanged:(NSNotification *)notification
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        // hide no internet popup
        [OAPluginPopupViewController hideNoInternetConnection];
        
        if (![_iapHelper productsLoaded])
            [self loadProducts];

        if (!_app.resourcesManager->isRepositoryAvailable() && !_app.isRepositoryUpdating)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateRepository];
            });
    }
}

- (void) loadProducts
{
    [_iapHelper requestProductsWithCompletionHandler:^(BOOL success) {
        
        if (success)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFreeDownloadsBanner];
            });
    }];
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

    if (self.region == _app.worldRegion)
    {
        if (!_displayBannerPurchaseAllMaps)
        {
            int freeMaps = [OAIAPHelper freeMapsAvailable];
            if (freeMaps > 1)
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
        OAWorldRegion *region = self.region;
        while (region.superregion != _app.worldRegion)
            region = region.superregion;
            
        if (region)
            regionId = region.regionId;
        
        if ([regionId isEqualToString:OsmAnd::WorldRegions::AfricaRegionId.toNSString()])
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

- (void) resourceInstalled:(NSNotification *)notification
{
    NSString * resourceId = notification.object;
    OAWorldRegion* match = [OAResourcesBaseViewController findRegionOrAnySubregionOf:_app.worldRegion
                                                                thatContainsResource:QString([resourceId UTF8String])];
    
    const auto citRegionResources = _resourcesByRegions.constFind(match);
    if (citRegionResources == _resourcesByRegions.cend())
        return;
    const auto& regionResources = *citRegionResources;
    
    OsmAndResourceType resourceType = OsmAndResourceType::Unknown;
    
    for (const auto& resource : regionResources.allResources)
        if (resource->id == QString([resourceId UTF8String]))
        {
            resourceType = resource->type;
            break;
        }
    
    if ((!match || ![match isInPurchasedArea]) && resourceType == OsmAndResourceType::MapRegion)
        [OAIAPHelper decreaseFreeMapsCount];
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
        {
            [self onSearchBtnClicked:nil];
        }
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
        const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix).toLower();
        
        RegionResources regionResources;
        RegionResources regionResPrevious;

        if (!doInit)
        {
            const auto citRegionResources = _resourcesByRegions.constFind(region);
            if (citRegionResources != _resourcesByRegions.cend())
                regionResources = *citRegionResources;
        }

        if (!doInit) {

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
                
                //if ([resource->id.toNSString() rangeOfString:@"brazil"].location != NSNotFound)
                //     OALog(@"region=%@, resId=%@, downloadPrefix=%@", region.name,  resource->id.toNSString(), downloadsIdPrefix.toNSString());

                switch (resource->type)
                {
                    case OsmAndResourceType::SrtmMapRegion:
                        hasSrtm = YES;
                    case OsmAndResourceType::MapRegion:
                    case OsmAndResourceType::WikiMapRegion:
                    case OsmAndResourceType::HillshadeRegion:
                        
                        [typesArray addObject:[NSNumber numberWithInt:(int)resource->type]];
                        break;
                        
                    default:
                        break;
                }
                
                if (!regionResources.allResources.contains(resource->id))
                    regionResources.allResources.insert(resource->id, resource);
                
                regionResources.repositoryResources.insert(resource->id, resource);
            }
            
            if (region.superregion && hasSrtm && region.superregion.superregion != app.worldRegion)
            {
                if (![region.superregion.resourceTypes containsObject:[NSNumber numberWithInt:(int)OsmAndResourceType::SrtmMapRegion]])
                {
                    region.superregion.resourceTypes = [region.superregion.resourceTypes arrayByAddingObject:[NSNumber numberWithInt:(int)OsmAndResourceType::SrtmMapRegion]];
                    region.superregion.resourceTypes = [region.superregion.resourceTypes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2) {
                        if ([num2 intValue] > [num1 intValue])
                            return NSOrderedAscending;
                        else if ([num2 intValue] < [num1 intValue])
                            return NSOrderedDescending;
                        else
                            return NSOrderedSame;
                    }];
                }
            }
            
            region.resourceTypes = [typesArray sortedArrayUsingComparator:^NSComparisonResult(NSNumber *num1, NSNumber *num2) {
                if ([num2 intValue] > [num1 intValue])
                    return NSOrderedAscending;
                else if ([num2 intValue] < [num1 intValue])
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
    
    for (OAWorldRegion* subregion in self.region.flattenedSubregions)
    {
        if (subregion.superregion == self.region)
        {
            if (subregion.subregions.count > 0)
                [_allSubregionItems addObject:subregion];
            else
                [self collectSubregionItems:subregion];
        }
    }
    
}

- (void) collectSubregionItems:(OAWorldRegion *) region
{
    const auto citRegionResources = _resourcesByRegions.constFind(region);
    if (citRegionResources == _resourcesByRegions.cend())
        return;
    const auto& regionResources = *citRegionResources;
    
    NSMutableArray *regionMapArray = [NSMutableArray array];
    NSMutableArray *allResourcesArray = [NSMutableArray array];
    
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
                item.resourceType = resource->type;
                item.title = [self.class titleOfResource:resource_
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
            }
            else
            {
                LocalResourceItem* item = [[LocalResourceItem alloc] init];
                item_ = item;
                item.resourceId = resource->id;
                item.resourceType = resource->type;
                item.title = [self.class titleOfResource:resource_
                                                inRegion:region
                                          withRegionName:YES
                                        withResourceType:NO];
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
            item.resourceType = resource->type;
            item.title = [self.class titleOfResource:resource_
                                            inRegion:region
                                      withRegionName:YES
                                    withResourceType:NO];
            item.resource = resource;
            item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
            item.size = resource->size;
            item.sizePkg = resource->packageSize;
            item.worldRegion = region;

            if (item.title == nil)
                continue;
            
            if (region != self.region && _srtmDisabled)
            {
                if (_hasSrtm && resource->type == OsmAndResourceType::SrtmMapRegion)
                    continue;
                
                if (resource->type == OsmAndResourceType::SrtmMapRegion)
                {
                    item.title = OALocalizedString(@"srtm_disabled");
                    item.size = 0;
                    item.sizePkg = 0;
                }
                
                if (!_hasSrtm && resource->type == OsmAndResourceType::SrtmMapRegion)
                    _hasSrtm = YES;
            }
        }
        
        if (region == self.region)
            [regionMapArray addObject:item_];
        else
            [allResourcesArray addObject:item_];
        
    }
    
    [_regionMapItems addObjectsFromArray:regionMapArray];
    
    if (allResourcesArray.count > 1)
        [_allSubregionItems addObject:region];
    else
        [_allResourceItems addObjectsFromArray:allResourcesArray];
}

- (void)collectResourcesDataAndItems
{
    [self collectSubregionItems:self.region];
    
    [_allResourceItems addObjectsFromArray:_allSubregionItems];
    [_allResourceItems sortUsingComparator:self.resourceItemsComparator];
    [_regionMapItems sortUsingComparator:self.resourceItemsComparator];
    
    // Map Creator sqlitedb files
    [_localSqliteItems removeAllObjects];
    NSString *sqliteFilesPath = [[OAMapCreatorHelper sharedInstance] filesDir];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files)
    {
        SqliteDbResourceItem *item = [[SqliteDbResourceItem alloc] init];
        item.title = [[fileName stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        item.fileName = fileName;
        item.path = [sqliteFilesPath stringByAppendingPathComponent:fileName];
        item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
        [_localSqliteItems addObject:item];
    }
    
    [_localSqliteItems sortUsingComparator:^NSComparisonResult(SqliteDbResourceItem *obj1, SqliteDbResourceItem *obj2) {
        return [obj1.title caseInsensitiveCompare:obj2.title];
    }];
    
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
        item.resourceType = resource->type;
        item.title = [self.class titleOfResource:resource
                                  inRegion:match
                            withRegionName:YES
                          withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;

        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.size = resourceInRepository->size;
        item.sizePkg = resourceInRepository->packageSize;
        
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
        //NSLog(@"=== %@", resource->id.toNSString());
        
        OAWorldRegion* match = [OAManageResourcesViewController findRegionOrAnySubregionOf:self.region
                                                                      thatContainsResource:resource->id];
        
        if (!match && (resource->type != OsmAndResourceType::MapRegion))
            continue;
        
        LocalResourceItem* item = [[LocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        if (match)
            item.title = [self.class titleOfResource:resource
                                        inRegion:match
                                  withRegionName:YES
                                withResourceType:NO];
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
    
    if (![_iapHelper.nautical isActive])
    {
        for (ResourceItem *item in _regionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksKey)) == 0)
            {
                [_regionMapItems removeObject:item];
                break;
            }
        for (ResourceItem *item in _regionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksOldKey)) == 0)
            {
                [_regionMapItems removeObject:item];
                break;
            }
        for (ResourceItem *item in _localRegionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksKey)) == 0)
            {
                [_localRegionMapItems removeObject:item];
                break;
            }
        for (ResourceItem *item in _localRegionMapItems)
            if (item.resourceId.compare(QString(kWorldSeamarksOldKey)) == 0)
            {
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

- (void) prepareContent
{
    @synchronized(_dataLock)
    {
        _lastUnusedSectionIndex = 0;
        _osmAndLiveSection = -1;
        _regionMapSection = -1;
        _bannerSection = -1;
        _subscribeEmailSection = -1;
        _outdatedResourcesSection = -1;
        _localResourcesSection = -1;
        _resourcesSection = -1;
        _localSqliteSection = -1;
        
        if (_displayBanner)
            _bannerSection = _lastUnusedSectionIndex++;
        
        _freeMemorySection = _lastUnusedSectionIndex++;
        if (_displaySubscribeEmailView)
            _subscribeEmailSection = _lastUnusedSectionIndex++;

        // Updates always go first
        if (_currentScope == kAllResourcesScope && [_outdatedResourceItems count] > 0 && self.region == _app.worldRegion)
            _outdatedResourcesSection = _lastUnusedSectionIndex++;
        
        if (_currentScope == kAllResourcesScope && self.region == _app.worldRegion)
            _osmAndLiveSection = _lastUnusedSectionIndex++;

        if (_currentScope == kAllResourcesScope && ([_localResourceItems count] > 0 || [_localRegionMapItems count] > 0 || _localSqliteItems.count > 0) && self.region == _app.worldRegion)
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
        
        if (_localSqliteItems.count > 0)
            _localSqliteSection = _lastUnusedSectionIndex++;
        
        // Configure search scope
        self.searchDisplayController.searchBar.scopeButtonTitles = nil;
        self.searchDisplayController.searchBar.placeholder = OALocalizedString(@"res_search_world");
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
            return;
        }

        NSMutableArray *resourceItems = [self getResourceItems];
        for (int i = 0; i < resourceItems.count; i++) {
            if ([resourceItems[i] isKindOfClass:[OAWorldRegion class]])
                continue;
            ResourceItem *item = resourceItems[i];
            if ([[item.downloadTask key] isEqualToString:downloadTaskKey]) {
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_resourcesSection]];
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

- (NSString *)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
              withRegionName:(BOOL)includeRegionName
{
    return [self.class titleOfResource:resource
                        inRegion:self.region
                  withRegionName:includeRegionName
                withResourceType:NO];
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
        NSPredicate* startsWith = [NSPredicate predicateWithFormat:@"(ANY resourceTypes == 0) AND name BEGINSWITH[cd] %@", searchString];
        NSMutableArray *regions_startsWith = [[searchableContent filteredArrayUsingPredicate:startsWith] mutableCopy];
        if ([regions_startsWith count] == 0)
        {
            NSPredicate* anyStartsWith = [NSPredicate predicateWithFormat:@"ANY allNames BEGINSWITH[cd] %@", searchString];
            [regions_startsWith addObjectsFromArray:[searchableContent filteredArrayUsingPredicate:anyStartsWith]];
        }
        [regions_startsWith sortUsingComparator:regionComparator];

        // Regions that only contain given string have less priority
        NSPredicate* onlyContains = [NSPredicate predicateWithFormat:
                                     @"(ANY resourceTypes == 0) AND (name CONTAINS[cd] %@) AND NOT (name BEGINSWITH[cd] %@)",
                                     searchString,
                                     searchString];
        NSMutableArray *regions_onlyContains = [[searchableContent filteredArrayUsingPredicate:onlyContains] mutableCopy];
        if ([regions_onlyContains count] == 0)
        {
            NSPredicate* anyOnlyContains = [NSPredicate predicateWithFormat:
                                            @"(ANY resourceTypes == 0) AND (ANY allNames CONTAINS[cd] %@) AND NOT (ANY allNames BEGINSWITH[cd] %@)",
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
                        item.resourceType = resource->type;
                        item.title = [self.class titleOfResource:resource_
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
                        LocalResourceItem* item = [[LocalResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [self.class titleOfResource:resource_
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
                    RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.title = [self.class titleOfResource:resource_
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

- (void)showNoInternetAlertForCatalogUpdate
{
    [[OARootViewController instance] showNoInternetAlertFor:OALocalizedString(@"res_catalog_upd")];
}

- (void)updateRepository
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

- (UITableView *)getTableView
{
    return self.tableView;
}

- (void)showDetailsOf:(LocalResourceItem*)item
{
    [self performSegueWithIdentifier:kOpenDetailsSegue sender:item];
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
        return _bannerView;

    if (section == _freeMemorySection)
        return _freeMemoryView;

    if (section == _subscribeEmailSection)
        return _subscribeEmailView;

    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
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
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 1;

    if (_currentScope == kLocalResourcesScope)
        return ([_localResourceItems count] > 0 ? 1 : 0) + ([_localRegionMapItems count] > 0 ? 1 : 0) + (_localSqliteItems.count > 0 ? 1 : 0) + 1;

    NSInteger sectionsCount = 0;

    if (_bannerSection >= 0)
        sectionsCount++;
    if (_freeMemorySection >= 0)
        sectionsCount++;
    if (_osmAndLiveSection >= 0)
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
    if (section == _freeMemorySection)
        return 0;
    if (section == _outdatedResourcesSection)
        return 1;
    if (section == _osmAndLiveSection)
        return 1;
    if (section == _resourcesSection)
        return [[self getResourceItems] count];
    if (section == _localResourcesSection)
        return 1;
    if (section == _regionMapSection)
        return [[self getRegionMapItems] count];
    if (section == _localSqliteSection)
        return _localSqliteItems.count;

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;

    if (self.region.superregion == nil)
    {
        if (_currentScope == kLocalResourcesScope)
        {
            if (section == _regionMapSection)
                return OALocalizedString(@"res_world_map");
            else if (section == _localSqliteSection)
                return OALocalizedString(@"map_creator");
            else
                return OALocalizedString(@"res_mapsres");
        }
        
        if (section == _outdatedResourcesSection)
            return OALocalizedString(@"res_updates");
        if (section == _osmAndLiveSection)
            return OALocalizedString(@"osmand_live_title");
        if (section == _resourcesSection)
            return OALocalizedString(@"res_worldwide");
        if (section == _localResourcesSection)
            return OALocalizedString(@"res_installed");
        if (section == _regionMapSection)
            return OALocalizedString(@"res_world_map");
        
        return nil;
    }

    if (section == _outdatedResourcesSection)
        return OALocalizedString(@"res_updates");
    if (section == _osmAndLiveSection)
        return OALocalizedString(@"osmand_live_title");
    if (section == _resourcesSection)
        return OALocalizedString(@"res_mapsres");
    if (section == _localResourcesSection)
        return OALocalizedString(@"res_installed");
    if (section == _regionMapSection)
        return OALocalizedString(@"res_region_map");

    return nil;
}

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
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

- (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView
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

/*
 -(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}
*/

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const subregionCell = @"subregionCell";
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const osmAndLiveCell = @"osmAndLiveCell";
    static NSString* const localResourceCell = @"localResourceCell";
    static NSString* const repositoryResourceCell = @"repositoryResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";
    static NSString* const outdatedResourcesSubmenuCell = @"outdatedResourcesSubmenuCell";
    static NSString* const installedResourcesSubmenuCell = @"installedResourcesSubmenuCell";

    NSString* cellTypeId = nil;
    NSString* title = nil;
    NSString* subtitle = nil;
    BOOL disabled = NO;
    
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
            title = OALocalizedString(@"res_updates_avail");

            NSArray* regionsNames = [_regionsWithOutdatedResources valueForKey:NSStringFromSelector(@selector(name))];
            subtitle = [_arrFmt stringFromArray:regionsNames];
        }
        else if (indexPath.section == _localResourcesSection && _localResourcesSection >= 0)
        {
            cellTypeId = installedResourcesSubmenuCell;
            title = OALocalizedString(@"res_installed");
            
            subtitle = [NSString stringWithFormat:@"%d %@ - %@", (int)(_localResourceItems.count + _localRegionMapItems.count + _localSqliteItems.count), OALocalizedString(@"res_maps_inst"), [NSByteCountFormatter stringFromByteCount:_totalInstalledSize countStyle:NSByteCountFormatterCountStyleFile]];
        }
        else if (indexPath.section == _osmAndLiveSection)
        {
            cellTypeId = osmAndLiveCell;
            title = OALocalizedString(@"osmand_live_title");
            
//            subtitle = [NSString stringWithFormat:@"%d %@ - %@", (int)(_localResourceItems.count + _localRegionMapItems.count + _localSqliteItems.count), OALocalizedString(@"res_maps_inst"), [NSByteCountFormatter stringFromByteCount:_totalInstalledSize countStyle:NSByteCountFormatterCountStyleFile]];
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
                {
                    if (item.resourceTypes.count > 0)
                    {
                        NSMutableString *str = [NSMutableString string];
                        for (NSNumber *typeNum in item.resourceTypes)
                        {
                            if (str.length > 0)
                                [str appendString:@", "];
                            [str appendString:[OAResourcesBaseViewController resourceTypeLocalized:(OsmAndResourceType)[typeNum intValue]]];
                        }
                        subtitle = str;
                    }
                    else
                    {
                        subtitle = item.superregion.name;
                    }
                }
            }
            else
            {
                ResourceItem* item = (ResourceItem*)item_;
                uint64_t _sizePkg = item.sizePkg;
                
                if (item.downloadTask != nil)
                    cellTypeId = downloadingResourceCell;
                else if ([item isKindOfClass:[OutdatedResourceItem class]])
                    cellTypeId = outdatedResourceCell;
                else if ([item isKindOfClass:[LocalResourceItem class]])
                {
                    cellTypeId = localResourceCell;
                    _sizePkg = item.size;
                }
                else if ([item isKindOfClass:[RepositoryResourceItem class]]) {
                    cellTypeId = repositoryResourceCell;
                }
                
                BOOL mapDownloaded = NO;
                for (ResourceItem* it in [self getRegionMapItems])
                {
                    if (it.resourceType == OsmAndResourceType::MapRegion && ([it isKindOfClass:[LocalResourceItem class]] || [it isKindOfClass:[OutdatedResourceItem class]]))
                    {
                        mapDownloaded = YES;
                        break;
                    }
                }
                
                if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion)
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
                    NSString *countryName = [self.class getCountryName:item];
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
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourcesBaseViewController resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
                else
                    subtitle = [NSString stringWithFormat:@"%@", [OAResourcesBaseViewController resourceTypeLocalized:item.resourceType]];
            }
        }
        else if (indexPath.section == _regionMapSection && _regionMapSection >= 0)
        {
            item_ = [[self getRegionMapItems] objectAtIndex:indexPath.row];

            ResourceItem* item = (ResourceItem*)item_;
            uint64_t _sizePkg = item.sizePkg;
            
            if (item.downloadTask != nil)
                cellTypeId = downloadingResourceCell;
            else if ([item isKindOfClass:[OutdatedResourceItem class]])
                cellTypeId = outdatedResourceCell;
            else if ([item isKindOfClass:[LocalResourceItem class]])
            {
                cellTypeId = localResourceCell;
                _sizePkg = item.size;
            }
            else if ([item isKindOfClass:[RepositoryResourceItem class]])
                cellTypeId = repositoryResourceCell;
            
            BOOL mapDownloaded = NO;
            for (ResourceItem* it in [self getRegionMapItems])
            {
                if (it.resourceType == OsmAndResourceType::MapRegion && ([it isKindOfClass:[LocalResourceItem class]] || [it isKindOfClass:[OutdatedResourceItem class]]))
                {
                    mapDownloaded = YES;
                    break;
                }
            }
            
            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion)
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
                NSString *countryName = [self.class getCountryName:item];
                if (countryName)
                    title = [NSString stringWithFormat:@"%@ - %@", countryName, item.title];
                else
                    title = item.title;
                
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourcesBaseViewController resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

            }
            else if (self.region != _app.worldRegion)
            {
                title = [OAResourcesBaseViewController resourceTypeLocalized:item.resourceType];

                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
            }
            else
            {
                title = item.title;
                
                if (_sizePkg > 0)
                    subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourcesBaseViewController resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
            }
        }
        else if (indexPath.section == _localSqliteSection)
        {
            SqliteDbResourceItem *item = [_localSqliteItems objectAtIndex:indexPath.row];
            cellTypeId = localResourceCell;
            
            title = item.title;
            subtitle = [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile];
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
            cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);
            
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_update_icon.png"];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            btnAcc.frame = CGRectMake(0.0, 0.0, 60.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];

            cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:17.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12.0];
            cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

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
        [_updateCouneView setText:[NSString stringWithFormat:@"%d", (int)_outdatedResourceItems.count]];
        cell.accessoryView = _updateCouneView;
    }

    // Fill cell content
    
    if ([cellTypeId isEqualToString:repositoryResourceCell])
    {
        if (!disabled)
        {
            cell.textLabel.textColor = [UIColor blackColor];
            UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
            UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
            [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
            [btnAcc setImage:iconImage forState:UIControlStateNormal];
            btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
            [cell setAccessoryView:btnAcc];
        }
        else
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
                
            if (self.region && [self.region isInPurchasedArea])
            {
                UILabel *labelGet = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 100.0)];
                labelGet.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13];
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
        } else {
            for (UIView *view in cell.contentView.subviews)
                if (view.tag == -1) {
                    [view removeFromSuperview];
                    break;
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

- (void) accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (!indexPath)
        return;
    
    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

#pragma mark - UITableViewDelegate

-(id)getItemByIndexPath:(NSIndexPath *)indexPath
{
    id item;
    if (indexPath.section == _resourcesSection)
        item = [[self getResourceItems] objectAtIndex:indexPath.row];
    else if (indexPath.section == _regionMapSection)
        item = [[self getRegionMapItems] objectAtIndex:indexPath.row];
    else if (indexPath.section == _localSqliteSection)
        item = [_localSqliteItems objectAtIndex:indexPath.row];
    
    return item;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
        item = [self getItemByIndexPath:indexPath];

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (_searchResults.count > 0)
            item = [_searchResults objectAtIndex:indexPath.row];
    }
    else if (tableView == self.tableView)
    {
        item = [self getItemByIndexPath:indexPath];
    }

    if (item)
    {
        if ([item isKindOfClass:[OutdatedResourceItem class]])
        {
            if (((OutdatedResourceItem *)item).downloadTask != nil)
                [self onItemClicked:item];
            else
                [self showDetailsOf:item];
        }
        else if (![item isKindOfClass:[LocalResourceItem class]])
        {
            [self onItemClicked:item];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        item = [_searchResults objectAtIndex:indexPath.row];
    else if (tableView == self.tableView)
        item = [self getItemByIndexPath:indexPath];

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
        item = [self getItemByIndexPath:indexPath];

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
        item = [self getItemByIndexPath:indexPath];

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

    CGFloat h = self.view.bounds.size.height - 50.0 - 61.0;
    if (self.downloadView && self.downloadView.superview)
        h -= self.downloadView.bounds.size.height;

    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.titlePanelView.frame = CGRectMake(0.0, 0.0, self.titlePanelView.frame.size.width, self.titlePanelView.frame.size.height);
                         self.toolbarView.frame = CGRectMake(0.0, self.view.frame.size.height - self.toolbarView.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
                         self.tableView.frame = CGRectMake(0.0, 64.0, self.view.bounds.size.width, h);
                         [self applySafeAreaMargins];

                     } completion:^(BOOL finished) {
                         self.titlePanelView.userInteractionEnabled = YES;
                         if (_displayBanner)
                             [self.tableView reloadData];
                     }];
    
    if (self.openFromSplash && _app.resourcesManager->isRepositoryAvailable())
    {
        int showMapIterator = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kShowMapIterator];
        if (showMapIterator == 0)
        {
            [[NSUserDefaults standardUserDefaults] setInteger:++showMapIterator forKey:kShowMapIterator];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *key = [@"resource:" stringByAppendingString:_app.resourcesManager->getResourceInRepository(kWorldBasemapKey)->id.toNSString()];
            BOOL _isWorldMapDownloading = [_app.downloadsManager.keysOfDownloadTasks containsObject:key];
            
            const auto worldMap = _app.resourcesManager->getLocalResource(kWorldBasemapKey);
            if (!worldMap && !_isWorldMapDownloading)
                [OAPluginPopupViewController askForWorldMap];
        }
    }
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
    if ([segue.identifier isEqualToString:kOpenDetailsSegue] && [sender isKindOfClass:[LocalResourceItem class]])
    {
        OALocalResourceInformationViewController* resourceInfoViewController = [segue destinationViewController];
        resourceInfoViewController.openFromSplash = _openFromSplash;
        resourceInfoViewController.baseController = self;
        
        LocalResourceItem* item = sender;
        if (item)
        {
            if (item.worldRegion)
                resourceInfoViewController.regionTitle = item.worldRegion.name;
            else if (self.region.name)
                resourceInfoViewController.regionTitle = self.region.name;
            else
                resourceInfoViewController.regionTitle = item.title;
            
            if ([item isKindOfClass:[SqliteDbResourceItem class]])
            {
                [resourceInfoViewController initWithLocalSqliteDbItem:(SqliteDbResourceItem *)item];
                return;
            }
            else
            {
                NSString* resourceId = item.resourceId.toNSString();
                [resourceInfoViewController initWithLocalResourceId:resourceId];
            }
        }
        
        resourceInfoViewController.localItem = item;
        return;
    }

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
    else if ([segue.identifier isEqualToString:kOpenOsmAndLiveSegue])
    {
        OAOsmAndLiveViewController* osmandLiveViewController = [segue destinationViewController];
        [osmandLiveViewController setLocalResources:_localResourceItems];
    }
    else if ([segue.identifier isEqualToString:kOpenDetailsSegue])
    {
        OALocalResourceInformationViewController* resourceInfoViewController = [segue destinationViewController];
        resourceInfoViewController.openFromSplash = _openFromSplash;
        resourceInfoViewController.baseController = self;
        
        LocalResourceItem* item = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView)
        {
            item = [_searchResults objectAtIndex:cellPath.row];
        }
        else if (tableView == self.tableView)
        {
            if (cellPath.section == _resourcesSection && _resourcesSection >= 0)
                item = [[self getResourceItems] objectAtIndex:cellPath.row];
            if (cellPath.section == _regionMapSection && _regionMapSection >= 0)
                item = [[self getRegionMapItems] objectAtIndex:cellPath.row];
            if (cellPath.section == _localSqliteSection)
                item = [_localSqliteItems objectAtIndex:cellPath.row];
        }

        if (item)
        {
            if (item.worldRegion)
                resourceInfoViewController.regionTitle = item.worldRegion.name;
            else if (self.region.name)
                resourceInfoViewController.regionTitle = self.region.name;
            else
                resourceInfoViewController.regionTitle = item.title;
            
            if ([item isKindOfClass:[SqliteDbResourceItem class]])
            {
                [resourceInfoViewController initWithLocalSqliteDbItem:(SqliteDbResourceItem *)item];
                return;
            }
            else
            {
                NSString* resourceId = item.resourceId.toNSString();
                [resourceInfoViewController initWithLocalResourceId:resourceId];
            }
        }
        
        resourceInfoViewController.localItem = item;

    }
}

#pragma mark -

- (IBAction)btnToolbarMapsClicked:(id)sender
{
}

- (IBAction)btnToolbarPluginsClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"plugins_open"];

    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
    pluginsViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:pluginsViewController animated:NO];
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"purchases_open"];

    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:purchasesViewController animated:NO];
}

- (void) doSubscribe:(NSString *)email
{
    [_refreshRepositoryProgressHUD show:YES];
    NSDictionary<NSString *, NSString *> *params = @{ @"os" : @"ios", @"email" : email };
    [OANetworkUtilities sendRequestWithUrl:@"https://osmand.net/subscription/register" params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             BOOL error = YES;
             if (response)
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
                             [OAAppSettings sharedManager].emailSubscribed = YES;
                             
                             if (_displaySubscribeEmailView)
                             {
                                 _displaySubscribeEmailView = NO;
                                 [self updateContent];
                             }

                             error = NO;
                             [OAFirebaseHelper logEvent:@"subscribed_by_email"];
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
    [OAFirebaseHelper logEvent:@"subscribe_email_pressed"];

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"shared_string_email_address") message:nil delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_ok"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSString* email = [alertView textFieldAtIndex:0].text;
        if (email.length == 0 || ![email isValidEmail])
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"osm_live_enter_email") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [self doSubscribe:email];
        }
    }
}

#pragma mark OABannerViewDelegate

- (void) bannerButtonPressed
{
    [OAFirebaseHelper logEvent:@"subscribe_email_pressed"];

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
        {
            [_refreshRepositoryProgressHUD show:YES];
            [_iapHelper buyProduct:product];
        }
    }
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_refreshRepositoryProgressHUD hide:YES];
        
        if (_currentScope == kLocalResourcesScope ||
            (self.region == _app.worldRegion && [_iapHelper isAnyMapPurchased]) ||
            (self.region != _app.worldRegion && [self.region isInPurchasedArea]))
        {
            if (_displayBanner)
            {
                _displayBanner = NO;
                [self updateContent];
            }
        }
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshRepositoryProgressHUD hide:YES];
    });
}

@end
