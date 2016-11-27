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
#import "OAPluginsViewController.h"
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

@implementation OAPurchasesViewController
{
    NSNumberFormatter *_numberFormatter;
    MBProgressHUD* _loadProductsProgressHUD;
    BOOL _restoringPurchases;

    CALayer *_horizontalLine;
    NSArray *_addonsPurchased;
    
    NSInteger _pluginsSection;
    NSInteger _mapsSection;
    NSInteger _restoreSection;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"purchases");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    
    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _addonsPurchased = [OAIAPHelper inAppsAddonsPurchased];
    NSInteger index = 0;
    if (_addonsPurchased.count > 0)
        _pluginsSection = index++;
    else
        _pluginsSection = -1;
    
    _mapsSection = index++;
    _restoreSection = index;

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

    if (![[OAIAPHelper sharedInstance] productsLoaded])
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self loadProducts];
        else
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    if (![[OAIAPHelper sharedInstance] productsLoaded] &&
        [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        [self loadProducts];
    }
}

- (void)loadProducts
{
    [_loadProductsProgressHUD show:YES];
    
    [[OAIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
            {
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
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (_pluginsSection >=0 ? 3 : 2);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _pluginsSection)
        return [_addonsPurchased count];
    else if (section == _mapsSection)
        return [[OAIAPHelper inAppsMaps] count];
    else if (section == _restoreSection)
        return 1;
    else
        return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _pluginsSection)
        return OALocalizedString(@"plugins");
    else if (section == _mapsSection)
        return OALocalizedString(@"maps");
    else if (section == _restoreSection)
        return OALocalizedString(@"restore");
    else
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
    
    BOOL allWorldMapsPurchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:kInAppId_Region_All_World];
    
    if (cell) {
        [UIView performWithoutAnimation:^{
            cell.btnPrice.userInteractionEnabled = NO;
            
            NSString *identifier;
            NSString *title;
            NSString *desc;
            NSString *price;
            UIImage *imgTitle;
            
            if (indexPath.section == _pluginsSection)
            {
                identifier = _addonsPurchased[indexPath.row];
                imgTitle = [UIImage imageNamed:[OAIAPHelper productIconName:identifier]];
                if (!imgTitle)
                    imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
                cell.imgIconBackground.layer.backgroundColor = UIColorFromRGB(0xF0F0F0).CGColor;
                cell.imgIconBackground.hidden = NO;
                cell.btnPrice.hidden = YES;
                
            }
            else if (indexPath.section == _mapsSection)
            {
                identifier = [OAIAPHelper inAppsMaps][indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_1.png"];
                cell.imgIconBackground.hidden = YES;
                cell.btnPrice.hidden = NO;
            }
            else if (indexPath.section == _restoreSection)
            {
                identifier = nil;
                imgTitle = [UIImage imageNamed:@"ic_restore_purchase"];
                title = OALocalizedString(@"restore_all_purchases");
                cell.imgIconBackground.layer.backgroundColor = UIColorFromRGB(0xff8f00).CGColor;
                cell.imgIconBackground.hidden = NO;
                cell.btnPrice.hidden = YES;
            }
            
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
            [cell.btnPrice setTitle:price forState:UIControlStateNormal];
            
            BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
            BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:identifier];
            
            if (indexPath.section == _mapsSection)
                [cell setPurchased:(purchased || allWorldMapsPurchased) disabled:NO];
            else  if (indexPath.section == _pluginsSection)
                [cell setPurchased:purchased disabled:disabled];
            
            [cell.btnPrice layoutIfNeeded];
        }];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier;
    if (indexPath.section == _pluginsSection)
        identifier = _addonsPurchased[indexPath.row];
    else if (indexPath.section == _mapsSection)
        identifier = [OAIAPHelper inAppsMaps][indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == _restoreSection)
    {
        [self btnRestorePurchasesClicked:nil];
        return;
    }

    BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:identifier];
    BOOL allWorldMapsPurchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:kInAppId_Region_All_World];
    
    if (indexPath.section == _mapsSection)
    {
        if (purchased || allWorldMapsPurchased)
            return;
    }
    else if (indexPath.section == _pluginsSection)
    {
        return;
    }
    
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];

    if (product)
    {
        _restoringPurchases = NO;
        [_loadProductsProgressHUD show:YES];
        
        [[OAIAPHelper sharedInstance] buyProduct:product];
    }
    
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_restoringPurchases)
            [_loadProductsProgressHUD hide:YES];

        [self.tableView reloadData];
        
    });
}

- (void)productPurchaseFailed:(NSNotification *)notification
{
    if (_restoringPurchases)
        return;
    
    NSString * identifier = notification.object;
    OAProduct *product = nil;
    if (identifier)
    {
        product = [[OAIAPHelper sharedInstance] product:identifier];
    }
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

- (IBAction)btnToolbarPluginsClicked:(id)sender
{
    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
    pluginsViewController.openFromSplash = _openFromSplash;
    
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [controllers removeObject:self];
    [controllers addObject:pluginsViewController];
    [self.navigationController setViewControllers:controllers];
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
                                                         withRegionName:YES withResourceType:NO];
        
        [OAResourcesBaseViewController startBackgroundDownloadOf:repositoryMap resourceName:name];
    }
}

@end
