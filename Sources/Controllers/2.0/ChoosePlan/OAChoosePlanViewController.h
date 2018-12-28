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
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *cardsContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnLater;

@property (nonatomic, readonly) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic, readonly) NSArray<OAFeature *> *selectedPlanTypeFeatures;

- (void) commonInit;

- (NSString *) getInfoDescription;
- (UIImage *) getPlanTypeHeaderImage;
- (NSString *) getPlanTypeHeaderTitle;
- (NSString *) getPlanTypeHeaderDescription;
- (NSString *) getPlanTypeButtonTitle;
- (NSString *) getPlanTypeButtonDescription;

- (void) setPlanTypeButtonClickListener:(UIButton *)button;

+ (OAProduct *) getPlanTypeProduct;

@end

NS_ASSUME_NONNULL_END
