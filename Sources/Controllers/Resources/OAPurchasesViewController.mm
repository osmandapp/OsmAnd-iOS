//
//  OAPurchasesViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPurchasesViewController.h"
#import "OAPurchaseDetailsViewController.h"
#import "OAIAPHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAChoosePlanHelper.h"
#import "OAMultiIconTextDescCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OACardButtonCell.h"
#import "OAIconTitleValueCell.h"
#import "OAColors.h"
#import "OALinks.h"
#import <SafariServices/SafariServices.h>

@interface OAPurchasesViewController () <UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;

@end

@implementation OAPurchasesViewController
{
    OAIAPHelper *_iapHelper;
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSMapTable<NSNumber *, NSString *> *_headers;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"purchases");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _iapHelper = [OAIAPHelper sharedInstance];
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
    [self generateData];
}

- (void) generateData
{
    NSArray<OAProduct *> *mainPurchases = [_iapHelper getEverMadeMainPurchases];
    NSMutableArray<OAProduct *> *activeProducts = [NSMutableArray array];
    NSMutableArray<OAProduct *> *expiredProducts = [NSMutableArray array];
    for (OAProduct *product in mainPurchases)
    {
        if (product.purchaseState == PSTATE_PURCHASED)
            [activeProducts addObject:product];
        else if (product.purchaseState == PSTATE_NOT_PURCHASED)
            [expiredProducts addObject:product];
    }
    // Display old purchases if no new purchases are active
    if (activeProducts.count == 0)
    {
        for (OAProduct *product in _iapHelper.inAppsPurchased)
        {
            if (product.purchaseState == PSTATE_PURCHASED)
                [activeProducts addObject:product];
            else if (product.purchaseState == PSTATE_NOT_PURCHASED)
                [expiredProducts addObject:product];
        }
    }

    _headers = [NSMapTable new];
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray array];
    OAAppSettings *settings = OAAppSettings.sharedManager;
    BOOL isProSubscriptionAvailable = [settings.backupPurchaseActive get];
    if (activeProducts.count == 0 && expiredProducts.count == 0 && !isProSubscriptionAvailable)
    {
        [data addObject:@[@{
                @"key": @"no_purchases",
                @"type": [OALargeImageTitleDescrTableViewCell getCellIdentifier],
                @"icon": [UIImage templateImageNamed:@"ic_custom_shop_bag"],
                @"icon_color": UIColorFromRGB(color_tint_gray),
                @"title": OALocalizedString(@"no_purchases"),
                @"description" : [NSString stringWithFormat:OALocalizedString(@"empty_purchases_description"), OALocalizedString(@"restore_purchases")]
        }]];
        [data addObject:@[@{
                @"key": @"get_osmand_pro",
                @"type": [OACardButtonCell getCellIdentifier],
                @"icon": [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"],
                @"title": OALocalizedString(@"product_title_pro"),
                @"description" : OALocalizedString(@"osm_live_banner_desc"),
                @"button_title": OALocalizedString(@"purchase_get"),
                @"button_icon": [UIImage templateImageNamed:@"ic_custom_arrow_forward"],
                @"button_icon_color": UIColorFromRGB(color_primary_purple),
        }]];
    }
    else
    {
        if (activeProducts.count > 0 || isProSubscriptionAvailable)
        {
            NSMutableArray *active = [NSMutableArray array];
            if (isProSubscriptionAvailable)
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateStyle = NSDateFormatterMediumStyle;
                NSString *dateString = @"";
                NSString *datePattern = @"";
                OASubscriptionState *state = [settings.backupPurchaseState get];
                BOOL isPromo = ((EOASubscriptionOrigin) [settings.proSubscriptionOrigin get]) == EOASubscriptionOriginPromo;
                if (state != OASubscriptionState.EXPIRED)
                    datePattern = OALocalizedString(@"expires");
                else
                    datePattern = OALocalizedString(@"expired");
                long expiretime = [settings.backupPurchaseExpireTime get];
                if (expiretime > 0)
                {
                    NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:[settings.backupPurchaseExpireTime get]];
                    dateString = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), datePattern,
                                  expireDate ? [formatter stringFromDate:expireDate] : @""];
                }
                [active addObject:@{
                    @"key" : @"product_pro_crossplatform",
                    @"type" : [OAMultiIconTextDescCell getCellIdentifier],
                    @"icon" : @"ic_custom_osmand_pro_logo_colored",
                    @"title" : isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro"),
                    @"descr" : dateString
                }];
            }
            for (OAProduct *product in activeProducts)
            {
                [active addObject:@{
                        @"key": [@"product_" stringByAppendingString:product.productIdentifier],
                        @"type": [OAMultiIconTextDescCell getCellIdentifier],
                        @"product": product
                }];
            }
            [data addObject:active];
            [_headers setObject:OALocalizedString(@"menu_active_trips") forKey:@(data.count - 1)];
        }
        if (expiredProducts.count > 0)
        {
            NSMutableArray *expired = [NSMutableArray array];
            for (OAProduct *product in expiredProducts)
            {
                [expired addObject:@{
                        @"key": [@"product_" stringByAppendingString:product.productIdentifier],
                        @"type": [OAMultiIconTextDescCell getCellIdentifier],
                        @"product": product
                }];
            }
            [data addObject:expired];
            [_headers setObject:OALocalizedString(@"expired") forKey:@(data.count - 1)];
        }
        [data addObject:@[@{
            @"key": @"explore_osmnad_plans",
            @"type": [OACardButtonCell getCellIdentifier],
            @"title": OALocalizedString(@"explore_osmnad_plans_to_find_suitable"),
            @"button_title": OALocalizedString(@"shared_string_learn_more"),
            @"button_icon": [UIImage templateImageNamed:@"ic_custom_arrow_forward"],
            @"button_icon_color": UIColorFromRGB(color_primary_purple)
        }]];
    }
    
    [data addObject:@[
        @{
            @"key": @"restore_purchases",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"restore_purchases"),
            @"icon": [UIImage templateImageNamed:@"ic_custom_reset"],
            @"tint_color": UIColorFromRGB(color_primary_purple)
        },
        @{
            @"key": @"redeem_promo_code",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"redeem_promo_code"),
            @"icon": [UIImage templateImageNamed:@"ic_custom_label_sale"],
            @"tint_color": UIColorFromRGB(color_primary_purple)
        },
        @{
            @"key": @"new_device_account",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"new_device_account"),
            @"icon": [UIImage templateImageNamed:@"ic_navbar_help"],
            @"tint_color": UIColorFromRGB(color_primary_purple)
        }
    ]];
    [_headers setObject:OALocalizedString(@"menu_help") forKey:@(data.count - 1)];

    _data = data;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
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

