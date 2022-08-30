//
//  OAFeatureCardRow.h
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseFeatureCardView.h"
#import "OAChoosePlanViewController.h"

#define kMinRowHeight 48.

NS_ASSUME_NONNULL_BEGIN

@class OAFeature;

typedef NS_ENUM (NSUInteger, OAFeatureCardRowType)
{
    EOAFeatureCardRowPlan = 0,
    EOAFeatureCardRowSubscription,
    EOAFeatureCardRowSimple,
    EOAFeatureCardRowInclude

};

@protocol OAFeatureCardRowDelegate

- (void)onFeatureSelected:(NSInteger)tag state:(UIGestureRecognizerState)state;

@end

@interface OAFeatureCardRow : OABaseFeatureCardView

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;

@property (nonatomic, weak) id<OAFeatureCardRowDelegate> delegate;

- (instancetype) initWithType:(OAFeatureCardRowType)type;

- (void)updateInfo:(OAFeature *)feature showDivider:(BOOL)showDivider selected:(BOOL)selected;

- (void)updateSimpleRowInfo:(NSString *)title
                showDivider:(BOOL)showDivider
          dividerLeftMargin:(CGFloat)dividerLeftMargin
                       icon:(NSString *)icon;

- (void)updateIncludeInfo:(OAFeature *)feature;

@end

NS_ASSUME_NONNULL_END
