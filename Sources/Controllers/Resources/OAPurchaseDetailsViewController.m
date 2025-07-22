//
//  OAPurchaseDetailsViewController.m
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPurchaseDetailsViewController.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
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
    EOAPurchaseOrigin _origin;
    NSDate *_purchaseDate;
    NSDate *_expireDate;

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
        _origin = (EOAPurchaseOrigin) [_settings.proSubscriptionOrigin get];
        _isPromo = _origin == EOAPurchaseOriginPromo;
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

- (instancetype)initWithProduct:(OAProduct *)product origin:(EOAPurchaseOrigin)origin purchaseDate:(NSDate *)purchaseDate expireDate:(NSDate *)expireDate
{
    self = [super init];
    if (self)
    {
        _product = product;
        _origin = origin;
        _purchaseDate = purchaseDate;
        _expireDate = expireDate;
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

- (void)registerCells
{
    for (NSString *identifier in @[[OAValueTableViewCell reuseIdentifier],
                                   [OARightIconTableViewCell reuseIdentifier],
                                   [OATitleDescriptionBigIconCell reuseIdentifier]])
        [self addCell:identifier];
}

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
        kCellTypeKey : [OATitleDescriptionBigIconCell reuseIdentifier],
        kCellTitleKey : OSMAND_START,
        @"icon" : [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"]
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : OALocalizedString(@"free_account")
    }];
    NSDate *purchasedDate = [NSDate dateWithTimeIntervalSince1970:[OAAppSettings.sharedManager.backupFreePlanRegistrationTime get]];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_purchased"),
        kCellDescrKey : [formatter stringFromDate:purchasedDate]
    }];

    [productSection addRowFromDictionary:@{
        kCellKeyKey : @"purchase_origin",
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : @"-"
    }];
}

- (void)generateDataForProduct
{
    BOOL isSubscription = [self isSubscription];
    BOOL isDepthContours = [_product.productIdentifier isEqualToString:kInAppId_Addon_Nautical];

    OATableSectionData *productSection = [_data createNewSection];

    OATableRowData *productRow = [productSection createNewRow];
    productRow.cellType = [OATitleDescriptionBigIconCell reuseIdentifier];
    productRow.title = isDepthContours ? OALocalizedString(@"rendering_attr_depthContours_name") : _product.localizedTitle;
    productRow.descr = !isSubscription && ![OAIAPHelper isFullVersion:_product]
        ? (isDepthContours ? OALocalizedString(@"product_desc_sea_depth_contours") : _product.localizedDescription)
        : @"";
    UIImage *productIcon = [self getIcon];
    if (productIcon)
        [productRow setObj:productIcon forKey:@"icon"];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : isSubscription || [OAIAPHelper isFullVersion:_product]
            ? [_product getTitle:17.].string
            : OALocalizedString(@"in_app_purchase_desc")
    }];

    NSString *purchasedType = OALocalizedString(@"shared_string_purchased");
    NSDate *date = nil;
    if ([self isSubscription])
    {
        if (_product.purchaseState == PSTATE_NOT_PURCHASED)
            purchasedType = OALocalizedString(@"expired");
        else if (isSubscription)
            purchasedType = OALocalizedString(@"shared_string_expires");
        date = !_expireDate ? _product.expirationDate : _expireDate;
    }
    else if (_expireDate)
    {
        purchasedType = [[NSDate date] earlierDate:_expireDate]
            ? OALocalizedString(@"shared_string_expires")
            : OALocalizedString(@"expired");
        date = _expireDate;
    }
    else
    {
        date = _purchaseDate;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    
    NSString *descr = date ? [formatter stringFromDate:date] : @"";
    if (_product.purchaseState == PSTATE_NOT_PURCHASED && [self isSubscription])
    {
        if (_product.expirationDate)
            descr = [formatter stringFromDate:_product.expirationDate];
        else if (_product.purchaseCancelledTime > 0)
            descr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_product.purchaseCancelledTime]];
    }
    
    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : purchasedType,
        kCellDescrKey : descr
    }];
    
    [productSection addRowFromDictionary:@{
        kCellKeyKey : @"purchase_origin",
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : [self purchaseOriginToString:_origin]
    }];
    
    if ([self isOriginFastSpring])
        [self generateDataForFastSpringForSection:productSection];
    else if (isSubscription && _origin == EOAPurchaseOriginIOS)
        [self generateManageSubscriptionForSection:productSection];
}

