//
//  OAOutdatedResourcesViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOutdatedResourcesViewController.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <UIAlertView+Blocks.h>
#import "Localization.h"
#import "OAColors.h"
#import "OASubscriptionBannerCardView.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"
#import "OAWeatherForecastViewController.h"
#import "OAPluginPopupViewController.h"

#define kRowsInUpdatesSection 2

#define kOpenLiveUpdatesSegue @"openLiveUpdatesSegue"

@interface OAOutdatedResourcesViewController () <UITableViewDelegate, UITableViewDataSource, OASubscriptionBannerCardViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *updateAllButton;

@end

@implementation OAOutdatedResourcesViewController
{
    OsmAndAppInstance _app;
    NSObject* _dataLock;

    NSInteger _updatesSection;
    NSInteger _availableMapsSection;
    NSInteger _liveUpdatesRow;
    NSInteger _weatherForecastsRow;

    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
    NSMutableArray* _resourcesItems;

    CALayer *_horizontalLine;
    OASubscriptionBannerCardView *_subscriptionBannerView;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];
        _resourcesItems = [NSMutableArray array];
        self.region = _app.worldRegion;

        _dataLock = [[NSObject alloc] init];
    }
    return self;
}

-(void)applyLocalization
{
    [super applyLocalization];
    
    _titleView.text = OALocalizedString(@"download_tab_updates");
    [_updateAllButton setTitle:OALocalizedString(@"res_update_all") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem* refreshAllBarButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"res_update_all")
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(onUpdateAllBarButtonClicked)];
    self.navigationItem.rightBarButtonItem = refreshAllBarButton;
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];

    [self setupSubscriptionBanner];
    [self updateContent];
    [self prepareContent];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupSubscriptionBanner];
    } completion:nil];
}

- (void)prepareContent
{
    @synchronized (_dataLock)
    {
        _updatesSection = 0;
        _availableMapsSection = 1;
        _liveUpdatesRow = 0;
        _weatherForecastsRow = 1;
    }
}

- (void)setupSubscriptionBanner
{
    BOOL isPaid = [OAIAPHelper isPaidVersion];
    if (!isPaid && !_subscriptionBannerView)
    {
        _subscriptionBannerView = [[OASubscriptionBannerCardView alloc] initWithType:EOASubscriptionBannerUpdates];
        _subscriptionBannerView.delegate = self;
    }
    else if (isPaid)
    {
        _subscriptionBannerView = nil;
    }

    if (_subscriptionBannerView)
        [_subscriptionBannerView updateView];

    self.tableView.tableHeaderView = _subscriptionBannerView ? _subscriptionBannerView : [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (UITableView *)getTableView
{
    return self.tableView;
}

- (void)updateContent
{
    [self obtainDataAndItems];
    [self refreshContent:YES];
}

- (void)refreshContent:(BOOL)update;
{
    @synchronized(_dataLock)
    {
        [self.tableView reloadData];
    }
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        [self prepareData];
        [self collectResourcesDataAndItems];
    }
}

- (void)prepareData
{
    // Obtain all resources separately

    // IOS-199
    _outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
}

- (void)collectResourcesDataAndItems
{
    [_resourcesItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:resource->id];
        if (!match)
            continue;

        OAOutdatedResourceItem* item = [[OAOutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:match
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;
        item.resourceType = resource->type;

        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.size = resourceInRepository->size;
        item.sizePkg = resourceInRepository->packageSize;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];

        if (item.title == nil)
            continue;

        [_resourcesItems addObject:item];
    }
    [_resourcesItems sortUsingComparator:self.resourceItemsComparator];
}

- (void)offerDownloadAndUpdateMultiple:(NSArray*)items
{
    uint64_t totalDownloadSize = 0;
    uint64_t totalSpaceNeeded = 0;
    for (OAOutdatedResourceItem* item in items)
    {
        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);

        totalDownloadSize += resourceInRepository->packageSize;
        totalSpaceNeeded += resourceInRepository->packageSize + resourceInRepository->size;
    }

    if (_app.freeSpaceAvailableOnDevice < totalSpaceNeeded)
    {
        NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalSpaceNeeded
                                                                   countStyle:NSByteCountFormatterCountStyleFile];

        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:OALocalizedString(@"res_updates_no_space"),
                                                              [items count],
                                                              stringifiedSize]
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_ok")]
                           otherButtonItems:nil] show];
        return;
    }

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalDownloadSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSMutableString* message  = [[NSString stringWithFormat:@"%d %@",
                                  [items count],
                                  OALocalizedString(@"res_updates_avail_q")] mutableCopy];
    
    if (AFNetworkReachabilityManager.sharedManager.isReachableViaWWAN)
    {
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"res_update_all")
                                                             action:^{
                                                                 for (OAOutdatedResourceItem* item in items)
                                                                 {
                                                                     const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
                                                                     
                                                                     NSString *resourceName = [OAResourcesUIHelper titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];

                                                                     [self startDownloadOf:resourceInRepository resourceName:resourceName];
                                                                 }
                                                             }], nil] show];
}

