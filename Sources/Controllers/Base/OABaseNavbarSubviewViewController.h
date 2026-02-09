//
//  OABaseNavbarSubviewViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@interface OABaseNavbarSubviewViewController : OABaseButtonsViewController

- (UIView *)createSubview;
- (CGFloat)getOriginalNavbarHeight;
- (void)updateSubviewHeight:(CGFloat)height;
- (void)updateSubview:(BOOL)forceUpdate;
- (UIEdgeInsets)subviewMargin;

@end
