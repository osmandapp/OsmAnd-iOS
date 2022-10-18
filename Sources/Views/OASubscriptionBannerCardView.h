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

@property (nonatomic, weak) id<OASubscriptionBannerCardViewDelegate> delegate;

- (void)updateView;
- (void)updateFrame;

@end
