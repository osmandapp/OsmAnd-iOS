//
//  OAPlanTypeCardRow.h
//  OsmAnd
//
//  Created by Skalii on 20.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseFeatureCardView.h"

typedef NS_ENUM (NSUInteger, OAPlanTypeCardRowType)
{
    EOAPlanTypeChoosePlan = 0,
    EOAPlanTypeChooseSubscription,
    EOAPlanTypePurchase
};

@class OASubscription, OAFeature;

@protocol OAPlanTypeCardRowDelegate

- (void)onPlanTypeSelected:(NSInteger)tag
                      type:(OAPlanTypeCardRowType)type
                     state:(UIGestureRecognizerState)state
              subscription:(OASubscription *)subscription;

@end

@interface OAPlanTypeCardRow : OABaseFeatureCardView

- (instancetype)initWithType:(OAPlanTypeCardRowType)type;

@property (nonatomic, weak) id<OAPlanTypeCardRowDelegate> delegate;

- (void)updateSelected:(BOOL)selected;

- (void)updateInfo:(OASubscription *)subscription selectedFeature:(OAFeature *)selectedFeature selected:(BOOL)selected;

@end
