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
#import "OASimpleTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OACardButtonCell.h"
#import "OARightIconTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "OALinks.h"
#import <SafariServices/SafariServices.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "OABackupHelper.h"
#import "GeneratedAssetSymbols.h"

#define OSMAND_START @"OsmAnd Start"

@interface OAPurchasesViewController () <SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation OAPurchasesViewController
{
    OAIAPHelper *_iapHelper;
    OATableDataModel *_data;
}

static BOOL _purchasesUpdated;

#pragma mark - Initialization

- (void)commonInit
{
    _iapHelper = [OAIAPHelper sharedInstance];
}

- (void)registerNotifications
{
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
    [self addNotification:OAIAPProductPurchaseFailedNotification selector:@selector(productPurchaseFailed:)];
    [self addNotification:OAIAPProductsRestoredNotification selector:@selector(productsRestored:)];
    [self addNotification:OAIAPProductsRequestSucceedNotification selector:@selector(productsRequested:)];
    [self addNotification:OAIAPProductsRequestFailedNotification selector:@selector(productsRequested:)];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self updateLoadingView:!_purchasesUpdated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    OAAppSettings.sharedManager.lastReceiptValidationDate = [NSDate dateWithTimeIntervalSince1970:0];
    [[OARootViewController instance] requestProductsWithProgress:NO reload:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"purchases");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil
                                                        iconName:@"ic_navbar_reset"
                                                          action:@selector(onRightNavbarButtonPressed)
                                                            menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"shared_string_restore");
    return @[rightButton];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)createStartFreeSubscription
{
    OATableSectionData *activeSection = [_data createNewSection];
    activeSection.headerText = OALocalizedString(@"osm_live_active");
    NSDate *purchasedDate = [NSDate dateWithTimeIntervalSince1970:[OAAppSettings.sharedManager.backupFreePlanRegistrationTime get]];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *descriptionString = [NSString stringWithFormat:@"%@\n%@", OALocalizedString(@"free_account"), [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), OALocalizedString(@"shared_string_purchased"), [formatter stringFromDate:purchasedDate]]];
    
    [activeSection addRowFromDictionary:@{
        kCellKeyKey : @"product_osmand_start",
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellIconNameKey : @"ic_custom_osmand_start",
        kCellTitleKey : OSMAND_START,
        kCellDescrKey : descriptionString
    }];
}

