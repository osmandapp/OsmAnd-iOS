//
//  OAPurchasesViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPurchasesViewController.h"
#import "OAIAPHelper.h"
#import "OAInAppCell.h"
#import <StoreKit/StoreKit.h>
#import "OALog.h"
#import "OAResourcesBaseViewController.h"
#import "OsmAndApp.h"
#include "Localization.h"
#import "OAUtilities.h"
#import <Reachability.h>


@interface OAPurchasesViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIButton *btnRestorePurchases;

@end

@implementation OAPurchasesViewController {

    NSNumberFormatter *_numberFormatter;
    MBProgressHUD* _loadProductsProgressHUD;
    BOOL _restoringPurchases;

}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"purchases");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    
    [_btnToolbarMaps setTitle:OALocalizedStringUp(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedStringUp(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
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
                if (success) {
                    [self.tableView reloadData];
                    CATransition *animation = [CATransition animation];
                    [animation setType:kCATransitionPush];
                    [animation setSubtype:kCATransitionFromBottom];
                    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                    [animation setFillMode:kCAFillModeBoth];
                    [animation setDuration:.3];
                    [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
                }
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
    return [OAIAPHelper sharedInstance].productsLoaded ? 2 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [[OAIAPHelper inAppsAddons] count];
            
        case 1:
            return [[OAIAPHelper inAppsMaps] count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return OALocalizedString(@"prch_addons");
            
        case 1:
            return OALocalizedString(@"maps");
            
        default:
            return @"";
    }
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
    
    BOOL allWorldMapsPurchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:kInAppId_Region_All_World];
    
    if (cell) {
        
        NSString *identifier;
        NSString *title;
        NSString *desc;
        NSString *price;
        UIImage *imgTitle;
        
        switch (indexPath.section)
        {
            case 0: // Addons
            {
                identifier = [OAIAPHelper inAppsAddons][indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
                break;
            }
                
            case 1: // Maps
            {
                identifier = [OAIAPHelper inAppsMaps][indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_1.png"];
                break;
            }

            default:
                break;
        }

        SKProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
        if (product) {
            title = product.localizedTitle;
            desc = product.localizedDescription;
            [_numberFormatter setLocale:product.priceLocale];
            price = [_numberFormatter stringFromNumber:product.price];
        }

        [cell.imgIcon setImage:imgTitle];
        [cell.lbTitle setText:title];
        [cell.lbDescription setText:desc];
        [cell.lbPrice setText:price];
        
        BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
        BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:identifier];
        
        if (indexPath.section == 1)
            [cell setPurchased:(purchased || allWorldMapsPurchased) disabled:NO];
        else
            [cell setPurchased:purchased disabled:disabled];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    switch (indexPath.section)
    {
        case 0: // Addons
            identifier = [OAIAPHelper inAppsAddons][indexPath.row];
            break;

        case 1: // Maps
            identifier = [OAIAPHelper inAppsMaps][indexPath.row];
            break;
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
    BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:identifier];
    BOOL allWorldMapsPurchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:kInAppId_Region_All_World];
    
    if (indexPath.section == 1)
    {
        if (purchased || allWorldMapsPurchased)
            return;
    }
    else
    {
        if (purchased)
        {
            if (disabled)
                [[OAIAPHelper sharedInstance] enableProduct:identifier];
            else
                [[OAIAPHelper sharedInstance] disableProduct:identifier];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
            return;
        }
    }
    
    
    SKProduct *product = [[OAIAPHelper sharedInstance] product:identifier];

    if (product) {
        
        _restoringPurchases = NO;
        [_loadProductsProgressHUD show:YES];
        
        [[OAIAPHelper sharedInstance] buyProduct:product];
    }
    
}

- (void)productPurchased:(NSNotification *)notification {
    
    NSString * identifier = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_restoringPurchases)
            [_loadProductsProgressHUD hide:YES];

        [self.tableView reloadData];
        
        if (!_restoringPurchases && [identifier isEqualToString:kInAppId_Addon_SkiMap]) {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"prch_ski_q") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
        }

        if (!_restoringPurchases && [identifier isEqualToString:kInAppId_Addon_Nautical]) {
            
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

- (void)productPurchaseFailed:(NSNotification *)notification {
    
    if (_restoringPurchases)
        return;
    
    NSString * identifier = notification.object;
    SKProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];

        if (product) {
            NSString *text = [NSString stringWithFormat:OALocalizedString(@"prch_failed"), product.localizedTitle];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void)productsRestored:(NSNotification *)notification {

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

- (IBAction)btnRestorePurchasesClicked:(id)sender
{
    if (![[OAIAPHelper sharedInstance] productsLoaded])
        return;
    
    _restoringPurchases = YES;
    [_loadProductsProgressHUD show:YES];
    
    [[OAIAPHelper sharedInstance] restoreCompletedTransactions];
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
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 100 && buttonIndex != alertView.cancelButtonIndex) {
        // Download map
        const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
        NSString* name = [OAResourcesBaseViewController titleOfResource:repositoryMap
                                                               inRegion:[OsmAndApp instance].worldRegion
                                                         withRegionName:YES];
        
        [OAResourcesBaseViewController startBackgroundDownloadOf:repositoryMap resourceName:name];
    }
}

@end