- (void)generateDataForCrossplatform
{
    OATableSectionData *productSection = [_data createNewSection];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OATitleDescriptionBigIconCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(_isPromo ? @"promo_subscription" : @"product_title_pro"),
        @"icon" : [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"]
    }];

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_type"),
        kCellDescrKey : OALocalizedString(@"subscription")
    }];

    OASubscriptionState *state = [_settings.backupPurchaseState get];
    NSDate *expirationDate = [_settings.backupPurchaseExpireTime get] > 0 ? [NSDate dateWithTimeIntervalSince1970:_settings.backupPurchaseExpireTime.get] : nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;

    [productSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(!state.isActive ? @"expired" : @"shared_string_expires"),
        kCellDescrKey : expirationDate ? [formatter stringFromDate:expirationDate] : @""
    }];

    [productSection addRowFromDictionary:@{
        kCellKeyKey : @"purchase_origin",
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString(@"purchase_origin"),
        kCellDescrKey : [self purchaseOriginToString:_origin]
    }];
    
    if ([self isOriginFastSpring])
        [self generateDataForFastSpringForSection:productSection];
}

- (void)generateDataForFastSpringForSection:(OATableSectionData *)section
{
    [section addRowFromDictionary:@{
        kCellKeyKey : @"fastspring_desc",
        kCellTypeKey : [OARightIconTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString([self isSubscription] ? @"fastspring_subscription_desc" : @"fastspring_one_time_payment_desc"),
    }];
    
    [self generateManageSubscriptionForSection:section];
}

- (void)generateManageSubscriptionForSection:(OATableSectionData *)section
{
    [section addRowFromDictionary:@{
        kCellKeyKey: @"manage_subscription",
        kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
        kCellTitleKey : OALocalizedString([self isOriginFastSpring] && ![self isSubscription] ? @"manage_purchases" : @"manage_subscription"),
        kCellIconKey : [UIImage templateImageNamed:@"ic_custom_shop_bag"]
    }];
}

- (NSString *)purchaseOriginToString:(EOAPurchaseOrigin)origin
{
    switch (origin)
    {
        case EOAPurchaseOriginPromo:
            return OALocalizedString(@"promo");
        case EOAPurchaseOriginAndroid:
            return OALocalizedString(@"google_play");
        case EOAPurchaseOriginAmazon:
            return OALocalizedString(@"amazon_appstore");
        case EOAPurchaseOriginHuawei:
            return OALocalizedString(@"huawei_appgallery");
        case EOAPurchaseOriginIOS:
            return OALocalizedString(@"app_store");
        case EOAPurchaseOriginFastSpring:
            return OALocalizedString(@"osmand_web");

        default:
            return @"";
    }
}

- (BOOL)isOriginFastSpring
{
    return _origin == EOAPurchaseOriginFastSpring;
}

- (BOOL)isSubscription
{
    return [_product isKindOfClass:OASubscription.class];
}

- (UIImage *)getIcon
{
    NSString *iconName = _product.productIconName;
    UIImage *icon;
    if ([self isSubscription] || [_product isFullVersion] || [_product isKindOfClass:OAExternalProduct.class])
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
    if ([item.cellType isEqualToString:[OATitleDescriptionBigIconCell reuseIdentifier]])
    {
        OATitleDescriptionBigIconCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionBigIconCell reuseIdentifier]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell showLeftIcon:NO];
        [cell showRightIcon:YES];
        cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
        cell.titleView.text = item.title;
        cell.rightIconView.image = [item objForKey:@"icon"];
        cell.descriptionView.text = item.descr;
        [cell showDescription:item.descr && item.descr.length > 0];
        outCell = cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell reuseIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell reuseIdentifier]];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightRegular];
        cell.titleLabel.text = item.title;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell rightIconVisibility:NO];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell reuseIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell reuseIdentifier]];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        BOOL isManageSubscription = [item.key isEqualToString:@"manage_subscription"];
        cell.selectionStyle = isManageSubscription ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        
        if ([self isOriginFastSpring])
        {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
            if (nextIndexPath)
            {
                OATableRowData *nextItem = [_data itemForIndexPath:nextIndexPath];
                if (nextItem && [nextItem.key isEqualToString:@"fastspring_desc"])
                {
                    [cell setCustomLeftSeparatorInset:YES];
                    cell.separatorInset = UIEdgeInsetsZero;
                }
            }
        }
        
        UIColor *tintColor = [UIColor colorNamed:isManageSubscription ? ACColorNameTextColorActive : ACColorNameTextColorSecondary];
        cell.titleLabel.text = item.title;
        cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isManageSubscription ? UIFontWeightMedium : UIFontWeightRegular];
        cell.titleLabel.textColor = tintColor;
        
        if ([item.key isEqualToString:@"purchase_origin"])
        {
            CGSize textSize = [cell.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: cell.titleLabel.font}];
            [cell setActiveTitleWidthGreaterThanEqualConstraint:false];
            [cell setActiveTitleWidthEqualConstraint:true];
            [cell setTitleWidthEqualConstraintValue:textSize.width];
        }
        
        cell.valueLabel.text = isManageSubscription ? @"" : item.descr;
        cell.accessoryView = isManageSubscription ? [[UIImageView alloc] initWithImage:[item objForKey:kCellIconKey]] : nil;
        cell.accessoryView.tintColor = tintColor;
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
        [self presentViewController:[[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[self isOriginFastSpring] ? kFastSpringManage : kAppleManageSubscriptions]]
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
