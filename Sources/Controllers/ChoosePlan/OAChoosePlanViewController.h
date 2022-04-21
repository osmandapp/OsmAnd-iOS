//
//  OAChoosePlanViewController.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAProduct;

typedef enum : NSUInteger {
    EOAFeatureWikivoyageOffline = 0,
    EOAFeatureDailyMapUpdates,
    EOAFeatureMonthlyMapUpdates,
    EOAFeatureUnlimitedDownloads,
    EOAFeatureWikipediaOffline,
    EOAFeatureContourLinesHillshadeMaps,
    EOAFeatureWeather,
    EOAFeatureSeaDepthMaps,
    EOAFeatureDonationToOSM,
    EOAFeatureUnlockAllFeatures,
    EOAFeatureSkiMap,
    EOAFeatureNautical,
    EOAFeatureParking,
    EOAFeatureTripRecording,
    EOAFeatureRegionAfrica,
    EOAFeatureRegionRussia,
    EOAFeatureRegionAsia,
    EOAFeatureRegionAustralia,
    EOAFeatureRegionEurope,
    EOAFeatureRegionCentralAmerica,
    EOAFeatureRegionNorthAmerica,
    EOAFeatureRegionSouthAmerica
} EOAFeature;

@interface OAFeature : NSObject

@property (nonatomic, readonly) EOAFeature value;

- (instancetype) initWithFeature:(EOAFeature)feature;

- (NSString *) toHumanString;
- (UIImage *) getImage;
- (BOOL) isFeaturePurchased;
- (BOOL) isFeatureFree;
- (BOOL) isFeatureAvailable;
- (OAProduct *) getFeatureProduct;

@end

@interface OAChoosePlanViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIView *cardsContainer;
@property (weak, nonatomic) IBOutlet UIView *publicInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *lbPublicInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnTermsOfUse;
@property (weak, nonatomic) IBOutlet UIButton *btnPrivacyPolicy;
@property (weak, nonatomic) IBOutlet UIButton *btnLater;
@property (weak, nonatomic) IBOutlet UIButton *restorePurchasesBottomButton;

@property (nonatomic, readonly) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@property (nonatomic, assign) BOOL purchasing;
@property (nonatomic) OAProduct *product;

- (void) commonInit;

- (UIView *) createNavBarBackgroundView;
- (NSString *) getPlanTypeTopText;
- (NSString *) getPlanTypeHeaderTitle;
- (NSString *) getPlanTypeHeaderDescription;
- (NSString *) getPlanTypeButtonTitle;
- (NSString *) getPlanTypeButtonHeaderText;
- (NSString *) getPlanTypeButtonDescription;

//- (void) setPlanTypeButtonClickListener:(UIButton *)button;
- (void)setupBottomButton:(UIButton *)button;

+ (OAProduct *) getPlanTypeProduct;

@end

NS_ASSUME_NONNULL_END
