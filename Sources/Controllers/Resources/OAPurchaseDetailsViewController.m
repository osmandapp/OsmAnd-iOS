//
//  OAPurchaseDetailsViewController.m
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPurchaseDetailsViewController.h"
#import "OAValueTableViewCell.h"
#import "OATitleDescriptionBigIconCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OAProducts.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"
#import "OALinks.h"
#import "OASizes.h"
#import "Localization.h"
#import <SafariServices/SafariServices.h>
#import "GeneratedAssetSymbols.h"

#define OSMAND_START @"OsmAnd Start"

@interface OAPurchaseDetailsViewController () <SFSafariViewControllerDelegate>

@end

@implementation OAPurchaseDetailsViewController
{
    OAProduct *_product;
    OATableDataModel *_data;
    OAAppSettings *_settings;
    
    BOOL _isCrossplatform;
    BOOL _isFreeStart;
    BOOL _isPromo;
}

#pragma mark - Initialization

- (instancetype)initForCrossplatformSubscription
{
    self = [super init];
    if (self)
    {
        _isCrossplatform = YES;
        _isPromo = ((EOASubscriptionOrigin) [_settings.proSubscriptionOrigin get]) == EOASubscriptionOriginPromo;
    }
    return self;
}

- (instancetype)initForFreeStartSubscription
{
    self = [super init];
    if (self)
    {
        _isFreeStart = YES;
    }
    return self;
}

- (instancetype)initWithProduct:(OAProduct *)product
{
    self = [super init];
    if (self)
    {
        _product = product;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (_isCrossplatform)
    {
        return _isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro");
    }
    else if (_isFreeStart) {
        return OSMAND_START;
    }
    else
    {
        BOOL isDepthContours = [_product.productIdentifier isEqualToString:kInAppId_Addon_Nautical];
        return isDepthContours ? OALocalizedString(@"rendering_attr_depthContours_name") : _product.localizedTitle;
    }
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_close");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    if (_isCrossplatform)
        [self generateDataForCrossplatform];
    else if (_isFreeStart)
        [self generateDataForFreeStart];
    else
        [self generateDataForProduct];
}

- (void)generateDataForFreeStart
{
    OATableSectionData *productSection = [_data createNewSection];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OATitleDescriptionBigIconCell getCellIdentifier],
        kCellTitleKey : OSMAND_START,
        @"icon" : [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"]
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : OALocalizedString(@"free_account")
    }];
    NSDate *purchasedDate = [NSDate dateWithTimeIntervalSince1970:[OAAppSettings.sharedManager.backupFreePlanRegistrationTime get]];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_purchased"),
        kCellDescrKey : [formatter stringFromDate:purchasedDate]
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : @"-"
    }];
}

- (void)generateDataForProduct
{
    BOOL isSubscription = [_product isKindOfClass:OASubscription.class];
    BOOL isDepthContours = [_product.productIdentifier isEqualToString:kInAppId_Addon_Nautical];

    OATableSectionData *productSection = [_data createNewSection];

    OATableRowData *productRow = [productSection createNewRow];
    productRow.cellType = [OATitleDescriptionBigIconCell getCellIdentifier];
    productRow.title = isDepthContours ? OALocalizedString(@"rendering_attr_depthContours_name") : _product.localizedTitle;
    productRow.descr = !isSubscription && ![OAIAPHelper isFullVersion:_product]
        ? (isDepthContours ? OALocalizedString(@"product_desc_sea_depth_contours") : _product.localizedDescription)
        : @"";
    UIImage *productIcon = [self getIcon];
    if (productIcon)
        [productRow setObj:productIcon forKey:@"icon"];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : isSubscription || [OAIAPHelper isFullVersion:_product]
            ? [_product getTitle:17.].string
            : OALocalizedString(@"in_app_purchase_desc")
    }];

    NSString *purchasedType = OALocalizedString(@"shared_string_purchased");
    if ([_product isKindOfClass:OASubscription.class])
    {
        if (_product.purchaseState == PSTATE_NOT_PURCHASED)
            purchasedType = OALocalizedString(@"expired");
        else if (isSubscription)
            purchasedType = OALocalizedString(@"shared_string_expires");
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    
    NSString *descr = _product.expirationDate ? [formatter stringFromDate:_product.expirationDate] : @"";
    if (_product.purchaseState == PSTATE_NOT_PURCHASED && [_product isKindOfClass:OASubscription.class])
    {
        if (_product.expirationDate)
            descr = [formatter stringFromDate:_product.expirationDate];
        else if (_product.purchaseCancelledTime > 0)
            descr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_product.purchaseCancelledTime]];
    }
    
    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : purchasedType,
        kCellDescrKey : descr
    }];
    
    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : OALocalizedString(@"app_store")
    }];

    if (isSubscription)
    {
        [productSection addRowFromDictionary:@{
            kCellKeyKey: @"manage_subscription",
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"manage_subscription"),
            @"icon" : [UIImage templateImageNamed:@"ic_custom_shop_bag"]
        }];
    }
}

