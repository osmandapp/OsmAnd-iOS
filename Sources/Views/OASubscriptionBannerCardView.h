//
//  OASubscriptionBannerCardView.h
//  OsmAnd
//
//  Created by Skalii on 13.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOASubscriptionBannerType)
{
    EOASubscriptionBannerFree = 0,
    EOASubscriptionBannerNoFree,
    EOASubscriptionBannerUpdates
};

@protocol OASubscriptionBannerCardViewDelegate

- (void)onButtonPressed;

@end

@interface OASubscriptionBannerCardView : UIView

@property (nonatomic, assign, readonly) EOASubscriptionBannerType type;
@property (nonatomic, assign) NSInteger freeMapsCount;

- (instancetype)initWithType:(EOASubscriptionBannerType)type;

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIButton *buttonView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomNoSeparatorMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconBottomNoSeparatorMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBottomNoSeparatorMargin;

@property (nonatomic, weak) id<OASubscriptionBannerCardViewDelegate> delegate;

@end
