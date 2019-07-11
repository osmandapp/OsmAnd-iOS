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
#import "OAFirebaseHelper.h"
#import "OADonationSettingsViewController.h"
#import "OARootViewController.h"
#import "OAOsmLiveFeaturesCardView.h"

#define kMargin 16.0
#define kTextMargin 18.0
#define kTextBorderH 32.0

@interface OAChooseOsmLivePlanViewController ()

@end

@implementation OAChooseOsmLivePlanViewController
{
    OAIAPHelper *_iapHelper;
    OAOsmLiveFeaturesCardView *_osmLiveCard;
    OAOsmLivePlansCardView *_purchaseButtonsCard;
}

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;
@synthesize btnBack = _btnBack, scrollView = _scrollView, cardsContainer = _cardsContainer, navBarView = _navBarView;

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
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
    
    _iapHelper = [OAIAPHelper sharedInstance];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"osmand_live_title");
    self.descriptionView.text = OALocalizedString(@"get_osmand_live");
    [self.btnRestore setTitle:OALocalizedString(@"restore") forState:UIControlStateNormal];
    self.lbPublicInfo.text = OALocalizedString(@"subscriptions_public_info");
    [self.btnTermsOfUse setTitle:OALocalizedString(@"terms_of_use") forState:UIControlStateNormal];
    [self.btnPrivacyPolicy setTitle:OALocalizedString(@"privacy_policy") forState:UIControlStateNormal];
    [self.btnLater setTitle:OALocalizedString(@"shared_string_later") forState:UIControlStateNormal];
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
    CALayer *bl = self.btnLater.layer;
    bl.cornerRadius = 9;
    bl.shadowColor = UIColor.blackColor.CGColor;
    bl.shadowOpacity = 0.2;
    bl.shadowRadius = 1.5;
    bl.shadowOffset = CGSizeMake(0.0, 0.5);
    bl.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnLater setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    CALayer *termsLayer = self.btnTermsOfUse.layer;
    termsLayer.cornerRadius = 9.0;
    termsLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnTermsOfUse setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    CALayer *privacyLayer = self.btnPrivacyPolicy.layer;
    privacyLayer.cornerRadius = 9.0;
    privacyLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
    [self.btnPrivacyPolicy setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    
    _osmLiveCard = [self buildOsmLiveCard];
    [self.featuresView addSubview:_osmLiveCard];
    _purchaseButtonsCard = [[OAOsmLivePlansCardView alloc] initWithFrame:{0, 0, 300, 200}];
    [self.cardsContainer addSubview:_purchaseButtonsCard];
    
    [_btnBack setTintColor:UIColor.whiteColor];
    [_btnBack setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
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
    nf.origin.y = OAUtilities.getStatusBarHeight;
    nf.origin.x = correctedX;
    nf.size.width = correctedWidth;
    self.navBarView.frame = nf;
    
    CGRect tf = self.titleView.frame;
    self.titleView.frame = CGRectMake(kMargin + correctedX, self.navBarView.hidden ? kMargin : CGRectGetMaxY(nf), correctedWidth - kMargin * 2, titleHeight);
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
    liveFeaturesFrame.origin.y = CGRectGetMaxY(df) + kMargin;
    liveFeaturesFrame.origin.x = correctedX;
    liveFeaturesFrame.size.width = correctedWidth;
    _osmLiveCard.frame = liveFeaturesFrame;
    
    CGRect featuresFrame = CGRectMake(0., -OAUtilities.getStatusBarHeight, DeviceScreenWidth, nf.size.height + nf.origin.y + titleHeight + descrHeight + y + kTextMargin + kMargin);
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
    cf.origin.y =  CGRectGetMaxY(featuresFrame) + 1.0;
    cf.origin.x = correctedX;
    cf.size.height = y;
    cf.size.width = correctedWidth;
    self.cardsContainer.frame = cf;

    CGFloat publicInfoWidth = correctedWidth - kMargin * 2;
    CGFloat buttonSpacing = 21;
    CGFloat publicInfoHeight = [OAUtilities calculateTextBounds:self.lbPublicInfo.text width:publicInfoWidth font:self.lbPublicInfo.font].height;
    self.lbPublicInfo.frame = CGRectMake(0, 0, publicInfoWidth, publicInfoHeight + 8);
    CGRect pf = self.lbPublicInfo.frame;
    self.btnTermsOfUse.frame = CGRectMake(0, CGRectGetMaxY(pf) + buttonSpacing, (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect tosf = self.btnTermsOfUse.frame;
    self.btnPrivacyPolicy.frame = CGRectMake(CGRectGetMaxX(tosf) + buttonSpacing, CGRectGetMaxY(pf) + buttonSpacing, (publicInfoWidth - buttonSpacing) / 2, 32);
    CGRect ppf = self.btnPrivacyPolicy.frame;

    self.publicInfoContainer.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(cf) + kMargin, publicInfoWidth, CGRectGetMaxY(ppf));
    CGRect pif = self.publicInfoContainer.frame;

    CGRect lbf = self.btnLater.frame;
    self.btnLater.frame = CGRectMake(kMargin + correctedX, CGRectGetMaxY(pif) + 35., correctedWidth - kMargin * 2, lbf.size.height);
    lbf = self.btnLater.frame;
    if (self.btnLater.hidden)
        lbf.size.height = 0;
    
    UIImage *img = [UIImage imageNamed:@"img_background_plans.png"];
    CGFloat scale = MIN(img.size.height / _backgroundImageView.frame.size.height, img.size.width / _backgroundImageView.frame.size.width);
    _backgroundImageView.image = [UIImage imageWithCGImage:img.CGImage scale:scale orientation:UIImageOrientationUp];

    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(lbf) + kMargin);
}

- (IBAction)restoreButtonPressed:(id)sender
{
    [[OARootViewController instance] restorePurchasesWithProgress:NO];
    [[OARootViewController instance] requestProductsWithProgress:YES reload:YES];
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
        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"ic_live_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName textColor:UIColor.whiteColor image:image selected:NO showDivider:NO];
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
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:s.formattedPrice buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES showTopDiv:showTopDiv showBottomDiv:NO onButtonClick:nil];
                
                [_purchaseButtonsCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:15.0] buttonText:OALocalizedString(@"shared_string_cancel") buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES showTopDiv:NO showBottomDiv:showBottomDiv onButtonClick:^{
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
                
                BOOL hasSpecialOffer = discountOffer;
                buttonType = hasSpecialOffer ? EOAPurchaseDialogCardButtonTypeOffer : buttonType;
                
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:hasSpecialOffer ? [[NSAttributedString alloc] initWithString:discountOffer.getDescriptionTitle attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}] : [s getDescription:15.0] buttonText:hasSpecialOffer ? discountOffer.getShortDescription : s.formattedPrice buttonType:buttonType active:NO showTopDiv:showTopDiv showBottomDiv:showBottomDiv onButtonClick:^{
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

@end
