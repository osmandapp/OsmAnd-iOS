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
#import "OATextCardView.h"
#import "OAAnalyticsHelper.h"
#import "OADonationSettingsViewController.h"
#import "OARootViewController.h"

#define kMargin 16.0
#define kTextBorderH 32.0
#define kNavBarHeight 54.0

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
        case EOAFeatureWeather:
            return OALocalizedString(@"product_title_weather");
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
            return [UIImage imageNamed:@"ic_custom_timer"];
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
            return [UIImage imageNamed:@"ic_custom_boat"];
        case EOAFeatureParking:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureTripRecording:
            return [UIImage imageNamed:@"ic_live_osmand_logo"];
        case EOAFeatureWeather:
            return [UIImage imageNamed:@"ic_custom_umbrella"];
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
        case EOAFeatureWeather:
            return [helper.weather isPurchased];
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
        case EOAFeatureWeather:
            return helper.weather;
        default:
            return nil;
    }
}

@end

@interface OAChoosePlanViewController () <UIScrollViewDelegate>

@end

@implementation OAChoosePlanViewController
{
    OAIAPHelper *_iapHelper;
    OAOsmLiveCardView *_osmLiveCard;
    OAPurchaseCardView *_planTypeCard;
    OATextCardView *_introTextCard;
    
    UIView *_navBarBackgroundView;
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
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    self.lbPublicInfo.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"subscriptions_public_info") attributes:@{NSParagraphStyleAttributeName : style}];
    [self.btnTermsOfUse setTitle:OALocalizedString(@"terms_of_use") forState:UIControlStateNormal];
    [self.btnPrivacyPolicy setTitle:OALocalizedString(@"privacy_policy") forState:UIControlStateNormal];
    [self.btnLater setTitle:OALocalizedString(@"shared_string_later") forState:UIControlStateNormal];
    [self.restorePurchasesBottomButton setTitle:OALocalizedString(@"restore_all_purchases") forState:UIControlStateNormal];
}

- (UIImage *) getPlanTypeHeaderImage
{
    return [UIImage imageNamed:@"img_logo_38dp_osmand"];
}

- (NSString *) getPlanTypeTopText
 {
     return nil; // not implemented
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
        return product.formattedPrice;
    
    return @"";
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return nil; // not implemented
}

- (NSString *) getPlanTypeButtonDescription
{
    return OALocalizedString(@"in_app_purchase_desc");
}

//- (void) setPlanTypeButtonClickListener:(UIButton *)button
//{
//    [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
//    [button addTarget:self action:@selector(onPlanTypeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
//}

- (IBAction) onPlanTypeButtonClick:(id)sender
{
    if (!_purchasing)
    {
        [OAAnalyticsHelper logEvent:@"in_app_purchase_redirect_from_choose_plan"];
        [[OARootViewController instance] buyProduct:[self.class getPlanTypeProduct] showProgress:YES];
    }
}

- (IBAction)termsOfUseButtonClicked:(id)sender
{
    [OAUtilities callUrl:@"https://osmand.net/help-online/terms-of-use"];
}

- (IBAction)privacyPolicyButtonClicked:(id)sender
{
    [OAUtilities callUrl:@"https://osmand.net/help-online/privacy-policy"];
}

