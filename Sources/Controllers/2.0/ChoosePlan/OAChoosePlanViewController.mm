//
//  OAChoosePlanViewController.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

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
    OAOsmLiveFeaturesCardView *_osmLiveCard;
    OAOsmLivePlansCardView *_purchaseButtonsCard;
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
    return [super initWithNibName:@"OAChoosePlanViewController" bundle:nil];
}

- (void) commonInit
{
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
    [super viewDidLoad];

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
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
    self.navBarView.hidden = self.purchasing;
    self.btnLater.hidden = self.purchasing;
    
    [self setupOsmLiveCardButtons:NO];
    
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
    _navBarView.frame = nf;
    
    CGRect tf = self.titleView.frame;
    self.titleView.frame = CGRectMake(kMargin + correctedX, self.navBarView.hidden ? kMargin : CGRectGetMaxY(nf), correctedWidth - kMargin * 2, titleHeight);
    tf = self.titleView.frame;
    
    CGRect df = self.descriptionView.frame;
    self.descriptionView.frame = CGRectMake(kMargin + correctedX, self.navBarView.hidden ? kMargin : CGRectGetMaxY(tf), correctedWidth - kMargin * 2, descrHeight);
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
    liveFeaturesFrame.origin.y = CGRectGetMaxY(df);
    liveFeaturesFrame.origin.x = correctedX;
    liveFeaturesFrame.size.width = correctedWidth;
    _osmLiveCard.frame = liveFeaturesFrame;
    
    CGRect featuresFrame = CGRectMake(0., -OAUtilities.getStatusBarHeight, DeviceScreenWidth, nf.size.height + nf.origin.y + titleHeight + descrHeight + y);
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

    self.scrollView.contentSize = CGSizeMake(w, CGRectGetMaxY(lbf) + kMargin);
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
        
        OASubscription *monthlyLiveUpdates = _iapHelper.monthlyLiveUpdates;
        double regularMonthlyPrice = monthlyLiveUpdates.price.doubleValue;
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
        OAChoosePlanViewController * __weak weakSelf = self;
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
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:s.formattedPrice buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES discountDescr:@"" showDiscount:NO highDiscount:NO showTopDiv:showTopDiv showBottomDiv:NO onButtonClick:nil];
                
                [_purchaseButtonsCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:14.0] buttonText:OALocalizedString(@"shared_string_cancel") buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES discountDescr:@"" showDiscount:NO highDiscount:NO showTopDiv:NO showBottomDiv:showBottomDiv onButtonClick:^{
                    [weakSelf manageSubscription];
                }];
            }
            else
            {
                BOOL highDiscount = NO;
                BOOL showDiscount = NO;
                NSString *discountStr = nil;
                double monthlyPrice = s.monthlyPrice ? s.monthlyPrice.doubleValue : 0.0;
                if (regularMonthlyPrice > 0 && monthlyPrice > 0 && monthlyPrice < regularMonthlyPrice)
                {
                    int discount = (int) ((1 - monthlyPrice / regularMonthlyPrice) * 100.0);
                    discountStr = [NSString stringWithFormat:@"%d%%", discount];
                    if (discount > 0)
                    {
                        discountStr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_discount_descr"), discountStr];
                        showDiscount = YES;
                        highDiscount = discount > 50;
                    }
                }
                EOAPurchaseDialogCardButtonType buttonType;
                if (self.purchasing)
                    buttonType = ![self.product isEqual:s] ? EOAPurchaseDialogCardButtonTypeDisabled : EOAPurchaseDialogCardButtonTypeExtended;
                else
                    buttonType = anyPurchased ? EOAPurchaseDialogCardButtonTypeRegular : EOAPurchaseDialogCardButtonTypeExtended;
                
                [_purchaseButtonsCard addCardButtonWithTitle:[s getTitle:17.0] description:[s getDescription:15.0] buttonText:s.formattedPrice buttonType:buttonType active:NO discountDescr:discountStr showDiscount:showDiscount highDiscount:highDiscount showTopDiv:showTopDiv showBottomDiv:showBottomDiv onButtonClick:^{
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
