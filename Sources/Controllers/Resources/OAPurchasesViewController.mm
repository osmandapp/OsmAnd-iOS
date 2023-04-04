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
#import "OAMenuSimpleCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OACardButtonCell.h"
#import "OAIconTitleValueCell.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OALinks.h"
#import <SafariServices/SafariServices.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface OAPurchasesViewController () <UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate>

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
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
}

static BOOL _purchasesUpdated;

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"purchases");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 0.001;
    self.tableView.sectionFooterHeight = 0.001;

    _iapHelper = [OAIAPHelper sharedInstance];
    _headers = [NSMutableDictionary dictionary];

    [self generateData];
    [self updateLoadingView:!_purchasesUpdated];
    
    [self.backButton setImage:[UIImage rtlImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestFailedNotification object:nil];

    OAAppSettings.sharedManager.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
    [[OARootViewController instance] requestProductsWithProgress:NO reload:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateLoadingView:self.tableView.tableHeaderView != nil];
    } completion:nil];
}

- (void)updateLoadingView:(BOOL)show
{
    self.tableView.tableHeaderView = show ? [self getHeaderView] : nil;
}

- (UIView *)getHeaderView
{
    CGFloat headerTopPadding = 40.;
    UIFont *labelFont = [UIFont scaledSystemFontOfSize:17.];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., self.tableView.frame.size.width, headerTopPadding + labelFont.lineHeight)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    headerView.backgroundColor = UIColor.clearColor;

    UIView *loadingContainerView = [[UIView alloc] init];
    loadingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:loadingContainerView];

    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    loadingLabel.text = OALocalizedString(@"loading_purchase_information");
    loadingLabel.textColor = UIColorFromRGB(color_text_footer);
    loadingLabel.font = labelFont;
    loadingLabel.adjustsFontForContentSizeCategory = YES;
    [loadingContainerView addSubview:loadingLabel];

    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] init];
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [loadingIndicator startAnimating];
    [loadingContainerView addSubview:loadingIndicator];

    CGFloat indicatorSideSize = 20.;
    CGFloat indicatorTrailing = 10.;
    CGFloat textWidthMax = self.tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2 - indicatorSideSize - indicatorTrailing;
    CGFloat textWidth = [OAUtilities calculateTextBounds:loadingLabel.text width:textWidthMax height:labelFont.lineHeight font:labelFont].width;
    [NSLayoutConstraint activateConstraints:@[
        [loadingContainerView.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:headerTopPadding],
        [loadingContainerView.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor],
        [loadingContainerView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [loadingContainerView.widthAnchor constraintEqualToConstant:indicatorSideSize + indicatorTrailing + textWidth],
        [loadingIndicator.centerYAnchor constraintEqualToAnchor:loadingContainerView.centerYAnchor],
        [loadingIndicator.leadingAnchor constraintEqualToAnchor:loadingContainerView.leadingAnchor],
        [loadingLabel.centerYAnchor constraintEqualToAnchor:loadingContainerView.centerYAnchor],
        [loadingLabel.leadingAnchor constraintEqualToAnchor:loadingIndicator.trailingAnchor constant:indicatorTrailing],
        [loadingLabel.trailingAnchor constraintEqualToAnchor:loadingContainerView.trailingAnchor],
        [loadingLabel.widthAnchor constraintEqualToConstant:textWidth]
    ]];

    return headerView;
}

-(void) addAccessibilityLabels
{
    self.backButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
    self.restoreButton.accessibilityLabel = OALocalizedString(@"shared_string_restore");
}

