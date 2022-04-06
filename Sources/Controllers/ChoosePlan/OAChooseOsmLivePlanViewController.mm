//
//  OAChooseOsmLivePlanViewController.m
//  OsmAnd
//
//  Created by Paul on 06/07/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAChooseOsmLivePlanViewController.h"
#import "OAChoosePlanViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAIAPHelper.h"
#import "OAOsmLivePlansCardView.h"
#import "OAPurchaseCardView.h"
#import "OAColors.h"
#import "OAAnalyticsHelper.h"
#import "OADonationSettingsViewController.h"
#import "OARootViewController.h"
#import "OAOsmLiveFeaturesCardView.h"

#define kMargin 16.0
#define kTextMargin 18.0
#define kTextBorderH 32.0
#define kNavBarHeight 54.0

@interface OAChooseOsmLivePlanViewController () <UIScrollViewDelegate>

@end

@implementation OAChooseOsmLivePlanViewController
{
    OAIAPHelper *_iapHelper;
    OAOsmLiveFeaturesCardView *_osmLiveCard;
    OAOsmLivePlansCardView *_purchaseButtonsCard;
    
    UIView *_navBarBackgroundView;
}

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;
@synthesize btnBack = _btnBack, scrollView = _scrollView, cardsContainer = _cardsContainer, navBarView = _navBarView;
@synthesize btnLater = _btnLater, publicInfoContainer = _publicInfoContainer, lbPublicInfo = _lbPublicInfo;
@synthesize btnTermsOfUse = _btnTermsOfUse, btnPrivacyPolicy = _btnPrivacyPolicy;
@synthesize restorePurchasesBottomButton = _restorePurchasesBottomButton;

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
    return [super initWithNibName:@"OAChooseOsmLivePlanViewController" bundle:nil];
}

