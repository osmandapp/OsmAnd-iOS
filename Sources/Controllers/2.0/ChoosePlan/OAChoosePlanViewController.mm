//
//  OAChoosePlanViewController.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanViewController.h"
#import "OAChoosePlanHelper.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAIAPHelper.h"
#import "OAOsmLiveCardView.h"
#import "OAPurchaseCardView.h"
#import "OAColors.h"
#import "OAFirebaseHelper.h"
#import "OADonationSettingsViewController.h"
#import "OARootViewController.h"

#define kMargin 16.0
#define kTextBorderH 32.0

@interface OAFeature()

@property (nonatomic) EOAFeature value;

@end

@implementation OAFeature

- (instancetype) initWithFeature:(EOAFeature)feature
{
    self = [super init];
    if (self)
    {
        self.value = feature;
    }
    return self;
}

- (NSString *) toHumanString
{
    switch (self.value)
    {
        case EOAFeatureWikivoyageOffline:
            return OALocalizedString(@"wikivoyage_offline");
        case EOAFeatureDailyMapUpdates:
            return OALocalizedString(@"daily_map_updates");
        case EOAFeatureMonthlyMapUpdates:
            return OALocalizedString(@"monthly_map_updates");
        case EOAFeatureUnlimitedDownloads:
            return OALocalizedString(@"unlimited_downloads");
        case EOAFeatureWikipediaOffline:
            return OALocalizedString(@"wikipedia_offline");
        case EOAFeatureContourLinesHillshadeMaps:
            return OALocalizedString(@"contour_lines_hillshade_maps");
        case EOAFeatureSeaDepthMaps:
            return OALocalizedString(@"index_item_depth_contours_osmand_ext");
        case EOAFeatureDonationToOSM:
            return OALocalizedString(@"donation_to_osm");
        case EOAFeatureUnlockAllFeatures:
            return OALocalizedString(@"unlock_all_features");
        case EOAFeatureSkiMap:
            return OALocalizedString(@"product_title_skimap");
        case EOAFeatureNautical:
            return OALocalizedString(@"product_title_nautical");
        case EOAFeatureParking:
            return OALocalizedString(@"product_title_parking");
        case EOAFeatureTripRecording:
            return OALocalizedString(@"product_title_track_recording");
        case EOAFeatureRegionAfrica:
            return OALocalizedString(@"product_desc_africa");
        case EOAFeatureRegionRussia:
            return OALocalizedString(@"product_desc_russia");
        case EOAFeatureRegionAsia:
            return OALocalizedString(@"product_desc_asia");
        case EOAFeatureRegionAustralia:
            return OALocalizedString(@"product_desc_australia");
        case EOAFeatureRegionEurope:
            return OALocalizedString(@"product_desc_europe");
        case EOAFeatureRegionCentralAmerica:
            return OALocalizedString(@"product_desc_centralamerica");
        case EOAFeatureRegionNorthAmerica:
            return OALocalizedString(@"product_desc_northamerica");
        case EOAFeatureRegionSouthAmerica:
            return OALocalizedString(@"product_desc_southamerica");
        default:
            return @"";
    }
}

- (UIImage *) getImage
{
    switch (self.value)
    {
        case EOAFeatureWikivoyageOffline:
            return [UIImage imageNamed:@"ic_live_wikivoyage"];
        case EOAFeatureDailyMapUpdates:
            return [UIImage imageNamed:@"ic_custom_timer"];
        case EOAFeatureMonthlyMapUpdates:
            return [UIImage imageNamed:@"ic_live_monthly_updates"];
        case EOAFeatureUnlimitedDownloads:
        case EOAFeatureRegionAfrica:
        case EOAFeatureRegionRussia:
        case EOAFeatureRegionAsia:
        case EOAFeatureRegionAustralia:
        case EOAFeatureRegionEurope:
        case EOAFeatureRegionCentralAmerica:
        case EOAFeatureRegionNorthAmerica:
        case EOAFeatureRegionSouthAmerica:
            return [UIImage imageNamed:@"ic_custom_unlimited_downloads"];
        case EOAFeatureWikipediaOffline:
            return [UIImage imageNamed:@"ic_custom_wikipedia"];
        case EOAFeatureContourLinesHillshadeMaps:
            return [UIImage imageNamed:@"ic_custom_contour_lines"];
        case EOAFeatureSeaDepthMaps:
            return [UIImage imageNamed:@"ic_action_bearing"];
        case EOAFeatureDonationToOSM:
            return nil;
        case EOAFeatureUnlockAllFeatures:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureSkiMap:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureNautical:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureParking:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureTripRecording:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        default:
            return nil;
    }
}