- (void) generateData
{
    [_headers removeAllObjects];
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray array];
    if (_purchasesUpdated)
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
        for (OAProduct *product in _iapHelper.inAppsPurchased)
        {
            if ([activeProducts containsObject:product])
                continue;
            if (product.purchaseState == PSTATE_PURCHASED)
                [activeProducts addObject:product];
            else if (product.purchaseState == PSTATE_NOT_PURCHASED)
                [expiredProducts addObject:product];
        }

        OAAppSettings *settings = OAAppSettings.sharedManager;
        BOOL isProSubscriptionAvailable = [settings.backupPurchaseActive get];
        if (activeProducts.count == 0 && expiredProducts.count == 0 && !isProSubscriptionAvailable)
        {
            [data addObject:@[
                    @{
                            @"key": @"no_purchases",
                            @"type": [OALargeImageTitleDescrTableViewCell getCellIdentifier],
                            @"icon": [UIImage templateImageNamed:@"ic_custom_shop_bag_48"],
                            @"icon_color": UIColorFromRGB(color_tint_gray),
                            @"title": OALocalizedString(@"no_purchases"),
                            @"description": [NSString stringWithFormat:OALocalizedString(@"empty_purchases_description"), OALocalizedString(@"restore_purchases")]
                    }
            ]];
            [data addObject:@[
                    @{
                            @"key": @"get_osmand_pro",
                            @"type": [OACardButtonCell getCellIdentifier],
                            @"icon": [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"],
                            @"title": OALocalizedString(@"product_title_pro"),
                            @"description": OALocalizedString(@"osm_live_banner_desc"),
                            @"button_title": OALocalizedString(@"shared_string_get"),
                            @"button_icon": [UIImage templateImageNamed:@"ic_custom_arrow_forward"],
                            @"button_icon_color": UIColorFromRGB(color_primary_purple)
                    }
            ]];
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
                        datePattern = OALocalizedString(@"shared_string_expires");
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
                            @"key": @"product_pro_crossplatform",
                            @"type": [OAMenuSimpleCell getCellIdentifier],
                            @"icon": @"ic_custom_osmand_pro_logo_colored",
                            @"title": isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro"),
                            @"descr": dateString
                    }];
                }
                for (NSInteger i = 0; i < activeProducts.count; i++)
                {
                    OAProduct *product = activeProducts[i];
                    [active addObject:@{
                            @"key": [@"product_" stringByAppendingString:product.productIdentifier],
                            @"type": [OAMenuSimpleCell getCellIdentifier],
                            @"product": product
                    }];
                }
                [data addObject:active];
                _headers[@(data.count - 1)] = OALocalizedString(@"osm_live_active");
            }
            if (expiredProducts.count > 0)
            {
                NSMutableArray *expired = [NSMutableArray array];
                for (NSInteger i = 0; i < expiredProducts.count; i++)
                {
                    OAProduct *product = expiredProducts[i];
                    [expired addObject:@{
                            @"key": [@"product_" stringByAppendingString:product.productIdentifier],
                            @"type": [OAMenuSimpleCell getCellIdentifier],
                            @"product": product
                    }];
                }
                [data addObject:expired];
                _headers[@(data.count - 1)] = OALocalizedString(@"expired");
            }
            [data addObject:@[
                    @{
                            @"key": @"explore_osmnad_plans",
                            @"type": [OACardButtonCell getCellIdentifier],
                            @"title": OALocalizedString(@"explore_osmnad_plans_to_find_suitable"),
                            @"button_title": OALocalizedString(@"shared_string_learn_more"),
                            @"button_icon": [UIImage templateImageNamed:@"ic_custom_arrow_forward"],
                            @"button_icon_color": UIColorFromRGB(color_primary_purple)
                    }
            ]];
        }
    }
    
    [data addObject:@[
        @{
            @"key": @"restore_purchases",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"restore_purchases"),
            @"icon": [UIImage templateImageNamed:@"ic_custom_reset"],
            @"tint_color": UIColorFromRGB(color_primary_purple),
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
        },
        @{
            @"key": @"contact_support_description",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": [NSString stringWithFormat: OALocalizedString(@"contact_support_description"), kSupportEmail],
            @"tint_color": UIColorFromRGB(color_text_footer)
        },
        @{
            @"key": @"contact_support",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"contact_support"),
            @"tint_color": UIColorFromRGB(color_primary_purple)
        }
    ]];
    _headers[@(data.count - 1)] = OALocalizedString(@"shared_string_help");

    _data = data;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        datePattern = OALocalizedString(@"shared_string_expires");
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

