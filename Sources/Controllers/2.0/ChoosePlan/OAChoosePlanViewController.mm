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
#import "OAOsmLiveCardView.h"

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
            return [UIImage imageNamed:@"ic_live_map_updates"];
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
            return [UIImage imageNamed:@"ic_live_unlimited_downloads"];
        case EOAFeatureWikipediaOffline:
            return [UIImage imageNamed:@"ic_live_wikipedia"];
        case EOAFeatureContourLinesHillshadeMaps:
            return [UIImage imageNamed:@"ic_live_srtm"];
        case EOAFeatureSeaDepthMaps:
            return [UIImage imageNamed:@"ic_live_nautical_depth"];
        case EOAFeatureDonationToOSM:
            return nil;
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
            return NO;
        case EOAFeatureSeaDepthMaps:
            return [helper.nautical isPurchased];
        case EOAFeatureContourLinesHillshadeMaps:
            return [helper.srtm isPurchased];
        default:
            return NO;
    }
}

@end

@interface OAChoosePlanViewController ()

@end

@implementation OAChoosePlanViewController
{
    OAIAPHelper *_iapHelper;
    OAOsmLiveCardView *_osmLiveCard;
}

- (instancetype)init
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
    self.lbTitle.text = OALocalizedString(@"purchase_dialog_title");
    self.lbDescription.text = [self getInfoDescription];
    [self.btnLater setTitle:OALocalizedString(@"shared_string_later") forState:UIControlStateNormal];
}

- (NSString *) getInfoDescription
{
    return [[[NSString stringWithFormat:OALocalizedString(@"free_version_message"), [OAIAPHelper freeMapsAvailable]] stringByAppendingString:@"\n"] stringByAppendingString:OALocalizedString(@"get_osmand_live")];
}

- (NSArray<OAFeature *> *) getOsmLiveFeatures
{
    return nil; // not implemented
}

- (NSArray<OAFeature *> *) getPlanTypeFeatures
{
    return nil; // not implemented
}

- (NSArray<OAFeature *> *) getSelectedOsmLiveFeatures
{
    return nil; // not implemented
}

- (NSArray<OAFeature *> *) getSelectedPlanTypeFeatures
{
    return nil; // not implemented
}

- (UIImage *) getPlanTypeHeaderImage
{
    return nil; // not implemented
}

- (NSString *) getPlanTypeHeaderTitle
{
    return nil; // not implemented
}

- (NSString *) getPlanTypeHeaderDescription
{
    return nil; // not implemented
}

- (NSString *) getPlanTypeButtonTitle
{
    OAProduct *product = [self getPlanTypeProduct];
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
    return nil; // not implemented
}

- (void) setPlanTypeButtonClickListener:(UIButton *)button
{
    // not implemented
}

- (OAProduct * _Nullable) getPlanTypeProduct;
{
    return nil; // not implemented
}

- (BOOL) hasSelectedOsmLiveFeature:(OAFeature *)feature
{
    NSArray<OAFeature *> *features = [self getSelectedOsmLiveFeatures];
    if (features)
        for (OAFeature *f in features)
            if (feature.value == f.value)
                return YES;

    return NO;
}

- (BOOL) hasSelectedPlanTypeFeature:(OAFeature *)feature
{
    NSArray<OAFeature *> *features = [self getSelectedPlanTypeFeatures];
    if (features)
        for (OAFeature *f in features)
            if (feature.value == f.value)
                return YES;

    return NO;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _osmLiveCard = [self buildOsmLiveCard];
    [self.cardsContainer addSubview:_osmLiveCard];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) viewWillLayoutSubviews
{
    CGRect frame = self.scrollView.frame;
    
    CGFloat w = frame.size.width;
    CGFloat descrHeight = [OAUtilities calculateTextBounds:self.lbDescription.text width:w - kTextBorderH * 2 font:self.lbDescription.font].height;
    CGRect nf = self.navBarView.frame;
    CGRect df = self.lbDescription.frame;
    self.lbDescription.frame = CGRectMake(kTextBorderH, nf.origin.y + nf.size.height, w - kTextBorderH * 2, descrHeight + kMargin);
    df = self.lbDescription.frame;

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
            y += crf.size.height;
        }
    }
    CGRect cf = self.cardsContainer.frame;
    cf.origin.y =  df.origin.y + df.size.height + kMargin;
    cf.size.height = y;
    cf.size.width = cw;
    self.cardsContainer.frame = cf;
    
    CGRect lbf = self.btnLater.frame;
    self.btnLater.frame = CGRectMake(kMargin, cf.origin.y + cf.size.height + kMargin, w - kMargin * 2, lbf.size.height);
}