- (void) commonInit
{
    _osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWeather],
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
    
    _iapHelper = [OAIAPHelper sharedInstance];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"osmand_live_title");
    self.descriptionView.text = OALocalizedString(@"get_osmand_live");
    [self.btnRestore setTitle:OALocalizedString(@"restore") forState:UIControlStateNormal];
    [super applyLocalization];
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
    [OAAnalyticsHelper logEvent:@"in_app_purchase_redirect_from_choose_plan"];
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
    self.scrollView.delegate = self;
    
    [self setupBottomButton:self.btnLater];
    [self setupBottomButton:self.restorePurchasesBottomButton];
    
    CALayer *termsLayer = self.btnTermsOfUse.layer;
    termsLayer.cornerRadius = 4.0;
    termsLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnTermsOfUse setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    CALayer *privacyLayer = self.btnPrivacyPolicy.layer;
    privacyLayer.cornerRadius = 4.0;
    privacyLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnPrivacyPolicy setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    _osmLiveCard = [self buildOsmLiveCard];
    [self.featuresView addSubview:_osmLiveCard];
    _purchaseButtonsCard = [[OAOsmLivePlansCardView alloc] initWithFrame:{0, 0, 300, 200}];
    [self.cardsContainer addSubview:_purchaseButtonsCard];
    
    [_btnBack setTintColor:UIColor.whiteColor];
    [_btnBack setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = _navBarView.bounds;
    _navBarBackgroundView.alpha = 0.0;
    [_navBarView insertSubview:_navBarBackgroundView atIndex:0];
    if (!UIAccessibilityIsReduceTransparencyEnabled())
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self applyLocalization];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) viewWillLayoutSubviews
{
    CGRect frame = self.scrollView.frame;
    CGFloat w = frame.size.width;

    CGFloat correctedWidth = w - (OAUtilities.getLeftMargin * 2);
    CGFloat correctedX = OAUtilities.getLeftMargin;
    
    CGFloat descrHeight = [OAUtilities calculateTextBounds:self.descriptionView.text width:correctedWidth - kTextBorderH * 2 font:self.descriptionView.font].height;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:self.titleView.text width:correctedWidth - kTextBorderH * 2 font:self.titleView.font].height;
    CGRect nf = self.navBarView.frame;
    nf.size.width = w;
    CGFloat statusBarCorrection = 0;
    if (@available(iOS 13.0, *)) {
        nf.size.height = kNavBarHeight;
    }
    else {
        statusBarCorrection = OAUtilities.getStatusBarHeight;
        nf.size.height = statusBarCorrection + kNavBarHeight;
    }
    self.navBarView.frame = nf;
    
    CGFloat maxRestoreButtonWidth = correctedWidth / 2;
    CGSize buttonSize = [OAUtilities calculateTextBounds:self.btnRestore.titleLabel.text width:maxRestoreButtonWidth font:self.btnRestore.titleLabel.font];
    CGFloat buttonHeight = self.btnRestore.frame.size.height;
    self.btnRestore.frame = CGRectMake(w - correctedX - kMargin - MIN(maxRestoreButtonWidth, buttonSize.width), nf.size.height - kNavBarHeight / 2 - buttonHeight / 2, MIN(maxRestoreButtonWidth, buttonSize.width), buttonHeight);
    
    CGFloat backBtnHeight = self.btnBack.frame.size.height;
    self.btnBack.frame = CGRectMake(correctedX + 8.0, nf.size.height - kNavBarHeight / 2 - backBtnHeight / 2, self.btnBack.frame.size.width, backBtnHeight);
    
    CGRect tf = self.titleView.frame;
    self.titleView.frame = CGRectMake(kMargin + correctedX, nf.size.height, correctedWidth - kMargin * 2, titleHeight);
    tf = self.titleView.frame;
    
    CGRect df = self.descriptionView.frame;
    self.descriptionView.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(tf) + kTextMargin, correctedWidth - kMargin * 2, descrHeight);
    df = self.descriptionView.frame;
    
    CGFloat y = 0;
    for (UIView *v in self.featuresView.subviews)
    {
        if ([v isKindOfClass:[OAPurchaseDialogItemView class]])
        {
            OAPurchaseDialogItemView *card = (OAPurchaseDialogItemView *)v;
            CGRect crf = [card updateFrame:correctedWidth];
            crf.origin.y = y;
            card.frame = crf;
            y += crf.size.height + kMargin;
        }
    }
    
    CGRect liveFeaturesFrame = _osmLiveCard.frame;
    liveFeaturesFrame.origin.y = CGRectGetMaxY(df) + 2.0;
    liveFeaturesFrame.origin.x = correctedX;
    liveFeaturesFrame.size.width = correctedWidth;
    _osmLiveCard.frame = liveFeaturesFrame;
    
    CGRect featuresFrame = CGRectMake(0., -statusBarCorrection, DeviceScreenWidth, nf.size.height + nf.origin.y + titleHeight + descrHeight + y + kTextMargin + kMargin);
    _featuresView.frame = featuresFrame;

    y = 0;
    for (UIView *v in self.cardsContainer.subviews)
    {
        if ([v isKindOfClass:[OAPurchaseDialogItemView class]])
        {
            OAPurchaseDialogItemView *card = (OAPurchaseDialogItemView *)v;
            CGRect crf = [card updateFrame:correctedWidth];
            crf.origin.y = y;
            card.frame = crf;
            y += crf.size.height + kMargin;
        }
    }
    if (y > 0)
        y -= kMargin;
    
    CGRect cf = self.cardsContainer.frame;
    cf.origin.y =  CGRectGetMaxY(featuresFrame);
    cf.origin.x = correctedX;
    cf.size.height = y;
    cf.size.width = correctedWidth;
    self.cardsContainer.frame = cf;

    CGFloat publicInfoWidth = correctedWidth - kMargin * 2;
    CGFloat buttonSpacing = 21;
    // Use bigger font size to compensate the line spacing
    CGFloat bh = [OAUtilities calculateTextBounds:self.lbPublicInfo.attributedText.string width:publicInfoWidth font:[UIFont systemFontOfSize:18]].height;
    self.lbPublicInfo.frame = CGRectMake(0, 0, publicInfoWidth, bh);
    CGRect pf = self.lbPublicInfo.frame;
    self.btnTermsOfUse.frame = CGRectMake(0, CGRectGetMaxY(pf), (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect tosf = self.btnTermsOfUse.frame;
    self.btnPrivacyPolicy.frame = CGRectMake(CGRectGetMaxX(tosf) + buttonSpacing, CGRectGetMaxY(pf), (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect ppf = self.btnPrivacyPolicy.frame;

    self.publicInfoContainer.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(cf), publicInfoWidth, CGRectGetMaxY(ppf));
    CGRect pif = self.publicInfoContainer.frame;
    
    CGRect rbf = self.restorePurchasesBottomButton.frame;
    self.restorePurchasesBottomButton.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(pif) + 35., correctedWidth - kMargin * 2, rbf.size.height);
    rbf = self.restorePurchasesBottomButton.frame;
    if (self.restorePurchasesBottomButton.hidden)
        rbf.size.height = 0;

    CGRect lbf = self.btnLater.frame;
    self.btnLater.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(rbf) + kMargin, correctedWidth - kMargin * 2, lbf.size.height);
    lbf = self.btnLater.frame;
    if (self.btnLater.hidden)
        lbf.size.height = 0;
    
    UIImage *img = [UIImage imageNamed:@"img_background_plans.png"];
    CGFloat scale = MIN(img.size.height / _backgroundImageView.frame.size.height, img.size.width / _backgroundImageView.frame.size.width);
    _backgroundImageView.image = [UIImage imageWithCGImage:img.CGImage scale:scale orientation:UIImageOrientationUp];

    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(lbf) + kMargin);
}

