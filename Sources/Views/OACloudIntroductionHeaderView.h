//
//  OACloudIntroductionHeaderView.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OACloudIntroductionDelegate <NSObject>

- (void)getOrRegisterButtonPressed;
- (void)logInButtonPressed;

@end

@interface OACloudIntroductionHeaderView : UIView

@property (nonatomic, weak) id<OACloudIntroductionDelegate> delegate;

- (void)setUpViewWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image topButtonTitle:(NSString *)topButtonTitle bottomButtonTitle:(NSString *)bottomButtonTitle;
- (CGFloat)calculateViewHeight;

@end

NS_ASSUME_NONNULL_END