- (void)updateViewAfterProductsRequested
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _purchasesUpdated = YES;
        [self updateLoadingView:NO];
        [self generateData];
        [self.tableView reloadData];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void) productsRestored:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void) productsRequested:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (IBAction) onRestoreButtonPressed:(id)sender
{
    _purchasesUpdated = NO;
    [self updateLoadingView:YES];
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
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
    return _headers[@(section)];
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
            cell.textView.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            cell.descriptionView.text = @"";
        }
        if (cell)
        {
            NSString *key = item[@"key"];
            CGFloat leftInset = [key isEqualToString: @"new_device_account"]
                    ? 0. : [key isEqualToString: @"contact_support_description"]
                            ? CGFLOAT_MAX : ([OAUtilities getLeftMargin] + kPaddingOnSideOfContent);
            cell.separatorInset = UIEdgeInsetsMake(0., leftInset, 0., 0.);

            UIColor *tintColor = [item.allKeys containsObject:@"tint_color"] ? item[@"tint_color"] : UIColor.blackColor;
            cell.textView.text = item[@"title"];
            cell.textView.textColor = tintColor;

            BOOL hasRightIcon = ![key hasPrefix:@"contact_support"];
            [cell showRightIcon:hasRightIcon];
            cell.selectionStyle = [key isEqualToString: @"contact_support_description"]
                    ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

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
            cell.titleView.font = [item[@"key"] isEqualToString:@"get_osmand_pro"]
                    ? [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] : [UIFont scaledSystemFontOfSize:17.];

            NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:item[@"button_title"]];
            [buttonTitle addAttribute:NSForegroundColorAttributeName
                                value:UIColorFromRGB(color_primary_purple)
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [buttonTitle addAttribute:NSFontAttributeName
                                value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold]
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [cell.buttonView setAttributedTitle:buttonTitle forState:UIControlStateNormal];

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
            [cell showButton:NO];
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
    else if ([cellType isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell changeHeight:YES];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0, 0);
            OAProduct *product = item[@"product"];
            if (product)
            {
                cell.textView.text = [product.productIdentifier isEqualToString:kInAppId_Addon_Nautical]
                        ? OALocalizedString(@"rendering_attr_depthContours_name")
                        : product.localizedTitle;
                cell.imgView.image = [product isKindOfClass:OASubscription.class] || [OAIAPHelper isFullVersion:product]
                        ? [UIImage imageNamed:product.productIconName]
                        : [product.feature getIcon];

                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self getStatus:product]];
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.minimumLineHeight = 17.;
                paragraphStyle.lineSpacing = 2.;
                [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:13.] range:NSMakeRange(0, attributedString.length)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_footer) range:NSMakeRange(0, attributedString.length)];
                cell.descriptionView.attributedText = attributedString;
            }
            else
            {
                cell.textView.text = item[@"title"];
                cell.imgView.image = [UIImage imageNamed:item[@"icon"]];
                cell.descriptionView.text = item[@"descr"];
                cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
                cell.descriptionView.font = [UIFont scaledSystemFontOfSize:13.];
            }
            UIImageView *rightImageView = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:@"ic_custom_arrow_right"]];
            rightImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.accessoryView = rightImageView;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OACardButtonCell getCellIdentifier]])
    {
        [((OACardButtonCell *) cell) setNeedsUpdateConfiguration];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = _headers[@(section)];
    if (header)
    {
        UIFont *font = [UIFont scaledSystemFontOfSize:13.];
        CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + kPaddingOnSideOfHeaderWithText;
        return headerHeight;
    }

    return kHeaderHeightDefault;
}

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
    else if ([key isEqualToString:@"contact_support"])
        [self sendEmail];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)sendEmail
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:OALocalizedString(@"osmand_purchases_item")];
        [mailCont setToRecipients:@[OALocalizedString(@"login_footer_email_part")]];
        [mailCont setMessageBody:@"" isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