- (IBAction)bottomRestorePressed:(id)sender
{
    [[OARootViewController instance] requestProductsWithProgress:YES reload:YES restorePurchases:YES];
}

- (IBAction)restoreButtonPressed:(id)sender
{
    [[OARootViewController instance] requestProductsWithProgress:YES reload:YES restorePurchases:YES];
}

- (IBAction) termsOfUseButtonClicked:(id)sender
{
    [OAUtilities callUrl:@"https://osmand.net/help-online/terms-of-use"];
}

- (IBAction) privacyPolicyButtonClicked:(id)sender
{
    [OAUtilities callUrl:@"https://osmand.net/help-online/privacy-policy"];
}

- (IBAction) backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (OAOsmLiveFeaturesCardView *) buildOsmLiveCard
{
    OAOsmLiveFeaturesCardView *cardView = [[OAOsmLiveFeaturesCardView alloc] initWithFrame:{0, 0, 300, 200}];
    
    BOOL firstRow = YES;
    for (OAFeature *feature in self.osmLiveFeatures)
    {
        if (![feature isFeatureAvailable] || [feature isFeatureFree])
            continue;
        
        NSString *featureName = [feature toHumanString];
//        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName textColor:UIColor.whiteColor image:[feature getImage] selected:NO showDivider:NO];
        if (firstRow)
            firstRow = NO;
    }
    return firstRow ? nil : cardView;
}

