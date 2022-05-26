//
//  OAPurchasesViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPurchasesViewController.h"
#import "OAPluginDetailsViewController.h"
#import "OAIAPHelper.h"
#import "OAInAppCell.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAChoosePlanHelper.h"

@interface OAPurchasesViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAPurchasesViewController
{
    OAIAPHelper *_iapHelper;

    CALayer *_horizontalLine;
    NSArray<OAProduct *> *_addonsPurchased;
    NSArray<OAProduct *> *_mapsPurchased;

    NSInteger _pluginsSection;
    NSInteger _mapsSection;
    NSInteger _restoreSection;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"purchases");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _iapHelper = [OAIAPHelper sharedInstance];
    [self generateData];

    if (self.openFromSplash)
    {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void) generateData
{
    _mapsPurchased = _iapHelper.inAppMapsPurchased;
    _addonsPurchased = _iapHelper.inAppAddonsPurchased;
    if ([OAIAPHelper isDepthContoursPurchased])
        _addonsPurchased = [_addonsPurchased arrayByAddingObject:_iapHelper.nautical];

    NSInteger index = 0;

    if (_addonsPurchased.count > 0)
        _pluginsSection = index++;
    else
        _pluginsSection = -1;

    if (_mapsPurchased.count > 0)
        _mapsSection = index++;
    else
        _mapsSection = -1;

    _restoreSection = index;
}

- (UIView *) getTopView
{
    return _titlePanelView;
}

- (UIView *) getMiddleView
{
    return _tableView;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];

    [[OARootViewController instance] requestProductsWithProgress:YES reload:NO];

    [self applySafeAreaMargins];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
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

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return (_pluginsSection >=0 ? 3 : 2);
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _pluginsSection)
        return [_addonsPurchased count];
    else if (section == _mapsSection)
        return [_mapsPurchased count];
    else if (section == _restoreSection)
        return 1;
    else
        return 0;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
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

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAInAppCell* cell;
    cell = (OAInAppCell *)[tableView dequeueReusableCellWithIdentifier:[OAInAppCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInAppCell getCellIdentifier] owner:self options:nil];
        cell = (OAInAppCell *)[nib objectAtIndex:0];
    }
    
    BOOL allWorldMapsPurchased = [_iapHelper.allWorld isPurchased];
    
    if (cell)
    {
        [UIView performWithoutAnimation:^{
            cell.btnPrice.userInteractionEnabled = NO;
            
            NSString *title;
            NSString *desc;
            NSString *price;
            UIImage *imgTitle;
            BOOL purchased = NO;
            BOOL disabled = YES;

            OAProduct *product = nil;
            BOOL isNautical = NO;
            
            if (indexPath.section == _pluginsSection)
            {
                product = _addonsPurchased[indexPath.row];
                isNautical = [product isEqual:_iapHelper.nautical];
                imgTitle = [UIImage imageNamed:isNautical ? @"ic_custom_nautical_depth_colored_day" : [product productIconName]];
                if (!imgTitle)
                    imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
                cell.imgIconBackground.layer.backgroundColor = UIColorFromRGB(0xF0F0F0).CGColor;
                cell.imgIconBackground.hidden = NO;
                cell.btnPrice.hidden = YES;
            }
            else if (indexPath.section == _mapsSection)
            {
                product = _mapsPurchased[indexPath.row];
                imgTitle = [UIImage imageNamed:@"img_app_purchase_1.png"];
                cell.imgIconBackground.hidden = YES;
                cell.btnPrice.hidden = NO;
            }
            else if (indexPath.section == _restoreSection)
            {
                imgTitle = [UIImage imageNamed:@"ic_restore_purchase"];
                title = OALocalizedString(@"restore_all_purchases");
                cell.imgIconBackground.layer.backgroundColor = UIColorFromRGB(0xff8f00).CGColor;
                cell.imgIconBackground.hidden = NO;
                cell.btnPrice.hidden = YES;
            }
            
            if (product)
            {
                purchased = [product isPurchased];
                disabled = product.disabled;

                title = isNautical ? OALocalizedString(@"product_title_sea_depth_contours") : product.localizedTitle;
                desc = isNautical ? OALocalizedString(@"product_desc_sea_depth_contours") : product.localizedDescription;
                if (!product.free)
                    price = [OALocalizedString(@"shared_string_buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
            }
            
            [cell.imgIcon setImage:imgTitle];
            [cell.lbTitle setText:title];
            [cell.lbDescription setText:desc];
            [cell.btnPrice setTitle:price forState:UIControlStateNormal];
            
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAProduct *product;
    if (indexPath.section == _pluginsSection)
        product = _addonsPurchased[indexPath.row];
    else if (indexPath.section == _mapsSection)
        product = _mapsPurchased[indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == _restoreSection)
    {
        [self btnRestorePurchasesClicked:nil];
        return;
    }

    BOOL purchased = product && [product isPurchased];
    BOOL allWorldMapsPurchased = [_iapHelper.allWorld isPurchased];
    
    if (indexPath.section == _mapsSection)
    {
        if (purchased || allWorldMapsPurchased)
            return;
    }
    else if (indexPath.section == _pluginsSection)
    {
        return;
    }
    
    if (product)
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:self.navigationController];
//        [[OARootViewController instance] buyProduct:product showProgress:YES];
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

- (void) productsRestored:(NSNotification *)notification
{
    NSNumber *errorsCountObj = notification.object;
    int errorsCount = errorsCountObj.intValue;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

- (IBAction) btnRestorePurchasesClicked:(id)sender
{
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
}


#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 100 && buttonIndex != alertView.cancelButtonIndex)
    {
        // Download map
        std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
        if (!repositoryMap)
            repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksOldKey);
        
        if (repositoryMap)
        {
            NSString *name = [OAResourcesUIHelper titleOfResource:repositoryMap
                                                         inRegion:[OsmAndApp instance].worldRegion
                                                   withRegionName:YES withResourceType:NO];
            
            [OAResourcesUIHelper startBackgroundDownloadOf:repositoryMap resourceName:name];
        }
    }
}

@end