- (IBAction)updateAllClicked:(id)sender
{
    [self onUpdateAllBarButtonClicked];
}

- (void)onUpdateAllBarButtonClicked
{
    NSMutableArray* resourcesToUpdate = [NSMutableArray array];
    BOOL needPurchaseAny = NO;
    @synchronized(_dataLock)
    {
        for (OAOutdatedResourceItem* item in _resourcesItems)
        {
            const auto repoRes = _app.resourcesManager->getResourceInRepository(item.resourceId);
            BOOL isFree = repoRes && repoRes->free;
            BOOL needPurchase = (item.worldRegion.regionId != nil && ![item.worldRegion isInPurchasedArea] && !isFree);
            if (!needPurchaseAny && needPurchase)
                needPurchaseAny = YES;
            
            if (item.downloadTask != nil || needPurchase)
                continue;

            [resourcesToUpdate addObject:item];
        }
    }
    if ([resourcesToUpdate count] == 0)
    {
        if (needPurchaseAny)
        {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"res_updates_exp") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
        }
        return;
    }

    if ([resourcesToUpdate count] == 1)
        [self offerDownloadAndUpdateOf:[resourcesToUpdate firstObject]];
    else
        [self offerDownloadAndUpdateMultiple:resourcesToUpdate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _updatesSection)
        return kRowsInUpdatesSection;
    else if (section == _availableMapsSection)
        return _resourcesItems.count;

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _availableMapsSection)
        return OALocalizedStringUp(@"res_updates_avail");

    return nil;
}