- (BOOL) isFeaturePurchased
{
    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    if (helper.subscribedToLiveUpdates)
        return YES;
    
    switch (self.value)
    {
        case EOAFeatureDailyMapUpdates:
        case EOAFeatureDonationToOSM:
        case EOAFeatureMonthlyMapUpdates:
        case EOAFeatureUnlockAllFeatures:
            return NO;
        case EOAFeatureUnlimitedDownloads:
            return [helper.allWorld isPurchased];
        case EOAFeatureRegionAfrica:
            return [helper.africa isPurchased];
        case EOAFeatureRegionRussia:
            return [helper.russia isPurchased];
        case EOAFeatureRegionAsia:
            return [helper.asia isPurchased];
        case EOAFeatureRegionAustralia:
            return [helper.australia isPurchased];
        case EOAFeatureRegionEurope:
            return [helper.europe isPurchased];
        case EOAFeatureRegionCentralAmerica:
            return [helper.centralAmerica isPurchased];
        case EOAFeatureRegionNorthAmerica:
            return [helper.northAmerica isPurchased];
        case EOAFeatureRegionSouthAmerica:
            return [helper.southAmerica isPurchased];
        case EOAFeatureWikipediaOffline:
            return [helper.wiki isPurchased];
        case EOAFeatureWikivoyageOffline:
            return NO;//[helper.wikivoyage isPurchased];
        case EOAFeatureSeaDepthMaps:
            return NO;//[helper.seaDepth isPurchased];
        case EOAFeatureContourLinesHillshadeMaps:
            return [helper.srtm isPurchased];
        case EOAFeatureSkiMap:
            return [helper.skiMap isPurchased];
        case EOAFeatureNautical:
            return [helper.nautical isPurchased];
        case EOAFeatureParking:
            return [helper.parking isPurchased];
        case EOAFeatureTripRecording:
            return [helper.trackRecording isPurchased];
        default:
            return NO;
    }
}

- (BOOL) isFeatureFree
{
    OAProduct *p = [self getFeatureProduct];
    return p && p.free;
}

- (BOOL) isFeatureAvailable
{
    switch (self.value)
    {
        case EOAFeatureDailyMapUpdates:
        case EOAFeatureDonationToOSM:
        case EOAFeatureMonthlyMapUpdates:
        case EOAFeatureUnlockAllFeatures:
            return YES;
        default:
        {
            OAProduct *p = [self getFeatureProduct];
            return p != nil;
        }
    }
}

- (OAProduct *) getFeatureProduct
{
    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    switch (self.value)
    {
        case EOAFeatureUnlimitedDownloads:
            return helper.allWorld;
        case EOAFeatureRegionAfrica:
            return helper.africa;
        case EOAFeatureRegionRussia:
            return helper.russia;
        case EOAFeatureRegionAsia:
            return helper.asia;
        case EOAFeatureRegionAustralia:
            return helper.australia;
        case EOAFeatureRegionEurope:
            return helper.europe;
        case EOAFeatureRegionCentralAmerica:
            return helper.centralAmerica;
        case EOAFeatureRegionNorthAmerica:
            return helper.northAmerica;
        case EOAFeatureRegionSouthAmerica:
            return helper.southAmerica;
        case EOAFeatureWikipediaOffline:
            return helper.wiki;
        case EOAFeatureWikivoyageOffline:
            return nil;//helper.wikivoyage;
        case EOAFeatureSeaDepthMaps:
            return nil;//helper.seaDepth;
        case EOAFeatureContourLinesHillshadeMaps:
            return helper.srtm;
        case EOAFeatureSkiMap:
            return helper.skiMap;
        case EOAFeatureNautical:
            return helper.nautical;
        case EOAFeatureParking:
            return helper.parking;
        case EOAFeatureTripRecording:
            return helper.trackRecording;
        default:
            return nil;
    }
}

