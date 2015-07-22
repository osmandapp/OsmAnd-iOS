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
#import <StoreKit/StoreKit.h>
#import "OALog.h"
#import "OAResourcesBaseViewController.h"
#import "OAPurchasesViewController.h"
#import "OsmAndApp.h"
#include "Localization.h"
#import "OAUtilities.h"
#import <Reachability.h>


@interface OAPluginsViewController ()<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAPluginsViewController
{
    NSNumberFormatter *_numberFormatter;
    MBProgressHUD* _loadProductsProgressHUD;
    
    CALayer *_horizontalLine;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"plugins");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    
    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _loadProductsProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    //_loadProductsProgressHUD.dimBackground = YES;
    _loadProductsProgressHUD.minShowTime = .5f;
    
    [self.view addSubview:_loadProductsProgressHUD];
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.toolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.toolbarView.layer addSublayer:_horizontalLine];
    
    if (self.openFromSplash)
    {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
    
    if (self.openFromCustomPlace)
    {
        [_toolbarView removeFromSuperview];
        _tableView.frame = CGRectMake(_tableView.frame.origin.x, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height + _toolbarView.frame.size.height);
    }
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    
    if (![[OAIAPHelper sharedInstance] productsLoaded]) {
        
        [_loadProductsProgressHUD show:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[OAIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success) {
                
                [self.tableView reloadData];
                CATransition *animation = [CATransition animation];
                [animation setType:kCATransitionPush];
                [animation setSubtype:kCATransitionFromBottom];
                [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                [animation setFillMode:kCAFillModeBoth];
                [animation setDuration:.3];
                [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
                
                [_loadProductsProgressHUD hide:YES];
            }];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [OAIAPHelper sharedInstance].productsLoaded ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[OAIAPHelper inAppsAddons] count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const inAppCellIdentifier = @"OAInAppCell";
    
    OAInAppCell* cell;
    cell = (OAInAppCell *)[tableView dequeueReusableCellWithIdentifier:inAppCellIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAInAppCell" owner:self options:nil];
        cell = (OAInAppCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        NSString *identifier;
        NSString *title;
        NSString *desc;
        NSString *price;
        UIImage *imgTitle;

        identifier = [OAIAPHelper inAppsAddons][indexPath.row];
        imgTitle = [UIImage imageNamed:[OAIAPHelper productIconName:identifier]];
        if (!imgTitle)
            imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];

        cell.imgIconBackground.hidden = NO;

        OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
        if (product)
        {
            title = product.localizedTitle;
            desc = product.localizedDescription;
            if (product.price)
            {
                [_numberFormatter setLocale:product.priceLocale];
                price = [_numberFormatter stringFromNumber:product.price];
            }
            else
            {
                price = [OALocalizedString(@"shared_string_buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
            }
        }
        
        [cell.imgIcon setImage:imgTitle];
        [cell.lbTitle setText:title];
        [cell.lbDescription setText:desc];
        [cell.lbPrice setText:price];
        
        BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
        BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:identifier];
        
        [cell setPurchased:purchased disabled:disabled];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [OAIAPHelper inAppsAddons][indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
    BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:identifier];
    
    if (purchased)
    {
        if (disabled)
        {
            [[OAIAPHelper sharedInstance] enableProduct:identifier];
            if ([identifier isEqualToString:kInAppId_Addon_SkiMap])
            {
                if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
                {
                    [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_ski_q") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                    [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
                }
            }
            else if ([identifier isEqualToString:kInAppId_Addon_Wiki])
            {
                if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
                {
                    [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_wiki_info") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                    [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
                }
            }
            else if ([identifier isEqualToString:kInAppId_Addon_Srtm])
            {
                if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
                {
                    [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_srtm_info") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                    [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
                }
            }
        }
        else
        {
            [[OAIAPHelper sharedInstance] disableProduct:identifier];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
        return;
    }
    
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    
    if (product)
    {
        [_loadProductsProgressHUD show:YES];
        
        [[OAIAPHelper sharedInstance] buyProduct:product];
    }
    
}

- (void)productPurchased:(NSNotification *)notification {
    
    NSString * identifier = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        [self.tableView reloadData];
        
        if ([identifier isEqualToString:kInAppId_Addon_SkiMap])
        {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_ski_q") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
            }
        }
        else if ([identifier isEqualToString:kInAppId_Addon_Wiki])
        {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_wiki_info") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
            }
        }
        else if ([identifier isEqualToString:kInAppId_Addon_Srtm])
        {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]] == nil)
            {
                [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_srtm_info") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
                [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:[NSString stringWithFormat:@"%@_alert_showed", identifier]];
            }
        }
        else if ([identifier isEqualToString:kInAppId_Addon_Nautical])
        {
            const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
            NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:repositoryMap->packageSize
                                                                       countStyle:NSByteCountFormatterCountStyleFile];
            
            NSMutableString* message = [OALocalizedString(@"prch_nau_q1") mutableCopy];
            [message appendString:@"\n\n"];
            if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
            {
                [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
                [message appendString:@" "];
                [message appendString:OALocalizedString(@"incur_high_charges")];
            }
            else
            {
                [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
            }
            
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"prch_nau_q3")];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"proceed_q")];
            
            UIAlertView *mapDownloadAlert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"download") message:message delegate:self  cancelButtonTitle:OALocalizedString(@"nothanks") otherButtonTitles:OALocalizedString(@"download_now"), nil];
            mapDownloadAlert.tag = 100;
            [mapDownloadAlert show];
        }
        
    });
}

- (void)productPurchaseFailed:(NSNotification *)notification
{
    NSString * identifier = notification.object;
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        if (product) {
            NSString *text = [NSString stringWithFormat:OALocalizedString(@"prch_failed"), product.localizedTitle];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void)productsRestored:(NSNotification *)notification
{
    NSNumber *errorsCountObj = notification.object;
    int errorsCount = errorsCountObj.intValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_loadProductsProgressHUD hide:YES];
        
        if (errorsCount > 0) {
            NSString *text = [NSString stringWithFormat:@"%d %@", errorsCount, OALocalizedString(@"prch_items_failed")];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
    
}

-(void)backButtonClicked:(id)sender
{
    if (self.openFromCustomPlace)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)btnToolbarMapsClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [controllers removeObject:self];
    [controllers addObject:purchasesViewController];
    [self.navigationController setViewControllers:controllers];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{    
    if (alertView.tag == 100 && buttonIndex != alertView.cancelButtonIndex)
    {
        // Download map
        const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
        NSString* name = [OAResourcesBaseViewController titleOfResource:repositoryMap
                                                               inRegion:[OsmAndApp instance].worldRegion
                                                         withRegionName:YES];
        
        [OAResourcesBaseViewController startBackgroundDownloadOf:repositoryMap resourceName:name];
    }
}

@end
