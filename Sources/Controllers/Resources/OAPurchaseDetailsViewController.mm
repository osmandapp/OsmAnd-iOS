//
//  OAPurchaseDetailsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPurchaseDetailsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OATitleDescriptionBigIconCell.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OAProducts.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "OALinks.h"
#import "Localization.h"
#import <SafariServices/SafariServices.h>

@interface OAPurchaseDetailsViewController () <UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation OAPurchaseDetailsViewController
{
    OAProduct *_product;
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
    
    BOOL _isCrossplatform;
    BOOL _isPromo;
}

- (instancetype)initForCrossplatformSubscription
{
    self = [super init];
    if (self) {
        [self commonInit];
        _isCrossplatform = YES;
        _isPromo = ((EOASubscriptionOrigin) [_settings.proSubscriptionOrigin get]) == EOASubscriptionOriginPromo;
        [self generateDataForCrossplatform];
    }
    return self;
}

- (instancetype)initWithProduct:(OAProduct *)product
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _product = product;
        [self generateData];
    }
    return self;
}

- (void) commonInit
{
    _settings = OAAppSettings.sharedManager;
}

- (void)applyLocalization
{
    [super applyLocalization];
    if (_isCrossplatform)
    {
        self.titleView.text = _isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro");
    }
    else
    {
        BOOL isDepthContours = [_product.productIdentifier isEqualToString:kInAppId_Addon_Nautical];
        self.titleView.text = isDepthContours ? OALocalizedString(@"product_title_sea_depth_contours") : _product.localizedTitle;
    }
    [self.backButton setTitle:@"" forState:UIControlStateNormal];
    [self.backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];
    BOOL isSubscription = [_product isKindOfClass:OASubscription.class];
    BOOL isDepthContours = [_product.productIdentifier isEqualToString:kInAppId_Addon_Nautical];

    NSMutableDictionary *productDict = [NSMutableDictionary dictionary];
    productDict[@"type"] = [OATitleDescriptionBigIconCell getCellIdentifier];
    productDict[@"title"] = isDepthContours ? OALocalizedString(@"product_title_sea_depth_contours") : _product.localizedTitle;
    UIImage *icon = [self getIcon];
    if (icon)
        productDict[@"icon"] = icon;
    if (!isSubscription && ![OAIAPHelper isFullVersion:_product])
        productDict[@"description"] = isDepthContours ? OALocalizedString(@"product_desc_sea_depth_contours") : _product.localizedDescription;

    [data addObject:productDict];

    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"res_type"),
            @"description": isSubscription || [OAIAPHelper isFullVersion:_product]
                    ? [_product getTitle:17.].string
                    : OALocalizedString(@"in_app_purchase_desc")
    }];

    NSString *purchasedType = OALocalizedString(@"shared_string_purchased");
    if ([_product isKindOfClass:OASubscription.class])
    {
        if (_product.purchaseState == PSTATE_NOT_PURCHASED)
            purchasedType = OALocalizedString(@"expired");
        else if (isSubscription)
            purchasedType = OALocalizedString(@"expires");
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    
    NSString *descr = _product.expirationDate ? [formatter stringFromDate:_product.expirationDate] : @"";
    if (_product.purchaseState == PSTATE_NOT_PURCHASED && [_product isKindOfClass:OASubscription.class])
    {
        if (_product.expirationDate)
        {
            descr = [formatter stringFromDate:_product.expirationDate];
        }
        else if (_product.purchaseCancelledTime > 0)
        {
            descr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_product.purchaseCancelledTime]];
        }
    }
    
    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": purchasedType,
            @"description": descr
    }];
    
    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"purchase_origin"),
            @"description": OALocalizedString(@"app_store")
    }];

    if (isSubscription)
    {
        [data addObject:@{
                @"key": @"manage_subscription",
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"title": OALocalizedString(@"manage_subscription"),
                @"icon": [UIImage templateImageNamed:@"ic_custom_shop_bag"]
        }];
    }

    _data = data;
}

- (void)generateDataForCrossplatform
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableDictionary *productDict = [NSMutableDictionary dictionary];
    productDict[@"type"] = [OATitleDescriptionBigIconCell getCellIdentifier];
    productDict[@"title"] = _isPromo ? OALocalizedString(@"promo_subscription") : OALocalizedString(@"product_title_pro");
    UIImage *icon = [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"];
    if (icon)
        productDict[@"icon"] = icon;
    

    [data addObject:productDict];

    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"res_type"),
            @"description": OALocalizedString(@"subscription")
    }];

    NSString *purchasedType = @"";
    OASubscriptionState *state = [_settings.backupPurchaseState get];
    if (!state.isActive)
        purchasedType = OALocalizedString(@"expired");
    else
        purchasedType = OALocalizedString(@"expires");

    NSDate *expirationDate = [_settings.backupPurchaseExpireTime get] > 0 ? [NSDate dateWithTimeIntervalSince1970:_settings.backupPurchaseExpireTime.get] : nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;

    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": purchasedType,
            @"description": expirationDate ? [formatter stringFromDate:expirationDate] : @""
    }];

    [data addObject:@{
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"title": OALocalizedString(@"purchase_origin"),
            @"description": _isPromo ? OALocalizedString(@"promo") : OALocalizedString(@"google_play")
    }];

    _data = data;
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

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"key"] isEqualToString:@"product"])
        return estimated ? 66. : UITableViewAutomaticDimension;
    return UITableViewAutomaticDimension;
}

- (void)openSafariWithURL:(NSString *)url
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [self presentViewController:safariViewController animated:YES completion:nil];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    UITableViewCell *outCell = nil;
    if ([cellType isEqualToString:[OATitleDescriptionBigIconCell getCellIdentifier]])
    {
        OATitleDescriptionBigIconCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionBigIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionBigIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionBigIconCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell showDescription:[item.allKeys containsObject:@"description"]];

            cell.titleView.text = item[@"title"];
            cell.descriptionView.text = item[@"description"];
            cell.iconView.image = item[@"icon"];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            cell.descriptionView.textColor = UIColor.blackColor;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(
                    0.,
                    [_product isKindOfClass:OASubscription.class] && [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row + 1 ? 0. : 20.,
                    0.,
                    0.
            );

            BOOL isManageSubscription = [item[@"key"] isEqualToString:@"manage_subscription"];
            cell.selectionStyle = isManageSubscription ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            [cell showRightIcon:isManageSubscription];

            UIColor *tintColor = isManageSubscription ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer);
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:isManageSubscription ? UIFontWeightMedium : UIFontWeightRegular];
            cell.textView.textColor = tintColor;
            cell.descriptionView.text = isManageSubscription ? @"" : item[@"description"];
            cell.rightIconView.image = item[@"icon"];
            cell.rightIconView.tintColor = tintColor;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:YES];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    BOOL isManageSubscription = [item[@"key"] isEqualToString:@"manage_subscription"];
    if (isManageSubscription)
        [self openSafariWithURL:kAppleManageSubscriptions];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