@end

@interface OAChoosePlanViewController ()

@end

@implementation OAChoosePlanViewController
{
    OAIAPHelper *_iapHelper;
    OAOsmLiveCardView *_osmLiveCard;
    OAPurchaseCardView *_planTypeCard;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:!nibNameOrNil ? @"OAChoosePlanViewController" : nibNameOrNil bundle:nil];
}

- (void) commonInit
{
    _iapHelper = [OAIAPHelper sharedInstance];
}

- (void) applyLocalization
{
}

- (UIImage *) getPlanTypeHeaderImage
{
    return [UIImage imageNamed:@"img_logo_38dp_osmand"];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return nil; // not implemented
}

- (NSString *) getPlanTypeHeaderDescription
{
    return OALocalizedString(@"in_app_purchase");
}

- (NSString *) getPlanTypeButtonTitle
{
    OAProduct *product = [self.class getPlanTypeProduct];
    if (product)
    {
        if ([product isPurchased])
            return product.formattedPrice;
        else
            return [NSString stringWithFormat:OALocalizedString(@"purchase_unlim_title"), product.formattedPrice];
    }
    return @"";
}

- (NSString *) getPlanTypeButtonDescription
{
    return OALocalizedString(@"in_app_purchase_desc");
}

- (void) setPlanTypeButtonClickListener:(UIButton *)button
{
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(onPlanTypeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) onPlanTypeButtonClick:(id)sender
{
    [OAFirebaseHelper logEvent:@"in_app_purchase_redirect_from_choose_plan"];
    [[OARootViewController instance] buyProduct:[self.class getPlanTypeProduct] showProgress:YES];
}

+ (OAProduct *) getPlanTypeProduct;
{
    return nil; // not implemented
}

- (BOOL) hasSelectedOsmLiveFeature:(OAFeature *)feature
{
    NSArray<OAFeature *> *features = self.selectedOsmLiveFeatures;
    if (features)
        for (OAFeature *f in features)
            if (feature.value == f.value)
                return YES;

    return NO;
}

- (BOOL) hasSelectedPlanTypeFeature:(OAFeature *)feature
{
    NSArray<OAFeature *> *features = self.selectedPlanTypeFeatures;
    if (features)
        for (OAFeature *f in features)
            if (feature.value == f.value)
                return YES;

    return NO;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _planTypeCard = [self buildPlanTypeCard];
    [self.cardsContainer addSubview:_planTypeCard];
    
    _osmLiveCard = [self buildOsmLiveCard];
    [self.cardsContainer addSubview:_osmLiveCard];
    
    [_btnBack setTintColor:UIColorFromRGB(color_primary_purple)];
    [_btnBack setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
    self.navBarView.hidden = self.purchasing;
    
    [self setupOsmLiveCardButtons:NO];
    [self setupPlanTypeCardButtons:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];

    [[OARootViewController instance] requestProductsWithProgress:YES reload:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) viewWillLayoutSubviews
{
    CGRect frame = self.scrollView.frame;
    CGFloat w = frame.size.width;
    if (@available(iOS 11.0, *))
    {
         w -= self.scrollView.safeAreaInsets.left + self.scrollView.safeAreaInsets.right;
        self.scrollView.contentInset = UIEdgeInsetsMake(0, self.scrollView.safeAreaInsets.left, 0, self.scrollView.safeAreaInsets.right);
    }

    CGRect nf = self.navBarView.frame;

    CGFloat y = 0;
    CGFloat cw = w - kMargin * 2;
    for (UIView *v in self.cardsContainer.subviews)
    {
        if ([v isKindOfClass:[OAPurchaseDialogItemView class]])
        {
            OAPurchaseDialogItemView *card = (OAPurchaseDialogItemView *)v;
            CGRect crf = [card updateFrame:cw];
            crf.origin.y = y;
            card.frame = crf;
            y += crf.size.height + kMargin;
        }
    }
    if (y > 0)
        y -= kMargin;
    
    CGRect cf = self.cardsContainer.frame;
    cf.origin.y =  CGRectGetMaxY(nf) + kMargin;
    cf.size.height = y;
    cf.size.width = cw;
    self.cardsContainer.frame = cf;

    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(cf) + kMargin);
}

- (IBAction) backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) plansPricesPressed:(id)sender
{
    [OAChoosePlanHelper showChoosePlanScreenWithProduct:nil navController:self.navigationController purchasing:self.purchasing];
}

- (OAOsmLiveCardView *) buildOsmLiveCard
{
    OAOsmLiveCardView *cardView = [[OAOsmLiveCardView alloc] initWithFrame:{0, 0, 300, 200}];
    cardView.lbTitle.text = OALocalizedString(@"osmand_live_title");
    cardView.lbDescription.text = OALocalizedString(@"osm_live_subscription");
    [cardView.plansPricesButton addTarget:self action:@selector(plansPricesPressed:) forControlEvents:UIControlEventTouchUpInside];

    BOOL firstRow = YES;
    for (OAFeature *feature in self.osmLiveFeatures)
    {
        if (![feature isFeatureAvailable] || [feature isFeatureFree])
            continue;
        
        NSString *featureName = [feature toHumanString];
        BOOL selected = [self hasSelectedOsmLiveFeature:feature];
        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName image:image selected:selected showDivider:!firstRow];
        if (firstRow)
            firstRow = NO;
    }
    return firstRow ? nil : cardView;
}

