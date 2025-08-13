//
//  OACollapsableView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT CGFloat const kMarginLeft;
FOUNDATION_EXPORT CGFloat const kMarginRight;
FOUNDATION_EXPORT CGFloat const kMarginTop;
FOUNDATION_EXPORT CGFloat const kCollapsableTitleMarginRight;

@interface OACollapsableView : UIView

@property (nonatomic) BOOL collapsed;

- (void) adjustHeightForWidth:(CGFloat)width;
- (void) setSelected:(BOOL)selected animated:(BOOL)animated;
- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@end
