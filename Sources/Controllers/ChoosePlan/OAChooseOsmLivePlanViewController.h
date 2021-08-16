//
//  OAChoosePlanViewController.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAProduct;
@class OAFeature;

@interface OAChooseOsmLivePlanViewController : OAChoosePlanViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIView *cardsContainer;
@property (weak, nonatomic) IBOutlet UIView *publicInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *lbPublicInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnTermsOfUse;
@property (weak, nonatomic) IBOutlet UIButton *btnPrivacyPolicy;
@property (weak, nonatomic) IBOutlet UIButton *btnLater;
@property (weak, nonatomic) IBOutlet UIView *featuresView;
@property (weak, nonatomic) IBOutlet UIButton *btnRestore;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIButton *restorePurchasesBottomButton;

- (void) commonInit;

- (UIImage *) getPlanTypeHeaderImage;
- (NSString *) getPlanTypeHeaderTitle;
- (NSString *) getPlanTypeHeaderDescription;
- (NSString *) getPlanTypeButtonTitle;
- (NSString *) getPlanTypeButtonDescription;

- (void) setPlanTypeButtonClickListener:(UIButton *)button;

+ (OAProduct *) getPlanTypeProduct;

@end

NS_ASSUME_NONNULL_END