- (void)generateDataForCrossplatform
{
    OATableSectionData *productSection = [_data createNewSection];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OATitleDescriptionBigIconCell getCellIdentifier],
        kCellTitleKey : _isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro"),
        @"icon" : [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"]
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : OALocalizedString(@"subscription")
    }];

    OASubscriptionState *state = [_settings.backupPurchaseState get];
    NSDate *expirationDate = [_settings.backupPurchaseExpireTime get] > 0 ? [NSDate dateWithTimeIntervalSince1970:_settings.backupPurchaseExpireTime.get] : nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : !state.isActive ? OALocalizedString(@"expired") : OALocalizedString(@"shared_string_expires"),
        kCellDescrKey : expirationDate ? [formatter stringFromDate:expirationDate] : @""
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : [self subscripitonOriginToString:(EOASubscriptionOrigin)_settings.proSubscriptionOrigin.get]
    }];
}

- (NSString *)subscripitonOriginToString:(EOASubscriptionOrigin)origin
{
    switch (origin)
    {
        case EOASubscriptionOriginPromo:
            return OALocalizedString(@"promo");
        case EOASubscriptionOriginAndroid:
            return OALocalizedString(@"google_play");
        case EOASubscriptionOriginAmazon:
            return OALocalizedString(@"amazon_appstore");
        case EOASubscriptionOriginHuawei:
            return OALocalizedString(@"huawei_appgallery");
        case EOASubscriptionOriginIOS:
            return OALocalizedString(@"app_store");

        default:
            return @"";
    }
}

- (UIImage *)getIcon
{
    NSString *iconName = _product.productIconName;
    UIImage *icon;
    if ([_product isKindOfClass:OASubscription.class] || [OAIAPHelper isFullVersion:_product])
    {
        icon = [UIImage imageNamed:[iconName stringByAppendingString:@"_big"]];
        if (!icon)
            icon = [UIImage imageNamed:iconName];
    }
    else if (_product.feature)
    {
        icon = [_product.feature getIconBig];
        if (!icon)
            icon = [_product.feature getIcon];
    }
    return icon;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [[_data sectionDataForIndex:section] rowCount];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    UITableViewCell *outCell = nil;
    if ([item.cellType isEqualToString:[OATitleDescriptionBigIconCell getCellIdentifier]])
    {
        OATitleDescriptionBigIconCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionBigIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionBigIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionBigIconCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
            cell.titleView.text = item.title;
            cell.rightIconView.image = [item objForKey:@"icon"];
            cell.descriptionView.text = item.descr;
            [cell showDescription:item.descr && item.descr.length > 0];
        }
        outCell = cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        if (cell)
        {
            BOOL isManageSubscription = [item.key isEqualToString:@"manage_subscription"];
            cell.selectionStyle = isManageSubscription ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            
            UIColor *tintColor = isManageSubscription ? [UIColor colorNamed:ACColorNameTextColorActive] : [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.titleLabel.text = item.title;
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isManageSubscription ? UIFontWeightMedium : UIFontWeightRegular];
            cell.titleLabel.textColor = tintColor;
            cell.valueLabel.text = isManageSubscription ? @"" : item.descr;
            cell.accessoryView = isManageSubscription ? [[UIImageView alloc] initWithImage:[item objForKey:@"icon"]] : nil;
            cell.accessoryView.tintColor = tintColor;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    BOOL isManageSubscription = [item.key isEqualToString:@"manage_subscription"];
    if (isManageSubscription)
    {
        [self presentViewController:[[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:kAppleManageSubscriptions]]
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
