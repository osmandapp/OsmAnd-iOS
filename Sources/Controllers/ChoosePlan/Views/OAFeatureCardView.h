//
//  OAFeatureCardView.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseFeatureCardView.h"

NS_ASSUME_NONNULL_BEGIN

@class OAFeature, OAProduct;

@protocol OAFeatureCardViewDelegate

- (void)onFeatureSelected:(OAFeature *)feature;
- (void)onPlanTypeSelected:(OAProduct *)subscription;

- (void)onLearnMoreButtonSelected;

@end

@interface OAFeatureCardView : OABaseFeatureCardView

- (instancetype)initWithFeature:(OAFeature *)feature;

- (void)updateInfo:(OAFeature *)selectedFeature replaceFeatureRows:(BOOL)replaceFeatureRows;

@property (nonatomic, weak) id <OAFeatureCardViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
