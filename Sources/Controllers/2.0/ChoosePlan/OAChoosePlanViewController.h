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

@end

@interface OAChoosePlanViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIView *cardsContainer;
@property (weak, nonatomic) IBOutlet UIButton *btnLater;

- (void) commonInit;

- (NSString *) getInfoDescription;
- (NSArray<OAFeature *> *) getOsmLiveFeatures;
- (NSArray<OAFeature *> *) getPlanTypeFeatures;
- (NSArray<OAFeature *> *) getSelectedOsmLiveFeatures;
- (NSArray<OAFeature *> *) getSelectedPlanTypeFeatures;
- (UIImage *) getPlanTypeHeaderImage;
- (NSString *) getPlanTypeHeaderTitle;
- (NSString *) getPlanTypeHeaderDescription;
- (NSString *) getPlanTypeButtonTitle;
- (NSString *) getPlanTypeButtonDescription;
- (void) setPlanTypeButtonClickListener:(UIButton *)button;
- (OAProduct * _Nullable) getPlanTypeProduct;

@end

NS_ASSUME_NONNULL_END
