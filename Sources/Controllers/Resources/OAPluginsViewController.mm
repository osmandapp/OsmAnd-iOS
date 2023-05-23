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

@interface OAPluginsViewController () <UIAlertViewDelegate, OASubscriptionBannerCardViewDelegate>

@end

@implementation OAPluginsViewController
{
    OAIAPHelper *_iapHelper;
    OASubscriptionBannerCardView *_subscriptionBannerView;

    NSArray<OACustomPlugin *> *_customPlugins;
}

#pragma mark - Initialization

- (void)commonInit
{
    _iapHelper = [OAIAPHelper sharedInstance];
    _customPlugins = [OAPlugin getCustomPlugins];
}

- (void)registerNotifications
{
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
    [self addNotification:OAIAPProductsRequestSucceedNotification selector:@selector(productsRequested:)];
    [self addNotification:OAIAPProductsRestoredNotification selector:@selector(productRestored:)];
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                 andObserve:OsmAndApp.instance.addonsSwitchObservable]];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[OARootViewController instance] requestProductsWithProgress:NO reload:NO];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"plugins_menu_group");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (void)setupTableHeaderView
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

#pragma mark - Table data

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)sectionsCount
{
    return _customPlugins.count > 0 ? 2 : 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == kCustomPluginsSection)
        return OALocalizedString(@"custom_plugins");
    return @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kDefaultPluginsSection)
        return _iapHelper.inAppAddons.count;
    else if (section == kCustomPluginsSection)
        return _customPlugins.count;
    return 0;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAInAppCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInAppCell getCellIdentifier]];
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

- (void)onRowSelected:(NSIndexPath *)indexPath
{
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
    [self showViewController:pluginDetails];
}

#pragma mark - Additions

- (void)onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)refreshProduct:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [OAQuickActionRegistry.sharedInstance updateActionTypes];
        [OAQuickActionRegistry.sharedInstance.quickActionListChangedObservable notifyEvent];
    });
}

- (void)productsRequested:(NSNotification *)notification
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

- (void)productPurchased:(NSNotification *)notification
{
    NSString * identifier = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupTableHeaderView];
        [self.tableView reloadData];
        
        OAProduct *product = [_iapHelper product:identifier];
        if (product)
            [OAPluginPopupViewController showProductAlert:product afterPurchase:YES];
    });
}

- (void)productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupTableHeaderView];
        [self.tableView reloadData];
    });
}

#pragma mark - Selectors

- (void)buttonPurchaseClicked:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    
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

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void)onButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
}

@end
