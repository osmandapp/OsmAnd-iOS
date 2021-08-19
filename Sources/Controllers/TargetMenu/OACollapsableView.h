//
//  OACollapsableView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMarginLeft 60.0f
#define kMarginRight 15.0f
#define kMarginTop 10.0f
#define kCollapsableTitleMarginRight 35.0f

@interface OACollapsableView : UIView

@property (nonatomic) BOOL collapsed;

- (void) adjustHeightForWidth:(CGFloat)width;
- (void) setSelected:(BOOL)selected animated:(BOOL)animated;
- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@end
