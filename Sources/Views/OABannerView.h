//
//  OABannerView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OABannerViewDelegate <NSObject>

@optional
- (void)bannerButtonPressed;

@end

@interface OABannerView : UIView

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *buttonTitle;

@property (nonatomic, weak) id<OABannerViewDelegate> delegate;

- (CGFloat) getHeightByWidth:(CGFloat)width;

@end