-(void)updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    OAResourceItem* item = (OAResourceItem*)[_resourcesItems objectAtIndex:indexPath.row];
    if (item.downloadTask == nil)
        return;
    
    if (cell.accessoryView && [cell.accessoryView isKindOfClass:FFCircularProgressView.class])
    {
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001 && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if ([progressView isSpinning])
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            progressView.progress = 0.;
            if (![progressView isSpinning])
                [progressView startSpinProgressBackgroundLayer];
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            [progressView setNeedsDisplay];
        }
    }
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";
    static NSString *const liveUpdatesCell = @"liveUpdatesCell";
    static NSString *const weatherForecastCell = @"weatherForecastCell";

    NSString* cellTypeId = nil;
    NSString* title = nil;
    OAResourceItem *item;

    if (indexPath.section == _updatesSection)
    {
        if (indexPath.row == _liveUpdatesRow)
        {
            cellTypeId = liveUpdatesCell;
            title = OALocalizedString(@"live_updates");
        }
        else if (indexPath.row == _weatherForecastsRow)
        {
            cellTypeId = weatherForecastCell;
            title = OALocalizedString(@"weather_forecast");
        }
    }
    else if (indexPath.section == _availableMapsSection && _resourcesItems.count > 0)
    {
        item = (OAResourceItem *) _resourcesItems[indexPath.row];

        if (item.downloadTask != nil)
            cellTypeId = downloadingResourceCell;
        else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
            cellTypeId = outdatedResourceCell;

        if (item.worldRegion && item.worldRegion.superregion)
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
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        
        if (indexPath.section == _updatesSection)
        {
            if ([cellTypeId isEqualToString:weatherForecastCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                            reuseIdentifier:cellTypeId];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        else if (indexPath.section == _availableMapsSection)
        {
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];

            if ([cellTypeId isEqualToString:outdatedResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];
                UIImage *iconImage = [UIImage templateImageNamed:@"ic_custom_download"];
                cell.accessoryView = [[UIImageView alloc] initWithImage:iconImage];
                [cell.accessoryView setTintColor:UIColorFromRGB(color_primary_purple)];
            }
            else if ([cellTypeId isEqualToString:downloadingResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];

                FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];
                progressView.tintColor = UIColorFromRGB(color_primary_purple);

                cell.accessoryView = progressView;
            }
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    if (cell && indexPath.section == _availableMapsSection && item)
    {
        cell.imageView.image = [OAResourceType getIcon:item.resourceType templated:YES];
        cell.imageView.tintColor = UIColorFromRGB(color_icon_inactive);
    }

    // Fill cell content
    cell.textLabel.text = title;
    if (cell.detailTextLabel)
    {
        if (indexPath.section == _updatesSection)
        {
            cell.detailTextLabel.text = nil;
        }
        else if (item)
        {
            if (item.sizePkg > 0)
            {
                NSString *date = [item getDate];
                NSString *dateDescription = date ? [NSString stringWithFormat:@"  •  %@", date] : @"";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  •  %@%@",
                        [OAResourceType resourceTypeLocalized:item.resourceType],
                        [NSByteCountFormatter stringFromByteCount:item.sizePkg
                                                       countStyle:NSByteCountFormatterCountStyleFile],
                        dateDescription];
            }
            else
            {
                cell.detailTextLabel.text = [OAResourceType resourceTypeLocalized:item.resourceType];
            }
            cell.detailTextLabel.textColor = UIColorFromRGB(color_text_footer);
        }
    }

    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        if (cell.accessoryView && [cell.accessoryView isKindOfClass:FFCircularProgressView.class])
        {
            FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
            
            float progressCompleted = item.downloadTask.progressCompleted;
            if (progressCompleted >= .001 && item.downloadTask.state == OADownloadTaskStateRunning)
            {
                progressView.iconPath = nil;
                if ([progressView isSpinning])
                    [progressView stopSpinProgressBackgroundLayer];
                progressView.progress = progressCompleted - .001;
            }
            else if (item.downloadTask.state == OADownloadTaskStateFinished)
            {
                progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                progressView.progress = 0.;
                if (![progressView isSpinning])
                    [progressView startSpinProgressBackgroundLayer];
            }
            else
            {
                progressView.iconPath = [UIBezierPath bezierPath];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];
                [progressView setNeedsDisplay];
            }
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == _updatesSection)
        return 35.;

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item = _resourcesItems[indexPath.row];

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _availableMapsSection)
    {
        id item = _resourcesItems[indexPath.row];

        if (item != nil)
            [self onItemClicked:item];
    }
    else if (indexPath.section == _updatesSection && indexPath.row == _weatherForecastsRow)
    {
        if (![[OAIAPHelper sharedInstance].weather isActive])
            [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Weather];
        else
            [self showViewController:[[OAWeatherForecastViewController alloc] init]];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized (_dataLock)
    {
        if (_resourcesItems.count > 0)
        {
            for (int i = 0; i < _resourcesItems.count; i++)
            {
                if ([_resourcesItems[i] isKindOfClass:[OAWorldRegion class]])
                    continue;

                OAResourceItem *item = _resourcesItems[i];
                if ([[item.downloadTask key] isEqualToString:downloadTaskKey] && _availableMapsSection > 0)
                {
                    [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_availableMapsSection]];
                    break;
                }
            }
        }
    }
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self.tableView reloadData];
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromBottom];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setFillMode:kCAFillModeBoth];
        [animation setDuration:.3];
        [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void) onButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
}

@end