- (void) generateData
{
    _data = [OATableDataModel model];
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
            if (OABackupHelper.sharedInstance.isRegistered)
            {
                [self createStartFreeSubscription];
            }
            else
            {
                OATableSectionData *noPurchasesSection = [_data createNewSection];
                [noPurchasesSection addRowFromDictionary:@{
                    kCellTypeKey : [OALargeImageTitleDescrTableViewCell getCellIdentifier],
                    kCellIconNameKey : @"ic_custom_shop_bag_48",
                    kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorDefault],
                    kCellTitleKey : OALocalizedString(@"no_purchases"),
                    kCellDescrKey : [NSString stringWithFormat:OALocalizedString(@"empty_purchases_description"), OALocalizedString(@"restore_purchases")]
                }];

                OATableSectionData *osmAndProSection = [_data createNewSection];
                [osmAndProSection addRowFromDictionary:@{
                    kCellKeyKey : @"get_osmand_pro",
                    kCellTypeKey : [OACardButtonCell getCellIdentifier],
                    kCellIconNameKey : @"ic_custom_osmand_pro_logo_colored",
                    kCellTitleKey : OALocalizedString(@"product_title_pro"),
                    kCellDescrKey : OALocalizedString(@"osm_live_banner_desc"),
                    @"button_title": OALocalizedString(@"shared_string_get"),
                    @"button_icon_name": @"ic_custom_arrow_forward",
                    @"button_icon_color": [UIColor colorNamed:ACColorNameIconColorActive]
                }];
            }
        }
        else
        {
            if (activeProducts.count > 0 || isProSubscriptionAvailable)
            {
                OATableSectionData *activeSection = [_data createNewSection];
                activeSection.headerText = OALocalizedString(@"osm_live_active");
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
                    [activeSection addRowFromDictionary:@{
                        kCellKeyKey : @"product_pro_crossplatform",
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        kCellIconNameKey : @"ic_custom_osmand_pro_logo_colored",
                        kCellTitleKey : isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro"),
                        kCellDescrKey : dateString
                    }];
                }
                for (NSInteger i = 0; i < activeProducts.count; i++)
                {
                    OAProduct *product = activeProducts[i];
                    [activeSection addRowFromDictionary:@{
                        kCellKeyKey : [@"product_" stringByAppendingString:product.productIdentifier],
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        @"product" : product
                    }];
                }
            }
            if (expiredProducts.count > 0)
            {
                if (OABackupHelper.sharedInstance.isRegistered
                    && !isProSubscriptionAvailable
                    && activeProducts.count == 0)
                {
                    [self createStartFreeSubscription];
                }
                OATableSectionData *expiredSection = [_data createNewSection];
                expiredSection.headerText = OALocalizedString(@"expired");
                for (NSInteger i = 0; i < expiredProducts.count; i++)
                {
                    OAProduct *product = expiredProducts[i];
                    [expiredSection addRowFromDictionary:@{
                        kCellKeyKey : [@"product_" stringByAppendingString:product.productIdentifier],
                        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                        @"product" : product
                    }];
                }
            }
            OATableSectionData *exploreOsmAndPlansSection = [_data createNewSection];
            [exploreOsmAndPlansSection addRowFromDictionary:@{
                kCellKeyKey : @"explore_osmand_plans",
                kCellTypeKey : [OACardButtonCell getCellIdentifier],
                kCellTitleKey : OALocalizedString(@"explore_osmnad_plans_to_find_suitable"),
                @"button_title": OALocalizedString(@"shared_string_learn_more"),
                @"button_icon_name": @"ic_custom_arrow_forward",
                @"button_icon_color": [UIColor colorNamed:ACColorNameIconColorActive]
            }];
        }
    }

    OATableSectionData *helpSection = [_data createNewSection];
    helpSection.headerText = OALocalizedString(@"shared_string_help");

    [helpSection addRowFromDictionary:@{
        kCellKeyKey : @"restore_purchases",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"restore_purchases"),
        kCellIconNameKey : @"ic_custom_reset",
        kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorActive]
    }];

    [helpSection addRowFromDictionary:@{
        kCellKeyKey : @"redeem_promo_code",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"redeem_promo_code"),
        kCellIconNameKey : @"ic_custom_label_sale",
        kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorActive]
    }];

    [helpSection addRowFromDictionary:@{
        kCellKeyKey : @"new_device_account",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"new_device_account"),
        kCellIconNameKey : @"ic_navbar_help",
        kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorActive]
    }];

    [helpSection addRowFromDictionary:@{
        kCellKeyKey : @"contact_support_description",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : [NSString stringWithFormat: OALocalizedString(@"contact_support_description"), kSupportEmail],
        kCellIconTintColor : [UIColor colorNamed:ACColorNameTextColorSecondary],
    }];

    [helpSection addRowFromDictionary:@{
        kCellKeyKey : @"contact_support",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"contact_support"),
        kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [[_data sectionDataForIndex:section] rowCount];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    UITableViewCell *outCell = nil;
    if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
        }
        if (cell)
        {
            UIColor *tintColor = item.iconTintColor;
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = tintColor;

            BOOL hasRightIcon = item.iconName && item.iconName.length > 0;
            cell.selectionStyle = [item.key isEqualToString: @"contact_support_description"]
                    ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            [cell rightIconVisibility:hasRightIcon];
            cell.rightIconView.image = hasRightIcon ? [UIImage templateImageNamed:item.iconName] : nil;
            cell.rightIconView.tintColor = tintColor;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACardButtonCell getCellIdentifier]])
    {
        OACardButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OACardButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACardButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OACardButtonCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            BOOL hasIcon = item.iconName && item.iconName.length > 0;
            cell.iconView.image = hasIcon ? [UIImage imageNamed:item.iconName] : nil;
            [cell showIcon:hasIcon];

            NSString *description = item.descr;
            cell.descriptionView.text = description;
            [cell showDescription:item.descr && item.descr.length > 0];

            cell.titleView.text = item.title;
            cell.titleView.font = [item.key isEqualToString:@"get_osmand_pro"]
                    ? [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] : [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

            NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:[item stringForKey:@"button_title"]];
            [buttonTitle addAttribute:NSForegroundColorAttributeName
                                value:[UIColor colorNamed:ACColorNameTextColorActive]
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [buttonTitle addAttribute:NSFontAttributeName
                                value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold]
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [cell.buttonView setAttributedTitle:buttonTitle forState:UIControlStateNormal];

            [cell.buttonView setImage:[UIImage templateImageNamed:[item stringForKey:@"button_icon_name"]] forState:UIControlStateNormal];
            cell.buttonView.tintColor = [item objForKey:@"button_icon_color"];

            cell.buttonView.tag = indexPath.section << 10 | indexPath.row;
            [cell.buttonView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.buttonView addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if ([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showButton:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.cellImageView.image = [UIImage templateImageNamed:item.iconName];
            cell.cellImageView.tintColor = item.iconTintColor;
        }
        outCell = cell;
    }
    else if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
        }
        if (cell)
        {
            OAProduct *product = [item objForKey:@"product"];
            if (product)
            {
                cell.titleLabel.text = [product.productIdentifier isEqualToString:kInAppId_Addon_Nautical]
                        ? OALocalizedString(@"rendering_attr_depthContours_name")
                        : product.localizedTitle;
                cell.leftIconView.image = [product isKindOfClass:OASubscription.class] || [OAIAPHelper isFullVersion:product]
                        ? [UIImage imageNamed:product.productIconName]
                        : [product.feature getIcon];

                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self getStatus:product]];
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.minimumLineHeight = 17.;
                paragraphStyle.lineSpacing = 2.;
                [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote] range:NSMakeRange(0, attributedString.length)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:NSMakeRange(0, attributedString.length)];
                cell.descriptionLabel.text = nil;
                cell.descriptionLabel.attributedText = attributedString;
            }
            else
            {
                cell.titleLabel.text = item.title;
                cell.leftIconView.image = [UIImage imageNamed:item.iconName];
                cell.descriptionLabel.attributedText = nil;
                cell.descriptionLabel.text = item.descr;
                cell.descriptionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
                cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }
    return outCell;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *key = item.key;
    if ([key isEqualToString:@"restore_purchases"])
        [self onRightNavbarButtonPressed];
    else if ([key isEqualToString:@"redeem_promo_code"])
        [self openSafariWithURL:kAppleRedeemPromoCode];
    else if ([key isEqualToString:@"new_device_account"])
        [self openSafariWithURL:kDocsPurchasesNewDevice];
    else if ([key isEqualToString:@"contact_support"])
        [self sendEmail];
    else if ([key isEqualToString:@"product_pro_crossplatform"])
        [self showModalViewController:[[OAPurchaseDetailsViewController alloc] initForCrossplatformSubscription]];
    else if ([key isEqualToString:@"product_osmand_start"])
        [self showModalViewController:[[OAPurchaseDetailsViewController alloc] initForFreeStartSubscription]];
    else if ([key hasPrefix:@"product_"])
        [self showModalViewController:[[OAPurchaseDetailsViewController alloc] initWithProduct:[item objForKey:@"product"]]];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OACardButtonCell getCellIdentifier]])
        [((OACardButtonCell *) cell) setNeedsUpdateConfiguration];
}

