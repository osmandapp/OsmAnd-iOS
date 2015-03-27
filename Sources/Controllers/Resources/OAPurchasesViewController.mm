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

- (void)viewDidLoad {

    [super viewDidLoad];

    _loadProductsProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    //_loadProductsProgressHUD.dimBackground = YES;
    _loadProductsProgressHUD.minShowTime = .5f;
    
    [self.view addSubview:_loadProductsProgressHUD];
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    if (self.openFromSplash) {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
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
            return [[OAIAPHelper inAppsMaps] count];
            
        case 1:
            return [[OAIAPHelper inAppsAddons] count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Maps";
            
        case 1:
            return @"Addons";
            
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
    
    if (cell) {
        
        NSString *identifier;
        NSString *title;
        NSString *desc;
        NSString *price;
        UIImage *imgTitle;
        
        switch (indexPath.section) {
            case 0: // Maps
            {
                identifier = [OAIAPHelper inAppsMaps][indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_1.png"];
                break;
            }

            case 1: // Addons
            {
                identifier = [OAIAPHelper inAppsAddons][indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
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
        
        [cell setPurchased:[[OAIAPHelper sharedInstance] productPurchased:identifier]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    switch (indexPath.section) {
        case 0: // Maps
            identifier = [OAIAPHelper inAppsMaps][indexPath.row];
            break;
            
        case 1: // Addons
            identifier = [OAIAPHelper inAppsAddons][indexPath.row];
            break;
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([[OAIAPHelper sharedInstance] productPurchased:identifier])
        return;
    
    SKProduct *product = [[OAIAPHelper sharedInstance] product:identifier];

    if (product) {
        
        _restoringPurchases = NO;
        [_loadProductsProgressHUD show:YES];
        
        [[OAIAPHelper sharedInstance] buyProduct:product];
    }
    
}

- (void)productPurchased:(NSNotification *)notification {
    
    NSString * identifier = notification.object;
    int index = [[OAIAPHelper sharedInstance] productIndex:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_restoringPurchases)
            [_loadProductsProgressHUD hide:YES];

        if (index != -1) {
            NSInteger section = [[OAIAPHelper inAppsMaps] containsObject:identifier] ? 0 : 1;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (!_restoringPurchases && [identifier isEqualToString:kInAppId_Addon_SkiMap]) {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Please turn on the \"Ski map\" style in the Map Settings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }

        if (!_restoringPurchases && [identifier isEqualToString:kInAppId_Addon_Nautical]) {
            
            const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
            NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:repositoryMap->packageSize
                                                                       countStyle:NSByteCountFormatterCountStyleFile];
            
            NSString* message = nil;
            if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
                message = OALocalizedString(@"Please turn on \"Nautical\" style in the Map Settings and install world seamarks basemap.\n\nDowloading requires %1$@ over cellular network. This may incur high charges. You may install it later through the Maps & Resources. Proceed?",
                                            stringifiedSize);
            else
                message = OALocalizedString(@"Please turn on \"Nautical\" style in the Map Settings and install world seamarks basemap.\n\nDowloading requires %1$@ over WiFi network. You may install it later through the Maps & Resources. Proceed?",
                                            stringifiedSize);
            
            UIAlertView *mapDownloadAlert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"Download") message:message delegate:self  cancelButtonTitle:OALocalizedString(@"No, thanks") otherButtonTitles:OALocalizedString(@"Download map now"), nil];
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
            NSString *text = [NSString stringWithFormat:@"Purchase of \"%@\" has failed", product.localizedTitle];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
            NSString *text;
            if (errorsCount > 1)
                text = [NSString stringWithFormat:@"%d items were not restored. Please try again.", errorsCount];
            else
                text = @"One item was not restored. Please try again.";
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