- (void)openSafariWithURL:(NSString *)url
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (NSString *)getStatus:(OAProduct *)product
{
    NSString *datePattern;
    if (product.purchaseState == PSTATE_NOT_PURCHASED)
        datePattern = OALocalizedString(@"expired");
    else if ([product isKindOfClass:OASubscription.class])
        datePattern = OALocalizedString(@"expires");
    else if ([product isKindOfClass:OAProduct.class])
        datePattern = OALocalizedString(@"shared_string_purchased");

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *dateString = nil;
    if (product.expirationDate)
    {
        dateString = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), datePattern,
                      product.expirationDate ? [formatter stringFromDate:product.expirationDate] : @""];
    }
    
    NSString *res;
    if (dateString)
    {
        res = [NSString stringWithFormat:@"%@\n%@", [product isKindOfClass:OASubscription.class]
               ? [product getTitle:13.].string
               : OALocalizedString(@"in_app_purchase_desc"), dateString];
    }
    else
    {
        res = [NSString stringWithFormat:@"%@", [product isKindOfClass:OASubscription.class]
               ? [product getTitle:13.].string
               : OALocalizedString(@"in_app_purchase_desc")];
    }
    return res;
}

- (IBAction) onRestoreButtonPressed:(id)sender
{
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

- (void) productsRestored:(NSNotification *)notification
{
//    NSNumber *errorsCountObj = notification.object;
//    int errorsCount = errorsCountObj.intValue;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_headers objectForKey:@(section)];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    UITableViewCell *outCell = nil;
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.descriptionView.text = @"";
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(
                    0.,
                    [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row + 1 ? 0. : 20.,
                    0.,
                    0.
            );

            UIColor *tintColor = [item.allKeys containsObject:@"tint_color"] ? item[@"tint_color"] : UIColor.blackColor;
            cell.textView.text = item[@"title"];
            cell.textView.textColor = tintColor;
            cell.rightIconView.image = item[@"icon"];
            cell.rightIconView.tintColor = tintColor;
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OACardButtonCell getCellIdentifier]])
    {
        OACardButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACardButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACardButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OACardButtonCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            UIImage *icon = item[@"icon"];
            cell.iconView.image = icon;
            [cell showIcon:icon != nil];

            NSString *description = item[@"description"];
            cell.descriptionView.text = description;
            [cell showDescription:description != nil && description.length > 0];

            cell.titleView.text = item[@"title"];

            NSMutableAttributedString *attributedString =
                    [[NSMutableAttributedString alloc] initWithString:item[@"button_title"]
                                                           attributes:@{
                    NSFontAttributeName: [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold]
            }];
            [cell.buttonView setAttributedTitle:attributedString forState:UIControlStateNormal];
            [cell.buttonView setImage:item[@"button_icon"] forState:UIControlStateNormal];
            cell.buttonView.tintColor = [item.allKeys containsObject:@"button_icon_color"] ? item[@"button_icon_color"] : UIColor.blackColor;

            cell.buttonView.tag = indexPath.section << 10 | indexPath.row;
            [cell.buttonView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.buttonView addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];
            cell.cellImageView.image = item[@"icon"];
            cell.cellImageView.tintColor = item[@"icon_color"];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0, 66., 0, 0);
        }
        if (cell)
        {
            OAProduct *product = item[@"product"];
            if (product)
            {
                cell.textView.text = [product.productIdentifier isEqualToString:kInAppId_Addon_Nautical]
                        ? OALocalizedString(@"product_title_sea_depth_contours")
                        : product.localizedTitle;
                cell.iconView.image = [product isKindOfClass:OASubscription.class] || [OAIAPHelper isFullVersion:product]
                        ? [UIImage imageNamed:product.productIconName]
                        : [product.feature getIcon];
                cell.descView.text = [self getStatus:product];
            }
            else
            {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [UIImage imageNamed:item[@"icon"]];
                cell.descView.text = item[@"descr"];
            }
            [cell setOverflowVisibility:NO];
            [cell.overflowButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_right"] forState:UIControlStateNormal];
            cell.overflowButton.tintColor = UIColorFromRGB(color_tint_gray);
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"restore_purchases"])
        [self onRestoreButtonPressed:nil];
    else if ([key isEqualToString:@"redeem_promo_code"])
        [self openSafariWithURL:kAppleRedeemPromoCode];
    else if ([key isEqualToString:@"new_device_account"])
        [self openSafariWithURL:kDocsPurchasesNewDevice];
    else if ([key isEqualToString:@"product_pro_crossplatform"])
        [self presentViewController:[[OAPurchaseDetailsViewController alloc] initForCrossplatformSubscription] animated:YES completion:nil];
    else if ([key hasPrefix:@"product_"])
        [self presentViewController:[[OAPurchaseDetailsViewController alloc] initWithProduct:item[@"product"]] animated:YES completion:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    if (button)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *key = item[@"key"];
        if ([key isEqualToString:@"get_osmand_pro"])
            [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
        else if ([key isEqualToString:@"explore_osmnad_plans"])
            [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.MONTHLY_MAP_UPDATES navController:self.navigationController];
    }
}

@end