#pragma mark - Additions

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
        [self updateUI];
    });
}

- (void)updateLoadingView:(BOOL)show
{
    if (show)
    {
        CGFloat headerTopPadding = 40.;
        UIFont *labelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., self.tableView.frame.size.width, headerTopPadding + labelFont.lineHeight)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        headerView.backgroundColor = UIColor.clearColor;

        UIView *loadingContainerView = [[UIView alloc] init];
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:loadingContainerView];

        UILabel *loadingLabel = [[UILabel alloc] init];
        loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        loadingLabel.text = OALocalizedString(@"loading_purchase_information");
        loadingLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
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

        self.tableView.tableHeaderView = headerView;
    }
    else
    {
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    _purchasesUpdated = NO;
    [self updateLoadingView:YES];
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
}

- (void)onRotation
{
    [self updateLoadingView:self.tableView.tableHeaderView != nil];
}

- (void)onButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *key = item.key;
    if ([key isEqualToString:@"get_osmand_pro"])
        [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
    else if ([key isEqualToString:@"explore_osmand_plans"])
        [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.MONTHLY_MAP_UPDATES navController:self.navigationController];
}

- (void)productPurchased:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void)productPurchaseFailed:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void)productsRestored:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

- (void)productsRequested:(NSNotification *)notification
{
    [self updateViewAfterProductsRequested];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
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
