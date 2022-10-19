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
#define kPrimarySpaceMargin 16.
#define kSecondarySpaceMargin 12.

NS_ASSUME_NONNULL_BEGIN

@interface OABaseFeatureCardView : UIView

- (CGFloat)updateLayout:(CGFloat)y width:(CGFloat)width;
- (CGFloat)updateFrame:(CGFloat)y width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
