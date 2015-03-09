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


@interface OAPurchasesViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAPurchasesViewController {

    NSNumberFormatter *_numberFormatter;
    MBProgressHUD* _loadProductsProgressHUD;

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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
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

@end
