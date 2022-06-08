//
//  OAPurchaseDialogCardView.h
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSeparatorHeight .5
#define kIconSize 30.
#define kSpaceMargin 16.

NS_ASSUME_NONNULL_BEGIN

@interface OABaseFeatureCardView : UIView

- (CGFloat)updateLayout:(CGFloat)y;
- (CGFloat)updateFrame:(CGFloat)y;

@end

NS_ASSUME_NONNULL_END