- (IBAction)bottomRestorePressed:(id)sender
{
    [[OARootViewController instance] requestProductsWithProgress:YES reload:YES restorePurchases:YES];
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
    
    CALayer *termsLayer = self.btnTermsOfUse.layer;
    termsLayer.cornerRadius = 4.0;
    termsLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnTermsOfUse setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    CALayer *privacyLayer = self.btnPrivacyPolicy.layer;
    privacyLayer.cornerRadius = 4.0;
    privacyLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnPrivacyPolicy setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    [self setupBottomButton:self.btnLater];
    [self setupBottomButton:self.restorePurchasesBottomButton];
    
    _scrollView.delegate = self;
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = _navBarView.bounds;
    _navBarBackgroundView.alpha = 0.0;
    [_navBarView insertSubview:_navBarBackgroundView atIndex:0];
    if (!UIAccessibilityIsReduceTransparencyEnabled())
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    NSString *introText = [self getPlanTypeTopText];
    if (introText)
    {
        _introTextCard = [self buildTextCard: introText];
        [self.cardsContainer addSubview:_introTextCard];
    }

    _planTypeCard = [self buildPlanTypeCard];
    [self.cardsContainer addSubview:_planTypeCard];
    
    _osmLiveCard = [self buildOsmLiveCard];
    [self.cardsContainer addSubview:_osmLiveCard];
    
    [_btnBack setTintColor:UIColorFromRGB(color_primary_purple)];
    [_btnBack setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
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
    w -= self.scrollView.safeAreaInsets.left + self.scrollView.safeAreaInsets.right;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, self.scrollView.safeAreaInsets.left, 0, self.scrollView.safeAreaInsets.right);

    CGRect nf = self.navBarView.frame;
    nf.size.width = frame.size.width;
    if (@available(iOS 13.0, *)) {
        nf.size.height = kNavBarHeight;
    }
    else {
        nf.size.height = OAUtilities.getStatusBarHeight + kNavBarHeight;
    }
    self.navBarView.frame = nf;

    CGFloat backBtnHeight = self.btnBack.frame.size.height;
    self.btnBack.frame = CGRectMake(OAUtilities.getLeftMargin + 8.0, nf.size.height - kNavBarHeight / 2 - backBtnHeight / 2, self.btnBack.frame.size.width, backBtnHeight);

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
    cf.origin.y =  kNavBarHeight + kMargin;
    cf.size.height = y;
    cf.size.width = cw;
    self.cardsContainer.frame = cf;
    
    CGFloat publicInfoWidth = w - kMargin * 2;
    CGFloat buttonSpacing = 21;
    // Use bigger font size to compensate the line spacing
    CGFloat bh = [OAUtilities calculateTextBounds:self.lbPublicInfo.attributedText.string width:publicInfoWidth font:[UIFont systemFontOfSize:18]].height;
    self.lbPublicInfo.frame = CGRectMake(0, 0, publicInfoWidth, bh);
    CGRect pf = self.lbPublicInfo.frame;
    self.btnTermsOfUse.frame = CGRectMake(0, CGRectGetMaxY(pf), (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect tosf = self.btnTermsOfUse.frame;
    self.btnPrivacyPolicy.frame = CGRectMake(CGRectGetMaxX(tosf) + buttonSpacing, CGRectGetMaxY(pf), (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect ppf = self.btnPrivacyPolicy.frame;
    
    self.publicInfoContainer.frame = CGRectMake(kMargin, CGRectGetMaxY(cf), publicInfoWidth, CGRectGetMaxY(ppf));
    CGRect pif = self.publicInfoContainer.frame;
    
    CGRect rbf = self.restorePurchasesBottomButton.frame;
    self.restorePurchasesBottomButton.frame = CGRectMake(kMargin, CGRectGetMaxY(pif) + 35., publicInfoWidth, rbf.size.height);
    rbf = self.restorePurchasesBottomButton.frame;
    if (self.restorePurchasesBottomButton.hidden)
        rbf.size.height = 0;
    
    CGRect lbf = self.btnLater.frame;
    self.btnLater.frame = CGRectMake(kMargin, CGRectGetMaxY(rbf) + kMargin, publicInfoWidth, lbf.size.height);
    lbf = self.btnLater.frame;
    if (self.btnLater.hidden)
        lbf.size.height = 0;

    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(lbf) + kMargin);
}

- (void)setupBottomButton:(UIButton *)button
{
    CALayer *bl = button.layer;
    bl.cornerRadius = 9.0;
    bl.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [button setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
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

    for (OAFeature *feature in self.osmLiveFeatures)
    {
        if (![feature isFeatureAvailable] || [feature isFeatureFree])
            continue;
        
        NSString *featureName = [feature toHumanString];
        BOOL selected = [self hasSelectedOsmLiveFeature:feature];
//        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName image:[feature getImage] selected:selected showDivider:NO];
    }
    return (!self.osmLiveFeatures || self.osmLiveFeatures.count == 0) ? nil : cardView;
}

- (OAPurchaseCardView *) buildPlanTypeCard
{
    if (self.planTypeFeatures.count == 0)
        return nil;
    
    NSString *headerTitle = [self getPlanTypeHeaderTitle];
    NSString *headerDescr = [self getPlanTypeHeaderDescription];

    OAPurchaseCardView *cardView = [[OAPurchaseCardView alloc] initWithFrame:{0, 0, 300, 200}];
    [cardView setupCardWithTitle:headerTitle description:headerDescr buttonTitle:[self getPlanTypeButtonDescription] buttonDescription:[self getPlanTypeButtonHeaderText]];

    
    for (OAFeature *feature in self.planTypeFeatures)
    {
        if (![feature isFeatureAvailable] || [feature isFeatureFree])
            continue;

        NSString *featureName = [feature toHumanString];
        BOOL selected = [self hasSelectedOsmLiveFeature:feature];
//        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName image:[feature getImage] selected:selected showDivider:NO];
    }
    
    return (!self.planTypeFeatures || self.planTypeFeatures.count == 0) ? nil : cardView;
}

- (OATextCardView *) buildTextCard:(NSString *)text
 {
     OATextCardView *cardView = [[OATextCardView alloc] initWithFrame:{0, 0, 300, 200}];
     cardView.textLabel.text = text;
     return cardView;
 }

- (UIView *) createNavBarBackgroundView
{
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurEffectView.alpha = 0;
        return blurEffectView;
        
    }
    else
    {
        UIView *res = [[UIView alloc] init];
        res.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        res.backgroundColor = UIColorFromRGB(color_primary_purple);
        res.alpha = 0;
        return res;
    }
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
        
        NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]};
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
            [_osmLiveCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:[[NSAttributedString alloc] initWithString:s.formattedPrice attributes:attributes] buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES showTopDiv:showTopDiv showBottomDiv:NO onButtonClick:nil];
            
            [_osmLiveCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:15.0] buttonText:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_cancel_subscription") attributes:attributes] buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES showTopDiv:NO showBottomDiv:showBottomDiv onButtonClick:^{
                [weakSelf manageSubscription];
            }];
        }
        else
        {
            EOAPurchaseDialogCardButtonType buttonType;
            if (self.purchasing)
                buttonType = ![self.product isEqual:s] ? EOAPurchaseDialogCardButtonTypeDisabled : EOAPurchaseDialogCardButtonTypeExtended;
            else
                buttonType = EOAPurchaseDialogCardButtonTypeRegular;
            
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
            
            [_osmLiveCard addCardButtonWithTitle:[s getTitle:17.0] description:hasSpecialOffer ? [[NSAttributedString alloc] initWithString:discountOffer.getDescriptionTitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}] : [s getDescription:15.0] buttonText:hasSpecialOffer ? discountOffer.getFormattedDescription : [[NSAttributedString alloc] initWithString:s.formattedPrice attributes:attributes] buttonType:buttonType active:NO showTopDiv:showTopDiv showBottomDiv:showBottomDiv onButtonClick:^{
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
        [titleStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold] range:NSMakeRange(0, titleStr.length)];
        [titleStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, titleStr.length)];
        if (progress)
        {
            [_planTypeCard setProgressVisibile:YES];
            [_planTypeCard setupCardButtonEnabled:YES buttonText:[[NSAttributedString alloc] initWithString:@" \n "] buttonClickHandler:^{
                [self onPlanTypeButtonClick:_planTypeCard.cardButton];
            }];
        }
        else
        {
            NSMutableAttributedString *buttonText = [[NSMutableAttributedString alloc] initWithString:@""];
            [_planTypeCard setProgressVisibile:NO];
            if (!purchased)
            {
                [titleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:NSMakeRange(0, titleStr.length)];
                [buttonText appendAttributedString:titleStr];

                [_planTypeCard setupCardButtonEnabled:YES buttonText:buttonText buttonClickHandler:^{
                    [self onPlanTypeButtonClick:_planTypeCard.cardButton];
                }];
//                if (!self.purchasing)
//                    [self setPlanTypeButtonClickListener:_planTypeCard.cardButton];
            }
            else
            {
                [titleStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_secondary_text_blur) range:NSMakeRange(0, titleStr.length)];
                [buttonText appendAttributedString:titleStr];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = _scrollView.contentOffset.y < 0 ? 0 : (_scrollView.contentOffset.y / (_scrollView.contentSize.height - _scrollView.frame.size.height));
    _navBarBackgroundView.alpha = alpha;
}

@end