- (OAPurchaseCardView *) buildPlanTypeCard
{
    if (self.planTypeFeatures.count == 0)
        return nil;
    
    NSString *headerTitle = [self getPlanTypeHeaderTitle];
    NSString *headerDescr = [self getPlanTypeHeaderDescription];

    OAPurchaseCardView *cardView = [[OAPurchaseCardView alloc] initWithFrame:{0, 0, 300, 200}];
    [cardView setupCardWithTitle:headerTitle description:headerDescr buttonDescription:OALocalizedString(@"in_app_purchase_desc_ex")];

    
    for (OAFeature *feature in self.planTypeFeatures)
    {
        if (![feature isFeatureAvailable] || [feature isFeatureFree])
            continue;

        NSString *featureName = [feature toHumanString];
        BOOL selected = [self hasSelectedOsmLiveFeature:feature];
        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName image:image selected:selected showDivider:NO];
    }
    
    return (!self.planTypeFeatures || self.planTypeFeatures.count == 0) ? nil : cardView;
}

- (void) manageSubscription
{
    if (!self.purchasing)
    {
        NSURL *url = [NSURL URLWithString:@"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"];
        if ([[UIApplication sharedApplication] canOpenURL:url])
            [[UIApplication sharedApplication] openURL:url];
    }
}

- (void) subscribe:(OASubscription *)subscriptipon
{
    if (!self.purchasing)
        [[OARootViewController instance] buyProduct:subscriptipon showProgress:YES];
}