- (void) setupOsmLiveCardButtons:(BOOL)progress
{
    if (progress)
    {
        [_purchaseButtonsCard setProgressVisibile:YES];
        [self.view setNeedsLayout];
        return;
    }
    else
    {
        for (UIView *v in _purchaseButtonsCard.buttonsContainer.subviews)
            [v removeFromSuperview];
        
        NSArray<OASubscription *> *visibleSubscriptions = [_iapHelper.liveUpdates getVisibleSubscriptions];
        NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]};
        BOOL anyPurchased = NO;
        for (OASubscription *s in visibleSubscriptions)
        {
            if ([s isPurchased])
            {
                anyPurchased = YES;
                break;
            }
        }
        BOOL firstRow = YES;
        BOOL purchased = NO;
        BOOL prevPurchased = NO;
        BOOL nextPurchased = NO;
        OAChooseOsmLivePlanViewController * __weak weakSelf = self;
        for (NSInteger i = 0; i < visibleSubscriptions.count; i++)
        {
            OASubscription *s = [visibleSubscriptions objectAtIndex:i];
            OASubscription *next = nil;
            if (i < visibleSubscriptions.count - 1)
                next = [visibleSubscriptions objectAtIndex:i + 1];
            
            purchased = [s isPurchased];
            nextPurchased = [next isPurchased];
            
            BOOL showTopDiv = NO;
            BOOL showBottomDiv = NO;
            if (purchased)
            {
                showTopDiv = !prevPurchased;
                showBottomDiv = next != nil;
            }
            else
            {
                showTopDiv = !prevPurchased && !firstRow;
            }
            
            if (purchased)
            {
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:[[NSAttributedString alloc] initWithString:s.formattedPrice attributes:attributes] buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES showTopDiv:showTopDiv showBottomDiv:NO onButtonClick:nil];
                
                [_purchaseButtonsCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:15.0] buttonText:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_cancel_subscription") attributes:attributes] buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES showTopDiv:NO showBottomDiv:showBottomDiv onButtonClick:^{
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
                
                NSMutableAttributedString *descr = [[NSMutableAttributedString alloc] initWithString:@""];
                if ([s isKindOfClass:OALiveUpdatesMonthly.class] && hasSpecialOffer)
                {
                    [descr appendAttributedString:[s getDescription:15.0]];
                    [descr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                    [descr appendAttributedString:[[NSAttributedString alloc] initWithString:discountOffer.getDescriptionTitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}]];
                }
                else
                {
                    [descr appendAttributedString:hasSpecialOffer ? [[NSAttributedString alloc]
                                                                     initWithString:discountOffer.getDescriptionTitle
                                                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}]
                                                 : [s getDescription:15.0]];
                }
                
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:descr buttonText:hasSpecialOffer ? discountOffer.getFormattedDescription : [[NSAttributedString alloc] initWithString:s.formattedPrice attributes:attributes] buttonType:buttonType active:NO showTopDiv:showTopDiv showBottomDiv:showBottomDiv onButtonClick:^{
                    [weakSelf subscribe:s];
                }];
            }
            if (firstRow)
                firstRow = NO;
            
            prevPurchased = purchased;
        }
    }
    [_purchaseButtonsCard setProgressVisibile:NO];
    [self.view setNeedsLayout];
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
    });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = (_scrollView.contentOffset.y / (_scrollView.contentSize.height - _scrollView.frame.size.height));
    _navBarBackgroundView.alpha = alpha;
    CGRect container = CGRectMake(_scrollView.contentOffset.x, _scrollView.contentOffset.y, _scrollView.frame.size.width, _scrollView.frame.size.height);
    BOOL isOnWhite = !CGRectIntersectsRect(_featuresView.frame, container);
    if ((alpha > 0.2 && _btnRestore.titleLabel.textColor != UIColor.whiteColor) || isOnWhite)
    {
        [_btnRestore setTitleColor:isOnWhite ? UIColorFromRGB(color_primary_purple) : UIColor.whiteColor forState:UIControlStateNormal];
        [_btnBack setTintColor:isOnWhite ? UIColorFromRGB(color_primary_purple) : UIColor.whiteColor];
    }
    else if (alpha <= 0.2 && _btnRestore.titleLabel.textColor != UIColorFromRGB(color_tint_gray))
    {
        [_btnRestore setTitleColor:UIColorFromRGB(color_tint_gray) forState:UIControlStateNormal];
        [_btnBack setTintColor:UIColor.whiteColor];
    }
    if (_scrollView.contentOffset.y <= -OAUtilities.getStatusBarHeight)
    {
        _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x, -OAUtilities.getStatusBarHeight);
    }
}

@end
