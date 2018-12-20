//
//  OAPurchaseDialogCardView.h
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAPurchaseDialogItemView : UIView

- (CGFloat) updateLayout:(CGFloat)width;
- (CGRect) updateFrame:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