- (void) setupOsmLiveCardButtons:(BOOL)progress
{
    if (progress)
    {
        [_osmLiveCard setProgressVisibile:YES];
        [self.view setNeedsLayout];
        return;
    }
    else
    {
        for (UIView *v in _osmLiveCard.buttonsContainer.subviews)
            [v removeFromSuperview];
        
        NSArray<OASubscription *> *visibleSubscriptions = [_iapHelper.liveUpdates getVisibleSubscriptions];
        OASubscription *s;
        BOOL anyPurchased = NO;
        for (OASubscription *subscription in visibleSubscriptions)
        {
            if ([subscription isPurchased])
                anyPurchased = YES;
            if ([subscription isKindOfClass:OALiveUpdatesAnnual.class])
                s = subscription;
        }
        if (!s)
            s = visibleSubscriptions.firstObject;
        
        BOOL purchased = NO;
        OAChoosePlanViewController * __weak weakSelf = self;
        purchased = [s isPurchased];
        
        BOOL showTopDiv = NO;
        BOOL showBottomDiv = NO;
        if (purchased)
        {
            showTopDiv = YES;
            showBottomDiv = NO;
        }
        else
        {
            showTopDiv = NO;
        }
        
        if (purchased)
        {
            [_osmLiveCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:s.formattedPrice buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES showTopDiv:showTopDiv showBottomDiv:NO onButtonClick:nil];
            
            [_osmLiveCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:15.0] buttonText:OALocalizedString(@"shared_string_cancel") buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES showTopDiv:NO showBottomDiv:showBottomDiv onButtonClick:^{
                [weakSelf manageSubscription];
            }];
        }
        else
        {
            EOAPurchaseDialogCardButtonType buttonType;
            if (self.purchasing)
                buttonType = ![self.product isEqual:s] ? EOAPurchaseDialogCardButtonTypeDisabled : EOAPurchaseDialogCardButtonTypeExtended;
            else
                buttonType = anyPurchased ? EOAPurchaseDialogCardButtonTypeRegular : EOAPurchaseDialogCardButtonTypeExtended;
            
            OAAppSettings *settings = [OAAppSettings sharedManager];
            OAProductDiscount *discountOffer;
            if (settings.eligibleForIntroductoryPrice)
                discountOffer = s.introductoryPrice;
            else if (settings.eligibleForSubscriptionOffer)
            {
                if (s.discounts && s.discounts.count > 0)
                    discountOffer = s.discounts[0];
            }
            
            BOOL hasSpecialOffer = discountOffer != nil;
            buttonType = hasSpecialOffer ? EOAPurchaseDialogCardButtonTypeOffer : buttonType;
            
            [_osmLiveCard addCardButtonWithTitle:[s getTitle:17.0] description:hasSpecialOffer ? [[NSAttributedString alloc] initWithString:discountOffer.getDescriptionTitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}] : [s getDescription:15.0] buttonText:hasSpecialOffer ? discountOffer.getShortDescription : s.formattedPrice buttonType:buttonType active:NO showTopDiv:showTopDiv showBottomDiv:showBottomDiv onButtonClick:^{
                [weakSelf subscribe:s];
            }];
        }
    }
    [_osmLiveCard setProgressVisibile:NO];
    [self.view setNeedsLayout];
}

- (void) setupPlanTypeCardButtons:(BOOL)progress
{
    if (_planTypeCard)
    {
        OAProduct *product = [self.class getPlanTypeProduct];
        BOOL purchased = product && [product isPurchased];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;

        NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:[self getPlanTypeButtonTitle]];
        [titleStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium] range:NSMakeRange(0, titleStr.length)];
        [titleStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, titleStr.length)];
        NSMutableAttributedString *subtitleStr = [[NSMutableAttributedString alloc] initWithString:[self getPlanTypeButtonDescription]];
        [subtitleStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular] range:NSMakeRange(0, subtitleStr.length)];
        [subtitleStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, subtitleStr.length)];
        if (progress)
        {
            [_planTypeCard setProgressVisibile:YES];
            [_planTypeCard setupCardButtonEnabled:YES buttonText:[[NSAttributedString alloc] initWithString:@" \n "] buttonClickHandler:nil];
        }
        else
        {
            NSMutableAttributedString *buttonText = [[NSMutableAttributedString alloc] initWithString:@""];
            [_planTypeCard setProgressVisibile:NO];
            if (!purchased)
            {
                [titleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:NSMakeRange(0, titleStr.length)];
                [subtitleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:NSMakeRange(0, subtitleStr.length)];
                [buttonText appendAttributedString:titleStr];
                [buttonText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                [buttonText appendAttributedString:subtitleStr];
                [_planTypeCard setupCardButtonEnabled:YES buttonText:buttonText buttonClickHandler:nil];
                if (!self.purchasing)
                    [self setPlanTypeButtonClickListener:_planTypeCard.cardButton];
            }
            else
            {
                [titleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_secondary_text_blur) range:NSMakeRange(0, titleStr.length)];
                [subtitleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_secondary_text_blur) range:NSMakeRange(0, subtitleStr.length)];
                [buttonText appendAttributedString:titleStr];
                [buttonText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                [buttonText appendAttributedString:subtitleStr];
                [_planTypeCard setupCardButtonEnabled:NO buttonText:buttonText buttonClickHandler:nil];
            }
        }
    }
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    if (self.purchasing)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupOsmLiveCardButtons:NO];
        [self setupPlanTypeCardButtons:NO];
    });
}

@end