- (IBAction) backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (OAOsmLiveCardView *) buildOsmLiveCard
{
    OAOsmLiveCardView *cardView = [[OAOsmLiveCardView alloc] initWithFrame:{0, 0, 300, 200}];
    cardView.lbTitle.text = OALocalizedString(@"osmand_live_title");
    cardView.lbDescription.text = OALocalizedString(@"osm_live_subscription");

    //View featureRowDiv = null;
    for (OAFeature *feature in [self getOsmLiveFeatures])
    {
        NSString *featureName = [feature toHumanString];
        BOOL selected = [self hasSelectedOsmLiveFeature:feature];
        UIImage *image = [feature isFeaturePurchased] ? [UIImage imageNamed:@"img_feature_purchased"] : [feature getImage];
        [cardView addInfoRowWithText:featureName image:image selected:selected];
        //featureRowDiv = featureRow.findViewById(R.id.div);
        //LinearLayout.LayoutParams p = (LinearLayout.LayoutParams) featureRowDiv.getLayoutParams();
        //p.rightMargin = AndroidUtils.dpToPx(ctx, 1f);
        //featureRowDiv.setLayoutParams(p);
        //rowsContainer.addView(featureRow);
    }
    //if (featureRowDiv != null) {
    //    featureRowDiv.setVisibility(View.GONE);
    //}
    return cardView;
}

- (void) manageSubscription
{
    //https://apps.apple.com/account/subscriptions
}

- (void) subscribe:(OASubscription *)subscriptipon
{
    
}

- (void) setupOsmLiveCardButtons:(BOOL)progress
{
    if (progress)
    {
        [_osmLiveCard setProgressVisibile:YES];
    }
    else
    {
        for (UIView *v in _osmLiveCard.buttonsContainer.subviews)
            [v removeFromSuperview];
        
        OAPurchaseDialogCardButton *lastBtn = nil;
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
        OAChoosePlanViewController * __weak weakSelf = self;
        for (OASubscription *s in visibleSubscriptions)
        {
            if ([s isPurchased])
            {
                [_osmLiveCard addCardButtonWithTitle:[s getTitle:16.0] description:[s getDescription:14.0] buttonText:s.formattedPrice buttonType:EOAPurchaseDialogCardButtonTypeDisabled active:YES discountDescr:@"" showDiscount:NO highDiscount:NO onButtonClick:nil];
                //divTop.setVisibility(View.VISIBLE);
                //div.setVisibility(View.VISIBLE);
                //divBottom.setVisibility(View.GONE);
                
                OAPurchaseDialogCardButton* buttonCancel = [_osmLiveCard addCardButtonWithTitle:[[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_current_subscription")] description:[s getRenewDescription:14.0] buttonText:OALocalizedString(@"shared_string_cancel") buttonType:EOAPurchaseDialogCardButtonTypeExtended active:YES discountDescr:@"" showDiscount:NO highDiscount:NO onButtonClick:^{
                    [weakSelf manageSubscription];
                }];
                //divTop.setVisibility(View.GONE);
                //div.setVisibility(View.GONE);
                //divBottom.setVisibility(View.VISIBLE);
                
                if (lastBtn)
                {
                    /*
                    View lastBtnDiv = lastBtn.findViewById(R.id.div);
                    if (lastBtnDiv != null) {
                        lastBtnDiv.setVisibility(View.GONE);
                    }
                    View lastBtnDivBottom = lastBtn.findViewById(R.id.div_bottom);
                    if (lastBtnDivBottom != null) {
                        lastBtnDivBottom.setVisibility(View.GONE);
                    }
                     */
                }
                lastBtn = buttonCancel;
            }
            else
            {
                BOOL highDiscount = NO;
                BOOL showDiscount = NO;
                NSString *discountStr = nil;
                if (regularMonthlyPrice > 0 && s.monthlyPrice.doubleValue > 0 && s.monthlyPrice.doubleValue < regularMonthlyPrice)
                {
                    int discount = (int) ((1 - s.monthlyPrice.doubleValue / regularMonthlyPrice) * 100.0);
                    discountStr = [NSString stringWithFormat:@"%d%%", discount];
                    if (discount > 0)
                    {
                        discountStr = [NSString stringWithFormat:@" %@ ", [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_discount_descr"), discountStr]];
                        showDiscount = YES;
                        highDiscount = discount > 50;
                    }
                }
                OAPurchaseDialogCardButton* button = [_osmLiveCard addCardButtonWithTitle:[s getTitle:16.0] description:[s getDescription:14.0] buttonText:s.formattedPrice buttonType:anyPurchased ? EOAPurchaseDialogCardButtonTypeRegular : EOAPurchaseDialogCardButtonTypeExtended active:YES discountDescr:discountStr showDiscount:showDiscount highDiscount:highDiscount onButtonClick:^{
                    [weakSelf subscribe:s];
                }];

                //div.setVisibility(View.VISIBLE);
                lastBtn = button;
            }
        }
        if (lastBtn)
        {
            /*
            View div = lastBtn.findViewById(R.id.div);
            if (div != null) {
                div.setVisibility(View.GONE);
            }
            View divBottom = lastBtn.findViewById(R.id.div_bottom);
            if (divBottom != null) {
                divBottom.setVisibility(View.GONE);
            }
             */
        }
    }
    [_osmLiveCard setProgressVisibile:NO];
    [_osmLiveCard setNeedsLayout];
}

@end
