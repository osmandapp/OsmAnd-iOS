//
//  OAPluginsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPluginsViewController.h"
#import "OAIAPHelper.h"
#import "OAInAppCell.h"
#import "OAResourcesBaseViewController.h"
#include "Localization.h"
#import "OAPluginDetailsViewController.h"
#import "OAPluginPopupViewController.h"
#import "OASizes.h"
#import "OASubscriptionBannerCardView.h"
#import "OAChoosePlanHelper.h"
#import "OARootViewController.h"
#import "OAQuickActionRegistry.h"
#import "OAPlugin.h"
#import "OACustomPlugin.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"

#define kDefaultPluginsSection 0
#define kCustomPluginsSection 1

@interface OAPluginsViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, OASubscriptionBannerCardViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAPluginsViewController
{
    OAIAPHelper *_iapHelper;
    OASubscriptionBannerCardView *_subscriptionBannerView;

    NSArray<OACustomPlugin *> *_customPlugins;
    
    OAAutoObserverProxy *_addonsSwitchObserver;
    
    CALayer *_horizontalLine;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"plugins_menu_group");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _iapHelper = [OAIAPHelper sharedInstance];
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

- (CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];
    
    _addonsSwitchObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                       andObserve:OsmAndApp.instance.addonsSwitchObservable];

    _customPlugins = [OAPlugin getCustomPlugins];
    [[OARootViewController instance] requestProductsWithProgress:NO reload:NO];

    [self setupSubscriptionBanner];

    [self applySafeAreaMargins];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_addonsSwitchObserver detach];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupSubscriptionBanner];
    } completion:nil];
}

- (void) onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
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

-(void) addAccessibilityLabels
{
    self.backButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _customPlugins.count > 0 ? 2 : 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kDefaultPluginsSection)
        return _iapHelper.inAppAddons.count;
    else if (section == kCustomPluginsSection)
        return _customPlugins.count;
    return 0;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kCustomPluginsSection)
        return OALocalizedString(@"custom_plugins");
    return @"";
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAInAppCell* cell;
    cell = (OAInAppCell *)[tableView dequeueReusableCellWithIdentifier:[OAInAppCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInAppCell getCellIdentifier] owner:self options:nil];
        cell = (OAInAppCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [UIView performWithoutAnimation:^{
            [cell.btnPrice removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            cell.btnPrice.tag = indexPath.section << 10 | indexPath.row;;
            [cell.btnPrice addTarget:self action:@selector(buttonPurchaseClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            BOOL purchased = NO;
            BOOL disabled = YES;
            
            UIImage *imgTitle = nil;
            cell.imgIconBackground.hidden = NO;
            
            NSString *title = nil;
            NSString *desc = nil;
            NSString *price = nil;
            
            if (indexPath.section == kDefaultPluginsSection)
            {
                OAProduct *product = _iapHelper.inAppAddons[indexPath.row];

                purchased = [product isPurchased];
                disabled = product.disabled;

                imgTitle = [UIImage templateImageNamed:[product productIconName]];

                title = product.localizedTitle;
                desc = product.localizedDescription;
                if (!product.free)
                    price = [OALocalizedString(@"buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
            }
            else if (indexPath.section == kCustomPluginsSection)
            {
                OACustomPlugin *plugin = _customPlugins[indexPath.row];
                purchased = YES;
                disabled = ![plugin isEnabled];
                
                imgTitle = plugin.getLogoResource;
                
                title = plugin.getName;
                desc = plugin.getDescription;
            }
             
            cell.imgIcon.contentMode = UIViewContentModeCenter;
            if (!imgTitle)
                imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
            else if (indexPath.section == kCustomPluginsSection)
                cell.imgIcon.contentMode = UIViewContentModeScaleAspectFit;
            
            [cell.imgIcon setImage:imgTitle];
            cell.imgIcon.tintColor = UIColorFromRGB(plugin_icon_green);
            [cell.lbTitle setText:title];
            [cell.lbDescription setText:desc];
            [cell.btnPrice setTitle:price forState:UIControlStateNormal];
            
            [cell setPurchased:purchased disabled:disabled];
            [cell.btnPrice layoutIfNeeded];
        }];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OAPluginDetailsViewController *pluginDetails = nil;
    if (indexPath.section == kDefaultPluginsSection)
    {
        OAProduct *product = _iapHelper.inAppAddons[indexPath.row];
        if (product)
            pluginDetails = [[OAPluginDetailsViewController alloc] initWithProduct:product];
    }
    else if (indexPath.section == kCustomPluginsSection)
    {
        OACustomPlugin *plugin = _customPlugins[indexPath.row];
        if (plugin)
            pluginDetails = [[OAPluginDetailsViewController alloc] initWithCustomPlugin:plugin];
    }
    [self.navigationController pushViewController:pluginDetails animated:YES];
}

- (void)refreshProduct:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [OAQuickActionRegistry.sharedInstance updateActionTypes];
        [OAQuickActionRegistry.sharedInstance.quickActionListChangedObservable notifyEvent];
    });
}

- (IBAction) buttonPurchaseClicked:(id)sender
{
    UIButton *btn = sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btn.tag & 0x3FF inSection:btn.tag >> 10];
    
    if (indexPath.section == kDefaultPluginsSection)
    {
        OAProduct *product = _iapHelper.inAppAddons[indexPath.row];
        
        BOOL purchased = [product isPurchased];
        BOOL disabled = product.disabled;
        
        if (purchased)
        {
            if (disabled)
            {
                [_iapHelper enableProduct:product.productIdentifier];
                OAPlugin *plugin = [OAPlugin getPluginById:product.productIdentifier];
                [plugin showInstalledScreen];
                [OAPluginPopupViewController showProductAlert:product afterPurchase:NO];
            }
            else
            {
                [_iapHelper disableProduct:product.productIdentifier];
            }
            
            [self refreshProduct:indexPath];
            return;
        }
        //    [[OARootViewController instance] buyProduct:product showProgress:YES];
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:self.navigationController];
    }
    else if (indexPath.section == kCustomPluginsSection)
    {
        OACustomPlugin *plugin = _customPlugins[indexPath.row];
        [OAPlugin enablePlugin:plugin enable:![plugin isEnabled]];
        [self refreshProduct:indexPath];
        [OAResourcesBaseViewController setDataInvalidated];
    }
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    NSString * identifier = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubscriptionBanner];
        [self.tableView reloadData];

        OAProduct *product = [_iapHelper product:identifier];
        if (product)
            [OAPluginPopupViewController showProductAlert:product afterPurchase:YES];
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

- (void) onLeftNavbarButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void) onButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
}

@end
